module test;

`include "utest.vlib"

`TEST_PRELUDE(4)

`TEST_TIMEOUT(6000)

`TEST_CLOCK(clk, 4);

reg reset = 1;
reg [2:0] channel = 1;
wire miso;

adc082s021 dut(
    .clk(clk),
    .reset(reset),
    .channel(channel),
    .miso(miso)
);

reg [15:0] frame_mosi;
always @(negedge dut.sclk)
    if(~dut.ss)
        frame_mosi <= 0;
    else
        frame_mosi <= {frame_mosi[14:0], dut.mosi};

reg [16:0] frame_miso;
assign miso = frame_miso[15];

always @(posedge dut.sclk)
    if(dut.ss)
        frame_miso <= {frame_miso[15:0], 1'bx};

initial
begin
    `TEST_INIT(test)

    #10
    frame_miso <= 17'hxxff0;
    reset <= 0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);

    while(~dut.ready) @(posedge clk);
    `ASSERT_EQUAL(frame_mosi, 16'h0800, "first cmd")
    `ASSERT_EQUAL(dut.data, 12'hff0, "first data")

    frame_miso <= 17'hxx120;

    while(dut.ready) @(posedge clk);

    while(~dut.ready) @(posedge clk);
    `ASSERT_EQUAL(frame_mosi, 16'h0800, "second cmd")
    `ASSERT_EQUAL(dut.data, 12'h120, "second data")


    #8 `TEST_DONE 
end

endmodule
