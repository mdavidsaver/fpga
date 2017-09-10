module test;

`include "utest.vlib"
`TEST_CLOCK(clk,10);

`define TMOMAX 8'hff
`include "mtest.vlib"

`TEST_PRELUDE(19)

`TEST_TIMEOUT(4000)

task mod_rx;
  input [15:0] addr;
  input [15:0] cnt;
  begin
  $display("# read %04x cnt %04x", addr, cnt);
  mod_rx_msg(5, 3, addr, cnt);

  uart_rx(scratch[7:0]);
  `ASSERT_EQUAL(scratch[7:0], 5, "RX slave address")
  uart_rx(scratch[7:0]);
  `ASSERT_EQUAL(scratch[7:0], 3, "RX function")
  uart_rx(scratch[7:0]);
  `ASSERT_EQUAL(scratch[7:0], cnt*2, "RX length in bytes")

  for(i=0; i<cnt; i=i+1) begin
    while(~dut.valid) @(posedge clk);
    rdata <= 16'habcd ^ addr+i;
    ack   <= 1;
    $display("Bus Read %04x", dut.addr);
    `ASSERT_EQUAL(dut.iswrite, 0, "Read")
    while(dut.valid) @(posedge clk);
    rdata <= 16'hxx;
    ack   <= 0;

    uart_rx(scratch[15:8]);
    uart_rx(scratch[7:0]);
    `ASSERT_EQUAL(scratch, 16'habcd ^ addr+i, "RX data")
  end

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

  $display("# Test READ HOLDING");
  mod_rx(0, 1);
  mod_rx(16'h1234, 4);

  //$display("# Test READ ERRORS");
  //mod_except();

  #4
  `TEST_DONE
end

endmodule
