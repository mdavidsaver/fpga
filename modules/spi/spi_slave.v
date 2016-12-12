/* SPI busy slave Mode 3 (CPHA=1 CPOL=1)
 *
 * mclk, mosi, and select should be stabalized w/ an external DFF
 *
 * Protocol
 *  When request==1 then dout is stable and recipient should set din
 *  immediately.
 */
module spi_slave(
  input wire        clk,   // sample clock.  must be at least 2x mclk

  input  wire       select,// chip select (active high)
  input  wire       mclk,
  input  wire       mosi,
  output reg        miso,

  input  wire [7:0] din,   // data to be sent to master
  output reg  [7:0] dout,  // data received from master

  output reg        request
);

`ifdef SIM
localparam UDF = 1'bx;
`else
localparam UDF = 1'b0;
`endif

reg mclk_p;
always @(posedge clk)
  mclk_p <= mclk;
wire [1:0] mclk_x = {mclk_p, mclk};

wire setup = mclk_x==2'b10,
     sample= mclk_x==2'b01;

reg req_p;
always @(posedge clk)
  req_p <= request;

localparam S_IDLE = 0,
           S_SETUP = 9,
           S_BIT7 = 1,
           S_BIT6 = 2,
           S_BIT5 = 3,
           S_BIT4 = 4,
           S_BIT3 = 5,
           S_BIT2 = 6,
           S_BIT1 = 7,
           S_BIT0 = 8;

reg [3:0] state;

always @(posedge clk)
  begin
    request <= 0;
    if(~select)
    begin
      state <= S_IDLE;
`ifdef SIM
      dout <= 8'hxx;
`endif
    end else case(state)
    S_IDLE:if(select) begin
      request <= 1;
      state <= S_SETUP;
      end
    S_SETUP:if(req_p) begin
        // latch into shift register
        dout <= din;
        state <= S_BIT7;
      end
    S_BIT7:
      if(setup) begin
        miso <= dout[7];
      end else if(sample) begin
        dout[7] <= mosi;
        state <= S_BIT6;
      end
    S_BIT6:
      if(setup) begin
        miso <= dout[6];
      end else if(sample) begin
        dout[6] <= mosi;
        state <= S_BIT5;
      end
    S_BIT5:
      if(setup) begin
        miso <= dout[5];
      end else if(sample) begin
        dout[5] <= mosi;
        state <= S_BIT4;
      end
    S_BIT4:
      if(setup) begin
        miso <= dout[4];
      end else if(sample) begin
        dout[4] <= mosi;
        state <= S_BIT3;
      end
    S_BIT3:
      if(setup) begin
        miso <= dout[3];
      end else if(sample) begin
        dout[3] <= mosi;
        state <= S_BIT2;
      end
    S_BIT2:
      if(setup) begin
        miso <= dout[2];
      end else if(sample) begin
        dout[2] <= mosi;
        state <= S_BIT1;
      end
    S_BIT1:
      if(setup) begin
        miso <= dout[1];
      end else if(sample) begin
        dout[1] <= mosi;
        state <= S_BIT0;
      end
    S_BIT0:
      if(setup) begin
        miso <= dout[0];
      end else if(sample) begin
        dout[0] <= mosi;
        request <= 1;
        state <= S_SETUP;
      end
    endcase
  end

endmodule
