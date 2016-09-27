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
  input [6:0]   maddr, // MODBUS slave address (must not be zero)

  // Serial interface
  output [7:0]  dout,   // data to TX
  output        send,
  input         txbusy,

  //input         rxbusy, // RX in progress
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
  input         ack
);

localparam S_IDLE         =0, // waiting for start of frame (slave address)
           S_RX_FUNC      =1, // waiting for function
           // Handle Read request
           S_RX_RD_ADDR_H =2,
           S_RX_RD_ADDR_L =3,
           S_RX_RD_CNT_H  =4,
           S_RX_RD_CNT_L  =5,
           S_RX_RD_CRC_L  =6,
           S_RX_RD_CRC_H  =7,
           // Send Read response
           S_TX_RD_FUNC   =8,
           S_TX_RD_CNT    =9,
           S_TX_RD_BUS_PREP  =10,
           S_TX_RD_BUS    =11,
           S_TX_RD_DATA_L =12,
           // -> S_TX_RD_BUS or S_TX_CRC1
/*
           // Handle Write request
           S_RX_WR_ADDR_L =16,
           S_RX_WR_ADDR_H =17,
           S_RX_WR_DATA_L =18,
           S_RX_WR_DATA_H =19,
           S_RX_WR_CRC1   =20,
           S_RX_WR_CRC2   =16,
           // Send Write response
           S_TX_WR_FUNC   =24,
           S_TX_WR_ADDR_L =25,
           S_TX_WR_ADDR_H =26,
           S_TX_WR_DATA_L =27,
           S_TX_WR_DATA_H =28,
           // -> S_TX_CRC1
*/
           // Send exception response
           S_TX_RD_EXC_FUNC  =26,
           //S_TX_WR_EXC_FUNC  =27,
           S_TX_EXC_CODE  =28,
           // Finalize all TX
           S_TX_CRC_L     =29,
           S_TX_CRC_H     =30,
           S_HOLDOFF      =31; // Ignore master after sending exception
           // -> S_IDLE

reg [4:0] state = S_IDLE;

reg send=0;
reg [7:0] dout;

// slave bus
assign valid = state==S_TX_RD_BUS;
assign iswrite = 0;
reg [15:0] addr;
reg [15:0] wdata;

// internal for read
reg [6:0] dcnt;
// internal for exception code
reg [7:0] except;
// various places where the upper byte of a 16-bit value
// is latched until it can be sent
reg  [7:0] scratch;

// same CRC calculator use for both RX and TX phases
reg  crc_mode = 0, crc_mode_prev; // 0 - RX, 1 - TX
reg  crc_hold = 0;
wire crc_reset = (state==S_IDLE)
               | (state==S_TX_RD_EXC_FUNC)
               | (crc_mode!=crc_mode_prev);
wire [15:0] crc_current;
wire [15:0] crc_expect = {din, scratch};

always @(posedge clk)
  crc_mode_prev <= crc_mode;

mcrc crc(
  .clk(clk),
  .reset(crc_reset),
  .ready(~crc_hold & (crc_mode ? (send & ~txbusy) : ready)),
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
    crc_hold <= 0;
  end
  else if(state==S_HOLDOFF | rxerr) begin
    // Wait for timeout
    send     <= 0;
    crc_mode <= 0;
    crc_hold <= 0;
    state    <= S_HOLDOFF;
  end
  // Handle recv'd serial byte
  else if(ready) case(state)
    S_IDLE: begin
      address_bcast  <= din==0;
      address_me     <= din==maddr;
      state          <= S_RX_FUNC;
      except         <= din[7]; // slave >127 not legal
      send           <= 0;
    end

    S_RX_FUNC: begin
      $display("# Start Frame RX w/ func=%02x", din);
      case(din)
        8'h03: begin // Read Holding
          // | addr | 0x02 | ADDR[2] | CNT[2] | CRC[2] |
          state <= S_RX_RD_ADDR_H;
        end
        //8'h06: begin // Write single
          // | addr | 0x06 | ADDR[2] | VAL[2] | CRC[2] |
        //end
        default: begin
          $display("# Invalid function %02x", din);
          // This may be a CRC error (which we shouldn't respond to)
          // but we don't know how long the message is, so we have to bail now
          except <= 1; // illegal function
          state  <= S_TX_RD_EXC_FUNC;
          crc_mode <= 1;
          // after this point we don't send exception until
          // CRC match
        end
      endcase
    end
    
    S_RX_RD_ADDR_H: begin
      addr[15:8] <= din;
      state      <= S_RX_RD_ADDR_L;
    end
    
    S_RX_RD_ADDR_L: begin
      addr[7:0]  <= {din[7:1], 1'b0};
      state      <= S_RX_RD_CNT_H;
      if(din[0]) except <= 3; // no unaligned reads
    end
    
    S_RX_RD_CNT_H: begin
      state       <= S_RX_RD_CNT_L;
      // read reply can only contain 254 bytes
      // so the count field can't contain anything
      // larger than 0x7f.
      // So this byte must be zero
      if(din) begin
        except <= 3;
        $display("# Invalid count_h %02x", din);
      end
    end

    S_RX_RD_CNT_L: begin
      dcnt     <= din[6:0];
      state    <= S_RX_RD_CRC_L;
      crc_hold <= 1;
      if(din[7]) begin
        except <= 3;
        $display("# Invalid count_l %02x", din);
      end
    end

    S_RX_RD_CRC_L: begin
      scratch  <= din;
      state    <= S_RX_RD_CRC_H;
    end

    S_RX_RD_CRC_H: begin
      if(crc_expect==crc_current) begin
        // no reply for bcast, otherwise start read reply
        if(address_bcast | ~address_me) begin
          if(address_bcast)
            $display("# Refuse to reply to broadcast read");
          state <= S_IDLE;
        end else if(except) begin
          state  <= S_TX_RD_EXC_FUNC;
          crc_mode <= 1;
        end else begin
          // send slave address
          crc_mode <= 1;
          crc_hold <= 0;
          state <= S_TX_RD_FUNC;
          dout  <= maddr;
          send  <= 1;
        end
        state <= address_bcast ? S_IDLE : S_TX_RD_FUNC;
      end else begin
        $display("# CRC mismatch %04x != %04x", crc_expect, crc_current);
        // no reply for CRC error
        state <= S_HOLDOFF;
      end
    end

  endcase // end ready
  // Logic when not receiving new serial byte
  else case(state) // ~ready
    S_IDLE: begin
      crc_mode <= 0;
      crc_hold <= 0;
      send     <= 0;
    end

    S_TX_RD_FUNC: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send) begin
        dout  <= 3;
        send  <= 1;
        state <= S_TX_RD_CNT;
      end
    end

    S_TX_RD_CNT: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send) begin
        dout  <= dcnt<<1;
        send  <= 1;
        // Handle zero length read
        state <= dcnt==0 ? S_TX_CRC_L : S_TX_RD_BUS_PREP;
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
      dcnt         <= dcnt-1;
    end
    
    S_TX_RD_DATA_L: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send & ~ack) begin
        dout  <= scratch;
        send  <= 1;
        state <= dcnt==0 ? S_TX_CRC_L : S_TX_RD_BUS_PREP;
      end      
    end

    S_TX_RD_EXC_FUNC: begin
      dout  <= 8'h83;
      send  <= 1;
      state <= S_TX_EXC_CODE;
    end

    S_TX_EXC_CODE: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send) begin
        dout  <= except;
        send  <= 1;
        state <= S_TX_CRC_L;
      end
    end

    S_TX_CRC_L: begin
      if(txbusy) begin
        send <= 0;
      end else if(~send) begin
        dout         <= crc_current[7:0];
        scratch <= crc_current[15:8];
        send  <= 1;
        state <= S_TX_CRC_H;
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
