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

// divide 25MHz/16 -> 1.56 MHz
reg [2:0] cdiv;
always @(posedge gclk2)
    cdiv <= cdiv+1;

wire clk = cdiv[2];

wire dac_sync, dac_sclk, dac_mosi;

assign dac1_sync = ~dac_sync;
assign dac1_sclk = ~dac_sclk;
assign dac1_mosi = dac_mosi;

assign dac2_sync = ~dac_sync;
assign dac2_sclk = ~dac_sclk;
assign dac2_mosi = dac_mosi;

assign gpio0[0] = ~debug_ss; // 28
assign gpio0[1] = ~debug_sclk; // 27
assign gpio0[2] = debug_mosi; // 30
assign gpio0[3] = debug_miso; // 29

wire ready;

reg reset = 0, pause = 0;
reg [7:0] cnt = 0;
reg [7:0] cnt_l;

wire [11:0] frame = {cnt, 4'h0};

dacx311 dac(
    .clk(clk),
    .reset(reset),
    .pd(2'b00),
    .data(frame),
    .ready(ready),
    .ss(dac_sync),
    .sclk(dac_sclk),
    .mosi(dac_mosi)
);

always @(posedge clk)
    if(ready & ~pause) begin
        cnt  <= cnt + 1;
        if(debug_ss)
            cnt_l <= cnt;
    end

wire adc1_ready, adc2_ready;
wire [11:0] adc1_data;
wire [11:0] adc2_data;

adc082s021 #(
    .CPOL(1),
    .SS(1)
) adc1 (
    .clk(clk),
    .reset(reset),
    .channel(3'h1),
    .data(adc1_data),
    .ready(adc1_ready),
    .ss(adc1_ss),
    .sclk(adc1_sclk),
    .mosi(adc1_mosi),
    .miso(adc1_miso)
);

adc082s021 #(
    .CPOL(1),
    .SS(1)
) adc2 (
    .clk(clk),
    .reset(reset),
    .channel(3'h1),
    .data(adc2_data),
    .ready(adc2_ready),
    .ss(adc2_ss),
    .sclk(adc2_sclk),
    .mosi(adc2_mosi),
    .miso(adc2_miso)
);

reg [7:0] adc1_data_l;
always @(posedge clk)
    if(adc1_ready & debug_ss)
        adc1_data_l <= adc1_data[11:4];

reg [7:0] adc2_data_l;
always @(posedge clk)
    if(adc2_ready & debug_ss)
        adc2_data_l <= adc2_data[11:4];

wire dclk, dready;
wire [0:7] cmd;
reg [0:7] reply;

spi_slave_async dspi(
  .ss(~debug_ss),
  .sclk(~debug_sclk),
  .mosi(debug_mosi),
  .miso(debug_miso),
  .clk(dclk),
  .ready(dready),
  .mdat(cmd),
  .sdat(reply)
);

always @(posedge dclk)
    if(dready) begin
    case(cmd[6:7])
    0: reply <= cnt_l;
    1: reply <= adc1_data_l;
    2: reply <= adc2_data_l;
    default: reply <= 8'hab;
    endcase
    end

endmodule
