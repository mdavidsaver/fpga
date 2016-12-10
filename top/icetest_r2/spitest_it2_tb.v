module test;
`include "utest.vlib"

`TEST_PRELUDE(29)

`TEST_CLOCK(clk,1);


reg [1:0] clk4_cnt = 0;
reg clk4;

always @(posedge clk)
  {clk4, clk4_cnt} <= clk4_cnt+1;


`TEST_TIMEOUT(6000)

reg mselect = 1; // active low
wire mclk, mosi, miso;

top DUT(
  .clk(clk),
  .mselect(mselect),
  .mclk(mclk),
  .mosi(mosi),
  .miso(miso)
);

reg [7:0] din;
reg start = 0;

spi_master DRV(
  .ref_clk(clk),
  .bit_clk2(clk4),

  .cpol(0),
  .cpha(0),

  .mclk(mclk),
  .mosi(mosi),
  .miso(miso),

  .din(din),
  .start(start)
);

task spiout;
  input [7:0] inp;
  begin
    @(posedge clk);
    din <= inp;
    start <= 1;

    while(~DRV.busy) @(posedge clk);
    din <= 8'hxx;
    start <= 0;

    while(DRV.busy) @(posedge clk);
  end
endtask

initial
begin
  `TEST_INIT(test)

  #10 @(posedge clk);
  mselect <= 0;

  $display("Command echo");
  #6 spiout(8'h11);
  `ASSERT_EQUAL(DUT.state, DUT.S_IDLE, "Accepted echo command")

  $display("Command byte 0x42");
  #10 spiout(8'h42);
  `ASSERT_EQUAL(DUT.state, DUT.S_ECHO, "Accepted echo 1")

  `ASSERT_EQUAL(DRV.dout, 8'h22, "Echo cmd ack")

  $display("Command byte 0x43");
  #10 spiout(8'h43);
  `ASSERT_EQUAL(DUT.state, DUT.S_ECHO, "Accepted echo 2")

  `ASSERT_EQUAL(DRV.dout, 8'h42, "Byte 1")

  $display("Command byte 0x43");
  #10 spiout(8'h44);
  `ASSERT_EQUAL(DUT.state, DUT.S_ECHO, "Accepted echo 2")

  `ASSERT_EQUAL(DRV.dout, 8'h43, "Byte 2)

  mselect <= 1;
  #10 @(posedge clk);
  `ASSERT_EQUAL(DUT.state, DUT.S_IDLE, "IDLE")
  
  mselect <= 0;

  $display("Command mem write");
  #6 spiout(8'h12);
  `ASSERT_EQUAL(DUT.state, DUT.S_IDLE, "Accepted write command")
  #10 spiout(8'h04);
  `ASSERT_EQUAL(DUT.state, DUT.S_WRITE_ADDR, "in addr state")
  #10 spiout(8'hab);
  `ASSERT_EQUAL(DUT.state, DUT.S_WRITE_DATA, "in data state")
  #10 spiout(8'hcd);
  `ASSERT_EQUAL(DUT.state, DUT.S_WRITE_DATA, "in data state")
  #10 spiout(8'hef);

  mselect <= 1;
  #10 @(posedge clk);
  `ASSERT_EQUAL(DUT.state, DUT.S_IDLE, "IDLE")
  
  `ASSERT_EQUAL(DUT.ram[3], 8'hxx, "ram[3]")
  `ASSERT_EQUAL(DUT.ram[4], 8'hab, "ram[4]")
  `ASSERT_EQUAL(DUT.ram[5], 8'hcd, "ram[5]")
  `ASSERT_EQUAL(DUT.ram[6], 8'hxx, "ram[6]")

  mselect <= 0;

  $display("Command mem read");
  #6 spiout(8'h13);
  `ASSERT_EQUAL(DUT.state, DUT.S_IDLE, "Accepted read command")
  #10 spiout(8'h03);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_ADDR, "in addr state")
  #10 spiout(8'hxx);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_DATA, "in data state")
  `ASSERT_EQUAL(DRV.dout, 8'hxx, "junk")
  #10 spiout(8'hxx);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_DATA, "in data state")
  `ASSERT_EQUAL(DRV.dout, 8'hxx, "ram[3]")
  #10 spiout(8'hxx);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_DATA, "in data state")
  `ASSERT_EQUAL(DRV.dout, 8'hab, "ram[4]")
  #10 spiout(8'hxx);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_DATA, "in data state")
  `ASSERT_EQUAL(DRV.dout, 8'hcd, "ram[5]")
  #10 spiout(8'hxx);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_DATA, "in data state")
  `ASSERT_EQUAL(DRV.dout, 8'hxx, "ram[6]")

  mselect <= 1;
  #10 @(posedge clk);
  `ASSERT_EQUAL(DUT.state, DUT.S_IDLE, "IDLE")

  #8 `TEST_DONE
end

endmodule
