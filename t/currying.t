#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use Sidef;

my $code = <<'EOT';

func curry(f, *args1) {
    func (*args2) {
        f(args1..., args2...);
    }
}

func add(a, b) {
    a + b
}

var adder = curry(add, 13);
adder(29);

EOT

my $sidef = Sidef->new(name => 'currying');
my $result = $sidef->execute_code($code);

is("$result", "42");
