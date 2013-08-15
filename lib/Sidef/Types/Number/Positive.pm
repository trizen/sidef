package Sidef::Types::Number::Positive {

    # This module is non-sense. I know...

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef);

    sub new {
        bless {}, __PACKAGE__
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+'} = sub {
            my ($self, $number) = @_;
            $self->_is_number($number) || return;
            Sidef::Types::Number::Number->new(+$$number);
        };
    }

};

1;
