module top(
  input clk,

  // SPI
  input mselect, // active low
  input mclk,
  input mosi,
  output miso,

  output err,
  
  // debug
  output d_mselect,
  output d_mclk,
  output d_mosi,
  output d_miso
);

assign d_mselect = mselect;
assign d_mclk    = mclk;
assign d_mosi    = mosi;
assign d_miso    = miso;

wire [7:0] din; // from master
reg [7:0] dout; // to master
wire done;

spi_slave D(
  .clk(clk),

  .cpol(0),
  .cpha(0),

  .select(~mselect),
  .mclk(mclk),
  .mosi(mosi),
  .miso(miso),

  .din(dout),
  .dout(din),
  
  .done(done)
);

localparam S_IDLE = 0,
           S_ERR  = 1,
           S_ECHO = 2,
           S_WRITE_ADDR = 3,
           S_WRITE_DATA = 4,
           S_READ_ADDR = 5,
           S_READ_DATA = 6;
reg [2:0] state = 0;

wire err = state==S_ERR;
reg [7:0] ram [0:255];
reg [7:0] ramptr;

always @(posedge clk)
  begin
  if(mselect)
  begin
    state  <= S_IDLE;
    dout   <= 8'hab;
    ramptr <= 0;
  end else if(done) case(state)
    S_IDLE:begin
      case(din)
      8'h11:begin // command echo
        state <= S_ECHO;
        dout  <= 8'h22;
      end
      8'h12:begin // command ram write
        state <= S_WRITE_ADDR;
        dout  <= 8'h23;
      end
      8'h13:begin // command ram read
        state <= S_READ_ADDR;
        dout  <= 8'h24;
      end
      default:begin
        state <= S_ERR;
        dout <= 8'hff;
      end
      endcase
    end
    S_ECHO:begin
      dout <= din;
    end
    S_WRITE_ADDR:begin
      ramptr <= din;
      dout   <= 8'hee;
      state  <= S_WRITE_DATA;
    end
    S_WRITE_DATA:begin
      dout   <= ram[ramptr];
      ramptr <= ramptr + 1;
      state  <= S_WRITE_DATA;
    end
    S_READ_ADDR:begin
      ramptr <= din;
      dout   <= 8'hee;
      state  <= S_READ_DATA;
    end
    S_READ_DATA:begin
      ram[ramptr] <= din;
      dout   <= 8'hee;
      ramptr <= ramptr + 1;
      state  <= S_READ_DATA;
    end
    default:begin // S_ERR
      dout <= 8'hff;
    end
  endcase
  end

endmodule
