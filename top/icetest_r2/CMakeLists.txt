
add_synth(iceblink
  PCF iceblink.pcf
  DEVICE hx1k-vq100
  MAXCLOCK 12.0
  SRCS
    iceblink.v
)

if(ICE40_SIM)

  add_isim(test_spitest_it2
    SRCS
      spitest_it2_tb.v
      spitest_it2.v
      ${PROJECT_SOURCE_DIR}/modules/spi/spi_slave.v
      ${PROJECT_SOURCE_DIR}/modules/spi/spi_master.v
      ${ICE40_SIM}
    ARGS
      -I${PROJECT_SOURCE_DIR}/util
    DEPENDS
      ${PROJECT_SOURCE_DIR}/util/utest.vlib
  )
  add_itest(test_spitest_it2)

  add_synth(spitest_it2
    PCF spitest_it2.pcf
    DEVICE hx1k-vq100
    MAXCLOCK 12.0
    SRCS
      spitest_it2.v
      ${PROJECT_SOURCE_DIR}/modules/spi/spi_slave.v
  )
endif()
