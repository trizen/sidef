#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use Sidef;

my $code = <<'EOT';

func eval_with_x(code, x, y) {
    var f = eval(code);
    x = y;
    eval(code) - f;
}

eval_with_x('2 ** x', 3, 5)     # should be: "24"

EOT

my $sidef = Sidef->new(name => 'eval');
my $result = $sidef->execute_code($code);

is("$result", "24");
