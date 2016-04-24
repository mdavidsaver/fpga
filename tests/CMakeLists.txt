

add_isim(test_utest
  SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/utest_tb.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/../util/utest.vlib
)
add_itest(test_utest)

add_isim(test_uart_tx
  SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/uart_tx_tb.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/uart/uart_tx.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/../util/utest.vlib
)
add_itest(test_uart_tx)

add_isim(test_uart_rx
  SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/uart_rx_tb.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/uart/uart_rx.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/../util/utest.vlib
)
add_itest(test_uart_rx)

add_isim(test_uart_loop
  SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/uart_loop_tb.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/uart/uart.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/uart/uart_tx.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/uart/uart_rx.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/uart/uart_rx_filter.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../util/frac_div.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/../util/utest.vlib
)
add_itest(test_uart_loop)

add_isim(test_uart_echo
  SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/uart_echo_tb.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/uart/uart.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/uart/uart_tx.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/uart/uart_rx.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/uart/uart_rx_filter.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../util/frac_div.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/../util/utest.vlib
)
add_itest(test_uart_echo)

add_isim(test_frac_div
  SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/frac_div_tb.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../util/frac_div.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/../util/utest.vlib
)
add_itest(test_frac_div)
