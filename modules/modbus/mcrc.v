/* MODBUS CRC (CRC-16)


def mcrc(vals):
    crc = 0xffff
    for v in map(ord,vals):
        print 'apply %02x'%v
        crc ^= v
        for i in range(8):
            lsb = crc&1
            crc >>= 1
            if lsb:
                crc ^= 0xA001
        print ' now  %04x'%crc
    return crc

 */
module mcrc(
   input             clk,
   input             reset,
   input             ready,
   input      [DWIDTH-1:0 ] din,
   output     [CWIDTH-1:0] crc
);

parameter DWIDTH = 8;
parameter CWIDTH = 16;
parameter INITIAL = 16'hFFFF;
parameter POLY = 16'hA001;

reg [CWIDTH-1:0] crc = INITIAL;

wire [CWIDTH-1:0] stage[0:DWIDTH];

assign stage[0] = crc ^ din;

genvar i;
generate
    for(i=0; i<=DWIDTH-1; i=i+1) begin
      //wire [CWIDTH-1:0] ival = stage[i];
      //wire [CWIDTH-1:0] oval = (stage[i]>>1)^(stage[i][0] ? POLY : 0);
      assign stage[i+1] = (stage[i]>>1)^(stage[i][0] ? POLY : 0);
    end
endgenerate

always @(posedge clk)
  if(reset)
    crc <= INITIAL;
  else if(ready)
    crc <= stage[DWIDTH];

endmodule
