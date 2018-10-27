`timescale 1us/1ns
/* SPI multiplexer
 * mode=3, cpol=1, cpha=1
 * idle high.
 * setup on falling (1->0) edge
 * sample on rising (0->1) edge
 */
module spi_mux(
    input clk,
    // upstream/slave interface
    input s_ss,   // active low select/reset
    input s_sclk,
    input s_mosi,
    output s_miso,
    // master/downstream interfaces
    output [0:5] m_ss,
    output [0:5] m_sclk,
    output [0:5] m_mosi,
    input  [0:5] m_miso
);

wire [0:7] select;
wire ready;

select sel(
    .clk(clk),
    .ss(s_ss),
    .sclk(s_sclk),
    .mosi(s_mosi),
    .select(select),
    .ready(ready)
);

// gated control signals
wire g_ss = ready ? s_ss : 1'b1;
wire g_sclk = ready ? s_sclk : 1'b1;

assign m_ss = {
    ready & select==1 ? g_ss : 1'b1,
    ready & select==2 ? g_ss : 1'b1,
    ready & select==3 ? g_ss : 1'b1,
    ready & select==4 ? g_ss : 1'b1,
    ready & select==5 ? g_ss : 1'b1,
    ready & select==6 ? g_ss : 1'b1
};

assign m_sclk = {6{g_sclk}};
assign m_mosi = {6{s_mosi}};

assign s_miso = ready & select==1 ? m_miso[0] :
                ready & select==2 ? m_miso[1] :
                ready & select==3 ? m_miso[2] :
                ready & select==4 ? m_miso[3] :
                ready & select==5 ? m_miso[4] :
                ready & select==6 ? m_miso[5] :
                ready & select==7 ? 1'b1 :
                1'b0;

endmodule

module select(
    input clk,
    input ss,
    input sclk,
    input mosi,
    output reg [0:7] select,
    output reg ready
);

reg p_sclk;

always @(posedge clk)
    p_sclk <= sclk;

wire rise_sclk = ~p_sclk & sclk; // 0 -> 1

always @(posedge clk)
    if(ss)
        select <= 0;
    else if(rise_sclk & ~ready)
        select <= {select[1:7], mosi};
    else
        select <= select;

// count 0 -> 8 and hold at 8
reg [0:4] state;

always @(posedge clk)
    if(ss)
        state <= 0;
    else if(rise_sclk && state!=8)
        state <= state+1;
    else
        state <= state;

always @(posedge clk)
    if(ss)
        ready <= 0;
    else if(state==8)
        ready <= 1;

endmodule
