module test;

`include "utest.vlib"

`TEST_PRELUDE(14)

`TEST_CLOCK(clk,10);

`TEST_TIMEOUT(4000)

reg reset = 1, txbusy = 0, ready;
reg [7:0] serrx;

reg [15:0] rdata;
reg ack = 0;

modbus_endpoint dut(
  .clk(clk),
  .timeout_clk(clk),
  .reset(reset),
  .maddr(5),
  .txbusy(txbusy),
  .ready(ready),
  .rxerr(0),
  .din(serrx),
  .rdata(rdata),
  .ack(ack)
);

// TX -> MOSI
reg crctx_reset=1;
reg [15:0] crc_scratch;
mcrc crctx(
  .clk(clk),
  .reset(crctx_reset),
  .ready(ready),
  .din(serrx)
);

task uart_tx;
  input [7:0] val;
  begin
    $display("# -> %02x", val);
    @(negedge clk);
    serrx <= val;
    ready <= 1;
    @(negedge clk);
    serrx <= 8'hxx;
    ready <= 0;
    @(negedge clk);
  end
endtask

// RX -> MISO
reg crcrx_reset=0, crcrx_latch=0;
mcrc crcrx(
  .clk(clk),
  .reset(crcrx_reset),
  .ready(crcrx_latch),
  .din(dut.dout)
);

task uart_rx;
  output [7:0] val;
  begin
    while(~dut.send) @(posedge clk);
    crcrx_latch <= 1;
    val <= dut.dout;
    txbusy <= 1;
    @(posedge clk);
    crcrx_latch <= 0;
    while(dut.send) @(posedge clk);
    txbusy <= 0;
    $display("# <- %02x", val);
  end
endtask

integer i;
reg [15:0] scratch;

task mod_rx;
  input [15:0] addr;
  input [15:0] cnt;
  begin
  $display("# read %04x cnt %04x", addr, cnt);

  crctx_reset <= 1;
  @(negedge clk);
  crctx_reset <= 0;

  uart_tx(5); // slave address
  uart_tx(3); // function, read holding
  uart_tx(addr>>8);
  uart_tx(addr);
  uart_tx(cnt>>8);
  uart_tx(cnt);
  crc_scratch = crctx.crc;
  uart_tx(crc_scratch);
  uart_tx(crc_scratch>>8);

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
    $display("Bus Read %04x", addr);
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

  mod_rx(0, 1);
  mod_rx(16'h1234, 4);

  #4
  `TEST_DONE
end

endmodule
