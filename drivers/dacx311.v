/*
 * Change data when ready, data must remain stable otherwise
 */
module dacx311(
    input clk,
    input reset,
    input [1:0] pd, // power down (0 - normal, 1 - 1Kohm to gnd, 2 - 100Kohm, 3 - highZ)
    input [11:0] data,
    output ready,

    output sclk,
    output mosi,
    output ss
);

parameter CPOL = 1'b0; // clock idle state
parameter SS = 1'b1; // SS active state

reg [5:0] cnt;

always @(posedge clk)
    if(reset | cnt==36)
        cnt <= 0;
    else
        cnt <= cnt + 1;

reg ready;

always @(posedge clk)
    ready <= cnt==36;

reg sclk, mosi, ss;

always @(posedge clk)
    if(reset | cnt<2)
        ss <= ~SS;
    else
        ss <= SS;

always @(posedge clk)
    if(cnt<4)
        sclk <= CPOL;
    else
        sclk <= cnt[0] ^ CPOL;

wire [0:17] frame = {2'b00, pd, data, 2'b00};

always @(posedge clk)
    if(cnt[0])
        mosi <= frame[cnt[5:1]];

endmodule
