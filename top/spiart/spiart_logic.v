module spiart_logic(
   input wire        clk,

   // config registers
   output            cpol,
   output            cpha,
   output      [7:0] divparam,

   // general I/O pins
   output      [2:0] genio,

   // uart RX
   input  wire       uart_ready,
   input  wire       uart_rxerr,
   input  wire [7:0] uart_rx,

   // uart TX
   output reg        uart_start,
   input  wire       uart_busy,
   output reg  [7:0] uart_tx,

   // SPI
   input  wire [7:0] spi_rx,
   output reg  [7:0] spi_tx,
   output reg        spi_start,
   input  wire       spi_busy
);

reg        cpol = 0;
reg        cpha = 0;
reg  [7:0] divparam = 255;
reg  [2:0] genio = 0;

localparam S_RESET=0,
           S_IDLE=1,
           S_WAIT_CMD=2,
           S_SPI_START=3,
           S_WAIT_SPI=4,
           S_UART1_START=5,
           S_WAIT_UART1=6,
           S_UART2_START=7,
           S_WAIT_UART2=8,
           S_ERROR=9;

reg [3:0] state=S_RESET;

reg [7:0] cmd;
reg [7:0] reply;

wire cmd_conf_set = cmd==8'h58, // 'X'
     cmd_conf_get = cmd==8'h78, // 'x'
     cmd_div_set  = cmd==8'h43, // 'C'
     cmd_div_get  = cmd==8'h63, // 'c'
     cmd_spi      = cmd==8'h44, // 'D'
     cmd_sync     = cmd==8'h0a; // '\n'

wire cmd_valid = cmd_conf_set | cmd_conf_get
               | cmd_div_set  | cmd_div_get
               | cmd_spi
               | cmd_sync;
     
always @(posedge clk)
  case(state)
    S_RESET:begin
      uart_start <= 0;
      spi_start  <= 0;
      // hold in reset until SPI and UART TX sequence completes
      if(~spi_busy & ~uart_busy)
        state      <= S_IDLE;
    end
    S_ERROR:begin
      uart_tx    <= 8'h3f; // '?'
      cmd        <= 8'h3f; // '?'
      reply      <= 8'h3f; // '?'
      uart_start <= 1;
      state      <= S_UART1_START;
    end
    S_IDLE:if(uart_rxerr) begin
      state <= S_ERROR;
    end else if(uart_ready) begin
      cmd    <= uart_rx;
      state <= S_WAIT_CMD;
    end
    S_WAIT_CMD:if(uart_rxerr) begin
      state <= S_ERROR;
    end else if(uart_ready) begin
      if(cmd_conf_set) begin
          // update settings
          cpol   <= uart_rx[0];
          cpha   <= uart_rx[1];
          genio  <= uart_rx[4:2];
          reply  <= uart_rx; // echo
      end
      if(cmd_conf_get) begin
          // send back current settings
          reply  <= {3'b000, genio, cpha, cpol};
      end
      if(cmd_div_set) begin
          // SPI clock divider
          divparam <= uart_rx;
          reply    <= uart_rx;
      end
      if(cmd_div_get) begin
          // send back SPI clock divider
          reply <= divparam;
      end
      if(cmd_spi) begin
          // start SPI
          spi_tx    <= uart_rx;
          spi_start <= 1;
          state     <= S_SPI_START;
      end
      if(cmd_sync) begin
          reply <= cmd;
      end
      if(cmd_spi) begin
          // spi reply when operation complete
      end else if(cmd_valid) begin
          // others reply immediately
          uart_start <= 1;
          uart_tx    <= cmd;
          state  <= S_UART1_START;
      end else begin
          state  <= S_ERROR;
      end
    end // S_WAIT_CMD
    S_SPI_START:if(spi_busy) begin
      spi_start <= 0;
      state     <= S_WAIT_SPI;
    end
    S_WAIT_SPI:if(~spi_busy) begin
      reply <= spi_rx;
      uart_start <= 1;
      uart_tx    <= cmd;
      state  <= S_UART1_START;
    end
    S_UART1_START:if(uart_busy) begin
      uart_start <= 0;
      state      <= S_WAIT_UART1;
    end
    S_WAIT_UART1:if(~uart_busy) begin
      uart_tx    <= reply;
      uart_start <= 1;
      state      <= S_UART2_START;
    end
    S_UART2_START:if(uart_busy) begin
      uart_start <= 0;
      state      <= S_WAIT_UART2;
    end
    S_WAIT_UART2:if(~uart_busy) begin
      state      <= S_IDLE;
    end
  endcase

endmodule
