package Sidef::Types::Number::Mod {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Number::Number
    );

    use overload
      q{bool} => sub { (@_) = ($_[0]); goto &__boolify__ },
      q{0+}   => sub { (@_) = ($_[0]); goto &__numify__ },
      q{""}   => sub { (@_) = ($_[0]); goto &__stringify__ },
      q{${}}  => sub { $_[0]{n} };

    sub new {
        my (undef, $n, $m) = @_;

        # Handle evaluation of polynomials
        if (ref($_[0]) eq __PACKAGE__) {
            return $_[0]->eval($n);
        }

        #$n = Sidef::Types::Number::Number->new($n) if !UNIVERSAL::isa($n, 'Sidef::Types::Number::Number');
        #$m = Sidef::Types::Number::Number->new($m) if !UNIVERSAL::isa($m, 'Sidef::Types::Number::Number');

        if (ref($n) eq __PACKAGE__) {
            $n = $n->real->mod($m);
        }

        $n = $n->mod($m);

        if (ref($n) eq __PACKAGE__) {
            return $n;
        }

        bless {n => $n, m => $m};
    }

    *call = \&new;

    sub to_n {
        $_[0]->{n};
    }

    *lift = \&to_n;

    sub eval {
        my ($x, $v) = @_;
        $x->{n}->eval($v)->mod($x->{m});
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

    sub is_neg {
        $_[0]->{n}->is_neg;
    }

    sub is_pos {
        $_[0]->{n}->is_pos;
    }

    sub is_nan {
        $_[0]->{n}->is_nan;
    }

    sub is_inf {
        $_[0]->{n}->is_inf;
    }

    sub is_ninf {
        $_[0]->{n}->is_ninf;
    }

    sub is_real {
        $_[0]->{n}->is_real;
    }

    sub real {
        $_[0]->{n}->is_zero ? $_[0]->{m} : $_[0]->{n};
    }

    *re = \&real;

    sub norm {
        $_[0]->real->norm;
    }

    sub modulus {
        $_[0]->{m};
    }

    sub __boolify__ {
        $_[0]->{n};
    }

    sub __numify__ {
        $_[0]->{n};
    }

    sub __stringify__ {
        my ($x) = @_;
        "Mod($x->{n}, $x->{m})";
    }

    sub to_s {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    *dump = \&to_s;

    sub div {
        my ($x, $y) = @_;

        if (ref($y) ne __PACKAGE__) {
            $y = __PACKAGE__->new($y, $x->{m});
        }

        __PACKAGE__->new($x->{n}->mul($y->{n}->invmod($x->{m})), $x->{m});
    }

    sub neg {
        my ($x) = @_;
        __PACKAGE__->new($x->{n}->neg, $x->{m});
    }

    sub inv {
        my ($x) = @_;
        __PACKAGE__->new($x->{n}->invmod($x->{m}), $x->{m});
    }

    sub inc {
        my ($x) = @_;
        $x->add(Sidef::Types::Number::Number::ONE);
    }

    sub dec {
        my ($x) = @_;
        $x->sub(Sidef::Types::Number::Number::ONE);
    }

    sub chinese {
        my (@values) = @_;

#<<<
        my $crt = __PACKAGE__->new(
            Sidef::Types::Number::Number::ZERO,
            Sidef::Types::Number::Number::ONE
        );
#>>>

        foreach my $mod (@values) {

            ref($mod) eq __PACKAGE__ or next;

#<<<
            $crt = __PACKAGE__->new(
                Sidef::Math::Math->chinese(
                    [$crt->{n}, $crt->{m}],
                    [$mod->{n}, $mod->{m}]
                ),
                Sidef::Types::Number::Number::lcm($crt->{m}, $mod->{m})
            );
#>>>
        }

        $crt;
    }

    sub sqrt {
        my ($x) = @_;
        __PACKAGE__->new($x->{n}->sqrtmod($x->{m}), $x->{m});
    }

    sub znorder {
        my ($x) = @_;
        $x->{n}->znorder($x->{m});
    }

    sub pow {
        my ($x, $y) = @_;
        __PACKAGE__->new($x->{n}->powmod($y, $x->{m}), $x->{m});
    }

    sub factorial {
        my ($x) = @_;
        __PACKAGE__->new($x->{n}->factorialmod($x->{m}), $x->{m});
    }

    sub lucas {
        my ($x) = @_;
        __PACKAGE__->new($x->{n}->lucasmod($x->{m}), $x->{m});
    }

    sub lucasu {
        my ($x, $P, $Q) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::lucasUmod($P, $Q, $x->{n}, $x->{m}), $x->{m});
    }

    *lucasU = \&lucasu;
    *LucasU = \&lucasu;

    sub lucasv {
        my ($x, $P, $Q) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::lucasVmod($P, $Q, $x->{n}, $x->{m}), $x->{m});
    }

    *lucasV = \&lucasv;
    *LucasV = \&lucasv;

    sub fibonacci {
        my ($x) = @_;
        __PACKAGE__->new($x->{n}->fibmod($x->{m}), $x->{m});
    }

    *fib = \&fibonacci;

    sub chebyshevu {
        my ($x, $n) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::chebyshevUmod($n, $x->{n}, $x->{m}), $x->{m});
    }

    *ChebyshevU = \&chebyshevu;
    *chebyshevU = \&chebyshevu;

    sub chebyshevt {
        my ($x, $n) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::chebyshevTmod($n, $x->{n}, $x->{m}), $x->{m});
    }

    *chebyshevT = \&chebyshevt;
    *ChebyshevT = \&chebyshevt;

    sub cyclotomic {
        my ($x, $n) = @_;
        __PACKAGE__->new(Sidef::Types::Number::Number::cyclotomicmod($n, $x->{n}, $x->{m}), $x->{m});
    }

    sub shift_left {    # x * 2^n
        my ($x, $n) = @_;
        $x->mul(Sidef::Types::Number::Number::TWO->powmod($n, $x->{m}));
    }

    *lsft = \&shift_left;

    sub shift_right {    # x / 2^n
        my ($x, $n) = @_;
        $x->div(Sidef::Types::Number::Number::TWO->powmod($n, $x->{m}));
    }

    *rsft = \&shift_right;

    {
        no strict 'refs';

        foreach my $method (qw(eq ne lt le gt ge cmp)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;

                if (ref($y) ne __PACKAGE__) {
                    $y = __PACKAGE__->new($y, $x->{m});
                }

                $x->{n}->$method($y->{n});
            };
        }

        foreach my $method (qw(mul add sub xor or and)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;

                if (ref($y) ne __PACKAGE__) {
                    $y = __PACKAGE__->new($y, $x->{m});
                }

                __PACKAGE__->new($x->{n}->$method($y->{n}), $x->{m});
            };
        }

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
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
    }
}

1
