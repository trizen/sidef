
use 5.014;
use strict;
use warnings;

package Sidef::Types::Number::Number {

    use parent qw(Sidef Sidef::Convert::Convert);

    sub new {
        my ($class, $num) = @_;
        $num   = $$num       if ref $num;
        $class = ref($class) if ref($class);
        $num += 0;
        bless \$num, $class;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '/'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
            $self->new($$self / $$num);
        };

        *{__PACKAGE__ . '::' . '*'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
            $self->new($$self * $$num);
        };

        *{__PACKAGE__ . '::' . '+'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
            $self->new($$self + $$num);
        };

        *{__PACKAGE__ . '::' . '-'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
            $self->new($$self - $$num);
        };

        *{__PACKAGE__ . '::' . '%'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
            $self->new($$self % $$num);
        };

        *{__PACKAGE__ . '::' . '**'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
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
            $self->_is_number($num) || return $self;
            Sidef::Types::Bool::Bool->new($$self < $$num);
        };

        *{__PACKAGE__ . '::' . '>'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
            Sidef::Types::Bool::Bool->new($$self > $$num);
        };

        *{__PACKAGE__ . '::' . '<='} = sub {
            my ($self, $num) = @_;

            $self->_is_number($num) || return $self;

            Sidef::Types::Bool::Bool->new($$self <= $$num);
        };

        *{__PACKAGE__ . '::' . '>='} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
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

        *{__PACKAGE__ . '::' . '..'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
            Sidef::Types::Array::Array->new(map { ref($self)->new($_) } $$self .. $$num);
        };
    }

    sub sqrt {
        my ($self) = @_;
        $self->new(CORE::sqrt $$self);
    }

    sub abs {
        my ($self) = @_;
        $self->new(CORE::abs $$self);
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

    sub chr {
        my ($self) = @_;
        Sidef::Types::Char::Char->new(CORE::chr $$self);
    }

    sub next_power_of_two {
        my ($self) = @_;
        $self->new(2 << CORE::log($$self) / CORE::log(2));
    }

    sub is_positive {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self > 0);
    }

    sub is_negative {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self < 0);
    }

    sub is_even {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self % 2 == 0);
    }

    sub is_odd {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self % 2 != 0);
    }

    sub is_integer {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self - CORE::int($$self) == 0);
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
};

1;
