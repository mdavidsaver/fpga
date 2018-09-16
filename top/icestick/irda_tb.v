`timescale 1us/1ns
module test;

`include "utest.vlib"

`TEST_PRELUDE(1)

`TEST_CLOCK(clk,0.042); // ~12MHz

`TEST_TIMEOUT(200000)

reg in = 0;

top dut(
    .clk(clk),
    .rx(~in) // actual signal in active low
);


// a 
task pulse;
  input integer N;
  integer n;
  begin
    for(n=0; n<N; n=n+1) begin
        in <= 1;
        #2.2
        in <= 0;
        #27.2
        in <= 0;
    end
  end
endtask

integer i;

task send;
  input [7:0] val;
  begin
    // START pulse
    pulse(119); // 3500us
    #1700
    in <= 0;
    for(i=0; i<8; i=i+1) begin
        pulse(15); // 440us
        if(val[7-i])
          #1300 in<=0;
        else
          #440 in<=0;
    end
    pulse(16);
  end
endtask

initial
begin
  `TEST_INIT(test)
  #4500

  send(8'b10101100);

  #4500

  `ASSERT(1, "foo");
  `TEST_DONE
end

endmodule
