package Sidef::Types::Number::Inf {

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

    sub sub {
        my ($x, $y) = @_;
        ref($y) eq __PACKAGE__ ? nan() : $x;
    }

    sub mul {
        my ($x, $y) = @_;
        ref($y) eq __PACKAGE__ and return $x;
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
        state $x = Sidef::Types::Bool::Bool->true;
    }

    sub is_neg {
        state $x = Sidef::Types::Bool::Bool->false;
    }

    sub nan {
        state $x = Sidef::Types::Number::Nan->new;
    }

    *mod  = \&nan;
    *fmod = \&nan;

    sub ninf {
        state $x = Sidef::Types::Number::Ninf->new;
    }

    *neg = \&ninf;

    sub min { $_[1] }
    sub inf { $_[0] }

    *max     = \&inf;
    *abs     = \&inf;
    *sqrt    = \&inf;
    *cbrt    = \&inf;
    *root    = \&inf;
    *sqr     = \&inf;
    *log     = \&inf;
    *log2    = \&inf;
    *log10   = \&inf;
    *exp     = \&inf;
    *exp2    = \&inf;
    *exp10   = \&inf;
    *sinh    = \&inf;
    *asinh   = \&inf;
    *cosh    = \&inf;
    *acosh   = \&inf;
    *tan     = \&inf;
    *sec     = \&inf;
    *csc     = \&inf;
    *cot     = \&inf;
    *hypot   = \&inf;
    *gamma   = \&inf;
    *lgamma  = \&inf;
    *digamma = \&inf;
    *eint    = \&inf;
    *li2     = \&inf;
    *inc     = \&inf;
    *dec     = \&inf;

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
        $y->is_neg ? $ZERO : $y->is_zero ? nan() : $x;
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
