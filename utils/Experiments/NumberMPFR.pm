package Sidef::Types::Number::NumberMPFR {

    #
    ## Proof of concept for using Math::MPFR instead of Math::BigFloat
    ## See also: https://www.youtube.com/watch?v=Dhl4_Chvm_g
    #

    use 5.014;
    use Math::MPFR qw(:mpfr);

    our $ROUND = MPFR_RNDA;
    Rmpfr_set_default_prec(128);

    use overload q{""} => \&get_value;

    sub _new {
        my (undef, $num) = @_;
        bless(\$num, __PACKAGE__);
    }

    sub new {
        my (undef, $num) = @_;

        if (index(ref($num), 'Sidef::') == 0) {
            $num = $num->get_value;
        }

        (index(ref($num), 'Math::') == 0)
          ? bless(\$num, __PACKAGE__)
          : bless(\Math::MPFR->new($num))

          #do {
          #    my ($rop, $si) = Rmpfr_init_set_str($num, 10, $ROUND);
          #    bless \$rop, __PACKAGE__;
          #};
    }

    sub get_value {
        my $value = ${$_[0]};

        # my ($str, $si) = Rmpfr_deref2($value, 10, 158, $ROUND);
        # return $str;

        # Rmpfr_integer_string($value, 10, $ROUND);
        # Rmpfr_get_str($value, 10, 0, $ROUND)
        # Rmpfr_get_NV($value, $ROUND);

        # my $digits = Rmpfr_min_prec($value);
        # my $digits = mpfr_max_orig_len(10, 10, $value);
        # my $digits = Rmpfr_min_prec($value);

        # require POSIX;
        # $digits = 1 + 2**POSIX::ceil($digits*log(2)/log(10));

        my $str = Rmpfr_get_str($value, 10, 0, $ROUND);
        index($str, 'e') != -1
          ? ($str =~ s/^.*?\K\.(.*?)e(.*)/$1 . ('0' x ($2-length($1)))/er)
          : $str;

        #ref($value) eq 'SCALAR'
        #    ? Rmpfr_get_str($value, 10, 0, $ROUND)
        #    : $value;
    }

    sub add {
        my ($x, $y) = @_;
        my $r = Rmpfr_init();
        Rmpfr_add($r, $$x, $$y, $ROUND);
        $x->_new($r);
    }

    sub sub {
        my ($x, $y) = @_;
        my $r = Rmpfr_init();
        Rmpfr_sub($r, $$x, $$y, $ROUND);
        $x->_new($r);
    }

    sub mul {
        my ($x, $y) = @_;
        my $r = Rmpfr_init2(Rmpfr_get_prec($$x) + Rmpfr_get_prec($$y));
        Rmpfr_mul($r, $$x, $$y, $ROUND);
        $x->_new($r);
    }

    sub div {
        my ($x, $y) = @_;
        my $r = Rmpfr_init();
        Rmpfr_div($r, $$x, $$y, $ROUND);
        $x->_new($r);
    }

    sub sqrt {
        my ($x) = @_;
        my $r = Rmpfr_init();
        Rmpfr_sqrt($r, $$x, $ROUND);
        $x->_new($r);
    }

};

#
## Testing
#

use 5.014;

my $pkg = 'Sidef::Types::Number::NumberMPFR';

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

say $sum;

say $psum;
say $sum2;

say $prod;
say $pkg->new("0x323");

say $pkg->new(2)->sqrt;
