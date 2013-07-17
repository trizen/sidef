package Sidef::Types::Number::Number {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $num) = @_;
        $num = $$num if ref $num;
        $num += 0;
        bless \$num, __PACKAGE__;
    }

    sub get_value {
        ${$_[0]};
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '/'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return;
            $self->new($$self / $$num);
        };

        *{__PACKAGE__ . '::' . '*'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return;
            $self->new($$self * $$num);
        };

        *{__PACKAGE__ . '::' . '+'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return;
            $self->new($$self + $$num);
        };

        *{__PACKAGE__ . '::' . '-'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return;
            $self->new($$self - $$num);
        };

        *{__PACKAGE__ . '::' . '%'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return;
            $self->new($$self % $$num);
        };

        *{__PACKAGE__ . '::' . '**'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return;
            $self->new($$self**$$num);
        };

        *{__PACKAGE__ . '::' . '++'} = sub {
            my ($self) = @_;
            $self->new($$self + 1);
        };

        *{__PACKAGE__ . '::' . '--'} = sub {
            my ($self) = @_;
            $self->new($$self - 1);
        };

        *{__PACKAGE__ . '::' . '<'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return;
            Sidef::Types::Bool::Bool->new($$self < $$num);
        };

        *{__PACKAGE__ . '::' . '>'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return;
            Sidef::Types::Bool::Bool->new($$self > $$num);
        };

        *{__PACKAGE__ . '::' . '>>'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
            $self->new($$self >> $$num);
        };

        *{__PACKAGE__ . '::' . '<<'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
            $self->new($$self << $$num);
        };

        *{__PACKAGE__ . '::' . '&'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self->new(0);
            $self->new($$self & $$num);
        };

        *{__PACKAGE__ . '::' . '|'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
            $self->new($$self | $$num);
        };

        *{__PACKAGE__ . '::' . '<=>'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return;
            Sidef::Types::Number::Number->new($$self <=> $$num);
        };

        *{__PACKAGE__ . '::' . '<='} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return;
            Sidef::Types::Bool::Bool->new($$self <= $$num);
        };

        *{__PACKAGE__ . '::' . '>='} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return;
            Sidef::Types::Bool::Bool->new($$self >= $$num);
        };

        *{__PACKAGE__ . '::' . '=='} = sub {
            my ($self, $num) = @_;
            ref($self) ne ref($num) and return Sidef::Types::Bool::Bool->false;
            Sidef::Types::Bool::Bool->new($$self == $$num);
        };

        *{__PACKAGE__ . '::' . '!='} = sub {
            my ($self, $num) = @_;
            ref($self) ne ref($num) and return Sidef::Types::Bool::Bool->true;
            Sidef::Types::Bool::Bool->new($$self != $$num);
        };

        *{__PACKAGE__ . '::' . '..'} = \&to;
    }

    sub to {
        my ($self, $num) = @_;
        $self->_is_number($num) || return $self;
        Sidef::Types::Array::Array->new(map { ref($self)->new($_) } $$self .. $$num);
    }

    sub sqrt {
        my ($self) = @_;
        $self->new(CORE::sqrt $$self);
    }

    sub sqrt_n {
        my ($self, $n) = @_;
        $self->_is_number($n) || return $self;
        $self->new($$self**(1 / $$n));
    }

    *sqrtN = \&sqrt_n;

    sub pi {
        my ($self) = @_;
        $self->new(atan2(0, -'inf'));
    }

    sub abs {
        my ($self) = @_;
        $self->new(CORE::abs $$self);
    }

    sub hex {
        my ($self) = @_;
        $self->new(CORE::hex $$self);
    }

    sub int {
        my ($self) = @_;
        $self->new(int $$self);
    }

    sub log {
        my ($self) = @_;
        $self->new(CORE::log $$self);
    }

    sub log10 {
        my ($self) = @_;
        $self->new(CORE::log($$self) / CORE::log(10));
    }

    sub log2 {
        my ($self) = @_;
        $self->new(CORE::log($$self) / CORE::log(2));
    }

    sub inf {
        my ($self) = @_;
        $self->new('inf');
    }

    sub chr {
        my ($self) = @_;
        Sidef::Types::Char::Char->new(CORE::chr $$self);
    }

    sub next_power_of_two {
        my ($self) = @_;
        $self->new(2 << CORE::log($$self) / CORE::log(2));
    }

    *nextPowerOfTwo = \&next_power_of_two;

    sub is_positive {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self > 0);
    }

    *isPositive = \&is_positive;

    sub is_negative {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self < 0);
    }

    *isNegative = \&is_negative;

    sub is_even {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self % 2 == 0);
    }

    *isEven = \&is_even;

    sub is_odd {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self % 2 != 0);
    }

    *isOdd = \&is_odd;

    sub is_integer {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self - CORE::int($$self) == 0);
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

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }
}
