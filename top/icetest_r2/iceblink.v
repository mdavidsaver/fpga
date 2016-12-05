module top(
  input        clk,
  output [0:7] out
);

assign out[0] = clk;
assign out[1] = ~clk;
assign out[2] = clk;
assign out[3] = ~clk;
assign out[4] = clk;
assign out[5] = ~clk;
assign out[6] = clk;
assign out[7] = ~clk;

endmodule
