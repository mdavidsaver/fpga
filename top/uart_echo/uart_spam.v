// Tx a repeating sequence of charactors
// to test frame format and baud rate
module top(
  input wire clk,   // 12 MHz

  output wire sertx,
  input wire  serrx,

  output wire sig1,
  output wire sig2,
  
  output reg [4:0] led
);

wire sertxi;
assign sertx = ~sertxi;
assign sig1 = sertx;
assign sig2 = serrx;

reg  send;
wire busy, tx_bit_clk;
reg  [7:0] dout = 0;

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

  .in(dout+97),
  .send(send),
  .busy(busy)
);

parameter X = 16;

reg slow_ena = 0;
reg [X:0] slow_cnt;
always @(posedge tx_bit_clk)
  if(slow_ena) slow_cnt <= slow_cnt[X-1:0] + 1;
  else         slow_cnt <= 0;

wire slow = slow_cnt[X];

reg [1:0] state = 0;

always @(posedge clk)
  case(state)
  0:begin
    send  <= 1;
    state <= 1;
    led[3] <= ~led[3];
  end
  1:if(busy)
    begin
      send     <= 0;
    end else begin
      state    <= 2;
      slow_ena <= 1;
    end
  2:if(slow)
    begin
      slow_ena <= 0;
      state    <= 0;
//      dout     <= 8'b01010101;
      if(dout==122+97) dout <= 0;     // 'a' through 'z'
      else          dout <= dout+1;
      led[4] <= ~led[4];
    end
  endcase

endmodule
