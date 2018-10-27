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
  input clk, // 25 MHz

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

// stablize sclk, and others to maintain phase
reg l_ss, l_sclk, l_mosi;
always @(posedge clk)
    {l_ss, l_sclk, l_mosi} <= {ss, sclk, mosi};

wire rom_ss, rom_sclk, rom_mosi, rom_miso;
wire unused_ss, unused_sclk, unused_mosi;

spi_mux mux(
    .clk(clk),
    .s_ss(l_ss),
    .s_sclk(l_sclk),
    .s_mosi(l_mosi),
    .s_miso(miso),
    .m_ss({rom_ss, adc1_ss, adc2_ss, dac1_sync, dac1_sync, unused_ss}),
    .m_sclk({rom_sclk, adc1_sclk, adc2_sclk, dac1_sclk, dac2_sclk, unused_sclk}),
    .m_mosi({rom_mosi, adc1_mosi, adc2_mosi, dac1_mosi, dac2_mosi, unused_mosi}),
    .m_miso({rom_miso, adc1_miso, adc2_miso, 3'b000})
);

spi_rom #(
    .SIZE(16),
    .INITFILE(`ROMFILE)
) idrom(
    .clk(clk),
    .ss(rom_ss),
    .sclk(rom_sclk),
    .mosi(rom_mosi),
    .miso(rom_miso)
);

endmodule
