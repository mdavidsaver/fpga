module top(
  input wire clk,   // 25 MHz
  input wire reset,

  output wire sertx,
  input wire  serrx,

  output reg [4:0] led
);

reg send = 0;
wire done, ready;
wire [7:0] din;
reg  [7:0] dlatch;

// 25000000/(115200*8) ~= 2**12/150  (0.6663 % error)
uart #(
  .Width(12),
  .Incr(150)
)D(
  .reset(reset),
  .clk(clk),

  .rin(serrx),
  .rout(sertx),

  .din(dlatch),
  .send(send),
  .done(done),

  .dout(din),
  .ready(ready)
);

always @(posedge clk)
  begin
    led[0]   <= send;
    led[1]   <= done;
    led[2]   <= ready;
    led[3]   <= reset;
    led[4]   <= 0;
  end

always @(posedge clk)
  if(!send & ready)
  begin
    dlatch <= din;
    send   <= 1;
  end
  else if(send & done)
  begin
    send <= 0;
  end

endmodule
