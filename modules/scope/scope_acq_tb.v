`timescale 1us/1ns
module test;
`include "utest.vlib"

`TEST_PRELUDE(44)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(6000)

reg [7:0] sig;
reg       trig;
reg       change;

wire [7:0] din;
reg [7:0] dout;
reg drequest = 0, select = 0;

scope_acq #(
  .NSIG(8),
  .NSAMP(3), // 2**3 == 8
  .NTIME(7)
) DUT (
  .clk(clk),
  .sig(sig),
  .select(select),
  .din(din),
  .dout(dout),
  .drequest(drequest)
);

task dshift;
  input [7:0] ival;
  begin
    $display("# dshift <- %x", ival);
    dout     <= ival;
    drequest <= 1;
    @(posedge clk);
    drequest <= 0;
    @(posedge clk);
  end
endtask

initial
begin
  `TEST_INIT(test)
  `ASSERT_EQUAL(DUT.NBYTES, 2, "NBYTES")
  `ASSERT_EQUAL(DUT.NBITS,  16, "NBYTES")
  #10 @(posedge clk);
  
  $display("# reset");
  select <= 1;
  dshift(8'h28);
  select <= 0;
  @(posedge clk);

  $display("# ID");
  select <= 1;
  dshift(8'h11);
  `ASSERT_EQUAL(din, 8'h53, "ID")
  select <= 0;
  @(posedge clk);

  $display("# INSP");
  select <= 1;
  dshift(8'h12);
  `ASSERT_EQUAL(din[3:0], 8, "NSIG")
  `ASSERT_EQUAL(din[7:4], 7, "NTIME")
  select <= 0;
  @(posedge clk);

  $display("# MEM");
  select <= 1;
  dshift(8'h13);
  `ASSERT_EQUAL(din, 3, "NSAMP")
  select <= 0;
  @(posedge clk);

  $display("# STS");
  select <= 1;
  dshift(8'h14);
  `ASSERT_EQUAL(din, 8'h00, "STS")
  select <= 0;
  @(posedge clk);

  $display("# set to trigger on count==5");
  select <= 1;
  dshift(8'h40); // ch 0 level 1
  dshift(8'h03);
  dshift(8'h41); // ch 1 level 0
  dshift(8'h02);
  dshift(8'h42); // ch 2 level 1
  dshift(8'h03);
  dshift(8'h43); // ch 3 level 0
  dshift(8'h02);
  dshift(8'h44); // ch 4 level 0
  dshift(8'h02);
  dshift(8'h45); // ch 5 level 0
  dshift(8'h02);
  dshift(8'h46); // ch 6 level 0
  dshift(8'h02);
  dshift(8'h47); // ch 7 level 0
  dshift(8'h02);
  select <= 0;
  @(posedge clk);

  `ASSERT_EQUAL(DUT.trig_conf[0 +: 3], 3'b011, "CH 0")
  `ASSERT_EQUAL(DUT.trig_conf[3 +: 3], 3'b010, "CH 1")
  `ASSERT_EQUAL(DUT.trig_conf[6 +: 3], 3'b011, "CH 2")
  `ASSERT_EQUAL(DUT.trig_conf[9 +: 3], 3'b010, "CH 3")
  `ASSERT_EQUAL(DUT.trig_conf[12 +: 3], 3'b010, "CH 4")
  `ASSERT_EQUAL(DUT.trig_conf[15 +: 3], 3'b010, "CH 5")
  `ASSERT_EQUAL(DUT.trig_conf[18 +: 3], 3'b010, "CH 6")
  `ASSERT_EQUAL(DUT.trig_conf[21 +: 3], 3'b010, "CH 7")

  $display("# npost");
  select <= 1;
  dshift(8'h15);
  dshift(8'h02); // 2 samples
  select <= 0;
  @(posedge clk);

  `ASSERT_EQUAL(DUT.npost, 2, "npost")

  $display("# switch to counter/test input");
  select <= 1;
  dshift(8'h31); // use sim
  select <= 0;
  @(posedge clk);

  $display("# reset");
  select <= 1;
  dshift(8'h28); // reset and use sim
  select <= 0;
  @(posedge clk);

  $display("# Wait for complete");
  while(~DUT.BUF.done) @(posedge clk);
  $display("# done");

  $display("# STS");
  select <= 1;
  dshift(8'h14);
  `ASSERT_EQUAL(din, 8'h07, "STS") // ready, triggered, and done
  select <= 0;
  @(posedge clk);

  $display("# Readout");
  select <= 1;
  dshift(8'h14);
  `ASSERT_EQUAL(din, 8'h07, "data 0")
  dshift(8'hxx);
  `ASSERT_EQUAL(din, 8'h07, "data 1")
  select <= 0;
  @(posedge clk);


  #10 @(posedge clk);
  #8 `TEST_DONE
end

endmodule
