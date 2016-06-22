module test;

`include "utest.vlib"

`TEST_PRELUDE(24)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(3000)

reg [3:0] sendclk_cnt = 0;
always @(posedge clk)
  sendclk_cnt <= sendclk_cnt[2:0]+1;
wire sendclk = sendclk_cnt[3];

reg select = 0, cpol = 0, cpha = 0;
reg [7:0] din;
wire [7:0] dout;
reg [7:0] dshift;
wire start, done, busy;

reg mclk = 0, mosi = 0;
wire miso;

spi_slave D(
  .clk(clk),

  .cpol(cpol),
  .cpha(cpha),

  .select(select),
  .mclk(mclk),
  .mosi(mosi),
  .miso(miso),

  .din(din),
  .dout(dout),

  .start(start),
  .done(done),
  .busy(busy)
);

integer i;

task spi_shift;
  input [7:0] mval;
  input [7:0] sval;
  begin
    $display("spi_shift mval=%x sval=%x", mval, sval);

    if(mclk!=cpol) begin
      mclk   <= cpol;
      @(posedge sendclk);
    end

    dshift <= mval;
    select <= 1;

    @(posedge start);
    din    <= sval;
    mosi   <= dshift[7];

    @(negedge start);
    din    <= 8'bxx;

    for(i=0; i<8; i=i+1)
    begin
      @(posedge sendclk);
      mclk <= ~cpol;
      if(cpha==0)
        dshift <= {dshift[6:0], miso};
      else
        mosi   <= dshift[7];
      @(posedge sendclk);
      mclk <= cpol;
      if(cpha==0)
        mosi   <= dshift[7];
      else
        dshift <= {dshift[6:0], miso};
    end

    @(posedge done);

    `ASSERT_EQUAL(0, busy, "busy")

    `ASSERT_EQUAL(sval, dshift, "to master from slave")
    `ASSERT_EQUAL(mval, dout, "from master to slave")

    select <= 0;
    @(posedge sendclk);
    @(posedge sendclk);
  end
endtask

initial
begin
  `TEST_INIT(test)

  cpol = 0;
  cpha = 0;
  #6
  $display("config CPOL=%d CPHA=%d", cpol, cpha);
  spi_shift(8'ha1, 8'hb2);
  spi_shift(8'h51, 8'h62);

  cpol = 1;
  cpha = 0;
  #6
  $display("config CPOL=%d CPHA=%d", cpol, cpha);
  spi_shift(8'ha1, 8'hb2);
  spi_shift(8'h51, 8'h62);

  cpol = 0;
  cpha = 1;
  #6
  $display("config CPOL=%d CPHA=%d", cpol, cpha);
  spi_shift(8'ha1, 8'hb2);
  spi_shift(8'h51, 8'h62);

  cpol = 1;
  cpha = 1;
  #6
  $display("config CPOL=%d CPHA=%d", cpol, cpha);
  spi_shift(8'ha1, 8'hb2);
  spi_shift(8'h51, 8'h62);

  #8 `TEST_DONE
end

endmodule
