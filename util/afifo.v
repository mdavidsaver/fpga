/* Asynchronous FIFO
 * Depth is a power of 2 (1<<DEPTH)
 * sync reset must be held high until both wclk and rclk tick once
 * Most flow control signals available on both sides.
 *
 * wpos and rpos are the next memory elements to be written/read respectively.
 */
module afifo(
  input               reset,
  // Writer side
  input               wclk,
  input   [WIDTH-1:0] wdata,  // must be valid while wstore is high
  input               wstore, // push while high
  output              wempty,
  output              wfull,
  output              woverflow,
  // Reader side
  input               rclk,
  input               rread, // pop while high
  output  [WIDTH-1:0] rdata, // valid when ~rempty
  output              rempty,
  output              rfull,
  output              runderflow
);

reg wreset, rreset;

always @(posedge wclk)
  wreset <= reset;
always @(posedge rclk)
  rreset <= reset;

// "REPLACE" overwrite last value pushed with new value being pushed
// "IGNORE"  ignore new value being pushed
parameter OFLOW = "REPLACE";

// # of data bits
parameter WIDTH=8;

// # of address bits in fifo
parameter DEPTH=4;
// # number of memory elements.  Can actually store NELEM-1
localparam NELEM = 1<<DEPTH;

reg [WIDTH-1:0] buffer [NELEM-1:0];

wire [DEPTH-1:0] rrpos;   // read pointer  in rclk domain
reg  [DEPTH-1:0] rwpos=0; // read pointer  in wclk domain
wire [DEPTH-1:0] wwpos;   // write pointer in wclk domain
reg  [DEPTH-1:0] wrpos=0; // write pointer in rclk domain

wire [DEPTH-1:0] rprev;   // rrpos-1
wire [DEPTH-1:0] wnext;   // wwpos+1

gray #(
  .DEPTH(DEPTH)
) rcnt (
  .clk(rclk),
  .reset(rreset),
  .tick(rread & ~rempty),
  .cnt(rrpos),
  .cnt_prev(rprev)
);

always @(posedge wclk)
  if(wreset)
    rwpos <= 0;
  else
    rwpos <= rrpos;  // read pointer crosses wclk <- rclk

gray #(
  .DEPTH(DEPTH)
) wcnt (
  .clk(wclk),
  .reset(wreset),
  .tick(wstore & ~wfull),
  .cnt(wwpos),
  .cnt_next(wnext)
);

always @(posedge rclk)
  if(rreset)
    wrpos <= 0;
  else
    wrpos <= wwpos;  // write pointer crosses rclk <- wclk

// empty when read and write pointers are equal
assign wempty = rwpos == wwpos;
assign rempty = rrpos == wrpos;

// full when write pointer is just behind read pointer (wpos+1==rpos)
assign wfull  = rwpos == wnext; // rpos   == wpos+1
assign rfull  = wrpos == rprev; // rpos-1 == wpos

assign woverflow  = wfull & wstore;
assign runderflow = rempty & rread;

wire dostore;
generate
  if(OFLOW=="REPLACE")
    assign dostore = wstore;
  else if(OFLOW=="IGNORE")
    assign dostore = wstore & ~wfull;
  else
    OFLOW_value_not_valid foo();
endgenerate

always @(posedge wclk)
  if(dostore)
  begin
    buffer[wwpos] <= wdata;
    $display("# store buffer[%d] = %x", wwpos, wdata);
  end

assign rdata = buffer[rrpos];
//always @(posedge rclk)
//  if(rread)
//    rdata <= buffer[rrpos];

endmodule

// Gray counter w/ previous and next counts as well
// since gray counts can't be simply added or subtracted
module gray(
  input              clk,
  input              reset,
  input              tick,
  output [DEPTH-1:0] cnt,
  output [DEPTH-1:0] cnt_next, // cnt+1
  output [DEPTH-1:0] cnt_prev  // cnt-1
);

parameter DEPTH=4;

reg [DEPTH-1:0] rprev = {DEPTH{1'b1}};
reg [DEPTH-1:0] rcnt  = 0;
reg [DEPTH-1:0] rnext = 1;

always @(posedge clk)
  if(reset)
    rprev <= {DEPTH{1'b1}};
  else if(tick)
    rprev <= rcnt;
  else
    rprev <= rprev;

always @(posedge clk)
  if(reset)
    rcnt <= 0;
  else if(tick)
    rcnt <= rnext;
  else
    rcnt <= rcnt;

always @(posedge clk)
  if(reset)
    rnext <= 1;
  else if(tick)
    rnext <= rnext+1;
  else
    rnext <= rnext;

assign cnt_prev = rprev ^ (rprev>>1);
assign cnt      = rcnt  ^ (rcnt >>1);
assign cnt_next = rnext ^ (rnext>>1);

endmodule
