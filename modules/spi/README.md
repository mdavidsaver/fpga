SPI bus master and slave

Master supports all 4 modes of clock polarity and phase.
Modes can be changed on the fly, or fixed (set to constant).

Slave supports only Mode 3 (CPOL=1 CPHA=1).

clock 'clk' must be at least 6 times faster than the SPI master's 'mclk'.
Tested SPI slave with clk=12 MHz and mclk=2MHz

implementation details

cpol and cpha are used to map the rising and falling edges of mclk
into 'sample' and 'setup' signals.

In modes 0 and 2 (CPHA=0), the first 'setup' comes after first before 'sample'.
In modes 1 and 3 (CPHA=1), the first 'setup' comes before the first 'sample'.

For this reason, MISO is first setup when 'select' becomes active.

http://wavedrom.com/editor.html

```
{signal: [
  {name: 'clk',    wave: 'p.....|.................................'},
  ['SPI',
    {name: 'sclk', wave: '1.....|0.1.0.1.0.1.0.1.0.1.0.1.0.1.0.1.0'},
    {name: 'mosi', wave: 'x.....|=...=...=...=...=...=...=...=...=', data:['7','6','5','4','3','2','1','0','7']},
    {name: 'miso', wave: 'x....=|....=...=...=...=...=...=...=...=', data:['7','6','5','4','3','2','1','0','7']},
    {name: 'sel',  wave: '10....|.................................'},
  ],
  {},
    {name: 'req',  wave: '0.10..|..............................10.'},
    {name: 'din',  wave: 'x..=x.|...............................=x'},
    {name: 'latch',wave: '0...10|................................1'},
    {name: 'dout', wave: 'x.....|..............................=x.'},
  {},
  { name: 'shift', wave: 'x...=.|=.=.=.=.=.=.=.=.=.=.=.=.=.=.=.x.='},
 ],
 head:{
  text:'SPI slave transfer Mode 3 (CPOL=1, CPHA=1)',
  tick:0,
 },
}

```
