`timescale 1us/1ns
/* Synchronous FIFO
 * Depth is a power of 2 (1<<DEPTH)
 * sync reset must be held high until both wclk and rclk tick once
 * Most flow control signals available on both sides.
 *
 * wpos and rpos are the next memory elements to be written/read respectively.
 */
module sfifo(
  input               reset,
  input               clk,
  // Writer side
  input   [WIDTH-1:0] wdata,  // must be valid while wstore is high
  input               store, // push while high
  // Reader side
  input               read, // pop while high
  output  [WIDTH-1:0] rdata, // valid when ~rempty
  // Status
  output              empty,
  output              full,
  output              overflow
);

//reg [WIDTH-1:0] rdata;

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

reg  [DEPTH-1:0] rpos=0; // read pointer
reg  [DEPTH-1:0] wpos=0; // write pointer
wire [DEPTH-1:0] wpos_next = wpos+1;

assign empty = rpos==wpos;
assign full  = rpos==wpos_next;
assign overflow = store & full;

//always @(posedge clk)
//  if(read)
//    rdata <= buffer[rpos];
assign rdata = buffer[rpos];

always @(posedge clk)
  if(reset)
    rpos <= 0;
  else if(read & ~empty)
    rpos <= rpos+1;

wire dostore;
generate
  if(OFLOW=="REPLACE")
    assign dostore = store;
  else if(OFLOW=="IGNORE")
    assign dostore = store & ~full;
  else
    OFLOW_value_not_valid foo();
endgenerate

always @(posedge clk)
  if(dostore)
    buffer[wpos] <= wdata;

always @(posedge clk)
  if(reset) begin
    wpos         <= 0;
  end else if(store & ~full) begin
    wpos         <= wpos_next;
  end

endmodule
