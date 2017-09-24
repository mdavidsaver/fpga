/* Controller for multiple SPI masters
 *
 * tranfer BYTES with 2 extra bits to deselect between frames.
 */
module spi_master_ctrl(
    input clk,   // bit clock
    input reset, // sync reset

    output reg sclk,
    output ss,

    output reg selected, // non-inverted ss
    output reg ready,    // end of frame
    output reg [(3+BYTES):0] cnt
);

parameter CPOL = 1'b0; // clock idle state
parameter SS = 1'b0;   // SS idle state
parameter BYTES = 1;   // number of bytes per frame

// bits per cycle (including extra)
localparam BITS = 8*BYTES + 2;

localparam MAXCNT = 2*BITS;

always @(posedge clk)
    if(reset | cnt==MAXCNT)
        cnt <= 0;
    else
        cnt <= cnt + 1;

always @(posedge clk)
    ready <= cnt==MAXCNT;

always @(posedge clk)
    if(reset | cnt<2)
        selected <= 0;
    else
        selected <= 1;

assign ss = selected ^ SS;

always @(posedge clk)
    if(cnt<4)
        sclk <= CPOL;
    else
        sclk <= cnt[0] ^ CPOL;

endmodule
