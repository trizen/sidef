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
            e   => sub { Math::BigFloat->new(1)->bexp },
            pi  => sub { Math::BigFloat->bpi },
            phi => sub { Math::BigFloat->new(1)->badd(Math::BigFloat->new(5)->bsqrt)->bdiv(2) },

            sqrt2   => sub { Math::BigFloat->new(2)->bsqrt },
            sqrte   => sub { Math::BigFloat->new(1)->bexp->bsqrt },
            sqrtpi  => sub { Math::BigFloat->bpi->bsqrt },
            sqrtphi => sub { Math::BigFloat->new(1)->badd(Math::BigFloat->new(5)->bsqrt)->bdiv(2)->bsqrt },

            ln2    => sub { Math::BigFloat->new(2)->blog },
            log2e  => sub { Math::BigFloat->new(2)->blog->bpow(-1) },
            ln10   => sub { Math::BigFloat->new(10)->blog },
            log10e => sub { Math::BigFloat->new(10)->blog->bpow(-1) },
                       };

        my $key = lc($name);
        $cache{$key} //= exists($table->{$key}) ? Sidef::Types::Number::Number->new(scalar $table->{$key}->()) : do {
            warn qq{[WARN] Inexistent Math constant "$name"!\n};
            undef;
        };
    }

    sub e {
        my ($self, $places) = @_;
        state $one = Math::BigFloat->new(1);
        Sidef::Types::Number::Number->new($one->copy->bexp(defined($places) ? $places->get_value : ()));
    }

    sub exp {
        my ($self, $x, $places) = @_;
        Sidef::Types::Number::Number->new(
                                         Math::BigFloat->new($x->get_value)->bexp(defined($places) ? $places->get_value : ()));
    }

    sub pi {
        my ($self, $places) = @_;

        $places = defined($places) ? $places->get_value : undef;

        # For large accuracy, the arctan formulas become very inefficient with
        # Math::BigFloat.  Switch to Brent-Salamin (aka AGM or Gauss-Legendre).
        if (defined($places) and $places >= 1000) {

            # Code by Dana Jacobsen from RosettaCode
            # http://rosettacode.org/wiki/Arithmetic-geometric_mean/Calculate_Pi#Perl

            my $acc  = $places + 8;
            my $HALF = Math::BigFloat->new('0.5');

            my $an = Math::BigFloat->bone;
            my $bn = $HALF->copy->bsqrt($acc);
            my $tn = $HALF->copy->bmul($HALF);
            my $pn = Math::BigFloat->bone;

            while ($pn < $acc) {
                my $prev_an = $an->copy;
                $an->badd($bn)->bmul($HALF, $acc);
                $bn->bmul($prev_an)->bsqrt($acc);
                $prev_an->bsub($an);
                $tn->bsub($pn * $prev_an * $prev_an);
                $pn->badd($pn);
            }
            $an->badd($bn);
            $an->bmul($an, $acc)->bdiv($tn->bmul(4), $places);

            return Sidef::Types::Number::Number->new($an);
        }

        Sidef::Types::Number::Number->new(Math::BigFloat->bpi(defined($places) ? $places : ()));
    }

    *PI = \&pi;

    sub cos {
        my ($self, $x, $places) = @_;
        Sidef::Types::Number::Number->new(
                                         Math::BigFloat->new($x->get_value)->bcos(defined($places) ? $places->get_value : ()));
    }

    sub sin {
        my ($self, $x, $places) = @_;
        Sidef::Types::Number::Number->new(
                                         Math::BigFloat->new($x->get_value)->bsin(defined($places) ? $places->get_value : ()));
    }

    sub log {
        my ($self, $n, $base) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->blog(defined($base) ? $base->get_value : ()));
    }

    sub log2 {
        my ($self, $n) = @_;
        state $two = Math::BigFloat->new(2);
        Sidef::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->blog($two));
    }

    sub log10 {
        my ($self, $n) = @_;
        state $ten = Math::BigFloat->new(10);
        Sidef::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->blog($ten));
    }

    sub npow2 {
        my ($self, $x) = @_;
        state $two = Math::BigInt->new(2);
        Sidef::Types::Number::Number->new(scalar $two->copy->blsft(Math::BigFloat->new($x->get_value)->as_int->blog($two)));
    }

    sub npow {
        my ($self, $x, $y) = @_;

        $x = Math::BigFloat->new($x->get_value);
        $y = Math::BigFloat->new($y->get_value);

        Sidef::Types::Number::Number->new(scalar $y->bpow($x->blog($y)->binc->as_int));
    }

    sub gcd {
        my ($self, @list) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat::bgcd(map { $_->get_value } @list));
    }

    sub abs {
        my ($self, $n) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->babs);
    }

    sub lcm {
        my ($self, @list) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat::blcm(map { $_->get_value } @list));
    }

    sub inf {
        Sidef::Types::Number::Number->new(Math::BigFloat->binf);
    }

    sub precision {
        my ($self, $n) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat->precision(defined($n) ? $n->get_value || undef : ()));
    }

    sub accuracy {
        my ($self, $n) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat->accuracy(defined($n) ? $n->get_value || undef : ()));
    }

    sub ceil {
        my ($self, $n) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->bceil);
    }

    sub floor {
        my ($self, $n) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->bfloor);
    }

    sub sqrt {
        my ($self, $n) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->bsqrt);
    }

    sub root {
        my ($self, $n, $m) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->broot($m->get_value));
    }

    sub troot {
        my ($self, $n) = @_;

        state $two   = Math::BigFloat->new(2);
        state $eight = Math::BigFloat->new(8);

        Sidef::Types::Number::Number->new(
                                       scalar Math::BigFloat->new($n->get_value)->bmul($eight)->binc->bsqrt->bdec->bdiv($two));
    }

    sub pow {
        my ($self, $n, $pow) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($n->get_value)->bpow($pow->get_value));
    }

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
        my ($self, @nums) = @_;

        state $x = require List::Util;
        Sidef::Types::Number::Number->new(List::Util::sum(map { $_->get_value } @nums));
    }

    sub max {
        my ($self, @nums) = @_;

        state $x = require List::Util;
        Sidef::Types::Number::Number->new(List::Util::max(map { $_->get_value } @nums));
    }

    sub min {
        my ($self, @nums) = @_;

        state $x = require List::Util;
        Sidef::Types::Number::Number->new(List::Util::min(map { $_->get_value } @nums));
    }

    sub avg {
        my ($self, @nums) = @_;
        Sidef::Types::Number::Number->new($self->sum(@nums)->get_value / @nums);
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

};

1
