`timescale 1us/1ns

// (yet another) logic analyzer for an icestick eval board
//
// UART Tx only.  Send 5 byte messages on any input pin change
// or rollover of timebase counter.
// Uses 16 RAM blocks (all on HX1k) to buffer 2k messages.
//
// Message format is '\nCCCP' where C is a 24-bit counter (MSBF)
// and P is an overflow bit then the 7 input pin values.
//
// UART is 8N1 115200 buad
module icela(
    input clk, // 12 MHz

    // UART
    output sertx_n,

    input [6:0] pin,

    output [4:0] led
);
    reg [4:0] led;

    wire lvl_trig;
    level_trigger #(.N(7)) ltrig(
        .clk(clk),
        .pin(pin),
        .trigger(lvl_trig)
    );

    reg [23:0] timebase = 0;
    // send update when timebase rolls over.
    // allows host to track longer timer scales
    reg roll_trig = 0;

    always @(posedge clk)
        {roll_trig, timebase} <= timebase + 1;

    wire oflow;

    wire [31:0] sm_in;
    wire sm_active;
    wire sm_fetch;

    fifo dbuf(
        .clk(clk),
        .data_in({timebase, oflow, pin}),
        .trig_in(lvl_trig | roll_trig | oflow),
        .data_out(sm_in),
        .data_ready(sm_active),
        .data_read(sm_fetch),
        .oflow(oflow)
    );

    wire [7:0] ser_data;
    wire ser_send;
    wire ser_busy;

    uartsm sm(
        .clk(clk),
        .data_in(sm_in),
        .data_ready(sm_active),
        .data_fetch(sm_fetch),
        .ser_data(ser_data),
        .ser_send(ser_send),
        .ser_busy(ser_busy)
    );

    wire uart_baud; // bit clock
    // 12000000/115200 ~= 2**13/78   (0.825 % error)
    frac_div #(
        .Width(13),
        .Incr(78)
    ) CLK (
        .in(clk),
        .out(uart_baud)
    );

    wire sertx;
    uart_tx uart(
        .clk(clk),
        .baud(uart_baud),
        .data(ser_data),
        .send(ser_send),
        .busy(ser_busy),
        .tx(sertx)
    );
    // icestick UART level inverted
    assign sertx_n = ~sertx;

    always @(posedge clk) begin
        led[0] <= led[0] ^ lvl_trig;
        led[1] <= led[1] ^ roll_trig;
        led[2] <= led[2] ^ oflow;
        led[3] <= led[3] ^ ser_send;
        end

endmodule // icela

// Combine level triggers for N pins into a single output
module level_trigger(
    input clk,
    input [(N-1):0] pin,
    output trigger
);

    parameter N = 7;

    wire [(N-1):0] pin_trig;
    genvar i;
    generate
        for(i=0; i<N; i=i+1) begin
            wire tout;
            reg [2:0] latch;

            // consider current and previous 3 samples
            wire [3:0] phist = {latch, pin[i]};

            always @(posedge clk)
                latch <= phist[2:0]; // shift in current sample

            // debounce input by only allowing certain patterns
            wire rise = phist==4'b0011;
            wire fall = phist==4'b1100;

            assign tout = rise | fall;

            // combine triggers up.  eg pin_trig[1] = tout[1] | pin_trig[0]
            if(i==0) assign pin_trig[i] = tout;
            else     assign pin_trig[i] = tout | pin_trig[i-1];
    end
    endgenerate

    assign trigger = pin_trig[N-1];

endmodule // level_trigger

module fifo(
    input clk,
    input [31:0] data_in,
    input trig_in,
    output [31:0] data_out,
    output data_ready,
    input data_read,
    output oflow
);
    reg [31:0] data_out;
    reg data_ready = 0;

    reg [31:0] ram [0:2048];
    reg [10:0] ram_in = 0;
    reg [10:0] ram_out = 0;

    reg oflow = 0;

    wire empty = ram_in == ram_out;
    wire full = ram_in+1 == ram_out;

    // store if requested, even if in overflow
    always @(posedge clk)
        if(trig_in)
            ram[ram_in] <= data_in;

    always @(posedge clk)
        if(trig_in & ~full)
            ram_in <= ram_in+1;

    always @(posedge clk)
        if(trig_in)
            oflow <= full;

    always @(posedge clk)
        if(data_ready)
            data_out <= ram[ram_out];

    always @(posedge clk)
        data_ready <= ~empty;

    always @(posedge clk)
        if(data_read & ~empty)
            ram_out <= ram_out+1;

endmodule // fifo

// state machine to marshall 4 byte data frames into a byte stream
module uartsm(
    input clk,
    input [31:0] data_in,
    input data_ready,
    output data_fetch,
    output [7:0] ser_data,
    output ser_send,
    input  ser_busy
);
    reg data_fetch;
    reg [7:0] ser_data;
    reg ser_send;

    localparam S_IDLE = 0,
               S_NL = 1,
               S_C0 = 2,
               S_C1 = 3,
               S_C2 = 4,
               S_D  = 5;

    reg [2:0] state = 0;

    reg [31:0] dlatch;

    always @(posedge clk)
        begin
            data_fetch <= 0;

            case(state)
            S_IDLE:begin
                if(data_ready) begin
                    data_fetch <= 1;
                    ser_data <= 8'h0a;
                    ser_send <= 1;
                    state <= S_NL;
                end
            end
            // wait for newline to be sent
            S_NL:begin
                // on first tick
                if(data_fetch)
                    dlatch <= data_in;

                if(ser_send && ser_busy)
                    ser_send <= 0;
                
                else if(~ser_send && ~ser_busy) begin
                    // assert ~data_fetch
                    ser_data <= dlatch[31:24];
                    ser_send <= 1;
                    state <= S_C0;
                end
            end
            // wait for first counter byte to be sent
            S_C0:begin
                if(ser_send && ser_busy)
                    ser_send <= 0;
                
                else if(~ser_send && ~ser_busy) begin
                    ser_data <= dlatch[23:16];
                    ser_send <= 1;
                    state <= S_C1;
                end
            end
            S_C1:begin
                if(ser_send && ser_busy)
                    ser_send <= 0;
                
                else if(~ser_send && ~ser_busy) begin
                    ser_data <= dlatch[15:8];
                    ser_send <= 1;
                    state <= S_C2;
                end
            end
            S_C2:begin
                if(ser_send && ser_busy)
                    ser_send <= 0;
                
                else if(~ser_send && ~ser_busy) begin
                    ser_data <= dlatch[7:0];
                    ser_send <= 1;
                    state <= S_D;
                end
            end
            S_D:begin
                if(ser_send && ser_busy)
                    ser_send <= 0;
                
                else if(~ser_send && ~ser_busy) begin
                    state <= S_IDLE;
                end
            end
            endcase
        end

endmodule // uartsm

module frac_div(
  input  wire in,
  output reg  out
);

parameter Width = 3; // 2**3 = 8
parameter Incr  = 1;

reg [Width-1:0] counter = 0;

always @(posedge in)
  {out, counter} <= counter + Incr[Width:0];

endmodule

module uart_tx(
    input clk,
    input baud,
    input [7:0] data,
    input send,
    output busy,
    output tx
);
    reg busy;
    reg tx;
    reg [7:0] dlatch;

    localparam  S_IDLE = 0,
                S_T0   = 1,
                S_START= 2,
                S_BIT0 = 3,
                S_BIT1 = 4,
                S_BIT2 = 5,
                S_BIT3 = 6,
                S_BIT4 = 7,
                S_BIT5 = 8,
                S_BIT6 = 9,
                S_BIT7 = 10;

    reg [3:0] state = 0;

    always @(posedge clk)
        case(state)
        S_IDLE:begin
            tx   <= 0;
            if(send) begin
                dlatch <= data;
                busy <= 1;
                state <= S_T0;
                // wait for next baud tick (may be end of previous STOP) before starting
            end
        end
        // cf. https://en.wikipedia.org/wiki/RS-232#/media/File:Rs232_oscilloscope_trace.svg
        // wait for tick, then send start bit
        S_T0:   if(baud) begin tx <= 1;         state <= S_START; end
        S_START:if(baud) begin tx <= ~dlatch[0]; state <= S_BIT0;  end
        S_BIT0: if(baud) begin tx <= ~dlatch[1]; state <= S_BIT1;  end
        S_BIT1: if(baud) begin tx <= ~dlatch[2]; state <= S_BIT2;  end
        S_BIT2: if(baud) begin tx <= ~dlatch[3]; state <= S_BIT3;  end
        S_BIT3: if(baud) begin tx <= ~dlatch[4]; state <= S_BIT4;  end
        S_BIT4: if(baud) begin tx <= ~dlatch[5]; state <= S_BIT5;  end
        S_BIT5: if(baud) begin tx <= ~dlatch[6]; state <= S_BIT6;  end
        S_BIT6: if(baud) begin tx <= ~dlatch[7]; state <= S_BIT7;  end
        // stop bit
        S_BIT7: if(baud) begin tx <= 0;         state <= S_IDLE; busy <= 0;  end
        endcase


endmodule // uart_tx
