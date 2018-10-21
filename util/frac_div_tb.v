`timescale 1us/1ns
module test;

`include "utest.vlib"

`TEST_PRELUDE(4)

// 25 MHz has 40 nanosecond period
`TEST_CLOCK(clk,0.02);

`TEST_TIMEOUT(200000)

wire clk8, clkbaud;

frac_div
 #(.Width(3),
   .Incr(1)
 )
CLK8(
  .in(clk),
  .out(clk8)
);

// target freq 115200 Hz
//   period 8681 ns
// 25MHz/115200 = 217.013888889
// 2**20/4831   = 217.0515421237839
// 2**22/19327  = 217.01785067522118
frac_div
 #(.Width(22),
   .Incr(19327)
 )
CLKbaud(
  .in(clk),
  .out(clkbaud)
);

initial
begin
  `TEST_INIT(test)

  @(posedge clk8);
  `ASSERT_EQUAL($simtime, 40*8-20, "clk8 tick")

  @(posedge clk8);
  `ASSERT_EQUAL($simtime, 40*16-20, "clk8 tick")

  @(posedge clkbaud);
  `ASSERT_EQUAL($simtime, 8700, "clkbaud tick") // desired 8681

  @(posedge clkbaud);
  `ASSERT_EQUAL($simtime, 17380, "clkbaud tick") // desired 8681*2=17362

  @(posedge clk);
  @(posedge clk);
  `TEST_DONE
end

endmodule
