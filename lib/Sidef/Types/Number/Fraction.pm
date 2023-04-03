package Sidef::Types::Number::Fraction {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Number::Number
    );

    use overload
      q{bool} => \&to_n,
      q{0+}   => \&to_n,
      q{""}   => \&__stringify__,
      q{${}}  => \&to_n;

    sub new {
        my (undef, $n, $m) = @_;

        # Handle evaluation of polynomials
        if (ref($_[0]) eq __PACKAGE__) {
            return $_[0]->eval($n);
        }

        $n //= Sidef::Types::Number::Number::ZERO;
        $m //= Sidef::Types::Number::Number::ONE;

        bless {a => $n, b => $m};
    }

    *call = \&new;

    sub stringify {
        my ($x) = @_;
        Sidef::Types::String::String->new(
                                    join('/', join('', '(', $x->{a}->stringify, ')'), join('', '(', $x->{b}->stringify, ')')));
    }

    *pretty = \&stringify;

    sub is_nan {
        my ($x) = @_;
        if ($x->{a}->is_zero and $x->{b}->is_zero) {
            return Sidef::Types::Bool::Bool::TRUE;
        }
        $x->{a}->is_nan or $x->{b}->is_nan;
    }

    sub is_real {
        my ($x) = @_;
        if ($x->{a}->is_zero and $x->{b}->is_zero) {
            return Sidef::Types::Bool::Bool::FALSE;
        }
        $x->{a}->is_real and $x->{b}->is_real;
    }

    sub eval {
        my ($x, $v) = @_;
        $x->{a}->eval($v)->div($x->{b}->eval($v));
    }

    sub lift {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->lift, $x->{b}->lift);
    }

    sub to_n {
        my ($x) = @_;
        my $r = $x->{a}->to_n->div($x->{b}->to_n);

        if (ref($r) ne 'Sidef::Types::Number::Number') {
            return $r->to_n;
        }

        return $r;
    }

    *__boolify__ = \&to_n;
    *__numify__  = \&to_n;

    sub __stringify__ {
        my ($x) = @_;
        'Fraction(' . join(', ', $x->{a}->dump, $x->{b}->dump) . ')';
    }

    sub to_s {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    sub dump {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    sub nu {
        $_[0]->{a};
    }

    *num       = \&nu;
    *numerator = \&nu;

    sub de {
        $_[0]->{b};
    }

    *den         = \&de;
    *denominator = \&de;

    sub nude {
        ($_[0]->{a}, $_[0]->{b});
    }

    sub parts {
        Sidef::Types::Array::Array->new([$_[0]->nude]);
    }

    sub neg {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->neg, $x->{b});
    }

    sub dec {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->sub($x->{b}), $x->{b},);
    }

    sub inc {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->add($x->{b}), $x->{b},);
    }

    sub is_zero {
        my ($x) = @_;
        $x->eq(Sidef::Types::Number::Number::ZERO);
    }

    sub is_one {
        my ($x) = @_;
        $x->eq(Sidef::Types::Number::Number::ONE);
    }

    sub is_mone {
        my ($x) = @_;
        $x->eq(Sidef::Types::Number::Number::MONE);
    }

    sub add {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            return __PACKAGE__->new($x->{a}->mul($y->{b})->add($y->{a}->mul($x->{b})), $x->{b}->mul($y->{b}));
        }

        __PACKAGE__->new($x->{a}->add($y->mul($x->{b})), $x->{b});
    }

    sub sub {
        my ($x, $y) = @_;
        $x->add($y->neg);
    }

    sub mul {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            return __PACKAGE__->new($x->{a}->mul($y->{a}), $x->{b}->mul($y->{b}));
        }

        __PACKAGE__->new($x->{a}->mul($y), $x->{b});
    }

    sub sqr {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->mul($x->{a}), $x->{b}->mul($x->{b}));
    }

    sub inv {
        my ($x) = @_;
        __PACKAGE__->new($x->{b}, $x->{a});
    }

    sub invmod {
        my ($x, $n) = @_;
        $x->inv->mod($n);
    }

    sub div {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            return __PACKAGE__->new($x->{a}->mul($y->{b}), $x->{b}->mul($y->{a}));
        }

        __PACKAGE__->new($x->{a}, $x->{b}->mul($y));
    }

    sub pow {
        my ($x, $n) = @_;

        if ($n->is_neg) {
            my $abs_n = $n->neg;
            return __PACKAGE__->new($x->{b}->pow($abs_n), $x->{a}->pow($abs_n));
        }

        __PACKAGE__->new($x->{a}->pow($n), $x->{b}->pow($n));
    }

    sub powmod {
        my ($x, $n, $m) = @_;

        $x = $x->mod($m);

        my $negative_power = 0;

        if ($n->is_neg) {
            $n              = $n->abs;
            $negative_power = 1;
        }

        my $c = __PACKAGE__->new(Sidef::Types::Number::Number::ONE, Sidef::Types::Number::Number::ONE);

        foreach my $bit (reverse split(//, $n->as_bin)) {

            # c = (c*x)%m if bit
            # x = (x*x)%m

            $c = $c->mul($x)->mod($m) if $bit;
            $x = $x->sqr->mod($m);
        }

        if ($negative_power) {
            $c = $c->invmod($m);
        }

        return $c;
    }

    sub lsft {
        my ($x, $n) = @_;
        __PACKAGE__->new($x->{a}->lsft($n), $x->{b});
    }

    sub rsft {
        my ($x, $n) = @_;
        __PACKAGE__->new($x->{a}, $x->{b}->lsft($n));
    }

    sub floor {
        my ($x) = @_;

        my $y = $x->{a}->div($x->{b});

        if (ref($y) ne __PACKAGE__) {
            return $y->floor;
        }

        $x->{a}->idiv_floor($x->{b});
    }

    sub ceil {
        my ($x) = @_;

        my $y = $x->{a}->div($x->{b});

        if (ref($y) ne __PACKAGE__) {
            return $y->ceil;
        }

        $x->{a}->idiv_ceil($x->{b});
    }

    sub round {
        my ($x) = @_;

        my $y = $x->{a}->div($x->{b});

        if (ref($y) ne __PACKAGE__) {
            return $y->round;
        }

        $x->{a}->idiv_round($x->{b});
    }

    sub trunc {
        my ($x) = @_;

        my $y = $x->{a}->div($x->{b});

        if (ref($y) ne __PACKAGE__) {
            return $y->trunc;
        }

        $x->{a}->idiv_trunc($x->{b});
    }

    sub mod {
        my ($x, $y) = @_;

        if (ref($y) ne __PACKAGE__) {
            return __PACKAGE__->new(Sidef::Types::Number::Mod->new($x->{a}, $y), Sidef::Types::Number::Mod->new($x->{b}, $y));
        }

        $x->sub($y->mul($x->div($y)->floor));
    }

    {
        no strict 'refs';

        foreach my $method (qw(eq ne lt le gt ge cmp or xor and)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;

                if (ref($y) ne __PACKAGE__) {
                    $y = __PACKAGE__->new($y);
                }

                $x->{a}->mul($y->{b})->$method($x->{b}->mul($y->{a}));
            };
        }

        *{__PACKAGE__ . '::' . '%'}   = \&mod;
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}   = \&div;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '<<'}  = \&lsft;
        *{__PACKAGE__ . '::' . '>>'}  = \&rsft;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'}   = \&le;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'}   = \&ge;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
    }
}

1
