package Sidef::Types::Array::RangeNumber {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub by {
        my ($self, $step) = @_;
        $self->{step} = $self->{step} < 0 ? -$step->get_value : $step->get_value;
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
        Sidef::Types::Array::List->new($self->min, $self->max);
    }

    sub contains {
        my ($self, $num) = @_;

        my $value = $num->get_value;
        my ($min, $max) = map { $_->get_value } ($self->min, $self->max);
        my $step = $self->{step};

        Sidef::Types::Bool::Bool->new(
                                      $value >= $min and $value <= $max
                                        and (
                                               $step == 1 ? 1
                                             : $step > 0 ? (int(($value - $min) / $step) * $step == ($value - $min))
                                             :             (int(($value - $max) / $step) * $step == ($value - $max))
                                            )
                                     );
    }

    *includes = \&contains;

    sub each {
        my ($self, $code) = @_;

        my $step  = $self->{step};
        my $from  = $self->{from};
        my $limit = $self->{to};

        if ($step == 1 and not $limit > (-1 >> 1) and not $from > (-1 >> 1)) {

            # Unpack limit
            $limit = $limit->bstr if ref($limit);

            foreach my $i ($from .. $limit) {
                if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }

        }

        elsif ($step > 0) {
            for (my $i = $from ; $i <= $limit ; $i += $step) {
                if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }
        }
        else {
            for (my $i = $from ; $i >= $limit ; $i += $step) {
                if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }
        }

        $self;
    }

    *bcall = \&each;

    sub map {
        my ($self, $code) = @_;

        my $step  = $self->{step};
        my $from  = $self->{from};
        my $limit = $self->{to};

        my @values;
        if ($step == 1 and not $limit > (-1 >> 1) and not $from > (-1 >> 1)) {

            # Unpack limit
            $limit = $limit->bstr if ref($limit);

            foreach my $i ($from .. $limit) {
                push @values, $code->run(Sidef::Types::Number::Number->new($i));
            }
        }

        elsif ($step > 0) {
            for (my $i = $from ; $i <= $limit ; $i += $step) {
                push @values, $code->run(Sidef::Types::Number::Number->new($i));
            }
        }
        else {
            for (my $i = $from ; $i >= $limit ; $i += $step) {
                push @values, $code->run(Sidef::Types::Number::Number->new($i));
            }
        }

        Sidef::Types::Array::Array->new(@values);
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

}

1;
