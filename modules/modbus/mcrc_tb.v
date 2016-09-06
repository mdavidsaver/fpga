module test;

`include "utest.vlib"

`TEST_PRELUDE(12)

`TEST_CLOCK(clk,10);

`TEST_TIMEOUT(20000)

reg reset=1, ready=0;
reg [7:0] din;

mcrc dut(
  .clk(clk),
  .reset(reset),
  .ready(ready),
  .din(din)
);

task push;
  input [7:0] val;
  input [15:0] expect;
  begin
    $display("# shift x", val);
    @(negedge clk)
    din <= val;
    ready <= 1;
    @(negedge clk)
    din <= 8'hxx;
    ready <= 0;
    @(negedge clk)
    `ASSERT_EQUAL(dut.crc, expect, "CRC")
  end
endtask

initial
begin
  `TEST_INIT(test)

  @(posedge clk)
  reset <= 0;
  @(posedge clk)

  `ASSERT_EQUAL(dut.crc, 16'hFFFF, "Initial")

  push(8'hFF, 16'h00FF);
  push(8'hFF, 16'h0000);
  push(8'hFF, 16'h4040);

  reset <= 1;
  @(negedge clk)
  reset <= 0;

  push(8'h00, 16'h40bf);
  push(8'h00, 16'hb001);
  push(8'h00, 16'hc071);

  reset <= 1;
  @(negedge clk)
  reset <= 0;

  `ASSERT_EQUAL(dut.crc, 16'hFFFF, "Initial")

  push(8'hde, 16'h183F);
  push(8'had, 16'had99);
  push(8'hbe, 16'h1aed);
  push(8'hef, 16'hc19b);

  `TEST_DONE
end

endmodule
