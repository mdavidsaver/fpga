cmake_minimum_required(VERSION 2.8.2)

project("fpga-avr" C)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RELWITHDEBINFO) # default to debug build
  message(STATUS "Default to RELWITHDEBINFO build")
endif()

add_definitions(-Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers)

include(CMakeExtraGeneratorDetermineCompilerMacrosAndIncludeDirs)

add_executable(spiart_slave
  spiart_slave.c
)

add_custom_command(
  OUTPUT spiart_slave.hex
  COMMAND ${CMAKE_OBJCOPY} -O ihex spiart_slave.elf spiart_slave.hex
  DEPENDS spiart_slave
)

if(AVRDUDE_EXECUTABLE)
  message(STATUS "Can program")
  add_custom_target(load-spiart_slave
    COMMAND ${AVRDUDE_EXECUTABLE}
      -p ${AVRDUDE_MCU} 
      -c ${AVRDUDE_PROG}
      -b ${AVRDUDE_BAUD}
      -P ${AVRDUDE_PORT}
      -U flash:w:spiart_slave.hex:i
    DEPENDS
      spiart_slave.hex
  )
else()
endif()
