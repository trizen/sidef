#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

use Sidef;

my @codes = (<<'EOT1', <<'EOT2');

func A(m, n) {
    m == 0 ? (n + 1)
           : (n == 0 ? (A(m - 1, 1))
                     : (A(m - 1, A(m, n - 1))));
};

A(3, 2)

EOT1

func A((0), n)          { n + 1 }
func A(m, (0))          { A(m - 1, 1) }
func A(m,  n) is cached { A(m-1, A(m, n-1)) }

A(3, 2)

EOT2

my $i = 0;
foreach my $code (@codes) {
    ++$i;
    my $sidef = Sidef->new(name => "ackermann-$i");
    my $result = $sidef->execute_code($code);
    is("$result", "29", "ack-$i");
}
