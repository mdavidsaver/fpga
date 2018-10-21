`timescale 1us/1ns
/* SPI slave w/o local clock input
 *
 * setup of rising edge of sclk.
 * samples on falling edge of sclk.
 * active high slave select (ss)
 *
 * User logic should act on rising edge of 'clk'
 * to use 'mdat' to drive 'sdat'.
 spi_slave_async (...);
 always @(posedge clk, posedge reset)
    if(reset) ...
    else if(ready)
        sdat <= ...;
        ... <= mdat;
 */
module spi_slave_async(
    input ss,   // active high
    input sclk,
    input mosi,
    output reg miso,

    output clk, // output clock, use posedge
    output reg ready, // set when mdat is valid, should update sdat
    output [0:7] mdat, // master data
    input [0:7] sdat, // slave data
    output reset // async, active high, reset
);

parameter SS = 1'b0; // SS idle state
parameter CPOL = 1'b0; // SCLK idle state

// real signals (active high)
wire ss_r   = ss ^ SS,
     sclk_r = sclk ^ CPOL;

wire reset = ~ss_r;

wire clk = ~sclk_r;

reg mosi_l;
always @(negedge sclk_r)
  mosi_l <= mosi;

reg [0:2] state;

// assert ready after rising edge of 8th sclk
always @(posedge sclk_r, negedge ss_r)
  if(~ss_r)
    {ready, state} <= 4'h0;
  else
    {ready, state} <= state + 1;

always @(posedge sclk_r)
  if(state==0) // first tick of second byte
    miso <= sdat[0];
  else
    miso <= dshift[1];

// sampled when mosi is stable, posedge clk (aka negedge sclk_r)
wire [0:7] mdat = {dshift[1:7], mosi};

reg [1:7] dshift;

always @(posedge sclk_r)
  if(state==0) // first tick byte
    dshift <= sdat;
  else
    dshift <= {dshift[2:7], mosi_l};


always @(posedge sclk_r)
  $display("# / %d ss_r=%d state=%d ready=%d", $simtime, ss_r, state, ready);
always @(negedge ss_r)
  $display("# X %d ss_r=%d state=%d ready=%d", $simtime, ss_r, state, ready);
always @(negedge sclk_r)
  $display("# \\ %d sdat=%x dshift=%x mosi=%d", $simtime, sdat, dshift, mosi);
endmodule

/*
http://wavedrom.com/editor.html


{signal: [
  {name: 'sclk', wave: '0..10101010101010101010101010101010..'},
  {name: 'ss',   wave: '01..................................0'},
  {name: 'mosi', wave: 'xxx=.=.=.=.=.=.=.=.xxxxxxxxxxxxxxxxxx', data: ['M7', 'M6', 'M5', 'M4', 'M3', 'M2', 'M1', 'M0']},
  {name: 'miso', wave: 'xxxxxxxxxxxxxxxxxxx=.=.=.=.=.=.=.=.xx', data: ['S7', 'S6', 'S5', 'S4', 'S3', 'S2', 'S1', 'S0']},
  {},
  {name: 'state',wave: '=..=.=.=.=.=.=.=.=.=.=.=.=.=.=.=.=...', data:['0','1','2','3','4','5','6','7','0','1','2','3','4','5','6','7','0']},
  {name:'ready', wave: '0................1.0.'},
  {name:'sample',wave: '0.................1.0'},
  {name:'mdat' , wave: 'xxxxxxxxxxxxxxxxxx=.xxxxxxxxxxxxxxxxx'},
  {name:'sdat' , wave: 'xxxxxxxxxxxxxxxxxxx=.xxxxxxxxxxxxxxxx'},
  {name:'dshift[7]', wave: 'xxxxxxxxxxxxxxxxxx=.=.=.=.=.=.=.=.xxx', data: ['S7', 'S6', 'S5', 'S4', 'S3', 'S2', 'S1', 'S0']},
  {name:'dshift[6]', wave: 'xxxxxxxxxxxxxxxx=.=.=.=.=.=.=.=.xxxxx', data: ['M7', 'S6', 'S5', 'S4', 'S3', 'S2', 'S1', 'S0']},
  {name:'dshift[5]', wave: 'xxxxxxxxxxxxxx=.=.=.=.=.=.=.=.xxxxxxx', data: ['M7', 'M6', 'S5', 'S4', 'S3', 'S2', 'S1', 'S0']},
  {name:'dshift[4]', wave: 'xxxxxxxxxxxx=.=.=.=.=.=.=.=.xxxxxxxxx', data: ['M7', 'M6', 'M5', 'S4', 'S3', 'S2', 'S1', 'S0']},
  {name:'dshift[3]', wave: 'xxxxxxxxxx=.=.=.=.=.=.=.=.xxxxxxxxxxx', data: ['M7', 'M6', 'M5', 'M4', 'S3', 'S2', 'S1', 'S0']},
  {name:'dshift[2]', wave: 'xxxxxxxx=.=.=.=.=.=.=.=.xxxxxxxxxxxxx', data: ['M7', 'M6', 'M5', 'M4', 'M3', 'S2', 'S1', 'S0']},
  {name:'dshift[1]', wave: 'xxxxxx=.=.=.=.=.=.=.=.xxxxxxxxxxxxxxx', data: ['M7', 'M6', 'M5', 'M4', 'M3', 'M2', 'S1', 'S0']},
  {name:'dshift[0]', wave: 'xxxx=.=.=.=.=.=.=.=.xxxxxxxxxxxxxxxxx', data: ['M7', 'M6', 'M5', 'M4', 'M3', 'M2', 'M1', 'S0']},
]}
*/
