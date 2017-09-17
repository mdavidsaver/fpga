
add_synth(clock_test
  PCF clock_test.pcf
  DEVICE hx1k-vq100
  MAXCLOCK 12.0
  SRCS
      clock_test.v
)

add_synth(spi_test
  PCF spi_test.pcf
  DEVICE hx1k-vq100
  MAXCLOCK 12.0
  SRCS
      spi_test.v
      ${PROJECT_SOURCE_DIR}/modules/spi/spi_slave_async.v
)

add_isim(test_spi_test
  SRCS
    spi_test_tb.v
    spi_test.v
    ${PROJECT_SOURCE_DIR}/modules/spi/spi_slave_async.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_spi_test)
