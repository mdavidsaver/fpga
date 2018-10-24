`timescale 1us/1ns
/* SPI BRAM "ROM"
 * mode=3, cpol=1, cpha=1
 * idle high.
 * setup on falling (1->0) edge
 */
module spi_rom(
    input ss,   // active low select/reset
    input sclk,
    input mosi,
    output reg miso
);

parameter ORD = 3;
localparam SIZE = 2**ORD;

reg [0:7] rom [0:(SIZE-1)];

reg [ORD-1:0] pos;
reg [2:0] bit;

always @(posedge sclk, posedge ss)
    if(ss)
        {pos, bit} <= 0;
    else
        {pos, bit} = {pos, bit}+1;

wire [0:7] cur = rom[pos];
wire curb = cur[bit];

always @(negedge sclk)
    miso <= curb;

endmodule
