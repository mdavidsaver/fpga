module test;

`include "utest.vlib"

`TEST_PRELUDE(2)

`TEST_TIMEOUT(6000)

`TEST_CLOCK(clk, 4);

reg reset = 1;
reg [1:0] pd = 0;
reg [11:0] data = 0;

spi_master_ctrl #(
    .BYTES(2)
) ctrl(
    .clk(clk),
    .reset(reset)
);

dacx311 dut(
    .clk(clk),
    .reset(reset),
    .selected(ctrl.selected),
    .ready(ctrl.ready),
    .cnt(ctrl.cnt),
    .miso(1'b0),
    .pd(pd),
    .data(data)
);

reg [15:0] frame;

always @(negedge ctrl.sclk)
    if(~ctrl.ss)
        frame <= 0;
    else
        frame <= {frame[14:0], dut.mosi};

initial
begin
    `TEST_INIT(test)

    #10
    data <= 12'hfff;
    reset <= 0;

    @(posedge dut.ready);

    data <= 12'h123;

    @(negedge dut.ready);
    `ASSERT_EQUAL(frame, 16'h3ffc, "first")

    @(posedge dut.ready);
    @(negedge dut.ready);
    `ASSERT_EQUAL(frame, 16'h048c, "second")

    #8 `TEST_DONE 
end

endmodule
