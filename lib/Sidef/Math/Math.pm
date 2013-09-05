package Sidef::Math::Math {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      );

    require Math::BigFloat;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub pi {
        my ($self, $places) = @_;
        Sidef::Types::Number::Number->new(
             Math::BigFloat->bpi(defined($places) ? ($self->_is_number($places)) ? ($places->get_value) : return : ()));
    }

    *PI = \&pi;

    sub atan {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$x)->batan(defined($places) ? ($self->_is_number($places)) ? ($places->get_value) : return : ()));
    }

    sub atan2 {
        my ($self, $x, $y, $places) = @_;
        ($self->_is_number($x) && $self->_is_number($y)) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$x)->batan2($$y, defined($places) ? ($self->_is_number($places)) ? ($places->get_value) : return : ()));
    }

    sub cos {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$x)->bcos(defined($places) ? $places : ()));
    }

    sub sin {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$x)->bsin(defined($places) ? $places : ()));
    }

    sub gcd {
        my ($self, @list) = @_;
        $self->_is_number($_) || return for @list;
        Sidef::Types::Number::Number->new(Math::BigFloat::bgcd(map { $$_ } @list));
    }

    sub inf {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat->binf);
    }

    sub precision {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->precision($$n));
    }

    sub accuracy {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->accuracy($$n));
    }

};

1
