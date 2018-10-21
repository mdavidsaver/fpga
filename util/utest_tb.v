`timescale 1us/1ns
module test;

`include "utest.vlib"

`TEST_PRELUDE(4)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(200)

reg foo;

initial
begin
  `TEST_INIT(test)
  foo = 1;
  `ASSERT_EQUAL(foo, 1, "foo == 1")
  `ASSERT(foo>0, "foo>0")

  #10
  foo = 0;
  `ASSERT_EQUAL(foo, 0, "foo == 0")
  `ASSERT(foo==0, "foo==0")

  #5
  `TEST_DONE
end

endmodule
