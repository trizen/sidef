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
    our $PREC  = $Sidef::Types::Number::Number::PREC;

    sub new {
        my (undef, $x, $y) = @_;

        if (ref($x) eq 'Sidef::Types::Number::Number') {
            $x = $$x;
        }
        elsif (ref($x) eq __PACKAGE__) {
            return $x if not defined $y;
            my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPC::Rmpc_real($mpfr, ${$_[0]}, $ROUND);
            $x = $mpfr;
        }
        elsif (index(ref($x), 'Sidef::') == 0) {
            $x = $x->get_value;
        }

        return bless(\Math::MPC->new($x // 0), __PACKAGE__) if not defined $y;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            $y = $$y;
        }
        elsif (ref($y) eq __PACKAGE__) {
            my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPC::Rmpc_real($mpfr, ${$_[0]}, $ROUND);
            $x = $mpfr;
        }
        elsif (index(ref($y), 'Sidef::') == 0) {
            $y = $y->get_value;
        }

        bless \Math::MPC->new($x, $y), __PACKAGE__;
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
        Math::MPFR::Rmpfr_const_pi($pi, $ROUND);
        my $cplx_pi = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($cplx_pi, $pi, $ROUND);
        _new($cplx_pi);
    }

    sub e {
        state $one_f = (Math::MPFR::Rmpfr_init_set_ui(1, $ROUND))[0];
        my $e = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_exp($e, $one_f, $ROUND);
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
        state $one_f  = (Math::MPFR::Rmpfr_init_set_ui(1, $ROUND))[0];
        state $two_f  = (Math::MPFR::Rmpfr_init_set_ui(2, $ROUND))[0];
        state $five_f = (Math::MPFR::Rmpfr_init_set_ui(5, $ROUND))[0];

        my $phi = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sqrt($phi, $five_f, $ROUND);
        Math::MPFR::Rmpfr_add($phi, $phi, $one_f, $ROUND);
        Math::MPFR::Rmpfr_div($phi, $phi, $two_f, $ROUND);

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
        Sidef::Types::Number::Number::_new(Sidef::Types::Number::Number::_mpfr2rat($mpfr));
    }

    sub norm {
        my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_norm($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_new(Sidef::Types::Number::Number::_mpfr2rat($mpfr));
    }

    *reciprocal = \&norm;

    sub real {
        my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_real($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_new(Sidef::Types::Number::Number::_mpfr2rat($mpfr));
    }

    *re = \&real;

    sub imag {
        my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_imag($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_new(Sidef::Types::Number::Number::_mpfr2rat($mpfr));
    }

    *im = \&imag;

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
                Math::MPFR::Rmpfr_log($baseln, $y->_as_float(), $ROUND);
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

        state $two = (Math::MPFR::Rmpfr_init_set_ui(2, $ROUND))[0];

        my $baseln = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_log($baseln, $two, $ROUND);
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
    ## Testing
    #

    sub eq {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return $x->eq(__PACKAGE__->new($y));
        }
        else {
            _valid($y);
        }

        Sidef::Types::Bool::Bool->new(Math::MPC::Rmpc_cmp($$x, $$y) == 0);
    }

    sub gt {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return $x->gt(__PACKAGE__->new($y));
        }
        else {
            _valid($y);
        }

        my $cmp = Math::MPC::Rmpc_cmp($$x, $$y);
        my $re  = Math::MPC::RMPC_INEX_RE($cmp);
        my $im  = Math::MPC::RMPC_INEX_IM($cmp);

        Sidef::Types::Bool::Bool->new($re > 0 ? $im >= 0 : $re >= 0 ? $im > 0 : 0);
    }

    sub ge {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return $x->ge(__PACKAGE__->new($y));
        }
        else {
            _valid($y);
        }

        my $cmp = Math::MPC::Rmpc_cmp($$x, $$y);
        my $re  = Math::MPC::RMPC_INEX_RE($cmp);
        my $im  = Math::MPC::RMPC_INEX_IM($cmp);

        Sidef::Types::Bool::Bool->new($re >= 0 and $im >= 0);
    }

    sub lt {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return $x->lt(__PACKAGE__->new($y));
        }
        else {
            _valid($y);
        }

        my $cmp = Math::MPC::Rmpc_cmp($$x, $$y);
        my $re  = Math::MPC::RMPC_INEX_RE($cmp);
        my $im  = Math::MPC::RMPC_INEX_IM($cmp);

        Sidef::Types::Bool::Bool->new($re < 0 ? $im <= 0 : $re <= 0 ? $im < 0 : 0);
    }

    sub le {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return $x->le(__PACKAGE__->new($y));
        }
        else {
            _valid($y);
        }

        my $cmp = Math::MPC::Rmpc_cmp($$x, $$y);
        my $re  = Math::MPC::RMPC_INEX_RE($cmp);
        my $im  = Math::MPC::RMPC_INEX_IM($cmp);

        Sidef::Types::Bool::Bool->new($re <= 0 and $im <= 0);
    }

    sub cmp {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return $x->le(__PACKAGE__->new($y));
        }
        else {
            _valid($y);
        }

            $x->eq($y) ? $Sidef::Types::Number::Number::ZERO
          : $x->gt($y) ? $Sidef::Types::Number::Number::ONE
          :              $Sidef::Types::Number::Number::MONE;
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
