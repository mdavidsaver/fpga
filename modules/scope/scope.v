`timescale 1us/1ns
module scope(
  input clk,

  input [(NSIG-1):0] sig,

  input  [7:0] din,
  output [7:0] dout,
  input        dlatch
);

parameter NSIG = 1;

wire triggered;

wire [(NSIG-1):0] sigout,

reg [(3*NSIG-1):0] conf;

scope_trigger #(
  .NSIG(NSIG)
) trig (
  .clk(clk),
  .sig(sig),
  .sigout(sigout),
  .conf(conf),
  .triggered(triggered)
);

localparam M_IDLE = 0,
           M_ARM  = 1,
           M_RUN  = 2;

endmodule
