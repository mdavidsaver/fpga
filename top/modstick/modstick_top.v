module top(
  input clk,   // 12 MHz

  output sertx,
  input  serrx,

  output sig1,
  output sig2,
  
  output [4:0] leds
);

assign sig1 = 0;
assign sig2 = 0;

wire valid, iswrite, ack, frame_err;
wire [15:0] addr, wdata, rdata;

modbus_rtu #(
// 12000000/(115200*8) ~= 2**10/78   (0.825 % error)
  .Width(10),
  .Incr(78)
) mod(
  .clk(clk),
  .reset(0),
  .maddr(1), // slave address 1
  .rin(serrx),
  .rout(sertx),
  .valid(valid),
  .iswrite(iswrite),
  .addr(addr),
  .wdata(wdata),
  .rdata(rdata),
  .ack(ack),
  .frame_err(frame_err)
);

modstick_logic log(
  .clk(clk),
  .reset(0),
  .valid(valid),
  .iswrite(iswrite),
  .addr(addr),
  .wdata(wdata),
  .rdata(rdata),
  .ack(ack),
  .frame_err(frame_err),
  .leds(leds)
);

endmodule
