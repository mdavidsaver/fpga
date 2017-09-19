/*
 * Sample data when ready
 */
module adc082s021(
    input clk,
    input reset,
    input [2:0] channel, // 0, 1
    output [11:0] data,
    output ready,

    output sclk,
    output mosi,
    input  miso,
    output ss
);

parameter CPOL = 1'b0; // clock idle state
parameter SS = 1'b0; // SS idle state

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
        ss <= SS;
    else
        ss <= ~SS;

always @(posedge clk)
    if(cnt<4)
        sclk <= CPOL;
    else
        sclk <= cnt[0] ^ CPOL;

wire [0:17] frame = {2'b00, 2'b00, channel, 3'b000, 8'h00};

always @(posedge clk)
    if(cnt[0])
        mosi <= frame[cnt[5:1]];

reg [17:0] dshift;

always @(posedge clk)
    if(cnt[0])
        dshift <= {dshift[16:0], miso};

assign data = dshift[11:0];

endmodule
