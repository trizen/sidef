#!/usr/bin/perl

use 5.014;
use strict;
use warnings;

use ntheory qw(:all);
use Math::Sidef qw(digits digits2num);

foreach my $B(2..1000) {

    my $N = factorial($B);
    my @d = digits($N, $B);
    my $M = digits2num($B, \@d);
    #my $M = fromdigits([reverse @d], $B);

    if ($M != $N) {
        die "Error for N = $N (got $M)";
    }
}
