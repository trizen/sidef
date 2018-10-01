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

    sub _binsplit {
        my ($arr, $method) = @_;

        my $sub = sub {
            my ($s, $n, $m) = @_;

            $n == $m
              ? $s->[$n]
              : __SUB__->($s, $n, ($n + $m) >> 1)->$method(__SUB__->($s, (($n + $m) >> 1) + 1, $m));
        };

        my $end = $#$arr;

        if ($end < 0) {
            return undef;
        }

        if ($end <= 1e5) {
            return $sub->($arr, 0, $end);
        }

        my @partial;

        while (@$arr) {
            my @head = splice(@$arr, 0, 1e5);
            push @partial, $sub->(\@head, 0, $#head);
        }

        __SUB__->(\@partial, $method);
    }

    sub gcd {
        my ($self, @list) = @_;

        @list || return Sidef::Types::Number::Number::ZERO;

        my $gcd = $list[0];
        foreach my $i (1 .. $#list) {
            last if $gcd->is_one;
            $gcd = $gcd->gcd($list[$i]);
        }

        $gcd;
    }

    sub lcm {
        my ($self, @list) = @_;
        @list || return Sidef::Types::Number::Number::ZERO;
        _binsplit(\@list, 'lcm');
    }

    sub sum {
        my ($self, @list) = @_;
        @list || return Sidef::Types::Number::Number::ZERO;
        _binsplit(\@list, 'add');
    }

    sub prod {
        my ($self, @list) = @_;
        @list || return Sidef::Types::Number::Number::ONE;
        _binsplit(\@list, 'mul');
    }

    *product = \&prod;

    sub max {
        my ($self, @list) = @_;

        my $max = $list[0];
        foreach my $i (1 .. $#list) {
            $max = $max->max($list[$i]);
        }

        $max;
    }

    sub min {
        my ($self, @list) = @_;

        my $min = $list[0];
        foreach my $i (1 .. $#list) {
            $min = $min->min($list[$i]);
        }

        $min;
    }

    sub arithmetic_mean {
        my ($self, @list) = @_;

        my $sum = $self->sum(@list);
        my $n   = Sidef::Types::Number::Number->_set_uint(scalar(@list));

        $sum->div($n);
    }

    *avg = \&arithmetic_mean;

    sub geometric_mean {
        my ($self, @list) = @_;

        my $prod = $self->prod(@list);
        my $n    = Sidef::Types::Number::Number->_set_uint(scalar(@list));

        $prod->root($n);
    }

    sub harmonic_mean {
        my ($self, @list) = @_;

        my $sum = $self->sum(map { $_->inv } @list);
        my $n = Sidef::Types::Number::Number->_set_uint(scalar(@list));

        $n->div($sum);
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
