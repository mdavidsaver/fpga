module test;

`include "utest.vlib"

`TEST_PRELUDE(7)

`TEST_TIMEOUT(6000)

reg sclk, mosi, ss;
wire miso;

reg [0:7] outdat;
reg [0:7] indat;

reg [0:7] tsdat;
reg [0:7] tmdat;

task spi_xfer;
  input [0:7] in;
  output [0:7] out;
  begin
    $display("# spi_xfer start in=%x", in);
    #2 mosi <= in[0];
    sclk <= 1;
    #2 sclk <= 0;
    out[0] <= miso;

    #2 mosi <= in[1];
    sclk <= 1;
    #2 sclk <= 0;
    out[1] <= miso;

    #2 mosi <= in[2];
    sclk <= 1;
    #2 sclk <= 0;
    out[2] <= miso;

    #2 mosi <= in[3];
    sclk <= 1;
    #2 sclk <= 0;
    out[3] <= miso;

    #2 mosi <= in[4];
    sclk <= 1;
    #2 sclk <= 0;
    out[4] <= miso;

    #2 mosi <= in[5];
    sclk <= 1;
    #2 sclk <= 0;
    out[5] <= miso;

    #2 mosi <= in[6];
    sclk <= 1;
    #2 sclk <= 0;
    out[6] <= miso;

    #2 mosi <= in[7];
    sclk <= 1;
    #2 sclk <= 0;
    out[7] = miso; // immediate assignment
    `ASSERT_EQUAL(dut.ready, 1, "ready")
  end
endtask

reg [0:7] sdatl;

spi_slave_async dut(
    .sclk(sclk),
    .miso(miso),
    .mosi(mosi),
    .ss(ss),
    .sdat(sdatl)
);

always @(posedge dut.clk)
  if(dut.ready) begin
    $display("# @ %d Ready mdat=%x sdat=%x", $simtime, dut.mdat, tsdat);
    sdatl <= tsdat;
    tmdat <= dut.mdat;
  end else
    sdatl <= 8'hxx;

initial
begin
  `TEST_INIT(test)

  sclk <= 0;
  mosi <= 0;
  ss <= 0;
  #2
  ss <= 1;

  spi_xfer(8'b01101010, outdat);
  `ASSERT_EQUAL(dut.mdat, 8'b01101010, "master data")
  tsdat <= 8'b10010101;
  spi_xfer(8'b10010001, outdat);
  `ASSERT_EQUAL(dut.mdat, 8'b10010001, "master data")
  `ASSERT_EQUAL(outdat, 8'b10010101, "slave data")
  tsdat <= 8'b10010010;
  spi_xfer(8'hxx, outdat);
  `ASSERT_EQUAL(outdat, 8'b10010010, "slave data")
  tsdat <= 8'hxx;

  #8 `TEST_DONE
end

endmodule
