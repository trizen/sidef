#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use Sidef;

my $code = <<'EOT';

func A(m, n) {
    m == 0 ? (n + 1)
           : (n == 0 ? (A(m - 1, 1))
                     : (A(m - 1, A(m, n - 1))));
};

A(3, 2)

EOT

my $sidef = Sidef->new(name => 'ackermann');
my $result = $sidef->execute_code($code);

is("$result", "29");
