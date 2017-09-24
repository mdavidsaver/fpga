
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

add_synth(daq_test
  PCF daq_test.pcf
  DEVICE hx1k-vq100
  MAXCLOCK 3.2
  SRCS
      daq_test.v
      ${PROJECT_SOURCE_DIR}/modules/spi/spi_master_ctrl.v
      ${PROJECT_SOURCE_DIR}/modules/spi/spi_master_inst.v
      ${PROJECT_SOURCE_DIR}/drivers/dacx311.v
      ${PROJECT_SOURCE_DIR}/drivers/adc082S021.v
      ${PROJECT_SOURCE_DIR}/modules/spi/spi_slave_async.v
  DEPENDS
      ${CMAKE_CURRENT_BINARY_DIR}/sine8x256.txt
)

add_custom_command(
  COMMENT "Copy sine8x256.txt"
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/sine8x256.txt
  DEPENDS ${PROJECT_SOURCE_DIR}/util/sine8x256.txt
  COMMAND ${CMAKE_COMMAND} -E copy
            ${PROJECT_SOURCE_DIR}/util/sine8x256.txt
            ${CMAKE_CURRENT_BINARY_DIR}/sine8x256.txt
)
