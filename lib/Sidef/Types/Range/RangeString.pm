package Sidef::Types::Range::RangeString {

    use 5.014;

    use parent qw(
      Sidef::Types::Range::Range
      Sidef::Object::Object
      );

    use overload q{""} => \&dump;

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;
    use Sidef::Types::Number::Nan;

    my $ONE  = Sidef::Types::Number::Number::ONE;
    my $ZERO = Sidef::Types::Number::Number::ZERO;
    my $MONE = Sidef::Types::Number::Number::MONE;
    my $NAN  = Sidef::Types::Number::Nan::NAN;

    # This expects numbers
    sub new {
        my (undef, $from, $to, $step) = @_;

        if (not defined $from) {
            $from = $ZERO;
            $to   = $MONE;
        }

        if (not defined $to) {
            $to   = $from;
            $from = Sidef::Types::Number::Number::_new_uint(CORE::ord("a"));
        }

        bless {
               from => $from,
               to   => $to,
               step => $step // $ONE,
              },
          __PACKAGE__;
    }

    # This expects characters
    sub call {
        my (undef, $from, $to, $step) = @_;

        if (defined $from) {
            $from = $from->ord;
        }
        else {
            $from = $ZERO;
        }

        if (defined $to) {
            $to = $to->ord;
        }
        else {
            $to   = $from;
            $from = Sidef::Types::Number::Number::_new_uint(CORE::ord("a"));
        }

        bless {
               from => $from,
               to   => $to,
               step => $step // $ONE,
              },
          __PACKAGE__;
    }

    sub from {
        my ($self, $from) = @_;
        defined($from) ? $self->SUPER::from($from->ord) : $self->{from}->chr;
    }

    sub to {
        my ($self, $to) = @_;
        defined($to) ? $self->SUPER::to($to->ord) : $self->{to}->chr;
    }

    sub min {
        $_[0]->SUPER::min->chr;
    }

    sub max {
        $_[0]->SUPER::max->chr;
    }

    sub contains {
        my ($self, $value) = @_;
        $self->SUPER::contains($value->ord);
    }

    *contain  = \&contains;
    *include  = \&contains;
    *includes = \&contains;

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
                $value->chr;
            },
        );
    }

    sub pick {
        my ($self, $num) = @_;
        $self->SUPER::pick($num)->map_operator('chr');
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(
                           "RangeStr(" . join(', ', $self->{from}->chr->dump, $self->{to}->chr->dump, "$self->{step}",) . ")");
    }
}

1;
