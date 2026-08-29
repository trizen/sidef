#!perl -T

use strict;
use warnings;

use Test::More;
use Sidef;

plan tests => 2;

my $str = Sidef::Types::String::String->new('hi');

my $left = $str->pad_left(7, '***');
my $right = $str->pad_right(7, '***');

is("$left", 'hi*****', 'pad_left uses only the first padding character');
is("$right", '*****hi', 'pad_right uses only the first padding character');
