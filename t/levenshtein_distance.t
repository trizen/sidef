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
    var d = [@^(t.len+1), s.len.of{[_]}...];
    { |i|
        { |j|
            d[i][j] = (
              s[i-1] == t[j-1]
                ? d[i-1][j-1]
                : [d[i-1][j], d[i][j-1], d[i-1][j-1]].min+1;
              );
        } * t.len;
    } * s.len;
    d[-1][-1] \\ [s.len, t.len].min;
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
