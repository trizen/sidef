package Sidef::Types::Range::RangeNumber {

    use 5.014;

    use parent qw(
      Sidef::Types::Range::Range
      Sidef::Object::Object
      );

    use overload q{""} => \&dump;

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

    my $ONE  = Sidef::Types::Number::Number::ONE;
    my $ZERO = Sidef::Types::Number::Number::ZERO;
    my $MONE = Sidef::Types::Number::Number::MONE;

    sub new {
        my (undef, $from, $to, $step) = @_;

        if (not defined $from) {
            $from = $ZERO;
            $to   = $MONE;
        }

        if (not defined $to) {
            $to   = $from->sub($ONE);
            $from = $ZERO;
        }

        bless {
               from => $from,
               to   => $to,
               step => $step // $ONE,
              },
          __PACKAGE__;
    }

    *call = \&new;

    sub iter {
        my ($self) = @_;

        my $step = $self->{step};
        my $from = $self->{from};
        my $to   = $self->{to};

        my $asc = !!($step->is_pos);
        my $i   = $from;

        Sidef::Types::Block::Block->new(
            code => sub {
                ($asc ? $i->le($to) : $i->ge($to)) || return;
                my $value = $i;
                $i = $i->add($step);
                $value;
            },
        );
    }

    sub sum {
        my ($self, $arg) = @_;
        my $sum = $arg // $ZERO;

        my $iter = $self->iter->{code};
        while (defined(my $num = $iter->())) {
            $sum = $sum->add($num);
        }

        $sum;
    }

    sub prod {
        my ($self, $arg) = @_;
        my $prod = $arg // $ONE;

        my $iter = $self->iter->{code};
        while (defined(my $num = $iter->())) {
            $prod = $prod->mul($num);
        }

        $prod;
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new("RangeNum($self->{from}, $self->{to}, $self->{step})");
    }
}

1;
