package Sidef::Types::Number::Number {

    use utf8;
    use 5.014;

    use Math::GMPq qw();
    use Math::GMPz qw();
    use Math::MPFR qw();

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    our $ROUND = Math::MPFR::MPFR_RNDN();
    our $PREC  = 128;

    our $GET_PERL_VALUE = 0;

    use constant {
                  ONE  => bless(\Math::GMPq->new(1),  __PACKAGE__),
                  ZERO => bless(\Math::GMPq->new(0),  __PACKAGE__),
                  MONE => bless(\Math::GMPq->new(-1), __PACKAGE__),
                 };

    use overload
      q{bool} => sub { Math::GMPq::Rmpq_sgn(${$_[0]}) != 0 },
      q{0+}   => sub { Math::GMPq::Rmpq_get_d(${$_[0]}) },
      q{""}   => \&get_value;

    use Sidef::Types::Bool::Bool;

    sub _new {
        bless(\$_[0], __PACKAGE__);
    }

    sub _new_int {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_si($r, $_[0], 1);
        bless \$r, __PACKAGE__;
    }

    sub _new_uint {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($r, $_[0], 1);
        bless \$r, __PACKAGE__;
    }

    sub new {
        my (undef, $num, $base) = @_;

            ref($num) eq 'Math::GMPq' ? bless(\$num, __PACKAGE__)
          : ref($num) eq __PACKAGE__ ? $num
          : do {

            $base = defined($base) ? ref($base) ? $base->get_value : $base : 10;

            $num = $num->get_value
              if (index(ref($num), 'Sidef::') == 0);

            bless(\Math::GMPq->new($base == 10 ? _str2rat($num // 0) : ($num // 0), $base), __PACKAGE__);
          };
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
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_q($r, ${$_[0]}, $ROUND);
        $r;
    }

    sub _as_int {
        my $i = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($i, ${$_[0]});
        $i;
    }

    sub _mpfr2rat {

        $PREC = $PREC->get_value if ref($PREC);

        if (Math::MPFR::Rmpfr_inf_p($_[0])) {
            if (Math::MPFR::Rmpfr_sgn($_[0]) > 0) {
                return state $x = inf();
            }
            else {
                return state $x = ninf();
            }
        }

        if (Math::MPFR::Rmpfr_nan_p($_[0])) {
            return state $x = nan();
        }

        my $r = Math::GMPq::Rmpq_init();
        Math::MPFR::Rmpfr_get_q($r, $_[0]);
        bless \$r, __PACKAGE__;
    }

    sub _mpz2rat {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_z($r, $_[0]);
        bless \$r, __PACKAGE__;
    }

    sub _str2rat {
        my $str = lc($_[0]);

        my $sign = substr($str, 0, 1);
        if ($sign eq '-') {
            substr($str, 0, 1, '');
            $sign = '-';
        }
        else {
            substr($str, 0, 1, '') if ($sign eq '+');
            $sign = '';
        }

        my $i;
        if (($i = index($str, 'e')) != -1) {

            my $exp = substr($str, $i + 1);
            my ($before, $after) = split(/\./, substr($str, 0, $i));

            if (not defined($after)) {    # return faster for numbers like "13e2"
                if ($exp >= 0) {
                    return ("$sign$before" . ('0' x $exp));
                }
                else {
                    $after = '';
                }
            }

            my $numerator   = "$before$after";
            my $denominator = "1";

            if ($exp < 1) {
                $denominator .= '0' x (abs($exp) + length($after));
            }
            else {
                my $diff = ($exp - length($after));
                if ($diff >= 0) {
                    $numerator .= '0' x $diff;
                }
                else {
                    my $s = "$before$after";
                    substr($s, $exp + length($before), 0, '.');
                    return _str2rat("$sign$s");
                }
            }

            "$sign$numerator/$denominator";
        }
        elsif (($i = index($str, '.')) != -1) {
            my ($before, $after) = (substr($str, 0, $i), substr($str, $i + 1));
            if ($after =~ tr/0// == length($after)) {
                return "$sign$before";
            }
            $sign . ("$before$after/1" =~ s/^0+//r) . ('0' x length($after));
        }
        else {
            "$sign$str";
        }
    }

    sub get_value {
        $GET_PERL_VALUE ? Math::GMPq::Rmpq_get_d(${$_[0]}) : do {
            my $v = Math::GMPq::Rmpq_get_str(${$_[0]}, 10);

            if (index($v, '/') != -1) {
                my ($x) = @_;
                $PREC = "$$PREC" if ref($PREC);

                my $prec = CORE::int($PREC / 4);
                my $sgn  = Math::GMPq::Rmpq_sgn($$x);

                my $n = Math::GMPq::Rmpq_init();
                Math::GMPq::Rmpq_set($n, $$x);
                Math::GMPq::Rmpq_abs($n, $n) if $sgn < 0;

                my $z = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_ui_pow_ui($z, 10, CORE::abs($prec));

                my $p = Math::GMPq::Rmpq_init();
                Math::GMPq::Rmpq_set_z($p, $z);

                if ($prec < 0) {
                    Math::GMPq::Rmpq_div($n, $n, $p);
                }
                else {
                    Math::GMPq::Rmpq_mul($n, $n, $p);
                }

                state $half = do {
                    my $q = Math::GMPq::Rmpq_init();
                    Math::GMPq::Rmpq_set_ui($q, 1, 2);
                    $q;
                };

                Math::GMPq::Rmpq_add($n, $n, $half);
                Math::GMPz::Rmpz_set_q($z, $n);

                # Too much rounding... Give up and return an MPFR stringified number.
                Math::GMPz::Rmpz_sgn($z) || do {
                    my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
                    Math::MPFR::Rmpfr_set_q($mpfr, $$x, $ROUND);
                    return Math::MPFR::Rmpfr_get_str($mpfr, 10, $prec, $ROUND);
                };

                if (Math::GMPz::Rmpz_odd_p($z) and Math::GMPq::Rmpq_integer_p($n)) {
                    Math::GMPz::Rmpz_sub_ui($z, $z, 1);
                }

                Math::GMPq::Rmpq_set_z($n, $z);

                if ($prec < 0) {
                    Math::GMPq::Rmpq_mul($n, $n, $p);
                }
                else {
                    Math::GMPq::Rmpq_div($n, $n, $p);
                }

                my $num = Math::GMPz::Rmpz_init();
                my $den = Math::GMPz::Rmpz_init();

                Math::GMPq::Rmpq_get_num($num, $n);
                Math::GMPq::Rmpq_get_den($den, $n);

                my @r;
                my $c = 0;

                while (1) {

                    Math::GMPz::Rmpz_div($z, $num, $den);
                    push @r, Math::GMPz::Rmpz_get_str($z, 10);

                    Math::GMPz::Rmpz_mul($z, $z, $den);
                    last if Math::GMPz::Rmpz_divisible_p($num, $den);
                    Math::GMPz::Rmpz_sub($num, $num, $z);

                    my $s = -1;
                    while (Math::GMPz::Rmpz_cmp($den, $num) > 0) {
                        last if !Math::GMPz::Rmpz_sgn($num);
                        Math::GMPz::Rmpz_mul_ui($num, $num, 10);
                        ++$s;
                    }

                    push(@r, '0' x $s) if ($s > 0);
                }

                ($sgn < 0 ? "-" : '') . ((shift(@r) . '.' . join('', @r)) =~ s/0+\z//r =~ s/\.\z//r);
            }
            else {
                $v;
            }
          }
    }

    sub base {
        my ($x, $y) = @_;
        _valid($y);

        state $min = Math::GMPq->new(2);
        state $max = Math::GMPq->new(36);

        if (Math::GMPq::Rmpq_cmp($$y, $min) < 0 or Math::GMPq::Rmpq_cmp($$y, $max) > 0) {
            die "[ERROR] base must be between 2 and 36, got $$y\n";
        }

        Sidef::Types::String::String->new(Math::GMPq::Rmpq_get_str(${$_[0]}, $$y));
    }

    *in_base = \&base;

    sub _get_frac {
        Math::GMPq::Rmpq_get_str(${$_[0]}, 10);
    }

    sub _get_double {
        Math::GMPq::Rmpq_get_d(${$_[0]});
    }

    #
    ## Constants
    #

    sub pi {
        my $pi = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_const_pi($pi, $ROUND);
        _mpfr2rat($pi);
    }

    sub tau {
        my $tau = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_const_pi($tau, $ROUND);
        Math::MPFR::Rmpfr_mul_ui($tau, $tau, 2, $ROUND);
        _mpfr2rat($tau);
    }

    sub ln2 {
        my $ln2 = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_const_log2($ln2, $ROUND);
        _mpfr2rat($ln2);
    }

    sub Y {
        my $euler = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_const_euler($euler, $ROUND);
        _mpfr2rat($euler);
    }

    sub G {
        my $catalan = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_const_catalan($catalan, $ROUND);
        _mpfr2rat($catalan);
    }

    sub e {
        state $one_f = (Math::MPFR::Rmpfr_init_set_ui(1, $ROUND))[0];
        my $e = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_exp($e, $one_f, $ROUND);
        _mpfr2rat($e);
    }

    sub phi {
        state $one_f  = (Math::MPFR::Rmpfr_init_set_ui(1, $ROUND))[0];
        state $two_f  = (Math::MPFR::Rmpfr_init_set_ui(2, $ROUND))[0];
        state $five_f = (Math::MPFR::Rmpfr_init_set_ui(5, $ROUND))[0];

        my $phi = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sqrt($phi, $five_f, $ROUND);
        Math::MPFR::Rmpfr_add($phi, $phi, $one_f, $ROUND);
        Math::MPFR::Rmpfr_div($phi, $phi, $two_f, $ROUND);

        _mpfr2rat($phi);
    }

    sub nan  { state $x = Sidef::Types::Number::Nan->new }
    sub inf  { state $x = Sidef::Types::Number::Inf->new }
    sub ninf { state $x = Sidef::Types::Number::Ninf->new }

    #
    ## Rational operations
    #

    sub add {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Complex') {
            return $y->new($x)->add($y);
        }

        if (ref($y) eq 'Sidef::Types::Number::Inf' or ref($y) eq 'Sidef::Types::Number::Ninf') {
            return $y;
        }

        _valid($y);

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_add($r, $$x, $$y);
        bless \$r, __PACKAGE__;
    }

    sub sub {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Complex') {
            return $y->new($x)->sub($y);
        }

        if (ref($y) eq 'Sidef::Types::Number::Inf' or ref($y) eq 'Sidef::Types::Number::Ninf') {
            return $y->neg;
        }

        _valid($y);

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_sub($r, $$x, $$y);
        bless \$r, __PACKAGE__;
    }

    sub div {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Complex') {
            return $y->new($x)->div($y);
        }

        if (ref($y) eq 'Sidef::Types::Number::Inf' or ref($y) eq 'Sidef::Types::Number::Ninf') {
            return (ZERO);
        }

        _valid($y);

        if (!Math::GMPq::Rmpq_sgn($$y)) {
            my $sign = Math::GMPq::Rmpq_sgn($$x);
            return (!$sign ? nan() : $sign > 0 ? inf() : ninf());
        }

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_div($r, $$x, $$y);
        bless \$r, __PACKAGE__;
    }

    *rdiv = \&div;

    sub mul {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Complex') {
            return $y->mul($x);
        }

        if (ref($y) eq 'Sidef::Types::Number::Inf' or ref($y) eq 'Sidef::Types::Number::Ninf') {
            my $sign = Math::GMPq::Rmpq_sgn($$x);
            return ($sign < 0 ? $y->neg : $sign > 0 ? $y : nan());
        }

        _valid($y);

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul($r, $$x, $$y);
        bless \$r, __PACKAGE__;
    }

    sub neg {
        my ($x) = @_;
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_neg($r, $$x);
        bless \$r, __PACKAGE__;
    }

    *negative = \&neg;

    sub abs {
        my ($x) = @_;
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_abs($r, $$x);
        bless \$r, __PACKAGE__;
    }

    *pos      = \&abs;
    *positive = \&abs;

    sub inv {
        my ($x) = @_;

        # Return Inf when x is zero
        if (!Math::GMPq::Rmpq_sgn($$x)) {
            return inf();
        }

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_inv($r, $$x);
        bless \$r, __PACKAGE__;
    }

    sub sqrt {
        my ($x) = @_;

        # Return a complex number for x < 0
        if (Math::GMPq::Rmpq_sgn($$x) < 0) {
            return Sidef::Types::Number::Complex->new($x)->sqrt;
        }

        my $r = _as_float($x);
        Math::MPFR::Rmpfr_sqrt($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub cbrt {
        my ($x) = @_;

        # Return a complex number for x < 0
        if (Math::GMPq::Rmpq_sgn($$x) < 0) {
            return Sidef::Types::Number::Complex->new($x)->cbrt;
        }

        my $r = _as_float($x);
        Math::MPFR::Rmpfr_cbrt($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub root {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Complex') {
            return $y->new($x)->pow($y->inv);
        }

        if (ref($y) eq 'Sidef::Types::Number::Inf' or ref($y) eq 'Sidef::Types::Number::Ninf') {
            return (ONE);
        }

        _valid($y);
        return $x->pow($y->inv);
    }

    sub sqr {
        my ($x) = @_;
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul($r, $$x, $$x);
        bless \$r, __PACKAGE__;
    }

    sub pow {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Complex') {
            return $y->new($x)->pow($y);
        }

        if (ref($y) eq 'Sidef::Types::Number::Inf') {
            return $y;
        }
        elsif (ref($y) eq 'Sidef::Types::Number::Ninf') {
            return (ZERO);
        }

        _valid($y);

        if (Math::GMPq::Rmpq_integer_p($$x) and Math::GMPq::Rmpq_integer_p($$y)) {

            my $pow = Math::GMPq::Rmpq_get_d($$y);

            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $$x);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));

            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_z($q, $z);

            if ($pow < 0) {
                if (!Math::GMPq::Rmpq_sgn($q)) {
                    return inf();
                }
                Math::GMPq::Rmpq_inv($q, $q);
            }

            return bless \$q, __PACKAGE__;
        }

        if (Math::GMPq::Rmpq_sgn($$x) < 0 and !Math::GMPq::Rmpq_integer_p($$y)) {
            return Sidef::Types::Number::Complex->new($x)->pow($y);
        }

        my $r = _as_float($x);
        Math::MPFR::Rmpfr_pow($r, $r, _as_float($y), $ROUND);
        _mpfr2rat($r);
    }

    sub fmod {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_fmod($r, $r, _as_float($y), $ROUND);
        _mpfr2rat($r);
    }

    sub log {
        my ($x, $y) = @_;

        if (Math::GMPq::Rmpq_sgn($$x) < 0) {
            return Sidef::Types::Number::Complex->new($x)->log($y);
        }

        my $r = _as_float($x);
        Math::MPFR::Rmpfr_log($r, $r, $ROUND);

        if (defined $y) {

            if (ref($y) eq 'Sidef::Types::Number::Inf' or ref($y) eq 'Sidef::Types::Number::Ninf') {
                return (ZERO);
            }

            _valid($y);
            my $baseln = _as_float($y);
            Math::MPFR::Rmpfr_log($baseln, $baseln, $ROUND);
            Math::MPFR::Rmpfr_div($r, $r, $baseln, $ROUND);
        }

        _mpfr2rat($r);
    }

    sub ln {
        my ($x) = @_;

        if (Math::GMPq::Rmpq_sgn($$x) < 0) {
            return Sidef::Types::Number::Complex->new($x)->ln;
        }

        my $r = _as_float($x);
        Math::MPFR::Rmpfr_log($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub log2 {
        my ($x) = @_;

        if (Math::GMPq::Rmpq_sgn($$x) < 0) {
            return Sidef::Types::Number::Complex->new($x)->log2;
        }

        my $r = _as_float($x);
        Math::MPFR::Rmpfr_log2($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub log10 {
        my ($x) = @_;

        if (Math::GMPq::Rmpq_sgn($$x) < 0) {
            return Sidef::Types::Number::Complex->new($x)->log10;
        }

        my $r = _as_float($x);
        Math::MPFR::Rmpfr_log10($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub exp {
        my $r = _as_float($_[0]);
        Math::MPFR::Rmpfr_exp($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub exp2 {
        my $r = _as_float($_[0]);
        Math::MPFR::Rmpfr_exp2($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub exp10 {
        my $r = _as_float($_[0]);
        Math::MPFR::Rmpfr_exp10($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    #
    ## Trigonometric functions
    #

    sub sin {
        my $r = _as_float($_[0]);
        Math::MPFR::Rmpfr_sin($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub asin {
        my ($x) = @_;

        # Return a complex number for x < -1 or x > 1
        if (Math::GMPq::Rmpq_cmp_ui($$x, 1, 1) > 0 or Math::GMPq::Rmpq_cmp_si($$x, -1, 1) < 0) {
            return Sidef::Types::Number::Complex->new($x)->asin;
        }

        my $r = _as_float($x);
        Math::MPFR::Rmpfr_asin($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub sinh {
        my $r = _as_float($_[0]);
        Math::MPFR::Rmpfr_sinh($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub asinh {
        my $r = _as_float($_[0]);
        Math::MPFR::Rmpfr_asinh($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub cos {
        my $r = _as_float($_[0]);
        Math::MPFR::Rmpfr_cos($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub acos {
        my ($x) = @_;

        # Return a complex number for x < -1 or x > 1
        if (Math::GMPq::Rmpq_cmp_ui($$x, 1, 1) > 0 or Math::GMPq::Rmpq_cmp_si($$x, -1, 1) < 0) {
            return Sidef::Types::Number::Complex->new($x)->acos;
        }

        my $r = _as_float($x);
        Math::MPFR::Rmpfr_acos($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub cosh {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_cosh($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub acosh {
        my ($x) = @_;

        # Return a complex number for x < 1
        if (Math::GMPq::Rmpq_cmp_ui($$x, 1, 1) < 0) {
            return Sidef::Types::Number::Complex->new($x)->acosh;
        }

        my $r = _as_float($x);
        Math::MPFR::Rmpfr_acosh($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub tan {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_tan($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub atan {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_atan($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub tanh {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_tanh($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub atanh {
        my ($x) = @_;

        # Return a complex number for x <= -1 or x >= 1
        if (Math::GMPq::Rmpq_cmp_ui($$x, 1, 1) >= 0 or Math::GMPq::Rmpq_cmp_si($$x, -1, 1) <= 0) {
            return Sidef::Types::Number::Complex->new($x)->atanh;
        }

        my $r = _as_float($x);
        Math::MPFR::Rmpfr_atanh($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub sec {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_sec($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    #
    ## asec(x) = acos(1/x)
    #
    sub asec {
        my ($x) = @_;

        # Return a complex number for x > -1 and x < 1
        if (Math::GMPq::Rmpq_cmp_ui($$x, 1, 1) < 0 and Math::GMPq::Rmpq_cmp_si($$x, -1, 1) > 0) {
            return Sidef::Types::Number::Complex->new($x)->asec;
        }

        state $one = Math::MPFR->new(1);
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_div($r, $one, $r, $ROUND);
        Math::MPFR::Rmpfr_acos($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub sech {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_sech($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    #
    ## asech(x) = acosh(1/x)
    #
    sub asech {
        my ($x) = @_;

        # Return a complex number for x < 0 or x > 1
        if (Math::GMPq::Rmpq_cmp_ui($$x, 1, 1) > 0 or Math::GMPq::Rmpq_cmp_ui($$x, 0, 1) < 0) {
            return Sidef::Types::Number::Complex->new($x)->asech;
        }

        state $one = Math::MPFR->new(1);
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_div($r, $one, $r, $ROUND);
        Math::MPFR::Rmpfr_acosh($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub csc {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_csc($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    #
    ## acsc(x) = asin(1/x)
    #
    sub acsc {
        my ($x) = @_;

        # Return a complex number for x > -1 and x < 1
        if (Math::GMPq::Rmpq_cmp_ui($$x, 1, 1) < 0 and Math::GMPq::Rmpq_cmp_si($$x, -1, 1) > 0) {
            return Sidef::Types::Number::Complex->new($x)->acsc;
        }

        state $one = Math::MPFR->new(1);
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_div($r, $one, $r, $ROUND);
        Math::MPFR::Rmpfr_asin($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub csch {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_csch($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    #
    ## acsch(x) = asinh(1/x)
    #
    sub acsch {
        my ($x) = @_;
        state $one = Math::MPFR->new(1);
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_div($r, $one, $r, $ROUND);
        Math::MPFR::Rmpfr_asinh($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub cot {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_cot($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    #
    ## acot(x) = atan(1/x)
    #
    sub acot {
        my ($x) = @_;
        state $one = Math::MPFR->new(1);
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_div($r, $one, $r, $ROUND);
        Math::MPFR::Rmpfr_atan($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub coth {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_coth($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    #
    ## acoth(x) = atanh(1/x)
    #
    sub acoth {
        my ($x) = @_;
        state $one = Math::MPFR->new(1);
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_div($r, $one, $r, $ROUND);
        Math::MPFR::Rmpfr_atanh($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub atan2 {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Inf') {
            return (ZERO);
        }
        elsif (ref($y) eq 'Sidef::Types::Number::Ninf') {
            if (Math::GMPq::Rmpq_sgn($$x) >= 0) {
                return pi();
            }
            else {
                return pi()->neg;
            }
        }

        _valid($y);
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_atan2($r, $r, _as_float($y), $ROUND);
        _mpfr2rat($r);
    }

    #
    ## Special functions
    #

    sub agm {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_agm($r, $r, _as_float($y), $ROUND);
        _mpfr2rat($r);
    }

    sub hypot {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_hypot($r, $r, _as_float($y), $ROUND);
        _mpfr2rat($r);
    }

    sub gamma {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_gamma($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub lngamma {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_lngamma($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub lgamma {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_lgamma($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub digamma {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_digamma($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub zeta {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_zeta($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub erf {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_erf($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub erfc {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_erfc($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub eint {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_eint($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    sub li2 {
        my ($x) = @_;
        my $r = _as_float($x);
        Math::MPFR::Rmpfr_li2($r, $r, $ROUND);
        _mpfr2rat($r);
    }

    #
    ## Comparison and testing operations
    #

    sub eq {
        my ($x, $y) = @_;
        _valid($y);
        if (Math::GMPq::Rmpq_equal($$x, $$y)) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub ne {
        my ($x, $y) = @_;
        _valid($y);
        if (Math::GMPq::Rmpq_equal($$x, $$y)) {
            (Sidef::Types::Bool::Bool::FALSE);
        }
        else {
            (Sidef::Types::Bool::Bool::TRUE);
        }
    }

    sub cmp {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Inf') {
            return (MONE);
        }
        elsif (ref($y) eq 'Sidef::Types::Number::Ninf') {
            return (ONE);
        }

        _valid($y);
        my $cmp = Math::GMPq::Rmpq_cmp($$x, $$y);
        !$cmp ? (ZERO) : $cmp < 0 ? (MONE) : (ONE);
    }

    sub acmp {
        my ($x, $y) = @_;

        _valid($y);

        my $xn = $$x;
        my $yn = $$y;

        if (Math::GMPq::Rmpq_sgn($xn) < 0) {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_abs($r, $xn);
            $xn = $r;
        }

        if (Math::GMPq::Rmpq_sgn($yn) < 0) {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_abs($r, $yn);
            $yn = $r;
        }

        my $cmp = Math::GMPq::Rmpq_cmp($xn, $yn);
        !$cmp ? (ZERO) : $cmp < 0 ? (MONE) : (ONE);
    }

    sub gt {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Inf') {
            return (Sidef::Types::Bool::Bool::FALSE);
        }
        elsif (ref($y) eq 'Sidef::Types::Number::Ninf') {
            return (Sidef::Types::Bool::Bool::TRUE);
        }

        _valid($y);

        if (Math::GMPq::Rmpq_cmp($$x, $$y) > 0) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub ge {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Inf') {
            return (Sidef::Types::Bool::Bool::FALSE);
        }
        elsif (ref($y) eq 'Sidef::Types::Number::Ninf') {
            return (Sidef::Types::Bool::Bool::TRUE);
        }

        _valid($y);

        if (Math::GMPq::Rmpq_cmp($$x, $$y) >= 0) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub lt {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Inf') {
            return (Sidef::Types::Bool::Bool::TRUE);
        }
        elsif (ref($y) eq 'Sidef::Types::Number::Ninf') {
            return (Sidef::Types::Bool::Bool::FALSE);
        }

        _valid($y);

        if (Math::GMPq::Rmpq_cmp($$x, $$y) < 0) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub le {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Inf') {
            return (Sidef::Types::Bool::Bool::TRUE);
        }
        elsif (ref($y) eq 'Sidef::Types::Number::Ninf') {
            return (Sidef::Types::Bool::Bool::FALSE);
        }

        _valid($y);

        if (Math::GMPq::Rmpq_cmp($$x, $$y) <= 0) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub is_zero {
        my ($x) = @_;
        if (!Math::GMPq::Rmpq_sgn($$x)) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub is_one {
        my ($x) = @_;
        if (Math::GMPq::Rmpq_equal($$x, ${(ONE)})) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub is_positive {
        my ($x) = @_;
        if (Math::GMPq::Rmpq_sgn($$x) > 0) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    *is_pos = \&is_positive;

    sub is_negative {
        my ($x) = @_;
        if (Math::GMPq::Rmpq_sgn($$x) < 0) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    *is_neg = \&is_negative;

    sub sign {
        my ($x) = @_;
        my $sign = Math::GMPq::Rmpq_sgn($$x);
        if ($sign > 0) {
            state $z = Sidef::Types::String::String->new('+');
        }
        elsif (!$sign) {
            state $z = Sidef::Types::String::String->new('');
        }
        else {
            state $z = Sidef::Types::String::String->new('-');
        }
    }

    sub is_int {
        my ($x) = @_;
        if (Math::GMPq::Rmpq_integer_p($$x)) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub is_real {
        my ($x) = @_;
        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub is_even {
        my ($x) = @_;

        if (!Math::GMPq::Rmpq_integer_p($$x)) {
            return (Sidef::Types::Bool::Bool::FALSE);
        }

        my $nz = Math::GMPz::Rmpz_init();
        Math::GMPq::Rmpq_get_num($nz, $$x);

        if (Math::GMPz::Rmpz_even_p($nz)) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub is_odd {
        my ($x) = @_;

        if (!Math::GMPq::Rmpq_integer_p($$x)) {
            return (Sidef::Types::Bool::Bool::FALSE);
        }

        my $nz = Math::GMPz::Rmpz_init();
        Math::GMPq::Rmpq_get_num($nz, $$x);

        if (Math::GMPz::Rmpz_odd_p($nz)) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub is_div {
        my ($x, $y) = @_;
        _valid($y);

        return Sidef::Types::Bool::Bool::FALSE
          if Math::GMPq::Rmpq_sgn($$y) == 0;

        #---------------------------------------------------------------------------------
        ## Optimization for integers, but it turns out to be slower for small integers...
        #---------------------------------------------------------------------------------
        #~ if (Math::GMPq::Rmpq_integer_p($$x) and Math::GMPq::Rmpq_integer_p($$y)) {
        #~     if (Math::GMPz::Rmpz_divisible_p(_as_int($x), _as_int($y))) {
        #~         return (Sidef::Types::Bool::Bool::TRUE);
        #~     }
        #~     else {
        #~         return (Sidef::Types::Bool::Bool::FALSE);
        #~     }
        #~ }

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_div($q, $$x, $$y);

        if (Math::GMPq::Rmpq_integer_p($q)) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub divides {
        my ($x, $y) = @_;
        _valid($y);

        return Sidef::Types::Bool::Bool::FALSE
          if Math::GMPq::Rmpq_sgn($$x) == 0;

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_div($q, $$y, $$x);

        if (Math::GMPq::Rmpq_integer_p($q)) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub is_inf {
        (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_nan {
        (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_ninf {
        (Sidef::Types::Bool::Bool::FALSE);
    }

    sub max {
        my ($x, $y) = @_;
        _valid($y);
        Math::GMPq::Rmpq_cmp($$x, $$y) > 0 ? $x : $y;
    }

    sub min {
        my ($x, $y) = @_;
        _valid($y);
        Math::GMPq::Rmpq_cmp($$x, $$y) < 0 ? $x : $y;
    }

    sub int {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, ${$_[0]});
        _mpz2rat($z);
    }

    sub float {
        my $f = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_q($f, ${$_[0]}, $ROUND);
        _mpfr2rat($f);
    }

    sub rat { $_[0] }

    sub as_int {
        my ($x, $base) = @_;

        if (defined $base) {
            _valid($base);
            $base = CORE::int(Math::GMPq::Rmpq_get_d($$base));
            if ($base < 2 or $base > 36) {
                die "[ERROR] base must be between 2 and 36, got $base\n";
            }
        }
        else {
            $base = 10;
        }

        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $$x);
        Sidef::Types::String::String->new(Math::GMPz::Rmpz_get_str($z, $base));
    }

    sub as_float {
        my ($x, $prec) = @_;

        if (defined $prec) {
            _valid($prec);
            $prec = Math::GMPq::Rmpq_get_d($$prec);
        }
        else {
            $prec = $Sidef::Types::Number::Number::PREC / 4;
        }

        local $Sidef::Types::Number::Number::PREC = 4 * $prec;
        Sidef::Types::String::String->new($x->get_value);
    }

    sub as_rat {
        Sidef::Types::String::String->new(Math::GMPq::Rmpq_get_str(${$_[0]}, 10));
    }

    *dump = \&as_rat;

    sub as_bin {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, ${$_[0]});
        Sidef::Types::String::String->new(Math::GMPz::Rmpz_get_str($z, 2));
    }

    sub as_oct {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, ${$_[0]});
        Sidef::Types::String::String->new(Math::GMPz::Rmpz_get_str($z, 8));
    }

    sub as_hex {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, ${$_[0]});
        Sidef::Types::String::String->new(Math::GMPz::Rmpz_get_str($z, 16));
    }

    sub digits {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, ${$_[0]});
        Math::GMPz::Rmpz_abs($z, $z);
        Sidef::Types::Array::Array->new(map { _new_uint($_) } split(//, Math::GMPz::Rmpz_get_str($z, 10)));
    }

    sub digit {
        my ($x, $y) = @_;
        _valid($y);
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $$x);
        Math::GMPz::Rmpz_abs($z, $z);
        my $digit = (split(//, Math::GMPz::Rmpz_get_str($z, 10)))[Math::GMPq::Rmpq_get_d($$y)];
        defined($digit) ? _new_uint($digit) : (MONE);
    }

    sub length {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, ${$_[0]});
        Math::GMPz::Rmpz_abs($z, $z);

        #_new_uint(Math::GMPz::Rmpz_sizeinbase($z, 10));        # turns out to be inexact
        _new_uint(Math::GMPz::Rmpz_snprintf(my $buf, 0, "%Zd", $z, 0));
    }

    *len  = \&length;
    *size = \&length;

    sub floor {
        my ($x) = @_;
        Math::GMPq::Rmpq_integer_p($$x) && return $x;

        if (Math::GMPq::Rmpq_sgn($$x) > 0) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $$x);
            _mpz2rat($z);
        }
        else {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $$x);
            Math::GMPz::Rmpz_sub_ui($z, $z, 1);
            _mpz2rat($z);
        }
    }

    sub ceil {
        my ($x) = @_;
        Math::GMPq::Rmpq_integer_p($$x) && return $x;

        if (Math::GMPq::Rmpq_sgn($$x) > 0) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $$x);
            Math::GMPz::Rmpz_add_ui($z, $z, 1);
            _mpz2rat($z);
        }
        else {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $$x);
            _mpz2rat($z);
        }
    }

    sub inc {
        my ($x) = @_;
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_add($r, $$x, ${(ONE)});
        bless \$r, __PACKAGE__;
    }

    sub dec {
        my ($x) = @_;
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_sub($r, $$x, ${(ONE)});
        bless \$r, __PACKAGE__;
    }

    #
    ## Integer operations
    #

    sub iadd {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        Math::GMPz::Rmpz_add($r, $r, _as_int($y));
        _mpz2rat($r);
    }

    sub isub {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        Math::GMPz::Rmpz_sub($r, $r, _as_int($y));
        _mpz2rat($r);
    }

    sub imul {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        Math::GMPz::Rmpz_mul($r, $r, _as_int($y));
        _mpz2rat($r);
    }

    sub idiv {
        my ($x, $y) = @_;
        _valid($y);

        if (!Math::GMPq::Rmpq_sgn($$y)) {
            my $sign = Math::GMPq::Rmpq_sgn($$x);
            return (!$sign ? nan() : $sign > 0 ? inf() : ninf());
        }

        my $r = _as_int($x);
        Math::GMPz::Rmpz_div($r, $r, _as_int($y));
        _mpz2rat($r);
    }

    sub isqrt {
        my ($x)    = @_;
        my $r      = _as_int($x);
        my $is_neg = Math::GMPz::Rmpz_sgn($r) < 0;
        Math::GMPz::Rmpz_abs($r, $r) if $is_neg;
        Math::GMPz::Rmpz_sqrt($r, $r);

        $is_neg
          ? Sidef::Types::Number::Complex->new(0, _mpz2rat($r))
          : _mpz2rat($r);
    }

    sub iroot {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Inf' or ref($y) eq 'Sidef::Types::Number::Ninf') {
            return (ONE);
        }

        _valid($y);

        my $r    = _as_int($x);
        my $root = CORE::int(Math::GMPq::Rmpq_get_d($$y));

        my ($is_even, $is_neg) = $root % 2 == 0;
        ($is_neg = Math::GMPz::Rmpz_sgn($r) < 0) if $is_even;
        Math::GMPz::Rmpz_abs($r, $r) if ($is_even && $is_neg);
        Math::GMPz::Rmpz_root($r, $r, $root);

        $is_even && $is_neg
          ? Sidef::Types::Number::Complex->new(0, _mpz2rat($r))
          : _mpz2rat($r);
    }

    sub mod {
        my ($x, $y) = @_;
        _valid($y);

        if (Math::GMPq::Rmpq_integer_p($$x) and Math::GMPq::Rmpq_integer_p($$y)) {

            my $yz     = _as_int($y);
            my $sign_y = Math::GMPz::Rmpz_sgn($yz);
            return nan() if !$sign_y;

            my $r = _as_int($x);
            Math::GMPz::Rmpz_mod($r, $r, $yz);
            if (!Math::GMPz::Rmpz_sgn($r)) {
                return (ZERO);
            }
            elsif ($sign_y < 0) {
                Math::GMPz::Rmpz_add($r, $r, $yz);
            }
            _mpz2rat($r);
        }
        else {
            my $r  = _as_float($x);
            my $yf = _as_float($y);
            Math::MPFR::Rmpfr_fmod($r, $r, $yf, $ROUND);
            my $sign = Math::MPFR::Rmpfr_sgn($r);
            if (!$sign) {
                return (ZERO);
            }
            elsif ($sign > 0 xor Math::MPFR::Rmpfr_sgn($yf) > 0) {
                Math::MPFR::Rmpfr_add($r, $r, $yf, $ROUND);
            }
            _mpfr2rat($r);
        }
    }

    sub modpow {
        my ($x, $y, $z) = @_;
        _valid($y, $z);
        my $r = _as_int($x);
        Math::GMPz::Rmpz_powm($r, $r, _as_int($y), _as_int($z));
        _mpz2rat($r);
    }

    *expmod = \&modpow;

    sub modinv {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        Math::GMPz::Rmpz_invert($r, $r, _as_int($y)) || return nan();
        _mpz2rat($r);
    }

    *invmod = \&modinv;

    sub divmod {
        my ($x, $y) = @_;

        _valid($y);

        my $r1 = _as_int($x);
        my $r2 = _as_int($y);

        return (nan(), nan()) if !Math::GMPz::Rmpz_sgn($r2);

        Math::GMPz::Rmpz_divmod($r1, $r2, $r1, $r2);
        (_mpz2rat($r1), _mpz2rat($r2));
    }

    sub and {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        Math::GMPz::Rmpz_and($r, $r, _as_int($y));
        _mpz2rat($r);
    }

    sub or {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        Math::GMPz::Rmpz_ior($r, $r, _as_int($y));
        _mpz2rat($r);
    }

    sub xor {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        Math::GMPz::Rmpz_xor($r, $r, _as_int($y));
        _mpz2rat($r);
    }

    sub not {
        my ($x) = @_;
        my $r = _as_int($x);
        Math::GMPz::Rmpz_com($r, $r);
        _mpz2rat($r);
    }

    sub factorial {
        my ($x) = @_;
        return nan() if Math::GMPq::Rmpq_sgn($$x) < 0;
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fac_ui($r, CORE::int(Math::GMPq::Rmpq_get_d($$x)));
        _mpz2rat($r);
    }

    *fac = \&factorial;

    sub double_factorial {
        my ($x) = @_;
        return nan() if Math::GMPq::Rmpq_sgn($$x) < 0;
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_2fac_ui($r, CORE::int(Math::GMPq::Rmpq_get_d($$x)));
        _mpz2rat($r);
    }

    *dfac = \&double_factorial;

    sub primorial {
        my ($x) = @_;
        return nan() if Math::GMPq::Rmpq_sgn($$x) < 0;
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_primorial_ui($r, CORE::int(Math::GMPq::Rmpq_get_d($$x)));
        _mpz2rat($r);
    }

    sub fibonacci {
        my ($x) = @_;
        return nan() if Math::GMPq::Rmpq_sgn($$x) < 0;
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fib_ui($r, CORE::int(Math::GMPq::Rmpq_get_d($$x)));
        _mpz2rat($r);
    }

    *fib = \&fibonacci;

    sub binomial {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        Math::GMPz::Rmpz_bin_si($r, $r, CORE::int(Math::GMPq::Rmpq_get_d($$y)));
        _mpz2rat($r);
    }

    *nok = \&binomial;

    sub legendre {
        my ($x, $y) = @_;
        _valid($y);
        _new_int(Math::GMPz::Rmpz_legendre(_as_int($x), _as_int($y)));
    }

    sub jacobi {
        my ($x, $y) = @_;
        _valid($y);
        _new_int(Math::GMPz::Rmpz_jacobi(_as_int($x), _as_int($y)));
    }

    sub kronecker {
        my ($x, $y) = @_;
        _valid($y);
        _new_int(Math::GMPz::Rmpz_kronecker(_as_int($x), _as_int($y)));
    }

    sub lucas {
        my ($x) = @_;
        return nan() if Math::GMPq::Rmpq_sgn($$x) < 0;
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_lucnum_ui($r, CORE::int(Math::GMPq::Rmpq_get_d($$x)));
        _mpz2rat($r);
    }

    sub gcd {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        Math::GMPz::Rmpz_gcd($r, $r, _as_int($y));
        _mpz2rat($r);
    }

    sub lcm {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        Math::GMPz::Rmpz_lcm($r, $r, _as_int($y));
        _mpz2rat($r);
    }

    # By default, the test is correct up to a maximum value of 341,550,071,728,320
    # See: https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test#Deterministic_variants_of_the_test
    sub is_prime {
        my ($x, $k) = @_;
        if (
            Math::GMPz::Rmpz_probab_prime_p(_as_int($x), defined($k)
                                            ? do { _valid($k); CORE::int Math::GMPq::Rmpq_get_d($$k) }
                                            : 7) > 0
          ) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub next_prime {
        my ($x) = @_;
        my $r = _as_int($x);
        Math::GMPz::Rmpz_nextprime($r, $r);
        _mpz2rat($r);
    }

    sub is_square {
        my ($x) = @_;

        if (!Math::GMPq::Rmpq_integer_p($$x)) {
            return (Sidef::Types::Bool::Bool::FALSE);
        }

        my $nz = Math::GMPz::Rmpz_init();
        Math::GMPq::Rmpq_get_num($nz, $$x);

        if (Math::GMPz::Rmpz_perfect_square_p($nz)) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    *is_sqr = \&is_square;

    sub is_power {
        my ($x) = @_;

        if (!Math::GMPq::Rmpq_integer_p($$x)) {
            return (Sidef::Types::Bool::Bool::FALSE);
        }

        my $nz = Math::GMPz::Rmpz_init();
        Math::GMPq::Rmpq_get_num($nz, $$x);

        if (Math::GMPz::Rmpz_perfect_power_p($nz)) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    *is_pow = \&is_power;

    sub next_pow2 {
        my ($x) = @_;

        state $one_z = Math::GMPz::Rmpz_init_set_ui(1);

        my $f = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_z($f, _as_int($x), $PREC);
        Math::MPFR::Rmpfr_log2($f, $f, $ROUND);
        Math::MPFR::Rmpfr_ceil($f, $f);

        my $ui = Math::MPFR::Rmpfr_get_ui($f, $ROUND);

        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul_2exp($z, $one_z, $ui);
        _mpz2rat($z);
    }

    *next_power2 = \&next_pow2;

    sub next_pow {
        my ($x, $y) = @_;

        _valid($y);

        my $f = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_z($f, _as_int($x), $PREC);
        Math::MPFR::Rmpfr_log($f, $f, $ROUND);

        my $f2 = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_z($f2, _as_int($y), $PREC);
        Math::MPFR::Rmpfr_log($f2, $f2, $ROUND);

        Math::MPFR::Rmpfr_div($f, $f, $f2, $ROUND);
        Math::MPFR::Rmpfr_ceil($f, $f);

        my $ui = Math::MPFR::Rmpfr_get_ui($f, $ROUND);

        my $z = _as_int($y);
        Math::GMPz::Rmpz_pow_ui($z, $z, $ui);
        _mpz2rat($z);
    }

    *next_power = \&next_pow;

    sub shift_left {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        my $i = CORE::int(Math::GMPq::Rmpq_get_d($$y));
        if ($i < 0) {
            Math::GMPz::Rmpz_div_2exp($r, $r, CORE::abs($i));
        }
        else {
            Math::GMPz::Rmpz_mul_2exp($r, $r, $i);
        }
        _mpz2rat($r);
    }

    sub shift_right {
        my ($x, $y) = @_;
        _valid($y);
        my $r = _as_int($x);
        my $i = CORE::int(Math::GMPq::Rmpq_get_d($$y));
        if ($i < 0) {
            Math::GMPz::Rmpz_mul_2exp($r, $r, CORE::abs($i));
        }
        else {
            Math::GMPz::Rmpz_div_2exp($r, $r, $i);
        }
        _mpz2rat($r);
    }

    #
    ## Rational specific
    #

    sub numerator {
        my ($x) = @_;
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPq::Rmpq_get_num($z, $$x);

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_z($r, $z);
        bless \$r, __PACKAGE__;
    }

    *nu = \&numerator;

    sub denominator {
        my ($x) = @_;
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPq::Rmpq_get_den($z, $$x);

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_z($r, $z);
        bless \$r, __PACKAGE__;
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
        Sidef::Types::String::String->new(CORE::chr(Math::GMPq::Rmpq_get_d($$x)));
    }

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
        state $i = Sidef::Types::Number::Complex->i;
        $i->mul($x);
    }

    sub array_to {
        my ($from, $to, $step) = @_;

        if (!defined($step)) {
            _valid($to);
            $step = (ONE);
        }
        else {
            _valid($to, $step);
        }

        $from = $$from;
        $to   = $$to;
        $step = $$step;

        my $acc   = Math::GMPq::Rmpq_init();
        my $array = Sidef::Types::Array::Array->new;
        for (Math::GMPq::Rmpq_set($acc, $from) ;
             Math::GMPq::Rmpq_cmp($acc, $to) <= 0 ; Math::GMPq::Rmpq_add($acc, $acc, $step)) {
            my $copy = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set($copy, $acc);
            push @$array, bless(\$copy, __PACKAGE__);
        }

        $array;
    }

    *arr_to = \&array_to;

    sub array_downto {
        my ($from, $to, $step) = @_;

        if (!defined($step)) {
            _valid($to);
            $step = (ONE);
        }
        else {
            _valid($to, $step);
        }

        $from = $$from;
        $to   = $$to;
        $step = $$step;

        my $acc   = Math::GMPq::Rmpq_init();
        my $array = Sidef::Types::Array::Array->new;
        for (Math::GMPq::Rmpq_set($acc, $from) ;
             Math::GMPq::Rmpq_cmp($acc, $to) >= 0 ; Math::GMPq::Rmpq_sub($acc, $acc, $step)) {
            my $copy = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set($copy, $acc);
            push @$array, bless(\$copy, __PACKAGE__);
        }

        $array;
    }

    *arr_downto = \&array_downto;

    sub round {
        my ($x, $prec) = @_;
        _valid($prec);

        my $nth = -CORE::int(Math::GMPq::Rmpq_get_d($$prec));
        my $sgn = Math::GMPq::Rmpq_sgn($$x);

        my $n = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set($n, $$x);
        Math::GMPq::Rmpq_abs($n, $n) if $sgn < 0;

        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_ui_pow_ui($z, 10, CORE::abs($nth));

        my $p = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_z($p, $z);

        if ($nth < 0) {
            Math::GMPq::Rmpq_div($n, $n, $p);
        }
        else {
            Math::GMPq::Rmpq_mul($n, $n, $p);
        }

        state $half = do {
            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_ui($q, 1, 2);
            $q;
        };

        Math::GMPq::Rmpq_add($n, $n, $half);
        Math::GMPz::Rmpz_set_q($z, $n);

        if (Math::GMPz::Rmpz_odd_p($z) and Math::GMPq::Rmpq_integer_p($n)) {
            Math::GMPz::Rmpz_sub_ui($z, $z, 1);
        }

        Math::GMPq::Rmpq_set_z($n, $z);

        if ($nth < 0) {
            Math::GMPq::Rmpq_mul($n, $n, $p);
        }
        else {
            Math::GMPq::Rmpq_div($n, $n, $p);
        }

        if ($sgn < 0) {
            Math::GMPq::Rmpq_neg($n, $n);
        }

        bless \$n, __PACKAGE__;
    }

    *roundf = \&round;

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
                                                  step => (defined($step) ? $$step : ${(ONE)}),
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

        Sidef::Types::Range::RangeNumber->__new__(
                                                  from => $$from,
                                                  to   => $$to,
                                                  step => (defined($step) ? -$$step : ${(MONE)}),
                                                 );
    }

    sub range {
        my ($from, $to, $step) = @_;

        defined($to)
          ? $from->to($to, $step)
          : (ZERO)->to($from->dec);
    }

    sub rand {
        my ($x, $y) = @_;

        state $state = Math::MPFR::Rmpfr_randinit_mt();
        state $seed  = do {
            my $seed = srand();
            Math::MPFR::Rmpfr_randseed_ui($state, $seed);
        };

        my $rand = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_urandom($rand, $state, $ROUND);

        my $q = Math::GMPq::Rmpq_init();
        Math::MPFR::Rmpfr_get_q($q, $rand);

        if (defined $y) {
            _valid($y);

            my $diff = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_sub($diff, $$y, $$x);
            Math::GMPq::Rmpq_mul($q, $q, $diff);
            Math::GMPq::Rmpq_add($q, $q, $$x);
        }
        else {
            Math::GMPq::Rmpq_mul($q, $q, $$x);
        }

        bless \$q, __PACKAGE__;
    }

    sub rand_int {
        my ($x, $y) = @_;

        if (defined $y) {
            _valid($y);
            my $min = Math::GMPq::Rmpq_get_d($$x);
            _new_int(CORE::int($min + CORE::rand(Math::GMPq::Rmpq_get_d($$y) - $min)));
        }
        else {
            _new_int(CORE::int(CORE::rand(Math::GMPq::Rmpq_get_d($$x))));
        }
    }

    *irand = \&rand_int;

    sub of {
        my ($x, $obj) = @_;
        ref($obj) eq 'Sidef::Types::Block::Block'
          ? Sidef::Types::Array::Array->new(map { $obj->run(_new_uint($_)) } 1 .. Math::GMPq::Rmpq_get_d($$x))
          : Sidef::Types::Array::Array->new(($obj) x Math::GMPq::Rmpq_get_d($$x));
    }

    sub times {
        my ($num, $block) = @_;

        $num = $$num;
        return $block if Math::GMPq::Rmpq_cmp($num, ${(ONE)}) < 0;

        for (my $i = Math::GMPz::Rmpz_init_set_ui(1) ;
             Math::GMPz::Rmpz_cmp($i, $num) <= 0 ; Math::GMPz::Rmpz_add_ui($i, $i, 1)) {
            my $n = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_z($n, $i);
            if (defined(my $res = $block->_run_code(bless(\$n, __PACKAGE__)))) {
                return $res;
            }
        }

        $block;
    }

    sub commify {
        my ($self) = @_;

        my $n = $self->get_value;

        my $x   = $n;
        my $neg = $n =~ s{^-}{};
        $n =~ /\.|$/;

        if ($-[0] > 3) {

            my $l = $-[0] - 3;
            my $i = ($l - 1) % 3 + 1;

            $x = substr($n, 0, $i) . ',';

            while ($i < $l) {
                $x .= substr($n, $i, 3) . ',';
                $i += 3;
            }

            $x .= substr($n, $i);
        }

        Sidef::Types::String::String->new(($neg ? '-' : '') . $x);
    }

    #
    ## Conversions
    #

    sub rad2deg {
        my ($x) = @_;
        state $f = do {
            my $fr = Math::MPFR::Rmpfr_init2($PREC);
            my $pi = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_const_pi($pi, $ROUND);
            Math::MPFR::Rmpfr_ui_div($fr, 180, $pi, $ROUND);
            _mpfr2rat($fr);
        };
        $f->mul($x);
    }

    sub deg2rad {
        my ($x) = @_;
        state $f = do {
            my $fr = Math::MPFR::Rmpfr_init2($PREC);
            my $pi = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_const_pi($pi, $ROUND);
            Math::MPFR::Rmpfr_div_ui($fr, $pi, 180, $ROUND);
            _mpfr2rat($fr);
        };
        $f->mul($x);
    }

    sub rad2grad {
        my ($x) = @_;
        state $factor = do {
            my $fr = Math::MPFR::Rmpfr_init2($PREC);
            my $pi = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_const_pi($pi, $ROUND);
            Math::MPFR::Rmpfr_ui_div($fr, 200, $pi, $ROUND);
            _mpfr2rat($fr);
        };
        $factor->mul($x);
    }

    sub grad2rad {
        my ($x) = @_;
        state $factor = do {
            my $fr = Math::MPFR::Rmpfr_init2($PREC);
            my $pi = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_const_pi($pi, $ROUND);
            Math::MPFR::Rmpfr_div_ui($fr, $pi, 200, $ROUND);
            _mpfr2rat($fr);
        };
        $factor->mul($x);
    }

    sub grad2deg {
        my ($x) = @_;
        state $factor = do {
            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_ui($q, 9, 10);
            $q;
        };
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul($r, $factor, $$x);
        bless \$r, __PACKAGE__;
    }

    sub deg2grad {
        my ($x) = @_;
        state $factor = do {
            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_ui($q, 10, 9);
            $q;
        };
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul($r, $factor, $$x);
        bless \$r, __PACKAGE__;
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
        *{__PACKAGE__ . '::' . '//'}  = \&idiv;
        *{__PACKAGE__ . '::' . 'γ'}  = \&Y;
        *{__PACKAGE__ . '::' . 'Γ'}  = \&gamma;
        *{__PACKAGE__ . '::' . 'Ψ'}  = \&digamma;
    }
}

1
