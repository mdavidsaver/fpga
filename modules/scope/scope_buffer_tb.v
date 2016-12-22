module test;
`include "utest.vlib"

`TEST_PRELUDE(44)

`TEST_CLOCK(clk,2);

`TEST_TIMEOUT(6000)

reg [7:0] sig;
reg       reset = 1, trigger = 0, halt = 0, latch = 0, pop = 0;
reg [2:0] npost;

scope_buffer #(
    .N(8),
    .NSAMP(3) // 2**3 = 8 samples
) DUT (
  .clk(clk),
  .reset(reset),
  .trigger(trigger),
  .halt(halt),
  .npost(npost),
  .din(sig),
  .din_latch(latch),
  .dout_pop(pop)
);

task dpush;
  input [7:0] val;
  input trig;
  begin
    $display("# push %x %x", val, trig);
    sig <= val;
    latch <= 1;
    trigger <= trig;
    @(posedge clk);
    sig <= 8'hxx;
    latch <= 0;
    trigger <= 0;
    @(posedge clk);
  end
endtask

task dpop;
  input [7:0] val;
  begin
    $display("# pop %08x", val);
    pop <= 1;
    @(posedge clk);
    `ASSERT_EQUAL(DUT.dout_ready, 1, "ready")
    `ASSERT_EQUAL(DUT.dout, val, "val")
    pop <= 0;
  end
endtask

initial
begin
  `TEST_INIT(test)

  #10 @(posedge clk);
  reset <= 0;
  npost <= 2;
  #10 @(posedge clk);

  $display("# trigger before first wrap");
  dpush(8'h12, 0); // first sample
  dpush(8'h34, 1);
  dpush(8'h56, 0);
  dpush(8'h78, 0); // last sample
  dpush(8'hab, 0);
  dpush(8'hcd, 0);

  `ASSERT_EQUAL(DUT.rptr, 0, "rptr")
  `ASSERT_EQUAL(DUT.wptr, 4, "wptr")
  `ASSERT_EQUAL(DUT.triggered, 1, "triggered")
  `ASSERT_EQUAL(DUT.done, 1, "done")

  `ASSERT_EQUAL(DUT.mem[0], 8'h12, "mem[0]")
  `ASSERT_EQUAL(DUT.mem[1], 8'h34, "mem[1]")
  `ASSERT_EQUAL(DUT.mem[2], 8'h56, "mem[2]")
  `ASSERT_EQUAL(DUT.mem[3], 8'h78, "mem[3]")

  $display("# readout");
  dpop(8'h12);
  dpop(8'h34);
  dpop(8'h56);
  dpop(8'h78);
  @(posedge clk);
  `ASSERT_EQUAL(DUT.dout_ready, 0, "ready")

  reset <= 1;
  #10 @(posedge clk);
  reset <= 0;
  #10 @(posedge clk);

  $display("# trigger after first wrap");
  dpush(8'h10, 0);
  dpush(8'h11, 0);
  dpush(8'h12, 0);
  dpush(8'h13, 0);
  dpush(8'h14, 0);
  dpush(8'h15, 0);
  dpush(8'h16, 0);
  dpush(8'h17, 0); // first sample
  dpush(8'h18, 0);
  dpush(8'h19, 0);
  dpush(8'h1a, 0);
  dpush(8'h1b, 1);
  dpush(8'h1c, 0);
  dpush(8'h1d, 0); // last sample
  dpush(8'h1e, 0);
  dpush(8'h1f, 0);

  `ASSERT_EQUAL(DUT.rptr, 7, "rptr")
  `ASSERT_EQUAL(DUT.wptr, 6, "wptr")
  `ASSERT_EQUAL(DUT.triggered, 1, "triggered")
  `ASSERT_EQUAL(DUT.done, 1, "done")

  `ASSERT_EQUAL(DUT.mem[6], 8'h16, "mem[6]") // junk
  `ASSERT_EQUAL(DUT.mem[7], 8'h17, "mem[7]") // first sample
  `ASSERT_EQUAL(DUT.mem[0], 8'h18, "mem[0]")
  `ASSERT_EQUAL(DUT.mem[1], 8'h19, "mem[1]")
  `ASSERT_EQUAL(DUT.mem[2], 8'h1a, "mem[2]")
  `ASSERT_EQUAL(DUT.mem[3], 8'h1b, "mem[3]")
  `ASSERT_EQUAL(DUT.mem[4], 8'h1c, "mem[4]")
  `ASSERT_EQUAL(DUT.mem[5], 8'h1d, "mem[5]")

  $display("# readout");
  dpop(8'h17);
  dpop(8'h18);
  dpop(8'h19);
  dpop(8'h1a);
  dpop(8'h1b);
  dpop(8'h1c);
  dpop(8'h1d);
  @(posedge clk);
  `ASSERT_EQUAL(DUT.dout_ready, 0, "ready")

  #8 `TEST_DONE
end

endmodule
