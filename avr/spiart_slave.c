/** @file spiart_slave.c
 * 
 * Demo for use with spiart design.
 * A SPI slave which echos to MCU UART.
 */

#include <avr/io.h>
#include <avr/wdt.h>
#include <util/delay.h>

static inline void setupuart(void)
{
#define BAUD_TOL 3
#define BAUD 115200
#include <util/setbaud.h>
    UBRR0H = UBRRH_VALUE;
    UBRR0L = UBRRL_VALUE;
#if USE_2X
    UCSR0A = _BV(U2X0);
#else
    UCSR0A = 0;
#endif
    /* 8 N 1 */
    UCSR0C = _BV(UCSZ00)|_BV(UCSZ01);
    /* Enable Tx/Rx */
    UCSR0B = _BV(TXEN0)|_BV(RXEN0);
#undef BAUD
#undef BAUD_TOL
#ifdef USE_2X
#  undef USE_2X
#endif
}

static
void put_char(uint8_t c)
{
    loop_until_bit_is_set(UCSR0A, UDRE0);
    UDR0 = c;
}

static
char hexchars[] = "0123456789ABCDEF";

int main(void)
{
    wdt_disable();
#ifdef __AVR_ATmega328P__
    MCUSR &= ~_BV(WDRF);
#endif

    setupuart();

    // SPIE=0, SPE=1, DORD=0, MSTR=0, CPOL=0, CPHA=0, SPR1=0, SPR0=0
    // Enable in slave mode
    SPCR = _BV(SPE);

    put_char('H');
    put_char('i');
    put_char('\r');
    put_char('\n');

    while(1) {
        uint8_t sts = SPSR;
        if(sts&_BV(SPIF)) {
            uint8_t val = SPDR;

            put_char(hexchars[val>>4]);
            put_char(hexchars[val&0xf]);
            put_char('\r');
            put_char('\n');
        }
    }
}
