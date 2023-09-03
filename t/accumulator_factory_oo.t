#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

use Sidef;

my $code = <<'EOT';

class Accumulator(sum) {
    method add(num) {
        sum += num;
    }
}

EOT

my $sidef = Sidef->new(name => 'accumulator_factory_oo');
my $acc   = $sidef->execute_code($code);

my $obj = $acc->call(Sidef::Types::Number::Number->new(1));

my $r1  = $obj->add(Sidef::Types::Number::Number->new(5));
my $tmp = $acc->call(Sidef::Types::Number::Number->new(42));    # this should not reset any previous accumulator
my $r2  = $obj->add(Sidef::Types::Number::Number->new(4));
my $r3  = $tmp->add(Sidef::Types::Number::Number->new("3"));

is("$r1", "6");
is("$r2", "10");
is("$r3", "45");
