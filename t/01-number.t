#!perl

###############################################################################

use strict;
use warnings;

use Test::More tests => 98;

use Sidef;
use Sidef::Types::Number::Number;

sub re($) {
    qr/^\Q$_[0]\E\z/;
}

###############################################################################
# general tests

my $o = 'Sidef::Types::Number::Number';

{    ## Some tests doesn't pass, yet.
    my $x = $o->new(1234);
    is("$x", 1234);

    $x = $o->new("1234/1");
    is("$x", 1234);

    $x = $o->new("1234/2");
    is("$x", 617);

    #$x = $o->new("100/1.0");
    #is($x, 100, qq|\$x = $o->new("100/1.0")|);

    #$x = $o->new("10.0/1.0");
    #is($x, 10, qq|\$x = $o->new("10.0/1.0")|);

    #$x = $o->new("0.1/10");
    #is($x, "1/100", qq|\$x = $o->new("0.1/10")|);

    #$x = $o->new("0.1/0.1");
    #is($x, "1", qq|\$x = $o->new("0.1/0.1")|);

    #$x = $o->new("1e2/10");
    #is($x, 10, qq|\$x = $o->new("1e2/10")|);

    #$x = $o->new("5/1e2");
    #is($x, "1/20", qq|\$x = $o->new("5/1e2")|);

    #$x = $o->new("1e2/1e1");
    #is($x, 10, qq|\$x = $o->new("1e2/1e1")|);

    $x = $o->new("1 / 3");
    like($x->as_rat, re '1/3');

    $x = $o->new("-1 / 3");
    like($x->as_rat, re '-1/3');

    #$x = $o->new("NaN");
    #is($x, "NaN", qq|\$x = $o->new("NaN")|);

    #$x = $o->new("inf");
    #is($x, "inf", qq|\$x = $o->new("inf")|);

    #$x = $o->new("-inf");
    #is($x, "-inf", qq|\$x = $o->new("-inf")|);

    #$x = $o->new("1/");
    #is($x, "NaN", qq|\$x = $o->new("1/")|);

    $x = $o->new("7e", 16);
    is("$x", 126);

    #$x = $o->new("1/1.2");
    #like($x->as_rat, re "5/6");

    #$x = $o->new("1.3/1.2");
    #is($x, "13/12", qq|\$x = $o->new("1.3/1.2")|);

    #$x = $o->new("1.2/1");
    #is($x, "6/5", qq|\$x = $o->new("1.2/1")|);
}

###############################################################################
# general tests

{
    like($o->new(2)->sqrt,                qr/^1\.414213562/);
    like($o->new(100)->log,               qr/^4\.605170185/);
    like($o->new(10)->exp,                qr/^22026\.46579/);
    like($o->new(-4.5)->abs,              qr/^4.5\z/);
    like($o->new(10)->abs,                qr/^10\z/);
    like($o->new(2.9)->floor,             qr/^2\z/);
    like($o->new(2.5)->floor,             qr/^2\z/);
    like($o->new(2.1)->floor,             qr/^2\z/);
    like($o->new(2)->floor,               qr/^2\z/);
    like($o->new(2.9)->ceil,              qr/^3\z/);
    like($o->new(2.5)->ceil,              qr/^3\z/);
    like($o->new(2.1)->ceil,              qr/^3\z/);
    like($o->new(2)->ceil,                qr/^2\z/);
    like($o->new(2.3)->pow($o->new(5.4)), qr/^89.811/);
}

##############################################################################

my ($x, $y, $z);

$x = $o->new('1/4');
$y = $o->new('1/3');

like(($x->add($y))->as_rat, qr'^7/12\z');
like(($x->mul($y))->as_rat, qr'^1/12\z');
like(($x->div($y))->as_rat, qr'^3/4\z');

$x = $o->new('2/3');
$y = $o->new('3/2');
ok(!($x->gt($y)));
ok($x->lt($y));
ok(!($x->eq($y)));

$x = $o->new('-2/3');
$y = $o->new('3/2');
ok(!($x->gt($y)));
ok($x->lt($y));
ok(!($x->eq($y)));

$x = $o->new('-2/3');
$y = $o->new('-2/3');
ok(!($x->gt($y)));
ok(!($x->lt($y)));
ok($x->eq($y));

$x = $o->new('-2/3');
$y = $o->new('-1/3');
ok(!($x->gt($y)));
ok($x->lt($y));
ok(!($x->eq($y)));

$x = $o->new('-124');
$y = $o->new('-122');
is($x->acmp($y), $o->new(1));

$x = $o->new('-124');
$y = $o->new('-122');
is($x->cmp($y), $o->new(-1));

$x = $o->new('3/7');
$y = $o->new('5/7');
like(($x->add($y))->as_rat, re '8/7');

$x = $o->new('3/7');
$y = $o->new('5/7');
like(($x->mul($y))->as_rat, re '15/49');

$x = $o->new('3/5');
$y = $o->new('5/7');
like(($x->mul($y))->as_rat, re '3/7');

$x = $o->new('3/5');
$y = $o->new('5/7');
like(($x->div($y))->as_rat, re '21/25');

$x = $o->new('7/4');
$y = $o->new('1');
like(($x->mod($y))->as_rat, re '3/4');

## Not exact, yet.
#$x = $o->new('7/4');
#$y = $o->new('5/13');
#is(($x % $y)->as_rat, '11/52');

## Not exact, yet.
#$x = $o->new('7/4');
#$y = $o->new('5/9');
#is(($x % $y)->as_rat, '1/12');

#$x = $o->new('-144/9')->bsqrt();
#is("$x", '4i');

$x = $o->new('144/9')->sqrt();
is("$x", '4');

$x = $o->new('3/4');

my $n = 'numerator';
my $d = 'denominator';

my $num = $x->$n;
my $den = $x->$d;

is("$num", 3);
is("$den", 4);

##############################################################################
# mixed arguments

like($o->new('3/7')->add($o->new(1))->as_rat,    re '10/7');
like($o->new('3/10')->add($o->new(1.1))->as_rat, re '7/5');

like($o->new('3/7')->sub($o->new(1))->as_rat,      re '-4/7');
like($o->new('3/10')->sub($o->new('1.1'))->as_rat, re '-4/5');

like($o->new('3/7')->mul($o->new(1))->as_rat,      re '3/7');
like($o->new('3/10')->mul($o->new('1.1'))->as_rat, re '33/100');

like($o->new('3/7')->div($o->new(1))->as_rat,      re '3/7');
like($o->new('3/10')->div($o->new('1.1'))->as_rat, re '3/11');

##############################################################################
# pow

$x = $o->new('2/1')->pow($o->new('3'));
is("$x", '8');

$x = $o->new('1/2')->pow($o->new('3'));
is("$x", '0.125');    # 1/8

$x = $o->new('1/3')->pow($o->new('4'));
like("$x", qr/^0\.0123456/);    # 1/81

$x = $o->new('2/3')->pow($o->new(4));
like($x, qr/^0\.1975308641975308641/);    # 16/81

$x = $o->new('2/3')->pow($o->new('5/3'));
like("$x", qr/^0\.50876188557925/);

##############################################################################
# fac

$x = $o->new('1');
$x->fac();
is("$x", '1');

my @fac = qw(1 1 2 6 24 120);

for (my $i = 0 ; $i < 6 ; $i++) {
    $x = $o->new("$i/1")->fac();
    like($x, re $fac[$i]);
}

# test for $self->bnan() vs. $x->bnan();
$x = $o->new('-1')->fac;
is("$x", 'NaN');

##############################################################################
# inc/dec

$x = $o->new('3/2');
like($x->inc()->as_rat, re '5/2');
$x = $o->new('15/6');
like($x->dec()->as_rat, re '3/2');

##############################################################################
# bsqrt

$x = $o->new('144');
like($x->sqrt(), re '12');

$x = $o->new('144/16');
like($x->sqrt(), re '3');

##############################################################################
# floor/ceil

$x = $o->new('-7/7');
like($x->$n(), re '-1');
like($x->$d(), re '1');
$x = $o->new('-7/7')->floor();
like($x->$n(), re '-1');
like($x->$d(), re '1');

$x = $o->new('49/4');
like($x->floor(), re '12');

$x = $o->new('49/4');
like($x->ceil(), re '13');

##############################################################################
# root(), log(), modpow() and modinv()

$x = $o->new(2)->pow($o->new(32));
$y = $o->new(4);
$z = $o->new(3);

like($x->root($y), re '256');
is(ref($x->root($y)), $o);

like($x->modpow($y, $z), re '1');
is(ref($x->modpow($y, $z)), $o);

$x = $o->new(8);
$y = $o->new(5033);
$z = $o->new(4404);

is($x->modinv($y),      $z);
is(ref($x->modinv($y)), $o);

# square root with exact result
$x = $o->new('1.44');
like($x->root($o->new(2)), re "1.2");

# log with exact result
$x = $o->new('256.1');
like($x->log($o->new(2)), qr/^8.0005634/);

$x = $o->new(144);
like($x->root($o->new('2')), re '12');

$x = $o->new(12 * 12 * 12);
like($x->root($o->new('3')), re '12');

##############################################################################
# as_float()

$x = $o->new('1/2');
my $f = $x->as_float();

like($x->as_rat, re '1/2');
like($f,         re '0.5');

$x = $o->new('2/3');
$f = $x->as_float($o->new(5));

like($x->as_rat, re '2/3');
like($f,         re '0.66667');

##############################################################################
# int()

$x = $o->new('5/2');
is(int($x), '2', '5/2 converted to integer');

$x = $o->new('-1/2');
is(int($x), '0', '-1/2 converted to integer');

##############################################################################
# as_hex(), as_bin(), as_oct()

$x = $o->new('8/8');
like($x->as_hex(), re '1');
like($x->as_bin(), re '1');
like($x->as_oct(), re '1');

$x = $o->new('80/8');
like($x->as_hex(), re 'a');
like($x->as_bin(), re '1010');
like($x->as_oct(), re '12');

##############################################################################
# done

1;
