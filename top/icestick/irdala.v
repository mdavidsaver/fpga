`timescale 1us/1ns

// Use icestick to analyze IR remote traffic
module irdala(
    input clk, // 12 MHz 83.3ns

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
        .pin({5'h00, proc, rx}),
        .led(led)
    );

endmodule




// account for Vishay TFDU4101 receiver intended for IRDA data links.
// We will abuse this for simpler/slower remote control protocol.
// Daikin remote signal appears as 2.2us (26 ticks) pulses with 27.2us (326 ticks) seperation.
// irhat signal appears as 2.2us pulses with 200us seperation (2400 ticks)
//
// This is a counting filter to stretch any pulse out to ~200us
module vbounce(
    input clk,
    input in, // active high
    output out
);

reg [11:0] cnt=0;

always @(posedge clk)
  if(in)
    cnt <= 2500;
  else if(~in && cnt > 0)
    cnt <= cnt-1;
  else
    cnt <= cnt;

assign out = cnt > 0;

endmodule
