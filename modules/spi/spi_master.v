module spi_master(
  input  wire       clk4,  // 4x the SPI bus clock

  input  wire       cpol,  // clock polarity (idle level)
  input  wire       cpha,  // clock phase. 0 - sample on rising edge,
                           //              1 - sample on falling edge

  output reg        mclk,  // clk4/4
  output reg        mosi,
  input  wire       miso,

  input  wire [7:0] din,   // data to be sent by master
  output reg  [7:0] dout,  // data received by master
  input  wire       start, // toggle high to start transfer
  output wire       busy   // high while transfer in progress
                           // rising edge when 'start' toggled,
                           // falling edge when transfer complete
  
);

reg [1:0] phas = 0;
always @(posedge clk4)
  if(busy)
    phas <= phas+1;
  else
    phas <= 0;

reg [3:0] cnt = 0;
assign busy = cnt!=0;

always @(posedge clk4)
  if(!busy) begin
    mclk <= cpol;
    mosi <= 0;
    if(start) begin
      dout <= din;
      cnt  <= 8;
    end else begin
`ifdef SIM
      dout <= 8'hxx;
`else
      dout <= 0;
`endif
    end
  end else begin
    // CPHA=0
    case(phas)
    // setup
    0: begin
       mclk   <= cpol;
       mosi   <= dout[7];
       end
    // tick, slave may sample
    1: begin
       mclk   <= ~cpol;
       mosi   <= dout[7];
       if(cpha==0)
         dout   <= {dout[6:0], miso};
       end
    // master sample, slave must sample by this point
    2: begin
       mclk   <= ~cpol;
       mosi   <= dout[7];
       end
    // tock
    3:begin
       mclk   <= cpol;
       mosi   <= dout[7];
       cnt    <= cnt-1;
       if(cpha==1)
         dout   <= {dout[6:0], miso};
      end
    endcase
  end


endmodule
