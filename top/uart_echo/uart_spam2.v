// Tx test byte
module top(
  input wire clk,   // 12 MHz

  output wire sertx,
  input wire  serrx,

  output wire sig1,
  output wire sig2,
  
  output reg [4:0] led
);

reg  send;
wire sertxi;
wire done, tx_bit_clk;
reg  [7:0] dout = 8'b00010100;

assign sertx = ~sertxi;
assign sig1 = sertx;
assign sig2 = serrx;

frac_div #(
  .Width(15),
  .Incr(314)
) CLK (
  .in(clk),
  .out(tx_bit_clk)
);

uart_tx D(
  .ref_clk(clk),
  .bit_clk(tx_bit_clk),

  .out(sertxi),

  .in(dout),
  .send(send),
  .done(done)
);

always @(posedge clk)
  if(~send)      send <= 1;
  else if(done) send <= 0;

endmodule
