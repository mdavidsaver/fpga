`timescale 1us/1ns
module test;

`include "utest.vlib"

`TEST_PRELUDE(9)

`TEST_TIMEOUT(6000)

reg sclk, mosi, ss;
wire miso;
reg [0:7] outdat;

integer i;

task spi_xfer;
    input [0:7] in;
    output [0:7] out;
    begin
        $display("# spi_xfer start in=%x", in);
        for(i=0; i<8; i=i+1) begin
            #2 mosi <= in[i];
            sclk <= 0;
            #2 sclk <= 1;
            out[i] <= miso; // immediate assignment
        end
        #2 $display("# spi_xfer end out=%x", out);
    end
endtask

top dut(
    .debug_ss(ss),
    .debug_mosi(mosi),
    .debug_sclk(sclk),
    .debug_miso(miso),
    .ss(1'b1),
    .sclk(sclk),
    .mosi(1'b1),
    .adc1_miso(1'b0),
    .adc2_miso(1'b0)
);

initial
begin
    `TEST_INIT(test)
    #2 ss <= 1;

    #2
    spi_xfer(8'hff, outdat);
    `ASSERT_EQUAL(outdat, 8'hxx, "slave data")

    #2 ss <= 0;

    #2
    spi_xfer(8'h10, outdat);
    spi_xfer(8'h10, outdat);
    `ASSERT_EQUAL(outdat, 8'b101000xx, "slave data")
    `ASSERT_EQUAL(dut.mux, 2'b00, "mux 0")
    spi_xfer(8'h12, outdat);
    `ASSERT_EQUAL(outdat, 8'b10100000, "slave data")
    `ASSERT_EQUAL(dut.mux, 2'b10, "mux 2")
    spi_xfer(8'h20, outdat);
    `ASSERT_EQUAL(outdat, 8'b10100000, "slave data")
    `ASSERT_EQUAL(dut.mux, 2'b10, "mux 2")
    spi_xfer(8'h20, outdat);
    `ASSERT_EQUAL(outdat, 8'b10100010, "slave data")
    `ASSERT_EQUAL(dut.mux, 2'b10, "mux 2")

    #8 `TEST_DONE
end

endmodule
