module test;

`include "utest.vlib"

`TEST_PRELUDE(6)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(10000)

reg clk8_enable = 1;
reg [3:0] clk8_cnt = 0;

always @(posedge clk)
  if(clk8_enable)
    clk8_cnt <= clk8_cnt[2:0]+1;

wire clk8 = clk8_cnt[3];

reg send = 0, reset = 1;
reg [7:0] in = 0;
wire done, dloop, ready;
wire [7:0] dout;

uart #(
  .Width(2),
  .Incr(1)
)D(
  .reset(reset),
  .clk(clk),

  .rin(dloop),
  .rout(dloop),

  .din(in),
  .send(send),
  .done(done),

  .dout(dout),
  .ready(ready)
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
  clk8_enable = 0;
  #101
  clk8_enable = 1;
  uart_txrx(8'b10110001);
  uart_txrx(8'b11101010);
  
  `TICK
  `TICK
  `TEST_DONE
end

endmodule

