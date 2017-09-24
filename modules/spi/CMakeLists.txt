
add_isim(test_spi_slave_async
  SRCS
    spi_slave_async_tb.v
    ${PROJECT_SOURCE_DIR}/modules/spi/spi_slave_async.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_spi_slave_async)
