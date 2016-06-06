
add_synth(ublink
  PCF ublink.pcf
  MAXCLOCK 12.0
  SRCS
    ublink.v
    ../../modules/uart/uart.v
    ../../modules/uart/uart_tx.v
    ../../modules/uart/uart_rx.v
    ../../modules/uart/uart_rx_filter.v
    ../../util/frac_div.v
)
