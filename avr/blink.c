/* simple AVR test program */

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

static inline void uart_tx(uint8_t val)
{
    loop_until_bit_is_set(UCSR0A, UDRE0);
    UDR0 = val;
}

int main(void)
{
    wdt_disable();
    MCUSR &= ~_BV(WDRF);

    setupuart();

    DDRB = _BV(DDB5);

    while(1) {
        PORTB ^= _BV(PORTB5);
        _delay_ms(100);
        if(bit_is_set(UCSR0A, RXC0))
            uart_tx(UDR0);
        else
            uart_tx('_');
        uart_tx('\r');
        uart_tx('\n');
    }
}
