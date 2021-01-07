package Sidef::Math::Math {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Object::Object
      );

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
        my $n   = Sidef::Types::Number::Number->_set_uint(scalar(@list));

        $sum->div($n);
    }

    *avg = \&arithmetic_mean;

    sub geometric_mean {
        my ($self, @list) = @_;

        my $prod = Sidef::Types::Number::Number::prod(@list);
        my $n    = Sidef::Types::Number::Number->_set_uint(scalar(@list));

        $prod->root($n);
    }

    sub harmonic_mean {
        my ($self, @list) = @_;

        my $sum = Sidef::Types::Number::Number::sum(map { $_->inv } @list);
        my $n   = Sidef::Types::Number::Number->_set_uint(scalar(@list));

        $n->div($sum);
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

        if ($res < Sidef::Types::Number::Number::ULONG_MAX and $res >= 0) {
            return Sidef::Types::Number::Number->_set_uint($res);
        }

        Sidef::Types::Number::Number->_set_str('int', $res);
    }

    sub range_sum {
        my ($self, $from, $to, $step) = @_;
        $step //= Sidef::Types::Number::Number::ONE;
        state $two = Sidef::Types::Number::Number->_set_uint(2);
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

        state $hundred = Sidef::Types::Number::Number->_set_uint(100);
        ($sum->sub($dist))->div($sum)->mul($hundred);
    }
}

1;
