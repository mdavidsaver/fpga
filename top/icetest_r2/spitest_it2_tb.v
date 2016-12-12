module test;
`include "utest.vlib"

`TEST_PRELUDE(44)

`TEST_CLOCK(clk,1);


reg [1:0] clk4_cnt = 0;
reg clk4;

always @(posedge clk)
  {clk4, clk4_cnt} <= clk4_cnt+1;


`TEST_TIMEOUT(6000)

reg mselect = 1; // active low
wire mclk, mosi, miso;

reg [3:0] gpio_dir = 4'h0;
reg [3:0] gpio_data;
wire [3:0] gpio;
assign gpio[0] = gpio_dir[0] ? gpio_data[0] : 1'bz;
assign gpio[1] = gpio_dir[1] ? gpio_data[1] : 1'bz;
assign gpio[2] = gpio_dir[2] ? gpio_data[2] : 1'bz;
assign gpio[3] = gpio_dir[3] ? gpio_data[3] : 1'bz;

top DUT(
  .clk(clk),
  .mselect(mselect),
  .mclk(mclk),
  .mosi(mosi),
  .miso(miso),
  .gpio(gpio)
);

reg [7:0] din;
reg start = 0;

spi_master DRV(
  .ref_clk(clk),
  .bit_clk2(clk4),

  .cpol(1),
  .cpha(1),

  .mclk(mclk),
  .mosi(mosi),
  .miso(miso),

  .din(din),
  .start(start)
);

task spiout;
  input [7:0] inp;
  begin
    @(posedge clk);
    din <= inp;
    start <= 1;

    while(~DRV.busy) @(posedge clk);
    din <= 8'hxx;
    start <= 0;

    while(DRV.busy) @(posedge clk);
  end
endtask

initial
begin
  `TEST_INIT(test)

  #10 @(posedge clk);
  mselect <= 0;

  $display("# Command echo");
  #6 spiout(8'h11);
  `ASSERT_EQUAL(DUT.state, DUT.S_START, "Accepted echo command")
  `ASSERT_EQUAL(DRV.dout, 8'hxx, "Echo cmd ack")

  $display("# Command byte 0x42");
  #10 spiout(8'h42);
  `ASSERT_EQUAL(DUT.state, DUT.S_ECHO, "Accepted echo 1")
  `ASSERT_EQUAL(DRV.dout, 8'h22, "Echo cmd ack")

  $display("# Command byte 0x43");
  #10 spiout(8'h43);
  `ASSERT_EQUAL(DUT.state, DUT.S_ECHO, "Accepted echo 2")
  `ASSERT_EQUAL(DRV.dout, 8'h42, "Byte 1")

  $display("# Command byte 0x43");
  #10 spiout(8'h44);
  `ASSERT_EQUAL(DUT.state, DUT.S_ECHO, "Accepted echo 2")
  `ASSERT_EQUAL(DRV.dout, 8'h43, "Byte 2")

  mselect <= 1;
  #10 @(posedge clk);
  `ASSERT_EQUAL(DUT.state, DUT.S_IDLE, "IDLE")
  
  mselect <= 0;

  $display("# Command mem write");
  #6 spiout(8'h12);
  `ASSERT_EQUAL(DUT.state, DUT.S_START, "Accepted write command")
  #10 spiout(8'h04);
  `ASSERT_EQUAL(DUT.state, DUT.S_WRITE_ADDR, "in addr state")
  #10 spiout(8'hab);
  `ASSERT_EQUAL(DUT.state, DUT.S_WRITE_DATA, "in data state")
  #10 spiout(8'hcd);
  `ASSERT_EQUAL(DUT.state, DUT.S_WRITE_DATA, "in data state")
  #10 spiout(8'hef);

  mselect <= 1;
  #10 @(posedge clk);
  `ASSERT_EQUAL(DUT.state, DUT.S_IDLE, "IDLE")
  
  `ASSERT_EQUAL(DUT.ram[3], 8'hxx, "ram[3]")
  `ASSERT_EQUAL(DUT.ram[4], 8'hab, "ram[4]")
  `ASSERT_EQUAL(DUT.ram[5], 8'hcd, "ram[5]")
  `ASSERT_EQUAL(DUT.ram[6], 8'hxx, "ram[6]")

  mselect <= 0;

  $display("# Command mem read");
  #6 spiout(8'h13);
  `ASSERT_EQUAL(DUT.state, DUT.S_START, "Accepted read command")
  #10 spiout(8'h03);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_ADDR, "in addr state")
  #10 spiout(8'hxx);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_DATA, "in data state")
  `ASSERT_EQUAL(DRV.dout, 8'hxx, "junk")
  #10 spiout(8'hxx);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_DATA, "in data state")
  `ASSERT_EQUAL(DRV.dout, 8'hxx, "ram[3]")
  #10 spiout(8'hxx);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_DATA, "in data state")
  `ASSERT_EQUAL(DRV.dout, 8'hab, "ram[4]")
  #10 spiout(8'hxx);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_DATA, "in data state")
  `ASSERT_EQUAL(DRV.dout, 8'hcd, "ram[5]")
  #10 spiout(8'hxx);
  `ASSERT_EQUAL(DUT.state, DUT.S_READ_DATA, "in data state")
  `ASSERT_EQUAL(DRV.dout, 8'hxx, "ram[6]")

  mselect <= 1;
  #10 @(posedge clk);
  `ASSERT_EQUAL(DUT.state, DUT.S_IDLE, "IDLE")

  $display("# Test GPIO");

  `ASSERT_EQUAL(gpio, 4'bz, "gpio")  
  gpio_dir <= 4'b0001;
  gpio_data <= 4'h0;
  #6
  `ASSERT_EQUAL(gpio, 4'bzzz0, "gpio")  

  mselect <= 0;
  $display("# Read GPIO");

  #6 spiout(8'h15);
  `ASSERT_EQUAL(DUT.state, DUT.S_START, "Accepted data command")
  #6 spiout(8'h00);
  `ASSERT_EQUAL(DUT.state, DUT.S_GPIO_DATA, "Accepted data command")
  `ASSERT_EQUAL(DRV.dout, 8'h26, "gpio data ack")
  #6 spiout(8'h00);
  `ASSERT_EQUAL(DRV.dout, 8'b0000zzz0, "gpio low")
  gpio_data <= 1;
  #6 spiout(8'h00);
  `ASSERT_EQUAL(DRV.dout, 8'b0000zzz1, "gpio high")

  #10 @(posedge clk);
  mselect <= 1;
  gpio_dir <= 0;
  #6
  `ASSERT_EQUAL(gpio, 4'hz, "gpio")  

  mselect <= 0;
  $display("# Set GPIO out");
  
  #6 spiout(8'h14);
  `ASSERT_EQUAL(DUT.state, DUT.S_START, "Accepted data command")
  #6 spiout(8'h01);
  `ASSERT_EQUAL(DUT.state, DUT.S_GPIO_DIR, "Accepted dir command")
  `ASSERT_EQUAL(DRV.dout, 8'h25, "gpio data ack")

  #10 @(posedge clk);
  mselect <= 1;
  `ASSERT_EQUAL(gpio, 4'bzzz0, "gpio")  

  #10 @(posedge clk);
  mselect <= 0;
  $display("# Write GPIO");
  #6 spiout(8'h15);
  #6 spiout(8'h01);
  #10 @(posedge clk);
  mselect <= 1;

  `ASSERT_EQUAL(gpio, 4'bzzz1, "gpio")  

  #8 `TEST_DONE
end

endmodule
