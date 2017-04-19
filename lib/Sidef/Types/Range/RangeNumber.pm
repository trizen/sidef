package Sidef::Types::Range::RangeNumber {

    use 5.014;

    use parent qw(
      Sidef::Types::Range::Range
      Sidef::Object::Object
      );

    use overload q{""} => sub {
        my ($self) = @_;
        "RangeNum($self->{from}, $self->{to}, $self->{step})";
    };

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

    sub new {
        my (undef, $from, $to, $step) = @_;

        if (not defined $from) {
            $from = Sidef::Types::Number::Number::ZERO;
            $to   = Sidef::Types::Number::Number::MONE;
        }

        if (not defined $to) {
            $to   = $from->sub(Sidef::Types::Number::Number::ONE);
            $from = Sidef::Types::Number::Number::ZERO;
        }

        bless {
               from => $from,
               to   => $to,
               step => $step // Sidef::Types::Number::Number::ONE,
              },
          __PACKAGE__;
    }

    *call = \&new;

    sub iter {
        my ($self) = @_;

        my $step = $self->{step};
        my $from = $self->{from};
        my $to   = $self->{to};

        my $asc = ($self->{_asc} //= !!($step->is_pos));
        my $i = $from;

        my $tmp;
        my $times = ($self->{_times} //= $to->sub($from)->add($step)->div($step));

        if (ref($times) eq 'Sidef::Types::Number::Number') {
            my $repetitions = Sidef::Types::Number::Number::__numify__($$times);

            # An infinite number of repetitions
            if ($repetitions == 'inf') {
                return Sidef::Types::Block::Block->new(
                    code => sub {
                        $tmp = $i;
                        $i   = $i->add($step);
                        $tmp;
                    },
                );
            }

            if ($repetitions <= Sidef::Types::Number::Number::ULONG_MAX) {

                if ($repetitions < 0) {
                    return Sidef::Types::Block::Block->new(code => sub { undef; });
                }

                return Sidef::Types::Block::Block->new(
                    code => sub {
                        --$repetitions >= 0 or return undef;
                        $tmp = $i;
                        $i   = $i->add($step);
                        $tmp;
                    },
                );
            }
        }

        Sidef::Types::Block::Block->new(
            code => sub {
                ($asc ? $i->le($to) : $i->ge($to)) || return undef;
                $tmp = $i;
                $i   = $i->add($step);
                $tmp;
            },
        );
    }

    sub sum_by {
        my ($self, $arg) = @_;
        my $sum = Sidef::Types::Number::Number::ZERO;

        my $iter = $self->iter->{code};
        while (1) {
            $sum = $sum->add($arg->run($iter->() // last));
        }

        $sum;
    }

    sub sum {
        my ($self, $arg) = @_;

        if (ref($arg) eq 'Sidef::Types::Block::Block') {
            goto \&sum_by;
        }

        if ($self->{step}->is_one) {
            $self->{_asc} //= 1;
            state $two = Sidef::Types::Number::Number->_set_uint(2);
            my ($from, $to) = @{$self}{'from', 'to'};
            my $sum = ($from->add($to))->mul($to->sub($from)->add(Sidef::Types::Number::Number::ONE))->div($two);
            return ($sum->is_neg ? ($arg // Sidef::Types::Number::Number::ZERO) : defined($arg) ? $sum->add($arg) : $sum);
        }

        my $sum = $arg // Sidef::Types::Number::Number::ZERO;

        my $iter = $self->iter->{code};
        while (1) {
            $sum = $sum->add($iter->() // last);
        }

        $sum;
    }

    sub prod_by {
        my ($self, $arg) = @_;

        my $prod = Sidef::Types::Number::Number::ONE;

        my $iter = $self->iter->{code};
        while (1) {
            $prod = $prod->mul($arg->run($iter->() // last));
        }

        $prod;
    }

    sub prod {
        my ($self, $arg) = @_;

        if (ref($arg) eq 'Sidef::Types::Block::Block') {
            goto \&prod_by;
        }

        if (    $self->{step}->is_one
            and $self->{from}->is_one
            and $self->{to}->is_pos) {
            $self->{_asc} //= 1;
            my $prod = $self->{to}->factorial;
            return (defined($arg) ? $prod->mul($arg) : $prod);
        }

        my $prod = $arg // Sidef::Types::Number::Number::ONE;

        my $iter = $self->iter->{code};
        while (1) {
            $prod = $prod->mul($iter->() // last);
        }

        $prod;
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new("$self");
    }
}

1;
