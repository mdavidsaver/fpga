`timescale 1us/1ns
module spi_master_inst(
    input clk,   // bit clock
    input reset, // sync reset

    // from spi_master_ctrl
    input [(3+BYTES):0] cnt,

    // bus signals
    output reg mosi,
    input miso,

    // for user logic
    input  [(8*BYTES-1):0] mdat, // data this master will send.  update on controller ready.  remain stable otherwise
    output [(8*BYTES-1):0] sdat  // slave data received.  sample on controller ready.  unstable otherwise
);

parameter BYTES = 1;   // number of bytes per frame

localparam BITS = 8*BYTES + 2;

wire [0:(BITS-1)] frame = {2'b00, mdat};

always @(posedge clk)
    if(cnt[0])
        mosi <= frame[cnt[(3+BYTES):1]];

reg [(BITS-1):0] dshift;

always @(posedge clk)
    if(~cnt[0])
        dshift <= {dshift[(BITS-2):0], miso};

assign sdat = dshift;

endmodule
