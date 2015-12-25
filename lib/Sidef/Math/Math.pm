package Sidef::Math::Math {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    sub new {
        bless {}, __PACKAGE__;
    }

    sub get_constant {
        my ($self, $name) = @_;

        state %cache;
        state $table = {
                        e   => sub { Sidef::Types::Number::Number->e },
                        pi  => sub { Sidef::Types::Number::Number->pi },
                        phi => sub { Sidef::Types::Number::Number->phi },
                       };

        my $key = lc($name);
        $cache{$key} //= exists($table->{$key}) ? $table->{$key}->() : do {
            warn qq{[WARN] Inexistent Math constant "$name"!\n};
            undef;
        };
    }

    sub gcd {
        my ($self, @list) = @_;

        my $gcd = $list[0];
        foreach my $i (1 .. $#list) {
            last if ($gcd->is_one);
            $gcd = $gcd->gcd($list[$i]);
        }

        $gcd;
    }

    sub lcm {
        my ($self, @list) = @_;

        my $lcm = $list[0];
        foreach my $i (1 .. $#list) {
            $lcm = $lcm->lcm($list[$i]);
        }

        $lcm;
    }

    # TODO: make it work!
    sub rand {
        my ($self, $from, $to) = @_;

        if (defined($from) and not defined($to)) {
            $to   = $from->get_value;
            $from = 0;
        }
        else {
            $from = defined($from) ? $from->get_value : 0;
            $to   = defined($to)   ? $to->get_value   : 1;
        }

        Sidef::Types::Number::Number->new($from + CORE::rand($to - $from));
    }

    sub sum {
        my ($self, @list) = @_;

        my $sum = Sidef::Types::Number::Number::_new_int(0);
        foreach my $n (@list) {
            $sum = $sum->add($n);
        }

        $sum;
    }

    sub max {
        my ($self, @list) = @_;

        my $max = $list[0];
        foreach my $i (1 .. $#list) {
            $max = $max->max($list[$i]);
        }

        $max;
    }

    sub min {
        my ($self, @list) = @_;

        my $min = $list[0];
        foreach my $i (1 .. $#list) {
            $min = $min->min($list[$i]);
        }

        $min;
    }

    sub avg {
        my ($self, @list) = @_;

        my $sum = Sidef::Types::Number::Number::_new_int(0);
        foreach my $n (@list) {
            $sum = $sum->add($n);
        }

        my $n = Sidef::Types::Number::Number->new(scalar(@list));
        $sum->div($n);
    }

    sub range_sum {
        my ($self, $from, $to, $step) = @_;

        $from = $from->get_value;
        $to   = $to->get_value;
        $step = defined($step) ? $step->get_value : 1;

        Sidef::Types::Number::Number->new(($from + $to) * (($to - $from) / $step + 1) / 2);
    }

    sub map {
        my ($self, $value, $in_min, $in_max, $out_min, $out_max) = @_;

        $value = $value->get_value;

        $in_min = $in_min->get_value;
        $in_max = $in_max->get_value;

        $out_min = $out_min->get_value;
        $out_max = $out_max->get_value;

        Sidef::Types::Number::Number->new(($value - $in_min) * ($out_max - $out_min) / ($in_max - $in_min) + $out_min);
    }

    sub map_range {
        my ($self, $amount, $from, $to) = @_;

        $amount = $amount->get_value;
        $from   = $from->get_value;
        $to     = $to->get_value;

        Sidef::Types::Range::RangeNumber->__new__(
                                                  from => $from,
                                                  to   => $to,
                                                  step => ($to - $from) / $amount,
                                                 );
    }

    sub number_to_percentage {
        my ($self, $num, $from, $to) = @_;

        $num  = $num->get_value;
        $to   = $to->get_value;
        $from = $from->get_value;

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
            'asin',
            'acos',
            'atan',

            # The principal value of the arc tangent of y/x
            'atan2',

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
                state $x = require Math::Trig;
                local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                my $result = (\&{'Math::Trig::' . $f})->(map { $_->get_value } @rest);
                (
                 ref($result) eq 'Math::Complex'
                 ? 'Sidef::Types::Number::Complex'
                 : 'Sidef::Types::Number::Number'
                )->new($result);
            };
        }
    }

    our $AUTOLOAD;

    sub AUTOLOAD {
        my ($self, $x, @args) = @_;
        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);
        defined($x) ? $x->$method(@args) : do {
            state $one = Sidef::Types::Number::Number->new(1);
            $one->$method;
        };
    }

};

1
