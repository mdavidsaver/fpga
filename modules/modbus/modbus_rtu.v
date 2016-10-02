/* MODBUS slave endpoint+uart wrapper
 */
module modbus_rtu(
  input         reset,
  input         clk,  // ref clock

  // config
  input [6:0]   maddr, // modbus_endpoint.v
  
  // UART interface
  input         rin,   // rs232 data in
  output        rout,  // rs232 data out

  // bus interface
  output        valid,
  output        iswrite,
  output [15:0] addr,
  output [15:0] wdata,
  input  [15:0] rdata,
  input         ack,

  // Status
  output        frame_busy,
  output        frame_err
);

// see modules/uart/uart.v
parameter Width = 3; // 2**3 = 8
parameter Incr  = 1;
parameter Oversample = 3; // 2**3 = 8

// see modbus_endpoint.v
parameter TMOSIZE = 8;
parameter TMOMAX = {TMOSIZE{1'b1}};

wire send, txbusy, ready, rxerr;
wire [0:7]  miso, mosi;

uart #(
  .Width(Width),
  .Incr(Incr),
  .Oversample(Oversample)
) ser(
  .reset(reset),
  .clk(clk),
  .rin(rin),
  .rout(rout),
  .din(miso),
  .send(send),
  .txbusy(txbusy),
  .ready(ready),
  .rxerr(rxerr),
  .dout(mosi)
);

modbus_endpoint #(
  .TMOSIZE(TMOSIZE),
  .TMOMAX(TMOMAX)
) mod (
  .reset(reset),
  .clk(clk),
  .timeout_clk(clk),
  .maddr(maddr),
  .dout(miso),
  .send(send),
  .txbusy(txbusy),
  .ready(ready),
  .rxerr(rxerr),
  .din(mosi),
  .valid(valid),
  .iswrite(iswrite),
  .addr(addr),
  .wdata(wdata),
  .rdata(rdata),
  .ack(ack),
  .frame_busy(frame_busy),
  .frame_err(frame_err)
);

endmodule
