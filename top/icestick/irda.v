`timescale 1us/1ns
/* Use the IRDA receiver to decode the messages sent by a Daikin HVAC unit in my apartment
 *
 * I had a leg up using the analysis of: http://rdlab.cdmt.vn/project-2013/daikin-ir-protocol
 *
 * xmitter is Vishay TFDU4101
 *
 * RX is an active low pulse train.
 * pulses have a fixed 2.2us width.
 * min. time between pulses is 27.2us
 *
 * TX must remain high <= 50us
 *
 * Daikin HVAC
 * pulse distance encoding?
 * start - active 3500us, inactive 1700us
 * 1 - active 440us, inactive 1300us
 * 0 - active 440us, inactive 440us
 *  seems inverted from what is shown on rdlab.cdmt.vn page?
 */
`timescale 1us/1ns
module top(
    input clk, // 12 MHz

    // UART
    output sertx,
    //input  serrx,  // disable RX

    // IRDA
    input rx,
    output tx,
    output sd,

    output reg [4:0] led,

    // debug
    output raw, // copy of rx
    output proc, // filtered rx
    output tx2
);

assign sd = 0;

assign raw = rx;
assign tx2 = tx;

vbounce bounce(
  .clk(clk),
  .in(~rx), // rx is active low, flip this to active high for sanity
  .out(proc)
);

wire prog;

vpwm outpwm(
  .clk(clk),
  .in(prog),
  .out(tx)
);

pulseprog pprog(
  .clk(clk),
  .out(prog)
);

wire valid;
wire [1:0] code;

pulsedist decode(
  .clk(clk),
  .in(proc),
  .out(code),
  .valid(valid)
);

wire sertxi;
wire sertx = ~sertxi;
wire serrxi = 1'b0; // ~serrx;

reg send = 0;
reg [7:0] sdat;
wire txbusy;

// 12000000/(115200*8) ~= 2**10/78   (0.825 % error)
uart #(
  .Oversample(3), // 2**3 == 8
  .Width(10),
  .Incr(78)
)D(
  .reset(1'b0),
  .clk(clk),

  .rin(serrxi),
  .rout(sertxi),

  .din(sdat),
  .send(send),
  .txbusy(txbusy)
);

reg oflow = 0;

always @(posedge clk)
  if(valid)
    oflow <= txbusy;

always @(posedge clk)
  if(txbusy)
    send <= 0;
  else if(valid | oflow)
    send <= 1;

always @(posedge clk)
  if(oflow) begin
    $display("OFLOW!");
    sdat <= 8'h5f; // '_'
  end else if(valid) begin
    $display("SEND");
    case(code)
    2'b01: sdat <= 8'h53; // 'S'
    2'b00: sdat <= 8'h0a; // '\n'
    2'b10: sdat <= 8'h30; // '0'
    2'b11: sdat <= 8'h31; // '1'
    endcase
  end

always @(posedge clk) begin
  if(valid & code==2'b01)
    led[0] <= 1;
  else if(valid & code==2'b00)
    led[0] <= 0;
  if(valid)
    led[1] <= ~led[1];
  led[2] <= 0;
  led[3] <= 0;
  led[4] <= 0;
end

endmodule

// account for Vishay TFDU4101 xmitter intended for IRDA data links.
// We will abuse this for simpler/slower remote control protocol.
// A CW signal appears as 2.2us (26 ticks) pulses with 27.2us (326 ticks) seperation.
// a longer seperation implies !CW
//
// This is a counting filter to de-bounce the likely noisy pulse train
module vbounce(
    input clk,
    input in, // active high
    output out
);

// round 326 up to 512
wire [8:0] cnt;

sat_counter #(
    .WIDTH(9),
    .MAX(500),
    .INC(20)
) counter(
    .clk(clk),
    .dir(in),
    .cnt(cnt)
);

localparam THRESHOLD = 200;

reg out = 0;

wire [1:0] state = {out, in};

always @(posedge clk)
  case(state)
  2'b00:begin // idle
    out <= 0;
  end
  2'b01:begin // rising
    out <= cnt>=THRESHOLD;
  end
  2'b11:begin // active
    out <= 1;
  end
  2'b10:begin // falling
    out <= cnt!=0;
  end
  endcase

endmodule

module sat_counter (
    input clk,
    input dir,
    output [(WIDTH-1):0] cnt
);

parameter WIDTH = 8;
parameter MAX = 255;
parameter DEC = 1;
parameter INC = 1;

reg [(WIDTH-1):0] cnt = 0;

always @(posedge clk)
    if(dir && cnt >= MAX - INC) // cnt + INC >= MAX
        cnt <= MAX;
    else if(dir)
        cnt <= cnt + INC;
    else if(cnt < DEC)
        cnt <= 0;
    else
        cnt = cnt - DEC;

endmodule

// decode pulse distance modulation
module pulsedist(
    input clk,
    input in,
    output reg valid,
    output reg [1:0] out
);

localparam STOP = 2'b00,
           START= 2'b01,
           ZERO = 2'b10,
           ONE  = 2'b11;

reg prev = 0;

always @(posedge clk)
    prev <= in;

wire [1:0] state = {prev, in};

reg isstart = 0;
reg started = 0;

// Our threshold will be 500us (6000 ticks)
// round up to 8192.
// This counter will saturate
localparam MAX = 16'hffff;
localparam ZERO_THRESHOLD = 16'd2000; // min spacing
localparam ONE_THRESHOLD = 16'd10000;
localparam START_THRESHOLD = 16'd39000;
localparam TIMEOUT = 16'd30000;
reg [15:0] cnt = 0; //MAX; // initially saturated

always @(posedge clk) begin
    out   <= STOP;
    valid <= 0;

    if(cnt!=MAX)
        cnt <= cnt + 1;

    case(state)
    2'b01:begin // rising edge
        if(isstart && cnt>ONE_THRESHOLD && cnt<MAX-1) begin
            out   <= START;
            valid <= 1;
            started <= 1;
            $display("START %f", $simtime);
        end else if(cnt>ONE_THRESHOLD && cnt<MAX-1) begin
            out   <= ONE;
            valid <= started; // mask data before START
            $display("ONE %f %d", $simtime, started);
        end else if(cnt>ZERO_THRESHOLD && cnt<=ONE_THRESHOLD) begin
            out   <= ZERO;
            valid <= started;
            $display("ZERO %f %d", $simtime, started);
        end else begin
            $display("ERROR %f", $simtime);
        end
        cnt <= 0;
    end
    2'b10:begin // falling edge
        isstart <= cnt>=START_THRESHOLD;
        cnt <= 0;
    end
    2'b00:begin // idle
        if(cnt==TIMEOUT && started) begin
            // timeout
            out <= STOP;
            valid <= 1;
            started <= 0;
            $display("STOP %f", $simtime);
        end
    end
    endcase
end

endmodule

// Vishay TFDU4101 can't do true CW output.
// max pulse width is 50us.  recommended is 0 -> 20us
// No max. duty factor is specified, but the de-rating plot uses 20% so start there.
module vpwm(
    input clk,
    input in,
    output out
);

// 20us / 20% -> 100us period
// 100us * 12MHz -> 1200 ticks
// round up to 2048 (11 bits)
reg [10:0] cnt = 0;
localparam MAX = 1200;
localparam THRESHOLD = MAX - 240; // 20us * 12MHz

always @(posedge clk)
    if(cnt==MAX)
        cnt <= 0;
    else
        cnt <= cnt + 1;

assign out = in & (cnt > THRESHOLD);

endmodule

module pulseprog(
    input clk,
    output out
);

reg [19:0] prog [0:573];

initial $readmemh(`ROMFILE, prog);

reg state = 0;
reg [9:0] pos = 0;
reg [18:0] cnt = 0; // period >= 30ms

reg [19:0] inst;

reg out2 = 0;
assign out = out2;

wire done = cnt==inst[18:0];

always @(posedge clk)
    if(state==0) begin
        inst <= prog[pos];
        state <= 1;
        cnt <= 0;
    end else begin
        cnt <= cnt + 1;
        out2 <= inst[19];
        if(done) begin
            if(pos<573)
                pos <= pos + 1;
            else
                pos <= 0;
            state <= 0;
        end
    end

endmodule
