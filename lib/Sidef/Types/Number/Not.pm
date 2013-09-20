package Sidef::Types::Number::Not {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef);

    sub new {
        bless {}, __PACKAGE__;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '~'} = sub {
            my ($self, $number) = @_;
            $self->_is_number($number, 1) || return;
            $number->not;
        };
    }

};

1;
