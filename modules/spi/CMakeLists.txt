
add_isim(test_spi_master
  SRCS
    spi_master_tb.v
    ${PROJECT_SOURCE_DIR}/modules/spi/spi_master.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_spi_master)

add_isim(test_spi_slave
  SRCS
    spi_slave_tb.v
    ${PROJECT_SOURCE_DIR}/modules/spi/spi_slave.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_spi_slave)
