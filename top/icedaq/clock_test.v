module top(
    input wire crystal,
    output wire [0:3] gpio0
);

assign gpio0[0] = crystal;
assign gpio0[1] = crystal;
assign gpio0[2] = crystal;
assign gpio0[3] = crystal;

endmodule
