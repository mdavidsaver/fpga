/*
 * Change data when ready, data must remain stable otherwise
 */
module dacx311(
    input clk,   // bit clock
    input reset, // sync reset

    // from spi_master_ctrl
    input selected, // non-inverted ss
    input ready,    // end of frame
    input [5:0] cnt,

    // bus signals
    output mosi,
    input miso,

    input [1:0] pd, // power down (0 - normal, 1 - 1Kohm to gnd, 2 - 100Kohm, 3 - highZ)
    input [11:0] data
);

wire [15:0] frame = {2'b00, pd, data, 2'b00};

spi_master_inst #(
    .BYTES(2)
) spi(
    .clk(clk),
    .reset(reset),
    .selected(selected),
    .ready(ready),
    .cnt(cnt),
    .mosi(mosi),
    .miso(miso),
    .mdat(frame),
    .sdat() // device is write only
);

endmodule
