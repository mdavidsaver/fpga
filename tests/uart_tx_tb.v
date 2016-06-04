module test;

`include "utest.vlib"

`TEST_PRELUDE(28)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(2000)

reg [2:0] clk4cnt = 0;
wire clk4 = clk4cnt[2];
always @(posedge clk)
  clk4cnt[2:0] <= clk4cnt[1:0]+1;

reg send = 0;
reg [7:0] in = 0, dout;
wire busy, out;

uart_tx D(
  .ref_clk(clk),
  .bit_clk(clk4),
  .send(send),
  .in(in),
  .busy(busy),
  .out(out)
);

reg [9:0] capture;
wire [7:0] cdata = capture[8:1];
wire cstart = capture[0], cstop = capture[9];
always @(posedge clk4)
  capture <= {out, capture[9:1]};

`define TICK @(posedge clk4);

`define CHECK(MSG, B,O) `DIAG(MSG) `ASSERT_EQUAL(busy,B) `ASSERT_EQUAL(out,O)

task uart_send;
  input [7:0] data;
  begin
    $display("uart_send expect %x", data);
    in   <= data;
    send <= 1;

    @(posedge busy);
    send <= 0;
    in   <= 8'hxx;

    @(negedge busy);
    `ASSERT_EQUAL(cstart, 1)
    `ASSERT_EQUAL(~cdata, data)
    `ASSERT_EQUAL(cstop, 0)
    $display("uart_send complete");
  end
endtask

initial
begin
  `TEST_INIT(test)

  `TICK
  // output undefined
  `TICK
  `CHECK("Idle",0,0) // idle low

  `TICK
  `CHECK("Idle",0,0)

  in = 8'b10101001;
  
  `TICK
  `CHECK("Idle",0,0)

  uart_send(8'b10101001);
  uart_send(8'b11001010);
  uart_send(8'ha1);
  uart_send(8'hb2);
  uart_send(8'hc3);
  uart_send(75); // 'K'
  
  `TICK
  `CHECK("Idle",0,0)
  `TICK
  `TICK
  `TICK
  @(posedge clk);
  `CHECK("Idle",0,0)

  `TEST_DONE
end

endmodule
