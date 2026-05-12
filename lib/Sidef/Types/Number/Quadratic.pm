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

    sub with_value {
        my ($self, $value_1, $value_2) = @_;
        __PACKAGE__->new($value_1, $value_2, $self->{w});
    }

    sub eval {
        my ($x, $v) = @_;
        __PACKAGE__->new($x->{a}->eval($v), $x->{b}->eval($v), $x->{w}->eval($v));
    }

    sub lift {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->lift, $x->{b}->lift, $x->{w}->lift);
    }

    # Accessors
    sub a { $_[0]->{a} }
    *re   = \&a;
    *real = \&a;

    sub b { $_[0]->{b} }
    *im   = \&b;
    *imag = \&b;

    sub w { $_[0]->{w} }
    *order = \&w;

    sub reals {
        ($_[0]->{a}, $_[0]->{b});
    }

    sub parts {
        Sidef::Types::Array::Array->new($_[0]->{a}, $_[0]->{b}, $_[0]->{w});
    }

    # Boolean context
    sub __boolify__ {
        $_[0]->{a};
    }

    sub __numify__ {
        $_[0]->{a};
    }

    # Stringification
    sub __stringify__ {
        my ($x) = @_;
        'Quadratic(' . join(', ', $x->{a}->dump, $x->{b}->dump, $x->{w}->dump) . ')';
    }

    sub stringify {
        my ($x) = @_;

        my $a_str = $x->{a}->stringify;
        my $b_str = $x->{b}->stringify;
        my $w_str = $x->{w}->stringify;

        # If b is zero, just return a
        if ($x->{b}->is_zero) {
            return $a_str;
        }

        my $sign      = $x->{b}->is_neg ? ' - ' : ' + ';
        my $b_abs_str = $x->{b}->abs->stringify;

        Sidef::Types::String::String->new($a_str . $sign . $b_abs_str . '*sqrt(' . $w_str . ')');
    }

    *pretty = \&stringify;

    sub to_s {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    *dump = \&to_s;

    # Conversion to numeric/complex
    sub to_n {
        my ($x) = @_;
        my $r = $x->{a}->add($x->{b}->mul($x->{w}->sqrt));

        if (ref($r) ne 'Sidef::Types::Number::Number') {
            return $r->to_n;
        }

        return $r;
    }

    *to_c = \&to_n;

    # Conversion to QuadraticElement (t^2 = w, so p=w, q=0)
    sub to_quadratic_element {
        my ($x) = @_;
        require Sidef::Types::Number::QuadraticElement;
        Sidef::Types::Number::QuadraticElement->new($x->{a}, $x->{b}, $x->{w}, Sidef::Types::Number::Number::ZERO);
    }

    # Basic properties
    sub abs {
        my ($x) = @_;
        $x->norm->sqrt;
    }

    sub norm {
        my ($x) = @_;
        $x->{a}->sqr->sub($x->{b}->sqr->mul($x->{w}));
    }

    sub trace {
        my ($x) = @_;
        $x->{a}->mul(Sidef::Types::Number::Number::TWO);
    }

    sub sgn {
        my ($x) = @_;
        my $abs = $x->abs;
        $abs->is_zero && return undef;    # zero has no sign
        $x->div($abs);
    }

    # Arithmetic operations

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

        if (ref($y) eq __PACKAGE__ and $x->{w}->eq($y->{w})) {
            return __PACKAGE__->new($x->{a}->add($y->{a}), $x->{b}->add($y->{b}), $x->{w});
        }
        __PACKAGE__->new($x->{a}->add($y), $x->{b}, $x->{w});
    }

    sub sub {
        my ($x, $y) = @_;
        if (ref($y) eq __PACKAGE__ and $x->{w}->eq($y->{w})) {
            return __PACKAGE__->new($x->{a}->sub($y->{a}), $x->{b}->sub($y->{b}), $x->{w});
        }
        __PACKAGE__->new($x->{a}->sub($y), $x->{b}, $x->{w});
    }

    sub mul {
        my ($x, $y) = @_;

        # (x + y√d) (z + w√d) = (xz + ywd) + (xw + yz)√d

        if (ref($y) eq __PACKAGE__ and $x->{w}->eq($y->{w})) {
            return __PACKAGE__->new($x->{a}->mul($y->{a})->add($x->{b}->mul($y->{b})->mul($x->{w})), $x->{a}->mul($y->{b})->add($x->{b}->mul($y->{a})),
                                    $x->{w});
        }
        __PACKAGE__->new($x->{a}->mul($y), $x->{b}->mul($y), $x->{w});
    }

    sub div {
        my ($x, $y) = @_;
        if (ref($y) eq __PACKAGE__) {
            my $norm = $y->norm;
            my $num  = $x->mul($y->conj);
            return __PACKAGE__->new($num->{a}->div($norm), $num->{b}->div($norm), $x->{w});
        }
        __PACKAGE__->new($x->{a}->div($y), $x->{b}->div($y), $x->{w});
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

    # Euclidean division with rounding to nearest (gives better behaviour for Euclidean algorithm)
    sub divmod {
        my ($self, $other) = @_;
        my $q = $self->mul($other->inv)->round;
        my $r = $self->sub($q->mul($other));
        return ($q, $r);
    }

    sub idiv {
        my ($self, $other) = @_;
        my ($q, undef) = $self->divmod($other);
        return $q;
    }

    sub mod {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return __PACKAGE__->new($x->{a}->mod($y), $x->{b}->mod($y), $x->{w});
        }

        # Euclidean remainder
        my (undef, $r) = $x->divmod($y);
        return $r;
    }

    # Multiplicative inverse
    sub inv {
        my ($x) = @_;

        # 1/(a + b*sqrt(w)) = (a - b*sqrt(w)) / (a^2 - b^2*w)
        #                   = a/(a^2 - b^2*w) - b/(a^2 - b^2*w) * sqrt(w)

        my $norm = $x->norm;
        __PACKAGE__->new($x->{a}->div($norm), $x->{b}->div($norm)->neg, $x->{w});
    }

    sub invmod {
        my ($x, $m) = @_;
        $x = $x->mod($m);
        my $t = $x->norm->invmod($m);
        __PACKAGE__->new($x->{a}->mul($t)->mod($m), $x->{b}->mul($t)->neg->mod($m), $x->{w});
    }

    # Predicates

    sub is_zero {
        my ($x) = @_;
        $x->{a}->is_zero && $x->{b}->is_zero;
    }

    sub is_one {
        my ($x) = @_;
        $x->{a}->is_one && $x->{b}->is_zero;
    }

    sub is_mone {
        my ($x) = @_;
        $x->{a}->is_mone && $x->{b}->is_zero;
    }

    sub is_int {
        $_[0]->{b}->is_zero;
    }

    sub is_unit {
        my ($x) = @_;
        $x->norm->abs->is_one;
    }

    sub is_associate {
        my ($x, $y) = @_;
        return $x->is_zero ? $y->is_zero : !$y->is_zero && $x->mul($y->inv)->is_unit;
    }

    sub is_coprime {
        my ($n, $k) = @_;
        $n->norm->gcd($k->norm)->is_one;
    }

    sub is_prime {
        my ($x) = @_;
        $x->norm->abs->is_prime;
    }

    # Increment / decrement

    sub inc {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->inc, $x->{b}, $x->{w});
    }

    sub dec {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->dec, $x->{b}, $x->{w});
    }

    # Exponentiation

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
            $c = $c->mul($x)->mod($m) if $bit;
            $x = $x->sqr->mod($m);
        }

        if ($negative_power) {
            $c = $c->invmod($m);
        }

        return $c;
    }

    # GCD / LCM (Euclidean algorithm)

    sub gcd {
        my ($self, $other) = @_;
        my $u = $self;
        my $v = $other;
        while (!$v->is_zero) {
            my (undef, $r) = $u->divmod($v);
            $u = $v;
            $v = $r;
        }
        return $u;
    }

    sub lcm {
        my ($self, $other) = @_;
        if ($self->is_zero || $other->is_zero) {
            return __PACKAGE__->new(Sidef::Types::Number::Number::ZERO, Sidef::Types::Number::Number::ZERO, $self->{w});
        }
        $self->mul($other)->div($self->gcd($other));
    }

    # Comparisons

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
            return $x->{w}->ne($y->{w});
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

    # Operator overloading
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
                if (ref($y) eq __PACKAGE__ and $x->{w}->eq($y->{w})) {
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

1;
