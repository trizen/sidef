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

        # Handle evaluation of polynomials
        if (ref($_[0]) eq __PACKAGE__) {
            return $_[0]->eval($real);
        }

        $real //= Sidef::Types::Number::Number::ZERO;
        $imag //= Sidef::Types::Number::Number::ZERO;

        $real = Sidef::Types::Number::Number->new($real) if !UNIVERSAL::isa($real, 'Sidef::Types::Number::Number');
        $imag = Sidef::Types::Number::Number->new($imag) if !UNIVERSAL::isa($imag, 'Sidef::Types::Number::Number');

        bless {a => $real, b => $imag};
    }

    *call = \&new;

    sub eval {
        my ($x, $v) = @_;
        __PACKAGE__->new($x->{a}->eval($v), $x->{b}->eval($v));
    }

    sub lift {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->lift, $x->{b}->lift);
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

    *a    = \&re;
    *real = \&re;

    sub im {
        $_[0]->{b};
    }

    *b    = \&im;
    *imag = \&im;

    sub reals {
        ($_[0]->{a}, $_[0]->{b});
    }

    sub parts {
        Sidef::Types::Array::Array->new($_[0]->reals);
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

    sub stringify {
        my ($x) = @_;
        Sidef::Types::String::String->new(join(' + ', $x->{a}->stringify, join('', '(', $x->{b}->stringify, ')*1i')));
    }

    *pretty = \&stringify;

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

        if (ref($y) eq __PACKAGE__) {
            return __PACKAGE__->new($x->{a}->add($y->{a}), $x->{b}->add($y->{b}));
        }

        __PACKAGE__->new($x->{a}->add($y), $x->{b});
    }

    sub sub {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            return __PACKAGE__->new($x->{a}->sub($y->{a}), $x->{b}->sub($y->{b}));
        }

        __PACKAGE__->new($x->{a}->sub($y), $x->{b});
    }

    sub mul {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            return
              __PACKAGE__->new($x->{a}->mul($y->{a})->sub($x->{b}->mul($y->{b})),
                               $x->{a}->mul($y->{b})->add($x->{b}->mul($y->{a})));
        }

        __PACKAGE__->new($x->{a}->mul($y), $x->{b}->mul($y));
    }

    sub sqr {
        my ($x) = @_;
        my $t = $x->{a}->mul($x->{b});
        __PACKAGE__->new($x->{a}->sqr->sub($x->{b}->sqr), $t->add($t));
    }

    sub inv {
        my ($x) = @_;
        my $t = $x->{a}->sqr->add($x->{b}->sqr);
        __PACKAGE__->new($x->{a}->div($t), $x->{b}->neg->div($t));
    }

    sub invmod {
        my ($x, $m) = @_;
        $x->mod($m);
        my $t = $x->{a}->sqr->add($x->{b}->sqr)->invmod($m);
        __PACKAGE__->new($x->{a}->mul($t)->mod($m), $x->{b}->neg->mul($t)->mod($m));
    }

    sub div {
        my ($x, $y) = @_;
        $x->mul($y->inv);
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
            return __PACKAGE__->new($x->{a}->mod($y), $x->{b}->mod($y));
        }

        # mod(a, b) = a - b * floor(a/b)
        $x->sub($y->mul($x->div($y)->floor));
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

        my $norm_n = $n->norm;
        my $norm_k = $k->norm;

        if ($norm_n->gt($norm_k)) {
            ($n, $k) = ($k, $n);
        }

        until ($k->is_zero) {

            last if ($n->is_nan or $k->is_nan);

            my $q = $n->div($k)->round;
            my $r = $n->sub($q->mul($k));

            ($n, $k) = ($k, $r);
        }

        $n;
    }

    sub gcd_norm {
        my ($n, $k) = @_;
        $n->norm->gcd($k->norm);
    }

    sub is_coprime {
        my ($n, $k) = @_;
        $n->norm->gcd($k->norm)->is_one;
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

        $n->is_int || return $x->to_n->pow($n);

        my $negative_power = 0;

        if ($n->is_neg) {
            $n              = $n->abs;
            $negative_power = 1;
        }

        my $c = __PACKAGE__->new(Sidef::Types::Number::Number::ONE);

        foreach my $bit (reverse split(//, $n->as_bin)) {

            # c *= x if bit
            # x *= x

            $c = $c->mul($x) if $bit;
            $x = $x->sqr;
        }

        if ($negative_power) {
            $c = $c->inv;
        }

        return $c;
    }

    sub powmod {
        my ($x, $n, $m) = @_;

        $x = $x->mod($m);

        my $negative_power = 0;

        if ($n->is_neg) {
            $n              = $n->abs;
            $negative_power = 1;
        }

        my $c = __PACKAGE__->new(Sidef::Types::Number::Number::ONE);

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

    sub cmp {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            my $cmp = $x->{a}->cmp($y->{a}) // return undef;
            $cmp && return $cmp;
            return $x->{b}->cmp($y->{b});
        }

        my $cmp = $x->{a}->cmp($y) // return undef;
        $cmp && return $cmp;
        $x->{b}->cmp(Sidef::Types::Number::Number::ZERO);
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
                ($x->cmp($y) // return undef)->$method(Sidef::Types::Number::Number::ZERO);
            };
        }

        foreach my $method (qw(and xor or)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;

                if (ref($y) eq __PACKAGE__) {
                    return __PACKAGE__->new($x->{a}->$method($y->{a}), $x->{b}->$method($y->{b}));
                }

                return __PACKAGE__->new($x->{a}->$method($y), $x->{b});
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
