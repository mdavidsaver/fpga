module uart_tx(
  input wire       ref_clk,
  input wire       bit_clk,
  input wire       send, // command to send
  input wire [0:7] in,
  output reg       done, // high at end of frame
  output reg       done1,// high after last data bit send, stop bit not yet sent
  output reg       out
);

wire [0:9] frame = {1'b0, in, 1'b1};

reg [3:0] cnt;

always @(posedge ref_clk)
  if(!send | bit_clk)
    done <= done1;

always @(posedge ref_clk)
  if(!send)
  begin
    cnt  <= 0;
    out  <= frame[0];
    done1<= 0;
  end
  else if(!bit_clk) begin end
  else if(cnt==0)
  begin
    cnt  <= 9;
    out  <= frame[9];
    done1<= 0;
  end
  else
  begin
    cnt  <= cnt-1;
    out  <= frame[cnt-1];
    done1<= cnt==1;
  end

endmodule
