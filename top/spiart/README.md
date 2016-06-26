UART to SPI bus

Config:

cpol, cpha, select

divider

Commands

Xn - config
 n[0] - cpol
 n[1] - cpha
 n[4:2] - genio

Cn - Set master clock divider (/n)

Dx - data byte

'\n' - echo '\n'



Test spiart w/ icestick and arduino uno

signal, ice pin, arduino pin
MCLK, J2-1, 13
MOSI, J2-2, 11
MISO, J2-3, 12
SS,   J2-4, 10
GND,  
