
use 5.014;
use strict;
use warnings;

package Sidef::Types::Number::Number {

    use parent qw(Sidef Sidef::Convert::Convert);

    sub new {
        my ($class, $num) = @_;
        $num   = $$num       if ref $num;
        $class = ref($class) if ref($class);
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

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }
};

1;
