
add_isim(test_dacx311
  SRCS
    dacx311_tb.v
    dacx311.v
    ${PROJECT_SOURCE_DIR}/modules/spi/spi_master_ctrl.v
    ${PROJECT_SOURCE_DIR}/modules/spi/spi_master_inst.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_dacx311)

add_isim(test_adc082s021
  SRCS
    adc082S021_tb.v
    adc082S021.v
    ${PROJECT_SOURCE_DIR}/modules/spi/spi_master_ctrl.v
    ${PROJECT_SOURCE_DIR}/modules/spi/spi_master_inst.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_adc082s021)
