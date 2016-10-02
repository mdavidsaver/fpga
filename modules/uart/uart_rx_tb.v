module test;

`include "utest.vlib"

`TEST_PRELUDE(12)

`TEST_CLOCK(clk,10);

`TEST_TIMEOUT(200000)

reg [3:0] clk8_cnt = 0;
always @(posedge clk)
  clk8_cnt <= clk8_cnt[2:0]+1;

wire clk8 = clk8_cnt[3];

reg [3:0] clk64_cnt = 0;
always @(posedge clk)
  if(clk8)
    clk64_cnt <= clk64_cnt[2:0]+1;

wire clk64 = clk8 & clk64_cnt[3];

reg din, reset=1;
reg [7:0] expect;

wire ready, bit_clk;
wire [7:0] data;

uart_rx #(
  .Oversample(3) // 8 samples per bit
) D(
  .ref_clk(clk),
  .samp_clk(clk8),
  .reset(reset),
  .in(din),
  .ready(ready),
  .bit_clk(bit_clk),
  .out(data)
);

`define TICK @(posedge clk8); @(negedge clk8);

`define CHECK(MSG,R,D) `DIAG(MSG) `ASSERT_EQUAL(R,ready,"ready") `ASSERT_EQUAL(D,data[0],"data[0]")

task uart_recv;
  input [7:0] val;
  begin
    $display("# uart_recv %02x", val);
    clk64_cnt = 0;
    expect = val;
    din = 1;
    while(~clk64) @(posedge clk);
    din = ~val[0];
    @(negedge clk64);
    while(~clk64) @(posedge clk);
    din = ~val[1];
    @(negedge clk64);
    while(~clk64) @(posedge clk);
    din = ~val[2];
    @(negedge clk64);
    while(~clk64) @(posedge clk);
    din = ~val[3];
    @(negedge clk64);
    while(~clk64) @(posedge clk);
    din = ~val[4];
    @(negedge clk64);
    while(~clk64) @(posedge clk);
    din = ~val[5];
    @(negedge clk64);
    while(~clk64) @(posedge clk);
    din = ~val[6];
    @(negedge clk64);
    while(~clk64) @(posedge clk);
    din = ~val[7];
    @(negedge clk64);
    while(~clk64) @(posedge clk);
    din = 0;
    `DIAG("Wait for ready")
    while(~ready) @(posedge clk);
    `ASSERT_EQUAL(expect, data, "expect == data")
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

  #1330 @(posedge clk);
  uart_recv(8'h12);

  #1330 @(posedge clk);
  uart_recv(8'b10101010);

  #1330 @(posedge clk);
  uart_recv(8'b01010101);
  `TEST_DONE
end

endmodule
