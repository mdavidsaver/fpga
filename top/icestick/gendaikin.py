#!/usr/bin/env python3

import sys

Fclk = 12e6

START1 = int(3500e-6*Fclk)
START0 = int(1700e-6*Fclk)

HIGH = int(440e-6*Fclk)
LOW1 = int(1300e-6*Fclk)
LOW0 = HIGH

STOP = int(30e-3*Fclk)

MAX = 0x7fffe

print("START1", hex(START1))
print("START0", hex(START0))
print("HIGH", hex(HIGH))
print("LOW1", hex(LOW1))
print("STOP", hex(STOP))

msgs = [
    b'S1000100001011011111001000000000010100011000010000000000011100111\n',
    b'S1000100001011011111001000000000001000010001111001101000011011001\n',
    b'S10001000010110111110010000000000000000000001001001010100000000000000010100000000000000000110000000000110000000000000000010000011000000000000000011010010\n'
]

# build program from messages

prog = []

for msg in msgs:
    msg = msg[1:-1] # strip 'S' and '\n'

    prog.extend([
        (1, START1),
        (0, START0),
    ])

    for bit in msg:
        prog.append((1, HIGH))
        if bit==ord(b'1'):
            prog.append((0, LOW1))
        elif bit==ord(b'0'):
            prog.append((0, LOW0))
        else:
            raise RuntimeError(bit)

    prog.extend([
        (1, HIGH),
        (0, STOP),
    ])

prog.extend([
    (0, MAX),
    (0, MAX),
])

def squash(pair):
    lvl, delay = pair
    assert delay&0x7ffff==delay, hex(delay)
    return lvl<<19 | delay

prog = list(map(squash, prog))

with open(sys.argv[1], 'w') as F:
    for inst in prog:
        F.write('%05x\n'%inst)

print(len(prog), 'instructions')
