// Tx a repeating sequence of charactors
// to test frame format and baud rate
module top(
  input wire clk,   // 12 MHz

  output wire sertx,
  input wire  serrx,

  output reg [4:0] led
);

reg  send;
wire done, tx_bit_clk;
reg  [7:0] dout = 97;

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

  .out(sertx),

  .in(dout),
  .send(send),
  .done(done)
);

parameter X = 16;

reg slow_ena = 0;
reg [X:0] slow_cnt;
always @(posedge tx_bit_clk)
  if(slow_ena) slow_cnt <= slow_cnt[X-1:0] + 1;
  else         slow_cnt <= 0;

wire slow = slow_cnt[X];

always @(posedge slow)
  led[4] <= ~led[4];

reg [1:0] state = 0;

always @(posedge clk)
  case(state)
  0:begin
    send  <= 1;
    state <= 1;
  end
  1:if(done)
    begin
      send     <= 0;
      state    <= 2;
      slow_ena <= 1;
    end
  2:if(slow)
    begin
      slow_ena <= 0;
      state    <= 0;
      if(dout==122) dout <= 97;
      else          dout <= dout+1;
    end
  endcase

endmodule
