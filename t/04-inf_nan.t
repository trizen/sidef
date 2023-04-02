#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan(tests => 106);

use Sidef;

my $o = 'Sidef::Types::Number::Number';

my $mone = $o->new(-1);
my $zero = $o->new(0);
my $one  = $o->new(1);

my $five = $o->new(5);

my $inf  = $o->inf;
my $nan  = $o->nan;
my $ninf = $o->ninf;

my $i = Sidef::Types::Number::Complex->new(0, 1);

my $true  = Sidef::Types::Bool::Bool::TRUE;
my $false = Sidef::Types::Bool::Bool::FALSE;

##################################################
# extreme

is($one->div($zero),      $inf);
is($mone->div($zero),     $ninf);
is($zero->neg,            $zero);               # should be -0.0
is($inf->add($one),       $inf);
is($one->sub($inf),       $ninf);
is($inf->mul($five),      $inf);
is($inf->div($five),      $inf);
is($five->neg->sub($inf), $ninf);
is($ninf->sub($five),     $ninf);
is($five->neg->add($inf), $inf);
is($ninf->add($five),     $ninf);
is($inf->add($five->neg), $inf);
is($one->div($inf),       $zero);
is($mone->div($inf),      $zero);               # should be -0.0
is($ninf,                 $mone->div($zero));
is($inf->add($inf),       $inf);
is($inf->mul($inf),       $inf);
is($inf->mul($ninf),      $ninf);
is($ninf->mul($inf),      $ninf);
is($zero->lt($inf),       $true);
is($inf->eq($inf),        $true);
is($ninf->eq($ninf),      $true);
is($ninf->cmp($inf),      $mone);
is($inf->cmp($ninf),      $one);
is($inf->cmp($inf),       $zero);
is($ninf->cmp($ninf),     $zero);
is($zero->cmp($ninf),     $one);
is($nan->gt($zero),       undef);
is($nan->lt($zero),       undef);
is($nan->eq($zero),       $false);
is($inf->div($mone),      $ninf);
is($inf->abs,             $inf);
is($ninf->abs,            $inf);
is($inf->sqrt,            $inf);
is($inf->erfc,            $zero);
is(($ninf)->erfc,         $o->new(2));
like($o->new("-1.01")->acos, qr/^3\.141592653.*?\s*-\s*0\.14130376.*i\z/);
like($o->new("1.01")->acos,  qr/^-0\.1413037.*i\z/);
like($o->new("-1.01")->asin, qr/^-1\.5707963.*?\s*\+\s*0\.141303769.*i\z/);
like($o->new("1.01")->asin,  qr/^1\.57079632.*?\s*\+\s*0\.141303769.*i\z/);
is($mone->sqrt, $i);

##################################################
# Root

is($inf->root($o->new(-12)),  $zero);
is($ninf->root($o->new(-12)), $zero);
is($inf->root($o->new(2)),    $inf);
is($inf->root($inf),          $one);
is($ninf->root($inf),         $one);
is($inf->root($ninf),         $one);
is($ninf->root($ninf),        $one);
is($ninf->root($o->new(1)),   $ninf);
is($ninf->root($o->new(0)),   $inf);
is($inf->root($o->new(1)),    $inf);
is($inf->root($o->new(0)),    $inf);

like($inf->asec, qr/^1\.5707963267/);

is($one->root($mone),  $one);
is($one->iroot($mone), $one);

is($zero->root($zero),  $zero);
is($zero->iroot($zero), $zero);

is($zero->root($mone),  $inf);
is($zero->iroot($mone), $inf);

is($mone->root($zero),  $one);
is($mone->iroot($zero), $one);

is($mone->root($one),  $mone);
is($mone->iroot($one), $mone);

my $two  = $one->add($one);
my $mtwo = $two->neg;

is($mone->root($two), $i);

is($one->root($mtwo),  $one);
is($one->iroot($mtwo), $one);

is($mone->root($mtwo), $i->neg);

is($mtwo->root($mtwo)->abs->int, $zero);

is($zero->root($mone),  $inf);
is($zero->iroot($mone), $inf);

is($two->root($mone), $one->div($two));

is($two->iroot($mone), $zero);
is($two->iroot($mtwo), $zero);

#################################################
# Pow

is($inf->pow($o->new(-12)->inv),  $zero);
is($ninf->pow($o->new(-12)->inv), $zero);
is($inf->pow($o->new(2)->inv),    $inf);
is($inf->pow($o->new(2)->inv),    $inf);
is($inf->pow($inf->inv),          $one);
is($ninf->pow($inf->inv),         $one);
is($inf->pow($ninf->inv),         $one);
is($ninf->pow($ninf->inv),        $one);
is($ninf->pow($o->new(1)->inv),   $ninf);
is($ninf->pow($o->new(0)->inv),   $inf);
is($inf->pow($o->new(1)->inv),    $inf);
is($inf->pow($o->new(0)->inv),    $inf);

###################################################
# Infinity <=> Number

is($inf->gt($five), $true);
ok($inf->ge($zero),       $true);
ok($ninf->lt($zero),      $true);
ok($ninf->lt($mone),      $true);
ok($ninf->lt($inf),       $true);
ok($inf->ge($ninf),       $true);
ok($inf->gt($ninf),       $true);
ok($five->lt($inf),       $true);
ok($five->le($inf),       $true);
ok($five->ge($ninf),      $true);
ok($five->neg->gt($ninf), $true);
is($inf->cmp($inf),        $zero);
is($inf->cmp($ninf),       $one);
is($ninf->cmp($inf),       $mone);
is($inf->cmp($five),       $one);
is($ninf->cmp($five->neg), $mone);
is($ninf->cmp($five),      $mone);
is($five->cmp($inf),       $mone);
is($five->cmp($ninf),      $one);
is($five->neg->cmp($ninf), $one);
is($five->neg->cmp($inf),  $mone);
