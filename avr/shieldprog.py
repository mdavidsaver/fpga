#!/usr/bin/env python

from __future__ import print_function

import sys, struct, time
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
        print(">>>", repr(msg))
        self.write(msg)
    def readl(self, N):
        ret = self.read(N)
        print("<<<", repr(ret))
        return ret

    def echo_check(self, data):
        cmd = struct.pack("<BB", 0x42, len(data)-1)+data
        self.writel(cmd)
        rep = self.readl(len(data)+1)
        if rep!=data+'\xce':
            raise RuntimeError("Echo test fail %s != %s"%(repr(data), repr(rep)))

    def wait_ack(self, cdone=None):
        R = self.readl(2)
        if R[0]!=b'\x10':
            raise RuntimeError("Bad ack %s"%repr(R))
        elif cdone is not  None and ord(R[1])!=cdone:
            raise RuntimeError("CDONE not as expected %x != %x"%(ord(R[1]), cdone))
        return ord(R[1])

def main(args):
    if args.device is None:
        # by default find the first Arduino-ish TTY
        from glob import glob
        args.device = glob('/dev/ttyACM*')[0]

    with open(args.binfile, 'rb') as F:
        img = F.read()

    if img[:8] != b'\xff\x00\x00\xff\x7e\xaa\x99\x7e':
        print(b"file '%s' is not an ice40 .bin file"%args.binfile)
        sys.exit(1)

    with AVR(port=args.device, baudrate=115200) as ser:
        #ser.open()
        time.sleep(0.5) # wait for Arduino to reset
        ser.flush()

        ser.echo_check(b'\xde\xad')

        ser.writel(b'\x10') # reset and enter programming mode
        ser.wait_ack(cdone=0)

        # send bit stream in 1k chunks
        while len(img):
            tosend, img = img[:1024], img[1024:]

            ser.writel(struct.pack('<BH', 0x11, len(tosend)))
            ser.writel(tosend)
            ser.wait_ack()

        # must send 49 dummy bits

        ser.writel(struct.pack('<BB', 0x12, 5)) # 6 dummy bytes
        ser.wait_ack()

        ser.writel(struct.pack('<BB', 0x13, 0)) # 1 dummy bit
        ser.wait_ack(cdone=1)

        # exit programming mode (SPI and control pins tri-state)
        ser.writel('\x14')
        ser.wait_ack(cdone=1)

        ser.echo(check(b'\xbe\xef'))

if __name__=='__main__':
    main(getargs())
