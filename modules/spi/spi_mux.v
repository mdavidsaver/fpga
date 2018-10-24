`timescale 1us/1ns
/* SPI multiplexer
 * mode=3, cpol=1, cpha=1
 * idle high.
 * setup on falling (1->0) edge
 * sample on rising (0->1) edge
 */
module spi_mux(
    // upstream/slave interface
    input s_ss,   // active low select/reset
    input s_sclk,
    input s_mosi,
    output s_miso,
    // master/downstream interfaces
    output [0:1] m_ss,
    output [0:1] m_sclk,
    output [0:1] m_mosi,
    input  [0:1] m_miso
);

wire [0:7] select;
wire ready;

select sel(
    .ss(s_ss),
    .sclk(s_sclk),
    .mosi(s_mosi),
    .select(select),
    .ready(ready)
);

// gated control signals
wire g_ss = ready ? s_ss : 1'b1;
wire g_sclk = ready ? s_sclk : 1'b1;

assign m_ss = {select==1 ? g_ss : 1'b1, select==2 ? g_ss : 1'b1};

assign m_sclk = {g_sclk, g_sclk};
assign m_mosi = {s_mosi, s_mosi};

assign s_miso = select==1 ? m_miso[0] :
                select==2 ? m_miso[1] :
                1'b0;

endmodule

module select(
    input ss,
    input sclk,
    input mosi,
    output reg [0:7] select,
    output ready
);

// previous 6 bits
reg [0:5] shift;

always @(posedge sclk, posedge ss)
    if(ss)
        shift <= 0;
    else
        shift <= {shift[1:5], mosi};

// count 0 -> 8 and hold at 8
reg [0:4] state;

always @(posedge sclk, posedge ss)
    if(ss)
        state <= 0;
    else if(state!=8)
        state <= state+1;

// change mux output at end of first byte
always @(posedge sclk, posedge ss)
    if(ss)
        select <= 0;
    else if(state==6)
        select <= {shift, mosi};
    else
        select <= select;

// ready at end of second byte
assign ready = state==8;

endmodule
