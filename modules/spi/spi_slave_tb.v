module test;

`include "utest.vlib"

`TEST_PRELUDE(12)

`TEST_CLOCK(clk,4);

`TEST_TIMEOUT(6000)


reg select = 0, cpol = 1, cpha = 1;
reg [7:0] din;
wire [7:0] dout;
reg [7:0] dshift;

reg mclk = 1, mosi = 0;
wire miso, request;

spi_slave D(
  .clk(clk),

  .select(select),
  .mclk(mclk),
  .mosi(mosi),
  .miso(miso),

  .din(din),
  .dout(dout),

  .request(request)
);

reg [7:0] req_data [0:2];
reg [7:0] recv_data [0:2];
reg [1:0] requested = 0;
always @(posedge clk)
  if(request) begin
    $display("# SPI data request");
    din         <= req_data[0];
    req_data[0] <= req_data[1];
    req_data[1] <= req_data[2];
    req_data[2] <= 8'hxx;
    requested <= requested+1;
    recv_data[0] <= dout;
    recv_data[1] <= recv_data[0];
    recv_data[2] <= recv_data[1];
  end else
    din <= 8'hxx;

integer i;
reg [7:0] outdata;

task spi_master;
  input  [7:0] ival;
  begin
    $display("# spi_master <== %x @ %d", ival, $abstime);
    outdata <= 8'hxx;

    for(i=7; i>=0; i=i-1)
    begin
      #16
      mclk <= 0;
      mosi <= ival[i];
      #16
      mclk <= 1;
      outdata[i] = miso;
    end

    $display("# spi_master ==> %x @ %d", outdata, $abstime);
  end
endtask

initial
begin
  `TEST_INIT(test)

  @(posedge clk);
  $display("# check that ~select is ignored");
  spi_master(8'hab);
  @(posedge clk);
  @(posedge clk);
  @(posedge clk);
  `ASSERT_EQUAL(outdata, 8'hxx, "junk data")
  `ASSERT_EQUAL(requested, 0, "no request")

  @(posedge clk);
  @(posedge clk);
  $display("# shift a single byte");

  req_data[0] <= 8'h89;
  req_data[1] <= 8'hxx;
  req_data[2] <= 8'hxx;
  select <= 1;
  #16
  spi_master(8'hcd);
  `ASSERT_EQUAL(outdata, 8'h89, "sent data")
  #16
  select <= 0;

  #16
  `ASSERT_EQUAL(requested, 2, "requested")
  `ASSERT_EQUAL(recv_data[0], 8'hcd, "recv data[0]")
  `ASSERT_EQUAL(recv_data[1], 8'hxx, "recv data[1]")

  @(posedge clk);
  @(posedge clk);
  $display("# shift 2 bytes");

  requested   <= 0;
  req_data[0] <= 8'h12;
  req_data[1] <= 8'h34;
  req_data[2] <= 8'hxx;

  select <= 1;
  #16
  spi_master(8'h56);
  `ASSERT_EQUAL(outdata, 8'h12, "sent data")
  spi_master(8'h78);
  `ASSERT_EQUAL(outdata, 8'h34, "sent data")
  #16
  select <= 0;

  #16
  `ASSERT_EQUAL(requested, 3, "requested")
  `ASSERT_EQUAL(recv_data[0], 8'h78, "recv data[0]")
  `ASSERT_EQUAL(recv_data[1], 8'h56, "recv data[1]")
  `ASSERT_EQUAL(recv_data[2], 8'hxx, "recv data[2]")

  #8 `TEST_DONE
end

endmodule
