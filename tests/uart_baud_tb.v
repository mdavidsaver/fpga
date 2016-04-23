module test;

`include "utest.vlib"

`TEST_PRELUDE(0)

// 25 MHz has 40 nanosecond period
`TEST_CLOCK(clk,20);

`TEST_TIMEOUT(200000)

wire samp_clk8, bit_clk64;

uart_baud
 #(.Width(3),
   .Incr(1),
   .D(3)
 )
CLK8(
  .ref_clk(clk),
  .samp_clk(samp_clk8),
  .bit_clk(bit_clk64)
);

initial
begin
  `TEST_INIT(test)

  @(posedge samp_clk8);
  `ASSERT_EQUAL($simtime, 40*8-20)

  @(posedge bit_clk64);
  `ASSERT_EQUAL($simtime, 40*64+20)

  @(posedge clk);
  @(posedge clk);
  `TEST_DONE
end

endmodule
