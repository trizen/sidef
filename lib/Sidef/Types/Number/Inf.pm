package Sidef::Types::Number::Inf {

    use utf8;
    use 5.014;

    use parent qw(
      Sidef::Types::Number::Number
      );

    use overload
      q{bool} => sub { 1 },
      q{0+}   => sub { 'inf' },
      q{""}   => sub { 'Inf' };

    Math::GMPq::Rmpq_set_ui((state $INF = Math::GMPq::Rmpq_init_nobless()), 1, 0);

    use constant INF => bless(\$INF, __PACKAGE__);

    use Sidef::Types::Number::Nan;

    sub new { INF }

    sub get_value { 'Inf' }

    sub add {
        my ($x, $y) = @_;
        ref($y) eq 'Sidef::Types::Number::Ninf' ? Sidef::Types::Number::Nan::NAN : $x;
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
        ref($y) eq __PACKAGE__ and return $x;
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

    sub is_pos { Sidef::Types::Bool::Bool::TRUE }

    *is_inf = \&is_pos;

    sub is_real { Sidef::Types::Bool::Bool::FALSE }

    *is_nan            = \&is_real;
    *is_neg            = \&is_real;
    *is_prime          = \&is_real;
    *is_prob_prime     = \&is_real;
    *is_prov_prime     = \&is_real;
    *is_mersenne_prime = \&is_real;
    *is_square         = \&is_real;
    *is_sqr            = \&is_real;
    *is_power          = \&is_real;
    *is_pow            = \&is_real;
    *is_div            = \&is_real;
    *is_even           = \&is_real;
    *is_odd            = \&is_real;
    *divides           = \&is_real;
    *is_ninf           = \&is_real;
    *is_zero           = \&is_real;
    *is_one            = \&is_real;
    *is_mone           = \&is_real;
    *is_square_free    = \&is_real;
    *is_prime_power    = \&is_real;
    *is_primitive_root = \&is_real;

    sub nan { Sidef::Types::Number::Nan::NAN }

    *mod               = \&nan;
    *imod              = \&nan;
    *fmod              = \&nan;
    *frem              = \&nan;
    *bin               = \&nan;
    *modpow            = \&nan;
    *expmod            = \&nan;
    *powmod            = \&nan;
    *modinv            = \&nan;
    *invmod            = \&nan;
    *and               = \&nan;
    *or                = \&nan;
    *xor               = \&nan;
    *legendre          = \&nan;
    *jacobi            = \&nan;
    *kronecker         = \&nan;
    *gcd               = \&nan;
    *lcm               = \&nan;
    *next_power2       = \&nan;
    *next_pow2         = \&nan;
    *next_pow          = \&nan;
    *next_power        = \&nan;
    *next_prime        = \&nan;
    *prev_prime        = \&nan;
    *digit             = \&nan;
    *bernreal          = \&nan;
    *bernfrac          = \&nan;
    *bern              = \&nan;
    *bernoulli         = \&nan;
    *valuation         = \&nan;
    *popcount          = \&nan;
    *mobius            = \&nan;
    *moebius           = \&nan;
    *sigma             = \&nan;
    *sigma0            = \&nan;
    *omega             = \&nan;
    *big_omega         = \&nan;
    *prime_root        = \&nan;
    *prime_power       = \&nan;
    *perfect_root      = \&nan;
    *perfect_power     = \&nan;
    *totient           = \&nan;
    *euler_phi         = \&nan;
    *euler_totient     = \&nan;
    *jordan_totient    = \&nan;
    *carmichael_lambda = \&nan;
    *liouville         = \&nan;
    *exp_mangoldt      = \&nan;
    *stirling          = \&nan;
    *stirling2         = \&nan;
    *stirling3         = \&nan;
    *znorder           = \&nan;
    *znprimroot        = \&nan;
    *ramanujan_tau     = \&nan;
    *prime_count       = \&nan;
    *remove            = \&nan;
    *rad               = \&nan;

    *harm     = \&inf;
    *harmonic = \&inf;
    *harmfrac = \&inf;
    *harmreal = \&inf;

    sub as_bin {
        state $x = Sidef::Types::String::String->new;
    }

    *as_oct = \&as_bin;
    *as_hex = \&as_bin;

    sub digits {
        Sidef::Types::Array::Array->new([]);
    }

    *factor   = \&digits;
    *factors  = \&digits;
    *pfactor  = \&digits;
    *pfactors = \&digits;
    *primes   = \&digits;
    *divisors = \&digits;

    sub divmod {
        my ($x, $y) = @_;
        ($x->div($y), Sidef::Types::Number::Nan::NAN);
    }

    sub isqrtrem {
        my ($x) = @_;
        my $sqrt = $x->isqrt;
        ($sqrt, $x->isub($sqrt->imul($sqrt)));
    }

    sub irootrem {
        my ($x, $y) = @_;
        my $root = $x->iroot($y);
        ($root, $x->isub($root->ipow($y)));
    }

    sub ninf {
        state $x = Sidef::Types::Number::Ninf->new;
    }

    *neg = \&ninf;
    *not = \&ninf;

    sub root {
        my ($x, $y) = @_;
        ref($y) eq 'Sidef::Types::Number::Nan' ? $y
          : (   ref($y) eq 'Sidef::Types::Number::Inf'
             || ref($y) eq 'Sidef::Types::Number::Ninf') ? Sidef::Types::Number::Number::ONE
          : $y->is_neg ? Sidef::Types::Number::Number::ZERO
          :              INF;
    }

    *iroot = \&root;

    sub min { $_[1] }
    sub inf { INF }

    *max              = \&inf;
    *abs              = \&inf;
    *sqrt             = \&inf;
    *isqrt            = \&inf;
    *cbrt             = \&inf;
    *sqr              = \&inf;
    *log              = \&inf;
    *lgrt             = \&inf;
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
    *ei               = \&inf;
    *li2              = \&ninf;
    *li               = \&inf;
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
    *pn_primorial     = \&inf;
    *fibonacci        = \&inf;
    *lucas            = \&inf;
    *shift_left       = \&inf;
    *shift_right      = \&inf;
    *irand            = \&inf;
    *rand             = \&inf;
    *rad2deg          = \&inf;
    *rad2grad         = \&inf;
    *deg2grad         = \&inf;
    *deg2rad          = \&inf;
    *grad2rad         = \&inf;
    *grad2deg         = \&inf;
    *round            = \&inf;
    *roundf           = \&inf;
    *partitions       = \&inf;
    *bell             = \&inf;

    sub zero { Sidef::Types::Number::Number::ZERO }

    *inv = \&zero;

    *sin = \&nan;    # -1 to 1
    *cos = \&nan;    # -1 to 1

    *sech  = \&zero;
    *csch  = \&zero;
    *acsc  = \&zero;
    *acsch = \&zero;
    *acot  = \&zero;
    *acoth = \&zero;
    *erfc  = \&zero;

    sub tanh { Sidef::Types::Number::Number::ONE }

    *coth = \&tanh;
    *zeta = \&tanh;
    *eta  = \&tanh;
    *erf  = \&tanh;
    *sign = \&tanh;

    sub chr { state $x = Sidef::Types::String::String->new('') }

    #
    ## asin(inf) = -inf*i
    #
    sub asin { state $x = Sidef::Types::Number::Complex->new(0, '-@Inf@') }

    #
    ## acos(inf) = inf*i
    #
    sub acos { state $x = Sidef::Types::Number::Complex->new(0, '@Inf@') }

    #
    ## atan(inf) = pi/2
    #
    sub atan {
        state $two = Sidef::Types::Number::Number->new(2);
        Sidef::Types::Number::Number->pi->div($two);
    }

    *atan2 = \&atan;
    *asec  = \&atan;

    #
    ## atanh(inf) = -pi/2*i
    #
    sub atanh {
        state $neg_two = Sidef::Types::Number::Number->new(-2);
        Sidef::Types::Number::Number->pi->div($neg_two)->i;
    }

    #
    ## asech(inf) = pi/2*i
    #
    sub asech {
        state $two = Sidef::Types::Number::Number->new(2);
        Sidef::Types::Number::Number->pi->div($two)->i;
    }

    sub cis {
        state $x = Sidef::Types::Number::Complex->new((Sidef::Types::Number::Nan::NAN) x 2);
    }

    #
    ## binomial(inf, x) = 0       | with x < 0
    ## binomial(inf, inf) = 1
    ## binomial(inf, x) = inf     | with x > 0
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

    sub times {
        my ($x, $block) = @_;

        my $i = Math::GMPz::Rmpz_init_set_ui(1);
        while (1) {
            my $num = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_z($num, $i);
            Math::GMPz::Rmpz_add_ui($i, $i, 1);
            $block->run(bless \$num, 'Sidef::Types::Number::Number');
        }

        $block;
    }

    sub itimes {
        my ($x, $block) = @_;

        my $i = Math::GMPz::Rmpz_init_set_ui(0);
        while (1) {
            my $num = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_z($num, $i);
            Math::GMPz::Rmpz_add_ui($i, $i, 1);
            $block->run(bless \$num, 'Sidef::Types::Number::Number');
        }

        $block;
    }

    sub of {
        my ($x, $block) = @_;

        my @array;
        my $i = Math::GMPz::Rmpz_init_set_ui(1);

        while (1) {
            my $num = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_z($num, $i);
            Math::GMPz::Rmpz_add_ui($i, $i, 1);
            push @array, $block->run(bless \$num, 'Sidef::Types::Number::Number');
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    sub defs {
        my ($x, $block) = @_;

        my @array;
        my $i = Math::GMPz::Rmpz_init_set_ui(1);

        while (1) {
            my $num = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_z($num, $i);
            Math::GMPz::Rmpz_add_ui($i, $i, 1);
            push @array, $block->run(bless \$num, 'Sidef::Types::Number::Number') // next;
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    sub pow {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Nan') {
            return $y;
        }

            $y->is_neg  ? (Sidef::Types::Number::Number::ZERO)
          : $y->is_zero ? (Sidef::Types::Number::Number::ONE)
          :               $x;
    }

    *fpow = \&pow;

    sub ipow {
        $_[0]->pow($_[1]->int);
    }

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
        if (ref($_[1]) eq __PACKAGE__) {
            (Sidef::Types::Bool::Bool::FALSE);
        }
        else {
            (Sidef::Types::Bool::Bool::TRUE);
        }
    }

    sub ge {
        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub lt {
        (Sidef::Types::Bool::Bool::FALSE);
    }

    sub le {
        if (ref($_[1]) eq __PACKAGE__) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub cmp {
        ref($_[1]) eq __PACKAGE__
          ? Sidef::Types::Number::Number::ZERO
          : Sidef::Types::Number::Number::ONE;
    }

    sub i {
        state $x = Sidef::Types::Number::Complex->new(0, INF);
    }

    sub dump {
        state $x = Sidef::Types::String::String->new('Inf');
    }

    *commify = \&dump;

    sub numerator {
        Sidef::Types::Number::Number::ONE;
    }

    *nu = \&numerator;

    sub denominator {
        Sidef::Types::Number::Number::ZERO;
    }

    *de = \&denominator;

    sub parts {
        (Sidef::Types::Number::Number::ONE, Sidef::Types::Number::Number::ZERO);
    }

    *nude = \&parts;

    sub seed { }
    *iseed = \&seed;

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
        *{__PACKAGE__ . '::' . 'Γ'}  = \&inf;
        *{__PACKAGE__ . '::' . 'Ψ'}  = \&inf;
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
