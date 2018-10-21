`timescale 1us/1ns
/* RS232 receiver
 */
module uart_rx(
  input wire       ref_clk,   // logic clock
  input wire       samp_clk,  // bit sampling clock
  input wire       in,
  input wire       reset,
  output reg [7:0] out,
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
assign bit_clk = samp_clk & phase_cnt==(2**Oversample)/2-1; //{1'b0, {Oversample-1{1'b1}}};


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

reg [3:0] state = S_IDLE;

assign busy = state!=S_IDLE;

always @(posedge ref_clk)
  begin
    ready <= 0;
    err   <= 0;
    if(reset) begin
      out   <= 0;
      state <= S_IDLE;
    end else if(state==S_IDLE) begin
      // handle S_IDLE specially as the transition from IDLE -> START
      // resets the phase of bit_clk
      out   <= 0;
      state <= in ? S_START : S_IDLE;
    end else if(bit_clk) case(state)
    S_START:begin
        state <= in ? S_BIT0 : S_IDLE;
    end
    S_BIT0: begin
        out[0] <= ~in;
        state  <= S_BIT1;
    end
    S_BIT1: begin
        out[1] <= ~in;
        state  <= S_BIT2;
    end
    S_BIT2: begin
        out[2] <= ~in;
        state  <= S_BIT3;
    end
    S_BIT3: begin
        out[3] <= ~in;
        state  <= S_BIT4;
    end
    S_BIT4: begin
        out[4] <= ~in;
        state  <= S_BIT5;
    end
    S_BIT5: begin
        out[5] <= ~in;
        state  <= S_BIT6;
    end
    S_BIT6: begin
        out[6] <= ~in;
        state  <= S_BIT7;
    end
    S_BIT7: begin
        out[7] <= ~in;
        state  <= S_STOP;
    end
    S_STOP:begin
        state <= S_IDLE;
        if(!in) begin
          ready <= 1;
        end else begin
          err   <= 0;
        end
    end
    endcase
  end

endmodule
