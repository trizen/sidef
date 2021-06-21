#!/usr/bin/perl

use 5.014;
use Math::AnyNum qw(sumdigits digits irand ipow);
use ntheory qw(todigits vecsum);
use Math::Sidef;

foreach my $n (2 .. 1000) {

    my $k = irand(ipow(10, $n));
    my $base = irand(2, $n);

    my $s1 = vecsum(todigits($k, $base));
    my $s2 = sumdigits($k, $base);
    my $s3 = vecsum(digits($k, $base));

    my $s4 = Math::Sidef::sumdigits($k, $base);
    my $s5 = vecsum(map { $$_ } Math::Sidef::digits($k, $base));

    if ($s1 != $s2) {
        die "error: s1 != s2 for ($k, $base) -> $s1 != $s2";
    }

    if ($s2 != $s3) {
        die "error: s2 != s3 for ($k, $base)";
    }

    if ($s3 != $$s4) {
        die "error: s3 != s4 for ($k, $base)";
    }

    if ($$s4 != $s5) {
        die "error: s4 != s5 for ($k, $base)";
    }
}
