package Sidef::Types::Number::Unary {

    use utf8;
    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef);

    sub new {
        bless {}, __PACKAGE__;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '+'} = sub {
            $_[1];
        };

        *{__PACKAGE__ . '::' . '~'} = sub {
            my ($self, $number) = @_;
            $self->_is_number($number, 1) || return;
            $number->not;
        };

        *{__PACKAGE__ . '::' . '-'} = sub {
            my ($self, $number) = @_;
            $self->_is_number($number, 1) || return;
            $number->negate;
        };

        *{__PACKAGE__ . '::' . '√'} = sub {
            my ($self, $number) = @_;
            $self->_is_number($number, 1) || return;
            $number->sqrt;
        };

        *{__PACKAGE__ . '::' . '?'} = sub {
            my ($self, $obj) = @_;
            Sidef::Types::Bool::Bool->new($obj);
        };
    }

};

1;
