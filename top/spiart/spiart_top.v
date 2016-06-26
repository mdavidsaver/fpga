module top(
  input wire clk,   // 12 MHz

  output wire sertx,
  input wire  serrx,

  output wire mclk,
  output wire mosi,
  input  wire miso,
  output wire select,

  output reg [4:0] led
);

wire cpol, cpha ;

wire [7:0] divparam;
reg [7:0] divcnt = 0;

wire spi_start, spi_busy;
wire  [7:0] spi_send, spi_recv;

always @(posedge clk)
  if(divcnt>=divparam)
    divcnt <= 0;
  else
    divcnt <= divcnt+1;

wire mtick = divcnt==0;

spi_master spi(
    .ref_clk(clk),
    .bit_clk2(mtick),
    .cpol(cpol),
    .cpha(cpha),
    .mclk(mclk),
    .mosi(mosi),
    .miso(miso),
    .din(spi_send),
    .dout(spi_recv),
    .start(spi_start),
    .busy(spi_busy)
);

wire sertxi, serrxi;
assign sertx = ~sertxi;
assign serrxi = ~serrx;

wire uart_start, uart_txbusy, uart_rxbusy, uart_ready, uart_rxerr;
wire [7:0] uart_din, uart_latch;

// 12000000/(115200*8) ~= 2**10/78   (0.825 % error)
uart #(
  .Width(10),
  .Incr(78)
) U(
  .reset(0),
  .clk(clk),

  .rin(serrxi),
  .rout(sertxi),

  .din(uart_latch),
  .send(uart_start),
  .txbusy(uart_txbusy),

  .dout(uart_din),
  .rxbusy(uart_rxbusy),
  .rxerr(uart_rxerr),
  .ready(uart_ready)
);

wire [2:0] genio;
assign select = genio[0];

spiart_logic L(
  .clk(clk),
  .cpol(cpol),
  .cpha(cpha),
  .genio(genio),
  .uart_ready(uart_ready),
  .uart_rxerr(uart_rxerr),
  .uart_rx(uart_din),
  .uart_start(uart_start),
  .uart_busy(uart_txbusy),
  .uart_tx(uart_latch),
  .spi_rx(spi_recv),
  .spi_tx(spi_send),
  .spi_start(spi_start),
  .spi_busy(spi_busy)
);
endmodule
