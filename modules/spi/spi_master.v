module spi_master(
  input  wire       clk2,  // 2x the SPI bus clock

  input  wire       cpol,  // clock polarity (idle level)
  input  wire       cpha,  // clock phase. 0 - sample on rising edge,
                           //              1 - sample on falling edge

  output reg        mclk,  // clk2/2
  output reg        mosi,
  input  wire       miso,

  input  wire [7:0] din,   // data to be sent by master
  output reg  [7:0] dout,  // data received by master
  input  wire       start, // toggle high to start transfer
  output wire       busy   // high while transfer in progress
                           // rising edge when 'start' toggled,
                           // falling edge when transfer complete
  
);

reg [4:0] cnt = 0;
assign busy = cnt!=0;

wire phas=cnt[0];

always @(posedge clk2)
  if(start)
    cnt <= 16;
  else if(cnt==0)
    cnt <= 0;
  else
    cnt <= cnt-1;


always @(posedge clk2)
  if(!busy) begin
    mclk <= cpol;
    if(start) begin
      dout <= din; // latch data to send
      cnt  <= 16;
      mosi <= din[7];
    end else begin
`ifdef SIM
      mosi <= 1'bx;
`else
      mosi <= 0;
`endif
    end
  end else begin
    mclk <= ~phas ^ cpol;
    mosi <= dout[7];
    if(phas==cpha) // sample
       dout   <= {dout[6:0], miso};
  end


endmodule
