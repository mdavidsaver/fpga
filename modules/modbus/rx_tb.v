module test;

`include "utest.vlib"

`TEST_PRELUDE(12)

`TEST_CLOCK(clk,10);

`TEST_TIMEOUT(2000)

reg reset = 1, txbusy = 0, ready;
reg [7:0] serrx;

reg [15:0] rdata;
reg ack;

modbus_endpoint dut(
  .clk(clk),
  .reset(reset),
  .maddr(5),
  .txbusy(txbusy),
  .ready(ready),
  .rxerr(0),
  .din(serrx),
  .rdata(rdata),
  .ack(ack)
);

reg send_prev;
always @(posedge clk)
  send_prev <= dut.send;

reg [7:0] sertx;
always @(posedge clk)
  if({dut.send, send_prev}==2'b10)
  begin
    txbusy <= 1;
    sertx  <= dut.dout;
    $display("# sertx latch %02x", dut.dout);
  end

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

task uart_rx;
  output [7:0] val;
  begin
    if(~txbusy) @(posedge txbusy);
    if(dut.send) @(negedge dut.send);
    val <= sertx;
    @(negedge clk);
    txbusy <= 0;
    $display("# <- %02x", val);
  end
endtask

integer i;

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

  uart_rx(cnt[7:0]);
  `ASSERT_EQUAL(cnt[7:0], 5, "RX slave address")
  uart_rx(cnt[7:0]);
  `ASSERT_EQUAL(cnt[7:0], 3, "RX function")
  uart_rx(cnt[7:0]);
  `ASSERT_EQUAL(cnt[7:0], 2, "RX length in bytes")

  for(i=0; i<cnt; i=i+1) begin
    while(~dut.valid) @(posedge dut.valid);
    rdata <= addr;
    ack   <= 1;
    $display("Bus Read %04x", addr);
    @(negedge dut.valid);
    rdata <= 16'hxx;
    ack   <= 0;
  end

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

  `TEST_DONE
end

endmodule
