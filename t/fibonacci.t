#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use Sidef;

my $code = <<'EOT';

func fib((0)) { 0 }
func fib((1)) { 1 }

func fib(n) is cached { fib(n-1) + fib(n-2) }

fib(12)

EOT

my $sidef = Sidef->new(name => 'fibonacci');
my $result = $sidef->execute_code($code);

is("$result", "144");
