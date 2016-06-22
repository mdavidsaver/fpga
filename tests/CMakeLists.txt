

add_isim(test_utest
  SRCS
    utest_tb.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ../util/utest.vlib
)
add_itest(test_utest)

add_isim(test_spi_master
  SRCS
    spi_master_tb.v
    ../modules/spi/spi_master.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ../util/utest.vlib
)
add_itest(test_spi_master)

add_isim(test_spi_slave
  SRCS
    spi_slave_tb.v
    ../modules/spi/spi_slave.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ../util/utest.vlib
)
add_itest(test_spi_slave)

add_isim(test_uart_tx
  SRCS
    uart_tx_tb.v
    ../modules/uart/uart_tx.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ../util/utest.vlib
)
add_itest(test_uart_tx)

add_isim(test_uart_rx
  SRCS
    uart_rx_tb.v
    ../modules/uart/uart_rx.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ../util/utest.vlib
)
add_itest(test_uart_rx)

add_isim(test_uart_echo
  SRCS
    uart_echo_tb.v
    ../modules/uart/uart.v
    ../modules/uart/uart_tx.v
    ../modules/uart/uart_rx.v
    ../modules/uart/uart_rx_filter.v
    ../util/frac_div.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ../util/utest.vlib
)
add_itest(test_uart_echo)

add_isim(test_frac_div
  SRCS
    frac_div_tb.v
    ../util/frac_div.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../util
  DEPENDS
    ../util/utest.vlib
)
add_itest(test_frac_div)
