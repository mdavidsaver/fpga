
add_isim(test_spi_master
  SRCS
    spi_master_tb.v
    spi_master_ctrl.v
    spi_master_inst.v
    spi_slave_async.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_spi_master)

add_isim(test_spi_slave_async
  SRCS
    spi_slave_async_tb.v
    spi_slave_async.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_spi_slave_async)

add_isim(test_spi_mux
  SRCS
    spi_mux_tb.v
    spi_mux.v
    spi_rom.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_spi_mux)
