`timescale 1us/1ns
module uart(
  input  wire       reset,
  input  wire       clk,  // ref clock

  input  wire       rin,   // rs232 data in
  output wire       rout,  // rs232 data out

  input wire [7:0]  din,   // data to TX
  input wire        send,
  output wire       txbusy,

  output wire       rxbusy, // RX in progress
  output wire       ready,// pulsed when new data received
  output wire       rxerr,// RX bad frame
  output wire [7:0] dout,  // RX data

  output wire       samp_clk, // oversampled baud rate clock (debug)
  output wire       tx_bit_clk,  // TX bit clock (debug)
  output wire       rx_bit_clk  // reconstructed RX bit clock (debug)
);

parameter Width = 3; // 2**3 = 8
parameter Incr  = 1;
parameter Oversample = 3; // 2**3 = 8

// baud rate fractional divider
frac_div #(
  .Width(Width),
  .Incr(Incr)
) CLK (
  .in(clk),
  .out(samp_clk)
);

/////// TX stage

// fixed phase TX bit clock
reg [Oversample:0] bit_clk_cnt = 0;

always @(posedge clk)
  if(reset)
    bit_clk_cnt <= 0;
  else if(samp_clk)
    bit_clk_cnt <= bit_clk_cnt[Oversample-1:0]+1;

assign tx_bit_clk = samp_clk & bit_clk_cnt[Oversample];
wire tx_send = ~reset & send;

uart_tx TX(
  .ref_clk(clk),
  .bit_clk(tx_bit_clk),
  .send(tx_send),
  .in(din),
  .busy(txbusy),
  .out(rout)
);

/////// RX stage

wire dcon;

uart_rx_filter RXF(
  .clk(clk),
  .samp_clk(samp_clk),
  .in(rin),
  .out(dcon)
);

uart_rx RX(
  .ref_clk(clk),
  .samp_clk(samp_clk),
  .reset(reset),
  .in(dcon),
  .busy(rxbusy),
  .ready(ready),
  .out(dout),
  .err(rxerr),
  .bit_clk(rx_bit_clk)
);

endmodule
