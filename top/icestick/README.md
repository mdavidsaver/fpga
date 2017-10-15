uart_echo_top.v

  Loops back uart RX to TX.  Echos any charators received.

uart_spam.v

  Sends charactors 'a' through 'z' at ~1 char per second.

ublink.v

  Accepts commands to control icestick LEDs.

  Commands:

    'q' - query LED state.  Reply is 0b010 + leds[4:0]

    's' + [0-3] - Turn on LED.  Reply is 'S'

    'c' + [0-3] - Turn off LED.  Reply is 'C'
