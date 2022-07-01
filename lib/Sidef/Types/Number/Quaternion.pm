package Sidef::Types::Number::Quaternion {

    # Reference:
    #   https://en.wikipedia.org/wiki/Quaternion

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
        my (undef, $a, $b, $c, $d) = @_;

        # Handle evaluation of polynomials
        if (ref($_[0]) eq __PACKAGE__) {
            return $_[0]->eval($a);
        }

        $a //= Sidef::Types::Number::Number::ZERO;
        $b //= Sidef::Types::Number::Number::ZERO;
        $c //= Sidef::Types::Number::Number::ZERO;
        $d //= Sidef::Types::Number::Number::ZERO;

        $a = Sidef::Types::Number::Number->new($a) if !UNIVERSAL::isa($a, 'Sidef::Types::Number::Number');
        $b = Sidef::Types::Number::Number->new($b) if !UNIVERSAL::isa($b, 'Sidef::Types::Number::Number');
        $c = Sidef::Types::Number::Number->new($c) if !UNIVERSAL::isa($c, 'Sidef::Types::Number::Number');
        $d = Sidef::Types::Number::Number->new($d) if !UNIVERSAL::isa($d, 'Sidef::Types::Number::Number');

        bless {a => $a, b => $b, c => $c, d => $d};
    }

    *call = \&new;

    sub eval {
        my ($x, $v) = @_;
        __PACKAGE__->new($x->{a}->eval($v), $x->{b}->eval($v), $x->{c}->eval($v), $x->{d}->eval($v),);
    }

    sub a {
        $_[0]->{a};
    }

    *re   = \&a;
    *real = \&a;

    sub b {
        $_[0]->{b};
    }

    sub c {
        $_[0]->{c};
    }

    sub d {
        $_[0]->{d};
    }

    sub reals {
        ($_[0]->{a}, $_[0]->{b}, $_[0]->{c}, $_[0]->{d});
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
        'Quaternion(' . join(', ', $x->{a}->dump, $x->{b}->dump, $x->{c}->dump, $x->{d}->dump) . ')';
    }

    sub to_s {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    sub dump {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    sub to_gauss {
        my ($x) = @_;
#<<<
        Sidef::Types::Number::Gauss->new(
            Sidef::Types::Number::Gauss->new($x->{a}, $x->{b}),
            Sidef::Types::Number::Gauss->new($x->{c}, $x->{d}),
        );
#>>>
    }

    sub stringify {
        my ($x) = @_;
        $x->to_gauss->stringify;
    }

    sub to_n {
        my ($x) = @_;
        $x->to_gauss->to_n;
    }

    *to_c = \&to_n;

    sub norm {
        my ($x) = @_;
        $x->{a}->sqr->add($x->{b}->sqr)->add($x->{c}->sqr)->add($x->{d}->sqr);
    }

    sub abs {
        my ($x) = @_;
        $x->norm->sqrt;
    }

    sub sgn {
        my ($x) = @_;
        $x->div($x->abs);
    }

    sub neg {
        my ($x) = @_;
#<<<
        __PACKAGE__->new(
            $x->{a}->neg,
            $x->{b}->neg,
            $x->{c}->neg,
            $x->{d}->neg,
        );
#>>>
    }

    sub conj {
        my ($x) = @_;
#<<<
        __PACKAGE__->new(
            $x->{a},
            $x->{b}->neg,
            $x->{c}->neg,
            $x->{d}->neg,
        );
#>>>
    }

    sub sqr {
        my ($x) = @_;
        $x->mul($x);
    }

    sub add {
        my ($x, $y) = @_;

#<<<
        if (ref($y) eq __PACKAGE__) {
            return __PACKAGE__->new(
                $x->{a}->add($y->{a}),
                $x->{b}->add($y->{b}),
                $x->{c}->add($y->{c}),
                $x->{d}->add($y->{d}),
            );
        }
#>>>

        __PACKAGE__->new($x->{a}->add($y), $x->{b}, $x->{c}, $x->{d});
    }

    sub sub {
        my ($x, $y) = @_;

#<<<
        if (ref($y) eq __PACKAGE__) {
            return __PACKAGE__->new(
                $x->{a}->sub($y->{a}),
                $x->{b}->sub($y->{b}),
                $x->{c}->sub($y->{c}),
                $x->{d}->sub($y->{d}),
            );
        }
#>>>

        __PACKAGE__->new($x->{a}->sub($y), $x->{b}, $x->{c}, $x->{d});
    }

    sub mul {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            return __PACKAGE__->new(

                # Quaternion(a,b,c,d) * Quaternion(a',b',c',d') = Quaternion(
                #   a*a' - b*b' - c*c' - d*d',
                #   a*b' + b*a' + c*d' - d*c',
                #   a*c' - b*d' + c*a' + d*b',
                #   a*d' + b*c' - c*b' + d*a',
                #)

                $x->{a}->mul($y->{a})->sub($x->{b}->mul($y->{b}))->sub($x->{c}->mul($y->{c}))->sub($x->{d}->mul($y->{d})),
                $x->{a}->mul($y->{b})->add($x->{b}->mul($y->{a}))->add($x->{c}->mul($y->{d}))->sub($x->{d}->mul($y->{c})),
                $x->{a}->mul($y->{c})->sub($x->{b}->mul($y->{d}))->add($x->{c}->mul($y->{a}))->add($x->{d}->mul($y->{b})),
                $x->{a}->mul($y->{d})->add($x->{b}->mul($y->{c}))->sub($x->{c}->mul($y->{b}))->add($x->{d}->mul($y->{a})),
                                   );
        }

#<<<
        __PACKAGE__->new(
            $x->{a}->mul($y),
            $x->{b}->mul($y),
            $x->{c}->mul($y),
            $x->{d}->mul($y),
        );
#>>>
    }

    sub div {
        my ($x, $y) = @_;
        $x->mul($y->inv);
    }

    sub float {
        my ($x) = @_;
#<<<
        __PACKAGE__->new(
            $x->{a}->float,
            $x->{b}->float,
            $x->{c}->float,
            $x->{d}->float,
        );
#>>>
    }

    sub floor {
        my ($x) = @_;
#<<<
        __PACKAGE__->new(
            $x->{a}->floor,
            $x->{b}->floor,
            $x->{c}->floor,
            $x->{d}->floor,
        );
#>>>
    }

    sub ceil {
        my ($x) = @_;
#<<<
        __PACKAGE__->new(
            $x->{a}->ceil,
            $x->{b}->ceil,
            $x->{c}->ceil,
            $x->{d}->ceil,
        );
#>>>
    }

    sub round {
        my ($x, $r) = @_;
#<<<
        __PACKAGE__->new(
            $x->{a}->round($r),
            $x->{b}->round($r),
            $x->{c}->round($r),
            $x->{d}->round($r),
        );
#>>>
    }

    sub mod {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return __PACKAGE__->new($x->{a}->mod($y), $x->{b}->mod($y), $x->{c}->mod($y), $x->{d}->mod($y));
        }

        # mod(a, b) = a - b * floor(a/b)
        $x->sub($y->mul($x->div($y)->floor));
    }

    sub inv {
        my ($x) = @_;
        $x->conj->mul($x->{a}->sqr->add($x->{b}->sqr)->add($x->{c}->sqr)->add($x->{d}->sqr)->inv);
    }

    sub invmod {
        my ($x, $m) = @_;
        $x = $x->mod($m);
        $x->conj->mul($x->{a}->sqr->add($x->{b}->sqr)->add($x->{c}->sqr)->add($x->{d}->sqr)->invmod($m))->mod($m);
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
        __PACKAGE__->new($x->{a}->inc, $x->{b}, $x->{c}, $x->{d});
    }

    sub dec {
        my ($x) = @_;
        __PACKAGE__->new($x->{a}->dec, $x->{b}, $x->{c}, $x->{d});
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
            $x = $x->mul($x);
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
            $x = $x->mul($x)->mod($m);
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
            $cmp = $x->{c}->cmp($y->{c}) // return undef;
            $cmp && return $cmp;
            return $x->{d}->cmp($y->{d});
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
            $bool = $x->{c}->eq($y->{c}) // return undef;
            $bool || return $bool;
            return $x->{d}->eq($y->{d});
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
            $bool = $x->{c}->ne($y->{c});
            $bool && return $bool;
            return ($x->{d}->ne($y->{d}));
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

#<<<
                if (ref($y) eq __PACKAGE__) {
                    return __PACKAGE__->new(
                        $x->{a}->$method($y->{a}),
                        $x->{b}->$method($y->{b}),
                        $x->{c}->$method($y->{c}),
                        $x->{d}->$method($y->{d}),
                    );
                }
#>>>

                return __PACKAGE__->new($x->{a}->$method($y), $x->{b}, $x->{c}, $x->{d});
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
