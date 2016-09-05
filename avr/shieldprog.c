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

#define PORT_SPI PORTB
#define PORT_MOSI PORTB3
#define PORT_MISO PORTB4
#define PORT_SCLK PORTB5
#define PORT_CRST PORTB0
#define PORT_CDNE PORTB1
#define DDR_SPI DDRB
#define DD_MOSI DDB3
#define DD_MISO DDB4
#define DD_SCLK DDB5
#define DD_CRST DDB0
#define DD_CDNE DDB1
#define PIN_SPI PINB
#define PIN_MISO PINB4
#define PIN_CDNE PINB1

#define PORT_GPIO PORTD
#define PORT_SS   PORTD7
#define DDR_GPIO  DDRD
#define DD_SS    DDD7

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
    uint8_t sts, err, dat;
    do {
        sts = UCSR0A;
    } while(!(sts&_BV(RXC0)));

    dat = UDR0;

    err = sts&(_BV(DOR0)|_BV(FE0));

    if(ok)
        *ok |= !err;

    return err ? 0 : dat;
}

static inline void setup_spi(void)
{
    /* ICE40 programmed in mode 3
     * SCLK idles high, setup on falling edge, sample on rising edge.
     * MSB
     * Clock /16
     */
    SPCR =_BV(SPE) | _BV(MSTR) | _BV(CPOL) | _BV(CPHA) | _BV(SPR0);
}

static inline void setup_gpio(void)
{
    /* GPIO mode */
    /* Ensure SCLK remains high during transition */
    PORT_SPI |= _BV(DD_SCLK);
    /* Disable SPI engine */
    SPCR = 0;
}

static inline uint8_t spi_byte(uint8_t oval)
{
    SPDR = oval;
    loop_until_bit_is_set(SPCR, SPIF);
    return SPDR;
}

static inline uint8_t spi_bit(uint8_t oval)
{
    uint8_t ival;
    /* assume SCLK is idle (high).
     * drive SCLK low and setup MOSI, slave sets up MISO
     */
    PORT_SPI = oval ? _BV(PORT_MOSI) : 0;
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

static void spi_out(void)
{
    uint8_t ok = 1;
    uint16_t len = uart_rx(&ok), // LSB
             tmp = uart_rx(&ok); // MSB
    len |= tmp<<8;

    if(ok)
        setup_spi();

    /* number of output bytes is len+1 */
    if(ok)
        spi_byte(uart_rx(&ok));

    while(ok && len--) {
        spi_byte(uart_rx(&ok));
    }

    if(!ok)
        bad_cmd(0x71);
}

static void spi_dummy(void)
{
    uint8_t ok = 1;
    uint16_t len = uart_rx(&ok), // LSB
             tmp = uart_rx(&ok); // MSB
    len |= tmp<<8;

    setup_spi();

    spi_byte(0);
    while(ok && len--) {
        spi_byte(0);
    }

    if(!ok)
        bad_cmd(0x72);
}

static void gpio_dummy(void)
{
    uint8_t ok = 1;
    uint16_t len = uart_rx(&ok);

    setup_gpio();

    spi_bit(0);
    while(ok && len--) {
        spi_bit(0);
    }

    if(!ok)
        bad_cmd(0x73);
}

static void uart_echo(void)
{
    uint8_t ok = 1;
    uint8_t len = uart_rx(&ok);

    uart_tx(uart_rx(&ok));
    while(ok && len--) {
        uart_tx(uart_rx(&ok));
    }
    uart_tx(0xce);
}

int main(void)
{
    wdt_disable();
    MCUSR &= ~_BV(WDRF);

    setupuart();
    /* Initially all output tristate w/o pullup */
    PORT_SPI = 0;
    PORT_GPIO = 0;
    DDR_SPI = 0;
    PORT_GPIO = 0;
    /* SPI engine disabled */
    SPCR = 0;

    while(1) {
        uint8_t ok = 1;
        uint8_t cmd = uart_rx(&ok);
        switch(cmd) {
        case 0x10: /* reset ice40 and prepare for programming */
            /* switch on drivers for SCK=1, MOSI=0, SS=0, and CRST=0 */
            /* MISO and CDNE remain inputs */
            PORT_SPI = _BV(DD_SCLK);
            PORT_GPIO = 0;
            DDR_SPI = _BV(DD_SCLK) | _BV(DD_MOSI) | _BV(DD_CRST);
            DDR_GPIO = _BV(DD_SS);
            /* wait at least 200 ns for reset */
            _delay_us(1);
            /* release reset */
            PORT_SPI |= _BV(PORT_CRST);
            /* wait at least 800 ns to enter slave config mode */
            _delay_us(1);
            break;
        case 0x11: /* Bytes out, no read */
            spi_out();
            break;
        case 0x12: /* Bytes out, no data (read or write) */
            spi_dummy();
            break;
        case 0x13: /* Bytes out, no data (read or write) */
            gpio_dummy();
            break;
        case 0x14: /* end program mode */
            PORT_SPI = 0;
            PORT_GPIO = 0;
            DDR_SPI = 0;
            PORT_GPIO = 0;
            SPCR = 0;
            break;
        case 0x42: /* echo over uart for debug or host sync check */
            uart_echo();
            break;
        case 0x43:
            uart_tx(0x44);
            break;
        default:
            bad_cmd(cmd);
            continue;
        }
        /* indicate command completion, and sample CDONE (should be 0) */
        uart_tx(0x10);
        uart_tx((PIN_SPI&PIN_CDNE)?1:0);
    }
}
