module top(
  input wire clk,   // 12 MHz

  output wire sertx,
  input wire  serrx,

  output wire sig1,
  output wire sig2,
  
  output reg [4:0] led
);

reg send = 0;
wire txbusy, rxbusy, ready, rxerr;
wire [7:0] din;
reg  [7:0] dlatch;

wire sertxi, serrxi;
assign sertx = ~sertxi;
assign serrxi = ~serrx;
assign sig1 = sertx;
assign sig2 = serrx;

// 12000000/(115200*8) ~= 2**10/78   (0.825 % error)
uart #(
  .Oversample(3), // 2**3 == 8
  .Width(10),
  .Incr(78)
)D(
  .reset(0),
  .clk(clk),

  .rin(serrxi),
  .rout(sertxi),

  .din(dlatch),
  .send(send),
  .txbusy(txbusy),

  .dout(din),
  .rxbusy(rxbusy),
  .rxerr(rxerr),
  .ready(ready)
);

always @(posedge send)
  led[0] <= ~led[0]; // left
always @(posedge txbusy)
  led[1] <= ~led[1]; // top
always @(posedge ready)
  led[2] <= ~led[2]; // right
always @(posedge rxbusy)
  led[3] <= ~led[3]; // bottom
always @(posedge rxerr)
  led[4] <= ~led[4]; // center

always @(posedge clk)
  if(~txbusy & ready) // RX complete, begin TX
  begin
    dlatch <= din;
    send   <= 1;
  end
  else if(txbusy)
  begin
    send   <= 0;
  end

endmodule
