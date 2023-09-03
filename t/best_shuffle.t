#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 6;

use Sidef;

my $code = <<'EOT';

func best_shuffle(str) {

    var s = str.chars
    var t = s.shuffle

    for i in ^s {
        for j in ^s {
            if ((i == j) || (t[i] == s[j]) || (t[j] == s[i])) {
                next
            }
            t[i, j] = t[j, i]
            break
        }
    }

    s ~Z== t -> count(true)
}

EOT

my $sidef    = Sidef->new(name => 'best_shuffle');
my $bshuffle = $sidef->execute_code($code);

my @tests = (
             {
              str   => 'abracadabra',
              score => 0,
             },
             {
              str   => 'seesaw',
              score => 0,
             },
             {
              str   => 'elk',
              score => 0,
             },
             {
              str   => 'grrrrrr',
              score => 5,
             },
             {
              str   => 'up',
              score => 0,
             },
             {
              str   => 'a',
              score => 1,
             },
            );

foreach my $t (@tests) {
    my $score = $bshuffle->call(Sidef::Types::String::String->new($t->{str}));
    is("$score", "$t->{score}", "bshuffle($t->{str}) = $t->{score}");
}
