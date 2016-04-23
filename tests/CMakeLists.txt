

add_isim(test_utest
  SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/utest_tb.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/..
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/../utest.vlib
)
add_itest(test_utest)

add_isim(test_uart_tx
  SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/uart_tx_tb.v
    ${CMAKE_CURRENT_SOURCE_DIR}/../modules/uart/uart_tx.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/..
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/../utest.vlib
)
add_itest(test_uart_tx)
