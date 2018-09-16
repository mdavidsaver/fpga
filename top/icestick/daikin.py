#!/usr/bin/env python3
"""Use with icestick board loaded with irda.v

actual message.  13:48:00 Power.Off Mode.Cool Fan.Auto temp 70 F

b'S1000100001011011111001000000000010100011000010000000000011100111\n'
b'S1000100001011011111001000000000001000010001111001101000011011001\n'
b'S10001000010110111110010000000000000000000001001001010100000000000000010100000000000000000110000000000110000000000000000010000011000000000000000011010010\n'
"""

import logging
from enum import IntEnum
from datetime import time
from functools import reduce

import serial
from scipy.constants import convert_temperature

_log = logging.getLogger(__name__)

class Power(IntEnum):
    Off = 0
    On = 1

class Mode(IntEnum):
    Auto = 0b000
    Heat = 0b001
    Dry  = 0b010
    Fan  = 0b011
    Cool = 0b100

class Fan(IntEnum):
    Lvl1  = 3
    Lvl2  = 4
    Lvl3  = 5
    Lvl4  = 6
    Lvl5  = 7
    Auto  = 10
    Night = 11

def getargs():
    from argparse import ArgumentParser
    P = ArgumentParser()
    P.add_argument('-D','--device', metavar='TTY',
                   help='TTY to which programmer (Arduino/AVR) is connected')
    P.add_argument('-d','--debug', action='store_const', const=logging.DEBUG, default=logging.INFO)

    args = P.parse_args()
    if args.device is None:
        # by default find the first USB tty (icestick appears as this)
        from glob import glob
        args.device = glob('/dev/ttyUSB*')[0]
    return args

class Settings:
    def __init__(self, A, B, C):
        assert A[:4]==[17, 218, 39, 0], A[:4]
        assert B[:4]==[17, 218, 39, 0], B[:4]
        assert C[:4]==[17, 218, 39, 0], C[:4]

        T = B[6]&7
        T <<= 8
        T |= B[5]
        H, M = divmod(T, 60)
        self.time = time(H, M)

        self.power = Power(C[5]&1)
        self.mode = Mode((C[5]>>4)&7)

        self.temp = int(round(convert_temperature(C[6]/2.0, 'C', 'F'),0))

        self.fan = Fan(C[8]>>4)

    def __repr__(self):
        return "%s %s %s %s temp %d F"%(self.time, self.power, self.mode, self.fan, self.temp)
    __str__ = __repr__

class Daikin(serial.Serial):
    def __iter__(self):
        return self

    def __next__(self):
        A = self._get()
        self.timeout = 1.0
        try:
            B = self._get()
            C = self._get()
        except TimeoutError:
            return None
        finally:
            self.timeout = None
        A, B, C = map(self._proc, (A, B, C))
        return Settings(A, B, C)

    def _get(self):
        line = self.read_until()
        if len(line)==0:
            raise TimeoutError("Incomplete")
        _log.debug("Line: %s", repr(line))
        assert line[:1]==b'S', line[:10]
        assert line[-1:]==b'\n', line[-10:]

        line = line[1:-1]
        assert len(line)%8==0, len(line)

        return line

    @staticmethod
    def _proc(line):
        B = []
        for n in range(len(line)//8):
            bits = list(line[(8*n):(8*(n+1))]) # reversed bit string
            bits.reverse()
            bits = ''.join(map(chr, bits))
            B.append(int(bits, 2))

        chk = sum(B[:-1]) & 0xff
        assert chk==B[-1], (bin(chk), bin(B[-1]))

        return B

def main(args):
    # test checksum calc
    Daikin._proc(b'1000100001011011111001000000000010100011000000000000000011101011')
    Daikin._proc(b'1000100001011011111001000000000010100011000010000000000011100111')

    _log.info("Open %s", args.device)
    with Daikin(port=args.device, baudrate=115200) as ser:
        for cmd in ser:
            if cmd is None:
                print("Bad measurement")
                continue
            print(cmd)
            #print(' '.join([format(C, '08b') for C in cmd]))

if __name__=='__main__':
    args = getargs()
    logging.basicConfig(level=args.debug)
    try:
        main(args)
    except KeyboardInterrupt:
        pass
