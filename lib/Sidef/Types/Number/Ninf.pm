package Sidef::Types::Number::Ninf {

    use 5.014;
    require Math::GMPq;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      Sidef::Types::Number::Number
      );

    use overload
      q{bool} => sub { 1 },
      q{0+}   => sub { -'inf' },
      q{""}   => sub { '-Inf' };

    state $NINF = do {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_si($r, -1, 0);
        bless \$r, __PACKAGE__;
    };

    state $ZERO = $Sidef::Types::Number::Number::ZERO;
    state $ONE  = $Sidef::Types::Number::Number::ONE;
    state $MONE = $Sidef::Types::Number::Number::MONE;

    if (not defined $ZERO or not defined $ONE or not defined $MONE) {
        die "Fatal error: can't load the Ninf class!";
    }

    sub new { $NINF }

    sub get_value { -'Inf' }

    sub add {
        my ($x, $y) = @_;
        ref($y) eq 'Sidef::Types::Number::Inf' ? nan() : $x;
    }

    sub sub {
        my ($x, $y) = @_;
        ref($y) eq __PACKAGE__ ? nan() : $x;
    }

    sub mul {
        my ($x, $y) = @_;
        ref($y) eq __PACKAGE__ and return $x->neg;
        $y->is_neg ? $x->neg : $x;
    }

    sub div {
        my ($x, $y) = @_;
        if (ref($y) eq __PACKAGE__ or ref($y) eq 'Sidef::Types::Number::Ninf') {
            return nan();
        }
        $y->is_neg ? $x->neg : $x;
    }

    sub is_pos {
        state $x = Sidef::Types::Bool::Bool->false;
    }

    sub is_neg {
        state $x = Sidef::Types::Bool::Bool->true;
    }

    sub nan { state $x = Sidef::Types::Number::Nan->new }

    *gamma   = \&nan;
    *lgamma  = \&nan;
    *digamma = \&nan;
    *zeta    = \&nan;
    *fmod    = \&nan;
    *mod     = \&nan;

    sub inf { state $x = Sidef::Types::Number::Inf->new }

    *neg   = \&inf;
    *abs   = \&inf;
    *log   = \&inf;
    *cosh  = \&inf;
    *acosh = \&inf;
    *tan   = \&inf;
    *sec   = \&inf;
    *csc   = \&inf;
    *cot   = \&inf;
    *hypot = \&inf;

    sub ninf { $_[0] }

    *min   = \&ninf;
    *sinh  = \&ninf;
    *asinh = \&ninf;
    *li2   = \&ninf;
    *inc   = \&ninf;
    *dec   = \&ninf;

    sub max { $_[1] }

    sub zero { $ZERO }

    *inv   = \&zero;
    *sin   = \&zero;
    *exp   = \&zero;
    *cos   = \&zero;
    *sech  = \&zero;
    *csch  = \&zero;
    *eint  = \&zero;
    *exp   = \&zero;
    *exp2  = \&zero;
    *exp10 = \&inf;

    #
    ## erfc(-inf) = 2
    #

    sub erfc { state $x = Sidef::Types::Number::Number->new(2) }

    #
    ## asin(-inf) = inf*i
    #
    sub asin { state $x = Sidef::Types::Number::Complex->new(0, '@inf@') }

    *sqrt = \&asin;

    #
    ## acos(-inf) = -inf*i
    #
    sub acos { state $x = Sidef::Types::Number::Complex->new(0, '-@inf@') }

    #
    ## atan(-inf) = -pi/2
    #
    sub atan {
        state $x = Sidef::Types::Number::Number->pi->div(Sidef::Types::Number::Number->new(-2));
    }

    #
    ## atanh(-inf) = pi/2*i
    #
    sub atanh {
        state $x = Sidef::Types::Number::Complex->new(
                                                      0,
                                                      Sidef::Types::Number::Number->pi->div(
                                                                                           Sidef::Types::Number::Number->new(2)
                                                      )
                                                     );
    }

    #
    ## tanh(-inf) = -1
    #
    sub tanh { $MONE }

    *coth = \&tanh;
    *erf  = \&tanh;

    #
    ## -inf.times {} does no-op
    #
    sub times { $_[1] }

    #
    ## (-inf)^even = inf
    #
    sub pow {
        my ($x, $y) = @_;
        $y->is_neg ? $ZERO : $y->is_zero ? nan() : $y->is_even ? $x->neg : $x;
    }

    #
    ## Comparisons
    #

    sub eq {
        my ($x, $y) = @_;
        if (ref($y) eq __PACKAGE__) {
            state $z = Sidef::Types::Bool::Bool->true;
        }
        else {
            state $z = Sidef::Types::Bool::Bool->false;
        }
    }

    sub ne {
        my ($x, $y) = @_;
        if (ref($y) eq __PACKAGE__) {
            state $z = Sidef::Types::Bool::Bool->false;
        }
        else {
            state $z = Sidef::Types::Bool::Bool->true;
        }
    }

    sub gt {
        state $z = Sidef::Types::Bool::Bool->false;
    }

    sub ge {
        my ($x, $y) = @_;
        if (ref($y) eq __PACKAGE__) {
            state $z = Sidef::Types::Bool::Bool->true;
        }
        else {
            state $z = Sidef::Types::Bool::Bool->false;
        }
    }

    sub lt {
        my ($x, $y) = @_;
        if (ref($y) eq __PACKAGE__) {
            state $z = Sidef::Types::Bool::Bool->false;
        }
        else {
            state $z = Sidef::Types::Bool::Bool->true;
        }
    }

    sub le {
        state $z = Sidef::Types::Bool::Bool->true;
    }

    sub cmp {
        my ($x, $y) = @_;
        ref($y) eq __PACKAGE__ ? $ZERO : $MONE;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '%'}   = \&mod;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
    }
}

1
