/* SPI busy slave
 *
 * Protocol
 *  When din_latch==1 then din will be latched on the next tick.
 *  When done==1 then dout is stable
 *
 *  When a transfer starts din_latch==1 and done==0 signals the start
 *  of the first byte
 *  Subsequent bytes have din_latch==1 and done==1.
 *
 * done==1 will always conincide with din_latch==1
 */
module spi_slave(
  input wire        clk,   // sample clock.  must be at least 2x mclk

  input  wire       cpol,  // clock polarity (idle level)
  input  wire       cpha,  // clock phase. 0 - sample on rising edge,
                           //              1 - sample on falling edge

  input  wire       select,// chip select (active high)
  input  wire       mclk,
  input  wire       mosi,
  output reg        miso,

  output wire       din_latch,        // pulsed 1 tick before din is latched
  input  wire [(8*NBYTES-1):0] din,   // data to be sent to master
  output reg  [(8*NBYTES-1):0] dout,  // data received from master

  output wire       busy,
  output reg        done   // pulsed after each byte
);

parameter NBYTES = 1;

reg [3:0] select_x;
always @(posedge clk)
  select_x <= {select_x[2:0], select};

wire start = select_x==4'b0011;

reg [1:0] mclk_x;
always @(posedge clk)
  mclk_x <= {mclk_x[0], mclk};

wire mclk_p = mclk_x==2'b01, // rising edge
     mclk_n = mclk_x==2'b10, // falling edge
     mclk_tick = mclk_p | mclk_n,
     mclk_r = cpol==0 ? mclk_p : mclk_n, // inactive -> active
     mclk_f = cpol==0 ? mclk_n : mclk_p, // active -> inactive
     sample = cpha==0 ? mclk_r : mclk_f,
     setup  = cpha==0 ? mclk_f : mclk_r;

reg mosi_x;
always @(posedge clk)
  mosi_x <= mosi;

reg [(3+NBYTES):0] cnt = 0;
assign busy = start | (cnt!=0 & select_x[0]);

assign din_latch = start | done;

reg latched;
always @(posedge clk)
  latched   <= din_latch;

always @(posedge clk)
  if(latched) begin
    cnt <= 16*NBYTES;
    done<= 0;
  end else if(~busy) begin
    cnt <= 0;
    done<= 0;
  end else if(mclk_tick) begin
    cnt <= cnt-1;
    done<= cnt==1;
  end

always @(posedge clk)
  if(latched)
    miso <= din[(8*NBYTES-1)];
  else if(~busy)
`ifdef SIM
    miso <= 1'bz;
`else
    miso <= miso;
`endif
  else if(setup)
    miso <= dout[(8*NBYTES-1)];

always @(posedge clk)
  if(latched)
    dout<= din; // latch data to send
  else if(busy & sample)
    dout   <= {dout[(8*NBYTES-2):0], mosi_x};

endmodule
