add_isim(test_spiart_logic
  SRCS
    spiart_logic_tb.v
    spiart_logic.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_spiart_logic)

add_synth(spiart
  PCF spiart.pcf
  MAXCLOCK 12.0
  SRCS
    spiart_top.v
    spiart_logic.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_tx.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_rx.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_rx_filter.v
    ${PROJECT_SOURCE_DIR}/util/frac_div.v
    ${PROJECT_SOURCE_DIR}/modules/spi/spi_master.v
)
