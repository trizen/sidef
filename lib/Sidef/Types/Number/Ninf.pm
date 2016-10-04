package Sidef::Types::Number::Ninf {

    use utf8;
    use 5.014;

    use parent qw(
      Sidef::Types::Number::Inf
      );

    use overload
      q{bool} => sub { 1 },
      q{0+}   => sub { -'inf' },
      q{""}   => sub { '-Inf' };

    my $NINF = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_si($NINF, -1, 0);

    use constant NINF => bless(\$NINF, __PACKAGE__);

    sub new { NINF }

    sub get_value { -'Inf' }

    sub add {
        my ($x, $y) = @_;
        ref($y) eq 'Sidef::Types::Number::Inf' ? Sidef::Types::Number::Nan::NAN : $x;
    }

    *iadd = \&add;
    *fadd = \&add;

    sub sub {
        my ($x, $y) = @_;
        ref($y) eq __PACKAGE__ ? Sidef::Types::Number::Nan::NAN : $x;
    }

    *isub = \&sub;
    *fsub = \&sub;

    sub mul {
        my ($x, $y) = @_;
        ref($y) eq __PACKAGE__ and return $x->neg;
        $y->is_neg ? $x->neg : $y->is_pos ? $x : Sidef::Types::Number::Nan::NAN;
    }

    *imul = \&mul;
    *fmul = \&mul;

    sub div {
        my ($x, $y) = @_;
        if (ref($y) eq __PACKAGE__ or ref($y) eq 'Sidef::Types::Number::Ninf') {
            return Sidef::Types::Number::Nan::NAN;
        }
        $y->is_neg ? $x->neg : $x;
    }

    *idiv = \&div;
    *fdiv = \&div;

    sub is_pos { Sidef::Types::Bool::Bool::FALSE }

    *is_nan    = \&is_pos;
    *is_prime  = \&is_pos;
    *is_square = \&is_pos;
    *is_sqr    = \&is_pos;
    *is_power  = \&is_pos;
    *is_pow    = \&is_pos;
    *is_div    = \&is_pos;
    *is_even   = \&is_pos;
    *is_odd    = \&is_pos;
    *divides   = \&is_pos;
    *is_real   = \&is_pos;
    *is_zero   = \&is_pos;
    *is_one    = \&is_pos;
    *is_mone   = \&is_pos;

    sub is_neg { Sidef::Types::Bool::Bool::TRUE }

    *is_inf  = \&is_neg;
    *is_ninf = \&is_neg;

    sub nan { Sidef::Types::Number::Nan::NAN }

    *gamma            = \&nan;
    *lgamma           = \&nan;
    *digamma          = \&nan;
    *lngamma          = \&nan;
    *zeta             = \&nan;
    *fmod             = \&nan;
    *mod              = \&nan;
    *imod             = \&nan;
    *bin              = \&nan;
    *modpow           = \&nan;
    *expmod           = \&nan;
    *powmod           = \&nan;
    *modinv           = \&nan;
    *invmod           = \&nan;
    *and              = \&nan;
    *or               = \&nan;
    *xor              = \&nan;
    *factorial        = \&nan;
    *fac              = \&nan;
    *double_factorial = \&nan;
    *dfac             = \&nan;
    *primorial        = \&nan;
    *fibonacci        = \&nan;
    *legendre         = \&nan;
    *jacobi           = \&nan;
    *kronecker        = \&nan;
    *lucas            = \&nan;
    *gcd              = \&nan;
    *lcm              = \&nan;
    *next_power2      = \&nan;
    *next_pow2        = \&nan;
    *next_pow         = \&nan;
    *next_power       = \&nan;
    *digit            = \&nan;
    *bernreal         = \&nan;
    *popcount         = \&nan;
    *valuation        = \&nan;

    sub inf { Sidef::Types::Number::Inf::INF }

    *neg    = \&inf;
    *abs    = \&inf;
    *log    = \&inf;
    *lgrt   = \&inf;
    *cosh   = \&inf;
    *acosh  = \&inf;
    *tan    = \&inf;
    *sec    = \&inf;
    *csc    = \&inf;
    *cot    = \&inf;
    *hypot  = \&inf;
    *length = \&inf;
    *len    = \&inf;
    *size   = \&inf;
    *not    = \&inf;
    *li     = \&inf;

    sub ninf { NINF }

    *min         = \&ninf;
    *sinh        = \&ninf;
    *asinh       = \&ninf;
    *li2         = \&ninf;
    *inc         = \&ninf;
    *dec         = \&ninf;
    *int         = \&ninf;
    *as_int      = \&ninf;
    *float       = \&ninf;
    *as_float    = \&ninf;
    *rat         = \&ninf;
    *floor       = \&ninf;
    *ceil        = \&ninf;
    *shift_left  = \&ninf;
    *shift_right = \&ninf;
    *irand       = \&ninf;
    *rand        = \&ninf;
    *rad2deg     = \&ninf;
    *rad2grad    = \&ninf;
    *deg2grad    = \&ninf;
    *deg2rad     = \&ninf;
    *grad2rad    = \&ninf;
    *grad2deg    = \&ninf;
    *round       = \&ninf;
    *roundf      = \&ninf;

    sub max { $_[1] }

    sub zero { Sidef::Types::Number::Number::ZERO }

    *inv = \&zero;

    *sin = \&nan;    # -1 to 1
    *cos = \&nan;    # -1 to 1

    *exp   = \&zero;
    *sech  = \&zero;
    *csch  = \&zero;
    *acsc  = \&zero;
    *acsch = \&zero;
    *eint  = \&zero;
    *ei    = \&zero;
    *exp   = \&zero;
    *exp2  = \&zero;
    *exp10 = \&zero;
    *acot  = \&zero;
    *acoth = \&zero;

    sub chr { state $x = Sidef::Types::String::String->new('') }

    #
    ## erfc(-inf) = 2
    #

    sub erfc { state $x = Sidef::Types::Number::Number->new(2) }

    #
    ## asin(-inf) = inf*i
    #
    sub asin { state $x = Sidef::Types::Number::Complex->new(0, '@inf@') }

    #
    ## sqrt(-inf) = (-inf)^(1/2) == inf*i
    #
    *isqrt = \&inf;    # not quite right
    *sqrt  = \&inf;    # =//=

    #
    ## (-inf)^2 = inf
    #
    *sqr = \&inf;

    #
    ## (-inf)^(1/x) = i^(1/x) * inf
    #
    sub root {
        my ($x, $y) = @_;

        ref($y) eq 'Sidef::Types::Number::Nan' ? $y
          : (   ref($y) eq 'Sidef::Types::Number::Inf'
             || ref($y) eq 'Sidef::Types::Number::Ninf') ? Sidef::Types::Number::Number::ONE
          : $y->is_neg ? Sidef::Types::Number::Number::ZERO
          : $y->is_one ? $x
          :              Sidef::Types::Number::Inf::INF;
    }

    *iroot = \&root;

    #
    ## acos(-inf) = -inf*i
    #
    sub acos { state $x = Sidef::Types::Number::Complex->new(0, '-@inf@') }

    #
    ## atan(-inf) = -pi/2
    #
    sub atan {
        state $neg_two = Sidef::Types::Number::Number->new(-2);
        Sidef::Types::Number::Number->pi->div($neg_two);
    }

    *atan2 = \&atan;

    #
    ## asec(-inf) = pi/2
    #
    sub asec {
        state $two = Sidef::Types::Number::Number->new(2);
        Sidef::Types::Number::Number->pi->div($two);
    }

    #
    ## atanh(-inf) = pi/2*i
    #
    sub atanh {
        state $two = Sidef::Types::Number::Number->new(2);
        Sidef::Types::Number::Number->pi->div($two)->i;
    }

    *asech = \&atanh;

    #
    ## tanh(-inf) = -1
    #
    sub tanh { (Sidef::Types::Number::Number::MONE) }

    *coth = \&tanh;
    *erf  = \&tanh;
    *sign = \&tanh;

    #
    ## -inf.times {} is a no-op
    #
    sub times { $_[1] }

    *itimes = \&times;

    #
    ## (-inf)^even = inf
    #
    sub pow {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Inf' or ref($y) eq 'Sidef::Types::Number::Nan') {
            return $y;
        }

            $y->is_neg  ? (Sidef::Types::Number::Number::ZERO)
          : $y->is_zero ? (Sidef::Types::Number::Number::ONE)
          : $y->is_odd  ? $x
          :               $x->neg;
    }

    *fpow = \&pow;

    sub ipow {
        $_[0]->pow($_[1]->int);
    }

    #
    ## binomial(-inf, x) = 0        | with x < 0
    ## binomial(-inf, 0) = 1
    ## binomial(-inf, inf) = 1
    ## binomial(-inf, x) = -inf     | with x > 0
    ##
    #
    sub binomial {
        my ($x, $y) = @_;
        ref($y) eq 'Sidef::Types::Number::Inf' ? (Sidef::Types::Number::Number::ONE)
          : $y->is_neg                         ? (Sidef::Types::Number::Number::ZERO)
          : $y->is_zero                        ? (Sidef::Types::Number::Number::ONE)
          :                                      $x;
    }

    *nok = \&binomial;

    #
    ## Comparisons
    #

    sub eq {
        if (ref($_[1]) eq __PACKAGE__) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub ne {
        if (ref($_[1]) eq __PACKAGE__) {
            (Sidef::Types::Bool::Bool::FALSE);
        }
        else {
            (Sidef::Types::Bool::Bool::TRUE);
        }
    }

    sub gt {
        (Sidef::Types::Bool::Bool::FALSE);
    }

    sub ge {
        if (ref($_[1]) eq __PACKAGE__) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub lt {
        if (ref($_[1]) eq __PACKAGE__) {
            (Sidef::Types::Bool::Bool::FALSE);
        }
        else {
            (Sidef::Types::Bool::Bool::TRUE);
        }
    }

    sub le {
        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub cmp {
        ref($_[1]) eq __PACKAGE__
          ? Sidef::Types::Number::Number::ZERO
          : Sidef::Types::Number::Number::MONE;
    }

    sub i {
        state $x = Sidef::Types::Number::Complex->new(0, NINF);
    }

    sub dump {
        state $x = Sidef::Types::String::String->new('-Inf');
    }

    *commify = \&dump;

    sub of {
        Sidef::Types::Array::Array->new();
    }

    *defs = \&of;

    sub numerator {
        Sidef::Types::Number::Number::MONE;
    }

    *nu = \&numerator;

    sub denominator {
        Sidef::Types::Number::Number::ZERO;
    }

    *de = \&denominator;

    sub parts {
        (Sidef::Types::Number::Number::MONE, Sidef::Types::Number::Number::ZERO);
    }

    *nude = \&parts;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '%'}   = \&mod;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'} = \&ne;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'} = \&ge;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'} = \&le;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
        *{__PACKAGE__ . '::' . '%%'}  = \&is_div;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '//'}  = \&div;
        *{__PACKAGE__ . '::' . 'Γ'}  = \&nan;
        *{__PACKAGE__ . '::' . 'Ψ'}  = \&nan;
    }
}

1
