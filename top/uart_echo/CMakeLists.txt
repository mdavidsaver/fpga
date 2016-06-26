
add_isim(test_uart_echo
  SRCS
    uart_echo_tb.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_tx.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_rx.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_rx_filter.v
    ${PROJECT_SOURCE_DIR}/util/frac_div.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_uart_echo)

add_synth(uart_echo
  PCF uart_echo_top.pcf
  MAXCLOCK 12.0
  SRCS
    uart_echo_top.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_tx.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_rx.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_rx_filter.v
    ${PROJECT_SOURCE_DIR}/util/frac_div.v
)

add_synth(uart_spam
  PCF uart_echo_top.pcf
  MAXCLOCK 12.0
  SRCS
    uart_spam.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_tx.v
    ${PROJECT_SOURCE_DIR}/util/frac_div.v
)
