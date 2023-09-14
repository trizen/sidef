package Sidef::Types::Number::Polynomial {

    # References:
    #   https://en.wikipedia.org/wiki/Polynomial
    #   https://metacpan.org/pod/Math::Polynomial
    #   https://metacpan.org/pod/Math::Polynomial::Cyclotomic

    use utf8;
    use 5.016;

    require List::Util;

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

            if (ref($value) eq 'Sidef::Types::String::String') {
                my $str = "$value";

                # Basic support for fractions of polynomials
                if (

                    # (anything)/(anything)
                    # anything/(anything)
                    $str =~ m{^\s*+
                        \(?+(?<numerator>.*?)\)?+
                            \s*+/\s*+
                        \((?<denominator>.*)\)
                    \s*+\z}x

                    # (anything)/x
                    # anything/x
                    # anything/x^5
                    or $str =~ m{^\s*+
                        \(?+(?<numerator>.*?)\)?+
                            \s*+/\s*+
                        (?<denominator>[-+]?+\s*x(?>\^[-+]?+[0-9]++)?+)
                    \s*+\z}x

                    # (anything)/integer
                    or $str =~ m{^\s*+
                        \((?<numerator>.*?)\)
                            \s*+/\s*+
                        (?<denominator>[-+]?+[0-9]++)
                    \s*+\z}x
                  ) {
                    my $num   = $+{numerator};
                    my $den   = $+{denominator};
                    my $poly1 = __PACKAGE__->new(Sidef::Types::String::String->new($num));
                    my $poly2 = __PACKAGE__->new(Sidef::Types::String::String->new($den));
                    return $poly1->div($poly2);
                }

                my %pairs;
                while (
                    $str =~ m{\G\s*+
                        (?<sign>[-+])?+\s*+
                        (?<coeff>[0-9]++\s*+(?>/\s*[1-9]+[0-9]*)?)?+
                        (?>\s*\*\s*)?+
                        (?>(?<x>x)(?>\^\(?(?<exp>[-+]?[0-9]++))?+\)?+)?+
                \s*+}gcx
                  ) {
                    my $sign  = $+{sign} // '+';
                    my $exp   = defined($+{x}) ? ($+{exp} // 1) : 0;
                    my $coeff = Sidef::Types::Number::Number->new(($+{coeff} eq '') ? '1' : $+{coeff});
                    $coeff = $coeff->neg if $sign eq '-';
                    $pairs{$exp} = $coeff;
                    last if $str =~ /\G\z/;
                }

                # Failed to parse the entire string: return NaN
                if ($str !~ /\G\z/) {
                    return __PACKAGE__->new('0' => Sidef::Types::Number::Number::nan());
                }

                # Create and return the parsed polynomial
                return __PACKAGE__->new(%pairs);
            }

            if (UNIVERSAL::isa($value, 'Sidef::Types::Array::Array')) {
                my $end = $#{$value};
                return __PACKAGE__->new(
                    map {
                        my $t = $value->[$_];
                        UNIVERSAL::isa($t, 'Sidef::Types::Array::Array') ? (($t->[0], $t->[1])) : (($end - $_) => $t)
                      } 0 .. $end
                );
            }

            if (UNIVERSAL::isa($value, 'Sidef::Types::Number::Number')) {    # monomial
                return __PACKAGE__->new($value => Sidef::Types::Number::Number::ONE);
            }

            return __PACKAGE__->new(0 => $value);
        }

        my %poly;

        my %pairs = @args;
        foreach my $key (CORE::keys(%pairs)) {

            my $value = $pairs{$key} // next;
            $value = Sidef::Types::Number::Number->new($value) if !UNIVERSAL::isa($value, 'Sidef::Types::Number::Number');

            unless ($value->is_zero) {
                $poly{$key} = $value;
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
        my ($x, $method) = @_;

        $method //= 'to_s';

        my $str  = '';
        my @keys = sort { $b <=> $a } CORE::keys %$x;

        foreach my $key (@keys) {

            $str .= ' + ';

            my $v = $x->{$key};
            my $c_str =
              (ref($v) eq 'Sidef::Types::Number::Number' and ref($$v) eq 'Math::GMPq')
              ? Math::GMPq::Rmpq_get_str($$v, 10)
              : ${$v->$method};

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
        $str || '0';
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

    sub degree {
        my ($x) = @_;
        Sidef::Types::Number::Number::_set_int(List::Util::max(CORE::keys(%$x)) // 0);
    }

    sub derivative {
        my ($x) = @_;
        __PACKAGE__->new(map { ($_ - 1, $x->{$_}->mul(Sidef::Types::Number::Number::_set_int($_))) } CORE::keys(%$x));
    }

    sub eval {
        my ($x, $value) = @_;
        CORE::keys(%$x) || return Sidef::Types::Number::Number::ZERO;
        Sidef::Types::Number::Number::sum(map { $value->pow(Sidef::Types::Number::Number::_set_int($_))->mul($x->{$_}->eval($value)) } CORE::keys %$x);
    }

    sub exponents {
        my ($x) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::Number::Number::_set_int($_) } sort { $a <=> $b } CORE::keys(%$x));
    }

    sub coeff {
        my ($x, $key) = @_;
        $x->{$key} // Sidef::Types::Number::Number::ZERO;
    }

    sub coeffs {
        my ($x) = @_;
        Sidef::Types::Array::Array->new(
                                        [map  { Sidef::Types::Array::Array->new([Sidef::Types::Number::Number::_set_int($_), $x->{$_}]) }
                                         sort { $a <=> $b } CORE::keys(%$x)
                                        ]
                                       );
    }

    sub newton_method {
        my ($f, $x, $df) = @_;

        $x  //= Sidef::Types::Number::Number->i;
        $df //= $f->derivative;

        for (0 .. CORE::int($Sidef::Types::Number::Number::PREC)) {
            my $fx = $f->eval($x);
            if ($fx->approx_eq(Sidef::Types::Number::Number::ZERO)) {
                return $x;
            }
            my $dfx = $df->eval($x);
            $x = $x->sub($fx->div($dfx));
        }

        return $x;
    }

    sub roots {
        my ($f) = @_;

        my $degree         = $f->degree;
        my @roots_of_unity = @{$degree->roots_of_unity};

        @roots_of_unity || return Sidef::Types::Array::Array->new;

        my $df = $f->derivative;

        my $prec     = Sidef::Types::Number::Number::_set_int(-((CORE::int($Sidef::Types::Number::Number::PREC) >> 2) - 1));
        my $prec_min = Sidef::Types::Number::Number::_set_int(-(CORE::int($Sidef::Types::Number::Number::PREC) >> 3));

        my %seen;
        my @polygonal_roots;

        foreach my $root (@roots_of_unity) {
            my $solution = $f->newton_method($root, $df);
            if (defined($solution)) {
                my $key = join('', $solution->round($prec));
                if (!exists($seen{$key}) and $f->eval($solution)->round($prec_min)->is_zero) {
                    push @polygonal_roots, $solution;
                    $seen{$key} = 1;
                }
            }
        }

        $degree = CORE::int($degree);

        # TODO: find a more efficient approach for inputs like:
        #       x = Poly(1); roots(5*x**4 + 11*x**2 + 100)
        #       x = Poly(1); roots(5*x**4 + 9*x**3 + 11*x**2 + 100)
        #       x = Poly(1); roots(12*x**4 + 11*x**2 + 4171)
        if (scalar(@polygonal_roots) != $degree) {

            my @transformations = (
                                   sub { $_[0]->i },
                                   sub { $_[0]->exp },
                                   sub { $_[0]->neg },
                                   sub { $_[0]->sqr->dec },
                                   sub { $_[0]->sqr->inc },
                                   sub { $_[0]->sqrt },
                                   sub { $_[0]->conj },
                                   sub { $_[0]->neg },
                                  );

            while (@transformations) {

                my $transform = CORE::shift(@transformations);
                @roots_of_unity = map { $transform->($_) } @roots_of_unity;

                foreach my $root (@roots_of_unity) {
                    my $solution = $f->newton_method($root, $df);
                    if (defined($solution)) {

                        my $key = join('', $solution->round($prec));
                        if (!exists($seen{$key}) and $f->eval($solution)->round($prec_min)->is_zero) {
                            push @polygonal_roots, $solution;
                            $seen{$key} = 1;
                        }

                        last if (scalar(@polygonal_roots) == $degree);
                    }
                }

                last if (scalar(@polygonal_roots) == $degree);
            }
        }

        Sidef::Types::Array::Array->new(\@polygonal_roots);
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
                               (map { exists($x->{$_}) ? () : ($_ => $y->{$_}->neg) } CORE::keys %$y));
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

        # Reference:
        #   https://en.wikipedia.org/wiki/Polynomial_greatest_common_divisor#Euclidean_division

        my $deg_r = List::Util::max(CORE::keys(%$x));    # deg(x)
        $deg_r // return (__PACKAGE__->new(), __PACKAGE__->new());

        my $deg_y = List::Util::max(CORE::keys(%$y));    # deg(y)
        $deg_y // return (__PACKAGE__->new(0 => Sidef::Types::Number::Number::inf()), __PACKAGE__->new());

        my $q = __PACKAGE__->new();
        my $r = $x;
        my $c = $y->{$deg_y};                            # lc(y)

        while ($deg_r >= $deg_y) {

            my $lc = $r->{$deg_r};                       # lc(r)
            my $t  = $lc->div($c);                       # lc(r)/c

            # When the result of division is NaN, the loop never stops
            if ($t->is_nan) {
                return (__PACKAGE__->new(0 => Sidef::Types::Number::Number::nan()), __PACKAGE__->new());
            }

            # s := lc(r)/c * x^(deg(r)−deg(y))
            my $s = __PACKAGE__->new($deg_r - $deg_y, $t);
            $q = $q->add($s);
            $r = $r->sub($s->mul($y));

            # Find deg(r) for the new r
            $deg_r = List::Util::max(CORE::keys(%$r)) // last;
        }

        return ($q, $r);
    }

    sub sgn {
        my ($x) = @_;
        my $deg = List::Util::max(CORE::keys(%$x)) // return Sidef::Types::Number::Number::ZERO;
        $x->{$deg}->sgn;
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
            $y = __PACKAGE__->new(0 => $y);
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

            my $frac = Sidef::Types::Number::Fraction->new($quot->mul($y)->add($rem), $y);

            if ($frac->is_zero) {
                return Sidef::Types::Number::Polynomial->new();
            }

            return $frac;
        }

        if ($y->is_zero) {
            return __PACKAGE__->new(0 => Sidef::Types::Number::Number::inf());
        }

        __PACKAGE__->new(map { $_ => $x->{$_}->div($y) } CORE::keys %$x);
    }

    sub neg {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->neg } CORE::keys %$x);
    }

    sub float {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->float } CORE::keys %$x);
    }

    sub rat {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->rat } CORE::keys %$x);
    }

    sub rat_approx {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->rat_approx } CORE::keys %$x);
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

    sub lift {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->lift } CORE::keys %$x);
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

        $n->is_int || return $x->to_n->pow($n);

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

            my @keys_x = sort { $a <=> $b } CORE::keys %$x;
            my @keys_y = sort { $a <=> $b } CORE::keys %$y;

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
