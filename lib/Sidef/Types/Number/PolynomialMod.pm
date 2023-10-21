package Sidef::Types::Number::PolynomialMod {

    # References:
    #   Lecture 14, Week 8 (2hrs) - Towards polynomial factorization
    #   https://youtube.com/watch?v=KNyHz0eoAMA
    #
    #   Lecture 15, Week 8, 1hr - Polynomial factorization
    #   https://youtube.com/watch?v=tMqKqsMb-Ro

    use utf8;
    use 5.016;

    require List::Util;

    use parent qw(
      Sidef::Types::Number::Polynomial
    );

    use overload
      q{bool} => sub { (@_) = ($_[0]); goto &__boolify__ },
      q{""}   => sub { (@_) = ($_[0]); goto &__stringify__ },
      q{%{}}  => \&to_poly,
      q{${}}  => \&Sidef::Types::Number::Polynomial::to_n,
      q{0+}   => \&Sidef::Types::Number::Polynomial::to_n;

    sub new {
        my (undef, @args) = @_;

        my $mod = pop @args;

        if (scalar(@args) == 0 and ref($_[0]) eq __PACKAGE__) {
            return $_[0]->eval($mod);
        }

        my $poly;
        if (scalar(@args) == 1 and ref($args[0]) eq 'Sidef::Types::Number::Polynomial') {
            $poly = $args[0];
        }
        else {
            $poly = __PACKAGE__->SUPER::new(@args);
        }

        $poly = $poly->mod($mod)->lift;
        bless [$poly, $mod];
    }

    *call = \&new;

    sub to_poly {
        $_[0][0];
    }

    *lift = \&to_poly;

    sub modulus {
        $_[0][1];
    }

    sub __dump__ {
        my ($x) = @_;
        my $str = join('', $x->[0]->dump);
        $str =~ s{^Polynomial}{PolynomialMod};
        $str =~ s{\)\z}{, $x->[1])};
        return $str;
    }

    sub __boolify__ {
        my ($x) = @_;
        ($x->{0} // 0);
    }

    sub __stringify__ {
        my ($x, $method) = @_;
        $method //= 'to_s';
        $x->[0]->SUPER::__stringify__($method);
    }

    sub to_s {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__);
    }

    *stringify = \&to_s;

    sub pretty {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__stringify__('pretty'));
    }

    sub dump {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__dump__);
    }

    sub derivative {
        my ($x) = @_;
        my $m = $x->[1];
        $x = $x->[0];
        __PACKAGE__->new((map { (Math::Prime::Util::GMP::subint($_, 1), $x->{$_}->mulmod(Sidef::Types::Number::Number::_set_int($_), $m)) } CORE::keys(%$x)),
                         $m);
    }

    sub eval {
        my ($x, $value) = @_;

        my $m = $x->[1];
        $x = $x->[0];

        CORE::keys(%$x) || return Sidef::Types::Number::Number::ZERO;

        $value = $value->mod($m);
        Sidef::Types::Number::Number::sum(map { $value->powmod(Sidef::Types::Number::Number::_set_int($_), $m)->mulmod($x->{$_}->eval($value), $m) }
                                          CORE::keys(%$x))->mod($m);
    }

    sub binomial {
        my ($n, $k) = @_;

        my $k_int = CORE::int($k);
        my @terms;

        foreach my $i (0 .. $k_int - 1) {
            push @terms, $n;
            $n = $n->dec;
        }

        @terms || return __PACKAGE__->new((0 => Sidef::Types::Number::Number::ONE), $n->[1]);

        my $prod = Sidef::Types::Number::Number::_binsplit(\@terms, \&Sidef::Types::Number::PolynomialMod::mul);
        $prod->div($k->factorial);
    }

    sub chinese {
        my (@polynomials) = @_;

        my @moduli = map { $_->modulus } @polynomials;
        my $m      = Sidef::Types::Number::Number::lcm(@moduli);
        my $c      = __PACKAGE__->new($m);

        foreach my $i (0 .. $#polynomials) {
            my $poly = $polynomials[$i];
            my $n    = $moduli[$i];
            my $t    = $m->idiv($n);
            my $u    = $t->mul($t->invmod($n));
            $c = $c->add(__PACKAGE__->new($poly->lift, $m)->mul($u));
        }

        return $c;
    }

    sub add {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__ and $x->[1]->eq($y->[1])) {
            my $m = $x->[1];
            $x = $x->[0];
            $y = $y->[0];
            return
              __PACKAGE__->new(
                               (
                                (map { $_ => (exists($y->{$_}) ? $x->{$_}->addmod($y->{$_}, $m) : $x->{$_}) } CORE::keys %$x),
                                (map { exists($x->{$_}) ? () : ($_ => $y->{$_}) } CORE::keys(%$y))
                               ),
                               $m
                              );
        }

        my $m = $x->[1];
        $x = $x->[0];

        if (not exists $x->{0}) {
            return __PACKAGE__->new(0 => $y, %$x, $m);
        }

        $y = $y->mod($m);

        __PACKAGE__->new((map { $_ => (($_ eq '0') ? $x->{$_}->addmod($y, $m) : $x->{$_}) } CORE::keys(%$x)), $m);
    }

    sub sub {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__ and $x->[1]->eq($y->[1])) {
            my $m = $x->[1];
            $x = $x->[0];
            $y = $y->[0];
            return
              __PACKAGE__->new(
                               (
                                (map { $_ => (exists($y->{$_}) ? $x->{$_}->submod($y->{$_}, $m) : $x->{$_}) } CORE::keys %$x),
                                (map { exists($x->{$_}) ? () : ($_ => $y->{$_}->neg) } CORE::keys(%$y))
                               ),
                               $m
                              );
        }

        my $m = $x->[1];
        $x = $x->[0];

        if (not exists $x->{0}) {
            return __PACKAGE__->new(0 => $y->neg, %$x, $m);
        }

        $y = $y->mod($m);

        __PACKAGE__->new((map { $_ => (($_ eq '0') ? $x->{$_}->submod($y, $m) : $x->{$_}) } CORE::keys(%$x)), $m);
    }

    sub mul {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__ and $x->[1]->eq($y->[1])) {

            my $m = $x->[1];

            $x = $x->[0];
            $y = $y->[0];

            my @keys_x = CORE::keys %$x;
            my @keys_y = CORE::keys %$y;

            my %poly;
            foreach my $key_x (@keys_x) {
                foreach my $key_y (@keys_y) {

                    my $coeff = $x->{$key_x}->mulmod($y->{$key_y}, $m);
                    my $key_z = Math::Prime::Util::GMP::addint($key_x, $key_y);

                    if (exists $poly{$key_z}) {
                        $poly{$key_z} = $poly{$key_z}->addmod($coeff, $m);
                    }
                    else {
                        $poly{$key_z} = $coeff;
                    }
                }
            }

            return __PACKAGE__->new(%poly, $m);
        }

        $y = $y->mod($x->[1]);

        __PACKAGE__->new((map { $_ => $x->[0]{$_}->mulmod($y, $x->[1]) } CORE::keys(%{$x->[0]})), $x->[1]);
    }

    sub sqr {
        my ($x) = @_;
        $x->mul($x);
    }

    sub divmod {
        my ($x, $y) = @_;

        # Reference:
        #   https://en.wikipedia.org/wiki/Polynomial_greatest_common_divisor#Euclidean_division

        if ($x->[1]->ne($y->[1])) {
            return (__PACKAGE__->new(Sidef::Types::Number::Number::nan(), Sidef::Types::Number::Number::nan()),
                    __PACKAGE__->new(Sidef::Types::Number::Number::nan()));
        }

        my $m = $x->[1];

        my $x_mod = $x;
        my $y_mod = $y;

        $x = $x->[0];
        $y = $y->[0];

        my $deg_r = List::Util::max(CORE::keys(%$x));    # deg(x)
        $deg_r // return (__PACKAGE__->new($m), __PACKAGE__->new($m));

        if ($deg_r > ~0) {
            $deg_r = Math::GMPz::Rmpz_init_set_str("$deg_r", 10);
        }

        my $deg_y = List::Util::max(CORE::keys(%$y));    # deg(y)
        $deg_y // return (__PACKAGE__->new(0 => Sidef::Types::Number::Number::inf(), $m), __PACKAGE__->new($m));

        if ($deg_y > ~0) {
            $deg_y = Math::GMPz::Rmpz_init_set_str("$deg_y", 10);
        }

        my $q = __PACKAGE__->new($m);
        my $r = $x_mod;
        my $c = $y->{$deg_y};                            # lc(y)

        while ($deg_r >= $deg_y) {

            my $lc = $r->[0]{$deg_r};                    # lc(r)
            my $t  = $lc->divmod($c, $m);                # lc(r)/c

            # When the result of division is NaN, the loop never stops
            if ($t->is_nan) {
                return (__PACKAGE__->new(Sidef::Types::Number::Number::nan(), Sidef::Types::Number::Number::nan()), __PACKAGE__->new($m));
            }

            # s := lc(r)/c * x^(deg(r)−deg(y))
            my $s = __PACKAGE__->new(Math::Prime::Util::GMP::subint($deg_r, $deg_y) => $t, $m);
            $q = $q->add($s);
            $r = $r->sub($s->mul($y_mod));

            # Find deg(r) for the new r
            $deg_r = List::Util::max(CORE::keys(%{$r->[0]})) // last;

            if ($deg_r > ~0) {
                $deg_r = Math::GMPz::Rmpz_init_set_str("$deg_r", 10);
            }
        }

        return ($q, $r);
    }

    sub abs {
        my ($x) = @_;
        $x->mul($x->sgn);
    }

    sub lcm {
        my ($x, $y) = @_;
        $x->mul($y)->abs->div($x->gcd($y));
    }

    sub gcd {
        my ($x, $y) = @_;

        # Reference:
        #   https://en.wikipedia.org/wiki/Polynomial_greatest_common_divisor#Euclid's_algorithm

        my $r0 = $x;
        my $r1 = $y;

        until ($r1->is_zero) {
            my $r = $r0->mod($r1);
            ($r0, $r1) = ($r1, $r);
        }

        return $r0;
    }

    sub gcdext {
        my ($x, $y) = @_;

        # Reference:
        #   https://en.wikipedia.org/wiki/Polynomial_greatest_common_divisor#B%C3%A9zout's_identity_and_extended_GCD_algorithm

        if (ref($y) ne __PACKAGE__) {
            $y = __PACKAGE__->new(0 => $y, $x->[1]);
        }

        my $r0 = $x;
        my $r1 = $y;

        my $s0 = Sidef::Types::Number::Number::ONE;
        my $s1 = Sidef::Types::Number::Number::ZERO;
        my $t0 = Sidef::Types::Number::Number::ZERO;
        my $t1 = Sidef::Types::Number::Number::ONE;

        my $i = 1;
        until ($r1->is_zero) {
            my ($q) = $r0->divmod($r1);
            ($r0, $r1) = ($r1, $r0->sub($q->mul($r1)));
            ($s0, $s1) = ($s1, $s0->sub($q->mul($s1)));
            ($t0, $t1) = ($t1, $t0->sub($q->mul($t1)));
            ++$i;
        }

        my $g = $r0;
        my $u = $s0;
        my $v = $t0;

        my $a1 = $t1->mul(Sidef::Types::Number::Number::MONE->ipow(Sidef::Types::Number::Number::_set_int($i - 1)));
        my $b1 = $s1->mul(Sidef::Types::Number::Number::MONE->ipow(Sidef::Types::Number::Number::_set_int($i)));

        return ($g, $u, $v, $a1, $b1);
    }

    sub idiv {
        my ($x, $y) = @_;

        if (ref($y) ne __PACKAGE__) {
            $y = __PACKAGE__->new(0 => $y, $x->[1]);
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

        if (ref($y) eq __PACKAGE__ and $y->[1]->eq($x->[1])) {

            my ($quot, $rem) = $x->divmod($y);

            if ($rem->is_zero) {
                return $quot;
            }

            my $frac = Sidef::Types::Number::Fraction->new($quot->mul($y)->add($rem), $y);

            if ($frac->is_zero) {
                return __PACKAGE__->new($x->[1]);
            }

            return $frac;
        }

        if ($y->is_zero) {
            return __PACKAGE__->new((0 => Sidef::Types::Number::Number::inf()), $x->[1]);
        }

        my $m = $x->[1];
        $x = $x->[0];
        $y = $y->mod($m);

        __PACKAGE__->new((map { $_ => $x->{$_}->divmod($y, $m) } CORE::keys(%$x)), $m);
    }

    sub neg {
        my ($x) = @_;
        __PACKAGE__->new((map { $_ => $x->{$_}->neg } CORE::keys %{$x->[0]}), $x->[1]);
    }

    sub float {
        my ($x) = @_;
        __PACKAGE__->new((map { $_ => $x->{$_}->float } CORE::keys %{$x->[0]}), $x->[1]);
    }

    sub rat {
        my ($x) = @_;
        __PACKAGE__->new((map { $_ => $x->{$_}->rat } CORE::keys %{$x->[0]}), $x->[1]);
    }

    sub rat_approx {
        my ($x) = @_;
        __PACKAGE__->new((map { $_ => $x->{$_}->rat_approx } CORE::keys %{$x->[0]}), $x->[1]);
    }

    sub floor {
        my ($x) = @_;
        __PACKAGE__->new((map { $_ => $x->{$_}->floor } CORE::keys %{$x->[0]}), $x->[1]);
    }

    sub ceil {
        my ($x) = @_;
        __PACKAGE__->new((map { $_ => $x->{$_}->ceil } CORE::keys %{$x->[0]}), $x->[1]);
    }

    sub round {
        my ($x, $r) = @_;
        __PACKAGE__->new((map { $_ => $x->{$_}->round($r) } CORE::keys %{$x->[0]}), $x->[1]);
    }

    sub mod {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__ and $y->[1]->eq($x->[1])) {

            # mod(a, b) = a - b * floor(a/b)
            # return $x->sub($y->mul($x->div($y)->floor));

            my ($quot, $rem) = $x->divmod($y);
            return $rem;
        }

        __PACKAGE__->new($x->[0], $y);
    }

    #~ sub lift {
    #~ my ($x) = @_;
    #~ __PACKAGE__->new((map { $_ => $x->[0]{$_}->lift } CORE::keys %{$x->[0]}), $x->[1]);
    #~ }

    sub inv {
        my ($x) = @_;
        Sidef::Types::Number::Fraction->new(Sidef::Types::Number::Number::ONE, $x);
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
        __PACKAGE__->new(%{$x->[0]}, 0 => ($x->[0]{0} // Sidef::Types::Number::Number::ZERO)->inc, $x->[1]);
    }

    sub dec {
        my ($x) = @_;
        __PACKAGE__->new(%{$x->[0]}, 0 => ($x->[0]{0} // Sidef::Types::Number::Number::ZERO)->dec, $x->[1]);
    }

    sub pow {
        my ($x, $n) = @_;

        my $m = $x->[1];

        my $negative_power = 0;

        if ($n->is_neg) {
            $n              = $n->abs;
            $negative_power = 1;
        }

        my $c = __PACKAGE__->new(0 => Sidef::Types::Number::Number::ONE, $m);

        foreach my $bit (reverse split(//, $n->as_bin)) {

            # c = (c*x)%m if bit
            # x = (x*x)%m

            $c = $c->mul($x) if $bit;
            $x = $x->mul($x);
        }

        if ($negative_power) {
            $c = $c->inv;
        }

        return $c;
    }

    sub cmp {
        my ($x, $y) = @_;

        if (ref($x) eq ref($y)) {
            my $mod_cmp = $x->[1]->cmp($y->[1]);

            $mod_cmp->is_zero
              or return $mod_cmp;

            $x = $x->[0];
            $y = $y->[0];
        }
        else {
            $y = $y->mod($x->[1]);
            $x = $x->[0];
        }

        return $x->cmp($y);
    }

    sub eq {
        my ($x, $y) = @_;

        if (ref($x) eq ref($y)) {

            $x->[1]->eq($y->[1])
              or return Sidef::Types::Bool::Bool::FALSE;

            $x = $x->[0];
            $y = $y->[0];
        }
        else {
            $y = $y->mod($x->[1]);
            $x = $x->[0];
        }

        return $x->eq($y);
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
