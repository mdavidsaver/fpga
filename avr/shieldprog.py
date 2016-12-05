#!/usr/bin/env python

from __future__ import print_function

import sys, struct, time
from random import randint
import serial

def getargs():
    from argparse import ArgumentParser
    P = ArgumentParser()
    P.add_argument('binfile', metavar='FILE', help='ice40 .bin file')
    P.add_argument('-D','--device', metavar='TTY',
                   help='TTY to which programmer (Arduino/AVR) is connected')
    return P.parse_args()

class AVR(serial.Serial):
    def writel(self, msg):
        print("<<<", repr(msg))
        self.write(msg)

    def readl(self, N):
        ret = self.read(N)
        print(">>>", repr(ret))
        return ret

    def cmd(self, code, val, expect=None):
        cmd = struct.pack("<BB", code, val)
        self.writel(cmd)
        rep, rval = struct.unpack("<BB", self.readl(2))
        if rep!=code or (expect is not None and rval!=expect):
            raise RuntimeError("Command fails %s != %s (%s)"%((code,val),(rep,rval),expect))
        return rval

    def echo(self):
        N = randint(0,255)
        self.cmd(0x42, N, expect=N)


def main(args):
    if args.device is None:
        # by default find the first Arduino-ish TTY
        from glob import glob
        args.device = glob('/dev/ttyACM*')[0]

    print("<<< to device")
    print(">>> from device")

    with open(args.binfile, 'rb') as F:
        img = F.read()

    if img[:8] != b'\xff\x00\x00\xff\x7e\xaa\x99\x7e':
        print(b"file '%s' is not an ice40 .bin file"%args.binfile)
        sys.exit(1)

    with AVR(port=args.device, baudrate=115200) as ser:
        #ser.open()
        print ("Open", args.device)
        time.sleep(2.0) # wait for Arduino to reset
        ser.flush()
        print("Begin")

        ser.echo()
        ser.echo()
        ser.echo()

        print("Reset and enter program")
        ser.cmd(0x10, 0, expect=0xbd)

        for i,I in enumerate(img):
            print("### i =",i, len(img))
            #ser.echo()
            ser.cmd(0x11, ord(I), expect=ord(I))


        # must send 49 dummy bits
        # 6 dummy bytes
        for i in range(6):
            ser.cmd(0x11, 0, expect=0)
        # 1 dummy bit
        ser.cmd(0x13, 1)

        ser.cmd(0x14, 0, expect=0x22)

        time.sleep(1.0) # wait for Arduino to reset

        print("Check CDONE")
        ser.cmd(0x15, 0, expect=0xd0) # cdone set


if __name__=='__main__':
    main(getargs())
