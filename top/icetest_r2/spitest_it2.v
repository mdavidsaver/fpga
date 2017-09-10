module top(
  input clk,

  // SPI
  input mselect, // active low
  input mclk,
  input mosi,
  output miso, // TODO: Z when mselect==1

  output err,
  
  // debug
  inout [3:0] gpio
);

wire mclk_r, mosi_r, mselect_r, miso_x;
// use registered inputs to stabalize SPI inputs
SB_IO #(.PIN_TYPE(6'b000000)) mclk_pin (
  .PACKAGE_PIN(mclk),
  .CLOCK_ENABLE(1'b1),
  .INPUT_CLK(clk),
  .D_IN_0(mclk_r),
  // unused
  .OUTPUT_CLK(clk),
  .OUTPUT_ENABLE(1'b0),
  .LATCH_INPUT_VALUE(1'b0),
  .D_OUT_0(1'b0),
  .D_OUT_1(1'b0)
);
SB_IO #(.PIN_TYPE(6'b000000)) mosi_pin (
  .PACKAGE_PIN(mosi),
  .CLOCK_ENABLE(1'b1),
  .INPUT_CLK(clk),
  .D_IN_0(mosi_r),
  // unused
  .OUTPUT_CLK(clk),
  .OUTPUT_ENABLE(1'b0),
  .LATCH_INPUT_VALUE(1'b0),
  .D_OUT_0(1'b0),
  .D_OUT_1(1'b0)
);
SB_IO #(.PIN_TYPE(6'b000000)) mselect_pin (
  .PACKAGE_PIN(mselect),
  .CLOCK_ENABLE(1'b1),
  .INPUT_CLK(clk),
  .D_IN_0(mselect_r),
  // unused
  .OUTPUT_CLK(clk),
  .OUTPUT_ENABLE(1'b0),
  .LATCH_INPUT_VALUE(1'b0),
  .D_OUT_0(1'b0),
  .D_OUT_1(1'b0)
);
// non-registered output w/ enable
SB_IO #(.PIN_TYPE(6'b101001)) miso_pin (
  .PACKAGE_PIN(miso),
  .OUTPUT_ENABLE(~mselect_r),
  .D_OUT_0(miso_x),
  // unused
  .OUTPUT_CLK(clk),
  .INPUT_CLK(clk),
  .CLOCK_ENABLE(1'b1),
  .LATCH_INPUT_VALUE(1'b0),
  .D_OUT_1(1'b0)
);

`ifdef SIM
localparam UDF = 8'hxx;
`else
localparam UDF = 8'h21; // '!'
`endif

reg [3:0] gpio_dir = 4'h0;
reg [3:0] gpio_out = 4'h0;
wire [3:0] gpio_in;

genvar i;
generate
    for(i=0; i<=3; i=i+1) begin
    SB_IO #(
        // input registered
        // output registerd, out enable registered
        .PIN_TYPE(6'b110101)
    ) gpio_pin (
        .PACKAGE_PIN(gpio[i]),
        .CLOCK_ENABLE(1'b1),
        // input
        .INPUT_CLK(clk),
        .D_IN_0(gpio_in[i]),
        // output
        .OUTPUT_CLK(clk),
        .OUTPUT_ENABLE(gpio_dir[i]),
        .D_OUT_0(gpio_out[i]),
        // unused
        .LATCH_INPUT_VALUE(1'b0),
        .D_OUT_1(1'b0)
    );
    end
endgenerate

wire [7:0] din; // from master
reg [7:0] dout; // to master
wire latch;

spi_slave D(
  .clk(clk),

  .select(~mselect_r),
  .mclk(mclk_r),
  .mosi(mosi_r),
  .miso(miso_x),

  .din(dout),
  .dout(din),
  
  .request(latch)
);

localparam S_IDLE = 0,
           S_START = 9,
           S_ERR  = 1,
           S_ECHO = 2,
           S_WRITE_ADDR = 3,
           S_WRITE_DATA = 4,
           S_READ_ADDR = 5,
           S_READ_DATA = 6,
           S_GPIO_DIR = 7,
           S_GPIO_DATA = 8;
reg [3:0] state = 0;

wire err = mselect_r;
reg [7:0] ram [0:255];
reg [7:0] ramptr;

always @(posedge clk)
  begin
  if(mselect_r)
  begin
    state  <= S_IDLE;
    dout   <= UDF;
    ramptr <= 0;
  end else if(latch) case(state)
    S_IDLE:begin
      state <= S_START;
      dout   <= UDF;
      end
    S_START:begin
      case(din)
      8'h11:begin // command echo
        $display("# CMD ECHO");
        state <= S_ECHO;
        dout  <= 8'h22;
      end
      8'h12:begin // command ram write
        $display("# CMD WRITE");
        state <= S_WRITE_ADDR;
        dout  <= 8'h23;
      end
      8'h13:begin // command ram read
        $display("# CMD READ");
        state <= S_READ_ADDR;
        dout  <= 8'h24;
      end
      8'h14:begin // GPIO direction
        $display("# CMD DIR");
        state <= S_GPIO_DIR;
        dout  <= 8'h25;
      end
      8'h15:begin // GPIO data
        $display("# CMD DATA");
        state <= S_GPIO_DATA;
        dout  <= 8'h26;
      end
      default:begin
        $display("# CMD ???");
        state <= S_ERR;
        dout <= UDF;
      end
      endcase
    end
    S_ECHO:begin
      dout <= din;
    end
    S_WRITE_ADDR:begin
      $display("# Set WADDR %x", din);
      ramptr <= din;
      dout   <= UDF;
      state  <= S_WRITE_DATA;
    end
    S_WRITE_DATA:begin
      $display("# WRITE ram[%x] = %x", ramptr, din);
      ram[ramptr] <= din;
      ramptr <= ramptr + 1;
      dout   <= UDF;
      state  <= S_WRITE_DATA;
    end
    S_READ_ADDR:begin
      $display("# Set RADDR %x", din);
      ramptr <= din;
      // setup of dout<=ram[din] adds some complexity, so make master read once more
      // to get first byte
      dout   <= UDF;
      state  <= S_READ_DATA;
    end
    S_READ_DATA:begin
      $display("# READ ram[%x] -> %x", ramptr, ram[ramptr]);
      dout   <= ram[ramptr];
      ramptr <= ramptr + 1;
      state  <= S_READ_DATA;
    end
    S_GPIO_DIR:begin
      $display("# GPIO dir <= %x", din[0]);
      gpio_dir <= din[3:0];
      dout     <= UDF;
      state    <= S_GPIO_DIR;
    end
    S_GPIO_DATA:begin
      $display("# GPIO data <= %x => %x", din[0], gpio);
      gpio_out <= din[3:0];
      dout     <= {4'h0, gpio_in};
      state    <= S_GPIO_DATA;
    end
    default:begin // S_ERR
      dout <= 8'hff;
    end
  endcase
  end

endmodule
