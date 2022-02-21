package Sidef::Math::Math {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Object::Object
    );

    require List::Util;
    use Sidef::Types::Number::Number;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub binsplit {
        my ($self, $block, @list) = @_;
        Sidef::Types::Number::Number::_binsplit(\@list, $block);
    }

    sub gcd {
        my ($self, @list) = @_;
        Sidef::Types::Number::Number::gcd(@list);
    }

    sub lcm {
        my ($self, @list) = @_;
        Sidef::Types::Number::Number::lcm(@list);
    }

    sub sum {
        my ($self, @list) = @_;
        Sidef::Types::Number::Number::sum(@list);
    }

    sub prod {
        my ($self, @list) = @_;
        Sidef::Types::Number::Number::prod(@list);
    }

    *product = \&prod;

    sub max {
        my ($self, @list) = @_;
        Sidef::Types::Number::Number::max(@list);
    }

    sub min {
        my ($self, @list) = @_;
        Sidef::Types::Number::Number::min(@list);
    }

    sub arithmetic_mean {
        my ($self, @list) = @_;

        my $sum = Sidef::Types::Number::Number::sum(@list);
        my $n   = Sidef::Types::Number::Number::_set_int(scalar(@list));

        $sum->div($n);
    }

    *avg = \&arithmetic_mean;

    sub geometric_mean {
        my ($self, @list) = @_;

        my $prod = Sidef::Types::Number::Number::prod(@list);
        my $n    = Sidef::Types::Number::Number::_set_int(scalar(@list));

        $prod->root($n);
    }

    sub harmonic_mean {
        my ($self, @list) = @_;

        my $sum = Sidef::Types::Number::Number::sum(map { $_->inv } @list);
        my $n   = Sidef::Types::Number::Number::_set_int(scalar(@list));

        $n->div($sum);
    }

    sub product_tree {
        my ($self, @list) = @_;

        # Algorithm from: https://facthacks.cr.yp.to/product.html

        my @result = Sidef::Types::Array::Array->new([@list]);

        while (scalar(@list) > 1) {
            @list =
              map { Sidef::Types::Number::Number::prod(@list[($_ << 1) .. List::Util::min($#list, (($_ + 1) << 1) - 1)]) }
              0 .. (((scalar(@list) + 1) >> 1) - 1);

            push @result, Sidef::Types::Array::Array->new([@list]);
        }

        Sidef::Types::Array::Array->new(\@result);
    }

    sub remainders {
        my ($self, $n, $arr) = @_;

        # Algorithm from: https://facthacks.cr.yp.to/remainder.html

        my @result = ($n);

        foreach my $t (@{$self->product_tree(@$arr)->flip}) {
            @result = map { $result[$_ >> 1]->mod($t->[$_]) } 0 .. $#{$t};
        }

        Sidef::Types::Array::Array->new(\@result);
    }

    sub batch_gcd {
        my ($self, @X) = @_;

        # Algorithm from: https://facthacks.cr.yp.to/batchgcd.html

        my $prods = $self->product_tree(@X);
        my @R     = @{pop(@$prods) // return Sidef::Types::Array::Array->new()};

        while (@$prods) {
            @X = @{pop(@$prods)};
            @R = map { $R[$_ >> 1]->mod($X[$_]->sqr) } 0 .. $#X;
        }

        Sidef::Types::Array::Array->new([map { Sidef::Types::Number::Number::gcd($R[$_]->idiv($X[$_]), $X[$_]) } 0 .. $#R]);
    }

    sub batch_invmod {
        my ($self, $x, $n) = @_;

        # Algorithm 2.11 MultipleInversion from Modern Computer Arithmetic

        @$x || return Sidef::Types::Array::Array->new;

        my $k = $#{$x};
        my @z = ($x->[0]);

        foreach my $i (1 .. $k) {
            $z[$i] = ($z[$i - 1]->mulmod($x->[$i], $n));
        }

        my @y;
        my $q = $z[$k]->invmod($n);

        for (my $i = $k ; $i >= 1 ; --$i) {
            $y[$i] = $q->mulmod($z[$i - 1], $n);
            $q = $q->mulmod($x->[$i], $n);
        }

        $y[0] = $q;
        Sidef::Types::Array::Array->new(\@y);
    }

    sub smooth_numbers {
        my ($self, @primes) = @_;

        my @s = map { [Sidef::Types::Number::Number::ONE] } @primes;

        Sidef::Object::Enumerator->new(
            Sidef::Types::Block::Block->new(
                code => sub {
                    my ($callback) = @_;

                    while (1) {
                        my $n = Sidef::Types::Number::Number::min(map { $_->[0] } @s);

                        for my $i (0 .. $#primes) {
                            shift(@{$s[$i]}) if $s[$i][0]->eq($n);
                            push(@{$s[$i]}, $n->mul($primes[$i]));
                        }

                        $callback->run($n);
                    }
                }
            )
        );
    }

    sub chinese {
        my ($self, @arrs) = @_;

        my @pairs;
        foreach my $pair (@arrs) {
            if (    Scalar::Util::reftype($pair) eq 'ARRAY'
                and @$pair == 2
                and ref($pair->[0]) eq 'Sidef::Types::Number::Number'
                and ref($pair->[1]) eq 'Sidef::Types::Number::Number') {
                push @pairs, [map { $_->_big2istr } @$pair];
            }
            else {
                return Sidef::Types::Number::Number->nan;
            }
        }

        my $res = eval { Math::Prime::Util::GMP::chinese(@pairs) } // return Sidef::Types::Number::Number->nan;
        Sidef::Types::Number::Number::_set_int($res);
    }

    sub range_sum {
        my ($self, $from, $to, $step) = @_;
        $step //= Sidef::Types::Number::Number::ONE;
        state $two = Sidef::Types::Number::Number::_set_int(2);
        ($from->add($to))->mul($to->sub($from)->div($step)->add(Sidef::Types::Number::Number::ONE))->div($two);
    }

    sub range_map {
        my ($self, $amount, $from, $to) = @_;
        Sidef::Types::Range::RangeNumber->new($from, $to, $to->sub($from)->div($amount));
    }

    sub map {
        my ($self, $value, $in_min, $in_max, $out_min, $out_max) = @_;
        ($value->sub($in_min))->mul($out_max->sub($out_min))->div($in_max->sub($in_min))->add($out_min);
    }

    sub num2percent {
        my ($self, $num, $from, $to) = @_;

        my $sum  = $to->sub($from)->abs;
        my $dist = $num->sub($to)->abs;

        state $hundred = Sidef::Types::Number::Number::_set_int(100);
        ($sum->sub($dist))->div($sum)->mul($hundred);
    }
}

1;
