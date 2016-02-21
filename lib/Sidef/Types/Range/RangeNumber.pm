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

    use Sidef::Types::Number::Inf;
    use Sidef::Types::Number::Ninf;

    my $INF  = ${Sidef::Types::Number::Inf->new};
    my $NINF = ${Sidef::Types::Number::Ninf->new};

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
        __PACKAGE__->__new__(
                             from => $self->{from},
                             to   => $self->{to},
                             step => (Math::GMPq::Rmpq_sgn($self->{step}) < 0 ? -$$step : $$step),
                            );
    }

    sub from {
        my ($self, $from) = @_;
        Sidef::Types::Number::Number::_valid($from);
        __PACKAGE__->__new__(
                             from => $$from,
                             to   => $self->{to},
                             step => $self->{step},
                            );
    }

    sub to {
        my ($self, $to) = @_;
        Sidef::Types::Number::Number::_valid($to);
        __PACKAGE__->__new__(
                             from => $self->{from},
                             to   => $$to,
                             step => $self->{step},
                            );
    }

    sub reverse {
        my ($self) = @_;

        if (Math::GMPq::Rmpq_equal($self->{to}, $INF) or Math::GMPq::Rmpq_equal($self->{to}, $NINF)) {
            die "[ERROR] Can't reverse an infinite range: $self";
        }

        __PACKAGE__->__new__(
                             from => $self->{to},
                             to   => $self->{from},
                             step => -$self->{step},
                            );
    }

    sub min {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(
            Math::GMPq::Rmpq_sgn($self->{step}) > 0 ? $self->{from} : do {
                    Math::GMPq::Rmpq_equal($self->{to}, $INF) ? (return Sidef::Types::Number::Inf->new)
                  : Math::GMPq::Rmpq_equal($self->{to}, $NINF) ? (return Sidef::Types::Number::Ninf->new)
                  :                                              $self->{to};
              }
        );
    }

    sub max {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(
            Math::GMPq::Rmpq_sgn($self->{step}) > 0
            ? do {
                    Math::GMPq::Rmpq_equal($self->{to}, $INF) ? (return Sidef::Types::Number::Inf->new)
                  : Math::GMPq::Rmpq_equal($self->{to}, $NINF) ? (return Sidef::Types::Number::Ninf->new)
                  :                                              $self->{to};
              }
            : $self->{from}
        );
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
        my $step  = $self->{step};
        my $sgn   = Math::GMPq::Rmpq_sgn($step);

        if (Math::GMPq::Rmpq_equal($self->{to}, $INF)) {
            ($sgn < 0 ? $value <= $self->{from} : $value >= $self->{from}) or return (Sidef::Types::Bool::Bool::FALSE);
            Math::GMPq::Rmpq_equal($step, $ONE) and return (Sidef::Types::Bool::Bool::TRUE);
            return $num->add(bless \$self->{from}, 'Sidef::Types::Number::Number')
              ->mod(bless(\$step, 'Sidef::Types::Number::Number'))->is_zero;
        }
        elsif (Math::GMPq::Rmpq_equal($self->{to}, $NINF)) {
            ($sgn < 0 ? $value <= $self->{from} : $value >= $self->{from}) or return (Sidef::Types::Bool::Bool::FALSE);
            Math::GMPq::Rmpq_equal($step, $ONE) and return (Sidef::Types::Bool::Bool::TRUE);
            return $num->sub(bless \$self->{from}, 'Sidef::Types::Number::Number')
              ->mod(bless(\$step, 'Sidef::Types::Number::Number'))->is_zero;
        }

        my ($from, $to) = (
                           $sgn > 0
                           ? ($self->{from}, $self->{to})
                           : ($self->{to}, $self->{from})
                          );

        (
         $value >= $from and $value <= $to
           and (
                  Math::GMPq::Rmpq_equal($step, $ONE) ? 1
                : $sgn > 0 ? (int(($value - $from) / $step) * $step == ($value - $from))
                :            (int(($value - $to) / $step) * $step ==   ($value - $to))
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

        my $is_inf  = Math::GMPq::Rmpq_equal($to, $INF);
        my $is_ninf = Math::GMPq::Rmpq_equal($to, $NINF);

        sub {
            (
             $sgn > 0
             ? ($is_inf ? 1 : $is_ninf ? 0 : Math::GMPq::Rmpq_cmp($i, $to) <= 0)
             : ($is_inf ? 0 : $is_ninf ? 1 : Math::GMPq::Rmpq_cmp($i, $to) >= 0)
            )
              || return;
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
