package Sidef::Types::Range::RangeNumber {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use overload '@{}' => sub {
        $_[0]->{_cached_array} //= do {
            my @array;
            my $iter = $_[0]->iter->{code};
            while (defined(my $num = $iter->())) {
                push @array, $num;
            }
            \@array;
        };
      },
      q{""} => \&dump;

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

    sub by {
        my ($self, $step) = @_;
        $self->new($self->{from}, $self->{to}, $self->{step}->is_neg ? $step->neg : $step);
    }

    sub from {
        my ($self, $from) = @_;
        $self->new($from, $self->{to}, $self->{step});
    }

    sub to {
        my ($self, $to) = @_;
        $self->new($self->{from}, $to, $self->{step});
    }

    sub reverse {
        my ($self) = @_;
        $self->new($self->{to}, $self->{from}, $self->{step}->neg);
    }

    *flip = \&reverse;

    sub min {
        my ($self) = @_;

        $self->{step}->is_pos
          ? $self->{from}
          : $self->{to};
    }

    sub max {
        my ($self) = @_;

        $self->{step}->is_pos
          ? $self->{to}
          : $self->{from};
    }

    sub step {
        my ($self) = @_;
        $self->{step};
    }

    sub bounds {
        my ($self) = @_;
        ($self->min, $self->max);
    }

    sub contains {
        my ($self, $value) = @_;

        my $step = $self->{step};
        my $asc  = !!($step->is_pos);

        my ($from, $to) = (
                           $asc
                           ? ($self->{from}, $self->{to})
                           : ($self->{to}, $self->{from})
                          );

        (
         $value->ge($from) and $value->le($to)
           and (
                $step->abs->is_one && $value->is_int ? 1
                : $value->sub(
                                $asc ? $from
                              : $to
                )->div($step)->int->mul($step)->eq(
                                                   $value->sub(
                                                                 $asc ? $from
                                                               : $to
                                                              )
                                                  )
               )
          ) ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
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
                $value;
            },
        );
    }

    sub each {
        my ($self, $code) = @_;

        my $iter = $self->iter->{code};
        while (defined(my $num = $iter->())) {
            $code->run($num);
        }

        $self;
    }

    *for     = \&each;
    *foreach = \&each;

    sub map {
        my ($self, $code) = @_;

        my @values;
        my $iter = $self->iter->{code};
        while (defined(my $num = $iter->())) {
            push @values, $code->run($num);
        }

        Sidef::Types::Array::Array->new(\@values);
    }

    sub grep {
        my ($self, $code) = @_;

        my @values;
        my $iter = $self->iter->{code};
        while (defined(my $num = $iter->())) {
            push(@values, $num) if $code->run($num);
        }

        Sidef::Types::Array::Array->new(\@values);
    }

    *select = \&grep;

    sub all {
        my ($self, $code) = @_;

        my $iter = $self->iter->{code};
        while (defined(my $num = $iter->())) {
            $code->run($num)
              || return Sidef::Types::Bool::Bool::FALSE;
        }

        Sidef::Types::Bool::Bool::TRUE;
    }

    sub any {
        my ($self, $code) = @_;

        my $iter = $self->iter->{code};
        while (defined(my $num = $iter->())) {
            $code->run($num)
              && return Sidef::Types::Bool::Bool::TRUE;
        }

        Sidef::Types::Bool::Bool::FALSE;
    }

    sub to_array {
        my ($self) = @_;

        my @array;
        my $iter = $self->iter->{code};
        while (defined(my $num = $iter->())) {
            push @array, $num;
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    *to_a = \&to_array;

    sub to_list {
        my ($self) = @_;

        my @array;
        my $iter = $self->iter->{code};
        while (defined(my $num = $iter->())) {
            push @array, $num;
        }

        (@array);
    }

    sub add {
        my ($self, $arg) = @_;
        $self->new($self->{from}->add($arg), $self->{to}->add($arg), $self->{step});
    }

    sub sub {
        my ($self, $arg) = @_;
        $self->new($self->{from}->sub($arg), $self->{to}->sub($arg), $self->{step});
    }

    sub mul {
        my ($self, $arg) = @_;
        $self->new($self->{from}->mul($arg), $self->{to}->mul($arg), $self->{step});
    }

    sub div {
        my ($self, $arg) = @_;
        $self->new($self->{from}->div($arg), $self->{to}->div($arg), $self->{step});
    }

    sub length {
        my ($self) = @_;
        my $len = $self->{to}->sub($self->{from})->add($self->{step})->div($self->{step})->int;
        $len->is_neg ? $ZERO : $len;
    }

    *len = \&length;

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

    sub pick {
        my ($self, $n) = @_;

        # Check for "empty" range
        # TODO: replace it with arithmetic
        if (not defined $self->iter->{code}->()) {
            return Sidef::Types::Array::Array->new([]);
        }

        my $from = $self->{from};
        my $to   = $self->{to};
        my $step = $self->{step};

        my $limit = $to->sub($from)->div($step)->inc;

        my @array;
        for (1 .. "$n") {
            push @array, $limit->irand->mul($step)->add($from);
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    sub reduce {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Block::Block') {

            my $iter  = $self->iter->{code};
            my $value = $iter->();

            while (defined(my $num = $iter->())) {
                $value = $obj->run($value, $num);
            }

            return $value;
        }

        $self->reduce_operator("$obj");
    }

    sub reduce_operator {
        my ($self, $op) = @_;

        $op = "$op" if ref($op);

        my $iter  = $self->iter->{code};
        my $value = $iter->();

        while (defined(my $num = $iter->())) {
            $value = $value->$op($num);
        }

        $value;
    }

    sub map_operator {
        my ($self, @args) = @_;
        $self->to_a->map_operator(@args);
    }

    sub pam_operator {
        my ($self, @args) = @_;
        $self->to_a->pam_operator(@args);
    }

    sub unroll_operator {
        my ($self, @args) = @_;
        $self->to_a->unroll_operator(@args);
    }

    sub cross_operator {
        my ($self, @args) = @_;
        $self->to_a->cross_operator(@args);
    }

    sub eq {
        my ($r1, $r2) = @_;

        ref($r1) eq ref($r2)
          && $r1->{from}->eq($r2->{from})
          && $r1->{to}->eq($r2->{to})
          && $r1->{step}->eq($r2->{step})

          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub ne {
        my ($r1, $r2) = @_;
        $r1->eq($r2)
          ? (Sidef::Types::Bool::Bool::FALSE)
          : (Sidef::Types::Bool::Bool::TRUE);
    }

    #~ our $AUTOLOAD;
    #~ sub DESTROY { }

    #~ sub AUTOLOAD {
    #~ my ($self, @args) = @_;

    #~ my ($name) = (defined($AUTOLOAD) ? ($AUTOLOAD =~ /^.*[^:]::(.*)$/) : '');

    #~ my @array;
    #~ my $iter = $self->iter->{code};
    #~ while (defined(my $num = $iter->())) {
    #~ push @array, $num;
    #~ }

    #~ $name eq ''
    #~ ? Sidef::Types::Array::Array->new(\@array)
    #~ : Sidef::Types::Array::Array->new(\@array)->$name(@args);
    #~ }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '...'} = \&to_list;
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new("RangeNum($self->{from}, $self->{to}, $self->{step})");
    }
}

1;
