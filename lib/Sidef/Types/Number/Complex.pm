package Sidef::Types::Number::Complex {

    use utf8;
    use 5.014;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      Sidef::Types::Number::Number
      );

    use overload
      q{""}   => \&get_value,
      q{0+}   => \&get_value,
      q{bool} => \&get_value;

    use Math::MPC qw(:mpc);
    use Math::MPFR qw(:mpfr);

    our $ROUND = MPC_RNDNN;
    our $PREC  = $Sidef::Types::Number::Number::PREC;

    sub new {
        my (undef, $x, $y) = @_;

        if (ref($x) eq 'Sidef::Types::Number::Number') {
            $x = $$x;
        }
        elsif (ref($x) eq __PACKAGE__) {
            return $x if not defined $y;
            my $mpfr = Rmpfr_init2($PREC);
            Rmpc_real($mpfr, ${$_[0]}, $ROUND);
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
            my $mpfr = Rmpfr_init2($PREC);
            Rmpc_real($mpfr, ${$_[0]}, $ROUND);
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
        my $re = $_[0]->re->get_value;
        my $im = $_[0]->im->get_value;
        $im eq '0' ? $re : ($re . (substr($im, 0, 1) eq '-' ? '' : '+') . $im . 'i');
    }

    sub dump {
        Sidef::Types::String::String->new("Complex(" . $_[0]->re->get_value . ", ". $_[0]->im->get_value. ")");
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
            warn qq{[WARN] Inexistent Math constant "$name"!\n};
            undef;
        };
    }

    sub abs {
        my $mpfr = Rmpfr_init2($PREC);
        Rmpc_abs($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_new(Sidef::Types::Number::Number::_mpfr2rat($mpfr));
    }

    sub norm {
        my $mpfr = Rmpfr_init2($PREC);
        Rmpc_norm($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_new(Sidef::Types::Number::Number::_mpfr2rat($mpfr));
    }

    *reciprocal = \&norm;

    sub real {
        my $mpfr = Rmpfr_init2($PREC);
        Rmpc_real($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_new(Sidef::Types::Number::Number::_mpfr2rat($mpfr));
    }

    *re = \&real;

    sub imag {
        my $mpfr = Rmpfr_init2($PREC);
        Rmpc_imag($mpfr, ${$_[0]}, $ROUND);
        Sidef::Types::Number::Number::_new(Sidef::Types::Number::Number::_mpfr2rat($mpfr));
    }

    *im = \&imag;

    sub neg {
        my ($x) = @_;
        my $r = Rmpc_init2($PREC);
        Rmpc_neg($r, $$x, $ROUND);
        _new($r);
    }

    sub conj {
        my ($x) = @_;
        my $r = Rmpc_init2($PREC);
        Rmpc_conj($r, $$x, $ROUND);
        _new($r);
    }

    *not       = \&conj;
    *conjugate = \&conj;

    #
    ## Arithmetic operations
    #

    sub add {
        my ($x, $y) = @_;
        my $r = Rmpc_init2($PREC);

        if (ref($y) eq __PACKAGE__) {
            Rmpc_add($r, $$x, $$y, $ROUND);
        }
        else {
            Rmpc_add_fr($r, $$x, $y->_as_float(), $ROUND);
        }

        _new($r);
    }

    sub sub {
        my ($x, $y) = @_;
        my $r = Rmpc_init2($PREC);

        if (ref($y) eq __PACKAGE__) {
            Rmpc_sub($r, $$x, $$y, $ROUND);
        }
        else {
            Rmpc_add_fr($r, $$x, -$y->_as_float(), $ROUND);
        }

        _new($r);
    }

    sub mul {
        my ($x, $y) = @_;
        my $r = Rmpc_init2($PREC);

        if (ref($y) eq __PACKAGE__) {
            Rmpc_mul($r, $$x, $$y, $ROUND);
        }
        else {
            Rmpc_mul_fr($r, $$x, $y->_as_float(), $ROUND);
        }

        _new($r);
    }

    sub div {
        my ($x, $y) = @_;
        my $r = Rmpc_init2($PREC);

        if (ref($y) eq __PACKAGE__) {
            Rmpc_div($r, $$x, $$y, $ROUND);
        }
        else {
            Rmpc_div_fr($r, $$x, $y->_as_float(), $ROUND);
        }

        _new($r);
    }

    sub pow {
        my ($x, $y) = @_;
        my $r = Rmpc_init2($PREC);

        if (ref($y) eq __PACKAGE__) {
            Rmpc_pow($r, $$x, $$y, $ROUND);
        }
        else {
            Rmpc_pow_fr($r, $$x, $y->_as_float(), $ROUND);
        }

        _new($r);
    }

    sub sqrt {
        my ($x) = @_;
        my $r = Rmpc_init2($PREC);
        Rmpc_sqrt($r, $$x, $ROUND);
        _new($r);
    }

    sub exp {
        my ($x) = @_;
        my $r = Rmpc_init2($PREC);
        Rmpc_exp($r, $$x, $ROUND);
        _new($r);
    }

    sub log {
        my ($x) = @_;
        my $r = Rmpc_init2($PREC);
        Rmpc_log($r, $$x, $ROUND);
        _new($r);
    }

    sub dec {
        my ($x) = @_;
        state $one_c = $x->new(1);
        $x->sub($one_c);
    }

    sub inc {
        my ($x) = @_;
        state $one_c = $x->new(1);
        $x->add($one_c);
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

        Sidef::Types::Bool::Bool->new(Rmpc_cmp($$x, $$y) == 0);
    }

    sub gt {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return $x->gt(__PACKAGE__->new($y));
        }
        else {
            _valid($y);
        }

        my $cmp = Rmpc_cmp($$x, $$y);
        my $re  = RMPC_INEX_RE($cmp);
        my $im  = RMPC_INEX_IM($cmp);

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

        my $cmp = Rmpc_cmp($$x, $$y);
        my $re  = RMPC_INEX_RE($cmp);
        my $im  = RMPC_INEX_IM($cmp);

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

        my $cmp = Rmpc_cmp($$x, $$y);
        my $re  = RMPC_INEX_RE($cmp);
        my $im  = RMPC_INEX_IM($cmp);

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

        my $cmp = Rmpc_cmp($$x, $$y);
        my $re  = RMPC_INEX_RE($cmp);
        my $im  = RMPC_INEX_IM($cmp);

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

            $x->eq($y) ? Sidef::Types::Number::Number::ZERO
          : $x->gt($y) ? Sidef::Types::Number::Number::ONE
          :              Sidef::Types::Number::Number::MONE;
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
