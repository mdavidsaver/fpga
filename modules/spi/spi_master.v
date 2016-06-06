module spi_master(
  input  wire       clk4,  // 4x the SPI bus clock

  output reg        mclk,  // clk4/4
  output reg        mosi,
  input  wire       miso,

  input  wire [7:0] din,
  output wire [7:0] dout,
  input  wire       start,
  output wire       busy
  
);

reg [1:0] phas = 0;
always @(posedge clk4)
  if(busy)
    phas <= phas+1;
  else
    phas <= 0;

reg [7:0] dshift;
assign dout = dshift;

reg [3:0] cnt = 0;
assign busy = cnt!=0;

always @(posedge clk4)
  if(!busy && start) begin
    dshift <= din;
    cnt    <= 8;
  end else if(!busy) begin
    mclk <= 0;
`ifdef SIM
    dshift <= 8'hxx;
`else
    dshift <= 0;
`endif
  end

always @(posedge clk4)
  if(busy) begin
    // CPOL=0, CPHA=1
    case(phas)
    0: mosi   <= dshift[7];
    1: mclk   <= 1;
    2: dshift <= {dshift[6:0], miso};
    3:begin
       mclk   <= 0;
       cnt    <= cnt-1;
      end
    endcase
  end


endmodule
