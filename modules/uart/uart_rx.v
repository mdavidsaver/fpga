module uart_rx(
  input wire       clk,  // sample clock
  input wire       in,
  input wire       reset,
  output reg [0:7] out,
  output reg       ready,
  output wire      bit_clk
);

parameter Oversample = 3;

reg [Oversample:0] phase_cnt = 0;

// Start the phase counter on the rising edge of the start bit
always @(posedge clk)
  if(reset || state==0)
    phase_cnt <= 0;
  else
    phase_cnt <= phase_cnt[Oversample-1:0]+1;

// samples 90 deg. after rising edge
assign bit_clk = phase_cnt==(2**Oversample)/2-1; //{1'b0, {Oversample-1{1'b1}}};

reg [3:0] state = 0;

always @(posedge clk)
  if(reset)
  begin
    ready <= 0;
    out   <= 0;
    state <= 0;
  end
  else if(state==0) // wait for rising edge of start bit
  begin
    ready <= 0;
    out   <= 0;
    if(in==0)
    begin // continue waiting
      state <= 0;
    end
    else
    begin // have start bit
      state <= 1; // phase_cnt starts to run
    end
  end
  else if(!bit_clk) // don't proceed unless sync'd
  begin
    // noop
  end
  else if(state==1) // sample start bit
  begin
    ready <= 0;
    out   <= 0;
    if(in==0)
    begin // triggered on noise, reset
      state <= 0;
    end
    else
    begin // have start bit
      state <= 2;
    end
  end
  else if(state==10) // check for stop bit
  begin
    state <= 0;
    if(in==1) // not stop bit, bad frame (reset)
    begin
      ready <= 0;
      out   <= 0;
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
