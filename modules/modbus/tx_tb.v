module test;

`include "utest.vlib"
`define TMOMAX 8'hff
`include "mtest.vlib"

`TEST_PRELUDE(21)

`TEST_CLOCK(clk,10);

`TEST_TIMEOUT(4000)

task mod_tx;
  input [15:0] addr;
  input [15:0] val;
  begin
  $display("# write %04x <- %04x", addr, val);
  mod_rx_msg(5, 6, addr, val);

  while(~dut.valid) @(posedge clk);
  `ASSERT_EQUAL(dut.addr, addr, "Address")
  `ASSERT_EQUAL(dut.iswrite, 1, "Write")
  `ASSERT_EQUAL(dut.wdata, val, "Data")

  ack   <= 1;
  while(dut.valid) @(posedge clk);
  ack   <= 0;

  uart_rx(scratch[7:0]);
  `ASSERT_EQUAL(scratch[7:0], 5, "RX slave address")
  uart_rx(scratch[7:0]);
  `ASSERT_EQUAL(scratch[7:0], 6, "RX function")
  uart_rx(scratch[7:0]);
  `ASSERT_EQUAL(scratch[7:0], addr[15:8], "RX echo addr1")
  uart_rx(scratch[7:0]);
  `ASSERT_EQUAL(scratch[7:0], addr[7:0], "RX echo addr2")
  uart_rx(scratch[7:0]);
  `ASSERT_EQUAL(scratch[7:0], val[15:8], "RX echo val1")
  uart_rx(scratch[7:0]);
  `ASSERT_EQUAL(scratch[7:0], val[7:0], "RX echo val2")

  crc_scratch = crcrx.crc;
  uart_rx(scratch[7:0]);
  uart_rx(scratch[15:8]);
  `ASSERT_EQUAL(crc_scratch, scratch, "RX CRC")

  crctx_reset <= 1;
  crcrx_reset <= 1;
  @(posedge clk);
  crctx_reset <= 0;
  crcrx_reset <= 0;

  end
endtask

initial
begin
  `TEST_INIT(test)
  @(posedge clk);
  reset <= 0;
  @(posedge clk);

  `ASSERT_EQUAL(dut.state, dut.S_IDLE, "IDLE")

  $display("# Test Write single HOLDING");
  mod_tx(0, 1);
  mod_tx(16'h1234, 16'h4567);

  //$display("# Test READ ERRORS");
  //mod_except();

  #4
  `TEST_DONE
end

endmodule
