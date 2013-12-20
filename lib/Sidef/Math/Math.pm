package Sidef::Math::Math {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      );

    sub new {
        bless {}, __PACKAGE__;
    }

    sub pi {
        my ($self, $places) = @_;
        Sidef::Types::Number::Number->new(
                        Math::BigFloat->new(0)->bpi(defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    *PI = \&pi;

    sub atan {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        Sidef::Types::Number::Number->new(
                    Math::BigFloat->new($$x)->batan(defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    sub atan2 {
        my ($self, $x, $y, $places) = @_;
        ($self->_is_number($x) && $self->_is_number($y)) || return;
        Sidef::Types::Number::Number->new(
              Math::BigFloat->new($$x)->batan2($$y, defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    sub cos {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        Sidef::Types::Number::Number->new(
                     Math::BigFloat->new($$x)->bcos(defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    sub sin {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        Sidef::Types::Number::Number->new(
                     Math::BigFloat->new($$x)->bsin(defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    sub gcd {
        my ($self, @list) = @_;
        $self->_is_number($_) || return for @list;
        Sidef::Types::Number::Number->new(Math::BigFloat::bgcd(map { $$_ } @list));
    }

    sub abs {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $num->abs;
    }

    sub lcm {
        my ($self, @list) = @_;
        $self->_is_number($_) || return for @list;
        Sidef::Types::Number::Number->new(Math::BigFloat::blcm(map { $$_ } @list));
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

    sub sqrt {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $num->sqrt();
    }

    sub range_sum {
        my ($self, $from, $to, $step) = @_;

        $self->_is_number($from) || return;
        $self->_is_number($to)   || return;

        defined($step) ? $self->_is_number($step) ? () : return : do {
            $step = Sidef::Types::Number::Number->new(1);
        };

        Sidef::Types::Number::Number->new(($$from + $$to) * (($$to - $$from) / $$step + 1) / 2);
    }

    *rangeSum = \&range_sum;

    sub map {
        my ($self, $amount, $from, $to) = @_;

        $self->_is_number($amount) || return;
        $self->_is_number($from)   || return;
        $self->_is_number($to)     || return;

        my $step  = ($$to - $$from) / $$amount;
        my $array = Sidef::Types::Array::Array->new();

        return $array if $step == 0;

        for (my $i = $$from ; $i < $$to ; $i += $step) {
            $array->push(Sidef::Types::Number::Number->new($i));
        }

        $array;
    }

};

1
