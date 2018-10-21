`timescale 1us/1ns
module test;

`include "utest.vlib"

`TEST_PRELUDE(131)

`TEST_CLOCK(rclk,5);
`TEST_CLOCK(wclk,7);

`TEST_TIMEOUT(200000)

reg reset = 1;

reg wstore, rread;

reg  [7:0] wdata;

afifo #(
  .WIDTH(8),
  .DEPTH(2),  // memory size is 4, stores 3 elements
  .OFLOW("IGNORE")
) dut (
  .reset(reset),
  .wclk(wclk),
  .wdata(wdata),
  .wstore(wstore),
  .rclk(rclk),
  .rread(rread)
);

always @(posedge rclk)
  if (dut.rempty & dut.rfull)
  begin
    `ASSERT(0, "Read flag violation")
  end

always @(posedge wclk)
  if (dut.wempty & dut.wfull)
  begin
    `ASSERT(0, "Write flag violation")
  end

initial
begin
  `TEST_INIT(test)

  `ASSERT_EQUAL(dut.rcnt.rprev, 3, "rcnt.rprev")
  `ASSERT_EQUAL(dut.rcnt.rcnt , 0, "rcnt.rcnt")
  `ASSERT_EQUAL(dut.rcnt.rnext, 1, "rcnt.rnext")

  @(posedge wclk);
  @(posedge rclk);

  `ASSERT_EQUAL(dut.wempty,     1, "wempty")
  `ASSERT_EQUAL(dut.rempty,     1, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     0, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")

  reset <= 0;
  `DIAG("Release reset")

  @(posedge wclk);
  @(posedge wclk);

  `ASSERT_EQUAL(dut.wempty,     1, "wempty")
  `ASSERT_EQUAL(dut.rempty,     1, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     0, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")

  `DIAG("Push 0xab")
  wdata  <= 'hab;
  wstore <= 1;
  @(posedge wclk);
  wdata  <= 'hxx;
  wstore <= 0;
  #1

  `ASSERT_EQUAL(dut.wwpos,      1, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      0, "wrpos")
  `ASSERT_EQUAL(dut.wempty,     0, "wempty")
  `ASSERT_EQUAL(dut.rempty,     1, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     0, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")
  `ASSERT_EQUAL(dut.rdata ,  'hab, "wwpos")

  `DIAG("Push 0xcd")
  wdata  <= 'hcd;
  wstore <= 1;
  @(posedge wclk);
  wdata  <= 'hxx;
  wstore <= 0;
  #1

  `ASSERT_EQUAL(dut.wwpos,      3, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      1, "wrpos")
  `ASSERT_EQUAL(dut.wempty,     0, "wempty")
  `ASSERT_EQUAL(dut.rempty,     0, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     0, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")
  `ASSERT_EQUAL(dut.rdata ,  'hab, "rdata")

  `DIAG("Pop 0xab")
  rread <= 1;
  @(posedge rclk);
  rread <= 0;
  #1

  `ASSERT_EQUAL(dut.wwpos,      3, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      3, "wrpos")
  `ASSERT_EQUAL(dut.rwpos,      0, "rwpos")
  `ASSERT_EQUAL(dut.rrpos,      1, "rrpos")
  `ASSERT_EQUAL(dut.wempty,     0, "wempty")
  `ASSERT_EQUAL(dut.rempty,     0, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     0, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")
  `ASSERT_EQUAL(dut.rdata ,  'hcd, "rdata")

  `DIAG("Pop 0xcd")
  rread <= 1;
  @(posedge rclk);
  rread <= 0;
  #1

  `ASSERT_EQUAL(dut.wwpos,      3, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      3, "wrpos")
  `ASSERT_EQUAL(dut.rwpos,      0, "rwpos")
  `ASSERT_EQUAL(dut.rrpos,      3, "rrpos")
  `ASSERT_EQUAL(dut.wempty,     0, "wempty")
  `ASSERT_EQUAL(dut.rempty,     1, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     0, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")
  `ASSERT_EQUAL(dut.woverflow,  0, "woverflow")
  //`ASSERT_EQUAL(dut.rdata ,  'hcd, "rdata")

  `DIAG("Writer catches up")
  @(posedge wclk);
  #1
  `ASSERT_EQUAL(dut.rwpos,      3, "rwpos")
  `ASSERT_EQUAL(dut.wempty,     1, "wempty")

  `DIAG("Fill writer")
  `DIAG("Push 0x12")
  wdata  <= 'h12;
  wstore <= 1;
  @(posedge wclk);
  `DIAG("Push 0x34")
  wdata  <= 'h34;
  wstore <= 1;
  @(posedge wclk);
  `DIAG("Push 0x56")
  wdata  <= 'h56;
  wstore <= 1;
  @(posedge wclk);
  wdata  <= 'hxx;
  wstore <= 0;
  #1

  `ASSERT_EQUAL(dut.wwpos,      1, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      0, "wrpos")
  `ASSERT_EQUAL(dut.rwpos,      3, "rwpos")
  `ASSERT_EQUAL(dut.rrpos,      3, "rrpos")
  `ASSERT_EQUAL(dut.wempty,     0, "wempty")
  `ASSERT_EQUAL(dut.rempty,     0, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     1, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")
  `ASSERT_EQUAL(dut.woverflow,  0, "woverflow")
  `ASSERT_EQUAL(dut.rdata ,  'h12, "rdata")

  `DIAG("Contents")
  `ASSERT_EQUAL(dut.buffer[0],  'h56, "buffer[0]")
  `ASSERT_EQUAL(dut.buffer[1],  'hcd, "buffer[1]")
  `ASSERT_EQUAL(dut.buffer[3],  'h12, "buffer[3]")
  `ASSERT_EQUAL(dut.buffer[2],  'h34, "buffer[2]")

  `DIAG("Push 0x78 (lost to overflow)")
  wdata  <= 'h78;
  wstore <= 1;
  @(posedge wclk);
  wdata  <= 'hxx;
  wstore <= 0;

  `ASSERT_EQUAL(dut.wwpos,      1, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      1, "wrpos")
  `ASSERT_EQUAL(dut.rwpos,      3, "rwpos")
  `ASSERT_EQUAL(dut.rrpos,      3, "rrpos")
  `ASSERT_EQUAL(dut.wempty,     0, "wempty")
  `ASSERT_EQUAL(dut.rempty,     0, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     1, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     1, "rfull")
  `ASSERT_EQUAL(dut.woverflow,  1, "woverflow")
  #1

  `ASSERT_EQUAL(dut.wwpos,      1, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      1, "wrpos")
  `ASSERT_EQUAL(dut.rwpos,      3, "rwpos")
  `ASSERT_EQUAL(dut.rrpos,      3, "rrpos")
  `ASSERT_EQUAL(dut.wempty,     0, "wempty")
  `ASSERT_EQUAL(dut.rempty,     0, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     1, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     1, "rfull")
  `ASSERT_EQUAL(dut.woverflow,  0, "woverflow")
  `ASSERT_EQUAL(dut.rdata ,  'h12, "rdata")

  `DIAG("Contents")
  `ASSERT_EQUAL(dut.buffer[0],  'h56, "buffer[0]")
  `ASSERT_EQUAL(dut.buffer[1],  'hcd, "buffer[1]")
  `ASSERT_EQUAL(dut.buffer[3],  'h12, "buffer[3]")
  `ASSERT_EQUAL(dut.buffer[2],  'h34, "buffer[2]")

  `DIAG("Pop 0x12")
  rread <= 1;
  @(posedge rclk);
  rread <= 0;
  #1

  `ASSERT_EQUAL(dut.wwpos,      1, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      1, "wrpos")
  `ASSERT_EQUAL(dut.rwpos,      3, "rwpos")
  `ASSERT_EQUAL(dut.rrpos,      2, "rrpos")
  `ASSERT_EQUAL(dut.wempty,     0, "wempty")
  `ASSERT_EQUAL(dut.rempty,     0, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     1, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")
  `ASSERT_EQUAL(dut.woverflow,  0, "woverflow")
  `ASSERT_EQUAL(dut.rdata ,  'h34, "rdata")

  `DIAG("Pop 0x34")
  rread <= 1;
  @(posedge rclk);
  rread <= 0;
  #1

  `ASSERT_EQUAL(dut.wwpos,      1, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      1, "wrpos")
  `ASSERT_EQUAL(dut.rwpos,      3, "rwpos")
  `ASSERT_EQUAL(dut.rrpos,      0, "rrpos")
  `ASSERT_EQUAL(dut.wempty,     0, "wempty")
  `ASSERT_EQUAL(dut.rempty,     0, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     1, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")
  `ASSERT_EQUAL(dut.woverflow,  0, "woverflow")
  `ASSERT_EQUAL(dut.rdata ,  'h56, "rdata")

  `DIAG("Pop 0x56")
  rread <= 1;
  @(posedge rclk);
  rread <= 0;
  #1

  `ASSERT_EQUAL(dut.wwpos,      1, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      1, "wrpos")
  `ASSERT_EQUAL(dut.rwpos,      0, "rwpos")
  `ASSERT_EQUAL(dut.rrpos,      1, "rrpos")
  `ASSERT_EQUAL(dut.wempty,     0, "wempty")
  `ASSERT_EQUAL(dut.rempty,     1, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     0, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")
  `ASSERT_EQUAL(dut.woverflow,  0, "woverflow")
  `ASSERT_EQUAL(dut.rdata ,  'hcd, "rdata")

  @(posedge wclk);
  @(posedge wclk);

  `ASSERT_EQUAL(dut.wwpos,      1, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      1, "wrpos")
  `ASSERT_EQUAL(dut.rwpos,      1, "rwpos")
  `ASSERT_EQUAL(dut.rrpos,      1, "rrpos")
  `ASSERT_EQUAL(dut.wempty,     1, "wempty")
  `ASSERT_EQUAL(dut.rempty,     1, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     0, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")
  `ASSERT_EQUAL(dut.woverflow,  0, "woverflow")
  `ASSERT_EQUAL(dut.rdata ,  'hcd, "rdata")

  reset <= 1;
  @(posedge wclk);
  @(posedge rclk);
  @(posedge wclk);
  @(posedge wclk);

  `ASSERT_EQUAL(dut.wwpos,      0, "wwpos")
  `ASSERT_EQUAL(dut.wrpos,      0, "wrpos")
  `ASSERT_EQUAL(dut.rwpos,      0, "rwpos")
  `ASSERT_EQUAL(dut.rrpos,      0, "rrpos")
  `ASSERT_EQUAL(dut.wempty,     1, "wempty")
  `ASSERT_EQUAL(dut.rempty,     1, "rempty")
  `ASSERT_EQUAL(dut.wfull ,     0, "wfull")
  `ASSERT_EQUAL(dut.rfull ,     0, "rfull")
  `ASSERT_EQUAL(dut.woverflow,  0, "woverflow")

  @(posedge wclk);
  @(posedge rclk);
  
  `TEST_DONE
end

endmodule
