module test;

`include "utest.vlib"

`TEST_PRELUDE(6)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(2000)

reg [2:0] clk8_cnt = 0;

always @(posedge clk)
  clk8_cnt <= clk8_cnt+1;

wire clk8 = clk8_cnt[2];

reg send = 0, reset = 1;
reg [7:0] in = 0;
wire done, dcon1, dcon2, ready;
wire [7:0] dout;

uart_tx TX(
  .clk(clk8),
  .send(send),
  .in(in),
  .done(done),
  .out(dcon1)
);

uart_rx_filter RXF(
  .bit_clk(clk8),
  .samp_clk(clk),
  .in(dcon1),
  .out(dcon2)
);

uart_rx RX(
  .clk(clk8),
  .reset(reset),
  .in(dcon2),
  .ready(ready),
  .out(dout)
);

`define TICK @(posedge clk8); @(negedge clk8);

task uart_txrx;
  input [7:0] val;
  begin
    $display("uart_txrx(%x)", val);
    @(negedge clk);
    in = val;
    send = 1;
    @(posedge done);
    `DIAG("sent")
    send = 0;
    @(posedge ready);
    `DIAG("ready")
    `ASSERT_EQUAL(val, dout)
  end
endtask

initial
begin
  `TEST_INIT(test)

  `TICK
  `TICK
  reset = 0;
  `TICK
  `TICK
  `ASSERT_EQUAL(0, done)
  `ASSERT_EQUAL(0, ready)

  uart_txrx(8'b10101001);
  uart_txrx(8'b10011001);
  uart_txrx(8'b10110001);
  uart_txrx(8'b11101010);
  
  `TICK
  `TICK
  `TEST_DONE
end

endmodule

