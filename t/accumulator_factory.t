#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

use Sidef;

my $code = <<'EOT';

func Accumulator(sum) {
    func(num) { sum += num };
}

EOT

my $sidef = Sidef->new(name => 'accumulator_factory');
my $acc   = $sidef->execute_code($code);

my $x = $acc->call(Sidef::Types::Number::Number->new(1));

my $r1 = $x->call(Sidef::Types::Number::Number->new(5));
$acc->call(Sidef::Types::Number::Number->new(42));    # this should not reset the accumulator
my $r2 = $x->call(Sidef::Types::Number::Number->new(4));

is("$r1", "6");
is("$r2", "10");
