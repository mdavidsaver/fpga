/* sample buffer with two modes.
 * after reset is circular buffer will silent roll-over
 * after freeze switch to FIFO until full
 */
module scope_buffer(
  input clk,
  
  input reset,
  input freeze,
  
  input [(N-1):0] din,
  input           din_latch,

  output [(N-1):0] dout,
  input            dout_pop,
  output           dout_ready,
  output           dout_oflow
);

parameter N = 8;

// sample buffer depth is 2**NSAMP
parameter NSAMP = 4;
localparam DEPTH = 1<<NSAMP;

reg [(N-1):0] mem [0:(DEPTH-1)];

reg [(N-1):0] rptr;
reg [(N-1):0] wptr;

wire empty = wptr==rptr;
wire full  = (wptr+1)==rptr;

assign dout_ready = mode==S_FIFO & ~empty;
assign dout_oflow = mode==S_FIFO & full;

localparam S_CIRC = 0,
           S_FIFO = 1;
reg mode;

assign dout = mem[rptr];

always @(posedge clk)
  if(reset)
    mode <= S_CIRC;
  else if(freeze)
    mode <= S_FIFO;

always @(posedge clk)
  if(reset) begin
    rptr <= 0;
    wptr <= 0;
  end else case(mode)
  S_CIRC: begin
    if(din_latch) begin
      mem[wptr] <= din;
      wptr      <= wptr + 1;
      if(full | dout_pop)
        rptr    <= rptr + 1;
    end
  end
  S_FIFO: begin
    if(din_latch & ~full) begin
      mem[wptr] <= din;
      wptr      <= wptr + 1;
    end
    if(dout_pop)
      rptr      <= rptr + 1;
  end
  endcase

endmodule
