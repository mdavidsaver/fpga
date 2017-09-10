/** @file shieldprog.c
 *
 * Program for arduino uno to load bitfile
 * to ice40 sram (ice40 is slave mode).
 * Assumes ice40 is connected to AVR SPI interface
 *
 * Assumes F_CPU is ~16 MHz
 *
 * Host UART should be 115200 8N1, no flow control
 */

#include <avr/io.h>
#include <avr/wdt.h>
#include <util/delay.h>

/* icetest rev. 2 pins
 *
 * PB5 - SCK
 * PB4 - MISO
 * PB3 - MOSI
 * PB2 - SS
 * PB1 - CRST
 * PB0 - CDONE
 * PD6 - app. specific
 * PD5 - app. specific
 *
 * PD3 - A3
 * PD2 - A2
 */

#define PORT_SPI  PORTB
#define PORT_SCLK PORTB5
#define PORT_MISO PORTB4
#define PORT_MOSI PORTB3
#define PORT_SS   PORTB2
#define PORT_CRST PORTB1
#define PORT_CDNE PORTB0

#define DDR_SPI DDRB
#define DD_SCLK DDB5
#define DD_MISO DDB4
#define DD_MOSI DDB3
#define DD_SS   DDB2
#define DD_CRST DDB1
#define DD_CDNE DDB0

#define PIN_SPI  PINB
#define PIN_MISO PINB4
#define PIN_CDNE PINB0

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

static uint8_t uart_rx(uint8_t *ok)
{
    uint8_t err;

    loop_until_bit_is_set(UCSR0A, RXC0);

    err = UCSR0A&(_BV(DOR0)|_BV(FE0));

    if(ok)
        *ok |= !err;

    return UDR0;
}

static inline void setup_spi(void)
{
    /* ICE40 programmed in mode 3
     * SCLK idles high, setup on falling edge, sample on rising edge.
     * MSB
     * Clock /4  SPR0=0 SPR1=0 SPI2x=0
     *       /8  SPR0=1 SPR1=0 SPI2x=1
     *       /16 SPR0=1 SPR1=0 SPI2x=0
     *       /64 SPR0=0 SPR1=1 SPI2x=0
     */
    SPCR = _BV(SPE) | _BV(MSTR) | _BV(CPOL) | _BV(CPHA) | _BV(SPR1);
    //SPSR = _BV(SPI2X);
}

static inline void setup_gpio(void)
{
    /* GPIO mode */
    /* Ensure SCLK remains high during transition */
    PORT_SPI |= _BV(PORT_SCLK);
    /* Disable SPI engine */
    SPCR = 0;
}

static inline uint8_t spi_byte(uint8_t oval)
{
    SPDR = oval;
    loop_until_bit_is_set(SPSR, SPIF);
    return SPDR;
}

static inline uint8_t spi_bit(uint8_t oval)
{
    uint8_t ival;

    /* drive SCLK low and setup MOSI, slave sets up MISO
     */
    PORT_SPI &= ~_BV(PORT_SCLK);
    if(oval)
        PORT_SPI |= _BV(PORT_MOSI);
    else
        PORT_SPI &= ~_BV(PORT_MOSI);

    _delay_us(1);

    /* drive SCLK, slave samples MOSI, we sample MISO */
    PORT_SPI |= _BV(PORT_SCLK);

    ival = !!(PIN_SPI&_BV(PIN_MISO));

    _delay_us(1);

    return ival;
}

static void bad_cmd(uint8_t val)
{
    uart_tx(0xfe);
    uart_tx(val);
    /* disable UART RX for 1 ms, then resume (also clears RX buffer) */
    UCSR0B &= ~_BV(RXEN0);
    _delay_ms(1);
    UCSR0B |= _BV(RXEN0);
}

static void gpio_dummy(uint8_t len)
{
    while(len--) {
        spi_bit(0);
    }
}

int main(void)
{
    wdt_disable();
#ifdef __AVR_ATmega328P__
    MCUSR &= ~_BV(WDRF);
#endif

    setupuart();

    /* switch on drivers for SCK=1, MOSI=0, SS=1, and CRST=1 */
    /* MISO and CDNE remain inputs */
    PORT_SPI = _BV(PORT_SCLK) | _BV(PORT_CRST) | _BV(PORT_SS);
    DDR_SPI = _BV(DD_SCLK) | _BV(DD_MOSI) | _BV(DD_SS) | _BV(DD_CRST);

    DDRD  |= _BV(DDD2);

    /* SPI engine disabled */
    SPCR = 0;

    while(1) {
        uint8_t ok = 1;
        uint8_t cmd = uart_rx(&ok),
                val = uart_rx(&ok);
        if(!ok) {
            bad_cmd(cmd);
            continue;
        }

        switch(cmd) {
        case 0x10: /* reset ice40 and prepare for programming */
            uart_tx(cmd);

            /* SS=0 */
            PORT_SPI &= ~_BV(PORT_SS);
            /* CRST=0 */
            PORT_SPI &= ~_BV(PORT_CRST);

            /* wait at least 200 ns for reset */
            _delay_us(1);

            /* CRST=1 */
            PORT_SPI |= _BV(PORT_CRST);

            /* wait at least 800 ns to enter slave config mode */
            _delay_us(1);

            uart_tx((PIN_SPI&PIN_CDNE)?0xd0:0xbd);
            break;

        case 0x11: /* Byte out, no read */
            uart_tx(cmd);
            setup_spi();
        {
            uint8_t cnt = val;
            while(ok && cnt--) {
                uint8_t b = uart_rx(&ok);
                spi_byte(b);
            }
            uart_tx(ok ? val : ~val);
        }
            break;

        case 0x13: /* Bits out, no data (read or write) */
            uart_tx(cmd);
            setup_gpio();
            gpio_dummy(val);
            uart_tx(val); // echo
            break;

        case 0x14: /* end program mode */
            uart_tx(cmd);
            setup_spi();
            /* SCLK=1, CRST=1, SS=1, MOSI=0 */
            PORT_SPI = _BV(PORT_SCLK) | _BV(PORT_CRST) | _BV(PORT_SS);
            uart_tx(0x22);
            break;

        case 0x15: /* poll CDONE */
            uart_tx(cmd);
            uart_tx((PIN_SPI&_BV(PIN_CDNE))?0xd0:0xbd);
            break;

        case 0x16: /* SPI transfer in/out */
            uart_tx(cmd);
            setup_spi();
            uart_tx(spi_byte(val));
            break;

        case 0x17: /* SPI SS */
            uart_tx(cmd);
            if(val&1)
                PORT_SPI |= _BV(PORT_SS); /* SS=1 */
            else
                PORT_SPI &= ~_BV(PORT_SS); /* SS=0 */
            _delay_us(1);
            uart_tx(val&1u);
            break;

        case 0x42:
            uart_tx(cmd);
            uart_tx(val); // echo
            break;

        case 0x55:
            uart_tx(cmd);
            setup_spi();
            PORTD  &= ~_BV(PORTD2);
            PORT_SPI |= _BV(PORT_SS); /* SS=1 */
            _delay_us(20);
            PORT_SPI &= ~_BV(PORT_SS); /* SS=0 */
            _delay_us(20);

            spi_byte(0x11); // echo command
            spi_byte(val);
        {
            uint8_t rep = spi_byte(0xaa);
            if(rep!=val) {
                PORTD  |= _BV(PORTD2);
            }
            uart_tx(rep);
        }

            PORT_SPI |= _BV(PORT_SS); /* SS=1 */
            break;

        default:
            uart_tx(cmd|0x80);
            uart_tx(val);
            break;
        }
    }
}
