

add_isim(test_utest
  SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/utest_tb.v
  ARGS
    -I${CMAKE_CURRENT_SOURCE_DIR}/..
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/../utest.vlib
)
add_itest(test_utest)
