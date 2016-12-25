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
  `ASSERT_EQUAL(din, 8'haa, "ID")
  select <= 0;
  @(posedge clk);

  $display("# STS");
  select <= 1;
  dshift(8'h12);
  `ASSERT_EQUAL(din, 8'h00, "STS")
  select <= 0;
  @(posedge clk);

  $display("# config");
  select <= 1;
  dshift(8'b10100010); // ch 0 level 0
  dshift(8'b10101011); // ch 1 level 1
  select <= 0;
  @(posedge clk);

  `ASSERT_EQUAL(DUT.trig_conf[0 +: 3], 3'b010, "CH 0")
  `ASSERT_EQUAL(DUT.trig_conf[3 +: 3], 3'b011, "CH 1")

  $display("# npost");
  select <= 1;
  dshift(8'h32); // 2 samples
  select <= 0;
  @(posedge clk);

  $display("# reset and start");
  select <= 1;
  dshift(8'h2c); // reset and use sim
  select <= 0;
  @(posedge clk);

  $display("# Wait for complete");
  while(~DUT.BUF.done) @(posedge clk);
  $display("# done");

  $display("# STS");
  select <= 1;
  dshift(8'h12);
  `ASSERT_EQUAL(din, 8'h07, "STS") // ready, triggered, and done
  select <= 0;
  @(posedge clk);


  #10 @(posedge clk);
  #8 `TEST_DONE
end

endmodule
