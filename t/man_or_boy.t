#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

use Sidef;

my @codes = (
    <<'EOT1',
func a(k, x1, x2, x3, x4, x5) {
    func b() { a(--k, b, x1, x2, x3, x4) };
    k <= 0 ? (x4() + x5()) : b();
}

a(10, func(){1}, func(){-1}, func(){-1}, func(){1}, func(){0})
EOT1

    <<'EOT2',
func a(k, x1, x2, x3, x4, x5) {
    k <= 0 ? (x4() + x5())
           : func b { a(--k, b, x1, x2, x3, x4) }();
}

a(10, {1}, {-1}, {-1}, {1}, {0})
EOT2

    <<'EOT3',
class MOB {
    method a(k, x1, x2, x3, x4, x5) {
        func b { self.a(--k, b, x1, x2, x3, x4) }
        k <= 0 ? (x4() + x5()) : b()
    }
}

var obj = MOB();
obj.a(10, {1}, {-1}, {-1}, {1}, {0})
EOT3
            );

foreach my $code (@codes) {

    my $sidef = Sidef->new(name => 'man_or_boy');
    my $result = $sidef->execute_code($code);

    is("$result", "-67");
}
