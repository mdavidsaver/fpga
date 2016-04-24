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

function(list_filter output input)
  cmake_parse_arguments(A "NOT" "PATTERN" "")
  unset(result) # needed?
  foreach(entry ${${input}})
    if(entry MATCHES ${A_PATTERN})
      if(NOT A_NOT)
        list(APPEND result ${entry})
      endif()
    elseif(A_NOT)
      list(APPEND result ${entry})
    endif()
  endforeach()
  set(${output} ${resut} PARENT_SCOPE)
endfunction()

function(list_prefix output input prefix)
  unset(result)
  foreach(entry ${${input}})
    list(APPEND result ${prefix}${entry})
  endforeach()
  set(${output} ${result} PARENT_SCOPE)
endfunction()

function(add_isim target)
  # OPTS VALUES LISTS
  cmake_parse_arguments(A "" "" "SRCS;ARGS;DEPENDS" ${ARGN})

  add_custom_command(
    COMMENT "Compile ${target}.vvp"
    OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/${target}.vvp
    DEPENDS ${IVERILOG_EXECUTABLE} ${A_SRCS} ${A_DEPENDS}
    COMMAND ${IVERILOG_EXECUTABLE} -o ${CMAKE_CURRENT_BINARY_DIR}/${target}.vvp -DSIM "-DVCD=\"\\\"${target}.vcd\\\"\"" -g2001 -Wall ${A_ARGS} ${A_SRCS}
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
