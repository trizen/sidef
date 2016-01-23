package Sidef::Types::Range::RangeNumber {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use overload
      '@{}' => \&to_a,
      q{""} => \&dump;

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

    my $ONE  = ${(Sidef::Types::Number::Number::ONE)};
    my $ZERO = ${(Sidef::Types::Number::Number::ZERO)};
    my $MONE = ${(Sidef::Types::Number::Number::MONE)};

    sub new {
        my (undef, $from, $to, $step) = @_;

        if (defined $to) {
            Sidef::Types::Number::Number::_valid($from, $to, defined($step) ? $step : ());
            $from = ref($from) ? $$from : $from;
            $to   = ref($to)   ? $$to   : $to;
            $step = ref($step) ? $$step : defined($step) ? $step : $ONE;
        }
        elsif (defined $from) {
            Sidef::Types::Number::Number::_valid($from);
            $to   = ref($from) ? $$from : $from;
            $from = $ZERO;
            $step = $ONE;
        }
        else {
            ($from, $to, $step) = ($ZERO, $MONE, $ONE);
        }

        bless {
               from => $from,
               to   => $to,
               step => $step,
              },
          __PACKAGE__;
    }

    *call = \&new;

    sub __new__ {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub by {
        my ($self, $step) = @_;
        Sidef::Types::Number::Number::_valid($step);
        $self->{step} = Math::GMPq::Rmpq_sgn($self->{step}) < 0 ? -$$step : $$step;
        $self;
    }

    sub reverse {
        my ($self) = @_;

        $self->{step} = -$self->{step};
        ($self->{from}, $self->{to}) = ($self->{to}, $self->{from});

        $self;
    }

    sub min {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(Math::GMPq::Rmpq_sgn($self->{step}) > 0 ? $self->{from} : $self->{to});
    }

    sub max {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(Math::GMPq::Rmpq_sgn($self->{step}) > 0 ? $self->{to} : $self->{from});
    }

    sub step {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($self->{step});
    }

    sub bounds {
        my ($self) = @_;
        ($self->min, $self->max);
    }

    sub contains {
        my ($self, $num) = @_;

        Sidef::Types::Number::Number::_valid($num);

        my $value = $$num;
        my ($min, $max) =
          (Math::GMPq::Rmpq_sgn($self->{step}) > 0 ? ($self->{from}, $self->{to}) : ($self->{to}, $self->{from}));
        my $step = $self->{step};

        (
         $value >= $min and $value <= $max
           and (
                  Math::GMPq::Rmpq_equal($step, $ONE) ? 1
                : Math::GMPq::Rmpq_sgn($step) > 0 ? (int(($value - $min) / $step) * $step == ($value - $min))
                :                                   (int(($value - $max) / $step) * $step == ($value - $max))
               )
        ) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *contain  = \&contains;
    *include  = \&contains;
    *includes = \&contains;

    sub _new_iter {
        my ($self) = @_;

        my $step = $self->{step};
        my $from = $self->{from};
        my $to   = $self->{to};

        my $sgn = Math::GMPq::Rmpq_sgn($step);

        my $i = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set($i, $from);

        sub {
            ($sgn > 0 ? Math::GMPq::Rmpq_cmp($i, $to) <= 0 : Math::GMPq::Rmpq_cmp($i, $to) >= 0) || return;
            my $tmp = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set($tmp, $i);
            Math::GMPq::Rmpq_add($i, $i, $step);
            bless \$tmp, 'Sidef::Types::Number::Number';
        };
    }

    sub each {
        my ($self, $code) = @_;

        my $iter = $self->_new_iter();
        while (defined(my $num = $iter->())) {
            if (defined(my $res = $code->_run_code($num))) {
                return $res;
            }
        }
    }

    *for     = \&each;
    *foreach = \&each;

    sub map {
        my ($self, $code) = @_;

        my $values = Sidef::Types::Array::Array->new;
        my $iter   = $self->_new_iter();
        while (defined(my $num = $iter->())) {
            push @$values, $code->run($num);
        }

        $values;
    }

    *collect = \&map;

    sub grep {
        my ($self, $code) = @_;

        my $values = Sidef::Types::Array::Array->new;
        my $iter   = $self->_new_iter();
        while (defined(my $num = $iter->())) {
            push(@$values, $num) if $code->run($num);
        }

        $values;
    }

    *filter = \&grep;
    *select = \&grep;

    sub reduce {
        my ($self, $code) = @_;

        my $iter  = $self->_new_iter();
        my $value = $iter->();

        while (defined(my $num = $iter->())) {
            $value = $code->run($value, $num);
        }

        $value;
    }

    sub all {
        my ($self, $code) = @_;

        my $iter = $self->_new_iter();
        while (defined(my $num = $iter->())) {
            $code->run($num)
              || return Sidef::Types::Bool::Bool::FALSE;
        }

        Sidef::Types::Bool::Bool::TRUE;
    }

    sub any {
        my ($self, $code) = @_;

        my $iter = $self->_new_iter();
        while (defined(my $num = $iter->())) {
            $code->run($num)
              && return Sidef::Types::Bool::Bool::TRUE;
        }

        Sidef::Types::Bool::Bool::FALSE;
    }

    our $AUTOLOAD;
    sub DESTROY { }

    sub to_array {
        my ($self) = @_;
        local $AUTOLOAD;
        $self->AUTOLOAD();
    }

    *to_a = \&to_array;

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($name) = (defined($AUTOLOAD) ? ($AUTOLOAD =~ /^.*[^:]::(.*)$/) : '');

        my $array = Sidef::Types::Array::Array->new;
        my $iter  = $self->_new_iter();
        while (defined(my $num = $iter->())) {
            push @$array, $num;
        }

        $name eq '' ? $array : $array->$name(@args);
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '=='} = sub {
            my ($r1, $r2) = @_;
            (ref($r1) eq ref($r2) and $r1->{from} == $r2->{from} and $r1->{to} == $r2->{to} and $r1->{step} == $r2->{step})
              ? (Sidef::Types::Bool::Bool::TRUE)
              : (Sidef::Types::Bool::Bool::FALSE);
        };
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new("RangeNum($self->{from}, $self->{to}, $self->{step})");
    }

}

1;
