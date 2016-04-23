module uart_tx(
  input wire       clk,  // bit clock
  input wire       send, // command to send
  input wire [0:7] in,
  output reg       done,
  output reg       out
);

wire [0:9] frame = {1'b0, in, 1'b1};

reg [3:0] cnt;

always @(posedge clk)
  if(!send)
  begin
    cnt  <= 0;
    out  <= frame[0];
    done <= 0;
  end
  else if(cnt==0)
  begin
    cnt  <= 9;
    out  <= frame[9];
    done <= 0;
  end
  else
  begin
    cnt  <= cnt-1;
    out  <= frame[cnt-1];
    done <= cnt==1;
  end

endmodule
