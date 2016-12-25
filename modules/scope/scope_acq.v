module scope_acq(
    input clk,

    input [(NSIG-1):0] sig,

    input              select,
    output       [7:0] din,   // data to be sent to master
    input        [7:0] dout,  // data received from master

    input              drequest
);

// number of input signals
parameter NSIG = 1;

// sample buffer depth is 2**NSAMP
parameter NSAMP = 4;

// time stamp counter size is 2**NTIME
parameter NTIME = 3;

// time stamp, signals, and trigger status
localparam NBITS = NSIG + NTIME + 1;
localparam NBYTES = ((NBITS-1)/8)+1;

reg [7:0] din;

reg use_sim = 0;
reg [(NSIG-1):0] sig_sim;
always @(posedge clk)
    if(reset)
        sig_sim <= 0;
    else
        sig_sim <= sig_sim + 1;


reg [(NTIME-1):0] tstamp;
reg toflow;
always @(posedge clk)
    if(reset)
        {toflow, tstamp} <= 0;
    else
        {toflow, tstamp} <= tstamp + 1;

reg [(3*NSIG)-1:0] trig_conf = 0;
wire [(NSIG-1):0] sig_out;
wire trigger, changed;

scope_trigger #(
    .NSIG(NSIG)
) TRG (
    .clk(clk),
    .sig(use_sim ? sig_sim : sig),
    .conf(trig_conf),
    .triggered(trigger),
    .changed(changed)
);

wire [(NBITS-1):0]  sig_store = {tstamp, trigger, sig_out};
wire [(NBITS-1):0]  buf_out;

reg reset = 0, halt = 0, pop = 0;
reg [(NSAMP-1):0] npost = 0;
wire [3:0] npost_addr = {dout[3:2], 2'b00};

wire triggered, done, buf_ready;

scope_buffer #(
    .N(NBITS),
    .NSAMP(NSAMP)
) BUF (
    .clk(clk),
    .reset(reset),
    .trigger(trigger),
    .halt(halt),
    .triggered(triggered),
    .done(done),
    .npost(npost),
    .din(sig_store),
    .din_latch(changed | toflow),
    .dout(buf_out),
    .dout_ready(buf_ready),
    .dout_pop(pop)
);

localparam CMD_NONE= 8'h00,
           CMD_ID  = 8'h11,
           CMD_STS = 8'h12,
           CMD_CMD = 8'h2z,
           CMD_POST= 8'h3z,
           CMD_DATA= 8'h4z,
           CMD_TRIG= 8'h5z,
           CMD_CONF= 8'b101zzzzz;

reg [3:0] mode;
localparam S_NONE = 0,
           S_POST = 1,
           S_DATA = 2;

always @(posedge clk)
    begin
        reset <= 0;
        halt  <= 0;
        pop   <= 0;
        if(~select) begin
            mode <= CMD_NONE;
        end else if(drequest)
        begin
            mode <= S_NONE;
            din  <= 8'h42;
            case(mode)
            default:begin
                casez(dout)
                CMD_ID:begin
                    din <= 8'ha8 | NBYTES;
                end
                CMD_STS:begin
                    din <= {5'h00, buf_ready, triggered, done}; 
                end
                CMD_CMD:begin
                    halt    <= dout[0];
                    pop     <= dout[1];
                    use_sim <= dout[2];
                    reset   <= dout[3];
                    din  <= 0;
                end
                CMD_POST:begin
                    npost[12:8] <= dout[3:0];
                    mode        <= S_POST;
                end
                CMD_DATA:begin
                    din  <= buf_out[7:0];
                    mode <= S_DATA;
                end
                CMD_CONF:begin
                    $display("# Set Trig %x %x", dout[4:3], dout[2:0]);
                    trig_conf[(3*dout[4:3])+:3] <= dout[2:0];
                end
                endcase
            end
            S_POST:begin
                mode <= CMD_NONE;
                npost[7:0] <= dout;
            end
            S_DATA:begin
                mode <= CMD_NONE;
                din  <= buf_out[15:8];
            end
            endcase
        end
    end

endmodule
