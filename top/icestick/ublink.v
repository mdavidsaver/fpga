`timescale 1us/1ns
module top(
  input wire clk,   // 12 MHz

  output wire sertx,
  input wire  serrx,

  output wire sig1,
  output wire sig2,
  
  output reg [4:0] led
);

wire sertxi, serrxi;
assign sertx = ~sertxi;
assign serrxi = ~serrx;

reg reply_send;
wire reply_busy;
reg [7:0] reply;

wire cmd_ready, cmd_err;
wire [7:0] cmd;

// 12000000/(115200*8) ~= 2**10/78   (0.825 % error)
uart #(
  .Width(10),
  .Incr(78)
)D(
  .reset(0),
  .clk(clk),

  .rin(serrxi),
  .rout(sertxi),

  .din(reply),
  .send(reply_send),
  .txbusy(reply_busy),

  .dout(cmd),
  .rxerr(cmd_err),
  .ready(cmd_ready)
);

reg [1:0] mode = 0;

always @(posedge clk)
  case (mode)
  // IDLE
  0:if(cmd_ready)
    begin
      if(cmd==8'h71) // 'q' query LED state
      begin
        reply_send <= 1;
        reply <= {3'b010, led};
        mode  <= 1;
      end
      else if(cmd==8'h73) // 's' set LED state
      begin
        mode <= 2;
      end
      else if(cmd==8'h63) // 'c' clear LED state
      begin
        mode <= 3;
      end
    end else if(cmd_err) begin
      led[4] <= 1; // RX err (center)
    end
  // Wait for send to complete
  1:if(reply_busy)
      reply_send <= 0;
    else if(!reply_send)
      mode <= 0;
  // SETLED
  2:if(cmd_ready && {cmd[7:2],2'h0}==8'h30) begin // '0' through '3'
      led[cmd[1:0]] <= 1;
      reply_send    <= 1;
      reply         <= 8'h53; // 'S'
      mode          <= 1;
    end else if(cmd_err || (cmd_ready && cmd[7:3]!=5'h6)) begin
      led[4] <= 1; // RX err (center)
      mode   <= 0;
    end
  // CLEARLED
  3:if(cmd_ready && {cmd[7:2],2'h0}==8'h30) begin // '0' through '3'
      led[cmd[1:0]] <= 0;
      reply_send <= 1;
      reply      <= 8'h43; // 'C'
      mode       <= 1;
    end else if(cmd_err || (cmd_ready && cmd[7:3]!=5'h6)) begin
      led[4] <= 1; // RX err (center)
      mode   <= 0;
    end
  endcase

endmodule
