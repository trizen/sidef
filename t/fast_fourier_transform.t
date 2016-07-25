#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use Sidef;

my $code = <<'EOT';

func fft(arr) {
    arr.len == 1 && return arr

    var evn = fft([arr[^arr -> grep { .is_even }]])
    var odd = fft([arr[^arr -> grep { .is_odd  }]])
    var twd = (Num.tau.i / arr.len)

    ^odd -> map {|n| odd[n] *= ::exp(twd * n)}
    (evn »+« odd) + (evn »-« odd)
}

var cycles = 3
var sequence = 0..15
var wave = sequence.map {|n| ::sin(n * Num.tau / sequence.len * cycles) }

fft(wave).map { '%6.3f' % .abs }.join(' ')

EOT

my $sidef = Sidef->new(name => 'fast_fourier_transform');
my $result = $sidef->execute_code($code);

is("$result",
    ' 0.000  0.000  0.000  8.000  0.000  0.000  0.000  0.000  0.000  0.000  0.000  0.000  0.000  8.000  0.000  0.000');
