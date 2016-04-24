#!/usr/bin/env python

"""Helper to calculate width and increment for fractional dividers
"""

from __future__ import print_function

import sys, math

log2 = lambda v:int(ceil(log(v,2)))

Fin = float(sys.argv[1])
Fout = float(sys.argv[2])
if len(sys.argv)>3:
    Fout *= float(sys.argv[3])

F = Fin/Fout
print("Input  freq", Fin, "hz")
print("Output freq", Fout, "hz")
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
    print("W=%2d   I=%10d  err=%.3f %%  F=%f"%(N,D,err*100,Fact))
