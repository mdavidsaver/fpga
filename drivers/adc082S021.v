`timescale 1us/1ns
/*
 * Sample data when ready
 */
module adc082s021(
    input clk,
    input reset,

    // from spi_master_ctrl
    input [5:0] cnt,

    // bus signals
    output mosi,
    input miso,

    input [2:0] channel, // 0, 1
    output [11:0] data
);

wire [15:0] frame = {2'b00, channel, 3'b000, 8'h00};

wire [15:0] oframe;
assign data = oframe[11:0];

spi_master_inst #(
    .BYTES(2)
) spi(
    .clk(clk),
    .reset(reset),
    .cnt(cnt),
    .mosi(mosi),
    .miso(miso),
    .mdat(frame),
    .sdat(oframe)
);

endmodule
