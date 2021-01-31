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

        bless {a => $real, b => $imag};
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
            return __PACKAGE__->new($x->{b}->neg, $x->{a});
        }

        __PACKAGE__->new(Sidef::Types::Number::Number::ZERO, Sidef::Types::Number::Number::ONE);
    }

    sub to_c {
        Sidef::Types::Number::Complex->new($_[0]->{a}, $_[0]->{b});
    }

    *to_n = \&to_c;

    sub re {
        $_[0]->{a};
    }

    *real = \&re;

    sub im {
        $_[0]->{b};
    }

    *imag = \&im;

    sub reals {
        ($_[0]->{a}, $_[0]->{b});
    }

    sub __boolify__ {
        $_[0]->{a};
    }

    sub __numify__ {
        $_[0]->{a};
    }

    sub __stringify__ {
        my ($x) = @_;
        'Gauss(' . join(', ', $x->{a}->dump, $x->{b}->dump) . ')';
    }

    sub to_s {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    sub dump {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    sub abs {
        my ($x) = @_;
        $x->{a}->sqr->add($x->{b}->sqr)->sqrt;
    }

    sub iabs {
        my ($x) = @_;
        $x->{a}->sqr->add($x->{b}->sqr)->isqrt;
    }

    sub norm {
        my ($x) = @_;
        $x->{a}->sqr->add($x->{b}->sqr);
    }

    sub sgn {
        my ($x) = @_;
        $x->div($x->abs);
    }

    sub neg {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->neg, $x->{b}->neg);
    }

    sub conj {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}, $x->{b}->neg);
    }

    sub add {
        my ($x, $y) = @_;
        _valid(\$y);
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_add($x->{a}, $x->{b}, $y->{a}, $y->{b}));
    }

    sub sub {
        my ($x, $y) = @_;
        _valid(\$y);
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_sub($x->{a}, $x->{b}, $y->{a}, $y->{b}));
    }

    sub mul {
        my ($x, $y) = @_;
        _valid(\$y);
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_mul($x->{a}, $x->{b}, $y->{a}, $y->{b}));
    }

    sub div {
        my ($x, $y) = @_;
        _valid(\$y);
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_div($x->{a}, $x->{b}, $y->{a}, $y->{b}));
    }

    sub float {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->float, $x->{b}->float);
    }

    sub floor {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->floor, $x->{b}->floor);
    }

    sub ceil {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->ceil, $x->{b}->ceil);
    }

    sub round {
        my ($x, $r) = @_;
        __PACKAGE__->new($x->{a}->round($r), $x->{b}->round($r));
    }

    sub mod {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return __PACKAGE__->new(Sidef::Types::Number::Number::complex_mod($x->{a}, $x->{b}, $y));
        }

        # mod(a, b) = a - b * floor(a/b)
        $x->sub($y->mul($x->div($y)->floor));
    }

    sub inv {
        my ($x) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_inv($x->{a}, $x->{b}));
    }

    sub is_prime {
        my ($x) = @_;
        Sidef::Types::Number::Number::is_gaussian_prime($x->{a}, $x->{b});
    }

    sub is_zero {
        my ($x) = @_;
        my $bool = $x->{a}->is_zero;
        $bool || return $bool;
        $x->{b}->is_zero;
    }

    sub is_one {
        my ($x) = @_;
        my $bool = $x->{b}->is_zero;
        $bool || return $bool;
        $x->{a}->is_one;
    }

    sub is_mone {
        my ($x) = @_;
        my $bool = $x->{b}->is_zero;
        $bool || return $bool;
        $x->{a}->is_mone;
    }

    sub is_real {
        my ($x) = @_;
        $x->{b}->is_zero;
    }

    sub is_imag {
        my ($x) = @_;
        my $bool = $x->{b}->is_zero;
        $bool && return $bool->not;
        $x->{a}->is_zero;
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
        __PACKAGE__->new($x->{a}->ratmod($m), $x->{b}->ratmod($m));
    }

    sub invmod {
        my ($x, $m) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_invmod($x->{a}, $x->{b}, $m));
    }

    sub inc {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->inc, $x->{b});
    }

    sub dec {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->dec, $x->{b});
    }

    sub pow {
        my ($x, $n) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_pow($x->{a}, $x->{b}, $n));
    }

    sub powmod {
        my ($x, $n, $m) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::complex_powmod($x->{a}, $x->{b}, $n, $m));
    }

    sub cmp {
        my ($x, $y) = @_;
        _valid(\$y);
        Sidef::Types::Number::Number::complex_cmp($x->{a}, $x->{b}, $y->{a}, $y->{b});
    }

    sub eq {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            my $bool = $x->{a}->eq($y->{a});
            $bool || return $bool;
            return $x->{b}->eq($y->{b});
        }

        my $bool = $x->{a}->eq($y);
        $bool || return $bool;
        $x->{b}->is_zero;
    }

    sub ne {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            my $bool = $x->{a}->ne($y->{a});
            $bool && return $bool;
            return $x->{b}->ne($y->{b});
        }

        my $bool = $x->{a}->ne($y);
        $bool && return $bool;
        $x->{b}->is_zero->not;
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
                (Sidef::Types::Number::Number::complex_cmp($x->{a}, $x->{b}, $y->{a}, $y->{b}) // return undef)
                  ->$method(Sidef::Types::Number::Number::ZERO);
            };
        }

        foreach my $method (qw(and xor or)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;
                _valid(\$y);
                __PACKAGE__->new($x->{a}->$method($y->{a}), $x->{b}->$method($y->{b}));
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
