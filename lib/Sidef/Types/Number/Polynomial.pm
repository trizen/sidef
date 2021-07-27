package Sidef::Types::Number::Polynomial {

    # Reference:
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
      q{""}   => sub { (@_) = ($_[0]); goto &__stringify__ };

    sub new {
        my (undef, @args) = @_;

        if (scalar(@args) == 1) {
            my $value = $args[0];

            if (UNIVERSAL::isa($value, 'Sidef::Types::Array::Array')) {
                my $end = $#{$value};
                return __PACKAGE__->new(map { ($end - $_) => $value->[$_] } 0 .. $end);
            }

            if (UNIVERSAL::isa($value, 'Sidef::Types::Number::Number')) {    # monomial
                return __PACKAGE__->new($value => Sidef::Types::Number::Number::ONE);
            }

            return __PACKAGE__->new(0 => $value);
        }

        my %coeff;

        while (@args) {
            my ($key, $value) = splice(@args, 0, 2);

            $key //= 0;
            $value // next;
            $value = Sidef::Types::Number::Number->new($value) if !UNIVERSAL::isa($value, 'Sidef::Types::Number::Number');

            if (!$value->is_zero) {
                $coeff{"$key"} = $value;
            }
        }

        bless \%coeff;
    }

    *call = \&new;

    sub __dump__ {
        my ($x) = @_;
        'Polynomial(' . join(", ", map { join(' => ', $_, $x->{$_}->dump) } sort { $a <=> $b } keys %$x) . ')';
    }

    sub __boolify__ {
        my ($x) = @_;
        ($x->{0} // 0);
    }

    sub __stringify__ {
        my ($x) = @_;

        my $str  = '';
        my @keys = sort { $b <=> $a } keys %$x;

        foreach my $key (@keys) {

            $str .= ' + ';

            my $c_str = ${$x->{$key}->dump};

            if ($c_str =~ s/^-//) {
                $str =~ s/ \+ \z/ - /;
            }

            if ($c_str =~ /[+-]/) {
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

    sub dump {
        my ($x) = @_;
        Sidef::Types::String::String->new($x->__dump__);
    }

    sub neg {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->neg } keys %$x);
    }

    sub add {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            return
              __PACKAGE__->new((map { $_ => (exists($y->{$_}) ? $x->{$_}->add($y->{$_}) : $x->{$_}) } keys %$x),
                               (map { exists($x->{$_}) ? () : ($_ => $y->{$_}) } keys %$y),);
        }

        if (not exists $x->{0}) {
            return __PACKAGE__->new(0 => $y, %$x);
        }

        __PACKAGE__->new(map { $_ => (($_ == 0) ? $x->{$_}->add($y) : $x->{$_}) } keys(%$x));
    }

    sub sub {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {
            return
              __PACKAGE__->new((map { $_ => (exists($y->{$_}) ? $x->{$_}->sub($y->{$_}) : $x->{$_}) } keys %$x),
                               (map { exists($x->{$_}) ? () : ($_ => $y->{$_}->neg) } keys %$y),);
        }

        if (not exists $x->{0}) {
            return __PACKAGE__->new(0 => $y->neg, %$x);
        }

        __PACKAGE__->new(map { $_ => (($_ == 0) ? $x->{$_}->sub($y) : $x->{$_}) } keys(%$x));
    }

    sub mul {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {

            my @keys_x = keys %$x;
            my @keys_y = keys %$y;

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

        __PACKAGE__->new(map { $_ => $x->{$_}->mul($y) } keys %$x);
    }

    sub sqr {
        my ($x) = @_;
        $x->mul($x);
    }

    sub div {
        my ($x, $y) = @_;

        # TODO: implement division by another polynomial (???)

        $x->mul($y->inv);
    }

    sub float {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->float } keys %$x);
    }

    sub floor {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->floor } keys %$x);
    }

    sub ceil {
        my ($x) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->ceil } keys %$x);
    }

    sub round {
        my ($x, $r) = @_;
        __PACKAGE__->new(map { $_ => $x->{$_}->round($r) } keys %$x);
    }

    sub mod {
        my ($x, $y) = @_;

        if (ref($y) eq 'Sidef::Types::Number::Number') {
            return __PACKAGE__->new(map { $_ => $x->{$_}->mod($y) } keys %$x);
        }

        # mod(a, b) = a - b * floor(a/b)
        $x->sub($y->mul($x->div($y)->floor));
    }

    sub inv {
        my ($x) = @_;

        # TODO: implement
        ...;
    }

    sub invmod {
        my ($x, $m) = @_;

        # TODO: implement
        ...;
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
            $c = $c->invmod($m);
        }

        return $c;
    }

    sub cmp {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {

            my @keys_x = grep { !$x->{$_}->is_zero } sort { $a <=> $b } keys %$x;
            my @keys_y = grep { !$y->{$_}->is_zero } sort { $a <=> $b } keys %$y;

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

        foreach my $key (keys(%$x)) {
            ($key == 0 or $x->{$key}->is_zero)
              or return undef;
        }

        $x->{0}->cmp($y);
    }

    sub eq {
        my ($x, $y) = @_;

        if (ref($y) eq __PACKAGE__) {

            foreach my $key (keys %$x) {
                if (exists $y->{$key}) {
                    $x->{$key}->eq($y->{$key})
                      or return Sidef::Types::Bool::Bool::FALSE;
                }
                else {
                    $x->{$key}->is_zero
                      or return Sidef::Types::Bool::Bool::FALSE;
                }
            }

            foreach my $key (keys %$y) {
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

        (exists($x->{0}) and $x->{0}->eq($y))
          || return Sidef::Types::Bool::Bool::FALSE;

        foreach my $key (keys(%$x)) {
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
