package Sidef::Types::Range::RangeNumber {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use overload '@{}' => \&to_a;

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

    sub new {
        my (undef, $from, $to, $step) = @_;

        if (defined $to) {
            Sidef::Types::Number::Number::_valid($from, $to, defined($step) ? $step : ());
            $from = ref($from) ? $$from : $from;
            $to   = ref($to)   ? $$to   : $to;
            $step = ref($step) ? $$step : defined($step) ? $step : 1;
        }
        elsif (defined $from) {
            Sidef::Types::Number::Number::_valid($from);
            $to   = ref($from) ? $$from : $from;
            $from = 0;
            $step = 1;
        }
        else {
            ($from, $to, $step) = (0, -1, 1);
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
        $self->{step} = $self->{step} < 0 ? -$$step : $$step;
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
        Sidef::Types::Number::Number->new($self->{step} > 0 ? $self->{from} : $self->{to});
    }

    sub max {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($self->{step} > 0 ? $self->{to} : $self->{from});
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
        my ($min, $max) = ($self->{step} > 0 ? ($self->{from}, $self->{to}) : ($self->{to}, $self->{from}));
        my $step = $self->{step};

        (
         $value >= $min and $value <= $max
           and (
                  $step == 1 ? 1
                : $step > 0 ? (int(($value - $min) / $step) * $step == ($value - $min))
                :             (int(($value - $max) / $step) * $step == ($value - $max))
               )
        ) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *contain  = \&contains;
    *include  = \&contains;
    *includes = \&contains;

    sub each {
        my ($self, $code) = @_;

        my $step = $self->{step};
        my $from = $self->{from};
        my $to   = $self->{to};

        if (    $step == 1
            and $to <   (-1 >> 1)
            and $from < (-1 >> 1)
            and (ref($from) ? Math::GMPq::Rmpq_integer_p($from) : 1)
            and (ref($to)   ? Math::GMPq::Rmpq_integer_p($to)   : 1)) {
            foreach my $i ($from .. $to) {
                if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number::_new_int($i)))) {
                    return $res;
                }
            }
        }
        elsif ($step > 0) {
            for (my $i = $from ; $i <= $to ; $i += $step) {
                if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }
        }
        else {
            for (my $i = $from ; $i >= $to ; $i += $step) {
                if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }
        }
    }

    *for     = \&each;
    *foreach = \&each;

    sub map {
        my ($self, $code) = @_;

        my $step = $self->{step};
        my $from = $self->{from};
        my $to   = $self->{to};

        my @values;
        if (    $step == 1
            and $to <   (-1 >> 1)
            and $from < (-1 >> 1)
            and (ref($from) ? Math::GMPq::Rmpq_integer_p($from) : 1)
            and (ref($to)   ? Math::GMPq::Rmpq_integer_p($to)   : 1)) {
            foreach my $i ($from .. $to) {
                push @values, $code->run(Sidef::Types::Number::Number::_new_int($i));
            }
        }
        elsif ($step > 0) {
            for (my $i = $from ; $i <= $to ; $i += $step) {
                push @values, $code->run(Sidef::Types::Number::Number->new($i));
            }
        }
        else {
            for (my $i = $from ; $i >= $to ; $i += $step) {
                push @values, $code->run(Sidef::Types::Number::Number->new($i));
            }
        }

        Sidef::Types::Array::Array->new(@values);
    }

    *collect = \&map;

    sub grep {
        my ($self, $code) = @_;

        my $step = $self->{step};
        my $from = $self->{from};
        my $to   = $self->{to};

        my @values;
        if (    $step == 1
            and $to <   (-1 >> 1)
            and $from < (-1 >> 1)
            and (ref($from) ? Math::GMPq::Rmpq_integer_p($from) : 1)
            and (ref($to)   ? Math::GMPq::Rmpq_integer_p($to)   : 1)) {
            foreach my $i ($from .. $to) {
                my $num = Sidef::Types::Number::Number::_new_int($i);
                push(@values, $num) if $code->run($num);
            }
        }
        elsif ($step > 0) {
            for (my $i = $from ; $i <= $to ; $i += $step) {
                my $num = Sidef::Types::Number::Number->new($i);
                push(@values, $num) if $code->run($num);
            }
        }
        else {
            for (my $i = $from ; $i >= $to ; $i += $step) {
                my $num = Sidef::Types::Number::Number->new($i);
                push(@values, $num) if $code->run($num);
            }
        }

        Sidef::Types::Array::Array->new(@values);
    }

    *filter = \&grep;
    *select = \&grep;

    sub reduce {
        my ($self, $code) = @_;

        my $step = $self->{step};
        my $from = $self->{from};
        my $to   = $self->{to};

        my $value = Sidef::Types::Number::Number->new($from);
        if (    $step == 1
            and $to <   (-1 >> 1)
            and $from < (-1 >> 1)
            and (ref($from) ? Math::GMPq::Rmpq_integer_p($from) : 1)
            and (ref($to)   ? Math::GMPq::Rmpq_integer_p($to)   : 1)) {
            foreach my $i ($from + 1 .. $to) {
                my $num = Sidef::Types::Number::Number::_new_int($i);
                $value = $code->run($value, $num);
            }
        }
        elsif ($step > 0) {
            for (my $i = $from + $step ; $i <= $to ; $i += $step) {
                my $num = Sidef::Types::Number::Number->new($i);
                $value = $code->run($value, $num);
            }
        }
        else {
            for (my $i = $from + $step ; $i >= $to ; $i += $step) {
                my $num = Sidef::Types::Number::Number->new($i);
                $value = $code->run($value, $num);
            }
        }

        $value;
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

        my $array;
        my $method = $self->{step} > 0 ? 'array_to' : 'array_downto';

        my $step = $self->{step};
        my $from = $self->{from};
        my $to   = $self->{to};

        $array = Sidef::Types::Number::Number->new($from)->$method(Sidef::Types::Number::Number->new($to),
                                                         abs($step) != 1 ? Sidef::Types::Number::Number->new(abs($step)) : ());

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

}

1;
