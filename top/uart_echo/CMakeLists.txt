
add_synth(uart_echo
  PCF uart_echo_top.pcf
  MAXCLOCK 12.0
  SRCS
    uart_echo_top.v
    ../../modules/uart/uart.v
    ../../modules/uart/uart_tx.v
    ../../modules/uart/uart_rx.v
    ../../modules/uart/uart_rx_filter.v
    ../../util/frac_div.v
)

add_synth(uart_spam
  PCF uart_echo_top.pcf
  MAXCLOCK 12.0
  SRCS
    uart_spam.v
    ../../modules/uart/uart_tx.v
    ../../util/frac_div.v
)

