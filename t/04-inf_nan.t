#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 105;

use Sidef;
use Sidef::Types::Number::Number;
use Sidef::Types::Number::Complex;

my $o = 'Sidef::Types::Number::Number';

my $mone = $o->new(-1);
my $zero = $o->new(0);
my $one  = $o->new(1);

my $five = $o->new(5);

my $inf  = $o->inf;
my $nan  = $o->nan;
my $ninf = $o->ninf;

my $true  = Sidef::Types::Bool::Bool::TRUE;
my $false = Sidef::Types::Bool::Bool::FALSE;

##################################################
# extreme

is($one->div($zero),             $inf);
is($mone->div($zero),            $ninf);
is($zero->div($zero),            $nan);
is($zero->neg,                   $zero);               # should be -0.0
is($inf->add($one),              $inf);
is($one->sub($inf),              $ninf);
is($inf->mul($five),             $inf);
is($inf->div($five),             $inf);
is($zero->mul($inf),             $nan);
is($five->neg->sub($inf),        $ninf);
is($ninf->sub($five),            $ninf);
is($five->neg->add($inf),        $inf);
is($ninf->add($five),            $ninf);
is($inf->add($ninf),             $nan);
is($ninf->add($inf),             $nan);
is($inf->add($five->neg),        $inf);
is($one->div($inf),              $zero);
is($mone->div($inf),             $zero);               # should be -0.0
is($ninf,                        $mone->div($zero));
is($ninf->mul($zero),            $nan);
is($zero->mul($ninf),            $nan);
is($zero->mul($one)->div($zero), $nan);
is($inf->add($inf),              $inf);
is($inf->sub($inf),              $nan);
is($inf->mul($inf),              $inf);
is($inf->mul($ninf),             $ninf);
is($ninf->mul($inf),             $ninf);
is($inf->div($inf),              $nan);
is($inf->mul($zero),             $nan);
is($zero->lt($inf),              $true);
is($inf->eq($inf),               $true);
is($ninf->eq($ninf),             $true);
is($ninf->cmp($inf),             $mone);
is($inf->cmp($ninf),             $one);
is($inf->cmp($inf),              $zero);
is($ninf->cmp($ninf),            $zero);
is($zero->cmp($ninf),            $one);
is($nan->add($one),              $nan);
is($nan->mul($five),             $nan);
is($nan->sub($nan),              $nan);
is($nan->mul($inf),              $nan);
is($nan->neg,                    $nan);
is($nan->gt($zero),              $false);
is($nan->lt($zero),              $false);
is($nan->eq($zero),              $false);
is($inf->sin,                    $nan);
is($ninf->sin,                   $nan);
is($inf->cos,                    $nan);
is($ninf->cos,                   $nan);
is($inf->div($mone),             $ninf);
is($inf->add($ninf),             $nan);
is($ninf->add($inf),             $nan);
is($inf->sub($inf),              $nan);
is($ninf->sub($ninf),            $nan);
is($zero->mul($inf),             $nan);
is($nan->add($nan),              $nan);
is($inf->abs,                    $inf);
is($ninf->abs,                   $inf);
is($nan->abs,                    $nan);
is($inf->sqrt,                   $inf);
is($ninf->sqrt,                  $inf);
is($inf->erfc,                   $zero);
is(($ninf)->erfc,                $o->new(2));
is($inf->fac,                    $inf);
is(($ninf)->fac,                 $nan);
like($o->new("-1.01")->acos, qr/^3\.141592653.*?-0\.14130376.*i\z/);
like($o->new("1.01")->acos,  qr/^-0\.1413037.*i\z/);
like($o->new("-1.01")->asin, qr/^-1\.5707963.*?\+0\.141303769.*i\z/);
like($o->new("1.01")->asin,  qr/^1\.57079632.*?\+0\.141303769.*i\z/);
is($mone->sqrt, Sidef::Types::Number::Complex->new(0, 1));
is($inf->pow($nan),  $nan);
is($ninf->pow($nan), $nan);
is($nan->pow($inf),  $nan);

##################################################
# Root

is(($inf)->root($o->new(-12)),  $zero);
is(($inf)->iroot($o->new(-12)), $zero);
is(($ninf)->root($o->new(-12)), $zero);
is(($inf)->root($o->new(2)),    $inf);
is(($inf)->iroot($o->new(2)),   $inf);
is(($ninf)->root($o->new(2)),   $inf);    # sqrt($ninf) -- shouldn't be $nan?
is(($inf)->root($inf),          $one);
is(($ninf)->root($inf),         $one);
is(($inf)->root($ninf),         $one);
is(($ninf)->root($ninf),        $one);

like($inf->asec, qr/^1\.5707963267/);

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
