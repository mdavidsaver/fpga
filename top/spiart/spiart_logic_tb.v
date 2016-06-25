module test;

`include "utest.vlib"

`TEST_PRELUDE(92)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(6000)

reg uart_ready=0, uart_rxerr=0, uart_busy=0, spi_busy=0;
reg [7:0] uart_rx=0, spi_rx=0;

spiart_logic D(
  .clk(clk),
  
  .uart_ready(uart_ready),
  .uart_rxerr(uart_rxerr),
  .uart_rx(uart_rx),
  .uart_busy(uart_busy),
  .spi_busy(spi_busy),
  .spi_rx(spi_rx)
);

task uart_send;
  input [7:0] cmd;
  input [7:0] data;
  begin
  $display("# uart send cmd=%x data=%x", cmd, data);
  `ASSERT_EQUAL(D.state, D.S_IDLE, "idle state")
  
  uart_rx    <= cmd;
  uart_ready <= 1;
  @(posedge clk);
  uart_ready <= 0;
  uart_rx    <= 8'hxx;
  @(posedge clk);
  `ASSERT_EQUAL(D.state, D.S_WAIT_CMD, "wait command state")
  `ASSERT_EQUAL(D.cmd, cmd, "latched command")

  uart_rx    <= data;
  uart_ready <= 1;
  @(posedge clk);
  uart_ready <= 0;
  uart_rx    <= 8'hxx;
  @(D.state);
  `DIAG("uart send complete")
  end
endtask

task uart_recv;
  input [7:0] cmd;
  input [7:0] expect;
  begin
  $display("# uart recv cmd=%x expect=%x", cmd, expect);

  `DIAG("Wait for reply byte 1")
  while(~D.uart_start) @(posedge clk);
  uart_busy <= 1;
  `ASSERT_EQUAL(D.uart_tx, cmd, "cmd==reply")

  @(posedge clk);
  @(posedge clk);
  @(posedge clk);

  `ASSERT_EQUAL(D.state, D.S_WAIT_UART1, "wait uart1 state")
  uart_busy <= 0;

  `DIAG("Wait for reply byte 2")
  while(~D.uart_start) @(posedge clk);
  uart_busy <= 1;
  `ASSERT_EQUAL(D.uart_tx, expect, "reply data")

  @(posedge clk);
  @(posedge clk);
  @(posedge clk);

  `ASSERT_EQUAL(D.state, D.S_WAIT_UART2, "wait uart2 state")
  uart_busy <= 0;

  @(D.state);
  `ASSERT_EQUAL(D.state, D.S_IDLE, "idle state")

  `DIAG("uart recv complete")
  end
endtask

task uart;
  input [7:0] cmd;
  input [7:0] data;
  input [7:0] expect;
  begin
    uart_send(cmd, data);
    uart_recv(cmd, expect);
  end
endtask

task uart_spi;
  input [7:0] data;
  input [7:0] expect;
  begin
    uart_send(8'h44, data);
  `ASSERT_EQUAL(D.state, D.S_SPI_START, "spi start state")

    `DIAG("Wait for SPI start")
    while(~D.spi_start) @(posedge clk);
    `ASSERT_EQUAL(data, D.spi_tx, "SPI mosi data")
    spi_busy <= 1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    spi_busy <= 0;
    spi_rx   <= expect;

    uart_recv(8'h44, expect);
  end
endtask

initial
begin
  `TEST_INIT(test)

  `ASSERT_EQUAL(D.state, D.S_RESET, "initial state")
  @(D.state);
  `ASSERT_EQUAL(D.state, D.S_IDLE, "idle state")

  `DIAG("set divider")
  uart(8'h43, 42, 42);
  `ASSERT_EQUAL(D.divparam, 42, "divider")
  
  `DIAG("get divider")
  uart(8'h63, 8'hxx, 42);
  `ASSERT_EQUAL(D.divparam, 42, "divider")

  `DIAG("set config")
  uart(8'h58, 8'b00011111, 8'b00011111);
  `ASSERT_EQUAL(D.cpha, 1, "cpha")
  `ASSERT_EQUAL(D.cpol, 1, "cpol")
  `ASSERT_EQUAL(D.genio, 7, "genio")

  `DIAG("set config")
  uart(8'h58, 8'b00011001, 8'b00011001);
  `ASSERT_EQUAL(D.cpha, 0, "cpha")
  `ASSERT_EQUAL(D.cpol, 1, "cpol")
  `ASSERT_EQUAL(D.genio, 6, "genio")

  `DIAG("get config")
  uart(8'h78, 8'hxx, 8'b00011001);
  `ASSERT_EQUAL(D.cpha, 0, "cpha")
  `ASSERT_EQUAL(D.cpol, 1, "cpol")
  `ASSERT_EQUAL(D.genio, 6, "genio")

  `DIAG("set config")
  uart(8'h58, 0, 0);
  `ASSERT_EQUAL(D.cpha, 0, "cpha")
  `ASSERT_EQUAL(D.cpol, 0, "cpol")
  `ASSERT_EQUAL(D.genio, 0, "genio")

  `DIAG("shift SPI data")
  uart_spi(8'hab, 8'hcd);
  uart_spi(8'h19, 8'h28);

  `DIAG("bad command")
  uart_send(8'hba, 8'hdc);
  uart_recv(8'h3f, 8'h3f);

  #8 `TEST_DONE
end

endmodule
