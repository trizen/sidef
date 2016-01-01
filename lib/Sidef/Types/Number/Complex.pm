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
    require Sidef::Types::Number::Number;

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
                return $x->add($y);
            }
            else {
                return $x->add(__PACKAGE__->new($y));
            }
        }
        elsif (index(ref($x), 'Sidef::') == 0) {
            $x = $x->get_value;
        }

        if (not defined($y)) {
            my $r = Math::MPC::Rmpc_init2($PREC);
            if (ref($x) eq 'Math::GMPq') {
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
            return $y->add(__PACKAGE__->new($x));
        }
        elsif (index(ref($y), 'Sidef::') == 0) {
            $y = $y->get_value;
        }

        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($x) eq 'Math::GMPq') {
            if (ref($y) eq 'Math::GMPq') {
                Math::MPC::Rmpc_set_q_q($r, $x, $y, $ROUND);
            }
            else {
                my $y_fr = Math::MPFR::Rmpfr_init2($PREC);
                Math::MPFR::Rmpfr_set_str($y_fr, $y, 10, $Sidef::Types::Number::Number::ROUND);
                Math::MPC::Rmpc_set_q_fr($r, $x, $y_fr, $ROUND);
            }
        }
        elsif (ref($y) eq 'Math::GMPq') {
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

    sub _new {
        bless \$_[0], __PACKAGE__;
    }

    sub _valid {
        (
         ref($_) eq __PACKAGE__
           or die "[ERROR] Invalid argument `$_` of type "
           . Sidef::normalize_type(ref($_)) . " in "
           . Sidef::normalize_method((caller(1))[3])
           . "(). Expected an argument of type Complex!\n"
        )
          for @_;
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

    sub get_constant {
        my (undef, $name) = @_;

        state %cache;
        state $table = {
                        e   => sub { __PACKAGE__->new(Sidef::Types::Number::Number->e) },
                        pi  => sub { __PACKAGE__->new(Sidef::Types::Number::Number->pi) },
                        phi => sub { __PACKAGE__->new(Sidef::Types::Number::Number->phi) },
                        i   => sub { __PACKAGE__->new(0, 1) },
                       };

        my $key = lc($name);
        $cache{$key} //= exists($table->{$key}) ? $table->{$key}->() : do {
            warn qq{[WARN] Inexistent Complex constant "$name"!\n};
            undef;
        };
    }

    #
    ## Complex constants
    #

    sub pi {
        my $pi = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_const_pi($pi, $Sidef::Types::Number::Number::ROUND);
        my $cplx_pi = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($cplx_pi, $pi, $ROUND);
        _new($cplx_pi);
    }

    sub e {
        state $one_f = (Math::MPFR::Rmpfr_init_set_ui(1, $Sidef::Types::Number::Number::ROUND))[0];
        my $e = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_exp($e, $one_f, $Sidef::Types::Number::Number::ROUND);
        my $cplx_e = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($cplx_e, $e, $ROUND);
        _new($cplx_e);
    }

    sub i {
        state $i = do {
            my $r = Math::MPC::Rmpc_init2($PREC);
            Math::MPC::Rmpc_set_ui_ui($r, 0, 1, $ROUND);
            _new($r);
        };
    }

    sub phi {
        state $one_f  = (Math::MPFR::Rmpfr_init_set_ui(1, $Sidef::Types::Number::Number::ROUND))[0];
        state $two_f  = (Math::MPFR::Rmpfr_init_set_ui(2, $Sidef::Types::Number::Number::ROUND))[0];
        state $five_f = (Math::MPFR::Rmpfr_init_set_ui(5, $Sidef::Types::Number::Number::ROUND))[0];

        my $phi = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sqrt($phi, $five_f, $Sidef::Types::Number::Number::ROUND);
        Math::MPFR::Rmpfr_add($phi, $phi, $one_f, $Sidef::Types::Number::Number::ROUND);
        Math::MPFR::Rmpfr_div($phi, $phi, $two_f, $Sidef::Types::Number::Number::ROUND);

        my $cplx_phi = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($cplx_phi, $phi, $ROUND);
        _new($cplx_phi);
    }

    #
    ## Complex specific functions
    #

    sub abs {
        my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_mpfr2rat($mpfr);
    }

    sub norm {
        my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_norm($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_mpfr2rat($mpfr);
    }

    *reciprocal = \&norm;

    sub real {
        my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_RE($mpfr, ${$_[0]});

        #Math::MPC::Rmpc_real($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_mpfr2rat($mpfr);
    }

    *re = \&real;

    sub imag {
        my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_IM($mpfr, ${$_[0]});

        #Math::MPC::Rmpc_imag($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_mpfr2rat($mpfr);
    }

    *im        = \&imag;
    *imaginary = \&imag;

    sub neg {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_neg($r, $$x, $ROUND);
        _new($r);
    }

    sub conj {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_conj($r, $$x, $ROUND);
        _new($r);
    }

    *not       = \&conj;
    *conjugate = \&conj;

    #
    ## Arithmetic operations
    #

    sub add {
        my ($x, $y) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($y) eq __PACKAGE__) {
            Math::MPC::Rmpc_add($r, $$x, $$y, $ROUND);
        }
        else {
            Math::MPC::Rmpc_add_fr($r, $$x, $y->_as_float(), $ROUND);
        }

        _new($r);
    }

    sub sub {
        my ($x, $y) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($y) eq __PACKAGE__) {
            Math::MPC::Rmpc_sub($r, $$x, $$y, $ROUND);
        }
        else {
            Math::MPC::Rmpc_add_fr($r, $$x, -$y->_as_float(), $ROUND);
        }

        _new($r);
    }

    sub mul {
        my ($x, $y) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($y) eq __PACKAGE__) {
            Math::MPC::Rmpc_mul($r, $$x, $$y, $ROUND);
        }
        else {
            Math::MPC::Rmpc_mul_fr($r, $$x, $y->_as_float(), $ROUND);
        }

        _new($r);
    }

    sub div {
        my ($x, $y) = @_;

        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($y) eq __PACKAGE__) {
            Math::MPC::Rmpc_div($r, $$x, $$y, $ROUND);
        }
        else {
            Math::MPC::Rmpc_div_fr($r, $$x, $y->_as_float(), $ROUND);
        }

        _new($r);
    }

    sub pow {
        my ($x, $y) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);

        if (ref($y) eq __PACKAGE__) {
            Math::MPC::Rmpc_pow($r, $$x, $$y, $ROUND);
        }
        else {
            Math::MPC::Rmpc_pow_fr($r, $$x, $y->_as_float(), $ROUND);
        }

        _new($r);
    }

    sub root {
        my ($x, $y) = @_;
        state $one = __PACKAGE__->new(1);
        return $x->pow($one->div($y));
    }

    sub sqrt {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sqrt($r, $$x, $ROUND);
        _new($r);
    }

    sub cbrt {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow_d($r, $$x, 1 / 3, $ROUND);
        _new($r);
    }

    sub log {
        my ($x, $y) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log($r, $$x, $ROUND);

        if (defined $y) {
            if (ref($y) eq __PACKAGE__) {
                my $baseln = Math::MPC::Rmpc_init2($PREC);
                Math::MPC::Rmpc_log($baseln, $$y, $ROUND);
                Math::MPC::Rmpc_div($r, $r, $baseln, $ROUND);
            }
            else {
                my $baseln = Math::MPFR::Rmpfr_init2($PREC);
                Math::MPFR::Rmpfr_log($baseln, $y->_as_float(), $Sidef::Types::Number::Number::ROUND);
                Math::MPC::Rmpc_div_fr($r, $r, $baseln, $ROUND);
            }
        }

        _new($r);
    }

    sub ln {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log($r, $$x, $ROUND);
        _new($r);
    }

    sub log2 {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log($r, $$x, $ROUND);

        state $two = (Math::MPFR::Rmpfr_init_set_ui(2, $Sidef::Types::Number::Number::ROUND))[0];

        my $baseln = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_log($baseln, $two, $Sidef::Types::Number::Number::ROUND);
        Math::MPC::Rmpc_div_fr($r, $r, $baseln, $ROUND);

        _new($r);
    }

    sub log10 {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log10($r, $$x, $ROUND);
        _new($r);
    }

    sub exp {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_exp($r, $$x, $ROUND);
        _new($r);
    }

    sub exp2 {
        my ($x) = @_;
        state $two = Math::MPC->new(2);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow($r, $two, $$x, $ROUND);
        _new($r);
    }

    sub exp10 {
        my ($x) = @_;
        state $ten = Math::MPC->new(10);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow($r, $ten, $$x, $ROUND);
        _new($r);
    }

    sub dec {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sub($r, $$x, $one, $ROUND);
        _new($r);
    }

    sub inc {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_add($r, $$x, $one, $ROUND);
        _new($r);
    }

    #
    ## Trigonometric
    #

    sub sin {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sin($r, $$x, $ROUND);
        _new($r);
    }

    sub asin {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_asin($r, $$x, $ROUND);
        _new($r);
    }

    sub sinh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sinh($r, $$x, $ROUND);
        _new($r);
    }

    sub asinh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_asinh($r, $$x, $ROUND);
        _new($r);
    }

    sub cos {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cos($r, $$x, $ROUND);
        _new($r);
    }

    sub acos {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_acos($r, $$x, $ROUND);
        _new($r);
    }

    sub cosh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cosh($r, $$x, $ROUND);
        _new($r);
    }

    sub acosh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_acosh($r, $$x, $ROUND);
        _new($r);
    }

    sub tan {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tan($r, $$x, $ROUND);
        _new($r);
    }

    sub atan {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_atan($r, $$x, $ROUND);
        _new($r);
    }

    sub tanh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tanh($r, $$x, $ROUND);
        _new($r);
    }

    sub atanh {
        my ($x) = @_;
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_atanh($r, $$x, $ROUND);
        _new($r);
    }

    #
    ## csc(x) = 1/sin(x)
    #
    sub csc {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sin($r, $$x, $ROUND);
        Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
        _new($r);
    }

    #
    ## acsc(x) = asin(1/x)
    #
    sub acsc {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
        Math::MPC::Rmpc_asin($r, $r, $ROUND);
        _new($r);
    }

    #
    ## csch(x) = 1/sinh(x)
    #
    sub csch {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sinh($r, $$x, $ROUND);
        Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
        _new($r);
    }

    #
    ## acsch(x) = asinh(1/x)
    #
    sub acsch {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
        Math::MPC::Rmpc_asinh($r, $r, $ROUND);
        _new($r);
    }

    #
    ## sec(x) = 1/cos(x)
    #
    sub sec {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cos($r, $$x, $ROUND);
        Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
        _new($r);
    }

    #
    ## asec(x) = acos(1/x)
    #
    sub asec {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
        Math::MPC::Rmpc_acos($r, $r, $ROUND);
        _new($r);
    }

    #
    ## sech(x) = 1/cosh(x)
    #
    sub sech {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cosh($r, $$x, $ROUND);
        Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
        _new($r);
    }

    #
    ## asech(x) = acosh(1/x)
    #
    sub asech {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
        Math::MPC::Rmpc_acosh($r, $r, $ROUND);
        _new($r);
    }

    #
    ## cot(x) = 1/tan(x)
    #
    sub cot {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tan($r, $$x, $ROUND);
        Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
        _new($r);
    }

    #
    ## acot(x) = atan(1/x)
    #
    sub acot {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
        Math::MPC::Rmpc_atan($r, $r, $ROUND);
        _new($r);
    }

    #
    ## coth(x) = 1/tanh(x)
    #
    sub coth {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tanh($r, $$x, $ROUND);
        Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
        _new($r);
    }

    #
    ## acoth(x) = atanh(1/x)
    #
    sub acoth {
        my ($x) = @_;
        state $one = Math::MPC->new(1);
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
        Math::MPC::Rmpc_atanh($r, $r, $ROUND);
        _new($r);
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
            _valid($y);
        }

        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($r, $$x, $$y, $ROUND);
        Math::MPC::Rmpc_atan($r, $r, $ROUND);
        _new($r);
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
            _valid($y);
        }

        if (Math::MPC::Rmpc_cmp($$x, $$y) == 0) {
            state $z = Sidef::Types::Bool::Bool->true;
        }
        else {
            state $z = Sidef::Types::Bool::Bool->false;
        }
    }

    sub ne {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid($y);
        }

        if (Math::MPC::Rmpc_cmp($$x, $$y) == 0) {
            state $z = Sidef::Types::Bool::Bool->false;
        }
        else {
            state $z = Sidef::Types::Bool::Bool->true;
        }
    }

    sub gt {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid($y);
        }

        $x->abs->gt($y->abs);
    }

    sub ge {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid($y);
        }

        $x->abs->ge($y->abs);
    }

    sub lt {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid($y);
        }

        $x->abs->lt($y->abs);
    }

    sub le {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid($y);
        }

        $x->abs->le($y->abs);
    }

    sub cmp {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = __PACKAGE__->new($y);
        }
        else {
            _valid($y);
        }

        $x->abs->cmp($y->abs);
    }

    sub floor {
        $_[0]->abs->floor;
    }

    sub ceil {
        $_[0]->abs->ceil;
    }

    sub roundf {
        my ($x, $prec) = @_;
        $x->abs->roundf($prec);
    }

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
            return state $z = Sidef::Types::Bool::Bool->false;
        }

        my $re = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_real($re, ${$_[0]}, $ROUND);

        if (Math::MPFR::Rmpfr_integer_p($re)) {
            state $z = Sidef::Types::Bool::Bool->true;
        }
        else {
            state $z = Sidef::Types::Bool::Bool->false;
        }
    }

    # Returns true when the imaginary part is zero
    sub is_real {
        my ($x) = @_;
        my $im = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_imag($im, ${$_[0]}, $ROUND);

        if (Math::MPFR::Rmpfr_sgn($im) == 0) {
            state $z = Sidef::Types::Bool::Bool->true;
        }
        else {
            state $z = Sidef::Types::Bool::Bool->false;
        }
    }

    sub is_nan {
        state $x = Sidef::Types::Bool::Bool->false;
    }

    sub is_inf {
        state $x = Sidef::Types::Bool::Bool->false;
    }

    sub is_ninf {
        state $x = Sidef::Types::Bool::Bool->false;
    }

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
