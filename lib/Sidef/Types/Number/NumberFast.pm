## package Sidef::Types::Number::NumberFast
package Sidef::Types::Number::Number {

    use 5.014;
    use strict;
    use warnings;

    no warnings 'redefine';

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $num) = @_;
        $num += 0;
        bless \$num, __PACKAGE__;
    }

    sub newInt {
        my (undef, $num) = @_;
        __PACKAGE__->new(CORE::int($num));
    }

    *new_int = \&newInt;

    sub get_value { ${$_[0]} }

    sub inc {
        my ($self) = @_;
        $self->new($$self + 1);
    }

    sub dec {
        my ($self) = @_;
        $self->new($$self - 1);
    }

    sub and {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self & $$num);
    }

    sub or {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self | $$num);
    }

    sub xor {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self ^ $$num);
    }

    sub cmp {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        __PACKAGE__->new($$self <=> $$num);
    }

    sub acmp {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        __PACKAGE__->new(CORE::abs($$self) <=> CORE::abs($$num));
    }

    sub factorial {
        my ($self) = @_;
        my $fac = 1;
        $fac *= $_ for (2 .. $$self);
        $self->new($fac);
    }

    *fac = \&factorial;

    sub root {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        $self->new($$self**(1 / $$n));
    }

    sub hex {
        my ($self) = @_;
        $self->new(CORE::hex($$self));
    }

    sub bin {
        my ($self) = @_;
        $self->new(oct("b$$self"));
    }

    sub int {
        my ($self) = @_;
        $self->new(CORE::int($$self));
    }

    *as_int = \&int;

    sub log {
        my ($self, $base) = @_;
        my $log = CORE::log($$self);

        defined($base)
          ? $self->_is_number($base)
              ? (return $self->new($log / CORE::log($$base)))
              : return
          : ();

        $self->new($log);
    }

    sub log10 {
        my ($self) = @_;
        $self->new(CORE::log($$self) / CORE::log(10));
    }

    sub log2 {
        my ($self) = @_;
        $self->new(CORE::log($$self) / CORE::log(2));
    }

    sub neg {
        my ($self) = @_;
        $self->new(-$$self);
    }

    *negate = \&neg;

    sub not {
        my ($self) = @_;
        $self->new(-$$self - 1);
    }

    sub sign {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self >= 0 ? '+' : '-');
    }

    sub nan {
        my ($self) = @_;
        $self->new('nan');
    }

    *NaN = \&nan;

    sub next_power_of_two {
        my ($self) = @_;
        $self->new(2 << CORE::log($$self) / CORE::log(2));
    }

    *nextPowerOfTwo = \&next_power_of_two;

    sub next_power_of {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$num**(CORE::int(CORE::log($$self) / CORE::log($$num)) + 1));
    }

    *nextPowerOf = \&next_power_of;

    sub is_zero {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self == 0);
    }

    *isZero = \&is_zero;

    sub is_nan {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self eq 'nan');
    }

    *isNaN  = \&is_nan;
    *is_NaN = \&is_nan;

    sub is_positive {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self >= 0);
    }

    *isPositive = \&is_positive;
    *isPos      = \&is_positive;
    *is_pos     = \&is_positive;

    sub is_inf {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self == 'inf');
    }

    *isInf       = \&is_inf;
    *is_infinite = \&is_inf;
    *isInfinite  = \&is_inf;

    sub is_negative {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self < 0);
    }

    *isNegative = \&is_negative;
    *isNeg      = \&is_negative;
    *is_neg     = \&is_negative;

    sub is_even {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self % 2 == 0);
    }

    *isEven = \&is_even;

    sub is_odd {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self % 2 == 1);
    }

    *isOdd = \&is_odd;

    sub is_integer {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self == CORE::int($$self));
    }

    *isInt     = \&is_integer;
    *is_int    = \&is_integer;
    *isInteger = \&is_integer;

    sub rand {
        my ($self, $max) = @_;

        my $min = $$self;
        $max = ref($max) ? $$max : do { $min = 0; $$self };

        $self->new($min + CORE::rand($max - $min));
    }

    sub ceil {
        my ($self) = @_;
        CORE::int($$self) == $$self
          && return $self;
        $self->new(CORE::int($$self + 1));
    }

    sub floor {
        my ($self) = @_;
        $self->new(CORE::int($$self));
    }

    sub round { ... }

    sub roundf {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new(sprintf "%.*f", $$num * -1, $$self);
    }

    *fround = \&roundf;
    *fRound = \&roundf;

    sub digit  { ... }
    sub nok    { ... }
    sub length { ... }

    *len = \&length;

    sub to_bin {
        my ($self) = @_;

        my $dec      = $$self;
        my $reminder = $dec % 2;

        my @bin;
        while ($dec > 0) {
            unshift @bin, $reminder;
            $reminder = ($dec >>= 1) % 2;
        }

        $self->new(join('', @bin));
    }

    sub commify {
        my ($self) = @_;

        my $n = $$self;
        my $x = $n;

        my $neg = $n =~ s{^-}{};
        $n =~ /\.|$/;

        if ($-[0] > 3) {

            my $l = $-[0] - 3;
            my $i = ($l - 1) % 3 + 1;

            $x = substr($n, 0, $i) . ',';

            while ($i < $l) {
                $x .= substr($n, $i, 3) . ',';
                $i += 3;
            }

            $x .= substr($n, $i);
        }

        Sidef::Types::String::String->new(($neg ? '-' : '') . $x);
    }

    sub sstr {
        my ($self) = @_;
        Sidef::Types::String::String->new(sprintf "%g", $$self);
    }

    sub shift_right {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self >> $$num);
    }

    *shiftRight = \&shift_right;

    sub shift_left {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self << $$num);
    }

    *shiftLeft = \&shift_left;

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
    }
};

1
