`timescale 1us/1ns
module top(
    input gclk2,

    input debug_ss,
    input debug_sclk,
    input debug_mosi,
    output debug_miso,

    output dac1_sync,
    output dac1_sclk,
    output dac1_mosi,

    output dac2_sync,
    output dac2_sclk,
    output dac2_mosi,

    output adc1_ss,
    output adc1_sclk,
    input  adc1_miso,
    output adc1_mosi,

    output adc2_ss,
    output adc2_sclk,
    input  adc2_miso,
    output adc2_mosi,

    output [3:0] gpio0
);

reg reset = 0;

// divide 25MHz/16 -> 1.56 MHz
reg [2:0] cdiv;
always @(posedge gclk2)
    cdiv <= cdiv+1;

wire clk = cdiv[2];

// DAC phase counter
reg [7:0] cnt = 0;
reg [7:0] cnt_l;

always @(posedge clk)
    if(ready) begin
        cnt  <= cnt + 1;
        if(debug_ss)
            cnt_l <= cnt;
    end

reg [7:0] lut [255:0];
`define STRINGIFY(x) `"x`"
initial begin
    $readmemh("sine8x256.txt", lut);
end
wire [7:0] sine = lut[cnt];

wire ready;

wire ctrl_ss, ctrl_sclk;
wire [5:0] ctrl_cnt;

spi_master_ctrl #(
    .CPOL(1'b1), // active low
    .SS(1'b1), // active low
    .BYTES(2)
) ctrl(
    .clk(clk),
    .reset(reset),
    .cnt(ctrl_cnt),
    .ready(ready),
    .ss(ctrl_ss),
    .sclk(ctrl_sclk)
);

assign dac1_sync = ctrl_ss;
assign dac1_sclk = ~ctrl_sclk;
dacx311 dac1(
    .clk(clk),
    .reset(reset),
    .cnt(ctrl_cnt),
    .miso(reset), // one way
    .mosi(dac1_mosi),
    .pd(2'b00), // normal
    .data({sine, 4'h0})
);

assign dac2_sync = ctrl_ss;
assign dac2_sclk = ~ctrl_sclk;
dacx311 dac2(
    .clk(clk),
    .reset(reset),
    .cnt(ctrl_cnt),
    .miso(1'b0), // one way
    .mosi(dac2_mosi),
    .pd(2'b00), // normal
    .data({cnt, 4'h0})
);


assign gpio0[0] = ctrl_ss; // 28
assign gpio0[1] = ctrl_sclk; // 27
assign gpio0[2] = dac1_mosi; // 30
assign gpio0[3] = dac2_mosi; // 29

wire [11:0] adc1_data;
assign adc1_ss = ctrl_ss;
assign adc1_sclk = ctrl_sclk;
adc082s021 adc1(
    .clk(clk),
    .reset(reset),
    .channel(3'h1),
    .cnt(ctrl_cnt),
    .miso(adc1_miso),
    .mosi(adc1_mosi),
    .data(adc1_data)
);

wire [11:0] adc2_data;
assign adc2_ss = ctrl_ss;
assign adc2_sclk = ctrl_sclk;
adc082s021 adc2(
    .clk(clk),
    .reset(reset),
    .channel(3'h1),
    .cnt(ctrl_cnt),
    .miso(adc2_miso),
    .mosi(adc2_mosi),
    .data(adc2_data)
);

reg [7:0] adc1_data_l;
always @(posedge clk)
    if(ready & debug_ss)
        adc1_data_l <= adc1_data[11:4];

reg [7:0] adc2_data_l;
always @(posedge clk)
    if(ready & debug_ss)
        adc2_data_l <= adc2_data[11:4];

wire dclk, dready, n_dselect;
wire [0:7] cmd;
reg [0:7] reply;

spi_slave_async dspi(
  .ss(~debug_ss),
  .sclk(~debug_sclk),
  .mosi(debug_mosi),
  .miso(debug_miso),
  .clk(dclk),
  .reset(n_dselect),
  .ready(dready),
  .mdat(cmd),
  .sdat(reply)
);

reg [1:0] state;

always @(posedge dclk, posedge n_dselect)
    if(n_dselect)
        state <= 0;
    else if(dready)
        state <= state + 1;

always @(posedge dclk)
    if(dready) begin
    case(state)
    0: reply <= cnt_l;
    1: reply <= adc1_data_l;
    2: reply <= adc2_data_l;
    3: reply <= 8'hab;
    endcase
    end

endmodule
