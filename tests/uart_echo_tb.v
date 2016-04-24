module test;

`include "utest.vlib"

`TEST_PRELUDE(6)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(10000)

reg send = 0, reset = 1, rin;
wire done, rout, ready, tx_bit_clk, rx_bit_clk, samp_clk;
wire [7:0] drx;
reg [7:0] dtx;
reg [7:0] expect;
reg [7:0] actual;

uart #(
  .Width(2),
  .Incr(1)
)D(
  .reset(reset),
  .clk(clk),

  .rin(rin),
  .rout(rout),

  .din(dtx),
  .send(send),
  .done(done),

  .dout(drx),
  .ready(ready),

  .samp_clk(samp_clk),
  .rx_bit_clk(rx_bit_clk),
  .tx_bit_clk(tx_bit_clk)
);

// echo logic
always @(posedge samp_clk)
  if(reset)
  begin
    rin <= 0;
    send <= 0;
    dtx  <= 8'bx;
  end
  else if(ready)
  begin
    dtx  <= drx;
    send <= 1;
  end
  else if(done)
  begin
    dtx  <= 8'bx;
    send <= 0;
  end

// shift register to capture output when active (!done)
always @(negedge tx_bit_clk)
  begin
    if(done)
      actual = {1'bx, actual[7:1]};
    else
      actual = {rout, actual[7:1]};
  end

`define TICK @(posedge tx_bit_clk); @(negedge tx_bit_clk);
`define CHECK(MSG, D,O) `DIAG(MSG) `ASSERT_EQUAL(done,D) `ASSERT_EQUAL(out,O)

task uart_txrx;
  input [7:0] val;
  begin
    `DIAG("uart_txrx")
    @(negedge tx_bit_clk);
    expect = val;
    rin = 1;
    @(negedge tx_bit_clk);
    rin = val[0];
    @(negedge tx_bit_clk);
    rin = val[1];
    @(negedge tx_bit_clk);
    rin = val[2];
    @(negedge tx_bit_clk);
    rin = val[3];
    @(negedge tx_bit_clk);
    rin = val[4];
    @(negedge tx_bit_clk);
    rin = val[5];
    @(negedge tx_bit_clk);
    rin = val[6];
    @(negedge tx_bit_clk);
    rin = val[7];
    @(negedge tx_bit_clk);
    rin = 0;
    @(posedge done);
    `ASSERT_EQUAL(expect, actual)
  end
endtask

initial
begin
  `TEST_INIT(test)

  #16
  reset = 0;
  `TICK
  `TICK
  `ASSERT_EQUAL(0, done)
  `ASSERT_EQUAL(0, ready)

  uart_txrx(8'b10101001);
  uart_txrx(8'b10011001);
  #1001
  uart_txrx(8'b10110001);
  uart_txrx(8'b11101010);
  
  `TICK
  `TICK
  `TEST_DONE
end

endmodule
