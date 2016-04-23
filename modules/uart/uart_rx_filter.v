module uart_rx_filter(
  input wire samp_clk,
  input wire in,
  input wire bit_clk,
  output reg out
);

reg [1:0] sync; // synchronize async input with shift register
wire in_sync = sync[0];

reg [1:0] cnt = 0; // counting deadband filter to de-bounce

always @(posedge samp_clk)
  if(bit_clk)
  begin
    sync <= {in, sync[1]};

    if(in_sync==1 && cnt!=2'b11)
      cnt <= cnt+1;
    else if(in_sync==0 && cnt!=2'b00)
      cnt <= cnt-1;
    else
      cnt <= cnt;

    if(cnt==2'b11)
      out <= 1;
    else if(cnt==2'b00)
      out <= 0;
    else
      out <= out;
  end

endmodule
