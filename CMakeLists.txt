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

enable_testing()

add_subdirectory(tests)
