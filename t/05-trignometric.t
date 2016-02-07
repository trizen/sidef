#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 15;

use Sidef;
use Sidef::Types::Number::Number;
use Sidef::Types::Number::Complex;

my $o = 'Sidef::Types::Number::Number';

my $pi = $o->pi;

my $d = $o->new(45);
my $r = $pi->div($o->new(4));

sub rad2deg {
    $o->new(180)->div($pi)->mul($_[0]);
}

sub deg2rad {
    $pi->div($o->new(180))->mul($_[0]);
}

like($r->sin, qr/^0\.7071067811865/);
like($r->cos, qr/^0\.7071067811865/);

like(deg2rad($d)->sin, qr/^0\.7071067811865/);
like(deg2rad($d)->cos, qr/^0\.7071067811865/);

is($r->tan, $o->new(1));
is($r->cot, $o->new(1));

my $asin = $r->sin->asin;
is($asin,          $pi->div($o->new(4)));
is(rad2deg($asin), $d);

my $acos = $r->cos->acos;
is($acos,          $pi->div($o->new(4)));
is(rad2deg($acos), $d);

my $atan = $r->tan->atan;
is($atan,          $pi->div($o->new(4)));
is(rad2deg($atan), $d);

my $acot = $r->cot->acot;
is($acot,          $pi->div($o->new(4)));
is(rad2deg($acot), $d);

like($o->new(1)->atan2($o->new(1))->mul($o->new(4)), qr/^3.14159/);
