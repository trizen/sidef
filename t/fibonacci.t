#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

use Sidef;

my @codes = (<<'EOT1', <<'EOT2', <<'EOT3', <<'EOT4');

func fib((0)) { 0 }
func fib((1)) { 1 }

func fib(n) is cached { fib(n-1) + fib(n-2) }

fib(12)

EOT1

module Fibonacci {
    func nth(n) {
        n > 1 ? nth(n-2)+nth(n-1) : n
    }
}

Fibonacci::nth(12)

EOT2

func fib({.is_neg})  { NaN }
func fib({.is_zero}) { 0 }
func fib({.is_one})  { 1 }
func fib(n)          { fib(n-1) + fib(n-2) }

fib(12)

EOT3

func fib (Number n { _ <= 1} = 0) {
    return n
}

func fib (Number n) is cached {
    fib(n-1) + fib(n-2)
}

fib(12)

EOT4

my $i = 0;
foreach my $code (@codes) {
    ++$i;
    my $sidef = Sidef->new(name => "fibonacci-$i");
    my $result = $sidef->execute_code($code);
    is("$result", "144", "fib-$i");
}
