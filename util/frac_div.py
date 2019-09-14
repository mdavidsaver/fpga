#!/usr/bin/env python

"""Helper to calculate width and increment for fractional dividers
"""

from __future__ import print_function

import sys, math

log2 = lambda v:int(ceil(log(v,2)))

def getargs():
    from argparse import ArgumentParser
    P = ArgumentParser()
    P.add_argument('Fin', type=float,
                   help='Input clock frequency')
    P.add_argument('Fout', type=float,
                   help='Desired output frequency')
    P.add_argument('M', nargs='?', type=int, default=1,
                   help='Optional multipler on output frequency')
    return P.parse_args()

args = getargs()

Fin = args.Fin
Fout = args.Fout*args.M

F = Fin/Fout
print("Input  freq", Fin, "Hz")
print("Output freq", Fout, "Hz")
print("Fraction   ", F)

print("Input  period", 1/Fin, "s")
print("Output period", 1/Fout, "s")
print()

# Find some N and i such that
#  F ~= (2**N)/i

results = []

for N in range(32):
    D, M = divmod(2**N, F)
    if D<1:
        continue
    Fact = (2**N)/D
    err = abs(F-Fact)/F
    if err>=0.1:
        continue # ignore more than 10% error
    results.append((err, N, D, Fact))

results.sort()

for err, N, D, Fact in results:
    Fout2 = Fin/Fact
    print("W=%2d   I=%10d  err=%.3f %%  F=%.6f  freq=%.1f Hz"%(N,D,err*100,Fact,Fout2))
