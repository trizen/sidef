package Sidef::Types::Number::Nan {

    use 5.014;
    use Math::GMPq qw();

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => sub { 1 },
      q{0+}   => sub { 'NaN' },
      q{""}   => sub { 'NaN' };

    state $NAN = do {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_si($r, "-0", "-0");
        bless \$r, __PACKAGE__;
    };

    sub new { $NAN }

    sub get_value { 'NaN' }

    sub is_nan {
        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub nan { $_[0] }

    *abs         = \&nan;
    *add         = \&nan;
    *iadd        = \&nan;
    *sub         = \&nan;
    *isub        = \&nan;
    *sqrt        = \&nan;
    *isqrt       = \&nan;
    *mul         = \&nan;
    *imul        = \&nan;
    *div         = \&nan;
    *idiv        = \&nan;
    *mod         = \&nan;
    *imod        = \&nan;
    *pow         = \&nan;
    *ipow        = \&nan;
    *iroot       = \&nan;
    *root        = \&nan;
    *and         = \&nan;
    *or          = \&nan;
    *xor         = \&nan;
    *inc         = \&nan;
    *dec         = \&nan;
    *neg         = \&nan;
    *pos         = \&nan;
    *shift_left  = \&nan;
    *shift_right = \&nan;
    *factorial   = \&nan;
    *not         = \&nan;
    *idiv        = \&nan;
    *gamma       = \&nan;
    *digamma     = \&nan;
    *zeta        = \&nan;
    *log         = \&nan;
    *log2        = \&nan;
    *log10       = \&nan;
    *mod         = \&nan;
    *fmod        = \&nan;
    *ln          = \&nan;
    *exp         = \&nan;
    *exp2        = \&nan;
    *exp10       = \&nan;
    *sin         = \&nan;
    *asin        = \&nan;
    *sinh        = \&nan;
    *asinh       = \&nan;
    *cos         = \&nan;
    *acos        = \&nan;
    *cosh        = \&nan;
    *acosh       = \&nan;
    *tan         = \&nan;
    *atan        = \&nan;
    *tanh        = \&nan;
    *atanh       = \&nan;
    *sec         = \&nan;
    *asec        = \&nan;
    *sech        = \&nan;
    *asech       = \&nan;
    *csc         = \&nan;
    *acsc        = \&nan;
    *csch        = \&nan;
    *acsch       = \&nan;
    *cot         = \&nan;
    *acot        = \&nan;
    *coth        = \&nan;
    *acoth       = \&nan;
    *atan2       = \&nan;
    *agm         = \&nan;
    *hypot       = \&nan;
    *erf         = \&nan;
    *erfc        = \&nan;
    *eint        = \&nan;
    *li2         = \&nan;
    *max         = \&nan;
    *min         = \&nan;
    *int         = \&nan;
    *as_int      = \&nan;
    *float       = \&nan;
    *as_float    = \&nan;
    *sqr         = \&nan;
    *next_pow    = \&nan;
    *next_pow2   = \&nan;
    *next_prime  = \&nan;
    *primorial   = \&nan;
    *lcm         = \&nan;
    *gcd         = \&nan;
    *lucas       = \&nan;
    *fib         = \&nan;
    *binomial    = \&nan;
    *legendre    = \&nan;
    *jacobi      = \&nan;
    *kronecker   = \&nan;
    *rand_int    = \&nan;
    *rand        = \&nan;
    *rand        = \&nan;
    *rad2deg     = \&nan;
    *rad2grad    = \&nan;
    *deg2grad    = \&nan;
    *deg2rad     = \&nan;
    *grad2rad    = \&nan;
    *grad2deg    = \&nan;
    *round       = \&nan;
    *roundf      = \&nan;

    sub cmp { }

    *acmp = \&cmp;
    *sign = \&cmp;

    sub eq {
        my ($x, $y) = @_;
        ref($y) eq ref($x) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_inf {
        Sidef::Types::Bool::Bool::FALSE;
    }

    *le          = \&is_inf;
    *lt          = \&is_inf;
    *gt          = \&is_inf;
    *ge          = \&is_inf;
    *is_div      = \&is_inf;
    *ne          = \&is_inf;
    *is_zero     = \&is_inf;
    *is_one      = \&is_inf;
    *is_mone     = \&is_inf;
    *is_ninf     = \&is_inf;
    *is_positive = \&is_inf;
    *is_negative = \&is_inf;
    *is_pos      = \&is_inf;
    *is_neg      = \&is_inf;
    *is_real     = \&is_inf;
    *is_even     = \&is_inf;
    *is_odd      = \&is_inf;
    *divides     = \&is_inf;
    *is_square   = \&is_inf;
    *is_sqr      = \&is_inf;

    sub complex {
        my ($x, $y) = @_;
        if (defined $y) {
            Sidef::Types::Number::Complex->new($x, $y);
        }
        else {
            Sidef::Types::Number::Complex->new($x);
        }
    }

    *c = \&complex;

    sub i {
        my ($x) = @_;
        Sidef::Types::Number::Complex->new(0, $x);
    }

    sub dump {
        Sidef::Types::String::String->new('NaN');
    }

    *commify = \&dump;

    sub chr {
        Sidef::Types::String::String->new('');
    }

    sub numerator {
        Sidef::Types::Number::Number::ZERO;
    }

    *nu = \&numerator;

    sub denominator {
        Sidef::Types::Number::Number::ZERO;
    }

    *de = \&denominator;

    sub parts {
        (Sidef::Types::Number::Number::ZERO, Sidef::Types::Number::Number::ZERO);
    }

    *nude = \&parts;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '%'}   = \&mod;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'} = \&le;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'} = \&ge;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'} = \&ne;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
        *{__PACKAGE__ . '::' . '%%'}  = \&is_div;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
        *{__PACKAGE__ . '::' . ':'}   = \&complex;
        *{__PACKAGE__ . '::' . '//'}  = \&idiv;
        *{__PACKAGE__ . '::' . 'Γ'}  = \&gamma;
        *{__PACKAGE__ . '::' . 'Ψ'}  = \&digamma;
    }
}

1
