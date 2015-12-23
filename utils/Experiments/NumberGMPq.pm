package Sidef::Types::Number::NumberGMPq {

    use 5.014;

    use Math::GMPq qw(:mpq);
    use Math::GMPz qw(:mpz);
    use Math::GMPf qw(:mpf);
    use Math::MPFR qw(:mpfr);

    our $ROUND = MPFR_RNDN;
    our $PREC  = 128;

    sub _new {
        bless(\$_[1], __PACKAGE__);
    }

    use constant {
                  ONE  => __PACKAGE__->_new(Math::GMPq->new(-1)),
                  ZERO => __PACKAGE__->_new(Math::GMPq->new(0)),
                  MONE => __PACKAGE__->_new(Math::GMPq->new(1)),
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

          # Math::BigRat->new($num)->bstr
    }

    sub _as_float {
        my $r = Rmpfr_init2($PREC);
        Rmpfr_set_q($r, ${$_[0]}, $ROUND);
        $r;
    }

    sub _mpfr2rat {

        #~ my ($mantissa, $exponent) = Rmpfr_deref2($_[0], 10, 0, $ROUND);
        #~ my $r = Rmpq_init();
        #~ Rmpq_set_str($r, "$mantissa/1" . ('0' x (length($mantissa) - $exponent)), 10);
        #~ Rmpq_canonicalize($r);
        #~ $r

        #my $p =
        #say "P: $p";

        my $f = Rmpf_init2($PREC);
        Rmpfr_get_f($f, $_[0], $ROUND);

        my $r = Rmpq_init();
        Rmpq_set_f($r, $f);
        $r

          #Math::GMPq->new("$mantissa/1" . ('0' x (length($mantissa) - $exponent)));
          #my $str = Rmpfr_get_str($_[0], 10, 0, $ROUND);
          #Math::GMPq->new(_str2rat($str));
    }

    sub _as_int {
        my $i = Rmpz_init();
        Rmpz_set_q($i, ${$_[0]});
        $i;
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

    sub Rmpfr_get_str {

        my ($mantissa, $exponent) = Rmpfr_deref2($_[0], $_[1], $_[2], $_[3]);

        #say "M: $mantissa; E: $exponent";

        if ($mantissa =~ /^\@/) { return substr($mantissa, 1, -1) }
        if ($mantissa =~ /\-/ && $mantissa !~ /[^0,\-]/) { return '-0' }
        if ($mantissa !~ /[^0]/) { return '0' }

        my $len = substr($mantissa, 0, 1) eq '-' ? 2 : 1;

        if (!$_[2]) {

            #$mantissa =~ s/^.{$len}.*?\K0+$//;
            $mantissa =~ s/0+$//;

            #$mantissa = reverse(reverse($mantissa) =~ s/^0+(?=.{$len,})//r);

            #while(length($mantissa) > $len && substr($mantissa, -1, 1) eq '0') {
            #     substr($mantissa, -1, 1, '');
            #}
        }

        $exponent--;

        my $sep = $_[1] <= 10 ? 'e' : '@';

        if (length($mantissa) == $len) {
            if ($exponent) { return $mantissa . $sep . $exponent }
            return $mantissa;
        }

        substr($mantissa, $len, 0, '.');
        if ($exponent) { return $mantissa . $sep . $exponent }
        return $mantissa;
    }

    sub get_value {
        my $value = ${$_[0]};

        my $v = Rmpq_get_str($value, 10);
        if ((my $i = index($v, '/')) != -1) {
            my ($numerator, $denominator) = (substr($v, 0, $i), substr($v, $i + 1));

            my $r  = Rmpfr_init2($PREC);
            my $nu = Rmpfr_init2($PREC);
            my $de = Rmpfr_init2($PREC);

            Rmpfr_set_str($nu, $numerator,   10, $ROUND);
            Rmpfr_set_str($de, $denominator, 10, $ROUND);
            Rmpfr_div($r, $nu, $de, $ROUND);

            my $str = Rmpfr_get_str($r, 10, 0, $ROUND);

            if ((my $j = index($str, 'e')) != -1) {
                my $exp = substr($str, $j + 1);
                my ($before, $after) = split(/\./, substr($str, 0, $j));

                if ($exp < 1) {
                    '0' . '.' . ('0' x abs($exp + 1)) . $before . $after;
                }
                else {
                    my $s = $before . $after;
                    substr($s, $exp + length($before), 0, '.');
                    $s;
                }
            }
            else {
                $str;
            }
        }
        else {
            $v;
        }

        #my $n = Math::BigRat->new(Rmpq_get_str($value, 10));
        #$n->is_int ? $n->as_int->bstr : $n->as_float(int($PREC / 3.321923))->bstr;
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

    sub mod {
        my ($x, $y) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_fmod($r, _as_float($x), _as_float($y), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub log {
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

    sub gamma {
        my ($x) = @_;
        my $r = Rmpfr_init2($PREC);
        Rmpfr_gamma($r, _as_float($x), $ROUND);
        $x->_new(_mpfr2rat($r));
    }

    sub eq {
        my ($x, $y) = @_;
        Sidef::Types::Bool::Bool->new(Rmpq_equal($$x, $$y));
    }

    sub cmp {
        my ($x, $y) = @_;
        my $cmp = Rmpq_cmp($$x, $$y);
        $cmp == 0 ? ZERO : $cmp < 0 ? MONE : ONE;
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

    sub is_psquare {
        my ($x) = @_;

        my $dz = Rmpz_init();
        Rmpq_get_den($dz, $$x);

        state $zone = Rmpz_init_set_str(1, 10);
        Rmpz_cmp($dz, $zone) == 0 or return Sidef::Types::Bool::Bool->false;

        my $nz = Rmpz_init();
        Rmpq_get_num($nz, $$x);

        Sidef::Types::Bool::Bool->new(Rmpz_perfect_square_p($nz));
    }

    sub is_ppower {
        my ($x) = @_;

        my $dz = Rmpz_init();
        Rmpq_get_den($dz, $$x);

        state $zone = Rmpz_init_set_str(1, 10);
        Rmpz_cmp($dz, $zone) == 0 or return Sidef::Types::Bool::Bool->false;

        my $nz = Rmpz_init();
        Rmpq_get_num($nz, $$x);

        Sidef::Types::Bool::Bool->new(Rmpz_perfect_power_p($nz));
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
        Rmpz_bin_ui($r, $$x, CORE::int(Rmpq_get_d($$y)));
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
        Rmpz_gcd($r, $$x, $$y);
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
}

#
## Testing
#

use 5.014;

use lib ('/home/swampyx/Other/Programare/Sidef/lib');
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

say $pkg->new(5.6)->gamma;
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
say $pkg->new(81)->gcd($pkg->new(21));
say $pkg->new(5.5)->fac;
say $pkg->new(23.3)->and($pkg->new(99));
