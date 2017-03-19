package Sidef::Types::Number::Nan {

    use utf8;
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

    Math::GMPq::Rmpq_set_si((state $NAN = Math::GMPq::Rmpq_init_nobless()), "-0", "-0");

    use constant NAN => bless(\$NAN, __PACKAGE__);

    sub new { NAN }

    sub get_value { 'NaN' }

    sub is_nan { Sidef::Types::Bool::Bool::TRUE }

    sub nan { NAN }

    *abs                 = \&nan;
    *add                 = \&nan;
    *iadd                = \&nan;
    *fadd                = \&nan;
    *sub                 = \&nan;
    *isub                = \&nan;
    *fsub                = \&nan;
    *sqrt                = \&nan;
    *isqrt               = \&nan;
    *mul                 = \&nan;
    *imul                = \&nan;
    *fmul                = \&nan;
    *div                 = \&nan;
    *idiv                = \&nan;
    *fdiv                = \&nan;
    *inv                 = \&nan;
    *pow                 = \&nan;
    *ipow                = \&nan;
    *fpow                = \&nan;
    *root                = \&nan;
    *iroot               = \&nan;
    *and                 = \&nan;
    *or                  = \&nan;
    *xor                 = \&nan;
    *inc                 = \&nan;
    *modpow              = \&nan;
    *powmod              = \&nan;
    *expmod              = \&nan;
    *modinv              = \&nan;
    *invmod              = \&nan;
    *dec                 = \&nan;
    *neg                 = \&nan;
    *pos                 = \&nan;
    *shift_left          = \&nan;
    *shift_right         = \&nan;
    *factorial           = \&nan;
    *fac                 = \&nan;
    *double_factorial    = \&nan;
    *dfac                = \&nan;
    *not                 = \&nan;
    *idiv                = \&nan;
    *gamma               = \&nan;
    *digamma             = \&nan;
    *zeta                = \&nan;
    *eta                 = \&nan;
    *log                 = \&nan;
    *ilog                = \&nan;
    *log2                = \&nan;
    *ilog2               = \&nan;
    *log10               = \&nan;
    *ilog10              = \&nan;
    *lgrt                = \&nan;
    *lambert_w           = \&nan;
    *mod                 = \&nan;
    *imod                = \&nan;
    *fmod                = \&nan;
    *frem                = \&nan;
    *ln                  = \&nan;
    *exp                 = \&nan;
    *exp2                = \&nan;
    *exp10               = \&nan;
    *sin                 = \&nan;
    *asin                = \&nan;
    *sinh                = \&nan;
    *asinh               = \&nan;
    *cos                 = \&nan;
    *acos                = \&nan;
    *cosh                = \&nan;
    *acosh               = \&nan;
    *tan                 = \&nan;
    *atan                = \&nan;
    *tanh                = \&nan;
    *atanh               = \&nan;
    *sec                 = \&nan;
    *asec                = \&nan;
    *sech                = \&nan;
    *asech               = \&nan;
    *csc                 = \&nan;
    *acsc                = \&nan;
    *csch                = \&nan;
    *acsch               = \&nan;
    *cot                 = \&nan;
    *acot                = \&nan;
    *coth                = \&nan;
    *acoth               = \&nan;
    *atan2               = \&nan;
    *agm                 = \&nan;
    *hypot               = \&nan;
    *erf                 = \&nan;
    *erfc                = \&nan;
    *eint                = \&nan;
    *ei                  = \&nan;
    *li2                 = \&nan;
    *li                  = \&nan;
    *max                 = \&nan;
    *min                 = \&nan;
    *int                 = \&nan;
    *trunc               = \&nan;
    *float               = \&nan;
    *sqr                 = \&nan;
    *next_power2         = \&nan;
    *next_pow2           = \&nan;
    *next_pow            = \&nan;
    *next_power          = \&nan;
    *next_prime          = \&nan;
    *prev_prime          = \&nan;
    *primorial           = \&nan;
    *pn_primorial        = \&nan;
    *lcm                 = \&nan;
    *gcd                 = \&nan;
    *lucas               = \&nan;
    *fib                 = \&nan;
    *binomial            = \&nan;
    *legendre            = \&nan;
    *jacobi              = \&nan;
    *kronecker           = \&nan;
    *rand                = \&nan;
    *irand               = \&nan;
    *rad2deg             = \&nan;
    *rad2grad            = \&nan;
    *deg2grad            = \&nan;
    *deg2rad             = \&nan;
    *grad2rad            = \&nan;
    *grad2deg            = \&nan;
    *round               = \&nan;
    *roundf              = \&nan;
    *re                  = \&nan;
    *real                = \&nan;
    *bernreal            = \&nan;
    *bernfrac            = \&nan;
    *bern                = \&nan;
    *bernoulli           = \&nan;
    *popcount            = \&nan;
    *valuation           = \&nan;
    *harm                = \&nan;
    *harmonic            = \&nan;
    *harmfrac            = \&nan;
    *harmreal            = \&nan;
    *mobius              = \&nan;
    *moebius             = \&nan;
    *sigma               = \&nan;
    *sigma0              = \&nan;
    *omega               = \&nan;
    *big_omega           = \&nan;
    *prime_root          = \&nan;
    *prime_power         = \&nan;
    *perfect_root        = \&nan;
    *perfect_power       = \&nan;
    *partitions          = \&nan;
    *totient             = \&nan;
    *euler_phi           = \&nan;
    *euler_totient       = \&nan;
    *jordan_totient      = \&nan;
    *carmichael_lambda   = \&nan;
    *liouville           = \&nan;
    *exp_mangoldt        = \&nan;
    *stirling            = \&nan;
    *stirling2           = \&nan;
    *stirling3           = \&nan;
    *bell                = \&nan;
    *znorder             = \&nan;
    *znprimroot          = \&nan;
    *ramanujan_tau       = \&nan;
    *prime_count         = \&nan;
    *square_free_count   = \&nan;
    *remove              = \&nan;
    *make_coprime        = \&nan;
    *rad                 = \&nan;
    *bessel_j            = \&nan;
    *bessel_y            = \&nan;
    *beta                = \&nan;
    *prime               = \&nan;
    *nth_prime           = \&nan;
    *random_prime        = \&nan;
    *random_nbit_prime   = \&nan;
    *random_ndigit_prime = \&nan;

    sub cmp { }

    *acmp = \&cmp;
    *sign = \&cmp;

    sub eq {
        my ($x, $y) = @_;
        ref($y) eq ref($x)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_real {
        Sidef::Types::Bool::Bool::FALSE;
    }

    *le                = \&is_real;
    *lt                = \&is_real;
    *gt                = \&is_real;
    *ge                = \&is_real;
    *is_div            = \&is_real;
    *ne                = \&is_real;
    *is_zero           = \&is_real;
    *is_one            = \&is_real;
    *is_mone           = \&is_real;
    *is_ninf           = \&is_real;
    *is_positive       = \&is_real;
    *is_negative       = \&is_real;
    *is_pos            = \&is_real;
    *is_neg            = \&is_real;
    *is_inf            = \&is_real;
    *is_even           = \&is_real;
    *is_odd            = \&is_real;
    *is_int            = \&is_real;
    *divides           = \&is_real;
    *is_square         = \&is_real;
    *is_sqr            = \&is_real;
    *is_prime          = \&is_real;
    *is_semiprime      = \&is_real;
    *is_prob_prime     = \&is_real;
    *is_prov_prime     = \&is_real;
    *is_mersenne_prime = \&is_real;
    *is_square_free    = \&is_real;
    *is_prime_power    = \&is_real;
    *is_primitive_root = \&is_real;

    sub complex {
        my ($x, $y) = @_;
        if (defined $y) {
            Sidef::Types::Number::Complex->new(NAN, $y);
        }
        else {
            state $z = Sidef::Types::Number::Complex->new(NAN);
        }
    }

    *c = \&complex;

    sub i {
        state $x = Sidef::Types::Number::Complex->new(0, NAN);
    }

    sub cis {
        state $x = Sidef::Types::Number::Complex->new(NAN, NAN);
    }

    sub sin_cos {
        ((Sidef::Types::Number::Nan::NAN) x 2);
    }

    sub dump {
        state $x = Sidef::Types::String::String->new('NaN');
    }

    *commify = \&dump;

    sub as_rat {
        state $x = Sidef::Types::String::String->new('0/0');
    }

    *as_frac = \&as_rat;

    sub chr {
        state $x = Sidef::Types::String::String->new('');
    }

    *as_bin   = \&chr;
    *as_hex   = \&chr;
    *as_oct   = \&chr;
    *as_int   = \&chr;
    *as_float = \&chr;

    sub zero {
        Sidef::Types::Number::Number::ZERO;
    }

    *nu        = \&zero;
    *numerator = \&zero;

    *de          = \&zero;
    *denominator = \&zero;

    *im        = \&zero;
    *imag      = \&zero;
    *imaginary = \&zero;

    sub of {
        Sidef::Types::Array::Array->new([]);
    }

    *defs        = \&of;
    *digits      = \&of;
    *factor      = \&of;
    *factors     = \&of;
    *factor_exp  = \&of;
    *factors_exp = \&of;
    *primes      = \&of;
    *divisors    = \&of;

    sub times { $_[1] }

    *itimes = \&times;

    sub parts {
        (Sidef::Types::Number::Number::ZERO, Sidef::Types::Number::Number::ZERO);
    }

    *nude = \&parts;

    sub divmod {
        ($_[0], $_[0]);
    }

    *isqrtrem = \&divmod;
    *irootrem = \&divmod;

    sub seed { undef; }

    *iseed = \&seed;

    *forperm = \&seed;
    *forcomb = \&seed;

    *permutations = \&seed;
    *combinations = \&seed;

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
        *{__PACKAGE__ . '::' . '!!'}  = \&double_factorial;
        *{__PACKAGE__ . '::' . '%%'}  = \&is_div;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
        *{__PACKAGE__ . '::' . ':'}   = \&complex;
        *{__PACKAGE__ . '::' . '//'}  = \&idiv;
        *{__PACKAGE__ . '::' . 'Γ'}  = \&gamma;
        *{__PACKAGE__ . '::' . 'Ψ'}  = \&digamma;
        *{__PACKAGE__ . '::' . 'ϕ'}  = \&euler_totient;
        *{__PACKAGE__ . '::' . 'σ'}  = \&sigma;
        *{__PACKAGE__ . '::' . 'Ω'}  = \&big_omega;
        *{__PACKAGE__ . '::' . 'ω'}  = \&omega;
        *{__PACKAGE__ . '::' . 'ζ'}  = \&zeta;
        *{__PACKAGE__ . '::' . 'η'}  = \&eta;
        *{__PACKAGE__ . '::' . 'μ'}  = \&mobius;
    }
}

1
