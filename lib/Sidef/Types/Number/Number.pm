package Sidef::Types::Number::Number {

    use utf8;
    use 5.014;
    use strict;
    use warnings;

    use Math::BigFloat try => 'GMP,Pari';

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $num) = @_;

        ref($num) eq 'Math::BigFloat'
          ? (bless \$num, __PACKAGE__)
          : (bless \Math::BigFloat->new($num), __PACKAGE__);
    }

    sub newInt {
        my (undef, $num) = @_;

            ref($num) eq 'Math::BigInt' ? (bless \$num, __PACKAGE__)
          : ref($num) eq 'Math::BigFloat' || ref($num) eq __PACKAGE__ ? (bless \Math::BigInt->new($num->as_int))
          :   (bless \Math::BigInt->new(${__PACKAGE__->new($num)}->as_int), __PACKAGE__);
    }

    *new_int = \&newInt;

    sub get_value { ${$_[0]}->numify }

    sub mod {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self % $$num);
    }

    sub pow {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self**$$num);
    }

    sub inc {
        my ($self) = @_;
        $self->new($$self->copy->binc);
    }

    sub dec {
        my ($self) = @_;
        $self->new($$self->copy->bdec);
    }

    sub lt {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        Sidef::Types::Bool::Bool->new($$self < $$num);
    }

    sub gt {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        Sidef::Types::Bool::Bool->new($$self > $$num);
    }

    sub and {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self->as_int->band($$num->as_int));
    }

    sub or {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self->as_int->bior($$num->as_int));
    }

    sub xor {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self->as_int->bxor($$num->as_int));
    }

    sub eq {
        my ($self, $num) = @_;
        ref($self) ne ref($num) and return Sidef::Types::Bool::Bool->false;
        Sidef::Types::Bool::Bool->new($$self == $$num);
    }

    sub ne {
        my ($self, $num) = @_;
        ref($self) ne ref($num) and return Sidef::Types::Bool::Bool->true;
        Sidef::Types::Bool::Bool->new($$self != $$num);
    }

    sub cmp {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        Sidef::Types::Number::Number->new($$self->bcmp($$num));
    }

    sub ge {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        Sidef::Types::Bool::Bool->new($$self >= $$num);
    }

    sub le {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        Sidef::Types::Bool::Bool->new($$self <= $$num);
    }

    sub subtract {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self - $$num);
    }

    sub add {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self + $$num);
    }

    sub multiply {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self * $$num);
    }

    sub div {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self / $$num);
    }

    sub factorial {
        my ($self) = @_;
        $self->new($$self->copy->bfac);
    }

    *fac = \&factorial;

    sub to {
        my ($self, $num, $step) = @_;

        $self->_is_number($num) || return;
        $step = defined($step) ? $self->_is_number($step) ? ($$step) : return : 1;

        my $array = Sidef::Types::Array::Array->new();

        for (my $i = $$self ; $i <= $$num ; $i += $step) {
            $array->push($self->new($i));
        }

        $array;
    }

    *upto = \&to;
    *upTo = \&to;

    sub downto {
        my ($self, $num, $step) = @_;

        $self->_is_number($num) || return;
        $step = defined($step) ? $self->_is_number($step) ? ($$step) : return : 1;

        my $array = Sidef::Types::Array::Array->new();

        for (my $i = $$self ; $i >= $$num ; $i -= $step) {
            $array->push($self->new($i));
        }

        $array;
    }

    *downTo = \&downto;

    sub sqrt {
        my ($self) = @_;
        $self->new(sqrt $$self);
    }

    sub root {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        $self->new($$self->copy->broot($n));
    }

    sub abs {
        my ($self) = @_;
        $self->new(CORE::abs $$self);
    }

    sub hex {
        my ($self) = @_;
        $self->new(Math::BigInt->new("0x$$self"));
    }

    sub bin {
        my ($self) = @_;
        $self->new(Math::BigInt->new("0b$$self"));
    }

    sub exp {
        my ($self) = @_;
        $self->new(CORE::exp $$self);
    }

    sub int {
        my ($self) = @_;
        $self->new($$self->as_int);
    }

    *as_int = \&int;

    sub cos {
        my ($self) = @_;
        $self->new(CORE::cos $$self);
    }

    sub sin {
        my ($self) = @_;
        $self->new(CORE::sin $$self);
    }

    sub log {
        my ($self, $base) = @_;
        $self->new($$self->copy->blog(defined($base) ? $self->_is_number($base) ? ($$base) : return : ()));
    }

    sub log10 {
        my ($self) = @_;
        $self->new($$self->copy->blog(10));
    }

    sub log2 {
        my ($self) = @_;
        $self->new($$self->copy->blog(2));
    }

    sub inf {
        my ($self) = @_;
        $self->new('inf');
    }

    sub neg {
        my ($self) = @_;
        $self->new($$self->copy->bneg);
    }

    *negate = \&neg;

    sub not {
        my ($self) = @_;
        $self->new($$self->copy->bnot);
    }

    sub sign {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self->sign);
    }

    sub nan {
        my ($self) = @_;
        $self->new(Math::BigFloat->bnan);
    }

    *NaN = \&nan;

    sub chr {
        my ($self) = @_;
        Sidef::Types::Char::Char->new(CORE::chr $self->get_value);
    }

    sub next_power_of_two {
        my ($self) = @_;
        $self->new(2 << ($$self->copy->blog(2)->as_int));
    }

    *nextPowerOfTwo = \&next_power_of_two;

    sub next_power_of {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$num**($$self->copy->blog($$num)->as_int->binc));
    }

    *nextPowerOf = \&next_power_of;

    sub is_nan {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_nan);
    }

    *isNaN  = \&is_nan;
    *is_NaN = \&is_nan;

    sub is_positive {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_pos);
    }

    *isPositive = \&is_positive;
    *isPos      = \&is_positive;
    *is_pos     = \&is_positive;

    sub is_inf {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_inf);
    }

    *isInf       = \&is_inf;
    *is_infinite = \&is_inf;
    *isInfinite  = \&is_inf;

    sub is_negative {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_neg);
    }

    *isNegative = \&is_negative;
    *isNeg      = \&is_negative;
    *is_neg     = \&is_negative;

    sub is_even {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->as_int->is_even);
    }

    *isEven = \&is_even;

    sub is_odd {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->as_int->is_odd);
    }

    *isOdd = \&is_odd;

    sub is_integer {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self == $$self->as_int);
    }

    *isInt     = \&is_integer;
    *is_int    = \&is_integer;
    *isInteger = \&is_integer;

    sub rand {
        my ($self, $max) = @_;

        my $min = $$self;
        $max = ref($max) ? $$max : do { $min = 0; $$self };

        $self->new($min + rand($max - $min));
    }

    sub ceil {
        my ($self) = @_;
        $self->new($$self->copy->bceil);
    }

    sub floor {
        my ($self) = @_;
        $self->new($$self->copy->bfloor);
    }

    sub round {
        my ($self, $places) = @_;
        $self->new($$self->copy->bround(defined($places) ? ($self->_is_number($places)) ? ($$places) : (return) : ()));
    }

    sub roundf {
        my ($self, $places) = @_;
        $self->new($$self->copy->bfround(defined($places) ? ($self->_is_number($places)) ? ($$places) : (return) : ()));
    }

    *fround = \&roundf;
    *fRound = \&roundf;

    sub range {
        my ($self) = @_;
        $$self >= 0 ? $self->new(0)->to($self) : $self->to($self->new(0));
    }

    sub length {
        my ($self) = @_;
        $self->new($$self->length);
    }

    *len = \&length;

    sub digit {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        $self->new($$self->as_int->digit($$n));
    }

    sub nok {
        my ($self, $k) = @_;
        $self->_is_number($k) || return;
        $self->new($$self->as_int->bnok($$k));
    }

    sub to_bin {
        my ($self) = @_;

        my $dec      = Math::BigInt->new($$self);
        my $reminder = $dec % 2;

        my @bin;
        while ($dec->is_pos) {
            unshift @bin, $reminder;
            $reminder = $dec->brsft(1) % 2;
        }

        $self->new(join('', @bin));
    }

    sub commify {
        my ($self) = @_;

        my $n = $$self->bstr;
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

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }

    sub sstr {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self->bsstr);
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '*'}   = \&multiply;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&subtract;
        *{__PACKAGE__ . '::' . '%'}   = \&mod;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'} = \&le;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'} = \&ge;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '='}   = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'} = \&ne;
        *{__PACKAGE__ . '::' . '..'}  = \&to;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;

        *{__PACKAGE__ . '::' . '>>'} = sub {
            my ($self, $num, $base) = @_;
            $self->_is_number($num) || return;
            $self->new($$self->copy->brsft($$num, defined($base) ? $self->_is_number($base) ? $$base : return : ()));
        };

        *{__PACKAGE__ . '::' . '<<'} = sub {
            my ($self, $num, $base) = @_;
            $self->_is_number($num) || return;
            $self->new($$self->copy->blsft($$num, defined($base) ? $self->_is_number($base) ? $$base : return : ()));
        };
    }
}
