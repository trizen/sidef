#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 10;

use Sidef;

my $code = <<'EOT';

func bernoulli_number{};    # must be declared before used

func binomial(n, k) is cached {
    (k == 0) || (n == k) ? 1 : (binomial(n - 1, k - 1) + binomial(n - 1, k));
}

func bern_helper(n, k) {
    binomial(n, k) * (bernoulli_number(k) / (n - k + 1));
}

func bern_diff(n, k, d) {
    n < k ? d : bern_diff(n, k + 1, d - bern_helper(n + 1, k));
}

bernoulli_number = func(n) is cached {

    n.is_one && return 1/2;
    n.is_odd && return   0;

    n > 0 ? bern_diff(n - 1, 0, 1) : 1;
}

EOT

my $sidef = Sidef->new(name => 'bernoulli_numbers');
my $bern  = $sidef->execute_code($code);

my @bnums = qw(
  1/1
  1/6
  -1/30
  1/42
  -1/30
  5/66
  -691/2730
  7/6
  -3617/510
  43867/798
);

foreach my $i (0 .. 9) {
    my ($num, $den) = $bern->call(Sidef::Types::Number::Number->new(2 * $i))->nude;
    is("$num/$den", "$bnums[$i]");
}
