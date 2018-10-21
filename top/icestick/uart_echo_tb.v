`timescale 1us/1ns
module test;

`include "utest.vlib"

`TEST_PRELUDE(6)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(10000)

reg send = 0, reset = 1;
wire txbusy, rline, ready, tx_bit_clk, rx_bit_clk, samp_clk;
wire [7:0] drx;
reg [7:0] dtx;
reg [7:0] expect;
reg [7:0] actual;

uart #(
  .Width(2),
  .Incr(1)
)D(
  .reset(reset),
  .clk(clk),

  .rin(rline),
  .rout(rline),

  .din(dtx),
  .send(send),
  .txbusy(txbusy),

  .dout(drx),
  .ready(ready),

  .samp_clk(samp_clk),
  .rx_bit_clk(rx_bit_clk),
  .tx_bit_clk(tx_bit_clk)
);

`define TICK @(posedge tx_bit_clk); @(negedge tx_bit_clk);
`define CHECK(MSG, D,O) `DIAG(MSG) `ASSERT_EQUAL(done,D,"done") `ASSERT_EQUAL(out,O,"out")

task uart_txrx;
  input [7:0] val;
  begin
    $display("uart_txrx %x", val);

    dtx  <= val;
    send <= 1;
    @(posedge txbusy);
    dtx  <= 8'hxx;
    send <= 0;

    @(posedge ready);
    `ASSERT_EQUAL(val, drx, "drx")
  end
endtask

initial
begin
  `TEST_INIT(test)

  #16
  reset = 0;
  `TICK
  `TICK
  `ASSERT_EQUAL(0, txbusy, "txbusy")
  `ASSERT_EQUAL(0, ready, "ready")

  uart_txrx(8'b10101001);
  uart_txrx(8'b10011001);
  #1001
  uart_txrx(8'b10110001);
  uart_txrx(8'b11101010);
  
  `TICK
  `TICK
  `TEST_DONE
end

endmodule
