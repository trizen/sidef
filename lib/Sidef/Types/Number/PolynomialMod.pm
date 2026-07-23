package Sidef::Types::Number::PolynomialMod;

# References:
#   Lecture 14, Week 8 (2hrs) - Towards polynomial factorization
#   https://youtube.com/watch?v=KNyHz0eoAMA
#
#   Lecture 15, Week 8, 1hr - Polynomial factorization
#   https://youtube.com/watch?v=tMqKqsMb-Ro

use utf8;
use 5.016;

use List::Util   qw();
use Scalar::Util qw();

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

    if (Scalar::Util::reftype($mod) eq 'ARRAY') {
        $mod = __PACKAGE__->SUPER::new($mod);
    }

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

sub with_value {
    my ($self, $value) = @_;
    __PACKAGE__->new(0 => $value, $self->[1]);
}

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
    $str =~ s{\(\)}{\(0\)};
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
    $x->[0]->SUPER::__stringify__($method) . join('', " (mod ", ($x->[1] // '1'), ')');
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
    __PACKAGE__->new((map { (Math::Prime::Util::GMP::subint($_, 1), $x->{$_}->mul(Sidef::Types::Number::Number::_set_int($_))->mod($m)) } CORE::keys(%$x)), $m);
}

sub eval {
    my ($x, $value) = @_;

    my $m = $x->[1];
    $x = $x->[0];

    CORE::keys(%$x) || return Sidef::Types::Number::Number::ZERO;

    $value = $value->mod($m);
    Sidef::Types::Number::Number::sum(
                 map { Sidef::Types::Number::Mod->new($value, $m)->pow(Sidef::Types::Number::Number::_set_int($_))->lift->mul($x->{$_}->eval($value))->mod($m) }
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

    my $m = $moduli[0];
    foreach my $i (1 .. $#moduli) {
        $m = $m->lcm($moduli[$i]);
    }

    my $c = __PACKAGE__->new($m);

    foreach my $i (0 .. $#polynomials) {
        my $poly = $polynomials[$i];
        my $n    = $moduli[$i];
        my $t    = $m->div($n);
        my $u    = $t->mul($t->inv->mod($n));
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
                            (map { $_ => (exists($y->{$_}) ? $x->{$_}->add($y->{$_})->mod($m) : $x->{$_}) } CORE::keys %$x),
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

    __PACKAGE__->new((map { $_ => (($_ eq '0') ? $x->{$_}->add($y)->mod($m) : $x->{$_}) } CORE::keys(%$x)), $m);
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
                            (map { $_ => (exists($y->{$_}) ? $x->{$_}->sub($y->{$_})->mod($m) : $x->{$_}) } CORE::keys %$x),
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

    __PACKAGE__->new((map { $_ => (($_ eq '0') ? $x->{$_}->sub($y)->mod($m) : $x->{$_}) } CORE::keys(%$x)), $m);
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

                my $coeff = $x->{$key_x}->mul($y->{$key_y})->mod($m);
                my $key_z = Math::Prime::Util::GMP::addint($key_x, $key_y);

                if (exists $poly{$key_z}) {
                    $poly{$key_z} = $poly{$key_z}->add($coeff)->mod($m);
                }
                else {
                    $poly{$key_z} = $coeff;
                }
            }
        }

        return __PACKAGE__->new(%poly, $m);
    }

    $y = $y->mod($x->[1]);

    __PACKAGE__->new((map { $_ => $x->[0]{$_}->mul($y)->mod($x->[1]) } CORE::keys(%{$x->[0]})), $x->[1]);
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

    # Calculate modular inverse of the leading coefficient of divisor
    my $inv_c = $c->inv->mod($m);

    # If inverse does not exist (e.g. m is not prime), return NaN
    if ($inv_c->is_nan) {
        return (__PACKAGE__->new(Sidef::Types::Number::Number::nan(), Sidef::Types::Number::Number::nan()), __PACKAGE__->new($m));
    }

    while ($deg_r >= $deg_y) {

        my $lc = $r->[0]{$deg_r};    # lc(r)

        # Fix: Use modular inverse multiplication instead of integer division
        # t = lc(r) * inv(c) (mod m)
        my $t = $lc->mul($inv_c)->mod($m);

        # s := t * x^(deg(r)−deg(y))
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

sub normalize_to_monic {
    my ($x) = @_;
    my $deg = $x->degree->numify;
    return $x if $deg < 0;

    my $lc = $x->[0]{$deg};

    # Already monic
    return $x if $lc->is_one;

    # Multiply polynomial by inv(lc)
    my $inv = $lc->inv->mod($x->[1]);
    return $x if $inv->is_nan;    # Should not happen in field

    $x->mul($inv);
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

sub monic_gcd {
    my ($x, $y) = @_;
    $x->gcd($y)->normalize_to_monic;
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

    __PACKAGE__->new((map { $_ => $x->{$_}->div($y)->mod($m) } CORE::keys(%$x)), $m);
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

    my $m = $x->[1];     # modulus polynomial (a Polynomial)
    my $f = $x->lift;    # residue polynomial (a plain Polynomial)

    if (ref($m) ne 'Sidef::Types::Number::Polynomial') {
        return Sidef::Types::Number::Fraction->new(Sidef::Types::Number::Number::ONE, $x);
    }

    # Run the extended Euclidean algorithm on the plain polynomials.
    # Returns (g, u, v, ...) satisfying: u*f + v*m = g,
    # with g normalised to monic by Polynomial::gcdext.
    my ($g, $u) = $f->gcdext($m);

    # The inverse exists iff gcd(f, m) = 1.
    # If g is not the constant polynomial 1, f is not invertible mod m.
    $g->is_one
      || return __PACKAGE__->new(0 => Sidef::Types::Number::Number::nan(), $m);

    # u*f ≡ 1 (mod m).
    __PACKAGE__->new($u, $m);
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

sub powmod {
    my ($base, $exp, $poly_mod) = @_;

    my $p = $base->[1];    # scalar prime (Number)

    $base = $base->mod($poly_mod);

    my $result = __PACKAGE__->new(0 => Sidef::Types::Number::Number::ONE, $p);

    foreach my $bit (reverse split(//, $exp->as_bin)) {
        $result = $result->mul($base)->mod($poly_mod) if $bit;
        $base   = $base->mul($base)->mod($poly_mod);
    }

    return $result;
}

sub _poly_clone {
    my ($A) = @_;
    return [map { Math::GMPz::Rmpz_init_set($_) } @$A];
}

sub _poly_deg {
    my ($A) = @_;
    my $d = $#$A;
    while ($d >= 0 && Math::GMPz::Rmpz_sgn($A->[$d]) == 0) { $d--; }
    return $d;
}

sub _poly_strip {
    my ($A) = @_;
    while (@$A && Math::GMPz::Rmpz_sgn($A->[-1]) == 0) { pop @$A; }
    return $A;
}

sub _poly_monic {
    my ($A, $p) = @_;
    my $d = _poly_deg($A);
    return [] if $d < 0;
    my $lc = $A->[$d];
    if (Math::GMPz::Rmpz_cmp_ui($lc, 1) != 0) {
        my $inv = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_invert($inv, $lc, $p);
        for my $i (0 .. $d) {
            Math::GMPz::Rmpz_mul($A->[$i], $A->[$i], $inv);
            Math::GMPz::Rmpz_mod($A->[$i], $A->[$i], $p);
        }
    }
    return _poly_strip($A);
}

sub _poly_add {
    my ($A, $B, $p) = @_;
    my @res;
    my $max  = @$A > @$B ? $#$A : $#$B;
    my $zero = Math::GMPz::Rmpz_init();
    for my $i (0 .. $max) {
        my $v = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add($v, $i <= $#$A ? $A->[$i] : $zero, $i <= $#$B ? $B->[$i] : $zero);
        Math::GMPz::Rmpz_mod($v, $v, $p);
        push @res, $v;
    }
    return _poly_strip(\@res);
}

sub _poly_sub {
    my ($A, $B, $p) = @_;
    my @res;
    my $max  = @$A > @$B ? $#$A : $#$B;
    my $zero = Math::GMPz::Rmpz_init();
    for my $i (0 .. $max) {
        my $v = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub($v, $i <= $#$A ? $A->[$i] : $zero, $i <= $#$B ? $B->[$i] : $zero);
        Math::GMPz::Rmpz_mod($v, $v, $p);
        push @res, $v;
    }
    return _poly_strip(\@res);
}

sub _poly_mul {
    my ($A, $B, $p) = @_;
    my $da = _poly_deg($A);
    my $db = _poly_deg($B);
    return [] if $da < 0 || $db < 0;

    my @res = map { Math::GMPz::Rmpz_init() } 0 .. ($da + $db);
    my $t   = Math::GMPz::Rmpz_init();

    for my $i (0 .. $da) {
        next if Math::GMPz::Rmpz_sgn($A->[$i]) == 0;
        for my $j (0 .. $db) {
            Math::GMPz::Rmpz_mul($t, $A->[$i], $B->[$j]);
            Math::GMPz::Rmpz_add($res[$i + $j], $res[$i + $j], $t);
        }
    }
    for my $r (@res) {
        Math::GMPz::Rmpz_mod($r, $r, $p);
    }
    return _poly_strip(\@res);
}

sub _poly_divmod {
    my ($x, $y, $p) = @_;
    my $dx = _poly_deg($x);
    my $dy = _poly_deg($y);

    return ([], _poly_clone($x)) if $dx < $dy;

    my $r = _poly_clone($x);
    my @q = map { Math::GMPz::Rmpz_init() } 0 .. ($dx - $dy);

    my $inv_lc = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_invert($inv_lc, $y->[$dy], $p);
    my $t = Math::GMPz::Rmpz_init();

    for (my $i = $dx ; $i >= $dy ; $i--) {
        next if Math::GMPz::Rmpz_sgn($r->[$i]) == 0;

        Math::GMPz::Rmpz_mul($t, $r->[$i], $inv_lc);
        Math::GMPz::Rmpz_mod($t, $t, $p);
        Math::GMPz::Rmpz_set($q[$i - $dy], $t);

        for my $j (0 .. $dy) {
            next if Math::GMPz::Rmpz_sgn($y->[$j]) == 0;
            my $m = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_mul($m, $t, $y->[$j]);
            Math::GMPz::Rmpz_sub($r->[$i - $dy + $j], $r->[$i - $dy + $j], $m);
            Math::GMPz::Rmpz_mod($r->[$i - $dy + $j], $r->[$i - $dy + $j], $p);
        }
    }
    return (_poly_strip(\@q), _poly_strip($r));
}

sub _poly_mod {
    my ($x, $y, $p) = @_;
    my ($q, $r) = _poly_divmod($x, $y, $p);
    return $r;
}

sub _poly_gcd {
    my ($A, $B, $p) = @_;
    my $r0 = _poly_clone($A);
    my $r1 = _poly_clone($B);
    while (_poly_deg($r1) >= 0) {
        my $r = _poly_mod($r0, $r1, $p);
        $r0 = $r1;
        $r1 = $r;
    }
    return _poly_monic($r0, $p);
}

sub _poly_derivative {
    my ($A, $p) = @_;
    my $d = _poly_deg($A);
    return [] if $d < 1;
    my @res;
    for my $i (1 .. $d) {
        my $v = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul_ui($v, $A->[$i], $i);
        Math::GMPz::Rmpz_mod($v, $v, $p);
        push @res, $v;
    }
    return _poly_strip(\@res);
}

sub _poly_powmod {
    my ($base, $exp, $modpoly, $p) = @_;
    my $res = [Math::GMPz::Rmpz_init_set_ui(1)];
    my $B   = _poly_mod($base, $modpoly, $p);

    my $e = Math::GMPz::Rmpz_init_set($exp);
    while (Math::GMPz::Rmpz_sgn($e) > 0) {
        if (Math::GMPz::Rmpz_tstbit($e, 0)) {
            $res = _poly_mod(_poly_mul($res, $B, $p), $modpoly, $p);
        }
        $B = _poly_mod(_poly_mul($B, $B, $p), $modpoly, $p);
        Math::GMPz::Rmpz_fdiv_q_2exp($e, $e, 1);
    }
    return $res;
}

# ======================================================================
# Sub-algorithms for Factorization
# ======================================================================

sub _poly_ddf {
    my ($f, $p) = @_;
    my $x_poly = [Math::GMPz::Rmpz_init(), Math::GMPz::Rmpz_init_set_ui(1)];
    my $w      = _poly_clone($x_poly);
    my @factors;

    my $f_curr = _poly_clone($f);
    my $deg_f  = _poly_deg($f_curr);

    for my $k (1 .. $deg_f) {
        $w = _poly_powmod($w, $p, $f_curr, $p);
        my $diff = _poly_sub($w, $x_poly, $p);
        my $gk   = _poly_gcd($diff, $f_curr, $p);

        if (_poly_deg($gk) > 0) {
            push @factors, [$k, $gk];
            my ($q, $r) = _poly_divmod($f_curr, $gk, $p);
            $f_curr = $q;
        }
        last if _poly_deg($f_curr) <= 0;
    }

    if (_poly_deg($f_curr) > 0) {
        push @factors, [_poly_deg($f_curr), $f_curr];
    }
    return @factors;
}

sub _poly_edf {
    my ($f, $d, $p, $p_sidef) = @_;
    my $deg_f = _poly_deg($f);
    return ()   if $deg_f <= 0;
    return ($f) if $deg_f == $d;

    my $is_char2 = (Math::GMPz::Rmpz_cmp_ui($p, 2) == 0);
    my $exp      = Math::GMPz::Rmpz_init();

    if (!$is_char2) {
        Math::GMPz::Rmpz_pow_ui($exp, $p, $d);
        Math::GMPz::Rmpz_sub_ui($exp, $exp, 1);
        Math::GMPz::Rmpz_fdiv_q_2exp($exp, $exp, 1);
    }

    my $g;
    for (1 .. 200) {
        my @t;
        for my $k (0 .. $deg_f - 1) {
            my $c_sidef = $p_sidef->irand;
            my $c       = Sidef::Types::Number::Number::_any2mpz($$c_sidef);
            push @t, Math::GMPz::Rmpz_init_set($c);
        }
        my $t_poly = _poly_strip(\@t);
        next if _poly_deg($t_poly) < 0;

        my $h;
        if ($is_char2) {
            $h = _poly_mod($t_poly, $f, $p);
            my $ti = _poly_clone($h);
            for my $i (1 .. $d - 1) {
                $ti = _poly_powmod($ti, $p, $f, $p);
                $h  = _poly_add($h, $ti, $p);
            }
        }
        else {
            my $t_pow = _poly_powmod($t_poly, $exp, $f, $p);
            my $one   = [Math::GMPz::Rmpz_init_set_ui(1)];
            $h = _poly_sub($t_pow, $one, $p);
        }

        $g = _poly_gcd($h, $f, $p);
        last if _poly_deg($g) > 0 && _poly_deg($g) < $deg_f;
    }

    return ($f) unless (defined($g) && _poly_deg($g) > 0 && _poly_deg($g) < $deg_f);

    my ($q, $r) = _poly_divmod($f, $g, $p);
    return (__SUB__->($g, $d, $p, $p_sidef), __SUB__->($q, $d, $p, $p_sidef));
}

sub factor_exp {
    my ($original) = @_;

    my $p_sidef = $original->[1];
    Sidef::Types::Number::Number::_valid(\$p_sidef);
    my $p = Sidef::Types::Number::Number::_any2mpz($$p_sidef) // return Sidef::Types::Array::Array->new();

    # 1. Convert Sidef PolynomialMod into dense GMPz Array
    my $hash     = $original->[0];
    my $deg_orig = List::Util::max(CORE::keys %$hash) // -1;
    my @orig_poly;
    for my $i (0 .. $deg_orig) {
        if (exists $hash->{$i}) {
            push @orig_poly, Math::GMPz::Rmpz_init_set(Sidef::Types::Number::Number::_any2mpz(${$hash->{$i}}));
        }
        else {
            push @orig_poly, Math::GMPz::Rmpz_init();
        }
    }
    my $orig_poly = _poly_strip(\@orig_poly);
    $deg_orig = _poly_deg($orig_poly);

    # Handle leading coefficient
    my $lc_sidef;
    if ($deg_orig < 0) {
        $lc_sidef = Sidef::Types::Number::Number::ZERO;
        return Sidef::Types::Array::Array->new([Sidef::Types::Array::Array->new([$lc_sidef, Sidef::Types::Number::Number::ONE])]);
    }
    else {
        $lc_sidef = Sidef::Types::Number::Number::_set_int($orig_poly->[$deg_orig]);
    }

    # 2. Extract Monic and Squarefree part
    my $f  = _poly_monic(_poly_clone($orig_poly), $p);
    my $df = _poly_derivative($f, $p);
    if (_poly_deg($df) >= 0) {
        my $sq = _poly_gcd($f, $df, $p);
        if (_poly_deg($sq) > 0) {
            my ($q, $r) = _poly_divmod($f, $sq, $p);
            $f = _poly_monic($q, $p);
        }
    }

    # 3. Factorization Stages
    my @ddf_groups = _poly_deg($f) <= 0 ? () : _poly_ddf($f, $p);

    my @irreducibles;
    for my $pair (@ddf_groups) {
        my ($d, $fk) = @$pair;
        next if _poly_deg($fk) <= 0;
        push @irreducibles, _poly_edf($fk, $d, $p, $p_sidef);
    }

    # 4. Trial Division for Multiplicities
    my $remainder = _poly_clone($orig_poly);
    my @factors;

    for my $irred (@irreducibles) {
        my $e = 0;
        while (1) {
            my ($q, $r) = _poly_divmod($remainder, $irred, $p);
            last if _poly_deg($r) >= 0;    # Remainder is NOT zero
            $e++;
            $remainder = $q;
        }

        if ($e > 0) {

            # Map dense array back to Sidef object
            my %h;
            for my $i (0 .. _poly_deg($irred)) {
                next if Math::GMPz::Rmpz_sgn($irred->[$i]) == 0;
                my $r = $irred->[$i];
                $h{$i} = bless(\$r, 'Sidef::Types::Number::Number');
            }

            my $irred_sidef = __PACKAGE__->new(%h, $p_sidef);
            push @factors, Sidef::Types::Array::Array->new([$irred_sidef, Sidef::Types::Number::Number::_set_int($e)]);
        }
    }

    my $arr = Sidef::Types::Array::Array->new(\@factors)->sort;
    $arr->unshift(Sidef::Types::Array::Array->new([$lc_sidef, Sidef::Types::Number::Number::ONE]));

    return $arr;
}

sub factor {
    my ($self) = @_;
    Sidef::Types::Array::Array->new([map { ($_->[0]) x CORE::int($_->[1]) } @{$self->factor_exp}]);
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

1
