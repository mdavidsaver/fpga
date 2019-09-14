`timescale 1us/1ns
module test;

`include "utest.vlib"

`TEST_PRELUDE(1)

`TEST_CLOCK(clk,0.042); // ~12MHz

`TEST_TIMEOUT(200000)

wire sertx;
reg [6:0] pin = 6'b001000;
wire [4:0] led;

icela dut(
    .clk(clk),
    .sertx_n(sertx),
    .pin(pin),
    .led(led)
);

initial
begin
  `TEST_INIT(test)

    #1
    pin[0] <= 1;
    #40
    pin[1] <= 1;
    pin[0] <= 0;

    #1200 // one charactor ~100us
    `ASSERT_EQUAL(dut.sm.state, 0, "Idle")
    `TEST_DONE
end

endmodule
