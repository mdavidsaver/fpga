module test;
`include "utest.vlib"

`TEST_PRELUDE(21)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(6000)

reg [7:0] sig = 0;

reg [23:0] conf = 0;

scope_trigger #(
  .NSIG(8)
) DUT (
  .clk(clk),
  .sig(sig),
  .conf(conf)
);

initial
begin
  `TEST_INIT(test)
  #10 @(posedge clk);

  $display("# To change detect");
  `ASSERT_EQUAL(DUT.triggered, 0, "triggered")
  `ASSERT_EQUAL(DUT.changed, 0, "changed")
  `ASSERT_EQUAL(DUT.sigout[0], 0, "sigout")

  sig[0] <= 1;
  while(~DUT.changed) @(posedge clk);
  `ASSERT_EQUAL(DUT.triggered, 0, "triggered")
  `ASSERT_EQUAL(DUT.changed, 1, "changed")
  `ASSERT_EQUAL(DUT.sigout[0], 1, "sigout")

  while(DUT.changed) @(posedge clk);

  sig[0] <= 0;
  while(~DUT.changed) @(posedge clk);
  `ASSERT_EQUAL(DUT.triggered, 0, "triggered")
  `ASSERT_EQUAL(DUT.changed, 1, "changed")
  `ASSERT_EQUAL(DUT.sigout[0], 0, "sigout")

  $display("# Test trigger");

  $display("# rising edge");
  conf[1:0] <= 2;
  conf[2]   <= 1;

  sig[0] <= 1;
  while(~DUT.triggered) @(posedge clk);
  `ASSERT_EQUAL(DUT.triggered, 1, "triggered")
  `ASSERT_EQUAL(DUT.changed, 1, "changed")
  `ASSERT_EQUAL(DUT.sigout[0], 1, "sigout")

  while(DUT.triggered) @(posedge clk);

  $display("# falling edge");
  conf[1:0] <= 2;
  conf[2]   <= 0;

  sig[0] <= 0;
  while(~DUT.triggered) @(posedge clk);
  `ASSERT_EQUAL(DUT.triggered, 1, "triggered")
  `ASSERT_EQUAL(DUT.changed, 1, "changed")
  `ASSERT_EQUAL(DUT.sigout[0], 0, "sigout")

  while(DUT.triggered) @(posedge clk);

  $display("# high level");
  conf[1:0] <= 1;
  conf[2]   <= 1;

  sig[0] <= 1;
  while(~DUT.triggered) @(posedge clk);
  `ASSERT_EQUAL(DUT.triggered, 1, "triggered")
  `ASSERT_EQUAL(DUT.changed, 1, "changed")
  `ASSERT_EQUAL(DUT.sigout[0], 1, "sigout")

  $display("# low level");
  conf[1:0] <= 1;
  conf[2]   <= 0;

  while(DUT.triggered) @(posedge clk);

  sig[0] <= 0;
  while(~DUT.triggered) @(posedge clk);
  `ASSERT_EQUAL(DUT.triggered, 1, "triggered")
  `ASSERT_EQUAL(DUT.changed, 1, "changed")
  `ASSERT_EQUAL(DUT.sigout[0], 0, "sigout")

  while(DUT.triggered) @(posedge clk);

  #8 `TEST_DONE
end

endmodule
