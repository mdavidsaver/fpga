/* RS232 transmitter

 protocol
 1. Assert 'in' and set 'send' to 1.
 2. Wait for 'busy'==1, may deassert 'send'
 3. Wait for 'busy'==0, complete
*/
module uart_tx(
  input wire       ref_clk,
  input wire       bit_clk,
  input wire       send, // command to send
  input wire [7:0] in,
  output           busy, // rising edge with 'send', falling edge after stop bit
  output reg       out
);

reg busy;
reg [7:0] data;
reg [3:0] state = 0;

always @(posedge ref_clk)
  case(state)
  0:begin // IDLE
    busy  <= send;
    data  <= in;
    state <= send ? 1 : 0;
    out   <= 0;
  end
  1:if(bit_clk) // start bit
    begin
      out   <= 1;
      state <= 2;
    end
  2:if(bit_clk) // data bit 0
    begin
      out   <= ~data[0];
      state <= 3;
    end
  3:if(bit_clk) // data bit 1
    begin
      out   <= ~data[1];
      state <= 4;
    end
  4:if(bit_clk) // data bit 2
    begin
      out   <= ~data[2];
      state <= 5;
    end
  5:if(bit_clk) // data bit 3
    begin
      out   <= ~data[3];
      state <= 6;
    end
  6:if(bit_clk) // data bit 4
    begin
      out   <= ~data[4];
      state <= 7;
    end
  7:if(bit_clk) // data bit 5
    begin
      out   <= ~data[5];
      state <= 8;
    end
  8:if(bit_clk) // data bit 6
    begin
      out   <= ~data[6];
      state <= 9;
    end
  9:if(bit_clk) // data bit 7
    begin
      out   <= ~data[7];
      state <= 10;
    end
  10:if(bit_clk) // Stop bit
    begin
      out   <= 0;
      state <= 11;
    end
  11:if(bit_clk) // end of stop bit
    begin
      out   <= 0;
      state <= 0; // return to idle (TODO: check 'send' here for fast start?)
      busy  <= 0;
    end
  endcase

endmodule
