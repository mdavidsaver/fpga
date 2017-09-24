#!/usr/bin/env python

from numpy import arange, sin, pi

def getargs():
    from argparse import ArgumentParser, FileType
    P = ArgumentParser()
    P.add_argument('output', type=FileType('w'), metavar='FILE')
    P.add_argument('-N','--count', type=int, default=256, help='Number of points')
    P.add_argument('-W','--width', type=int, default=8)
    P.add_argument('-C','--center', type=int, default=128)
    P.add_argument('-H','--hex', action='store_const', const='hex', dest='fmt', default='hex')
    P.add_argument('-B','--bin', action='store_const', const='bin', dest='fmt')
    return P.parse_args()

def main(args):
    W = 1<<args.width
    if args.fmt=='bin':
        fmt = '0%db'%args.width
    else:
        fmt = '0%dx'%(args.width/4)

    phase = arange(0, 2*pi, 2*pi/args.count)
    A = sin(phase)*(W-1)/2.0 + args.center
    A = A.astype(long)

    if (A>=W).any():
        raise ValueError('overflow logic error')

    args.output.write('// width: %(width)s bits\n'%args.__dict__)
    args.output.write('// count: %(count)s\n'%args.__dict__)
    args.output.write('// center: %(center)s\n'%args.__dict__)
    args.output.write('\n'.join([format(n, fmt) for n in A]))
    args.output.write('\n')

if __name__=='__main__':
    main(getargs())
