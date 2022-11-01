package Sidef::Types::Number::Quadratic {

    # Reference:
    #   https://en.wikipedia.org/wiki/Quadratic_integer

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Number::Number
    );

    use overload
      q{bool} => sub { (@_) = ($_[0]); goto &__boolify__ },
      q{""}   => sub { (@_) = ($_[0]); goto &__stringify__ },
      q{0+}   => \&to_n,
      q{${}}  => \&to_n;

    sub new {
        my (undef, $x, $y, $w) = @_;

        # Handle evaluation of polynomials
        if (ref($_[0]) eq __PACKAGE__) {
            return $_[0]->eval($x);
        }

        $x //= Sidef::Types::Number::Number::ZERO;
        $y //= Sidef::Types::Number::Number::ZERO;
        $w //= Sidef::Types::Number::Number::ONE;

        $x = Sidef::Types::Number::Number->new($x) if !UNIVERSAL::isa($x, 'Sidef::Types::Number::Number');
        $y = Sidef::Types::Number::Number->new($y) if !UNIVERSAL::isa($y, 'Sidef::Types::Number::Number');
        $w = Sidef::Types::Number::Number->new($w) if !UNIVERSAL::isa($w, 'Sidef::Types::Number::Number');

        bless {a => $x, b => $y, w => $w};
    }

    *call = \&new;

    sub eval {
        my ($x, $v) = @_;
        __PACKAGE__->new($x->{a}->eval($v), $x->{b}->eval($v), $x->{w}->eval($v));
    }

    sub lift {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->lift, $x->{b}->lift, $x->{w}->lift);
    }

    sub a {
        $_[0]->{a};
    }

    *re   = \&a;
    *real = \&a;

    sub b {
        $_[0]->{b};
    }

    *im   = \&b;
    *imag = \&b;

    sub w {
        $_[0]->{w};
    }

    *order = \&w;

    sub reals {
        ($_[0]->{a}, $_[0]->{b});
    }

    sub parts {
        Sidef::Types::Array::Array->new($_[0]->{a}, $_[0]->{b}, $_[0]->{w});
    }

    sub __boolify__ {
        $_[0]->{a};
    }

    sub __numify__ {
        $_[0]->{a};
    }

    sub __stringify__ {
        my ($x) = @_;
        'Quadratic(' . join(', ', $x->{a}->dump, $x->{b}->dump, $x->{w}->dump) . ')';
    }

    sub stringify {
        my ($x) = @_;
        Sidef::Types::String::String->new(
                       join(' + ', $x->{a}->stringify, join('', '(', $x->{b}->stringify, ')*sqrt(', $x->{w}->stringify, ')')));
    }

    *pretty = \&stringify;

    sub to_s {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    sub dump {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    sub to_n {
        my ($x) = @_;
        my $r = $x->{a}->add($x->{b}->mul($x->{w}->sqrt));

        if (ref($r) ne 'Sidef::Types::Number::Number') {
            return $r->to_n;
        }

        return $r;
    }

    *to_c = \&to_n;

    sub abs {
        my ($x) = @_;
        $x->norm->sqrt;
    }

    sub norm {
        my ($x) = @_;
        $x->{a}->sqr->sub($x->{b}->sqr->mul($x->{w}));
    }

    sub sgn {
        my ($x) = @_;
        $x->div($x->abs);
    }

    sub neg {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->neg, $x->{b}->neg, $x->{w});
    }

    sub conj {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}, $x->{b}->neg, $x->{w});
    }

    sub sqr {
        my ($x) = @_;
        my $t = $x->{a}->mul($x->{b});
        __PACKAGE__->new($x->{a}->sqr->add($x->{b}->sqr->mul($x->{w})), $t->add($t), $x->{w});
    }

    sub add {
        my ($x, $y) = @_;

        # (x + y√d) + (z + w√d) = (x + z) + (y + w)√d

        if (ref($y) eq __PACKAGE__ and $x->{w} eq $y->{w}) {
            return __PACKAGE__->new($x->{a}->add($y->{a}), $x->{b}->add($y->{b}), $x->{w});
        }

        __PACKAGE__->new($x->{a}->add($y), $x->{b}, $x->{w});
    }

    sub sub {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__ and $x->{w} eq $y->{w}) {
            return __PACKAGE__->new($x->{a}->sub($y->{a}), $x->{b}->sub($y->{b}), $x->{w});
        }

        __PACKAGE__->new($x->{a}->sub($y), $x->{b}, $x->{w});
    }

    sub mul {
        my ($x, $y) = @_;

        # (x + y√d) (z + w√d) = (xz+ ywd) + (xw + yz)√d

        if (ref($y) eq __PACKAGE__ and $x->{w} eq $y->{w}) {
            return __PACKAGE__->new(

                # Quadratic(a*a' + b*b'*w, a*b' + b*a', w)

                $x->{a}->mul($y->{a})->add($x->{b}->mul($y->{b})->mul($x->{w})),
                $x->{a}->mul($y->{b})->add($x->{b}->mul($y->{a})),
                $x->{w},
                                   );
        }

        __PACKAGE__->new($x->{a}->mul($y), $x->{b}->mul($y), $x->{w});
    }

    sub div {
        my ($x, $y) = @_;
        $x->mul($y->inv);
    }

    sub float {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->float, $x->{b}->float, $x->{w});
    }

    sub floor {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->floor, $x->{b}->floor, $x->{w});
    }

    sub ceil {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->ceil, $x->{b}->ceil, $x->{w});
    }

    sub round {
        my ($x, $r) = @_;
        __PACKAGE__->new($x->{a}->round($r), $x->{b}->round($r), $x->{w});
    }

    sub mod {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return __PACKAGE__->new($x->{a}->mod($y), $x->{b}->mod($y), $x->{w});
        }

        # mod(a, b) = a - b * floor(a/b)
        $x->sub($y->mul($x->div($y)->floor));
    }

    sub inv {
        my ($x) = @_;

        # 1/(a + b*sqrt(w)) = (a - b*sqrt(w)) / (a^2 - b^2*w)
        #                   = a/(a^2 - b^2*w) - b/(a^2 - b^2*w) * sqrt(w)

        my $t = $x->{a}->sqr->sub($x->{b}->sqr->mul($x->{w}));

        __PACKAGE__->new($x->{a}->div($t), $x->{b}->div($t)->neg, $x->{w});
    }

    sub invmod {
        my ($x, $m) = @_;

        $x = $x->mod($m);
        my $t = $x->{a}->sqr->sub($x->{b}->sqr->mul($x->{w}))->invmod($m);

        __PACKAGE__->new($x->{a}->mul($t)->mod($m), $x->{b}->mul($t)->neg->mod($m), $x->{w});
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

    sub is_coprime {
        my ($n, $k) = @_;
        $n->norm->gcd($k->norm)->is_one;
    }

    sub inc {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->inc, $x->{b}, $x->{w});
    }

    sub dec {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->dec, $x->{b}, $x->{w});
    }

    sub pow {
        my ($x, $n) = @_;

        $n->is_int || return $x->to_n->pow($n);

        my $negative_power = 0;

        if ($n->is_neg) {
            $n              = $n->abs;
            $negative_power = 1;
        }

        my $c = __PACKAGE__->new(Sidef::Types::Number::Number::ONE, Sidef::Types::Number::Number::ZERO, $x->{w});

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

        my $c = __PACKAGE__->new(Sidef::Types::Number::Number::ONE, Sidef::Types::Number::Number::ZERO, $x->{w});

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
            $cmp = $x->{b}->cmp($y->{b}) // return undef;
            $cmp && return $cmp;
            return $x->{w}->cmp($y->{w});
        }

        my $cmp = $x->{a}->cmp($y) // return undef;
        $cmp && return $cmp;
        $x->{b}->cmp(Sidef::Types::Number::Number::ZERO);
    }

    sub eq {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            my $bool = $x->{a}->eq($y->{a}) // return undef;
            $bool || return $bool;
            $bool = $x->{b}->eq($y->{b}) // return undef;
            $bool || return $bool;
            return $x->{w}->eq($y->{w});
        }

        my $bool = $x->{a}->eq($y) // return undef;
        $bool || return $bool;
        $x->{b}->is_zero;
    }

    sub ne {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            my $bool = $x->{a}->ne($y->{a});
            $bool && return $bool;
            $bool = $x->{b}->ne($y->{b});
            $bool && return $bool;
            return ($x->{w}->ne($y->{w}));
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

                if (ref($y) eq __PACKAGE__ and $x->{w} eq $y->{w}) {
                    return __PACKAGE__->new($x->{a}->$method($y->{a}), $x->{b}->$method($y->{b}), $x->{w});
                }

                return __PACKAGE__->new($x->{a}->$method($y), $x->{b}, $x->{w});
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
