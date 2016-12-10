/* level and edge detection
 */
module scope_trigger(
  input clk,

  input [(NSIG-1):0] sig,
  output             triggered, // trigger condition meet
  output             changed,   // some input changed

  output [(NSIG-1):0] sigout,

  input [(3*NSIG-1):0] conf
);

parameter NSIG = 1;

localparam M_NONE=0,
           M_LVL=1,
           M_EDGE=2;

wire [(NSIG-1):0] trig;
wire [(NSIG-1):0] diff;
wire [(NSIG-1):0] sigout_w;

genvar i;
generate
    for(i=0; i<NSIG; i=i+1) begin
        reg [1:0] sig_s;
        always @(posedge clk)
            sig_s <= {sig_s[0], sig[i]};

        assign sigout_w[i] = sig_s[0];
        assign diff[i] = sig_s[1]!=sig_s[0];

        wire [1:0] mode = conf[(3*i) +: 2]; // [1:0]
        wire val        = conf[ 3*i  + 2];  // [2]

        wire s_high = sig_s[0]==1;
        wire s_low  = sig_s[0]==0;
        wire s_rise = sig_s==4'b01;
        wire s_fall = sig_s==4'b10;

        assign trig[i] = (mode==M_LVL  & val==1 & s_high)
                       | (mode==M_LVL  & val==0 & s_low)
                       | (mode==M_EDGE & val==1 & s_rise)
                       | (mode==M_EDGE & val==0 & s_fall)
                       ;
    end
endgenerate

reg triggered;
reg changed;
reg [(NSIG-1):0] sigout;

always @(posedge clk)
  begin
    triggered <= (| trig);
    changed   <= (| diff);
    sigout    <= sigout_w;
  end

endmodule
