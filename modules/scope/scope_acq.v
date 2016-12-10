module scope_acq(
  input clk,

  input [(NSIG-1):0] sig,
  input              triggered, // trigger condition meet
  input              changed,   // some input changed

  input [1:0] cmd,
  input       cmd_latch,

  output [1:0] sts,

  output [(NSIG+NSAMP-1):0] dout,
  output                    ready, // some data is ready
  input                     pop    // advance the read pointer
);

// number of input signals
parameter NSIG = 1;

// sample buffer depth is 2**NSAMP
parameter NSAMP = 4;

// time stamp counter size is 2**NTIME
parameter NTIME = 3;


localparam STS_IDLE = 0,
           STS_ARM  = 1,
           STS_RUN  = 2,
           STS_DONE = 3;
reg [1:0] sts;

localparam CMD_STOP = 0,
           CMD_ARM  = 1,
           CMD_TRG  = 2;

// sample buffer

wire boflow;
reg bfreeze,

scope_buffer #(
  .N(NSIG+NSAMP),
  .NSAMP(NSAMP)
) sbuf (
  .clk(clk),
  .reset(sts==STS_IDLE),
  .freeze(bfreeze),
  .din({tcnt, sig}),
  .din_latch(changed | tcnt_roll),
  .dout(dout),
  .dout_ready(ready),
  .dout_pop(pop),
  .dout_oflow(boflow)
);

// timestamp counter

reg [(NTIME-1):0] tcnt;
reg tcnt_roll;

always @(posedge clk)
  if(sts==STS_IDLE) begin
    tcnt      <= 0;
    tcnt_roll <= 0;
  end else begin
    {tcnt_roll, tcnt} <= tcnt+1;
  end


always @(posedge clk)
  begin
  bfreeze <= 0;
  case (sts)
  STS_IDLE:begin
    if(cmd_latch) case(cmd)
      CMD_ARM:  sts <= STS_ARM;
      CMD_TRG:  sts <= STS_ARM; // alias for ARM
      CMD_STOP: sts <= STS_IDLE;
    endcase
  end
  STS_ARM:begin
      if(triggered | (cmd_latch & cmd==CMD_TRG)) begin
        sts <= STS_RUN;
        bfreeze <= 1;
      end else if(cmd_latch & cmd==CMD_STOP)
        sts <= STS_IDLE;
      //CMD_ARM  ignored
    end
  STS_RUN:begin
    if(boflow | (cmd_latch & cmd==CMD_STOP)
      sts     <= STS_DONE;
    // CMD_ARM and CMD_TRG ignored
  end
  STS_DONE:if(cmd_latch & cmd==CMD_STOP)
    sts <= STS_IDLE;
  endcase
  end

endmodule
