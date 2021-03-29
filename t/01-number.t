#!perl -T

###############################################################################

use strict;
use warnings;

use Test::More tests => 167;

use Sidef;

sub re($) {
    qr/^\Q$_[0]\E\z/;
}

###############################################################################
# general tests

my $o = 'Sidef::Types::Number::Number';

{
    my $x = $o->new(1234);
    is("$x", "1234");

    $x = $o->new("1234/1");
    is("$x", "1234");

    $x = $o->new("1234/2");
    is("$x", "617");

    #$x = $o->new("100/1.0");
    #is("$x", "100");

    #$x = $o->new("10.0/1.0");
    #is("$x", "10");

    #$x = $o->new("0.1/10");
    #is("$x", "0.01");

    #$x = $o->new("0.1/0.1");
    #is("$x", "1");

    #$x = $o->new("1e2/10");
    #is("$x", "10");

    #$x = $o->new("5/1e2");
    #is("$x", "0.05");

    #$x = $o->new("1e2/1e1");
    #is("$x", "10");

    $x = $o->new("1 / 3");
    like($x->as_rat, re '1/3');

    $x = $o->new("-1 / 3");
    like($x->as_rat, re '-1/3');

    $x = $o->new("1 / -3");
    like($x->as_rat, re '-1/3');

    $x = $o->new("abc");
    is("$x", "NaN");

    $x = $o->new("inf");
    is("$x", "Inf");

    $x = $o->new("-inf");
    is("$x", "-Inf");

    $x = $o->new("1/");
    is("$x", "NaN");

    $x = $o->new("1/+");
    is("$x", "NaN");

    $x = $o->new("1/-");
    is("$x", "NaN");

    $x = $o->new("1/_");
    is("$x", "NaN");

    $x = $o->new("+");
    is("$x", "NaN");

    $x = $o->new("-");
    is("$x", "NaN");

    $x = $o->new("_");
    is("$x", "NaN");

    $x = $o->new("1_000_000");
    is("$x", "1000000");

    #$x = $o->new("1/2/3/4/5/6");    # is parsed as: (1 / (2 / (3 / (4 / (5 / 6)))))
    #like($x->as_rat, re '5/16');

    #$x = $o->new("1/0");
    #is("$x", "Inf");

    #$x = $o->new("-1/0");
    #is("$x", "-Inf");

    #$x = $o->new("-h5/0", 36);
    #is("$x", "-Inf");

    $x = $o->new("ff/f", 16);
    is("$x", "17");

    $x = $o->new("7e", 16);
    is("$x", "126");

    $x = $o->new("inf", 36);
    is("$x", "24171");

    $x = $o->new("-Inf", 36);
    is("$x", "-24171");

    $x = $o->new("nan", 36);
    is("$x", "30191");

    # fraction in base 10
    $x = $o->new('123/45');
    like($x->as_rat, re '41/15');

    # fraction in base 36
    $x = $o->new("h5/1e", 36);
    like($x->as_float, re "12.34");

    $x = $o->new("14/1e", 36);
    like($x->as_rat, re "4/5");

    # base-10 number, converted to another base
    $x = $o->new($o->new("1211"), 3);
    is("$x", "49");

    #$x = $o->new("1/1.2");
    #like($x->as_rat, re "5/6");

    #$x = $o->new("1.3/1.2");
    #like($x->as_rat, re "13/12");

    #$x = $o->new("1.2/1");
    #like($x->as_rat, re "6/5");
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
    like($o->new(1040)->ilog($o->new(2)), qr/^10\z/);
    like($o->new(2834)->ilog,             qr/^7\z/);

    my $x    = $o->new(1227);
    my $pow  = $o->new(42);
    my $bint = $x->ipow($pow);

    my $zero = $o->new(0);
    my $one  = $o->new(1);
    my $mone = $o->new(-1);

    ok($mone->is_pow($o->new(3)));
    ok(!($mone->is_pow($o->new(2))));

    ok($mone->is_pow($o->new(-3)));
    ok(!($mone->is_pow($o->new(-2))));

    ok($bint->is_pow($pow));
    ok($o->new(-27)->is_pow($o->new(3)));

    ok(!($o->new(-25)->is_pow($o->new(2))));
    ok(!($o->new(-27)->is_pow($o->new(-3))));

    ok($one->is_pow($o->new(3)));
    ok($one->is_pow($o->new(-2)));

    ok($zero->is_pow($one));
    ok($zero->is_pow($o->new(3)));

    ok(!($zero->is_pow($zero)));
    ok(!($zero->is_pow($o->new(-3))));
    ok(!($zero->is_pow($o->new(-4))));
    ok(!($zero->is_pow($o->new(-2))));
    ok(!($zero->is_pow($zero)));

    ok($bint->is_pow($o->new(2)));
    ok($bint->is_pow($o->new(3)));

    ok(!$bint->is_pow($o->new(4)));
    ok(!$bint->is_pow($o->new(5)));
}

##############################################################################

# Bernoulli numbers
{
    my %results = qw(
      0   1
      1   1/2
      2   1/6
      3   0
      4   -1/30
      5   0
      6   1/42
      10  5/66
      12  -691/2730
      20  -174611/330
      22  854513/138
    );

    #
    ## bernfrac()
    #
    foreach my $i (keys %results) {
        my $bn = $o->new($i)->bernfrac->as_rat;
        is("$bn", $results{$i});
    }

    is("${\($o->new(-2)->bernfrac)}", 'NaN');    # make sure we check for even correctly

    is($o->new(52)->bernfrac->as_frac->get_value, '-801165718135489957347924991853/1590');
    is($o->new(106)->bernfrac->as_frac->get_value,
        '36373903172617414408151820151593427169231298640581690038930816378281879873386202346572901/642');

    #
    ## bernreal()
    #
    my $r = $o->new(10);
    is("${\($o->new(-2)->bernreal)}", "NaN");    # check negative values

    is($o->new(1)->bernreal->get_value,                0.5);
    is($o->new(0)->bernreal->get_value,                1);
    is($o->new(3)->bernreal->get_value,                0);
    is($o->new(2)->bernreal->as_float($r)->get_value,  '0.1666666667');
    is($o->new(52)->bernreal->as_float($r)->get_value, '-5.038778101e26');
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

#$x = $o->new('-124');
#$y = $o->new('-122');
#is($x->acmp($y), $o->new(1));

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

$x = $o->new('43/99');
$y = $o->new('13');
like($x->mod($y)->as_rat,      re '7');
like($x->mod($y->rat)->as_rat, re '7');

$x = $o->new('7/4');
$y = $o->new('5/13');
like(($x->mod($y))->as_rat, re '11/52');

$x = $o->new('7/4');
$y = $o->new('5/9');
like(($x->mod($y))->as_rat, re '1/12');

$x = $o->new('-144/9')->sqrt();
is("$x", '4i');

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
is($x->as_frac->get_value, '1/8');
is("$x",                   '0.125');

$x = $o->new('1/3')->pow($o->new('4'));
is($x->as_frac->get_value, '1/81');
like("$x", qr/^0\.0123456790123456790123456790123456790123456790\d*\z/);

$x = $o->new('2/3')->pow($o->new(4));
is($x->as_frac->get_value, '16/81');
like("$x", qr/^0\.197530864197530864197530864197530864197530864\d*\z/);

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
# root(), log(), powmod() and invmod()

$x = $o->new(2)->pow($o->new(32));
$y = $o->new(4);
$z = $o->new(3);

like($x->root($y), re '256');
is(ref($x->root($y)), $o);

like($x->powmod($y, $z), re '1');
is(ref($x->powmod($y, $z)), $o);

$x = $o->new(8);
$y = $o->new(5033);
$z = $o->new(4404);

is($x->invmod($y),      $z);
is(ref($x->invmod($y)), $o);

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
