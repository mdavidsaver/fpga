#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use TAP::Parser;

my ($cmd) = @ARGV;

my $out = `$cmd`;
my $result = ${^CHILD_ERROR_NATIVE};

my $parser = TAP::Parser->new({source => $out});

while(my $result = $parser->next) {
    print $result->as_string;
    print "\n";
}

my $nplan = $parser->tests_planned;
my $npass = $parser->passed;
my $nfail = $parser->failed;
my $total = $npass+$nfail;

$result = 1 if $nplan!=$total;
$result = 1 if $nfail>0;

print <<EOF;
Ran    $total/$nplan
Passed $npass/$nplan
Fail   $nfail/$nplan
EOF

exit($result);
