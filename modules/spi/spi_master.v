module spi_master(
  input  wire       clk4,  // 4x the SPI bus clock

  output reg        mclk,  // clk4/4
  output reg        mosi,
  input  wire       miso,

  input  wire [7:0] din,
  output reg  [7:0] dout,
  input  wire       start,
  output wire       busy
  
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
  if(!busy && start) begin
    dout <= din;
    cnt    <= 8;
  end else if(!busy) begin
    mclk <= 0;
`ifdef SIM
    dout <= 8'hxx;
`else
    dout <= 0;
`endif
  end

always @(posedge clk4)
  if(busy) begin
    // CPOL=0, CPHA=1
    case(phas)
    0: mosi   <= dout[7];
    1: mclk   <= 1;
    2: dout <= {dout[6:0], miso};
    3:begin
       mclk   <= 0;
       cnt    <= cnt-1;
      end
    endcase
  end


endmodule
