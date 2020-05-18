package Sidef::Types::Number::Mod {

    use utf8;
    use 5.016;

    use parent qw(Sidef::Object::Object);

    use overload
      q{bool} => sub { (@_) = ($_[0]); goto &__boolify__ },
      q{0+}   => sub { (@_) = ($_[0]); goto &__numify__ },
      q{""}   => sub { (@_) = ($_[0]); goto &__stringify__ };

    sub new {
        my (undef, $n, $m) = @_;

        $n = Sidef::Types::Number::Number->new($n) if ref($n) ne 'Sidef::Types::Number::Number';
        $m = Sidef::Types::Number::Number->new($m) if ref($m) ne 'Sidef::Types::Number::Number';

        $n = $n->mod($m);

        bless {n => $n, m => $m};
    }

    *call = \&new;

    sub to_n {
        $_[0]->{n};
    }

    *lift = \&to_n;

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
        __PACKAGE__->new($x->{n}->mul($y->to_n->invmod($x->{m})), $x->{m});
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

        my $lcm = Sidef::Types::Number::Number::ONE;
        my $crt = __PACKAGE__->new(Sidef::Types::Number::Number::ZERO, Sidef::Types::Number::Number::ONE);

        foreach my $mod (@values) {

            ref($mod) eq __PACKAGE__ or next;

            $crt = __PACKAGE__->new(Sidef::Math::Math->chinese([$crt->{n}, $crt->{m}], [$mod->{n}, $mod->{m}]),
                                    Sidef::Types::Number::Number::lcm($crt->{m}, $mod->{m}));
        }

        $crt;
    }

    sub sqrt {
        my ($x) = @_;
        __PACKAGE__->new($x->{n}->sqrtmod($x->{m}), $x->{m});
    }

    sub pow {
        my ($x, $y) = @_;
        __PACKAGE__->new($x->{n}->powmod($y->to_n, $x->{m}), $x->{m});
    }

    {
        no strict 'refs';

        foreach my $method (qw(eq ne lt le gt ge cmp)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;
                $x->{n}->$method($y->to_n->mod($x->{m}));
            };
        }

        foreach my $method (qw(mul add sub xor or and)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;
                __PACKAGE__->new($x->{n}->$method($y->to_n->mod($x->{m})), $x->{m});
            };
        }

        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}   = \&div;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '%'}   = \&mod;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
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
