Modbus RTU slave implementation
===============================

Frame decoding

|    1    |     1    | 2-252 | 2   |
| address | function | body  | CRC |

Maximum frame length is 256 bytes,
mimimum is 4.

