package Sidef::Types::Number::Inf {

    use utf8;
    use 5.014;
    require Math::GMPq;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      Sidef::Types::Number::Number
      );

    use overload
      q{bool} => sub { 1 },
      q{0+}   => sub { 'inf' },
      q{""}   => sub { 'Inf' };

    state $INF = do {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($r, 1, 0);
        bless \$r, __PACKAGE__;
    };

    state $ZERO = $Sidef::Types::Number::Number::ZERO;
    state $ONE  = $Sidef::Types::Number::Number::ONE;
    state $MONE = $Sidef::Types::Number::Number::MONE;

    if (not defined $ZERO or not defined $ONE or not defined $MONE) {
        die "Fatal error: can't load the Inf class!";
    }

    sub new { $INF }

    sub get_value { 'Inf' }

    sub add {
        my ($x, $y) = @_;
        ref($y) eq 'Sidef::Types::Number::Ninf' ? nan() : $x;
    }

    *iadd = \&add;

    sub sub {
        my ($x, $y) = @_;
        ref($y) eq __PACKAGE__ ? nan() : $x;
    }

    *isub = \&sub;

    sub mul {
        my ($x, $y) = @_;
        ref($y) eq __PACKAGE__ and return $x;
        $y->is_neg ? $x->neg : $x;
    }

    *imul = \&mul;

    sub div {
        my ($x, $y) = @_;
        if (ref($y) eq __PACKAGE__ or ref($y) eq 'Sidef::Types::Number::Ninf') {
            return nan();
        }
        $y->is_neg ? $x->neg : $x;
    }

    *idiv = \&div;

    sub is_pos {
        state $x = Sidef::Types::Bool::Bool->true;
    }

    sub is_inf {
        state $x = Sidef::Types::Bool::Bool->true;
    }

    sub is_ninf {
        state $x = Sidef::Types::Bool::Bool->false;
    }

    *is_nan    = \&is_ninf;
    *is_neg    = \&is_ninf;
    *is_prime  = \&is_ninf;
    *is_square = \&is_ninf;
    *is_sqr    = \&is_ninf;
    *is_power  = \&is_ninf;
    *is_pow    = \&is_ninf;
    *is_div    = \&is_ninf;
    *is_even   = \&is_ninf;
    *is_odd    = \&is_ninf;

    sub nan {
        state $x = Sidef::Types::Number::Nan->new;
    }

    *mod         = \&nan;
    *fmod        = \&nan;
    *bin         = \&nan;
    *modpow      = \&nan;
    *expmod      = \&nan;
    *modinv      = \&nan;
    *invmod      = \&nan;
    *and         = \&nan;
    *or          = \&nan;
    *xor         = \&nan;
    *legendre    = \&nan;
    *jacobi      = \&nan;
    *kronecker   = \&nan;
    *gcd         = \&nan;
    *lcm         = \&nan;
    *next_power2 = \&nan;
    *next_pow2   = \&nan;
    *next_pow    = \&nan;
    *next_power  = \&nan;

    sub as_bin {
        state $x = Sidef::Types::String::String->new;
    }

    *as_oct = \&as_bin;
    *as_hex = \&as_bin;

    sub digits {
        Sidef::Types::Array::Array->new;
    }

    sub divmod {
        my ($x, $y) = @_;
        ($x->div($y), nan());
    }

    sub ninf {
        state $x = Sidef::Types::Number::Ninf->new;
    }

    *neg = \&ninf;
    *not = \&ninf;

    sub min { $_[1] }
    sub inf { $_[0] }

    *max              = \&inf;
    *abs              = \&inf;
    *sqrt             = \&inf;
    *cbrt             = \&inf;
    *root             = \&inf;
    *sqr              = \&inf;
    *log              = \&inf;
    *log2             = \&inf;
    *log10            = \&inf;
    *exp              = \&inf;
    *exp2             = \&inf;
    *exp10            = \&inf;
    *sinh             = \&inf;
    *asinh            = \&inf;
    *cosh             = \&inf;
    *acosh            = \&inf;
    *tan              = \&inf;
    *sec              = \&inf;
    *csc              = \&inf;
    *cot              = \&inf;
    *hypot            = \&inf;
    *gamma            = \&inf;
    *lgamma           = \&inf;
    *digamma          = \&inf;
    *lngamma          = \&inf;
    *eint             = \&inf;
    *li2              = \&inf;
    *inc              = \&inf;
    *dec              = \&inf;
    *int              = \&inf;
    *as_int           = \&inf;
    *float            = \&inf;
    *as_float         = \&inf;
    *rat              = \&inf;
    *length           = \&inf;
    *len              = \&inf;
    *size             = \&inf;
    *floor            = \&inf;
    *ceil             = \&inf;
    *factorial        = \&inf;
    *fac              = \&inf;
    *double_factorial = \&inf;
    *dfac             = \&inf;
    *primorial        = \&inf;
    *fibonacci        = \&inf;
    *lucas            = \&inf;
    *shift_left       = \&inf;
    *shift_right      = \&inf;
    *rand_int         = \&inf;
    *rand             = \&inf;
    *rad2deg          = \&inf;
    *rad2grad         = \&inf;
    *deg2grad         = \&inf;
    *deg2rad          = \&inf;
    *grad2rad         = \&inf;
    *grad2deg         = \&inf;

    sub zero { $ZERO }

    *inv  = \&zero;
    *sin  = \&zero;
    *cos  = \&zero;
    *sech = \&zero;
    *csch = \&zero;
    *erfc = \&zero;

    sub tanh { $ONE }

    *coth = \&tanh;
    *zeta = \&tanh;
    *erf  = \&tanh;

    sub chr { state $x = Sidef::Types::String::String->new('') }

    #
    ## asin(inf) = -inf*i
    #
    sub asin { state $x = Sidef::Types::Number::Complex->new(0, '-@inf@') }

    #
    ## acos(inf) = inf*i
    #
    sub acos { state $x = Sidef::Types::Number::Complex->new(0, '@inf@') }

    #
    ## atan(inf) = pi/2
    #
    sub atan {
        state $x = Sidef::Types::Number::Number->pi->div(Sidef::Types::Number::Number->new(2));
    }

    *atan2 = \&atan;

    #
    ## atanh(-inf) = -pi/2*i
    #
    sub atanh {
        state $x = Sidef::Types::Number::Complex->new(
                                                      0,
                                                      Sidef::Types::Number::Number->pi->div(
                                                                                          Sidef::Types::Number::Number->new(-2)
                                                      )
                                                     );
    }

    sub times {
        my ($x, $block) = @_;

        my $i = 0;
        while (1) {
            if (defined(my $res = $block->_run_code(Sidef::Types::Number::Number::_new_uint(++$i)))) {
                return $res;
            }
        }

        $block;
    }

    sub pow {
        my ($x, $y) = @_;
        $y->is_neg ? $ZERO : $y->is_zero ? $ONE : $x;
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
        my ($x, $y) = @_;
        if (ref($y) eq __PACKAGE__) {
            state $z = Sidef::Types::Bool::Bool->false;
        }
        else {
            state $z = Sidef::Types::Bool::Bool->true;
        }
    }

    sub ge {
        state $z = Sidef::Types::Bool::Bool->true;
    }

    sub lt {
        state $z = Sidef::Types::Bool::Bool->false;
    }

    sub le {
        my ($x, $y) = @_;
        if (ref($y) eq __PACKAGE__) {
            state $z = Sidef::Types::Bool::Bool->true;
        }
        else {
            state $z = Sidef::Types::Bool::Bool->false;
        }
    }

    sub cmp {
        my ($x, $y) = @_;
        ref($y) eq __PACKAGE__ ? $ZERO : $ONE;
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
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '//'}  = \&div;
        *{__PACKAGE__ . '::' . 'Γ'}  = \&inf;
        *{__PACKAGE__ . '::' . 'Ψ'}  = \&inf;
    }
}

1
