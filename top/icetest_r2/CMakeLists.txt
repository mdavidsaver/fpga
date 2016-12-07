
add_synth(iceblink
  PCF iceblink.pcf
  DEVICE hx1k-vq100
  MAXCLOCK 12.0
  SRCS
    iceblink.v
)

add_synth(spitest_it2
  PCF spitest_it2.pcf
  DEVICE hx1k-vq100
  MAXCLOCK 12.0
  SRCS
    spitest_it2.v
    ${PROJECT_SOURCE_DIR}/modules/spi/spi_slave.v
)
