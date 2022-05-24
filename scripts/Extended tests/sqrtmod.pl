#!/usr/bin/perl

use 5.014;

use ntheory qw(sqrtmod);
use Math::AnyNum qw(irand);

use lib qw(../../lib);
use Math::Sidef;

foreach my $k (2 .. 10000) {

    my $m = irand(2**64);
    my $n = irand($m);

    my $x = sqrtmod($n->numify, $m->numify);
    my $y = Math::Sidef::sqrtmod($n, $m)->numify;

    if (defined($x)) {
        if (lc($y) eq 'nan') {
            say "Sidef error: sqrtmod($n, $m) != $x (got $y)";
        }
    }

    if (defined($y) and !defined($x)) {
        if (lc($y) ne 'nan') {
            say "ntheory error: sqrtmod($n, $m) != $y (got $x)";
        }
    }
}

__END__
Sidef error: sqrtmod(900, 1280) != 30 (got NaN)
Sidef error: sqrtmod(880, 1632) != 484 (got NaN)
Sidef error: sqrtmod(784, 3360) != 28 (got NaN)
Sidef error: sqrtmod(1072, 3872) != 348 (got NaN)
Sidef error: sqrtmod(4624, 5728) != 68 (got NaN)
Sidef error: sqrtmod(4356, 6399) != 66 (got NaN)
Sidef error: sqrtmod(6736, 7776) != 3548 (got NaN)
Sidef error: sqrtmod(4410, 7911) != 111 (got NaN)
Sidef error: sqrtmod(2115, 8181) != 3723 (got NaN)
Sidef error: sqrtmod(2148, 8448) != 522 (got NaN)
Sidef error: sqrtmod(3056, 8864) != 828 (got NaN)
Sidef error: sqrtmod(112, 8992) != 3780 (got NaN)
