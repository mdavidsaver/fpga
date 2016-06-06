module test;

`include "utest.vlib"

`TEST_PRELUDE(6)

`TEST_CLOCK(clk,1);

`TEST_TIMEOUT(200)

wire mclk, mosi;
reg miso;

wire busy;
reg start;
wire [7:0] dout;
reg [7:0] din;
reg [7:0] dshift;

spi_master D(
  .clk4(clk),

  .mclk(mclk),
  .mosi(mosi),
  .miso(miso),

  .din(din),
  .dout(dout),
  .start(start),
  .busy(busy)
);

task spi_shift;
  input [7:0] mval;
  input [7:0] sval;
  begin
    $display("spi_shift mval=%x sval=%x", mval, sval);

    din    <= mval;
    dshift <= sval;
    start  <= 1;

    @(posedge busy);
    start  <= 0;

    @(posedge mclk);
    miso   <= dshift[7];
    @(negedge mclk);
    dshift <= {dshift[6:0], mosi};

    @(posedge mclk);
    miso   <= dshift[7];
    @(negedge mclk);
    dshift <= {dshift[6:0], mosi};

    @(posedge mclk);
    miso   <= dshift[7];
    @(negedge mclk);
    dshift <= {dshift[6:0], mosi};

    @(posedge mclk);
    miso   <= dshift[7];
    @(negedge mclk);
    dshift <= {dshift[6:0], mosi};

    @(posedge mclk);
    miso   <= dshift[7];
    @(negedge mclk);
    dshift <= {dshift[6:0], mosi};

    @(posedge mclk);
    miso   <= dshift[7];
    @(negedge mclk);
    dshift <= {dshift[6:0], mosi};

    @(posedge mclk);
    miso   <= dshift[7];
    @(negedge mclk);
    dshift <= {dshift[6:0], mosi};

    @(posedge mclk);
    miso   <= dshift[7];
    @(negedge mclk);
    dshift <= {dshift[6:0], mosi};

    `ASSERT_EQUAL(0, busy)

    `ASSERT_EQUAL(sval, dout)
    
    #2 `ASSERT_EQUAL(mval, dshift)
  end
endtask

initial
begin
  `TEST_INIT(test)

  #6
  spi_shift(8'ha1, 8'hb2);
  spi_shift(8'h51, 8'h62);

  #8 `TEST_DONE
end

endmodule
