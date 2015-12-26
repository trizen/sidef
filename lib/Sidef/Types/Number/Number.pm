package Sidef::Types::Number::Number {

    use utf8;
    use 5.014;

    use Math::GMPq qw(:mpq);
    use Math::GMPz qw(:mpz);
    use Math::GMPf qw(:mpf);
    use Math::MPFR qw(:mpfr);

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    our $ROUND = MPFR_RNDN;
    our $PREC  = 128;

    our $GET_PERL_VALUE = 0;

    use constant {
                  ONE      => bless(\Math::GMPq->new(1),  __PACKAGE__),
                  ZERO     => bless(\Math::GMPq->new(0),  __PACKAGE__),
                  MONE     => bless(\Math::GMPq->new(-1), __PACKAGE__),
                  _FFACTOR => 3.321923,
                 };

    use overload
      q{bool} => sub { Rmpq_sgn(${$_[0]}) != 0 },
      q{0+}   => sub { Rmpq_get_d(${$_[0]}) },
      q{""}   => \&get_value;

    sub _load_bigint {
        state $bigint = do {
            require Math::BigInt;
            Math::BigInt->import(try => 'GMP');
        };
    }

    sub _load_bigrat {
        state $bigrat = do {
            require Math::BigRat;
            Math::BigRat->import('try' => 'GMP');
        };
    }

    sub _new {
        bless(\$_[0], __PACKAGE__);
    }

    sub _new_int {
        my $r = Rmpq_init();
        Rmpq_set_si($r, $_[0], 1);
        bless \$r, __PACKAGE__;
    }

    sub _new_uint {
        my $r = Rmpq_init();
        Rmpq_set_ui($r, $_[0], 1);
        bless \$r, __PACKAGE__;
    }

    sub new {
        my (undef, $num, $base) = @_;

        $base = defined($base) ? ref($base) ? $base->get_value : $base : 10;

        ref($num) eq __PACKAGE__ ? $num : do {

            $num = $num->get_value
              if (index(ref($num), 'Sidef::') == 0);

            ref($num) eq 'Math::GMPq'
              ? bless(\$num, __PACKAGE__)
              : bless(\Math::GMPq->new($base == 10 ? _str2rat($num // 0) : ($num // 0), $base), __PACKAGE__);
          }
    }

    *call = \&new;

    sub _valid {
        (
         ref($_) eq __PACKAGE__
           or die "[ERROR] Invalid argument `$_` of type "
           . Sidef::normalize_type(ref($_)) . " in "
           . Sidef::normalize_method((caller(1))[3])
           . "(). Expected an argument of type Number!\n"
        )
          for @_;
    }

    sub _as_float {
        my $r = Rmpfr_init2($PREC);
        Rmpfr_set_q($r, ${$_[0]}, $ROUND);
        $r;
    }

    sub _as_int {
        my $i = Rmpz_init();
        Rmpz_set_q($i, ${$_[0]});
        $i;
    }

    sub _mpfr2rat {

        #~ my ($mantissa, $exponent) = Rmpfr_deref2($_[0], 10, 0, $ROUND);
        #~ my $r = Rmpq_init();
        #~ Rmpq_set_str($r, "$mantissa/1" . ('0' x (length($mantissa) - $exponent)), 10);
        #~ Rmpq_canonicalize($r);
        #~ $r

        if (Rmpfr_inf_p($_[0])) {
            my $r = Rmpq_init();
            if (Rmpq_sgn($_[0]) > 0) {
                Rmpq_set_ui($r, 1, 0);
            }
            else {
                Rmpq_set_si($r, -1, 0);
            }
            return $r;
        }

        if (Rmpfr_integer_p($_[0])) {
            my $z = Rmpz_init_nobless();
            Rmpfr_get_z($z, $_[0], $ROUND);

            my $r = Rmpq_init();
            Rmpq_set_z($r, $z);
            Rmpz_clear($z);
            $r;
        }
        else {
            my $f = Rmpf_init2_nobless($PREC);
            Rmpfr_get_f($f, $_[0], $ROUND);

            my $r = Rmpq_init();
            Rmpq_set_f($r, $f);
            Rmpf_clear($f);
            $r;
        }

        #Math::GMPq->new("$mantissa/1" . ('0' x (length($mantissa) - $exponent)));
        #my $str = Rmpfr_get_str($_[0], 10, 0, $ROUND);
        #Math::GMPq->new(_str2rat($str));
    }

    sub _mpz2rat {
        my $r = Rmpq_init();
        Rmpq_set_z($r, $_[0]);
        $r;
    }

    sub _str2rat {
        my ($str) = @_;

        my $sign = substr($str, 0, 1);
        if ($sign eq '-') {
            substr($str, 0, 1, '');
            $sign = '-';
        }
        else {
            substr($str, 0, 1, '') if ($sign eq '+');
            $sign = '';
        }

        if ((my $i = index($str, 'e')) != -1) {

            my $exp = substr($str, $i + 1);
            my ($before, $after) = split(/\./, substr($str, 0, $i));
            my $numerator = $before . $after;

            my $denominator = 1;
            if ($exp < 1) {
                $denominator .= '0' x (abs($exp) + length($after));
            }
            else {
                my $diff = ($exp - length($after));
                if ($diff >= 0) {
                    $numerator .= '0' x $diff;
                }
                else {
                    my $s = $before . $after;
                    substr($s, $exp + length($before), 0, '.');
                    return _str2rat("$sign$s");
                }
            }

            "$sign$numerator/$denominator";
        }
        elsif ((my $i = index($str, '.')) != -1) {
            my ($before, $after) = (substr($str, 0, $i), substr($str, $i + 1));
            if ($after =~ tr/0// == length($after)) {
                return "$sign$before";
            }
            $sign . ("$before$after/1" =~ s/^0+//r) . ('0' x length($after));
        }
        else {
            $sign . $str;
        }
    }

    sub get_value {
        $GET_PERL_VALUE ? Rmpq_get_d(${$_[0]}) : do {

            my $v = Rmpq_get_str(${$_[0]}, 10);

            if (index($v, '/') != -1) {
                state $bigrat = _load_bigrat();
                my $br = Math::BigRat->new($v);
                $br->as_float(CORE::int($PREC / _FFACTOR))->bstr =~ s/0+$//r;
            }
            else {
                $v;
            }
          }
    }

    sub _get_frac {
        Rmpq_get_str(${$_[0]}, 10);
    }

    #
    ## Constants
    #

    sub pi {
        my $pi = Rmpfr_init2($PREC);
        Rmpfr_const_pi($pi, $ROUND);
        _new(_mpfr2rat($pi));
    }

    sub e {

        state $one_f = do {
            my ($f) = Rmpfr_init_set_ui(1, $ROUND);
            $f;
        };

        my $e = Rmpfr_init2($PREC);
        Rmpfr_exp($e, $one_f, $ROUND);
        _new(_mpfr2rat($e));
    }

    sub phi {
        state $one_f = do {
            my ($f) = Rmpfr_init_set_ui(1, $ROUND);
            $f;
        };

        state $two_f = do {
            my ($f) = Rmpfr_init_set_ui(2, $ROUND);
            $f;
        };

        state $five_f = do {
            my ($f) = Rmpfr_init_set_ui(5, $ROUND);
            $f;
        };

        my $phi = Rmpfr_init2($PREC);
        Rmpfr_sqrt($phi, $five_f, $ROUND);
        Rmpfr_add($phi, $phi, $one_f, $ROUND);
        Rmpfr_div($phi, $phi, $two_f, $ROUND);

        _new(_mpfr2rat($phi));
    }

    sub inf {
        state $x = do {
            my $inf = Rmpq_init();
            Rmpq_set_ui($inf, 1, 0);
            _new($inf);
        };
    }

    sub ninf {
        state $x = do {
            my $ninf = Rmpq_init();
            Rmpq_set_si($ninf, -1, 0);
            _new($ninf);
        };
    }

    sub nan {
        state $x = do {
            my $nan = Rmpq_init();
            Rmpq_set_si($nan, "-0", "-0");
            _new($nan);
        };
    }

    #
    ## Rational operations
    #

    sub add {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Complex') {
            return $y->new($x)->add($y);
        }

        _valid($y);

        _is_inf($$x) && return $x;
        _is_inf($$y) && return $y;

        my $r = Rmpq_init();
        Rmpq_add($r, $$x, $$y);
        _new($r);
    }

    sub sub {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Complex') {
            return $y->new($x)->sub($y);
        }

        _valid($y);

        _is_inf($$x) && return $x;
        _is_inf($$y) && return $y;

        my $r = Rmpq_init();
        Rmpq_sub($r, $$x, $$y);
        _new($r);
    }

    sub div {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Complex') {
            return $y->new($x)->div($y);
        }

        _valid($y);

        _is_inf($$x) && return $x;
        _is_inf($$y) && return $y;

        if (Rmpq_sgn($$y) == 0) {
            my $sign = Rmpq_sgn($$x);
            return ($sign == 0 ? $x->nan : $sign > 0 ? $x->inf : $x->ninf);
        }

        my $r = Rmpq_init();
        Rmpq_div($r, $$x, $$y);
        _new($r);
    }

    *rdiv = \&div;

    sub mul {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Complex') {
            return $y->new($x)->mul($y);
        }

        _valid($y);

        _is_inf($$x) && return $x;
        _is_inf($$y) && return $y;

        my $r = Rmpq_init();
        Rmpq_mul($r, $$x, $$y);
        _new($r);
    }

    sub neg {
        my ($x) = @_;
        my $r = Rmpq_init();
        Rmpq_neg($r, $$x);
        _new($r);
    }

    *negative = \&neg;

    sub abs {
        my ($x) = @_;
        my $r = Rmpq_init();
        Rmpq_abs($r, $$x);
        _new($r);
    }

    *pos      = \&abs;
    *positive = \&abs;

    sub inv {
        my ($x) = @_;
        my $r = Rmpq_init();
        Rmpq_inv($r, $$x);
        _new($r);
    }

    sub sqrt {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_sqrt($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub cbrt {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_cbrt($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub root {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpfr_init2($PREC);
        Rmpfr_root($r, _as_float($x), CORE::int(Rmpq_get_d($$y)), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub sqr {
        my ($x) = @_;
        $x->mul($x);
    }

    sub pow {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Complex') {
            return $y->new($x)->pow($y);
        }

        _valid($y);

        if (_is_int($$x) and _is_int($$y) and Rmpq_sgn($$y) >= 0) {
            my $z = Rmpz_init();
            Rmpz_set_q($z, $$x);
            Rmpz_pow_ui($z, $z, Rmpq_get_d($$y));
            return _new(_mpz2rat($z));
        }

        my $r = Rmpfr_init2($PREC);
        Rmpfr_pow($r, _as_float($x), _as_float($y), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub fmod {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpfr_init2($PREC);
        Rmpfr_fmod($r, _as_float($x), _as_float($y), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub log {
        my ($x, $y) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_log($r, _as_float($x), $ROUND);

        if (defined $y) {
            _valid($y);
            my $baseln = Rmpfr_init2($PREC);
            Rmpfr_log($baseln, _as_float($y), $ROUND);
            Rmpfr_div($r, $r, $baseln, $ROUND);
        }

        _new(_mpfr2rat($r));
    }

    sub ln {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_log($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub log2 {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_log2($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub log10 {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_log10($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub exp {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_exp($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub exp2 {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_exp2($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub exp10 {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_exp10($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub sin {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_sin($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub asin {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_asin($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub sinh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_sinh($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub asinh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_asinh($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub cos {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_cos($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub acos {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_acos($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub cosh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_cosh($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub acosh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_acosh($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub tan {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_tan($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub atan {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_atan($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub tanh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_tanh($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub atanh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_atanh($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub sec {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_sec($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub sech {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_sech($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub csc {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_csc($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub csch {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_csch($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub cot {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_cot($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub coth {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_coth($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub agm {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpfr_init2($PREC);
        Rmpfr_agm($r, _as_float($x), _as_float($y), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub hypot {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpfr_init2($PREC);
        Rmpfr_hypot($r, _as_float($x), _as_float($y), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub gamma {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_gamma($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub lgamma {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_lgamma($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub digamma {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_digamma($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub zeta {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_zeta($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub erf {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_erf($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub erfc {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_erfc($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub eint {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_eint($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    sub li2 {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_li2($r, _as_float($x), $ROUND);
        _new(_mpfr2rat($r));
    }

    #
    ## Comparison and testing operations
    #

    sub eq {
        my ($x, $y) = @_;
        _valid($y);
        Sidef::Types::Bool::Bool->new(Rmpq_equal($$x, $$y));
    }

    sub ne {
        my ($x, $y) = @_;
        _valid($y);
        Sidef::Types::Bool::Bool->new(!Rmpq_equal($$x, $$y));
    }

    sub cmp {
        my ($x, $y) = @_;
        _valid($y);
        my $cmp = Rmpq_cmp($$x, $$y);
        $cmp == 0 ? ZERO : $cmp < 0 ? MONE : ONE;
    }

    sub acmp {
        my ($x, $y) = @_;

        _valid($y);

        my $xn = $$x;
        my $yn = $$y;

        my $a1 = Rmpq_sgn($xn) < 0
          ? do {
            my $r = Rmpq_init();
            Rmpq_abs($r, $xn);
            $r;
          }
          : $xn;

        my $a2 = Rmpq_sgn($yn) < 0
          ? do {
            my $r = Rmpq_init();
            Rmpq_abs($r, $yn);
            $r;
          }
          : $yn;

        my $cmp = Rmpq_cmp($a1, $a2);
        $cmp == 0 ? ZERO : $cmp < 0 ? MONE : ONE;
    }

    sub gt {
        my ($x, $y) = @_;
        _valid($y);

        return Sidef::Types::Bool::Bool->false if Rmpq_equal($$x, $$y);

        my $xs = Rmpq_get_str($$x, 10);
        my $ys = Rmpq_get_str($$y, 10);

        if ($xs eq '1/0' or $ys eq '-1/0') {
            return Sidef::Types::Bool::Bool->true;
        }
        elsif ($ys eq '1/0' or $xs eq '-1/0') {
            return Sidef::Types::Bool::Bool->false;
        }

        Sidef::Types::Bool::Bool->new(Rmpq_cmp($$x, $$y) > 0);
    }

    sub ge {
        my ($x, $y) = @_;
        _valid($y);

        if (!Rmpq_equal($$x, $$y)) {
            my $xs = "$$x";
            my $ys = "$$y";

            if ($xs eq '1/0' or $ys eq '-1/0') {
                return Sidef::Types::Bool::Bool->true;
            }
            elsif ($ys eq '1/0' or $xs eq '-1/0') {
                return Sidef::Types::Bool::Bool->false;
            }
        }
        else {
            return Sidef::Types::Bool::Bool->true;
        }

        Sidef::Types::Bool::Bool->new(Rmpq_cmp($$x, $$y) >= 0);
    }

    sub lt {
        my ($x, $y) = @_;
        _valid($y);

        return Sidef::Types::Bool::Bool->false if Rmpq_equal($$x, $$y);

        my $xs = Rmpq_get_str($$x, 10);
        my $ys = Rmpq_get_str($$y, 10);

        if ($xs eq '1/0' or $ys eq '-1/0') {
            return Sidef::Types::Bool::Bool->false;
        }
        elsif ($ys eq '1/0' or $xs eq '-1/0') {
            return Sidef::Types::Bool::Bool->true;
        }

        Sidef::Types::Bool::Bool->new(Rmpq_cmp($$x, $$y) < 0);
    }

    sub le {
        my ($x, $y) = @_;
        _valid($y);

        if (!Rmpq_equal($$x, $$y)) {
            my $xs = "$$x";
            my $ys = "$$y";

            if ($xs eq '1/0' or $ys eq '-1/0') {
                return Sidef::Types::Bool::Bool->false;
            }
            elsif ($ys eq '1/0' or $xs eq '-1/0') {
                return Sidef::Types::Bool::Bool->true;
            }
        }
        else {
            return Sidef::Types::Bool::Bool->true;
        }

        Sidef::Types::Bool::Bool->new(Rmpq_cmp($$x, $$y) <= 0);
    }

    sub is_zero {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_sgn($$x) == 0);
    }

    sub is_one {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_equal($$x, ${(ONE)}));
    }

    sub is_positive {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_sgn($$x) > 0);
    }

    *is_pos = \&is_positive;

    sub is_negative {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_sgn($$x) < 0);
    }

    *is_neg = \&is_negative;

    sub _is_int {
        my ($x) = @_;

        my $dz = Rmpz_init();
        Rmpq_get_den($dz, $x);

        state $one_z = Rmpz_init_set_str(1, 10);
        Rmpz_cmp($dz, $one_z) == 0;
    }

    sub is_int {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new(_is_int($$x));
    }

    sub is_even {
        my ($x) = @_;
        _is_int($$x) or return Sidef::Types::Bool::Bool->false;

        my $nz = Rmpz_init();
        Rmpq_get_num($nz, $$x);

        Sidef::Types::Bool::Bool->new(Rmpz_even_p($nz));
    }

    sub is_odd {
        my ($x) = @_;
        _is_int($$x) or return Sidef::Types::Bool::Bool->false;

        my $nz = Rmpz_init();
        Rmpq_get_num($nz, $$x);

        Sidef::Types::Bool::Bool->new(Rmpz_odd_p($nz));
    }

    sub is_div {
        my ($x, $y) = @_;
        _valid($y);
        my $z = Rmpz_init();
        Rmpz_mod($z, _as_int($x), _as_int($y));
        Sidef::Types::Bool::Bool->new(Rmpz_sgn($z) == 0);
    }

    sub divides {
        my ($x, $y) = @_;
        _valid($y);
        my $z = Rmpz_init();
        Rmpz_mod($z, _as_int($y), _as_int($x));
        Sidef::Types::Bool::Bool->new(Rmpz_sgn($z) == 0);
    }

    sub _is_inf {
        my ($x) = @_;

        state $inf = do {
            my $q = Rmpq_init();
            Rmpq_set_ui($q, 1, 0);
            $q;
        };

        state $ninf = do {
            my $q = Rmpq_init();
            Rmpq_set_si($q, -1, 0);
            $q;
        };

        Rmpq_equal($inf, $x) or Rmpq_equal($ninf, $x);
    }

    sub is_inf {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new(_is_inf($$x));
    }

    sub is_nan {
        my ($x) = @_;

        my $nz = Rmpz_init();
        my $dz = Rmpz_init();

        Rmpq_get_num($nz, $$x);
        Rmpq_get_den($dz, $$x);

        Sidef::Types::Bool::Bool->new(Rmpz_sgn($nz) == 0 and Rmpz_sgn($dz) == 0);
    }

    sub max {
        my ($x, $y) = @_;
        _valid($y);
        Rmpq_cmp($$x, $$y) > 0 ? $x : $y;
    }

    sub min {
        my ($x, $y) = @_;
        _valid($y);
        Rmpq_cmp($$x, $$y) < 0 ? $x : $y;
    }

    sub int {
        my ($x) = @_;
        my $z = Rmpz_init();
        Rmpz_set_q($z, $$x);
        _new(_mpz2rat($z));
    }

    *as_int = \&int;

    sub float {
        my $f = Rmpfr_init2($PREC);
        Rmpfr_set_q($f, ${$_[0]}, $ROUND);
        _new(_mpfr2rat($f));
    }

    *as_float = \&float;

    sub rat { $_[0] }

    sub as_rat {
        Sidef::Types::String::String->new(Rmpq_get_str(${$_[0]}, 10));
    }

    *dump = \&as_rat;

    sub as_bin {
        my $z = Rmpz_init();
        Rmpz_set_q($z, ${$_[0]});
        state $bigint = _load_bigint();
        Sidef::Types::String::String->new(substr(Math::BigInt->new(Rmpz_get_str($z, 10))->as_bin, 2));
    }

    sub as_oct {
        my $z = Rmpz_init();
        Rmpz_set_q($z, ${$_[0]});
        state $bigint = _load_bigint();
        Sidef::Types::String::String->new(substr(Math::BigInt->new(Rmpz_get_str($z, 10))->as_oct, 1));
    }

    sub as_hex {
        my $z = Rmpz_init();
        Rmpz_set_q($z, ${$_[0]});
        state $bigint = _load_bigint();
        Sidef::Types::String::String->new(substr(Math::BigInt->new(Rmpz_get_str($z, 10))->as_hex, 2));
    }

    sub bin {
        my $z = Rmpz_init();
        Rmpz_set_q($z, ${$_[0]});

        my $r = Rmpz_init();
        my @digits =
          grep { $_ eq '0' or $_ eq '1' or die "[ERROR] Non-binary digit detected inside number `$z` in Number.bin()\n" }
          split(//, scalar reverse Rmpz_get_str($z, 10));

        foreach my $i (0 .. $#digits) {
            if ($digits[$i] eq '1') {
                my $tmp = Rmpz_init();
                Rmpz_ui_pow_ui($tmp, 2, $i);
                Rmpz_add($r, $r, $tmp);
            }
        }
        _new(_mpz2rat($r));
    }

    sub digits {
        my $z = Rmpz_init();
        Rmpz_set_q($z, ${$_[0]});
        Rmpz_abs($z, $z);
        Sidef::Types::Array::Array->new(map { _new_uint($_) } split(//, Rmpz_get_str($z, 10)));
    }

    sub length {
        my $z = Rmpz_init();
        Rmpz_set_q($z, ${$_[0]});
        _new_uint(Rmpz_sizeinbase($z, 10));
    }

    *len  = \&length;
    *size = \&length;

    sub floor {
        my ($x) = @_;
        _is_int($$x) && return $x;

        if (Rmpq_sgn($$x) > 0) {
            my $z = Rmpz_init();
            Rmpz_set_q($z, $$x);
            _new(_mpz2rat($z));
        }
        else {
            my $z = Rmpz_init();
            Rmpz_set_q($z, $$x);
            Rmpz_sub_ui($z, $z, 1);
            _new(_mpz2rat($z));
        }
    }

    sub ceil {
        my ($x) = @_;
        _is_int($$x) && return $x;

        if (Rmpq_sgn($$x) > 0) {
            my $z = Rmpz_init();
            Rmpz_set_q($z, $$x);
            Rmpz_add_ui($z, $z, 1);
            _new(_mpz2rat($z));
        }
        else {
            my $z = Rmpz_init();
            Rmpz_set_q($z, $$x);
            _new(_mpz2rat($z));
        }
    }

    sub inc {
        my ($x) = @_;
        my $r = Rmpq_init();
        Rmpq_add($r, $$x, ${(ONE)});
        _new($r);
    }

    sub dec {
        my ($x) = @_;
        my $r = Rmpq_init();
        Rmpq_sub($r, $$x, ${(ONE)});
        _new($r);
    }

    #
    ## Integer operations
    #

    sub iadd {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_add($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    sub isub {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_sub($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    sub imul {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_mul($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    sub idiv {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_div($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    sub mod {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_mod($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    sub modpow {
        my ($x, $y, $z) = @_;
        _valid($y, $z);
        my $r = Rmpz_init();
        Rmpz_powm($r, _as_int($x), _as_int($y), _as_int($z));
        _new(_mpz2rat($r));
    }

    sub modinv {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_invert($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    sub divmod {
        my ($x, $y) = @_;

        _valid($y);

        my $r1 = Rmpz_init();
        my $r2 = Rmpz_init();

        Rmpz_divmod($r1, $r2, _as_int($x), _as_int($y));
        (_new(_mpz2rat($r1)), _new(_mpz2rat($r2)));
    }

    sub and {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_and($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    sub or {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_ior($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    sub xor {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_xor($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    sub not {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_com($r, _as_int($x));
        _new(_mpz2rat($r));
    }

    sub factorial {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_fac_ui($r, CORE::int(Rmpq_get_d($$x)));
        _new(_mpz2rat($r));
    }

    *fac = \&factorial;

    sub factorial2 {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_2fac_ui($r, CORE::int(Rmpq_get_d($$x)));
        _new(_mpz2rat($r));
    }

    *dfac = \&factorial2;

    sub primorial {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_primorial_ui($r, CORE::int(Rmpq_get_d($$x)));
        _new(_mpz2rat($r));
    }

    sub fibonacci {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_fib_ui($r, CORE::int(Rmpq_get_d($$x)));
        _new(_mpz2rat($r));
    }

    *fib = \&fibonacci;

    sub binomial {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_bin_ui($r, _as_int($x), CORE::int(Rmpq_get_d($$y)));
        _new(_mpz2rat($r));
    }

    sub legendre {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_legendre($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    sub lucas {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_lucnum_ui($r, CORE::int(Rmpq_get_d($$x)));
        _new(_mpz2rat($r));
    }

    sub gcd {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_gcd($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    sub lcm {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_lcm($r, _as_int($x), _as_int($y));
        _new(_mpz2rat($r));
    }

    # Correct up to a maximum value of 341,550,071,728,320
    # See: https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test#Deterministic_variants_of_the_test
    sub is_prime {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new(Rmpz_probab_prime_p(_as_int($x), 7) > 0);
    }

    sub next_prime {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_nextprime($r, _as_int($x));
        _new(_mpz2rat($r));
    }

    sub is_square {
        my ($x) = @_;

        _is_int($$x) or return Sidef::Types::Bool::Bool->false;

        my $nz = Rmpz_init();
        Rmpq_get_num($nz, $$x);

        Sidef::Types::Bool::Bool->new(Rmpz_perfect_square_p($nz));
    }

    *is_sqr = \&is_square;

    sub is_power {
        my ($x) = @_;

        _is_int($$x) or return Sidef::Types::Bool::Bool->false;

        my $nz = Rmpz_init();
        Rmpq_get_num($nz, $$x);

        Sidef::Types::Bool::Bool->new(Rmpz_perfect_power_p($nz));
    }

    *is_pow = \&is_power;

    sub next_pow2 {
        my ($x) = @_;

        state $one_z = do {
            my $r = Rmpz_init();
            Rmpz_set_ui($r, 1);
            $r;
        };

        my $f = Rmpfr_init2($PREC);
        Rmpfr_set_z($f, _as_int($x), $PREC);
        Rmpfr_log2($f, $f, $ROUND);
        Rmpfr_ceil($f, $f);

        my $ui = Rmpfr_get_ui($f, $ROUND);

        my $z = Rmpz_init();
        Rmpz_mul_2exp($z, $one_z, $ui);
        _new(_mpz2rat($z));
    }

    *next_power2 = \&next_pow2;

    sub next_pow {
        my ($x, $y) = @_;

        _valid($y);

        my $f = Rmpfr_init2($PREC);
        Rmpfr_set_z($f, _as_int($x), $PREC);
        Rmpfr_log($f, $f, $ROUND);

        my $f2 = Rmpfr_init2($PREC);
        Rmpfr_set_z($f2, _as_int($y), $PREC);
        Rmpfr_log($f2, $f2, $ROUND);

        Rmpfr_div($f, $f, $f2, $ROUND);
        Rmpfr_ceil($f, $f);

        my $ui = Rmpfr_get_ui($f, $ROUND);

        my $z = Rmpz_init();
        Rmpz_pow_ui($z, _as_int($y), $ui);
        _new(_mpz2rat($z));
    }

    *next_power = \&next_pow;

    sub shift_left {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_mul_2exp($r, _as_int($x), CORE::int(Rmpq_get_d($$y)));
        _new(_mpz2rat($r));
    }

    sub shift_right {
        my ($x, $y) = @_;
        _valid($y);
        my $r = Rmpz_init();
        Rmpz_div_2exp($r, _as_int($x), CORE::int(Rmpq_get_d($$y)));
        _new(_mpz2rat($r));
    }

    #
    ## Rational specific
    #

    sub numerator {
        my ($x) = @_;
        my $z = Rmpz_init();
        Rmpq_get_num($z, $$x);

        my $r = Rmpq_init();
        Rmpq_set_z($r, $z);
        _new($r);
    }

    *nu = \&numerator;

    sub denominator {
        my ($x) = @_;
        my $z = Rmpz_init();
        Rmpq_get_den($z, $$x);

        my $r = Rmpq_init();
        Rmpq_set_z($r, $z);
        _new($r);
    }

    *de = \&denominator;

    sub parts {
        my ($x) = @_;
        ($x->numerator, $x->denominator);
    }

    *nude = \&parts;

    #
    ## Conversion/Miscellaneous
    #

    sub chr {
        my ($x) = @_;
        Sidef::Types::String::String->new(CORE::chr(Rmpq_get_d($$x)));
    }

    sub complex {
        my ($x, $y) = @_;

        if (defined $y) {
            _valid($y);
            Sidef::Types::Number::Complex->new(Rmpq_get_d($$x), Rmpq_get_d($$y));
        }
        else {
            Sidef::Types::Number::Complex->new(Rmpq_get_d($$x));
        }
    }

    *c = \&complex;

    sub i {
        my ($x) = @_;
        Sidef::Types::Number::Complex->new(0, Rmpq_get_d($$x));
    }

    sub array_to {
        my ($x, $y, $step) = @_;

        my @array;
        if (not defined($step)) {

            _valid($y);

            foreach my $i (Rmpq_get_d($$x) .. Rmpq_get_d($$y)) {
                my $n = Rmpq_init();
                Rmpq_set_str($n, $i, 10);
                push @array, _new($n);
            }
        }
        else {

            _valid($y, $step);

            my $xq    = $$x;
            my $yq    = $$y;
            my $stepq = $$step;

            my $acc = Rmpq_init();
            Rmpq_set($acc, $xq);

            for (; Rmpq_cmp($acc, $yq) <= 0 ; Rmpq_add($acc, $acc, $stepq)) {
                my $copy = Rmpq_init();
                Rmpq_set($copy, $acc);
                push @array, _new($copy);
            }
        }

        Sidef::Types::Array::Array->new(@array);
    }

    *arr_to = \&array_to;

    sub array_downto {
        my ($x, $y, $step) = @_;

        if (not defined $step) {
            _valid($y);
            $step = ONE;
        }
        else {
            _valid($y, $step);
        }

        my $xq    = $$x;
        my $yq    = $$y;
        my $stepq = $$step;

        my $acc = Rmpq_init();
        Rmpq_set($acc, $xq);

        my @array;
        for (; Rmpq_cmp($acc, $yq) >= 0 ; Rmpq_sub($acc, $acc, $stepq)) {
            my $copy = Rmpq_init();
            Rmpq_set($copy, $acc);
            push @array, _new($copy);
        }

        Sidef::Types::Array::Array->new(@array);
    }

    # TODO: find a better solution which doesn't use Math::BigRat
    sub roundf {
        my ($x, $prec) = @_;
        _valid($prec);
        my $str = Rmpq_get_str($$x, 10);
        state $bigrat = _load_bigrat();
        $x->new(Math::BigRat->new($str)->as_float(CORE::length($str))->bfround(Rmpq_get_d($$prec))->bstr);
    }

    sub to {
        my ($from, $to, $step) = @_;

        if (defined $step) {
            _valid($to, $step);
        }
        else {
            _valid($to);
        }

        Sidef::Types::Range::RangeNumber->__new__(
                                                  from => $$from,
                                                  to   => $$to,
                                                  step => defined($step) ? $$step : ${(ONE)},
                                                 );
    }

    *upto = \&to;

    sub downto {
        my ($from, $to, $step) = @_;

        if (defined $step) {
            _valid($to, $step);
        }
        else {
            _valid($to);
        }

        $step = defined($step)
          ? do {
            my $r = Rmpq_init();
            Rmpq_neg($r, $$step);
            $r;
          }
          : ${(MONE)};

        Sidef::Types::Range::RangeNumber->__new__(
                                                  from => $$from,
                                                  to   => $$to,
                                                  step => $step,
                                                 );
    }

    sub rand {
        my ($x, $y) = @_;

        if (defined $y) {
            _valid($y);
            my $min = Rmpq_get_d($$x);
            $x->new($min + CORE::rand(Rmpq_get_d($$y) - $min));
        }
        else {
            $x->new(CORE::rand(Rmpq_get_d($$x)));
        }
    }

    sub rand_int {
        my ($x, $y) = @_;

        if (defined $y) {
            _valid($y);
            my $min = Rmpq_get_d($$x);
            $x->new(CORE::int($min + CORE::rand(Rmpq_get_d($$y) - $min)));
        }
        else {
            $x->new(CORE::int(CORE::rand(Rmpq_get_d($$x))));
        }
    }

    sub range {
        my ($from, $to, $step) = @_;

        defined($to)
          ? $from->to($to, $step)
          : (ZERO)->to($from->dec);
    }

    sub of {
        my ($x, $obj) = @_;
        ref($obj) eq 'Sidef::Types::Block::Block'
          ? Sidef::Types::Array::Array->new(map { $obj->run(_new_uint($_)) } 1 .. Rmpq_get_d($$x))
          : Sidef::Types::Array::Array->new(($obj) x Rmpq_get_d($$x));
    }

    sub times {
        my ($num, $block) = @_;

        $num = $$num;
        return $block if $num < 1;

        my $str = Rmpq_get_str($num, 10);

        if ($str eq '1/0') {
            my $i = 0;
            while (1) {
                if (defined(my $res = $block->_run_code(_new_uint(++$i)))) {
                    return $res;
                }
            }
        }
        elsif ($num < (-1 >> 1)) {
            foreach my $i (1 .. $num) {
                if (defined(my $res = $block->_run_code(_new_uint($i)))) {
                    return $res;
                }
            }
        }
        else {
            my $limit = Rmpz_init();
            Rmpz_set_q($limit, $num);

            for (my $i = Rmpz_init_set_ui(1) ; Rmpz_cmp($i, $num) <= 0 ; Rmpz_add_ui($i, $i, 1)) {
                my $n = Rmpq_init();
                Rmpq_set_z($n, $i);
                if (defined(my $res = $block->_run_code(_new($n)))) {
                    return $res;
                }
            }
        }

        $block;
    }

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
        *{__PACKAGE__ . '::' . '..'}  = \&array_to;
        *{__PACKAGE__ . '::' . '...'} = \&to;
        *{__PACKAGE__ . '::' . '..^'} = \&to;
        *{__PACKAGE__ . '::' . '^..'} = \&downto;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
        *{__PACKAGE__ . '::' . '%%'}  = \&is_div;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
        *{__PACKAGE__ . '::' . ':'}   = \&complex;
        *{__PACKAGE__ . '::' . '//'}  = \&rdiv;
    }
}

1
