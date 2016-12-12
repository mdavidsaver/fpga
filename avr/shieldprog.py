#!/usr/bin/env python

from __future__ import print_function

import sys, struct, time
from random import randint
import serial

def getargs():
    from argparse import ArgumentParser
    P = ArgumentParser()
    P.add_argument('-D','--device', metavar='TTY',
                   help='TTY to which programmer (Arduino/AVR) is connected')

    SP = P.add_subparsers()

    S = SP.add_parser('status')
    S.set_defaults(cmd=status)

    S = SP.add_parser('loadbin')
    S.set_defaults(cmd=loadbin)
    S.add_argument('binfile', metavar='FILE', help='ice40 .bin file')

    S = SP.add_parser('echo')
    S.set_defaults(cmd=bitecho)
    S.add_argument('-N','--number', type=int, default=4)

    S = SP.add_parser('bittest')
    S.set_defaults(cmd=bittest)
    S.add_argument('-N','--number', type=int, default=4)

    S = SP.add_parser('write')
    S.set_defaults(cmd=memwrite)
    S.add_argument('addr', type=int)
    S.add_argument('bytes')

    S = SP.add_parser('read')
    S.set_defaults(cmd=memread)
    S.add_argument('addr', type=int)
    S.add_argument('count', type=int)

    args = P.parse_args()
    if args.device is None:
        # by default find the first Arduino-ish TTY
        from glob import glob
        args.device = glob('/dev/ttyACM*')[0]
    return args

class AVR(serial.Serial):
    def prepare(self, args):
        print ("Open", args.device)
        time.sleep(2.0) # wait for Arduino to reset
        self.flush()
        print("Begin")

        self.echo()
        self.echo()
        self.echo()

        self.cmd(0x17, 1, expect=1) # SS=1
        time.sleep(0.01)

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

def status(args):
    with AVR(port=args.device, baudrate=115200) as ser:
        ser.prepare(args)

        done = ser.cmd(0x15, 0) # cdone set

    if done==0xd0:
        print("Loaded")
    elif done==0xbd:
        print("Not loaded")
        sys.exit(1)
    else:
        print("???", done)
        sys.exit(2)

def loadbin(args):
    with open(args.binfile, 'rb') as F:
        img = F.read()

    if img[:8] != b'\xff\x00\x00\xff\x7e\xaa\x99\x7e':
        print(b"file '%s' is not an ice40 .bin file"%args.binfile)
        sys.exit(1)

    with AVR(port=args.device, baudrate=115200) as ser:
        ser.prepare(args)

        print("Reset and enter program")
        ser.cmd(0x10, 0, expect=0xbd)

        while len(img):
            print("###", len(img))
            B, img = img[:128], img[128:]
            ser.writel(struct.pack('<BB', 0x11, len(B)))
            ser.write(B)
            R, V = struct.unpack('<BB', ser.readl(2))
            if (R, V) != (0x11, len(B)):
                raise RuntimeError("Block error %s %s"%((R, V), (0x11, len(B))))

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

        print("Check CDONE")
        ser.cmd(0x15, 0, expect=0xd0) # cdone set

def bitecho(args):
    inp, out = [], []

    with AVR(port=args.device, baudrate=115200) as ser:
        ser.prepare(args)

        print("Check CDONE")
        ser.cmd(0x15, 0, expect=0xd0) # cdone set

        ser.cmd(0x17, 0, expect=0) # SS=0
        ser.cmd(0x16, 0x11) # echo cmd

        for i in range(args.number):
            next = randint(0,255)
            inp.append(ser.cmd(0x16, next))
            out.append(next)
            if len(out)>1:
                if inp[-1]!=out[-2]:
                    break
        ser.cmd(0x17, 1, expect=1) # SS=1

    inp = inp[1:] # discard reply to echo command
    out = out[:-1]# discard last byte sent (reply never received)

    match = 0
    for i,(E,A) in enumerate(zip(inp, out)):
        if E!=A:
            match = 1
            print("mis-match {0: 3d} E {1:02x} {1:08b}".format(i,E))
            print("              A {0:02x} {0:08b}".format(A))

    if match==0:
        print("match")
    sys.exit(match)

def bittest(args):
    with AVR(port=args.device, baudrate=115200) as ser:
        ser.prepare(args)

        print("Check CDONE")
        ser.cmd(0x15, 0, expect=0xd0) # cdone set

        ser.cmd(0x17, 0, expect=0) # SS=0

        S = randint(0,255)
        R = ser.cmd(0x55, S)

        ser.cmd(0x17, 1, expect=1) # SS=1

    sys.exit(S!=R)

def memwrite(args):
    out = [0x12, args.addr] + map(ord, args.bytes)

    with AVR(port=args.device, baudrate=115200) as ser:
        ser.prepare(args)

        print("Check CDONE")
        ser.cmd(0x15, 0, expect=0xd0) # cdone set

        ser.cmd(0x17, 0, expect=0) # SS=0

        for v in out:
            ser.cmd(0x16, v)

        ser.cmd(0x17, 1, expect=1) # SS=1


def memread(args):
    out = [0x13, args.addr] + [0xff]*(args.count+1)
    rep = [None]*len(out)

    with AVR(port=args.device, baudrate=115200) as ser:
        ser.prepare(args)

        print("Check CDONE")
        ser.cmd(0x15, 0, expect=0xd0) # cdone set

        ser.cmd(0x17, 0, expect=0) # SS=0

        for i,v in enumerate(out):
            rep[i] = ser.cmd(0x16, v)

        ser.cmd(0x17, 1, expect=1) # SS=1

    print(', '.join(map(chr, rep[3:])))

def main(args):
    args.cmd(args)

if __name__=='__main__':
    print("<<< to device")
    print(">>> from device")
    main(getargs())
