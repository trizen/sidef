package Sidef::Types::Range::RangeNumber {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use overload '@{}' => \&to_a;

    sub new {
        my (undef, $from, $to, $step) = @_;

        if (defined $to) {
            $from = ref($from) ? $from->get_value : $from;
            $to   = ref($to)   ? $to->get_value   : $to;
            $step = ref($step) ? $step->get_value : defined($step) ? $step : 1;
        }
        elsif (defined $from) {
            $to   = ref($from) ? $from->get_value : $from;
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
        ($self->min, $self->max);
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

        if ($step == 1 and $limit < (-1 >> 1) and $from < (-1 >> 1)) {

            # Unpack limit
            if (ref($from)) {
                $self->{from} = $from = $from->numify;
                $self->{step} = 1;
            }
            if (ref($limit)) {
                $self->{step} = 1;
                $self->{to} = $limit = $limit->numify;
            }

            foreach my $i ($from .. $limit) {
                if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }
        }
        elsif ($step > 0) {
            if (ref($from) || ref($limit) || ref($step)) {

                $from  = Math::BigFloat->new($from)  if not ref($from);
                $limit = Math::BigFloat->new($limit) if not ref($limit);
                $step  = Math::BigFloat->new($step)  if not ref($step);

                for (my $i = $from->copy ; $i->bcmp($limit) <= 0 ; $i->badd($step)) {
                    if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i->copy)))) {
                        return $res;
                    }
                }
            }
            else {
                for (my $i = $from ; $i <= $limit ; $i += $step) {
                    if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i)))) {
                        return $res;
                    }
                }
            }
        }
        else {
            if (ref($from) || ref($limit) || ref($step)) {

                $from  = Math::BigFloat->new($from)  if not ref($from);
                $limit = Math::BigFloat->new($limit) if not ref($limit);
                $step  = Math::BigFloat->new($step)  if not ref($step);

                for (my $i = $from->copy ; $i->bcmp($limit) >= 0 ; $i->badd($step)) {
                    if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i->copy)))) {
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
        }

        $self;
    }

    sub map {
        my ($self, $code) = @_;

        my $step  = $self->{step};
        my $from  = $self->{from};
        my $limit = $self->{to};

        my @values;
        if ($step == 1 and $limit < (-1 >> 1) and $from < (-1 >> 1)) {

            # Unpack limit
            if (ref($from)) {
                $self->{from} = $from = $from->numify;
                $self->{step} = 1;
            }
            if (ref($limit)) {
                $self->{step} = 1;
                $self->{to} = $limit = $limit->numify;
            }

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

    sub grep {
        my ($self, $code) = @_;

        my $step  = $self->{step};
        my $from  = $self->{from};
        my $limit = $self->{to};

        my @values;
        if ($step == 1 and $limit < (-1 >> 1) and $from < (-1 >> 1)) {

            # Unpack limit
            if (ref($from)) {
                $self->{from} = $from = $from->numify;
                $self->{step} = 1;
            }
            if (ref($limit)) {
                $self->{step} = 1;
                $self->{to} = $limit = $limit->numify;
            }

            foreach my $i ($from .. $limit) {
                my $num = Sidef::Types::Number::Number->new($i);
                push(@values, $num) if $code->run($num);
            }
        }

        elsif ($step > 0) {
            for (my $i = $from ; $i <= $limit ; $i += $step) {
                my $num = Sidef::Types::Number::Number->new($i);
                push(@values, $num) if $code->run($num);
            }
        }
        else {
            for (my $i = $from ; $i >= $limit ; $i += $step) {
                my $num = Sidef::Types::Number::Number->new($i);
                push(@values, $num) if $code->run($num);
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

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '=='} = sub {
            my ($r1, $r2) = @_;
            Sidef::Types::Bool::Bool->new(    ref($r1) eq ref($r2)
                                          and $r1->{from} == $r2->{from}
                                          and $r1->{to} == $r2->{to}
                                          and $r1->{step} == $r2->{step});
        };
    }

}

1;
