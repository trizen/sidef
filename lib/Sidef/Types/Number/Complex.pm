package Sidef::Types::Number::Complex {

    use utf8;
    use 5.014;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{""}   => \&get_value,
      q{0+}   => \&get_value,
      q{bool} => \&get_value;

    require Math::MPC;
    require Math::MPFR;

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

    our $ROUND = Math::MPC::MPC_RNDNN();

    our ($PREC);
    *PREC = \$Sidef::Types::Number::Number::PREC;

    sub new {
        my (undef, $x, $y) = @_;

        if (ref($x) eq 'Sidef::Types::Number::Number') {
            $x = $$x;
        }
        elsif (ref($x) eq __PACKAGE__) {
            return $x if not defined $y;
            if (ref($y) eq __PACKAGE__) {
                return $x->add($y->mul(i()));
            }
            else {
                return $x->add(__PACKAGE__->new($y)->mul(i()));
            }
        }
        elsif (index(ref($x), 'Sidef::') == 0) {
            $x = "$x";
            if ($x eq 'i' or $x eq '+i') {
                return __PACKAGE__->new(__PACKAGE__->new(0, 1), $y);
            }
            elsif ($x eq '-i') {
                return __PACKAGE__->new(__PACKAGE__->new(0, -1), $y);
            }
            elsif (substr($x, -1) eq 'i') {
                if ($x =~ /^(.+?)([+-].*?)i\z/) {
                    my ($re, $im) = ($1, $2);
                    if ($im eq '+') {
                        $im = 1;
                    }
                    elsif ($im eq '-') {
                        $im = -1;
                    }
                    return __PACKAGE__->new(__PACKAGE__->new($re, $im), $y);
                }
                else {
                    return __PACKAGE__->new(__PACKAGE__->new(0, $x), $y);
                }
            }
        }

        if (not defined($y)) {
            my $r = Math::MPC::Rmpc_init2($PREC);
            if (ref($x) eq 'Math::GMPq' or ref($x) eq 'SCALAR') {
                Math::MPC::Rmpc_set_q($r, $x, $ROUND);
            }
            else {
                Math::MPC::Rmpc_set_str($r, $x, 10, $ROUND);
            }

            return (bless \$r, __PACKAGE__);
        }
        elsif (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = $$y;
        }
        elsif (ref($y) eq __PACKAGE__) {
            return $y->mul(i())->add(__PACKAGE__->new($x));
        }
        elsif (index(ref($y), 'Sidef::') == 0) {
            $y = "$y";
            if ($y eq 'i' or $y eq '+i') {
                return __PACKAGE__->new($x, __PACKAGE__->new(0, 1));
            }
            elsif ($y eq '-i') {
                return __PACKAGE__->new($x, __PACKAGE__->new(0, -1));
            }
            elsif (substr($y, -1) eq 'i') {
                if ($y =~ /^(.+?)([+-].*?)i\z/) {
                    my ($re, $im) = ($1, $2);
                    if ($im eq '+') {
                        $im = 1;
                    }
                    elsif ($im eq '-') {
                        $im = -1;
                    }
                    return __PACKAGE__->new($x, __PACKAGE__->new($re, $im));
                }
                else {
                    return __PACKAGE__->new($x, __PACKAGE__->new(0, substr($y, 0, -1)));
                }
            }
        }

        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($x) eq 'Math::GMPq' or ref($x) eq 'SCALAR') {
            if (ref($y) eq 'Math::GMPq' or ref($y) eq 'SCALAR') {
                Math::MPC::Rmpc_set_q_q($r, $x, $y, $ROUND);
            }
            else {
                my $y_fr = Math::MPFR::Rmpfr_init2($PREC);
                Math::MPFR::Rmpfr_set_str($y_fr, $y, 10, $Sidef::Types::Number::Number::ROUND);
                Math::MPC::Rmpc_set_q_fr($r, $x, $y_fr, $ROUND);
            }
        }
        elsif (ref($y) eq 'Math::GMPq' or ref($y) eq 'SCALAR') {
            my $x_fr = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_set_str($x_fr, $x, 10, $Sidef::Types::Number::Number::ROUND);
            Math::MPC::Rmpc_set_fr_q($r, $x_fr, $y, $ROUND);
        }
        else {
            my $x_fr = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_set_str($x_fr, $x, 10, $Sidef::Types::Number::Number::ROUND);

            my $y_fr = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_set_str($y_fr, $y, 10, $Sidef::Types::Number::Number::ROUND);

            Math::MPC::Rmpc_set_fr_fr($r, $x_fr, $y_fr, $ROUND);

            #my $x_q = Math::GMPq->new(Sidef::Types::Number::Number::_str2rat($x), 10);
            #my $y_q = Math::GMPq->new(Sidef::Types::Number::Number::_str2rat($y), 10);
            #Math::MPC::Rmpc_set_q_q($r, $x_q, $y_q, $ROUND);
        }

        bless \$r, __PACKAGE__;
    }

    *call = \&new;

    sub _valid {
        (
         ref($$_) eq __PACKAGE__
           or do {
             ref($$_) eq 'Sidef::Types::Number::Number' ? do { $$_ = __PACKAGE__->new($$_) } : do {
                 my $sub = UNIVERSAL::can($$_, 'to_c') // overload::Method($$_, '0+');

                 my $tmp = (
                            defined($sub)
                            ? __PACKAGE__->new($sub->($$_))
                            : die "[ERROR] Value <<$$_>> cannot be implicitly converted to a complex number!"
                           );

                 ref($tmp) eq __PACKAGE__
                   or die "[ERROR] Cannot convert <<$$_>> to a complex number! (is method \"to_c\" well-defined?)";

                 $$_ = $tmp;
               }
           }
        ) for @_;
    }

    sub get_value {
        my $re = $_[0]->re;
        my $im = $_[0]->im;

        $re = "$re";
        $im = "$im";

        return $re if $im eq '0';
        my $sign = '+';

        if (substr($im, 0, 1) eq '-') {
            $sign = '-';
            substr($im, 0, 1, '');
        }

        $im = '' if $im eq '1';
        $re eq '0' ? $sign eq '+' ? "${im}i" : "$sign${im}i" : "$re$sign${im}i";
    }

    sub reals {
        ($_[0]->re, $_[0]->im);
    }

    *parts = \&reals;

    sub dump {
        my $re = $_[0]->re;
        my $im = $_[0]->im;
        Sidef::Types::String::String->new("Complex($re, $im)");
    }

    #
    ## Complex constants
    #

    sub pi {
        my $pi = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_const_pi($pi, $Sidef::Types::Number::Number::ROUND);
        my $cplx_pi = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($cplx_pi, $pi, $ROUND);
        bless(\$cplx_pi, __PACKAGE__);
    }

    sub e {
        state $one_f = (Math::MPFR::Rmpfr_init_set_ui_nobless(1, $Sidef::Types::Number::Number::ROUND))[0];
        my $e = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_exp($e, $one_f, $Sidef::Types::Number::Number::ROUND);
        my $cplx_e = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($cplx_e, $e, $ROUND);
        bless(\$cplx_e, __PACKAGE__);
    }

    sub i {
        state $i = do {
            my $r = Math::MPC::Rmpc_init2_nobless($PREC);
            Math::MPC::Rmpc_set_ui_ui($r, 0, 1, $ROUND);
            bless(\$r, __PACKAGE__);
        };
        ref($_[0]) eq __PACKAGE__ ? $i->mul($_[0]) : $i;
    }

    sub phi {
        state $one_f  = (Math::MPFR::Rmpfr_init_set_ui_nobless(1, $Sidef::Types::Number::Number::ROUND))[0];
        state $two_f  = (Math::MPFR::Rmpfr_init_set_ui_nobless(2, $Sidef::Types::Number::Number::ROUND))[0];
        state $five_f = (Math::MPFR::Rmpfr_init_set_ui_nobless(5, $Sidef::Types::Number::Number::ROUND))[0];

        my $phi = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sqrt($phi, $five_f, $Sidef::Types::Number::Number::ROUND);
        Math::MPFR::Rmpfr_add($phi, $phi, $one_f, $Sidef::Types::Number::Number::ROUND);
        Math::MPFR::Rmpfr_div($phi, $phi, $two_f, $Sidef::Types::Number::Number::ROUND);

        my $cplx_phi = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($cplx_phi, $phi, $ROUND);
        bless(\$cplx_phi, __PACKAGE__);
    }

    #
    ## Complex specific functions
    #

    sub abs {
        my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_mpfr2big($mpfr);
    }

    sub norm {
        my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_norm($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_mpfr2big($mpfr);
    }

    *reciprocal = \&norm;

    sub real {
        my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_RE($mpfr, ${$_[0]});

        #Math::MPC::Rmpc_real($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_mpfr2big($mpfr);
    }

    *re = \&real;

    sub imag {
        my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_IM($mpfr, ${$_[0]});

        #Math::MPC::Rmpc_imag($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_mpfr2big($mpfr);
    }

    *im        = \&imag;
    *imaginary = \&imag;

    sub neg {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_neg($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub conj {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_conj($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    *not       = \&conj;
    *conjugate = \&conj;

    #
    ## Arithmetic operations
    #

    sub add {
        my ($x, $y) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            Math::MPC::Rmpc_add_fr($r, $$x, $y->_big2mpfr(), $ROUND);
        }
        else {
            _valid(\$y);
            Math::MPC::Rmpc_add($r, $$x, $$y, $ROUND);
        }

        bless(\$r, __PACKAGE__);
    }

    *fadd = \&add;

    sub sub {
        my ($x, $y) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            Math::MPC::Rmpc_add_fr($r, $$x, -$y->_big2mpfr(), $ROUND);
        }
        else {
            _valid(\$y);
            Math::MPC::Rmpc_sub($r, $$x, $$y, $ROUND);
        }

        bless(\$r, __PACKAGE__);
    }

    *fsub = \&sub;

    sub mul {
        my ($x, $y) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            Math::MPC::Rmpc_mul_fr($r, $$x, $y->_big2mpfr(), $ROUND);
        }
        else {
            _valid(\$y);
            Math::MPC::Rmpc_mul($r, $$x, $$y, $ROUND);
        }

        bless(\$r, __PACKAGE__);
    }

    *fmul = \&mul;

    sub div {
        my ($x, $y) = @_;

        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            Math::MPC::Rmpc_div_fr($r, $$x, $y->_big2mpfr(), $ROUND);
        }
        else {
            _valid(\$y);
            Math::MPC::Rmpc_div($r, $$x, $$y, $ROUND);
        }

        bless(\$r, __PACKAGE__);
    }

    *fdiv = \&div;

    sub inv {
        my ($x) = @_;

        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $$x, $ROUND);

        bless(\$r, __PACKAGE__);
    }

    sub pow {
        my ($x, $y) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            Math::MPC::Rmpc_pow_fr($r, $$x, $y->_big2mpfr(), $ROUND);
        }
        else {
            _valid(\$y);
            Math::MPC::Rmpc_pow($r, $$x, $$y, $ROUND);
        }

        bless(\$r, __PACKAGE__);
    }

    *fpow = \&pow;

    sub sqr {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sqr($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub root {
        my ($x, $y) = @_;
        return $x->pow($y->inv);
    }

    sub sqrt {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sqrt($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub cbrt {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        state $three_inv = do {
            my $r = Math::MPC::Rmpc_init2_nobless($PREC);
            Math::MPC::Rmpc_set_ui($r, 3, $ROUND);
            Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
            $r;
        };
        Math::MPC::Rmpc_pow($r, $$x, $three_inv, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub hypot {
        my ($x, $y) = @_;

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($r, $$x, $ROUND);

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            Math::MPFR::Rmpfr_hypot($r, $r, $y->_big2mpfr, $Sidef::Types::Number::Number::ROUND);
        }
        else {
            _valid(\$y);
            my $f = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPC::Rmpc_abs($f, $$y, $ROUND);
            Math::MPFR::Rmpfr_hypot($r, $r, $f, $Sidef::Types::Number::Number::ROUND);
        }

        Sidef::Types::Number::Number::_mpfr2big($r);
    }

    sub log {
        my ($x, $y) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log($r, $$x, $ROUND);

        if (defined $y) {
            if (ref($y) eq 'Sidef::Types::Number::Number') {
                my $baseln = $y->_big2mpfr();
                Math::MPFR::Rmpfr_log($baseln, $baseln, $Sidef::Types::Number::Number::ROUND);
                Math::MPC::Rmpc_div_fr($r, $r, $baseln, $ROUND);
            }
            else {
                _valid(\$y);
                my $baseln = Math::MPC::Rmpc_init2($PREC);
                Math::MPC::Rmpc_log($baseln, $$y, $ROUND);
                Math::MPC::Rmpc_div($r, $r, $baseln, $ROUND);
            }
        }

        bless(\$r, __PACKAGE__);
    }

    sub ln {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub log2 {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log($r, $$x, $ROUND);

        state $two = (Math::MPFR::Rmpfr_init_set_ui_nobless(2, $Sidef::Types::Number::Number::ROUND))[0];

        my $baseln = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_log($baseln, $two, $Sidef::Types::Number::Number::ROUND);
        Math::MPC::Rmpc_div_fr($r, $r, $baseln, $ROUND);

        bless(\$r, __PACKAGE__);
    }

    sub log10 {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log10($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub lgrt {
        my $c = ${$_[0]};

        $PREC = CORE::int($PREC);

        my $p = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_pow_ui($p, 10, int($PREC / 4), $Sidef::Types::Number::Number::ROUND);
        Math::MPFR::Rmpfr_ui_div($p, 1, $p, $Sidef::Types::Number::Number::ROUND);

        my $d = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log($d, $c, $ROUND);

        my $x = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set($x, $c, $ROUND);
        Math::MPC::Rmpc_sqr($x, $x, $ROUND);
        Math::MPC::Rmpc_add_ui($x, $x, 1, $ROUND);
        Math::MPC::Rmpc_log($x, $x, $ROUND);

        my $y = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_ui($y, 0, $ROUND);

        my $tmp = Math::MPC::Rmpc_init2($PREC);
        my $abs = Math::MPFR::Rmpfr_init2($PREC);

        my $count = 0;
        while (1) {
            Math::MPC::Rmpc_sub($tmp, $x, $y, $ROUND);

            Math::MPC::Rmpc_abs($abs, $tmp, $ROUND);
            Math::MPFR::Rmpfr_cmp($abs, $p) <= 0 and last;

            Math::MPC::Rmpc_set($y, $x, $ROUND);

            Math::MPC::Rmpc_log($tmp, $x, $ROUND);
            Math::MPC::Rmpc_add_ui($tmp, $tmp, 1, $ROUND);

            Math::MPC::Rmpc_add($x, $x, $d, $ROUND);
            Math::MPC::Rmpc_div($x, $x, $tmp, $ROUND);
            last if ++$count > $PREC;
        }

        #~ say "Complex.lgrt(): $count";

        bless \$x, __PACKAGE__;
    }

    sub lambert_w {
        my $c = ${$_[0]};

        $PREC = CORE::int($PREC);

        my $p = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_pow_ui($p, 10, CORE::int($PREC / 4), $Sidef::Types::Number::Number::ROUND);
        Math::MPFR::Rmpfr_ui_div($p, 1, $p, $Sidef::Types::Number::Number::ROUND);

        my $x = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set($x, $c, $ROUND);
        Math::MPC::Rmpc_sqrt($x, $x, $ROUND);
        Math::MPC::Rmpc_add_ui($x, $x, 1, $ROUND);

        my $y = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_ui($y, 0, $ROUND);

        my $tmp = Math::MPC::Rmpc_init2($PREC);
        my $abs = Math::MPFR::Rmpfr_init2($PREC);

        my $count = 0;
        while (1) {
            Math::MPC::Rmpc_sub($tmp, $x, $y, $ROUND);

            Math::MPC::Rmpc_abs($abs, $tmp, $ROUND);
            Math::MPFR::Rmpfr_cmp($abs, $p) <= 0 and last;

            Math::MPC::Rmpc_set($y, $x, $ROUND);

            Math::MPC::Rmpc_log($tmp, $x, $ROUND);
            Math::MPC::Rmpc_add_ui($tmp, $tmp, 1, $ROUND);

            Math::MPC::Rmpc_add($x, $x, $c, $ROUND);
            Math::MPC::Rmpc_div($x, $x, $tmp, $ROUND);
            last if ++$count > $PREC;
        }

        #~ say "Complex.lambert_w(): $count";

        Math::MPC::Rmpc_log($x, $x, $ROUND);
        bless \$x, __PACKAGE__;
    }

    sub exp {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_exp($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub exp2 {
        my ($x) = @_;
        state $two = do {
            my $c = Math::MPC::Rmpc_init2_nobless($PREC);
            Math::MPC::Rmpc_set_ui($c, 2, $ROUND);
            $c;
        };
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow($r, $two, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub exp10 {
        my ($x) = @_;
        state $ten = do {
            my $c = Math::MPC::Rmpc_init2_nobless($PREC);
            Math::MPC::Rmpc_set_ui($c, 10, $ROUND);
            $c;
        };
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow($r, $ten, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub dec {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sub_ui($r, $$x, 1, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub inc {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_add_ui($r, $$x, 1, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## Trigonometric
    #

    sub sin {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sin($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub asin {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_asin($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub sinh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sinh($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub asinh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_asinh($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub cos {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cos($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub acos {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_acos($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub cosh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cosh($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub acosh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_acosh($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub tan {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tan($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub atan {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_atan($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub tanh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tanh($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    sub atanh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_atanh($r, $$x, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## csc(x) = 1/sin(x)
    #
    sub csc {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sin($r, $$x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## acsc(x) = asin(1/x)
    #
    sub acsc {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $$x, $ROUND);
        Math::MPC::Rmpc_asin($r, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## csch(x) = 1/sinh(x)
    #
    sub csch {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sinh($r, $$x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## acsch(x) = asinh(1/x)
    #
    sub acsch {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $$x, $ROUND);
        Math::MPC::Rmpc_asinh($r, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## sec(x) = 1/cos(x)
    #
    sub sec {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cos($r, $$x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## asec(x) = acos(1/x)
    #
    sub asec {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $$x, $ROUND);
        Math::MPC::Rmpc_acos($r, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## sech(x) = 1/cosh(x)
    #
    sub sech {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cosh($r, $$x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## asech(x) = acosh(1/x)
    #
    sub asech {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $$x, $ROUND);
        Math::MPC::Rmpc_acosh($r, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## cot(x) = 1/tan(x)
    #
    sub cot {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tan($r, $$x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## acot(x) = atan(1/x)
    #
    sub acot {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $$x, $ROUND);
        Math::MPC::Rmpc_atan($r, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## coth(x) = 1/tanh(x)
    #
    sub coth {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tanh($r, $$x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## acoth(x) = atanh(1/x)
    #
    sub acoth {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $$x, $ROUND);
        Math::MPC::Rmpc_atanh($r, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## atan2(x, y) = atan(x/y)
    #
    sub atan2 {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid(\$y);
        }

        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($r, $$x, $$y, $ROUND);
        Math::MPC::Rmpc_atan($r, $r, $ROUND);
        bless(\$r, __PACKAGE__);
    }

    #
    ## Testing
    #

    sub eq {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid(\$y);
        }

        if (Math::MPC::Rmpc_cmp($$x, $$y) == 0) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub ne {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid(\$y);
        }

        if (Math::MPC::Rmpc_cmp($$x, $$y) == 0) {
            (Sidef::Types::Bool::Bool::FALSE);
        }
        else {
            (Sidef::Types::Bool::Bool::TRUE);
        }
    }

    sub gt {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid(\$y);
        }

        $x->abs->gt($y->abs);
    }

    sub ge {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid(\$y);
        }

        $x->abs->ge($y->abs);
    }

    sub lt {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid(\$y);
        }

        $x->abs->lt($y->abs);
    }

    sub le {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid(\$y);
        }

        $x->abs->le($y->abs);
    }

    sub cmp {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid(\$y);
        }

        $x->abs->cmp($y->abs);
    }

    sub floor {
        $_[0]->abs->floor;
    }

    sub ceil {
        $_[0]->abs->ceil;
    }

    sub round {
        my ($x, $prec) = @_;
        $x->abs->round(defined($prec) ? $prec : ());
    }

    *roundf = \&round;

    sub is_zero {
        $_[0]->abs->is_zero;
    }

    sub is_one {
        $_[0]->abs->is_one;
    }

    sub is_even {
        $_[0]->abs->is_even;
    }

    sub is_odd {
        $_[0]->abs->is_odd;
    }

    # Is int when the imaginary part is
    # zero and the real part is an integer
    sub is_int {
        my ($x) = @_;
        my $im = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_imag($im, ${$_[0]}, $ROUND);

        if (Math::MPFR::Rmpfr_sgn($im) != 0) {
            return (Sidef::Types::Bool::Bool::FALSE);
        }

        my $re = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_real($re, ${$_[0]}, $ROUND);

        if (Math::MPFR::Rmpfr_integer_p($re)) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    # Returns true when the imaginary part is zero
    sub is_real {
        my ($x) = @_;
        my $im = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_imag($im, ${$_[0]}, $ROUND);

        if (Math::MPFR::Rmpfr_sgn($im) == 0) {
            (Sidef::Types::Bool::Bool::TRUE);
        }
        else {
            (Sidef::Types::Bool::Bool::FALSE);
        }
    }

    sub is_nan {
        (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_inf {
        (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_ninf {
        (Sidef::Types::Bool::Bool::FALSE);
    }

    sub float { $_[0] }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
    }
}

1
