`timescale 1us/1ns
module test;

`include "utest.vlib"

`TEST_PRELUDE(8)

`TEST_TIMEOUT(6000)

`TEST_CLOCK(clk, 4);

reg reset = 1;

spi_master_ctrl #(
    .BYTES(2)
) ctrl(
    .clk(clk),
    .reset(reset)
);

reg [15:0] mdat; // master to send

spi_master_inst #(
    .BYTES(2)
) inst(
    .clk(clk),
    .reset(reset),
    .cnt(ctrl.cnt),
    .miso(tester.miso),
    .mdat(mdat)
);

reg [7:0] sdat; // slave to send

spi_slave_async tester(
    .ss(ctrl.ss),
    .sclk(ctrl.sclk),
    .mosi(inst.mosi),
    .sdat(sdat)
);

initial
begin
  `TEST_INIT(test)

  @(posedge clk);
  @(posedge clk);
  reset <= 0;
  @(posedge clk);
  @(posedge clk);
  @(posedge clk);
  @(posedge clk);
  @(posedge clk);
  @(posedge clk);

  `ASSERT_EQUAL(ctrl.cnt, 5, "in progress")
  reset <= 1;
  @(posedge clk);
  @(posedge clk);
  `ASSERT_EQUAL(ctrl.cnt, 0, "aborted")

  reset <= 0;
  mdat <= 16'habcd;
  while (~ctrl.ready) @(posedge clk);
  `ASSERT_EQUAL(inst.sdat, 16'hxx78, "From slave 1")
  mdat <= 16'h5070;
  while (ctrl.ready) @(posedge clk);

  while (~ctrl.ready) @(posedge clk);
  `ASSERT_EQUAL(inst.sdat, 16'ha1b3, "From slave 2")
  mdat <= 16'hxxxx;
  while (ctrl.ready) @(posedge clk);

  #8 `TEST_DONE
end

initial
begin
  // wait until out of first reset
  @(posedge clk);
  @(posedge clk);
  @(posedge clk);

  while (~tester.ready) @(posedge tester.clk);
  `ASSERT_EQUAL(tester.mdat, 16'hab, "From master 1")
  sdat <= 8'h78;
  while (tester.ready) @(posedge tester.clk);
  sdat <= 8'hxx;

  while (~tester.ready) @(posedge tester.clk);
  `ASSERT_EQUAL(tester.mdat, 16'hcd, "From master 2")
  sdat <= 8'ha1;
  while (tester.ready) @(posedge tester.clk);
  sdat <= 8'hxx;

  while (~tester.ready) @(posedge tester.clk);
  `ASSERT_EQUAL(tester.mdat, 16'h50, "From master 1")
  sdat <= 8'hb3;
  while (tester.ready) @(posedge tester.clk);
  sdat <= 8'hxx;

  while (~tester.ready) @(posedge tester.clk);
  `ASSERT_EQUAL(tester.mdat, 16'h70, "From master 2")
  sdat <= 8'h34;
  while (tester.ready) @(posedge tester.clk);
  sdat <= 8'hxx;

end

endmodule
