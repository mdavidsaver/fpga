cmake_minimum_required(VERSION 2.8.2)

project("fpga" C CXX)

include(CMakeParseArguments)

find_package(Perl REQUIRED)

find_program(IVERILOG_EXECUTABLE iverilog)
find_program(VVP_EXECUTABLE vvp)

message(STATUS "IVERILOG ${IVERILOG_EXECUTABLE}")
message(STATUS "VVP ${VVP_EXECUTABLE}")

if(NOT IVERILOG_EXECUTABLE OR NOT VVP_EXECUTABLE)
  message(SEND_ERROR "Failed to find iverilog")
endif()

# expand a list of source files for use in COMMAND of a custom command
function(expand_source output)
  unset(result)
  foreach(entry ${ARGN})
    get_source_file_property(isgen ${entry} GENERATED)
    if(IS_ABSOLUTE ${entry})
      list(APPEND result ${entry})
    elseif(isgen)
      list(APPEND result ${CMAKE_CURRENT_BINARY_DIR}/${entry})
    else()
      list(APPEND result ${CMAKE_CURRENT_SOURCE_DIR}/${entry})
    endif()
  endforeach()
  set(${output} ${result} PARENT_SCOPE)
endfunction()

function(add_isim target)
  # OPTS VALUES LISTS
  cmake_parse_arguments(A "" "" "SRCS;ARGS;DEPENDS" ${ARGN})

  expand_source(B_SRCS ${A_SRCS})

  add_custom_command(
    COMMENT "Compile ${target}.vvp"
    OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/${target}.vvp
    DEPENDS ${IVERILOG_EXECUTABLE} ${A_SRCS} ${A_DEPENDS}
    COMMAND ${IVERILOG_EXECUTABLE} -o ${CMAKE_CURRENT_BINARY_DIR}/${target}.vvp -DSIM "-DVCD=\"\\\"${target}.vcd\\\"\"" -g2001 -Wall ${A_ARGS} ${B_SRCS}
  )
  add_custom_target(${target} ALL
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${target}.vvp
    SOURCES ${A_DEPENDS}
  )
endfunction()

function(add_itest target)

  add_test(NAME ${target}
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_SOURCE_DIR}/util/tapit.pl "${VVP_EXECUTABLE} -M. -n -l${target}.tap ${target}.vvp"
  )
endfunction()

find_program(YOSYS_EXECUTABLE yosys
  HINTS YOSYS_PREFIX ENV YOSYS_PREFIX
  PATH_SUFFIXES bin
)

find_program(ARACHNE_EXECUTABLE arachne-pnr
  HINTS ARACHNE_PREFIX ENV ARACHNE_PREFIX
  PATH_SUFFIXES bin
)

find_program(ICEPACK_EXECUTABLE icepack
  HINTS ICESTORM_PREFIX ENV ICESTORM_PREFIX
  PATH_SUFFIXES bin
)

find_program(ICEPROG_EXECUTABLE iceprog
  HINTS ICESTORM_PREFIX ENV ICESTORM_PREFIX
  PATH_SUFFIXES bin
)

find_program(ICETIME_EXECUTABLE icetime
  HINTS ICESTORM_PREFIX ENV ICESTORM_PREFIX
  PATH_SUFFIXES bin
)

message(STATUS "YOSYS ${YOSYS_EXECUTABLE}")
message(STATUS "ARACHNE ${ARACHNE_EXECUTABLE}")
message(STATUS "ICEPACK ${ICEPACK_EXECUTABLE}")
message(STATUS "ICEPROG ${ICEPROG_EXECUTABLE}")
message(STATUS "ICETIME ${ICETIME_EXECUTABLE}")

if(YOSYS_EXECUTABLE AND ARACHNE_EXECUTABLE AND ICEPACK_EXECUTABLE)
  set(CAN_SYNTH 1)
  message(STATUS "Can synth")
  if(ICETIME_EXECUTABLE)
    set(CAN_TIME 1)
  message(STATUS "Can time")
  endif()
endif()

function(add_synth target)
  cmake_parse_arguments(A "" "DEVICE;PCF" "SRCS;ARGS;DEPENDS" ${ARGN})

  if(NOT A_DEVICE)
    set(A_DEVICE hx1k) # default to icestick
  endif()

  if(A_DEVICE MATCHES "(lp|hx)(1k|8k)")
    set(PNR_NAME ${CMAKE_MATCH_2})
    set(TIME_NAME ${A_DEVICE})
  else()
    message(SEND_ERROR "Unknown device ${A_DEVICE}")
    return()
  endif()

  expand_source(B_SRCS ${A_SRCS})
  expand_source(B_PCF ${A_PCF})

  add_custom_command(
    COMMENT "Test Compile ${target}.vvp"
    OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/${target}.vvp
    DEPENDS ${IVERILOG_EXECUTABLE} ${A_SRCS} ${A_DEPENDS}
    COMMAND ${IVERILOG_EXECUTABLE} -o ${CMAKE_CURRENT_BINARY_DIR}/${target}.vvp -DSIM "-DVCD=\"\\\"${target}.vcd\\\"\"" -g2001 -Wall ${A_ARGS} ${B_SRCS}
  )

  add_custom_command(
    COMMENT "synth ${target}.blif"
    OUTPUT ${target}.blif
    DEPENDS ${YOSYS_EXECUTABLE} ${A_SRCS} ${A_DEPENDS}
            ${CMAKE_CURRENT_BINARY_DIR}/${target}.vvp
    COMMAND ${YOSYS_EXECUTABLE} -p "synth_ice40 -blif ${CMAKE_CURRENT_BINARY_DIR}/${target}.blif" ${B_SRCS}
  )

  add_custom_command(
    COMMENT "place and route ${target}.blif.txt"
    OUTPUT ${target}.blif.txt
    DEPENDS ${target}.blif ${A_PCF}
    COMMAND ${ARACHNE_EXECUTABLE}
       -d ${PNR_NAME} -p ${B_PCF}
       -o ${CMAKE_CURRENT_BINARY_DIR}/${target}.blif.txt
       -V ${CMAKE_CURRENT_BINARY_DIR}/${target}.out.v
       ${CMAKE_CURRENT_BINARY_DIR}/${target}.blif
  )

  add_custom_command(
    COMMENT "Create ${target}.bin"
    OUTPUT ${target}.bin
    DEPENDS ${target}.blif.txt
    COMMAND ${ICEPACK_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/${target}.blif.txt ${CMAKE_CURRENT_BINARY_DIR}/${target}.bin
  )

  add_custom_target(${target} ALL
    DEPENDS
      ${target}.bin
  )

  if(CAN_TIME)
    add_custom_command(
      COMMENT "Report timeing ${target}-time.txt"
      OUTPUT ${target}-time.txt
      DEPENDS ${ICETIME_EXECUTABLE} ${target}.blif.txt
      COMMAND ${ICETIME_EXECUTABLE}
        -t -d ${TIME_NAME}
        -r ${CMAKE_CURRENT_BINARY_DIR}/${target}-time.txt
        ${CMAKE_CURRENT_BINARY_DIR}/${target}.blif.txt
    )

    add_custom_target(time-${target} ALL
      DEPENDS
        ${target}-time.txt
    )
  endif()

  add_custom_target(load-${target}
    DEPENDS ${ICEPROG_EXECUTABLE} ${target}
    COMMAND ${ICEPROG_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/${target}.bin
  )
endfunction()

enable_testing()

add_subdirectory(tests)
if(CAN_SYNTH)
  message(STATUS "Do synth")
  add_subdirectory(top/uart_echo)
else()
  message(STATUS "Skip synth")
endif()
