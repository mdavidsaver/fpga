module test;

`include "utest.vlib"

`TEST_PRELUDE(24)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(4000)

localparam NBYTES = 1;

wire mclk, mosi;
reg miso = 1'bz;

wire busy;
reg start, cpol = 0, cpha = 0;
wire [(8*NBYTES-1):0] dout;
reg [(8*NBYTES-1):0] din;
reg [(8*NBYTES-1):0] dshift;

spi_master #(.NBYTES(NBYTES)) D(
  .clk2(clk),

  .cpol(cpol),
  .cpha(cpha),

  .mclk(mclk),
  .mosi(mosi),
  .miso(miso),

  .din(din),
  .dout(dout),
  .start(start),
  .busy(busy)
);

integer i;

task spi_shift;
  input [(8*NBYTES-1):0] mval;
  input [(8*NBYTES-1):0] sval;
  begin
    $display("spi_shift mval=%x sval=%x", mval, sval);

    din    <= mval;
    dshift <= sval;
    start  <= 1;

    @(posedge busy); // pretend this is slave select
    start  <= 0;
    din    <= 8'hxx;
    miso   <= dshift[(8*NBYTES-1)];

    for(i=0; i<8*NBYTES; i=i+1) begin
      // phase 0
      if(cpol==0)
        @(posedge mclk);
      else
        @(negedge mclk);
      // phase 1
      if(cpha==0)
        dshift <= {dshift[(8*NBYTES-2):0], mosi};
      else
        miso   <= dshift[(8*NBYTES-1)];
      // phase 2
      if(cpol==0)
        @(negedge mclk);
      else
        @(posedge mclk);
      // phase 3
      if(cpha==0)
        miso   <= dshift[(8*NBYTES-1)];
      else
        dshift <= {dshift[(8*NBYTES-2):0], mosi};
    end

    miso   <= 1'bz;

    `ASSERT_EQUAL(0, busy, "busy")

    `ASSERT_EQUAL(sval, dout, "to master from slave")
    
    #2 `ASSERT_EQUAL(mval, dshift, "from master to slave")
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
