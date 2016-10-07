#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

use Sidef;

my $code = <<'EOT';

func lev(s, t) {
    var d = [@(0 .. t.len), s.len.of {[_]}...]
    for i,j in (^s ~X ^t) {
        d[i+1][j+1] = (
            s[i] == t[j]
                ? d[i][j]
                : 1+Math.min(d[i][j+1], d[i+1][j], d[i][j])
        )
    }
    d[-1][-1]
}

EOT

my $sidef = Sidef->new(name => 'levenshtein');
my $lev = $sidef->execute_code($code);

my @tests = (
             {
              s1 => 'kitten',
              s2 => 'sitting',
              d  => 3
             },
             {
              s1 => 'rosettacode',
              s2 => 'raisethysword',
              d  => 8,
             }
            );

foreach my $t (@tests) {
    my ($s1, $s2) = map { Sidef::Types::String::String->new($t->{$_})->chars } ('s1', 's2');
    my $dist = $lev->call($s1, $s2);
    is("$dist", "$t->{d}", "lev($t->{s1}, $t->{s2}) = $t->{d}");
}
