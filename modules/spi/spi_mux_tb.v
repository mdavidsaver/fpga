`timescale 1us/1ns
module test;

`include "utest.vlib"

`TEST_PRELUDE(14)

`TEST_TIMEOUT(6000)

reg sclk, ss, mosi;
wire miso;

wire [0:1] mux_miso;

spi_mux dut(
    .s_ss(ss),
    .s_sclk(sclk),
    .s_mosi(mosi),
    .s_miso(miso),
    .m_miso(mux_miso)
);

spi_rom rom1(
    .ss(dut.m_ss[0]),
    .sclk(dut.m_sclk[0]),
    .mosi(dut.m_mosi[0]),
    .miso(mux_miso[0])
);

spi_rom rom2(
    .ss(dut.m_ss[1]),
    .sclk(dut.m_sclk[1]),
    .mosi(dut.m_mosi[1]),
    .miso(mux_miso[1])
);


task xfer;
    input [0:7] inp;
    input [0:7] exp;
    reg [0:7] actual;
    integer i;
    begin
        $display("# @%d xfer(%02x, %02x)", $simtime, inp, exp);
        for(i = 0; i<8 ; i = i + 1) begin
            #10
            mosi <= 1'bx; // detect sim issue?
            sclk <= 0;
            mosi <= inp[i];
            #10
            sclk <= 1;
            actual[i] = miso;
        end
        $display("# @%d %02x == %02x", $simtime, exp, actual);
        `ASSERT_EQUAL(exp, actual, "xfer")
    end
endtask

initial
begin
  `TEST_INIT(test)

  rom1.rom[0] = 8'h12;
  rom1.rom[2] = 8'h34;

  rom2.rom[0] = 8'h01;
  rom2.rom[2] = 8'h02;

  ss <= 1;
  sclk <= 1;

  #10
  `DIAG("Read from ROM1")
  ss <= 0;

  #10
  xfer(2, 8'b0000000x);
  #10
  xfer(8'hxx, 8'h12);
  #10
  xfer(8'hxx, 8'hxx);
  #10
  xfer(8'hxx, 8'h34);
  #10
  xfer(8'hxx, 8'hxx);

  #10
  ss <= 1;
  #10
  `ASSERT_EQUAL(dut.ready, 0, "not ready")
  `ASSERT_EQUAL(dut.select, 0, "select cleared")

  #10
  `DIAG("Read from ROM2")
  ss <= 0;

  #10
  xfer(4, 0);
  #10
  xfer(8'hxx, 8'h01);
  #10
  xfer(8'hxx, 8'hxx);
  #10
  xfer(8'hxx, 8'h02);
  #10
  xfer(8'hxx, 8'hxx);

  #10
  ss <= 1;
  #10
  `ASSERT_EQUAL(dut.ready, 0, "not ready")
  `ASSERT_EQUAL(dut.select, 0, "select cleared")

  #8 `TEST_DONE
end

endmodule
