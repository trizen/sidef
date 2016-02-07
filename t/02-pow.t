#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 74;

use Sidef;
use Sidef::Types::Number::Number;

my $o = 'Sidef::Types::Number::Number';

my $int1 = $o->new(3);
my $int2 = $o->new(-4);

my $inf  = $o->inf;
my $nan  = $o->nan;
my $ninf = $o->ninf;

sub re($) {
    qr/^\Q$_[0]\E\z/;
}

#################################################################
# integer

my $r = $int1->pow($int1);
is("$r", "27");

$r = $int1->ipow($int1);
is("$r", "27");

$r = $int2->pow($int1);
is("$r", "-64");

$r = $int1->pow($int2);
ok($r eq $int1->pow($int2->abs)->inv);

$r = $int1->ipow($int2);
is("$r", "0");

$r = $int2->ipow($int1);
is("$r", "-64");

$r = $int1->neg->pow($int2);
ok($r eq ($int1->pow($int2->abs)->inv));

$r = $int1->neg->pow($int2->dec);
ok($r eq $int1->pow($int2->dec->abs)->inv->neg);

$r = $int2->pow($int1->neg);
is("$r", "-0.015625");

$r = $int2->pow($int1->neg->inc);
is("$r", "0.0625");

#################################################################
# float + int

my $float1 = $o->new(3.45);
my $float2 = $o->new(-5.67);

$r = $float1->pow($int1);
is("$r", "41.063625");

$r = $float1->pow($int2);
like("$r", qr/^0\.00705868/);

$r = $float1->pow($float2);
like("$r", qr/^0\.0008924/);

$r = $float2->pow($int1);
is("$r", "-182.284263");

$r = $float2->pow($int2);
like("$r", qr/^0\.00096753/);

$r = $float2->pow($int2->abs);
is("$r", "1033.55177121");

$r = $float2->pow($o->new("4.23"));
is(ref($r), 'Sidef::Types::Number::Complex');
like("$r", qr/^1155\.531831861.*?\+1018\.7383470368.*?i\z/);

$r = $o->new(0)->pow($int2);
is(ref($r),  'Sidef::Types::Number::Inf');
is(lc("$r"), 'inf');

$r = $o->new(0)->pow($int1);
is("$r", "0");

##############################################################
# special values
# See: https://en.wikipedia.org/wiki/$nan#Operations_generating_$nan

{

    my $one  = $o->new('1');
    my $mone = $o->new('-1');
    my $zero = $o->new('0');

    # BigNum
    is($zero->pow($zero),                    $one);
    is($one->pow($inf),                      $one);
    is($mone->pow($inf),                     $one);
    is($one->pow($ninf),                     $one);
    is($mone->pow($ninf),                    $one);
    is($inf->pow($zero),                     $one);
    is(($ninf)->pow($zero),                  $one);
    is(($ninf)->pow($o->new(2)),             $inf);
    is(($ninf)->pow($o->new(3)),             $ninf);
    is(($ninf)->pow($o->new(2.3)),           $inf);
    is($inf->pow($o->new(2.3)),              $inf);
    is($inf->pow($o->new(-2.3)),             $zero);
    is(($ninf)->pow($o->new(-3)),            $zero);
    is($inf->pow($inf),                      $inf);
    is(($ninf)->pow($inf),                   $inf);
    is(($ninf)->pow($ninf),                  $zero);
    is($inf->pow($ninf),                     $zero);
    is($o->new(100)->pow($ninf),             $zero);
    is($o->new(-100)->pow($ninf),            $zero);
    is((($zero->pow($inf))->pow($zero)),     $one);
    is($zero->root($zero)->pow($zero),       $one);
    is(($inf)->pow($one->div($o->new(-12))), $zero);
    is(($ninf)->pow($o->new(-12)->inv),      $zero);
    is(($inf)->pow($o->new(2)->inv),         $inf);
    is(($ninf)->pow($one->div($o->new(2))),  $inf);    # sqrt($ninf)
    is(($inf)->pow($one->div($inf)),         $one);
    is(($ninf)->pow($inf->inv),              $one);
    is(($inf)->pow($one->div($ninf)),        $one);
    is(($ninf)->pow($ninf->inv),             $one);
}

##############################################################
# real test

{

    sub round_nth {
        my ($orig, $nth) = @_;

        my $n = $orig->abs;
        my $p = $o->new(10)->pow($nth);

        $n = $n->mul($p);
        $n = $n->add($o->new(0.5));

        if ($n->is_int and $n->is_odd) {
            $n = $n->sub($o->new(0.5));
        }

        $n = $n->int;
        $n = $n->div($p);
        $n = $n->neg if ($orig->is_neg);

        return $n;
    }

    my @tests = (

        # original | rounded | places
        [+1.6,      +2,        0],
        [+1.5,      +2,        0],
        [+1.4,      +1,        0],
        [+0.6,      +1,        0],
        [+0.5,      0,         0],
        [+0.4,      0,         0],
        [-0.4,      0,         0],
        [-0.5,      0,         0],
        [-0.6,      -1,        0],
        [-1.4,      -1,        0],
        [-1.5,      -2,        0],
        [-1.6,      -2,        0],
        [3.016,     3.02,      2],
        [3.013,     3.01,      2],
        [3.015,     3.02,      2],
        [3.045,     3.04,      2],
        [3.04501,   3.05,      2],
        [-1234.555, -1000,     -3],
        [-1234.555, -1200,     -2],
        [-1234.555, -1230,     -1],
        [-1234.555, -1235,     0],
        [-1234.555, -1234.6,   1],
        [-1234.555, -1234.56,  2],
        [-1234.555, -1234.555, 3],
    );

    foreach my $pair (@tests) {
        my ($n, $expected, $places) = @$pair;
        my $rounded = round_nth($o->new($n), $o->new($places));
        is($rounded->eq($o->new($expected)), Sidef::Types::Bool::Bool::TRUE);
    }
}
