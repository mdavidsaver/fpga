/* SPI busy slave
 *
 * Protocol
 * 1. 'start' indicates that master has selected.  din should be stable.
 * 2. 'done' indicates that a frame has been shifted.
 *    din may be changed, and dout inspected.
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

  input  wire [(8*NBYTES-1):0] din,   // data to be sent to master
  output reg  [(8*NBYTES-1):0] dout,  // data received from master

  output wire       busy,
  output wire       start, // pulsed when 'select' rises
  output reg        done   // pulsed after each byte
);

parameter NBYTES = 1;

reg [3:0] select_x;
always @(posedge clk)
  select_x <= {select_x[2:0], select};

assign start = select_x==4'b0011;

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
assign busy = cnt!=0 & select_x[0];

always @(posedge clk)
  if(start) begin
    cnt <= 16*NBYTES;
    done<= 0;
    dout<= din; // latch data to send
  end else if(!busy) begin
    cnt <= 0;
    done<= 0;
  end else if(mclk_tick) begin
    cnt <= cnt-1;
    done<= cnt==1;
  end

always @(posedge clk)
  if(start)
    miso <= din[(8*NBYTES-1)];
  else if(!busy)
`ifdef SIM
    miso <= 1'bz;
`else
    miso <= miso;
`endif
  else if(setup)
    miso <= dout[(8*NBYTES-1)];

always @(posedge clk)
  if(busy & sample)
    dout   <= {dout[(8*NBYTES-2):0], mosi_x};

endmodule
