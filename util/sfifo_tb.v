`timescale 1us/1ns
module test;

`include "utest.vlib"

`TEST_PRELUDE(52)

`TEST_CLOCK(clk,10);

`TEST_TIMEOUT(200000)

reg reset = 1, store=0, read=0;

reg [7:0] wdata;

sfifo #(
  .WIDTH(8),
  .DEPTH(2)  // 4 entries
) dut (
  .reset(reset),
  .clk(clk),
  .store(store),
  .read(read),
  .wdata(wdata)
);

task push;
  input [7:0] val;
  begin
    $display("# push %02x", val);
    while(~clk) @(posedge clk);
    store <= 1;
    wdata <= val;
    @(posedge clk);
    store <= 0;
    wdata <= 8'hxx;
  end
endtask

task pop;
  input [7:0] exp;
  begin
    $display("# pop %02x", exp);
    while(~clk) @(posedge clk);
    read <= 1;
    @(posedge clk);
    read <= 0;
    `ASSERT_EQUAL(dut.rdata, exp, "read elem")
  end
endtask

task pushpop;
  input [7:0] val;
  input [7:0] exp;
  begin
    $display("# push %02x, pop %02x", val, exp);
    while(~clk) @(posedge clk);
    store <= 1;
    wdata <= val;
    read <= 1;
    @(posedge clk);
    store <= 0;
    wdata <= 8'hxx;
    read <= 0;
    `ASSERT_EQUAL(dut.rdata, exp, "read elem")
  end
endtask

initial
begin
  `TEST_INIT(test)

  @(posedge clk);
  @(posedge clk);
  reset <= 0;
  @(posedge clk);
  @(posedge clk);

  $display("# T %d", $simtime);
  `ASSERT_EQUAL(dut.empty, 1, "empty")
  `ASSERT_EQUAL(dut.full,  0, "full")
  `ASSERT_EQUAL(dut.rpos, 0, "rpos")
  `ASSERT_EQUAL(dut.wpos, 0, "wpos")

  push(8'h12);

  @(posedge clk);
  $display("# T %d", $simtime);
  `ASSERT_EQUAL(dut.empty, 0, "empty")
  `ASSERT_EQUAL(dut.full,  0, "full")
  `ASSERT_EQUAL(dut.rpos, 0, "rpos")
  `ASSERT_EQUAL(dut.wpos, 1, "wpos")
  `ASSERT_EQUAL(dut.buffer[0], 8'h12, "buffer[0]")

  push(8'h34);
  push(8'h56);

  @(posedge clk);
  $display("# T %d", $simtime);
  `ASSERT_EQUAL(dut.empty, 0, "empty")
  `ASSERT_EQUAL(dut.full,  1, "full")
  `ASSERT_EQUAL(dut.rpos, 0, "rpos")
  `ASSERT_EQUAL(dut.wpos, 3, "wpos")
  `ASSERT_EQUAL(dut.buffer[0], 8'h12, "buffer[0]")
  `ASSERT_EQUAL(dut.buffer[1], 8'h34, "buffer[1]")
  `ASSERT_EQUAL(dut.buffer[2], 8'h56, "buffer[2]")

  pop(8'h12);
  pop(8'h34);
  pop(8'h56);

  @(posedge clk);
  $display("# T %d", $simtime);
  `ASSERT_EQUAL(dut.empty, 1, "empty")
  `ASSERT_EQUAL(dut.full,  0, "full")
  `ASSERT_EQUAL(dut.rpos, 3, "rpos")
  `ASSERT_EQUAL(dut.wpos, 3, "wpos")
  `ASSERT_EQUAL(dut.buffer[0], 8'h12, "buffer[0]")
  `ASSERT_EQUAL(dut.buffer[1], 8'h34, "buffer[1]")
  `ASSERT_EQUAL(dut.buffer[2], 8'h56, "buffer[2]")

  push(8'h78);
  pushpop(8'h9a, 8'h78);

  @(posedge clk);
  $display("# T %d", $simtime);
  `ASSERT_EQUAL(dut.empty, 0, "empty")
  `ASSERT_EQUAL(dut.full,  0, "full")
  `ASSERT_EQUAL(dut.rpos, 0, "rpos")
  `ASSERT_EQUAL(dut.wpos, 1, "wpos")
  `ASSERT_EQUAL(dut.buffer[0], 8'h9a, "buffer[0]")
  `ASSERT_EQUAL(dut.buffer[1], 8'h34, "buffer[1]")
  `ASSERT_EQUAL(dut.buffer[2], 8'h56, "buffer[2]")
  `ASSERT_EQUAL(dut.buffer[3], 8'h78, "buffer[3]")

  pop(8'h9a);
  push(8'hbc);
  push(8'hde);
  push(8'hf0);

  @(posedge clk);
  $display("# T %d", $simtime);
  `ASSERT_EQUAL(dut.empty, 0, "empty")
  `ASSERT_EQUAL(dut.full,  1, "full")
  `ASSERT_EQUAL(dut.rpos, 1, "rpos")
  `ASSERT_EQUAL(dut.wpos, 0, "wpos")
  `ASSERT_EQUAL(dut.buffer[0], 8'h9a, "buffer[0]")
  `ASSERT_EQUAL(dut.buffer[1], 8'hbc, "buffer[1]")
  `ASSERT_EQUAL(dut.buffer[2], 8'hde, "buffer[2]")
  `ASSERT_EQUAL(dut.buffer[3], 8'hf0, "buffer[3]")

  reset <= 1;
  @(posedge clk);
  reset <= 0;
  
  @(posedge clk);
  $display("# T %d", $simtime);
  `ASSERT_EQUAL(dut.empty, 1, "empty")
  `ASSERT_EQUAL(dut.full,  0, "full")
  `ASSERT_EQUAL(dut.rpos, 0, "rpos")
  `ASSERT_EQUAL(dut.wpos, 0, "wpos")
  `ASSERT_EQUAL(dut.buffer[0], 8'h9a, "buffer[0]")
  `ASSERT_EQUAL(dut.buffer[1], 8'hbc, "buffer[1]")
  `ASSERT_EQUAL(dut.buffer[2], 8'hde, "buffer[2]")
  `ASSERT_EQUAL(dut.buffer[3], 8'hf0, "buffer[3]")

  `TEST_DONE
end

endmodule
