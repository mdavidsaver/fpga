
add_synth(uart_echo
  PCF uart_echo_top.pcf
  MAXCLOCK 25.0
  SRCS
    uart_echo_top.v
    ../../modules/uart/uart.v
    ../../modules/uart/uart_tx.v
    ../../modules/uart/uart_rx.v
    ../../modules/uart/uart_rx_filter.v
    ../../util/frac_div.v
)
