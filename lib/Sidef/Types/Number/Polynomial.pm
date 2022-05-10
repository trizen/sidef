package Sidef::Types::Number::Polynomial {

    # References:
    #   https://en.wikipedia.org/wiki/Polynomial
    #   https://metacpan.org/pod/Math::Polynomial
    #   https://metacpan.org/pod/Math::Polynomial::Cyclotomic

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Number::Number
    );

    use overload
      q{bool} => sub { (@_) = ($_[0]); goto &__boolify__ },
      q{""}   => sub { (@_) = ($_[0]); goto &__stringify__ },
      q{${}}  => \&to_n,
      q{0+}   => \&to_n;

    sub new {
        my (undef, @args) = @_;

        if (scalar(@args) == 1) {
            my $value = $args[0];

            if (ref($_[0]) eq __PACKAGE__) {
                return $_[0]->eval($value);
            }

            if (UNIVERSAL::isa($value, 'Sidef::Types::Array::Array')) {
                my $end = $#{$value};
                return __PACKAGE__->new(map { ($end - $_) => $value->[$_] } 0 .. $end);
            }

            if (UNIVERSAL::isa($value, 'Sidef::Types::Number::Number')) {    # monomial
                return __PACKAGE__->new($value => Sidef::Types::Number::Number::ONE);
            }

            return __PACKAGE__->new(0 => $value);
        }

        my %poly;

        while (@args) {
            my ($key, $value) = splice(@args, 0, 2);

            $key //= 0;
            $value // next;
            $value = Sidef::Types::Number::Number->new($value) if !UNIVERSAL::isa($value, 'Sidef::Types::Number::Number');

            unless ($value->is_zero) {
                $poly{"$key"} = $value;
            }
        }

        bless \%poly;
    }

    *call = \&new;

    sub to_poly {
        $_[0];
    }

    sub to_n {
        my ($x) = @_;
        my $d = scalar keys(%$x);

        return Sidef::Types::Number::Number::ZERO if ($d == 0);

        if ($d == 1 and exists $x->{0}) {
            return $x->{0}->to_n;
        }

        return Sidef::Types::Number::Number::nan();
    }

    sub real {
        my ($x) = @_;

        if (exists $x->{0}) {
            return $x->{0};
        }

        return Sidef::Types::Number::Number::ZERO;
    }

    *re = \&real;

    sub is_real {
        my ($x) = @_;
        my $d = scalar keys(%$x);

        ($d == 0 or ($d == 1 and exists($x->{0}) and $x->{0}->is_real))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_nan {
        my ($x) = @_;
        foreach my $key (keys %$x) {
            if ($x->{$key}->is_nan) {
                return Sidef::Types::Bool::Bool::TRUE;
            }
        }
        Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_inf {
        my ($x) = @_;
        foreach my $key (keys %$x) {
            if ($x->{$key}->is_inf) {
                return Sidef::Types::Bool::Bool::TRUE;
            }
        }
        Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_ninf {
        my ($x) = @_;
        foreach my $key (keys %$x) {
            if ($x->{$key}->is_ninf) {
                return Sidef::Types::Bool::Bool::TRUE;
            }
        }
        Sidef::Types::Bool::Bool::FALSE;
    }

    sub norm {
        $_[0]->real->norm;
    }

    sub __dump__ {
        my ($x) = @_;
        'Polynomial(' . join(", ", map { join(' => ', $_, $x->{$_}->dump) } sort { $a <=> $b } CORE::keys %$x) . ')';
    }

    sub __boolify__ {
        my ($x) = @_;
        ($x->{0} // 0);
    }

    sub __stringify__ {
        my ($x) = @_;

        my $str  = '';
        my @keys = sort { $b <=> $a } CORE::keys %$x;

        foreach my $key (@keys) {

            $str .= ' + ';

            my $c_str = ${$x->{$key}->dump};

            if ($c_str =~ s/^-//) {
                $str =~ s/ \+ \z/ - /;
            }

            if ($c_str =~ /[+-]/ and $c_str !~ /^\w+\(.*\)\z/) {
                $c_str = "($c_str)";
            }

            $str .= $c_str if ($key == 0 or $c_str ne '1');

            if ($key != 0) {
                $str .= '*' if ($c_str ne '1');
                $str .= "x";
                $str .= "^$key" if ($key != 1);
            }
        }

        $str =~ s/^ \+ //;
        $str =~ s/ \+ \z//;
        $str =~ s/^ \- /-/;
        $str =~ s/^\((.*)\)\z/$1/;
        $str;
    }

    sub to_s {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    *stringify = \&to_s;

    sub dump {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__dump__);
    }

    sub degree {
        my ($x) = @_;
        my $degree = 0;
        foreach my $key (CORE::keys(%$x)) {
            if ($key > $degree) {
                if (!$x->{$key}->is_zero) {
                    $degree = $key;
                }
            }
        }
        Sidef::Types::Number::Number::_set_int($degree);
    }

    sub derivative {
        my ($x) = @_;
        __PACKAGE__->new(map { ($_ - 1, $x->{$_}->mul(Sidef::Types::Number::Number::_set_int($_))) } CORE::keys(%$x));
    }

    sub eval {
        my ($x, $value) = @_;
        CORE::keys(%$x) || return Sidef::Types::Number::Number::ZERO;
        Sidef::Types::Number::Number::sum(map { $value->pow(Sidef::Types::Number::Number::_set_int($_))->mul($x->{$_}) }
                                          CORE::keys %$x);
    }

    sub keys {
        my ($x) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::Number::Number::_set_int($_) } sort { $a <=> $b } CORE::keys(%$x));
    }

    *exponents = \&keys;

    sub coeff {
        my ($x, $key) = @_;
        $x->{$key} // Sidef::Types::Number::Number::ZERO;
    }

    sub coeffs {
        my ($x) = @_;
        Sidef::Types::Array::Array->new(
                               [map { Sidef::Types::Array::Array->new([Sidef::Types::Number::Number::_set_int($_), $x->{$_}]) }
                                sort { $a <=> $b } CORE::keys(%$x)
                               ]
        );
    }

    sub binomial {
        my ($n, $k) = @_;

        my $k_int = CORE::int($k);
        my @terms;

        foreach my $i (0 .. $k_int - 1) {
            push @terms, $n;
            $n = $n->dec;
        }

        @terms || return __PACKAGE__->new(0 => Sidef::Types::Number::Number::ONE);

        my $prod = Sidef::Types::Number::Number::_binsplit(\@terms, \&Sidef::Types::Number::Polynomial::mul);
        $prod->div($k->factorial);
    }

    sub neg {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->neg } CORE::keys %$x);
    }

    sub add {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            return
              __PACKAGE__->new((map { $_ => (exists($y->{$_}) ? $x->{$_}->add($y->{$_}) : $x->{$_}) } CORE::keys %$x),
                               (map { exists($x->{$_}) ? () : ($_ => $y->{$_}) } CORE::keys %$y));
        }

        if (not exists $x->{0}) {
            return __PACKAGE__->new(0 => $y, %$x);
        }

        __PACKAGE__->new(map { $_ => (($_ == 0) ? $x->{$_}->add($y) : $x->{$_}) } CORE::keys(%$x));
    }

    sub sub {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            return
              __PACKAGE__->new((map { $_ => (exists($y->{$_}) ? $x->{$_}->sub($y->{$_}) : $x->{$_}) } CORE::keys %$x),
                               (map { exists($x->{$_}) ? () : ($_ => $y->{$_}->neg) } CORE::keys %$y),);
        }

        if (not exists $x->{0}) {
            return __PACKAGE__->new(0 => $y->neg, %$x);
        }

        __PACKAGE__->new(map { $_ => (($_ == 0) ? $x->{$_}->sub($y) : $x->{$_}) } CORE::keys(%$x));
    }

    sub mul {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {

            my @keys_x = CORE::keys %$x;
            my @keys_y = CORE::keys %$y;

            my %poly;
            foreach my $key_x (@keys_x) {
                foreach my $key_y (@keys_y) {

                    my $coeff = $x->{$key_x}->mul($y->{$key_y});
                    my $key_z = $key_x + $key_y;

                    if (exists $poly{$key_z}) {
                        $poly{$key_z} = $poly{$key_z}->add($coeff);
                    }
                    else {
                        $poly{$key_z} = $coeff;
                    }
                }
            }

            return __PACKAGE__->new(%poly);
        }

        __PACKAGE__->new(map { $_ => $x->{$_}->mul($y) } CORE::keys %$x);
    }

    sub sqr {
        my ($x) = @_;
        $x->mul($x);
    }

    sub divmod {
        my ($x, $y) = @_;

        # TODO: optimize this method for better performance.

        my @keys_x = sort { $b <=> $a } CORE::keys %$x;
        my @keys_y = sort { $b <=> $a } CORE::keys %$y;

        @keys_x
          || return (__PACKAGE__->new(), __PACKAGE__->new());

        @keys_y
          || return (__PACKAGE__->new(0 => Sidef::Types::Number::Number::inf()), __PACKAGE__->new());

        my $key_y = shift @keys_y;
        my $yc    = $y->{$key_y};

        my $quot = __PACKAGE__->new();

        while (1) {
            my $key_x = $keys_x[0];
            my $xc    = $x->{$key_x};
            my $q     = $xc->div($yc);

            # When the result of division is NaN, the loop never stops
            if ($q->is_nan) {
                return (__PACKAGE__->new(0 => Sidef::Types::Number::Number::nan()), __PACKAGE__->new());
            }

            # Stop when the degree is < 0
            if ($key_x < $key_y) {
                last;
            }

            my $t = __PACKAGE__->new($key_x - $key_y, $q);

            $quot = $quot->add($t);
            $x    = $x->sub($t->mul($y));

            @keys_x = sort { $b <=> $a } CORE::keys %$x;
            (@keys_x and $keys_x[0] >= $key_y) or last;
        }

        return ($quot, $x);
    }

    sub idiv {
        my ($x, $y) = @_;

        if (ref($y) ne __PACKAGE__) {
            $y = __PACKAGE__->new(0 => $y);
        }

        my ($quot, $rem) = $x->divmod($y);
        return $quot;
    }

    # Probably not right?
    *idiv_ceil  = \&idiv;
    *idiv_trunc = \&idiv;
    *idiv_round = \&idiv;
    *idiv_floor = \&idiv;

    sub div {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {

            my ($quot, $rem) = $x->divmod($y);

            if ($rem->is_zero) {
                return $quot;
            }

            return Sidef::Types::Number::Fraction->new($quot->mul($y)->add($rem), $y);
        }

        if ($y->is_zero) {
            return __PACKAGE__->new(0 => Sidef::Types::Number::Number::inf());
        }

        __PACKAGE__->new(map { $_ => $x->{$_}->div($y) } CORE::keys %$x);
    }

    sub float {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->float } CORE::keys %$x);
    }

    sub floor {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->floor } CORE::keys %$x);
    }

    sub ceil {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->ceil } CORE::keys %$x);
    }

    sub round {
        my ($x, $r) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->round($r) } CORE::keys %$x);
    }

    sub mod {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {

            # mod(a, b) = a - b * floor(a/b)
            # return $x->sub($y->mul($x->div($y)->floor));

            my ($quot, $rem) = $x->divmod($y);
            return $rem;
        }

        __PACKAGE__->new(map { $_ => Sidef::Types::Number::Mod->new($x->{$_}, $y) } CORE::keys %$x);
    }

    sub inv {
        my ($x) = @_;
        Sidef::Types::Number::Fraction->new(Sidef::Types::Number::Number::ONE, $x);
    }

    sub invmod {
        my ($x, $m) = @_;
        $x->mod($m)->inv;
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

    sub inc {
        my ($x) = @_;
        __PACKAGE__->new(%$x, 0 => ($x->{0} // Sidef::Types::Number::Number::ZERO)->inc);
    }

    sub dec {
        my ($x) = @_;
        __PACKAGE__->new(%$x, 0 => ($x->{0} // Sidef::Types::Number::Number::ZERO)->dec);
    }

    sub pow {
        my ($x, $n) = @_;

        my $negative_power = 0;

        if ($n->is_neg) {
            $n              = $n->abs;
            $negative_power = 1;
        }

        my $c = __PACKAGE__->new(0 => Sidef::Types::Number::Number::ONE);

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

        my $c = __PACKAGE__->new(0 => Sidef::Types::Number::Number::ONE);

        foreach my $bit (reverse split(//, $n->as_bin)) {

            # c = (c*x)%m if bit
            # x = (x*x)%m

            $c = $c->mul($x)->mod($m) if $bit;
            $x = $x->mul($x)->mod($m);
        }

        if ($negative_power) {
            $c = $c->inv;
        }

        return $c;
    }

    sub cmp {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {

            my @keys_x = grep { !$x->{$_}->is_zero } sort { $a <=> $b } CORE::keys %$x;
            my @keys_y = grep { !$y->{$_}->is_zero } sort { $a <=> $b } CORE::keys %$y;

            scalar(@keys_x) == scalar(@keys_y)
              or return Sidef::Types::Number::Number::_set_int(scalar(@keys_x) <=> scalar(@keys_y));

            while (@keys_x and @keys_y) {

                my $key_x = pop(@keys_x);
                my $key_y = pop(@keys_y);

                if ($key_x eq $key_y) {
                    my $cmp = $x->{$key_x}->cmp($y->{$key_y});
                    $cmp && return $cmp;
                }
                elsif ($key_x > $key_y) {
                    return Sidef::Types::Number::Number::ONE;
                }
                elsif ($key_y > $key_x) {
                    return Sidef::Types::Number::Number::MONE;
                }
            }

            return Sidef::Types::Number::Number::ZERO;
        }

        exists($x->{0}) || return undef;

        foreach my $key (CORE::keys(%$x)) {
            ($key == 0 or $x->{$key}->is_zero)
              or return undef;
        }

        $x->{0}->cmp($y);
    }

    sub eq {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {

            foreach my $key (CORE::keys %$x) {
                if (exists $y->{$key}) {
                    $x->{$key}->eq($y->{$key})
                      or return Sidef::Types::Bool::Bool::FALSE;
                }
                else {
                    $x->{$key}->is_zero
                      or return Sidef::Types::Bool::Bool::FALSE;
                }
            }

            foreach my $key (CORE::keys %$y) {
                if (exists $x->{$key}) {
                    ## ok
                }
                else {
                    $y->{$key}->is_zero
                      or return Sidef::Types::Bool::Bool::FALSE;
                }
            }

            return Sidef::Types::Bool::Bool::TRUE;
        }

        if (!scalar(CORE::keys(%$x))) {
            return $y->is_zero;
        }

        (exists($x->{0}) and $x->{0}->eq($y))
          || return Sidef::Types::Bool::Bool::FALSE;

        foreach my $key (CORE::keys(%$x)) {
            ($key == 0 or $x->{$key}->is_zero)
              or return Sidef::Types::Bool::Bool::FALSE;
        }

        Sidef::Types::Bool::Bool::TRUE;
    }

    sub ne {
        my ($x, $y) = @_;
        $x->eq($y)->not;
    }

    {
        no strict 'refs';

        foreach my $method (qw(ge gt lt le)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($x, $y) = @_;
                ($x->cmp($y) // return undef)->$method(Sidef::Types::Number::Number::ZERO);
            };
        }

        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '//'}  = \&idiv;
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
