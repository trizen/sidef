package Sidef::Types::Number::Unary {

    use utf8;
    our @ISA = qw(Sidef);

    sub new {
        bless {}, __PACKAGE__;
    }

    {
        *{__PACKAGE__ . '::' . '+'} = sub {
            $_[1];
        };

        *{__PACKAGE__ . '::' . '~'} = sub {
            $_[1]->not;
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

        *{__PACKAGE__ . '::' . '!'} = sub {
            my ($self, $bool) = @_;
            Sidef::Types::Bool::Bool->new(!$bool);
        };
    }

};

1;
