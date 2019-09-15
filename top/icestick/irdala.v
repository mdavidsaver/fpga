`timescale 1us/1ns

// Use icestick to analyze IR remote traffic
module irdala(
    input clk, // 12 MHz

    // UART
    output sertx_n,

    input rx,
    output sd,

    output [1:0] debug,

    output [4:0] led
);
    // pull down to enable
    assign sd = 0;

    wire proc;
    vbounce bounce(
        .clk(clk),
        .in(~rx), // rx is active low, flip this to active high for sanity
        .out(proc)
    );

    // allow use of oscilliscope to verify function of vbounce filter
    assign debug[0] = rx;
    assign debug[1] = proc;

    icela la(
        .clk(clk),
        .sertx_n(sertx_n),
        .pin({6'h00, proc}),
        .led(led)
    );

endmodule




// account for Vishay TFDU4101 receiver intended for IRDA data links.
// We will abuse this for simpler/slower remote control protocol.
// A CW signal appears as 2.2us (26 ticks) pulses with 27.2us (326 ticks) seperation.
// a longer seperation implies !CW
//
// This is a counting filter to de-bounce the likely noisy pulse train
module vbounce(
    input clk,
    input in, // active high
    output out
);

// round 326 up to 512
wire [8:0] cnt;

sat_counter #(
    .WIDTH(9),
    .MAX(500),
    .INC(20)
) counter(
    .clk(clk),
    .dir(in),
    .cnt(cnt)
);

localparam THRESHOLD = 200;

reg out = 0;

wire [1:0] state = {out, in};

always @(posedge clk)
  case(state)
  2'b00:begin // idle
    out <= 0;
  end
  2'b01:begin // rising
    out <= cnt>=THRESHOLD;
  end
  2'b11:begin // active
    out <= 1;
  end
  2'b10:begin // falling
    out <= cnt!=0;
  end
  endcase

endmodule

module sat_counter (
    input clk,
    input dir,
    output [(WIDTH-1):0] cnt
);

parameter WIDTH = 8;
parameter MAX = 255;
parameter DEC = 1;
parameter INC = 1;

reg [(WIDTH-1):0] cnt = 0;

always @(posedge clk)
    if(dir && cnt >= MAX - INC) // cnt + INC >= MAX
        cnt <= MAX;
    else if(dir)
        cnt <= cnt + INC;
    else if(cnt < DEC)
        cnt <= 0;
    else
        cnt = cnt - DEC;

endmodule
