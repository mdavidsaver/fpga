module test;

`include "utest.vlib"

`TEST_PRELUDE(0)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(200)

reg din, reset=1;
reg [7:0] expect;

wire ready;
wire [7:0] data;

uart_rx D(
  .clk(clk),
  .reset(reset),
  .in(din),
  .ready(ready),
  .out(data)
);

`define TICK @(posedge clk); @(negedge clk);

`define CHECK(MSG,R,D) `DIAG(MSG) `ASSERT_EQUAL(R,ready) `ASSERT_EQUAL(D,data[0])

task uart_recv;
  input [7:0] val;
  begin
    `DIAG("uart_recv")
    expect = val;
    din = 1;
    @(negedge clk);
    din = val[0];
    @(negedge clk);
    din = val[1];
    @(negedge clk);
    din = val[2];
    @(negedge clk);
    din = val[3];
    @(negedge clk);
    din = val[4];
    @(negedge clk);
    din = val[5];
    @(negedge clk);
    din = val[6];
    @(negedge clk);
    din = val[7];
    @(negedge clk);
    din = 0;
    @(negedge clk);
    `ASSERT_EQUAL(1, ready)
    `ASSERT_EQUAL(expect, data)
  end
endtask

initial
begin
  `TEST_INIT(test)

  `TICK
  `TICK
  `CHECK("Reset",0,0)
  reset = 0;
  din = 0;
  `TICK
  `TICK
  `CHECK("Idle",0,0)
  uart_recv(8'b10101100);

  din = 0;
  `TICK
  `TICK
  `CHECK("Idle",0,0)
  uart_recv(8'b10010011);
  uart_recv(8'b01001101);
  
  `TEST_DONE
end

endmodule
