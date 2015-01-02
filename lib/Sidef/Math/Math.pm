package Sidef::Math::Math {

    use 5.014;
    our @ISA = qw(Sidef);

    sub new {
        require Math::BigFloat;
        bless {}, __PACKAGE__;
    }

    sub e {
        my ($self, $places) = @_;
        Sidef::Types::Number::Number->new(
                            Math::BigFloat->bexp(1, defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    sub exp {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        Sidef::Types::Number::Number->new(
                     Math::BigFloat->new($$x)->bexp(defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
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

    sub asin {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        $self->atan2(
                     $x,
                     $self->sqrt(
                           Sidef::Types::Number::Number->new(1)->subtract($self->pow($x, Sidef::Types::Number::Number->new(2)))
                     ),
                     $places
                    );
    }

    sub log {
        my ($self, $n, $base) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(
                           Math::BigFloat->new($$n)->blog(defined($base) ? ($self->_is_number($base)) ? $$base : return : ()));
    }

    sub log2 {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->blog(2));
    }

    sub log10 {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->blog(10));
    }

    sub npow2 {
        my ($self, $x) = @_;

        $self->_is_number($x) || return;
        $x = Math::BigFloat->new($$x);

        my $y = Math::BigFloat->new(2);
        Sidef::Types::Number::Number->new($y->blsft($x->blog($y)->as_int));
    }

    sub npow {
        my ($self, $x, $y) = @_;
        $self->_is_number($x) || return;
        $self->_is_number($y) || return;

        $x = Math::BigFloat->new($$x);
        $y = Math::BigFloat->new($$y);

        Sidef::Types::Number::Number->new($y->bpow($x->blog($y)->as_int->binc));
    }

    sub gcd {
        my ($self, @list) = @_;
        $self->_is_number($_) || return for @list;
        Sidef::Types::Number::Number->new(Math::BigFloat::bgcd(map { $$_ } @list));
    }

    sub abs {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->babs);
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

    sub ceil {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->bceil);
    }

    sub floor {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->bfloor);
    }

    sub sqrt {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->bsqrt);
    }

    sub pow {
        my ($self, $n, $pow) = @_;
        $self->_is_number($n)   || return;
        $self->_is_number($pow) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->bpow($$pow));
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

    sub number_to_percentage {
        my ($self, $num, $from, $to) = @_;

        $self->_is_number($num)  || return;
        $self->_is_number($from) || return;
        $self->_is_number($to)   || return;

        $num  = $$num;
        $to   = $$to;
        $from = $$from;

        my $sum  = CORE::abs($to - $from);
        my $dist = CORE::abs($num - $to);

        Sidef::Types::Number::Number->new(($sum - $dist) / $sum * 100);
    }

    *num2percent = \&number_to_percentage;

    {
        no strict 'refs';
        foreach my $f (

            # (Plane, 2-dimensional) angles may be converted with the following functions.
            'rad2rad',
            'deg2deg',
            'grad2grad',
            'rad2deg',
            'deg2rad',
            'grad2deg',
            'deg2grad',
            'rad2grad',
            'grad2rad',

            # The tangent
            'tan',

            # The cofunctions of the sine, cosine,
            # and tangent (cosec/csc and cotan/cot are aliases)
            'csc',
            'cosec',
            'sec',
            'cot',
            'cotan',

            # The arcus (also known as the inverse) functions
            # of the sine, cosine, and tangent
            ##'asin',
            'acos',
            ##'atan',

            # The principal value of the arc tangent of y/x
            ##'atan2',

            #  The arcus cofunctions of the sine, cosine, and tangent (acosec/acsc and
            # acotan/acot are aliases).  Note that atan2(0, 0) is not well-defined.
            'acsc',
            'acosec',
            'asec',
            'acot',
            'acotan',

            # The hyperbolic sine, cosine, and tangent
            'sinh',
            'cosh',
            'tanh',

            # The cofunctions of the hyperbolic sine, cosine, and tangent
            # (cosech/csch and cotanh/coth are aliases)
            'csch',
            'cosech',
            'sech',
            'coth',
            'cotanh',

            # The area (also known as the inverse) functions of the hyperbolic sine,
            # cosine, and tangent
            'asinh',
            'acosh',
            'atanh',

            # The area cofunctions of the hyperbolic sine, cosine, and tangent
            # (acsch/acosech and acoth/acotanh are aliases)
            'acsch',
            'acosech',
            'asech',
            'acoth',
            'acotanh',

          ) {
            *{__PACKAGE__ . '::' . $f} = sub {
                my ($self, @rest) = @_;
                require Math::Trig;
                my $func = \&{'Math::Trig::' . $f};
                Sidef::Types::Number::Number->new($func->(map { $_->get_value } @rest));
            };
        }
    }

};

1
