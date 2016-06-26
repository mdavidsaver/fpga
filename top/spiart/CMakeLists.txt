add_isim(test_spiart_logic
  SRCS
    spiart_logic_tb.v
    spiart_logic.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/../../util
  DEPENDS
    ../../util/utest.vlib
)
add_itest(test_spiart_logic)

add_synth(spiart
  PCF spiart.pcf
  MAXCLOCK 12.0
  SRCS
    spiart_top.v
    spiart_logic.v
    ../../modules/uart/uart.v
    ../../modules/uart/uart_tx.v
    ../../modules/uart/uart_rx.v
    ../../modules/uart/uart_rx_filter.v
    ../../util/frac_div.v
    ../../modules/spi/spi_master.v
)
