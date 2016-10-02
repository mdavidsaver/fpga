/* MODBUS slave endpoint
 *
 * Handle functions
 *  0x3 Read holding registers
 *    -> | addr | 0x02 | ADDR[2] | CNT[2] | CRC[2] |
 *    <- | addr | 0x02 | bytes | body[0-254] | CRC[2] |
 *  0x6 Write single register
 *    -> | addr | 0x02 | ADDR[2] | VAL[2] | CRC[2] |
 *    <- | addr | 0x02 | ADDR[2] | VAL[2] | CRC[2] |
 *
 * All other functions trigger exception reply
 *    <- | addr | 0x8x | code | CRC[2] |
 *
 * CRC computed over entire frame, including slave address
 *
 * Support broadcast (slave address 0) and unicast (slave address==maddr).
 * Broadcast messages have no reply
 */
module modbus_endpoint(
  input         reset,
  input         clk,  // ref clock

  // Configuration
  input [6:0]   maddr, // MODBUS slave address.  Must not be zero.  Should not change while frame_busy

  // UART interface
  // TX (MISO)
  output [7:0]  dout,   // data to TX
  output        send,
  input         txbusy,
  // RX (MOSI)
  input         ready,// pulsed when new data received
  input         rxerr,// RX bad frame
  input   [7:0] din,  // RX data

  input         timeout_clk,  // Inactivity timeout clock.  Must be a integer fraction of 'clk'
                              // timeout period is (1<<TMOSIZE)-1 ticks of this clock

  // Slave bus
  output        valid,
  output        iswrite,
  output [15:0] addr,
  output [15:0] wdata,
  input  [15:0] rdata,
  input         ack,

  // Status
  output        frame_busy,
  output        frame_err
);

localparam S_IDLE         =0, // waiting for start of frame (slave address)
           S_RX_FUNC      =1, // waiting for function
           // Handle Read/Write request
           S_RX_ADDR_H =2,
           S_RX_ADDR_L =3,
           S_RX_VAL_H  =4,
           S_RX_VAL_L  =5,
           S_RX_CRC_L  =6,
           S_RX_CRC_H  =7,
           // -> S_TX_FUNC | S_TX_WR_BUS_PREP | S_HOLDOFF
           // Send response
           S_TX_FUNC   =8,
           // -> S_TX_RD_CNT | S_TX_WR_ADDR_H
           // Send Read response
           S_TX_RD_CNT    =9,
           S_TX_RD_BUS_PREP  =10,
           S_TX_RD_BUS    =11,
           S_TX_RD_DATA_L =12,
           // -> S_TX_RD_BUS or S_TX_CRC1
           // Send Write response
           S_TX_WR_BUS =21,
           // -> S_TX_FUNC
           S_TX_WR_ADDR_H =22,
           S_TX_WR_ADDR_L =23,
           S_TX_WR_DATA_H =24,
           S_TX_WR_DATA_L =25,
           // -> S_TX_CRC1
           // Finalize all TX
           S_TX_CRC_L     =29,
           S_TX_CRC_H     =30,
           S_HOLDOFF      =31; // Ignore master after sending exception
           // -> S_IDLE

reg [4:0] state = S_IDLE;

reg send=0, send_prev=0;
reg [7:0] dout;

always @(posedge clk)
  send_prev <= send;

wire txstart = {send, send_prev}==2'b10;

assign frame_err = state==S_HOLDOFF;
assign frame_busy = state!=S_IDLE;

// slave bus
assign valid = state==S_TX_RD_BUS | state==S_TX_WR_BUS;
assign iswrite = state==S_TX_WR_BUS;
reg func_write;
reg [15:0] addr;
reg [15:0] wdata;

// various places where the upper byte of a 16-bit value
// is latched until it can be sent
reg  [7:0] scratch;

// same CRC calculator use for both RX and TX phases
reg  crc_mode = 0, crc_mode_prev; // 0 - RX, 1 - TX
wire crc_hold  = state==S_RX_CRC_L;
wire crc_reset = (state==S_IDLE)
               | (crc_mode!=crc_mode_prev);
wire [15:0] crc_current;
wire [15:0] crc_expect = {din, scratch};

always @(posedge clk)
  crc_mode_prev <= crc_mode;

mcrc crc(
  .clk(clk),
  .reset(crc_reset),
  .ready(~crc_hold & (crc_mode ? txstart : ready)),
  .din(crc_mode ? dout : din),
  .crc(crc_current)
);

parameter TMOSIZE = 8;
parameter TMOMAX = {TMOSIZE{1'b1}};

reg [TMOSIZE-1:0] tmocnt;

always @(posedge clk)
  if(ready & state==S_IDLE)
    tmocnt <= TMOMAX; // Start timeout count down
  else if(state!=S_IDLE & timeout_clk & tmocnt>0)
    tmocnt <= tmocnt-1;        // count down while not idleing

// received slave address
reg address_bcast;  // was zero
reg address_me;     // was maddr

always @(posedge clk)
begin
  if(reset | (state!=S_IDLE & tmocnt==0))
  begin
    if(reset)
      $display("# reset");
    else if(state!=S_IDLE & tmocnt==0)
      $display("# timeout");
    state <= S_IDLE;
    send     <= 0;
    crc_mode <= 0;
  end
  else if(state==S_HOLDOFF | rxerr) begin
    // Wait for timeout
    send     <= 0;
    crc_mode <= 0;
    state    <= S_HOLDOFF;
  end
  // Handle recv'd serial byte
  else if(ready) case(state)
    S_IDLE: begin
      address_bcast  <= din==0;
      address_me     <= din==maddr;
      // slave address >=0x80 illegal
      state          <= din[7] ? S_HOLDOFF : S_RX_FUNC;
      send           <= 0;
    end

    S_RX_FUNC: begin
      $display("# Start Frame RX w/ func=%02x", din);
      func_write <= 0;
      case(din)
        8'h03: begin // Read Holding
          // | addr | 0x02 | ADDR[2] | CNT[2] | CRC[2] |
          state <= S_RX_ADDR_H;
        end
        8'h06: begin // Write single
          // | addr | 0x06 | ADDR[2] | VAL[2] | CRC[2] |
          state <= S_RX_ADDR_H;
          func_write <= 1;
        end
        default: begin
          $display("# Invalid function %02x", din);
          state  <= S_HOLDOFF;
        end
      endcase
    end
    
    S_RX_ADDR_H: begin
      addr[15:8] <= din;
      state      <= S_RX_ADDR_L;
    end
    
    S_RX_ADDR_L: begin
      addr[7:0]  <= {din[7:1], 1'b0};
      state      <= S_RX_VAL_H;
      if(din[0]) begin
        $display("# Unaligned access error");
        state  <= S_HOLDOFF; // no unaligned reads
      end
    end
    
    S_RX_VAL_H: begin
      state       <= S_RX_VAL_L;
      wdata[15:8] <= din;
    end

    S_RX_VAL_L: begin
      wdata[7:0] <= din;
      state    <= S_RX_CRC_L;
    end

    S_RX_CRC_L: begin
      scratch  <= din;
      state    <= S_RX_CRC_H;
    end

    S_RX_CRC_H: begin
      crc_mode <= 1;
      dout  <= maddr;
      send  <= 0;
      state <= S_HOLDOFF;

      if(crc_expect!=crc_current) begin
        $display("# CRC mismatch %04x != %04x", crc_expect, crc_current);
      end else if(addr[0]) begin
        $display("# ignore unaligned operation");
      end else begin

        // process write if bcast or selected
        if(func_write & (address_bcast | address_me)) begin
          state <= S_TX_WR_BUS;
        end
        // process read only when selected
        else if(~func_write & address_me) begin
          if(wdata[15:7]!=0) begin
            $display("# Read size too large %08x", wdata);
          end else begin
            state <= S_TX_FUNC;
            send  <= 1;
          end
        end
        // other combinations are in error
        else begin
          $display("# Ignore operation");
        end

      end
    end

  endcase // end ready
  // Logic when not receiving new serial byte
  else case(state) // ~ready
    S_IDLE: begin
      crc_mode <= 0;
      send     <= 0;
    end

    S_TX_FUNC: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send & ~ack) begin
        if(func_write) begin
          dout  <= 6;
          state <= S_TX_WR_ADDR_H;
        end else begin
          dout  <= 3;
          state <= S_TX_RD_CNT;
        end
        send  <= 1;
      end
    end

    S_TX_RD_CNT: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send) begin
        dout  <= {wdata[6:0], 1'b0};
        send  <= 1;
        // Handle zero length read
        state <= wdata[6:0]==0 ? S_TX_CRC_L : S_TX_RD_BUS_PREP;
      end
    end

    S_TX_RD_BUS_PREP: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send) begin
        state <= S_TX_RD_BUS;
      end
    end
    
    S_TX_RD_BUS: if(ack) begin
      dout         <= rdata[15:8];
      scratch      <= rdata[7:0];
      send         <= 1;
      state        <= S_TX_RD_DATA_L;
      addr         <= addr+2;
      wdata[6:0]   <= wdata[6:0]-1;
    end

    S_TX_RD_DATA_L: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send & ~ack) begin
        dout  <= scratch;
        send  <= 1;
        state <= wdata[6:0]==0 ? S_TX_CRC_L : S_TX_RD_BUS_PREP;
      end      
    end
    
    S_TX_WR_BUS: if(ack) begin
      state        <= S_TX_FUNC;
      // dout setup in S_RX_CRC_H
      send         <= 1;
    end

    S_TX_WR_ADDR_H: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send) begin
        dout  <= addr[15:8];
        send  <= 1;
        // Handle zero length read
        state <= S_TX_WR_ADDR_L;
      end
    end

    S_TX_WR_ADDR_L: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send) begin
        dout  <= addr[7:0];
        send  <= 1;
        // Handle zero length read
        state <= S_TX_WR_DATA_H;
      end
    end

    S_TX_WR_DATA_H: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send) begin
        dout  <= wdata[15:8];
        send  <= 1;
        // Handle zero length read
        state <= S_TX_WR_DATA_L;
      end
    end

    S_TX_WR_DATA_L: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send) begin
        dout  <= wdata[7:0];
        send  <= 1;
        // Handle zero length read
        state <= S_TX_CRC_L;
      end
    end

    S_TX_CRC_L: begin
      if(txbusy) begin
        send         <= 0;
      end else if(~send) begin
        dout         <= crc_current[7:0];
        scratch      <= crc_current[15:8];
        send         <= 1;
        state        <= S_TX_CRC_H;
      end
    end

    S_TX_CRC_H: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send) begin
        dout  <= scratch;
        send  <= 1;
        state <= S_IDLE;
      end
    end
  endcase
end

endmodule
