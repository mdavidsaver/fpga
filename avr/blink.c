/* simple AVR test program */

#include <avr/io.h>
#include <avr/wdt.h>
#include <avr/fuse.h>
#include <util/delay.h>


#if defined(__AVR_ATmega128__)
#define UBRRH UBRR0H
#define UBRRL UBRR0L
#define UCSRA UCSR0A
#define UCSRB UCSR0B
#define UCSRC UCSR0C
#elif defined(__AVR_ATmega328P__)
#define UBRRH UBRR0H
#define UBRRL UBRR0L
#define UCSRA UCSR0A
#define UCSRB UCSR0B
#define UCSRC UCSR0C
#else
#error Unsupported device
#endif

static inline void setupuart(void)
{
#define BAUD_TOL 3
#define BAUD 115200
#include <util/setbaud.h>
    UBRRH = UBRRH_VALUE;
    UBRRL = UBRRL_VALUE;
#if USE_2X
    UCSRA = _BV(U2X0);
#else
    UCSRA = 0;
#endif
    /* 8 N 1 */
    UCSRC = _BV(UCSZ00)|_BV(UCSZ01);
    /* Enable Tx/Rx */
    UCSRB = _BV(TXEN0)|_BV(RXEN0);
#undef BAUD
#undef BAUD_TOL
#ifdef USE_2X
#  undef USE_2X
#endif
}

static inline void uart_tx(uint8_t val)
{
    loop_until_bit_is_set(UCSRA, UDRE0);
    UDR0 = val;
}

int main(void)
{
    wdt_disable();
#ifdef __AVR_ATmega328P__
    MCUSR &= ~_BV(WDRF);
#endif

    setupuart();

    DDRB = _BV(DDB5);

    while(1) {
        PORTB ^= _BV(PORTB5);
        _delay_ms(100);
        if(bit_is_set(UCSRA, RXC0))
            uart_tx(UDR0);
        else
            uart_tx('_');
        uart_tx('\r');
        uart_tx('\n');
    }
}
