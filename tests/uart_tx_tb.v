module test;

`include "utest.vlib"

`TEST_PRELUDE(87)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(200)

reg send = 0;
reg [7:0] in = 0, dout;
wire done, done1, out;

uart_tx D(
  .ref_clk(clk),
  .bit_clk(clk),
  .send(send),
  .in(in),
  .done(done),
  .done1(done1),
  .out(out)
);

// shift register to capture output when active (!done)
always @(negedge clk)
  if(~done & ~done1)
    dout = {out, dout[7:1]};

`define TICK @(posedge clk); @(negedge clk);

`define CHECK(MSG, D,O) `DIAG(MSG) `ASSERT_EQUAL(done,D) `ASSERT_EQUAL(out,O)

task uart_send;
  input [7:0] data;
  begin
    $display("uart_send expect %x", data);
    `CHECK("Start bit",done,1) // don't care about done

    `TICK
    `CHECK("Bit 0",0,data[0])

    `TICK
    `CHECK("Bit 1",0,data[1])

    `TICK
    `CHECK("Bit 2",0,data[2])

    `TICK
    `CHECK("Bit 3",0,data[3])

    `TICK
    `CHECK("Bit 4",0,data[4])

    `TICK
    `CHECK("Bit 5",0,data[5])

    `TICK
    `CHECK("Bit 6",0,data[6])

    `TICK
    `CHECK("Bit 7",0,data[7])

    `TICK
    `CHECK("Stop bit",0,0)

    `DIAG("Actual")
    `ASSERT_EQUAL(data, dout)
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

  `DIAG("Start Sending 1")
  send = 1;

  `TICK
  uart_send(8'b10101001);
  send = 0;

  in = 8'b11001010;

  `TICK
  `CHECK("Idle",1,0)  // done
  `TICK
  `CHECK("Idle",0,0)
  `TICK
  `CHECK("Idle",0,0)

  `DIAG("Start Sending 2")
  send = 1;
  `TICK
  uart_send(8'b11001010);

  @(posedge done);
  `TIME
  `DIAG("Start Sending w/o idle")
  in = 8'b11010010;
  uart_send(8'b11010010);  

  `DIAG("Use handshaking")
  send = 0;
  `TICK
  `CHECK("Idle",1,0)
  `TICK

  @(posedge clk);
  send = 1;
  in = 8'ha1;

  @(posedge done);
  `ASSERT_EQUAL(in, dout)

  in = 8'hb2;
  @(posedge done);
  `ASSERT_EQUAL(in, dout)

  in = 8'hc3;
  @(posedge done);
  `ASSERT_EQUAL(in, dout)

  send = 0;
  
  `TICK
  `CHECK("Idle",0,0)
  `TICK
  `TICK
  `TICK
  @(posedge clk);
  `CHECK("Idle",0,0)

  send = 1;
  in = 8'hd4;
  @(posedge done);
  `ASSERT_EQUAL(in, dout)

  send = 0;
  `TICK
  @(posedge clk);
  `CHECK("Idle",0,0)

  `TEST_DONE
end

endmodule
