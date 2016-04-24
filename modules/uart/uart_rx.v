module uart_rx(
  input wire       ref_clk,
  input wire       samp_clk,
  input wire       in,
  input wire       reset,
  output reg [0:7] out,
  output wire      busy,
  output reg       ready,
  output reg       err,
  output wire      bit_clk
);

parameter Oversample = 3;

reg [Oversample:0] phase_cnt = 0;

// Start the phase counter on the rising edge of the start bit
always @(posedge ref_clk)
  if(samp_clk)
  begin
    if(reset || state==0)
      phase_cnt <= 0;
    else
      phase_cnt <= phase_cnt[Oversample-1:0]+1;
  end

// samples 90 deg. after rising edge
assign bit_clk = phase_cnt==(2**Oversample)/2-1; //{1'b0, {Oversample-1{1'b1}}};

reg [3:0] state = 0;

assign busy = state!=0;

always @(posedge ref_clk)
  if(!samp_clk)
  begin
    // no op
  end 
  else if(reset)
  begin
    ready <= 0;
    out   <= 0;
    state <= 0;
    err   <= 0;
  end
  else if(state==0) // wait for rising edge of start bit
  begin
    ready <= 0;
    out   <= 0;
    err   <= 0;
    if(in==0) state <= 0; // continue waiting
    else      state <= 1; // have start bit, phase_cnt starts to run
  end
  else if(!bit_clk) // don't proceed unless sync'd
  begin
    // noop
  end
  else if(state==1) // sample start bit
  begin
    ready <= 0;
    out   <= 0;
    if(in==0) state <= 0; // triggered on noise, reset
    else      state <= 2; // have start bit
  end
  else if(state==10) // check for stop bit
  begin
    state <= 0;
    if(in==1) // not stop bit, bad frame (reset)
    begin
      ready <= 0;
      out   <= 0;
      err   <= 1;
    end
    else
    begin // have stop bit
      ready <= 1;
      out   <= out;
    end
  end
  else
  begin // sample data bit
    ready <= 0;
    out   <= {in, out[0:6]};
    state <= state+1;
  end

endmodule
