`timescale 1us/1ns
/* SPI BRAM "ROM"
 * mode=3, cpol=1, cpha=1
 * idle high.
 * setup on falling (1->0) edge
 */
module spi_rom(
    input clk,
    input ss,   // active low select/reset
    input sclk,
    input mosi,
    output reg miso
);

reg p_sclk;

always @(posedge clk)
    p_sclk <= sclk;

wire fall_sclk = p_sclk & ~sclk; // 1 -> 0

parameter SIZE = 8;
localparam ORD = $clog2(SIZE);

parameter INITFILE = "";
localparam x = $size(INITFILE);

reg [0:7] rom [0:(SIZE-1)];

reg [ORD-1:0] pos;
reg [2:0] bitn;

always @(posedge clk)
    if(ss)
        {pos, bitn} <= {ORD-1+8{1'b1}};
    else if(fall_sclk)
        {pos, bitn} <= {pos, bitn}+1;
    else
        {pos, bitn} <= {pos, bitn};

wire [0:7] cur = rom[pos];
wire curb = cur[bitn];

always @(posedge clk)
    miso <= curb;

initial begin
    if($size(INITFILE)>0)
        $readmemh(INITFILE, rom);
end

endmodule
