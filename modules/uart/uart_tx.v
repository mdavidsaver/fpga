/* RS232 transmitter

 protocol
 1. Assert 'in' and set 'send' to 1.
 2. Wait for 'busy'==1, may deassert 'send'
 3. Wait for 'busy'==0, complete
*/
module uart_tx(
  input       ref_clk,
  input       bit_clk,
  input       send, // command to send
  input [7:0] in,
  output      busy, // rising edge with 'send', falling edge after stop bit
  output      out
);

localparam S_IDLE = 0,
           S_START= 1,
           S_BIT0 = 2,
           S_BIT1 = 3,
           S_BIT2 = 4,
           S_BIT3 = 5,
           S_BIT4 = 6,
           S_BIT5 = 7,
           S_BIT6 = 8,
           S_BIT7 = 9,
           S_STOP = 10,
           S_DONE = 11;

reg busy, out;
reg [7:0] data;
reg [3:0] state = S_IDLE;

always @(posedge ref_clk)
  case(state)
  S_IDLE:begin
    busy  <= send;
    data  <= in;
    state <= send ? S_START : S_IDLE;
    out   <= 0;
  end
  S_START:if(bit_clk)
    begin
      out   <= 1;
      state <= S_BIT0;
    end
  S_BIT0:if(bit_clk)
    begin
      out   <= ~data[0];
      state <= S_BIT1;
    end
  S_BIT1:if(bit_clk)
    begin
      out   <= ~data[1];
      state <= S_BIT2;
    end
  S_BIT2:if(bit_clk)
    begin
      out   <= ~data[2];
      state <= S_BIT3;
    end
  S_BIT3:if(bit_clk)
    begin
      out   <= ~data[3];
      state <= S_BIT4;
    end
  S_BIT4:if(bit_clk)
    begin
      out   <= ~data[4];
      state <= S_BIT5;
    end
  S_BIT5:if(bit_clk)
    begin
      out   <= ~data[5];
      state <= S_BIT6;
    end
  S_BIT6:if(bit_clk)
    begin
      out   <= ~data[6];
      state <= S_BIT7;
    end
  S_BIT7:if(bit_clk)
    begin
      out   <= ~data[7];
      state <= S_STOP;
    end
  S_STOP:if(bit_clk)
    begin
      out   <= 0;
      state <= S_DONE;
    end
  S_DONE:if(bit_clk) // end of stop bit
    begin
      out   <= 0;
      state <= S_IDLE;
      busy  <= 0;
    end
  endcase

endmodule
