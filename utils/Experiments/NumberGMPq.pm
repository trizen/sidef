package Sidef::Types::Number::NumberGMPq {

    use 5.014;

    use Math::GMPq qw(:mpq);
    use Math::GMPz qw(:mpz);
    use Math::GMPf qw(:mpf);
    use Math::MPFR qw(:mpfr);

    our $ROUND = MPFR_RNDN;
    our $PREC  = 128;

    our $GET_PERL_VALUE = 0;

    sub _new {
        bless(\$_[1], __PACKAGE__);
    }

    use constant {
                  ONE  => __PACKAGE__->_new(Math::GMPq->new(1)),
                  ZERO => __PACKAGE__->_new(Math::GMPq->new(0)),
                  MONE => __PACKAGE__->_new(Math::GMPq->new(-1)),
                 };

    use overload q{""} => \&get_value;

    sub new {
        my (undef, $num) = @_;

        if (index(ref($num), 'Sidef::') == 0) {
            $num = $num->get_value;
        }

        (index(ref($num), 'Math::') == 0)
          ? bless(\$num,                            __PACKAGE__)
          : bless(\Math::GMPq->new(_str2rat($num)), __PACKAGE__)
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

        #my $p =
        #say "P: $p";

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

        if ((my $i = index($str, 'e')) != -1) {

            my $exp = substr($str, $i + 1);
            my ($before, $after) = split(/\./, substr($str, 0, $i));
            my $numerator = $before . $after;

            my $denominator = 1;
            if ($exp < 1) {
                $denominator .= '0' x abs($exp);
            }
            else {
                my $diff = ($exp - length($after));
                if ($diff >= 0) {
                    $numerator .= '0' x $diff;
                }
                else {
                    my $s = $before . $after;
                    substr($s, $exp + length($before), 0, '.');
                    return _str2rat($s);
                }
            }

            "$numerator/$denominator";
        }
        elsif ((my $i = index($str, '.')) != -1) {
            my ($before, $after) = (substr($str, 0, $i), substr($str, $i + 1));
            "$before$after/1" . ('0' x length($after));
        }
        else {
            $str;
        }
    }

    #~ sub Rmpfr_get_str {

        #~ my ($mantissa, $exponent) = Rmpfr_deref2($_[0], $_[1], $_[2], $_[3]);

        #~ #say "M: $mantissa; E: $exponent";

        #~ if ($mantissa =~ /^\@/) { return substr($mantissa, 1, -1) }
        #~ if ($mantissa =~ /\-/ && $mantissa !~ /[^0,\-]/) { return '-0' }
        #~ if ($mantissa !~ /[^0]/) { return '0' }

        #~ my $len = substr($mantissa, 0, 1) eq '-' ? 2 : 1;

        #~ if (!$_[2]) {

            #~ #$mantissa =~ s/^.{$len}.*?\K0+$//;
            #~ $mantissa =~ s/0+$//;

            #~ #$mantissa = reverse(reverse($mantissa) =~ s/^0+(?=.{$len,})//r);

            #~ #while(length($mantissa) > $len && substr($mantissa, -1, 1) eq '0') {
            #~ #     substr($mantissa, -1, 1, '');
            #~ #}
        #~ }

        #~ $exponent--;

        #~ my $sep = $_[1] <= 10 ? 'e' : '@';

        #~ if (length($mantissa) == $len) {
            #~ if ($exponent) { return $mantissa . $sep . $exponent }
            #~ return $mantissa;
        #~ }

        #~ substr($mantissa, $len, 0, '.');
        #~ if ($exponent) { return $mantissa . $sep . $exponent }
        #~ return $mantissa;
    #~ }

    sub get_value {
        $GET_PERL_VALUE && return Rmpq_get_d(${$_[0]});

        my $v = Rmpq_get_str(${$_[0]}, 10);

        if (index($v, '/') != -1) {
            my $br = Math::BigRat->new($v);

            # This should not happen
            if ($br->is_int) {
                die "$v is integer from Math::BigRat!";
            }

            #return ($br->is_int ? $br->as_int->bstr :
            return ($br->as_float(int($PREC / 3.2))->bstr =~ s/0+$//r);
        }
        else {
            return $v;
        }
    }

    sub add {
        my ($x, $y) = @_;
        my $r = Rmpq_init();
        Rmpq_add($r, $$x, $$y);
        $x->_new($r);
    }

    sub sub {
        my ($x, $y) = @_;
        my $r = Rmpq_init();
        Rmpq_sub($r, $$x, $$y);
        $x->_new($r);
    }

    sub div {
        my ($x, $y) = @_;
        my $r = Rmpq_init();

        # Probably, we can work around
        # this and return Infinity instead?
        if (Rmpq_sgn($$y) == 0) {
            die "Illegal division by zero";
        }

        Rmpq_div($r, $$x, $$y);
        $x->_new($r);
    }

    sub mul {
        my ($x, $y) = @_;
        my $r = Rmpq_init();
        Rmpq_mul($r, $$x, $$y);
        $x->_new($r);
    }

    sub neg {
        my ($x) = @_;
        my $r = Rmpq_init();
        Rmpq_neg($r, $$x);
        $x->_new($r);
    }

    sub abs {
        my ($x) = @_;
        my $r = Rmpq_init();
        Rmpq_abs($r, $$x);
        $x->_new($r);
    }

    sub inv {
        my ($x) = @_;
        my $r = Rmpq_init();
        Rmpq_inv($r, $$x);
        $x->_new($r);
    }

    sub sqrt {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_sqrt($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub cbrt {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_cbrt($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub root {
        my ($x, $y) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_root($r, _as_float($x), CORE::int(Rmpq_get_d($$y)), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub sqr {
        my ($x) = @_;
        $x->mul($x);
    }

    sub pow {
        my ($x, $y) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_pow($r, _as_float($x), _as_float($y), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub fmod {
        my ($x, $y) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_fmod($r, _as_float($x), _as_float($y), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub log {
        my ($x, $y) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_log($r, _as_float($x), $ROUND);

        if (defined $y) {
            my $baseln = Rmpfr_init2($PREC);
            Rmpfr_log($baseln, _as_float($y), $ROUND);
            Rmpfr_div($r, $r, $baseln, $ROUND);
        }

        $x->_new(_mpfr2rat($r));
    }

    sub ln {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_log($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub log2 {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_log2($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub log10 {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_log10($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub exp {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_exp($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub exp2 {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_exp2($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub exp10 {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_exp10($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub sin {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_sin($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub asin {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_asin($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub sinh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_sinh($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub asinh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_asinh($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub cos {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_cos($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub acos {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_acos($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub cosh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_cosh($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub acosh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_acosh($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub tan {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_tan($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub atan {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_atan($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub tanh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_tanh($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub atanh {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_atanh($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub sec {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_sec($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub sech {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_sech($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub csc {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_csc($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub csch {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_csch($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub cot {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_cot($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub coth {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_coth($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub agm {
        my ($x, $y) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_agm($r, _as_float($x), _as_float($y), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub hypot {
        my ($x, $y) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_hypot($r, _as_float($x), _as_float($y), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub gamma {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_gamma($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub lgamma {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_lgamma($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub digamma {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_digamma($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub zeta {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_zeta($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub erf {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_erf($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub erfc {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_erfc($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub eint {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_eint($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub li2 {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_li2($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    #
    ## Comparison and testing operations
    #

    sub eq {
        my ($x, $y) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_equal($$x, $$y));
    }

    sub ne {
        my ($x, $y) = @_;
        Sidef::Types::Bool::Bool->new(!Rmpq_equal($$x, $$y));
    }

    sub cmp {
        my ($x, $y) = @_;
        my $cmp = Rmpq_cmp($$x, $$y);
        $cmp == 0 ? ZERO : $cmp < 0 ? MONE : ONE;
    }

    sub acmp {
        my ($x, $y) = @_;

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
        Sidef::Types::Bool::Bool->new(Rmpq_cmp($$x, $$y) > 0);
    }

    sub ge {
        my ($x, $y) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_cmp($$x, $$y) >= 0);
    }

    sub lt {
        my ($x, $y) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_cmp($$x, $$y) < 0);
    }

    sub le {
        my ($x, $y) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_cmp($$x, $$y) <= 0);
    }

    sub is_zero {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_sgn($$x) == 0);
    }

    sub is_positive {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_sgn($$x) > 0);
    }

    sub is_negative {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_sgn($$x) < 0);
    }

    sub _is_int {
        my ($x) = @_;

        my $dz = Rmpz_init();
        Rmpq_get_den($dz, $$x);

        state $one_z = Rmpz_init_set_str(1, 10);
        Rmpz_cmp($dz, $one_z) == 0
    }

    sub is_int {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new($x->_is_int);
    }

    sub is_even {
        my ($x) = @_;
        $x->_is_int or return Sidef::Types::Bool::Bool->false;

        my $nz = Rmpz_init();
        Rmpq_get_num($nz, $$x);

        Sidef::Types::Bool::Bool->new(Rmpz_even_p($nz));
    }

    sub is_odd {
        my ($x) = @_;
        $x->_is_int or return Sidef::Types::Bool::Bool->false;

        my $nz = Rmpz_init();
        Rmpq_get_num($nz, $$x);

        Sidef::Types::Bool::Bool->new(Rmpz_odd_p($nz));
    }

    sub max {
        my ($x, $y) = @_;
        Rmpq_cmp($$x, $$y) > 0 ? $x : $y;
    }

    sub min {
        my ($x, $y) = @_;
        Rmpq_cmp($$x, $$y) < 0 ? $x : $y;
    }

    sub floor {
        my($x) = @_;
        $x->_is_int && return $x;

        if (Rmpq_sgn($$x) > 0) {
            my $z = Rmpz_init();
            Rmpz_set_q($z, $$x);
            $x->_new(_mpz2rat($z));
        }
        else {
            my $z = Rmpz_init();
            Rmpz_set_q($z, $$x);
            Rmpz_sub_ui($z, $z, 1);
            $x->_new(_mpz2rat($z));
        }
    }

    sub ceil {
        my ($x) = @_;
        $x->_is_int && return $x;

        if (Rmpq_sgn($$x) > 0) {
            my $z = Rmpz_init();
            Rmpz_set_q($z, $$x);
            Rmpz_add_ui($z, $z, 1);
            $x->_new(_mpz2rat($z));
        }
        else {
            my $z = Rmpz_init();
            Rmpz_set_q($z, $$x);
            $x->_new(_mpz2rat($z));
        }
    }

    sub inc {
        my ($x) = @_;
        state $one = __PACKAGE__->_new(Math::GMPq->new(1));
        $x->add($one);
    }

    sub dec {
        my ($x) = @_;
        state $one = __PACKAGE__->_new(Math::GMPq->new(1));
        $x->sub($one);
    }

    #
    ## Integer operations
    #

    sub iadd {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_add($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub isub {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_sub($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub imul {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_mul($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub idiv {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_div($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub mod {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_mod($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub modinv {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_invert($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub divmod {
        my ($x, $y) = @_;

        my $r1 = Rmpz_init();
        my $r2 = Rmpz_init();

        Rmpz_divmod($r1, $r2, _as_int($x), _as_int($y));
        ($x->_new(_mpz2rat($r1)), $x->_new(_mpz2rat($r2)))
    }

    sub and {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_and($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub or {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_ior($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub xor {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_xor($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub not {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_com($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub factorial {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_fac_ui($r, CORE::int(Rmpq_get_d($$x)));
        $x->_new(_mpz2rat($r));
    }

    *fac = \&factorial;

    sub factorial2 {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_2fac_ui($r, CORE::int(Rmpq_get_d($$x)));
        $x->_new(_mpz2rat($r));
    }

    *dfac = \&factorial2;

    sub primorial {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_primorial_ui($r, CORE::int(Rmpq_get_d($$x)));
        $x->_new(_mpz2rat($r));
    }

    sub fibonacci {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_fib_ui($r, CORE::int(Rmpq_get_d($$x)));
        $x->_new(_mpz2rat($r));
    }

    *fib = \&fibonacci;

    sub binomial {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_bin_ui($r, _as_int($x), CORE::int(Rmpq_get_d($$y)));
        $x->_new(_mpz2rat($r));
    }

    sub legendre {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_legendre($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub lucas {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_lucnum_ui($r, CORE::int(Rmpq_get_d($$x)));
        $x->_new(_mpz2rat($r));
    }

    sub gcd {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_gcd($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    sub lcm {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_lcm($r, _as_int($x), _as_int($y));
        $x->_new(_mpz2rat($r));
    }

    # Correct up to a maximum value of 341,550,071,728,320
    # See: https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test#Deterministic_variants_of_the_test
    sub is_prime {
        my ($x) = @_;
        Sidef::Types::Bool::Bool->new(Rmpz_probab_prime_p(_as_int($x), 7) > 0);
    }

    sub nextprime {
        my ($x) = @_;
        my $r = Rmpz_init();
        Rmpz_nextprime($r, _as_int($x));
        $x->_new(_mpz2rat($r));
    }

    sub is_psquare {
        my ($x) = @_;

        $x->_is_int or return Sidef::Types::Bool::Bool->false;

        my $nz = Rmpz_init();
        Rmpq_get_num($nz, $$x);

        Sidef::Types::Bool::Bool->new(Rmpz_perfect_square_p($nz));
    }

    sub is_ppower {
        my ($x) = @_;

        $x->_is_int or  return Sidef::Types::Bool::Bool->false;

        my $nz = Rmpz_init();
        Rmpq_get_num($nz, $$x);

        Sidef::Types::Bool::Bool->new(Rmpz_perfect_power_p($nz));
    }

    sub shift_left {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_mul_2exp($r, _as_int($x), CORE::int(Rmpq_get_d($$y)));
        $x->_new(_mpz2rat($r));
    }

    sub shift_right {
        my ($x, $y) = @_;
        my $r = Rmpz_init();
        Rmpz_div_2exp($r, _as_int($x), CORE::int(Rmpq_get_d($$y)));
        $x->_new(_mpz2rat($r));
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
        $x->_new($r);
    }

    sub denominator {
        my ($x) = @_;
        my $z = Rmpz_init();
        Rmpq_get_den($z, $$x);

        my $r = Rmpq_init();
        Rmpq_set_z($r, $z);
        $x->_new($r);
    }

    #
    ## Conversion/Miscellaneous
    #

    sub chr {
        my ($x) = @_;
        Sidef::Types::String::String->new(CORE::chr(Rmpq_get_d($$x)));
    }

    sub complex {
        my ($x, $y) = @_;
        Sidef::Types::Number::Complex->new(Rmpq_get_d($$x), Rmpq_get_d($$y));
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
            foreach my $i(Rmpq_get_d($$x) .. Rmpq_get_d($$y)) {
                my $n = Rmpq_init();
                Rmpq_set_str($n, $i, 10);
                push @array, $x->_new($n);
            }
        }
        else {
            my $xq = $$x;
            my $yq = $$y;
            my $stepq = $$step;

            my $acc = Rmpq_init();
            Rmpq_set($acc, $xq);

            for (; Rmpq_cmp($acc, $yq) <= 0; Rmpq_add($acc, $acc, $stepq)) {
                my $copy = Rmpq_init();
                Rmpq_set($copy, $acc);
                push @array, $x->_new($copy);
            }
        }

        Sidef::Types::Array::Array->new(@array);
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

#
## Testing
#

use 5.014;

use lib ('../../lib');
require Sidef;

#my $pkg = 'Sidef::Types::Number::Number';

my $pkg = 'Sidef::Types::Number::NumberGMPq';

my $x = $pkg->new(42);
my $y = $pkg->new(21);

my $r = $x->add($y);

say "ref(r): ", ref($$r);
say "ref(x): ", ref($$x);

say $r;
say $y;

my $one  = $pkg->new(1);
my $sum  = $pkg->new(0);
my $sum2 = $pkg->new(0);
my $prod = $pkg->new(1);

my $psum = 0;
for my $i (1 .. 100) {
    my $n = $pkg->new($i);
    $sum  = $sum->add($n);
    $sum2 = $sum2->add($one->div($n));
    $prod = $prod->mul($n);
    $psum += 1 / $i;
}

sub zeta {
    my ($s) = @_;

    my $sum2 = 0;
    my $s2   = $s->get_value;

    my $sum = $pkg->new(0);
    my $one = $pkg->new(1);

    for my $i (1 .. 1000) {
        $sum = $sum->add($one->div($pkg->new($i)->pow($s)));
        $sum2 += 1 / $i**$s2;
    }

    say $sum2;

    $sum;
}

say $sum;

say $psum;
say $sum2;

say $prod;
say $pkg->new("0x323");

say $pkg->new(2)->sqrt;
say zeta($pkg->new(2));
say zeta($pkg->new(3));

say $prod->mod($pkg->new(101));

say $prod->div($pkg->new(2));
say $prod->div($pkg->new(0.01));

say $pkg->new(1)->div($pkg->new(2));
say $pkg->new(1)->div($pkg->new(7));

say $prod->sqrt;
say $pkg->new(1000)->div($pkg->new(10));
say $pkg->new(1000)->div($pkg->new(5));

say $pkg->new(42)->sub($pkg->new(21.1));
say $pkg->new(2)->neg;

say $pkg->new(13)->div($pkg->new(4))->numerator;
say $pkg->new(13)->div($pkg->new(4))->denominator;

say $pkg->new(21)->log;
say $pkg->new(1)->exp;

say $pkg->new(0.5)->gamma;
say $pkg->new(1)->div($pkg->new(12345));

say $pkg->new(10)->div($pkg->new(4));
say $pkg->new(10)->div($pkg->new(771));

say $pkg->new(25)->sqrt->inc;
say $pkg->new(23)->and($pkg->new(99));
say $pkg->new(5)->fac;
say $pkg->new(5)->primorial;
say $pkg->new(12)->fib;
say $pkg->new(100)->binomial($pkg->new(3));

say $pkg->new(25)->is_psquare;
say $pkg->new(26)->is_psquare;
say $pkg->new(1 / 3)->is_psquare;
say $pkg->new(3**7)->is_ppower;
say $pkg->new(12345)->is_ppower;
say $pkg->new(81.0)->gcd($pkg->new(21.6));
say $pkg->new(5.5)->fac;

say(join(' ', grep { $pkg->new($_)->is_prime } 0 .. 100));
say $pkg->new(98)->nextprime;
say $pkg->new(-3)->acmp($pkg->new(-3));
say $pkg->new(-42)->acmp($pkg->new(3));
say $pkg->new(1.34)->sub($pkg->new(9.49));
say $pkg->new('1521e-16');
say $pkg->new(10)->idiv($pkg->new(3));
say $pkg->new(2)->zeta;

for (1..100) {
    my $int = int(rand(1000));
    my $div = $int / $_;
    if (int($div) == $div) {
        my $x = $pkg->new($int)->div($pkg->new($_));
        $x->_is_int || die "error for $int/$_\n";
    }
}
say $pkg->new(2)->root($pkg->new(2));
say $pkg->new(125)->cbrt;
say $prod->floor;
say $pkg->new(8.3)->floor;
say $pkg->new(-8.3)->floor;

say $pkg->new(8.3)->ceil;
say $pkg->new(-8.3)->ceil;
say $pkg->new(8)->log($pkg->new(2));
say $pkg->new(97)->chr;
say $pkg->new(2)->shift_left($pkg->new(3));
say $pkg->new(2)->complex($pkg->new(3));
say $pkg->new(1)->array_to($pkg->new(10));
say $pkg->new(1)->array_to($pkg->new(10), $pkg->new(1));
