module uart_rx(
  input wire       clk,  // bit clock
  input wire       in,
  input wire       reset,
  output reg [0:7] out,
  output reg       ready
);

reg [3:0] state = 0;

always @(posedge clk)
  if(reset)
  begin
    ready <= 0;
    out   <= 0;
    state <= 0;
  end
  else if(state==0) // wait for start bit
  begin
    ready <= 0;
    out   <= 0;
    if(in==0)
    begin // continue waiting
      state <= 0;
    end
    else
    begin // have start bit
      state <= 1;
    end
  end
  else if(state==9) // check for stop bit
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
  begin
    ready <= 0;
    out   <= {in, out[0:6]};
    state <= state+1;
  end

endmodule
