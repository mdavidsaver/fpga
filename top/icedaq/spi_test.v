`timescale 1us/1ns
/* Testing SPI devices.
 *
 * debug SPI controls mux to select which
 * slave device is connected to primary SPI.
 *
 * Write to debug mux:
 *  0x10 - select ADC1
 *  0x11 - select ADC2
 *  0x12 - select DAC1
 *  0x13 - select DAC2
 *  others no-op
 *  reads back 0b101000__ mux setting 0 -> 3
 */
module top(
  input debug_ss,
  input debug_sclk,
  input debug_mosi,
  output debug_miso,

  input ss,
  input sclk,
  input mosi,
  output miso,

  output adc1_ss,
  output adc1_sclk,
  output adc1_mosi,
  input adc1_miso,

  output adc2_ss,
  output adc2_sclk,
  output adc2_mosi,
  input adc2_miso,

  output dac1_sync,
  output dac1_sclk,
  output dac1_mosi,

  output dac2_sync,
  output dac2_sclk,
  output dac2_mosi,

  output [0:1] gpio0
);

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

assign gpio0 = {dclk, dready};

reg [0:1] mux;

always @(posedge dclk)
    if(dready) begin
        $display("# SPI CMD %x DATA %x", cmd[0:3], cmd[6:7]);
        reply <= {6'b101000, mux};
        if(cmd[0:3]==4'h1)
          mux <= cmd[6:7];
    end

wire adc1_ss = mux==0 ? ss : 1;
wire adc2_ss = mux==1 ? ss : 1;
wire dac1_sync = mux==2 ? ss : 1;
wire dac2_sync = mux==3 ? ss : 1;

wire adc1_sclk = sclk;
wire adc2_sclk = sclk;
wire dac1_sclk = sclk;
wire dac2_sclk = sclk;

wire adc1_mosi = mosi;
wire adc2_mosi = mosi;
wire dac1_mosi = mosi;
wire dac2_mosi = mosi;

wire miso = mux==0 ? adc1_miso :
            mux==1 ? adc2_miso :
            0;

endmodule
