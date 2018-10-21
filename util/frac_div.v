`timescale 1us/1ns
module frac_div(
  input  wire in,
  output reg  out
);

parameter Width = 3; // 2**3 = 8
parameter Incr  = 1;

reg [Width-1:0] counter = 0;

always @(posedge in)
  {out, counter} <= counter + Incr[Width:0];

endmodule
