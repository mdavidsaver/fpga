module spi_master(
  input  wire       clk2,  // 2x the SPI bus clock

  input  wire       cpol,  // clock polarity (idle level)
  input  wire       cpha,  // clock phase. 0 - sample on rising edge,
                           //              1 - sample on falling edge

  output reg        mclk,  // clk2/2
  output reg        mosi,
  input  wire       miso,

  input  wire [(8*NBYTES-1):0] din,   // data to be sent by master
  output reg  [(8*NBYTES-1):0] dout,  // data received by master
  input  wire       start, // toggle high to start transfer
  output wire       busy   // high while transfer in progress
                           // rising edge when 'start' toggled,
                           // falling edge when transfer complete
  
);

parameter NBYTES = 1;

reg [(3+NBYTES):0] cnt = 0;
assign busy = cnt!=0;

wire phas=cnt[0];

always @(posedge clk2)
  if(!busy) begin
    mclk <= cpol;
    if(start) begin
      dout <= din; // latch data to send
      cnt  <= 16*NBYTES;
      mosi <= din[(8*NBYTES-1)];
    end else begin
      cnt <= 0;
`ifdef SIM
      mosi <= 1'bx;
`else
      mosi <= 0;
`endif
    end
  end else begin
    cnt <= cnt-1;
    mclk <= ~phas ^ cpol;
    mosi <= dout[(8*NBYTES-1)];
    if(phas==cpha) // sample
       dout   <= {dout[(8*NBYTES-2):0], miso};
  end


endmodule
