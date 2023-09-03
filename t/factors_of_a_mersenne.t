#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use Sidef;

my $code = <<'EOT';

func mtest(b, p) {
    var bits = b.base(2).digits
    for (var sq = 1; bits; sq %= p) {
        sq *= sq;
        sq += sq if bits.shift==1
    }
    sq == 1
}

var results = []

for m in (2..53 -> lazy.grep{.is_prime}) {
    var f = 0
    var x = (2**m - 1)
    var q
    { |k|
        q = (2*k*m + 1)
        q%8 ~~ [1,7] || q.is_prime || next
        q*q > x || (f = mtest(m, q)) && break
    } << 1..Inf
    results << (f ? "#{m}:#{q}" :  "#{m}:p")
}

results.join(' ')

EOT

my $sidef  = Sidef->new(name => 'factors_of_mersenne_numbers');
my $result = $sidef->execute_code($code);

is("$result", '2:p 3:p 5:p 7:p 11:23 13:p 17:p 19:p 23:47 29:233 31:p 37:223 41:13367 43:431 47:2351 53:6361');
