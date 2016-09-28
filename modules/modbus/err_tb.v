module test;

`include "utest.vlib"
`define TMOMAX 8'h30
`include "mtest.vlib"

`TEST_PRELUDE(5)

`TEST_CLOCK(clk,10);

`TEST_TIMEOUT(10000)

initial
begin
  `TEST_INIT(test)
  @(posedge clk);
  reset <= 0;
  @(posedge clk);

  $display("# Invalid function");
  mod_rx_msg(5, 4, 16'h1234, 16'h0001);
  while(~dut.frame_err) @(posedge clk);
  $display("# Error");
  while(dut.frame_err) @(posedge clk);
  `ASSERT(1, "Reset")

  $display("# Unaligned read");
  mod_rx_msg(5, 3, 16'h1235, 16'h0001);
  while(~dut.frame_err) @(posedge clk);
  $display("# Error");
  while(dut.frame_err) @(posedge clk);
  `ASSERT(1, "Reset")

  $display("# Unaligned write");
  mod_rx_msg(5, 6, 16'h1235, 16'h0001);
  while(~dut.frame_err) @(posedge clk);
  $display("# Error");
  while(dut.frame_err) @(posedge clk);
  `ASSERT(1, "Reset")

  $display("# too large read");
  mod_rx_msg(5, 3, 16'h1234, 16'h0081);
  while(~dut.frame_err) @(posedge clk);
  $display("# Error");
  while(dut.frame_err) @(posedge clk);
  `ASSERT(1, "Reset")

  $display("# too large read again");
  mod_rx_msg(5, 3, 16'h1234, 16'h0101);
  while(~dut.frame_err) @(posedge clk);
  $display("# Error");
  while(dut.frame_err) @(posedge clk);
  `ASSERT(1, "Reset")

  #4
  `TEST_DONE
end

endmodule
