module uart_baud(
  input wire ref_clk,
  output wire samp_clk,
  output wire bit_clk
);

/* let's build a fractional divider such that
 * samp_clk = ref_clk*F
 *   where F=Fsamp/(Fbaud*Mult)
 * bit_clk  = samp_clk/Mult
 *   where Mult=2**D
 *
 * Find Width and Incr such that
 *   Fbaud*Mult ~= (2**N)/i
 */

parameter Width = 3; // 2**3 = 8
parameter Incr  = 1;
parameter D     = 3; // 2**3 = 8

reg [Width:0] counter = 0;

`ifdef SIM
wire [Width:0] Incrx = Incr[Width:0];
`endif

always @(posedge ref_clk)
  counter <= counter[Width-1:0] + Incr[Width:0];

assign samp_clk = counter[Width];

reg [D:0] counter2 = 0;

always @(posedge ref_clk)
  if(samp_clk)
    counter2 <= counter2[D-1:0]+1;

assign bit_clk = counter2[D]; // note that bit_clk is one ref_clk tick behind samp_clk

endmodule
