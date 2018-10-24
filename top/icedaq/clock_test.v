`timescale 1us/1ns
module top(
    input wire clk0,
    input wire clk1,
    output wire [0:3] gpio0
);

assign gpio0[0] = clk0;
assign gpio0[1] = clk0;
assign gpio0[2] = clk1;
assign gpio0[3] = clk1;

endmodule
