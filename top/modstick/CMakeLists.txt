
add_synth(modstick
  PCF modstick.pcf
  MAXCLOCK 12.0
  SRCS
    modstick_top.v
    modstick_logic.v
    ${PROJECT_SOURCE_DIR}/modules/modbus/mcrc.v
    ${PROJECT_SOURCE_DIR}/modules/modbus/modbus_endpoint.v
    ${PROJECT_SOURCE_DIR}/modules/modbus/modbus_rtu.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_tx.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_rx.v
    ${PROJECT_SOURCE_DIR}/modules/uart/uart_rx_filter.v
    ${PROJECT_SOURCE_DIR}/util/frac_div.v
)
