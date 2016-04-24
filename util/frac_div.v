module frac_div(
  input  wire in,
  output wire out
);

parameter Width = 3; // 2**3 = 8
parameter Incr  = 1;

reg [Width:0] counter = 0;

always @(posedge in)
  counter <= counter[Width-1:0] + Incr[Width:0];

assign out = counter[Width];

endmodule
