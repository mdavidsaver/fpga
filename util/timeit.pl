#!/usr/bin/env perl
# post processor for icetime report

use strict;
use warnings;
use 5.010;

my ($report, $desired) = @ARGV;

$desired = 1.0*($desired or "25.0");

printf "Desired clock frequency %.3f MHz\n", $desired;

open(my $INP, "<", $report) or die "Failed to open $report";

my $actual;

while(<$INP>) {
  # Total path delay: 13.38 ns (74.72 MHz)
  if (m/Total path delay: (\S+) ns \((\S+) MHz/) {
    $actual = 1.0*$2;
    printf "Actual max. clock frequency %.3f MHz\n", $actual;
  }
}

if(not $actual or $actual<$desired) {
  print "Clock frequency constraint not met\n";
  exit 1;
} else {
  print "Clock frequency constraint met\n";
}
