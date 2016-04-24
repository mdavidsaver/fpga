module top(
  input wire clk,   // 12 MHz

  output wire sertx,
  input wire  serrx,

  output reg [4:0] led
);

reg send = 0;
wire done, busy, ready, rxerr;
wire [7:0] din;
reg  [7:0] dlatch;

// 12000000/(115200*8) ~= 2**10/78   (0.825 % error)
uart #(
  .Width(10),
  .Incr(78)
)D(
  .reset(0),
  .clk(clk),

  .rin(serrx),
  .rout(sertx),

  .din(dlatch),
  .send(send),
  .done(done),

  .dout(din),
  .busy(busy),
  .rxerr(rxerr),
  .ready(ready)
);

always @(posedge send)
  led[0] <= ~led[0]; // left
always @(posedge done)
  led[1] <= ~led[1]; // top
always @(posedge ready)
  led[2] <= ~led[2]; // right
always @(posedge busy)
  led[3] <= ~led[3]; // bottom
always @(posedge rxerr)
  led[4] <= ~led[4]; // center

always @(posedge clk)
  if(!send & ready)
  begin
    dlatch <= din;
    send   <= 1;
  end
  else if(done)
  begin
    send <= 0;
  end

endmodule
