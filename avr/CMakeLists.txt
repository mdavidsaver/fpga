cmake_minimum_required(VERSION 2.8.2)

project("fpga-avr" C)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RELWITHDEBINFO) # default to debug build
  message(STATUS "Default to RELWITHDEBINFO build")
endif()

add_definitions(-Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers)

include(CMakeExtraGeneratorDetermineCompilerMacrosAndIncludeDirs)

add_executable(blink
  blink.c
)

add_executable(spiart_slave
  spiart_slave.c
)

add_executable(shieldprog
  shieldprog.c
)

foreach(prog blink;spiart_slave;shieldprog)

  add_custom_command(
    OUTPUT ${prog}.hex
    COMMAND ${CMAKE_OBJCOPY} -O ihex ${prog}.elf ${prog}.hex
    DEPENDS ${prog}
  )

  if(AVRDUDE_EXECUTABLE)
    message(STATUS "Can program")
    add_custom_target(load-${prog}
      COMMAND ${AVRDUDE_EXECUTABLE}
        -p ${AVRDUDE_MCU}
        -c ${AVRDUDE_PROG}
        -b ${AVRDUDE_BAUD}
        -P ${AVRDUDE_PORT}
        -U flash:w:${prog}.hex:i
      DEPENDS
        ${prog}.hex
    )
  else()
  endif()

endforeach()
