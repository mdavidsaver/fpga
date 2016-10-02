module modstick_logic(
  input         reset,
  input         clk,  // ref clock

  // bus
  input         valid,
  input         iswrite,
  input  [15:0] addr,
  input  [15:0] wdata,
  output [15:0] rdata,
  output        ack,

  // modbus EP status
  input         frame_err,
  
  output  [4:0] leds
);

localparam A_ID = 0,
           A_STATUS = 1,
           A_LED = 2,
           A_MB = 3;

reg ack = 0;
reg [15:0] rdata;
reg [4:0] leds = 0;

reg moderr = 0;
reg [15:0] mbox = 0;

always @(posedge clk)
  if(reset) begin
    ack    <= 0;
    rdata  <= 0;
    leds   <= 0;
    moderr <= 0;
    mbox   <= 0;
  end else begin
    ack <= valid;
    if(frame_err) moderr <= 1;
    leds[1] <= moderr;

    if(valid & iswrite) case(addr)
      A_STATUS: if(wdata[0]) moderr <= 0;
      A_LED:                 {leds[4:2], leds[0]}   <= {wdata[4:2], wdata[0]};
      A_MB:                  mbox   <= wdata;
    endcase
    else if (valid & ~iswrite) case(addr)
      A_ID:     rdata <= 16'h1234;
      A_STATUS: rdata <= {15'h00, moderr};
      A_LED:    rdata <= {11'h00, leds};
      A_MB:     rdata <= mbox;
      default:  rdata <= 16'hbeef;
    endcase
  end

endmodule
