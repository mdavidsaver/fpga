
add_synth(clock_test
  PCF clock_test.pcf
  DEVICE hx1k-vq100
  MAXCLOCK 25.0
  SRCS
      clock_test.v
)

add_synth(spi_test
  PCF spi_test.pcf
  DEVICE hx1k-vq100
  MAXCLOCK 25.0
  SRCS
      spi_test.v
      ${PROJECT_SOURCE_DIR}/modules/spi/spi_slave_async.v
      ${PROJECT_SOURCE_DIR}/modules/spi/spi_mux.v
      ${PROJECT_SOURCE_DIR}/modules/spi/spi_rom.v
    ${PROJECT_SOURCE_DIR}/util/frac_div.v
    IVERILOGARGS
        "-DROMFILE=\"\\\"${CMAKE_CURRENT_SOURCE_DIR}/idrom.hex\\\"\""
    YOSYSARGS
        "-DROMFILE=\"${CMAKE_CURRENT_SOURCE_DIR}/idrom.hex\""
)
