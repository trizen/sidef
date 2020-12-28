package Sidef::Types::Number::Gauss {

    # Reference:
    #   https://en.wikipedia.org/wiki/Gaussian_integer

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Number::Number
      );

    use overload
      q{bool} => sub { (@_) = ($_[0]); goto &__boolify__ },
      q{""}   => sub { (@_) = ($_[0]); goto &__stringify__ },
      q{0+}   => \&to_c,
      q{${}}  => \&to_c;

    sub new {
        my (undef, $real, $imag) = @_;

        $real //= Sidef::Types::Number::Number::ZERO;
        $imag //= Sidef::Types::Number::Number::ZERO;

        $real = Sidef::Types::Number::Number->new($real) if !UNIVERSAL::isa($real, 'Sidef::Types::Number::Number');
        $imag = Sidef::Types::Number::Number->new($imag) if !UNIVERSAL::isa($imag, 'Sidef::Types::Number::Number');

        bless {re => $real, im => $imag};
    }

    *call = \&new;

    sub _valid {
        foreach (@_) {
            if (ref($$_) ne __PACKAGE__) {
                $$_ = __PACKAGE__->new($$_->to_n);
            }
        }
    }

    sub i {
        my ($x) = @_;

        if (ref($x) eq __PACKAGE__) {    # (a+bi)*i = -b + a*i
            return __PACKAGE__->new($x->{im}->neg, $x->{re});
        }

        __PACKAGE__->new(Sidef::Types::Number::Number::ZERO, Sidef::Types::Number::Number::ONE);
    }

    sub to_c {
        Sidef::Types::Number::Complex->new($_[0]->{re}, $_[0]->{im});
    }

    *to_n = \&to_c;

    sub re {
        $_[0]->{re};
    }

    *real = \&re;

    sub im {
        $_[0]->{im};
    }

    *imag = \&im;

    sub reals {
        ($_[0]->{re}, $_[0]->{im});
    }

    sub __boolify__ {
        $_[0]->{re};
    }

    sub __numify__ {
        $_[0]->{re};
    }

    sub __stringify__ {
        my ($x) = @_;
        '(' . join(', ', $x->{re}->dump, $x->{im}->dump) . ')';
    }

    sub to_s {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    sub dump {
        my ($x) = @_;
        Sidef::Types::String::String->new('Gauss' . $x->__stringify__);
    }

    sub abs {
        my ($x) = @_;
        $x->{re}->sqr->add($x->{im}->sqr)->sqrt;
    }

    sub iabs {
        my ($x) = @_;
        $x->{re}->sqr->add($x->{im}->sqr)->isqrt;
    }

    sub norm {
        my ($x) = @_;
        $x->{re}->sqr->add($x->{im}->sqr);
    }

    sub sgn {
        my ($x) = @_;
        $x->div($x->abs);
    }

    sub neg {
        my ($x) = @_;
        __PACKAGE__->new($x->{re}->neg, $x->{im}->neg);
    }

    sub conj {
        my ($x) = @_;
        __PACKAGE__->new($x->{re}, $x->{im}->neg);
    }

    sub add {
        my ($x, $y) = @_;
        _valid(\$y);
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_add($x->{re}, $x->{im}, $y->{re}, $y->{im}));
    }

    sub sub {
        my ($x, $y) = @_;
        _valid(\$y);
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_sub($x->{re}, $x->{im}, $y->{re}, $y->{im}));
    }

    sub mul {
        my ($x, $y) = @_;
        _valid(\$y);
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_mul($x->{re}, $x->{im}, $y->{re}, $y->{im}));
    }

    sub div {
        my ($x, $y) = @_;
        _valid(\$y);
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_div($x->{re}, $x->{im}, $y->{re}, $y->{im}));
    }

    sub float {
        my ($x) = @_;
        __PACKAGE__->new($x->{re}->float, $x->{im}->float);
    }

    sub floor {
        my ($x) = @_;
        __PACKAGE__->new($x->{re}->floor, $x->{im}->floor);
    }

    sub ceil {
        my ($x) = @_;
        __PACKAGE__->new($x->{re}->ceil, $x->{im}->ceil);
    }

    sub round {
        my ($x, $r) = @_;
        __PACKAGE__->new($x->{re}->round($r), $x->{im}->round($r));
    }

    sub mod {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return __PACKAGE__->new(Sidef::Types::Number::Number::complex_mod($x->{re}, $x->{im}, $y));
        }

        # mod(a, b) = a - b * floor(a/b)
        $x->sub($y->mul($x->div($y)->floor));
    }

    sub inv {
        my ($x) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_inv($x->{re}, $x->{im}));
    }

    sub is_prime {
        my ($x) = @_;
        Sidef::Types::Number::Number::is_gaussian_prime($x->{re}, $x->{im});
    }

    sub is_zero {
        my ($x) = @_;
        my $bool = $x->{re}->is_zero;
        $bool || return $bool;
        $x->{im}->is_zero;
    }

    sub is_one {
        my ($x) = @_;
        my $bool = $x->{im}->is_zero;
        $bool || return $bool;
        $x->{re}->is_one;
    }

    sub is_mone {
        my ($x) = @_;
        my $bool = $x->{im}->is_zero;
        $bool || return $bool;
        $x->{re}->is_mone;
    }

    sub is_real {
        my ($x) = @_;
        $x->{im}->is_zero;
    }

    sub is_imag {
        my ($x) = @_;
        my $bool = $x->{im}->is_zero;
        $bool && return $bool->not;
        $x->{re}->is_zero;
    }

    sub gcd {
        my ($n, $k) = @_;
        _valid(\$k);

        my $norm_n = $n->norm;
        my $norm_k = $k->norm;

        if ($norm_n->gt($norm_k)) {
            ($n, $k) = ($k, $n);
        }

        until ($k->is_zero) {

            my $q = $n->div($k)->round;
            my $r = $n->sub($q->mul($k));

            ($n, $k) = ($k, $r);
        }

        $n;
    }

    sub gcd_norm {
        my ($n, $k) = @_;
        _valid(\$k);
        $n->norm->gcd($k->norm);
    }

    sub is_coprime {
        my ($n, $k) = @_;
        _valid(\$k);
        $n->norm->gcd($k->norm)->is_one;
    }

    sub ratmod {
        my ($x, $m) = @_;
        __PACKAGE__->new($x->{re}->ratmod($m), $x->{im}->ratmod($m));
    }

    sub invmod {
        my ($x, $m) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_invmod($x->{re}, $x->{im}, $m));
    }

    sub inc {
        my ($x) = @_;
        __PACKAGE__->new($x->{re}->inc, $x->{im});
    }

    sub dec {
        my ($x) = @_;
        __PACKAGE__->new($x->{re}->dec, $x->{im});
    }

    sub pow {
        my ($x, $n) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_pow($x->{re}, $x->{im}, $n));
    }

    sub powmod {
        my ($x, $n, $m) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_powmod($x->{re}, $x->{im}, $n, $m));
    }

    sub cmp {
        my ($x, $y) = @_;
        _valid(\$y);
        Sidef::Types::Number::Number::complex_cmp($x->{re}, $x->{im}, $y->{re}, $y->{im});
    }

    sub eq {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            my $bool = $x->{re}->eq($y->{re});
            $bool || return $bool;
            return $x->{im}->eq($y->{im});
        }

        my $bool = $x->{re}->eq($y);
        $bool || return $bool;
        $x->{im}->is_zero;
    }

    sub ne {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            my $bool = $x->{re}->ne($y->{re});
            $bool && return $bool;
            return $x->{im}->ne($y->{im});
        }

        my $bool = $x->{re}->ne($y);
        $bool && return $bool;
        $x->{im}->is_zero->not;
    }

    sub shift_left {    # x * 2^n
        my ($x, $n) = @_;
        $x->mul(Sidef::Types::Number::Number::TWO->pow($n));
    }

    *lsft = \&shift_left;

    sub shift_right {    # x / 2^n
        my ($x, $n) = @_;
        $x->div(Sidef::Types::Number::Number::TWO->pow($n));
    }

    *rsft = \&shift_right;

    {
        no strict 'refs';

        foreach my $method (qw(ge gt lt le)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;
                _valid(\$y);
                (Sidef::Types::Number::Number::complex_cmp($x->{re}, $x->{im}, $y->{re}, $y->{im}) // return undef)
                  ->$method(Sidef::Types::Number::Number::ZERO);
            };
        }

        foreach my $method (qw(and xor or)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;
                _valid(\$y);
                __PACKAGE__->new($x->{re}->$method($y->{re}), $x->{im}->$method($y->{im}));
            };
        }

        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}   = \&div;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '%'}   = \&mod;
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
