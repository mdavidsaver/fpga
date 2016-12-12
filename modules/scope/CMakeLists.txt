
add_isim(test_scope_trigger
  SRCS
    scope_trigger_tb.v
    scope_trigger.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_scope_trigger)