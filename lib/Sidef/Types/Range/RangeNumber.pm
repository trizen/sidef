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

    my $MAX_UINT = ~0;

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
            my $repetitions = Math::GMPq::Rmpq_get_d($$times);

            if ($repetitions <= $MAX_UINT) {

                if ($repetitions < 0) {
                    return Sidef::Types::Block::Block->new(code => sub { });
                }

                return Sidef::Types::Block::Block->new(
                    code => sub {
                        --$repetitions >= 0 or return;
                        $tmp = $i;
                        $i   = $i->add($step);
                        $tmp;
                    },
                );
            }
        }
        elsif (ref($times) eq 'Sidef::Types::Number::Inf') {
            return Sidef::Types::Block::Block->new(
                code => sub {
                    $tmp = $i;
                    $i   = $i->add($step);
                    $tmp;
                },
            );
        }

        Sidef::Types::Block::Block->new(
            code => sub {
                ($asc ? $i->le($to) : $i->ge($to)) || return;
                $tmp = $i;
                $i   = $i->add($step);
                $tmp;
            },
        );
    }

    sub sum {
        my ($self, $arg) = @_;
        my $sum = $arg // Sidef::Types::Number::Number::ZERO;

        my $iter = $self->iter->{code};
        while (defined(my $num = $iter->())) {
            $sum = $sum->add($num);
        }

        $sum;
    }

    sub prod {
        my ($self, $arg) = @_;
        my $prod = $arg // Sidef::Types::Number::Number::ONE;

        my $iter = $self->iter->{code};
        while (defined(my $num = $iter->())) {
            $prod = $prod->mul($num);
        }

        $prod;
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new("$self");
    }
}

1;
