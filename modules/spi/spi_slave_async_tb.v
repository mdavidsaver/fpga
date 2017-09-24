module test;

`include "utest.vlib"

`TEST_PRELUDE(10)

`TEST_TIMEOUT(6000)

`TEST_CLOCK(tclk, 2);

reg sclk, mosi, ss;
wire miso;

reg [0:7] sdat;

spi_slave_async dut(
    .sclk(sclk),
    .miso(miso),
    .mosi(mosi),
    .ss(ss),
    .sdat(sdat)
);

reg [7:0] shift_mosi;
reg [7:0] shift_miso;

always @(posedge tclk)
    if(ss)
        sclk <= ~sclk;
    else
        sclk <= 0;

always @(posedge tclk)
    if(ss & sclk==0)
        {mosi, shift_mosi} <= {shift_mosi, 1'bx};

always @(posedge tclk)
    if(ss & sclk==1)
        shift_miso = {shift_miso[6:0], miso};

initial
begin
  `TEST_INIT(test)

  mosi <= 1'bx;
  ss <= 0;
  @(posedge tclk);
  ss <= 1;
  @(posedge tclk);
  @(posedge tclk);
  @(posedge tclk);
  @(posedge tclk);
  @(posedge tclk);
  @(posedge tclk);


  `ASSERT_EQUAL(dut.state, 3, "transfer in progress")
  ss <= 0;
  @(posedge tclk);
  `ASSERT_EQUAL(dut.state, 0, "transfer in aborted")
  @(posedge tclk);

  ss <= 1;
  shift_mosi <= 8'hff;
  shift_miso <= 8'hxx;

  while(~dut.ready) @(posedge dut.clk);
  `ASSERT_EQUAL(dut.mdat, 8'hff, "Master data")
  `ASSERT_EQUAL(shift_miso, 8'hxx, "Slave data")
  shift_miso <= 8'hxx;

  shift_mosi <= 8'h00;
  sdat <= 8'h00;

  while(dut.ready) @(posedge dut.clk);
  sdat <= 8'hxx;
  while(~dut.ready) @(posedge dut.clk);
  `ASSERT_EQUAL(dut.mdat, 8'h00, "Master data")
  `ASSERT_EQUAL(shift_miso, 8'h00, "Slave data")
  shift_miso <= 8'hxx;

  shift_mosi <= 8'ha2;
  sdat <= 8'h71;

  while(dut.ready) @(posedge dut.clk);
  sdat <= 8'hxx;
  while(~dut.ready) @(posedge dut.clk);
  `ASSERT_EQUAL(dut.mdat, 8'ha2, "Master data")
  `ASSERT_EQUAL(shift_miso, 8'h71, "Slave data")
  shift_miso <= 8'hxx;

  shift_mosi <= 8'h41;
  sdat <= 8'h32;

  while(dut.ready) @(posedge dut.clk);
  sdat <= 8'hxx;
  while(~dut.ready) @(posedge dut.clk);
  `ASSERT_EQUAL(dut.mdat, 8'h41, "Master data")
  `ASSERT_EQUAL(shift_miso, 8'h32, "Slave data")
  shift_miso <= 8'hxx;


  #8 `TEST_DONE
end

endmodule
