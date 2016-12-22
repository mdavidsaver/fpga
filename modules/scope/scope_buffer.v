/* sample buffer with two modes.
 * after reset is circular buffer will silent roll-over
 * after freeze switch to FIFO until full
 */
module scope_buffer(
  input clk,
  
  input reset,
  input trigger,
  input halt,

  output triggered,
  output done,

  input [(NSAMP-1):0] npost,  

  input [(N-1):0] din,
  input           din_latch,

  output [(N-1):0] dout,
  input            dout_pop,
  output           dout_ready
);

parameter N = 8;

// sample buffer depth is 2**NSAMP
parameter NSAMP = 4;
localparam DEPTH = 1<<NSAMP;

reg triggered;
always @(posedge clk)
  if(reset)
    triggered <= 0;
  else if(trigger)
    triggered <= 1;

reg [(NSAMP-1):0] postcnt;
always @(posedge clk)
  if(trigger & ~triggered)
    postcnt <= npost;
  else if(din_latch & postcnt!=0)
    postcnt <= postcnt - 1;

reg done;
always @(posedge clk)
  if(reset)
    done <= 0;
  else if(halt | (din_latch & triggered & postcnt<=1))
    done <= 1;

reg [(NSAMP-1):0] rptr;
always @(posedge clk)
  if(reset)
    rptr <= 0;
  else if(dout_pop | (store & wptr_next==rptr))
    rptr <= rptr + 1;

reg [(NSAMP-1):0] wptr;
wire [(NSAMP-1):0] wptr_next = wptr+1;
always @(posedge clk)
  if(reset)
    wptr <= 0;
  else if(store)
    wptr <= wptr + 1;

wire store = din_latch & (~triggered | postcnt!=0);

wire dout_ready = done & wptr!=rptr;

reg [(N-1):0] mem [0:(DEPTH-1)];

assign dout = mem[rptr];
always @(posedge clk)
  if(store)
    mem[wptr] <= din;

endmodule
