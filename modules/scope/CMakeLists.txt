
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

add_isim(test_scope_buffer
  SRCS
    scope_buffer_tb.v
    scope_buffer.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_scope_buffer)

add_isim(test_scope_acq
  SRCS
    scope_acq_tb.v
    scope_acq.v
    scope_trigger.v
    scope_buffer.v
  ARGS
    -I${PROJECT_SOURCE_DIR}/util
  DEPENDS
    ${PROJECT_SOURCE_DIR}/util/utest.vlib
)
add_itest(test_scope_acq)
