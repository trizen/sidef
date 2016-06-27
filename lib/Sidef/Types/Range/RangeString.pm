package Sidef::Types::Range::RangeString {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use overload '@{}' => sub {
        $_[0]->{_cached_array} //= do {
            my @array;
            my $iter = $_[0]->iter->{code};
            while (defined(my $chr = $iter->())) {
                push @array, $chr;
            }
            \@array;
        };
      },
      q{""} => \&dump;

    use Sidef::Types::Bool::Bool;

    sub new {
        my (undef, $from, $to, $step) = @_;

        if (defined $from) {
            $from = "$from";
            $from = $from eq '' ? -1 : CORE::ord("$from");
        }
        else {
            $from = 0;
        }

        if (defined $to) {
            $to = "$to";
            $to = $to eq '' ? -1 : CORE::ord("$to");
        }
        else {
            $to   = $from;
            $from = ord("a");
        }

        $step = defined($step) ? CORE::int($step) : 1;

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

    sub min {
        my ($self) = @_;
        Sidef::Types::String::String->new(
                                          $self->{step} > 0
                                          ? ($self->{from} < 0 ? '' : CORE::chr($self->{from}))
                                          : ($self->{to} < 0 ? '' : CORE::chr($self->{to}))
                                         );
    }

    sub max {
        my ($self) = @_;
        Sidef::Types::String::String->new(
                                          $self->{step} > 0
                                          ? ($self->{to} < 0 ? '' : CORE::chr($self->{to}))
                                          : ($self->{from} < 0 ? '' : CORE::chr($self->{from}))
                                         );
    }

    sub step {
        my ($self) = @_;
        Sidef::Types::Number::Number::_new_int($self->{step});
    }

    sub bounds {
        my ($self) = @_;
        ($self->min, $self->max);
    }

    sub reverse {
        my ($self) = @_;
        $self->__new__(
                       from => $self->{to},
                       to   => $self->{from},
                       step => -$self->{step},
                      );
    }

    *flip = \&reverse;

    sub contains {
        my ($self, $value) = @_;

        $value = ord("$value");

        my $step = $self->{step};
        my $asc  = $step > 0;

        my ($from, $to) = (
                           $asc
                           ? ($self->{from}, $self->{to})
                           : ($self->{to}, $self->{from})
                          );

        (
         $value >= $from and $value <= $to
           and (
                  CORE::abs($step) == 1 ? 1
                : CORE::int(($value - ($asc ? $from : $to)) / $step) * $step == $value - ($asc ? $from : $to)
               )
          ) ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *contain  = \&contains;
    *include  = \&contains;
    *includes = \&contains;

    sub iter {
        my ($self) = @_;

        my $from = $self->{from};
        my $to   = $self->{to};
        my $step = $self->{step};

        my $i   = $from;
        my $asc = $step > 0;

        Sidef::Types::Block::Block->new(
            code => sub {
                ($asc ? $i <= $to : $i >= $to) || return;
                my $value = $i;
                $i += $step;
                Sidef::Types::String::String->new(CORE::chr($value));
            },
        );
    }

    sub each {
        my ($self, $code) = @_;

        my $iter = $self->iter->{code};
        while (defined(my $chr = $iter->())) {
            $code->run($chr);
        }

        $self;
    }

    *for     = \&each;
    *foreach = \&each;

    sub map {
        my ($self, $code) = @_;

        my @values;
        my $iter = $self->iter->{code};
        while (defined(my $chr = $iter->())) {
            push @values, $code->run($chr);
        }

        Sidef::Types::Array::Array->new(\@values);
    }

    sub grep {
        my ($self, $code) = @_;

        my @values;
        my $iter = $self->iter->{code};
        while (defined(my $chr = $iter->())) {
            push(@values, $chr) if $code->run($chr);
        }

        Sidef::Types::Array::Array->new(\@values);
    }

    *select = \&grep;

    sub all {
        my ($self, $code) = @_;

        my $iter = $self->iter->{code};
        while (defined(my $chr = $iter->())) {
            $code->run($chr)
              || return Sidef::Types::Bool::Bool::FALSE;
        }

        Sidef::Types::Bool::Bool::TRUE;
    }

    sub any {
        my ($self, $code) = @_;

        my $iter = $self->iter->{code};
        while (defined(my $chr = $iter->())) {
            $code->run($chr)
              && return Sidef::Types::Bool::Bool::TRUE;
        }

        Sidef::Types::Bool::Bool::FALSE;
    }

    sub length {
        my ($self) = @_;
        my $len = CORE::int(($self->{to} - $self->{from} + $self->{step}) / ($self->{step}));
        $len <= 0
          ? Sidef::Types::Number::Number::ZERO
          : Sidef::Types::Number::Number::_new_uint($len);
    }

    *len = \&length;

    sub to_a {
        my ($self) = @_;

        my @array;
        my $iter = $self->iter->{code};
        while (defined(my $chr = $iter->())) {
            push @array, $chr;
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    *to_array = \&to_a;

    sub to_list {
        my ($self) = @_;

        my @array;
        my $iter = $self->iter->{code};
        while (defined(my $chr = $iter->())) {
            push @array, $chr;
        }

        (@array);
    }

    sub reduce {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Block::Block') {

            my $iter  = $self->iter->{code};
            my $value = $iter->();

            while (defined(my $chr = $iter->())) {
                $value = $obj->run($value, $chr);
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
          && $r1->{from} eq $r2->{from}
          && $r1->{to} eq $r2->{to}
          && $r1->{step} == $r2->{step}

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

    #~ sub to_array {
    #~ my ($self) = @_;
    #~ local $AUTOLOAD;
    #~ $self->AUTOLOAD();
    #~ }

    #~ *to_a = \&to_array;

    #~ sub AUTOLOAD {
    #~ my ($self, @args) = @_;

    #~ my ($name) = (defined($AUTOLOAD) ? ($AUTOLOAD =~ /^.*[^:]::(.*)$/) : '');

    #~ my $array;
    #~ my $method = $self->{asc} ? 'array_to' : 'array_downto';

    #~ $array = Sidef::Types::String::String->new($self->{from})->$method(Sidef::Types::String::String->new($self->{to}));
    #~ $name eq '' ? $array : $array->$name(@args);
    #~ }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '...'} = \&to_list;
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(
                           "RangeStr("
                             . join(', ',
                                    Sidef::Types::String::String->new($self->{from} < 0 ? '' : CORE::chr($self->{from}))->dump,
                                    Sidef::Types::String::String->new($self->{to} < 0   ? '' : CORE::chr($self->{to}))->dump,
                                    $self->{step},
                                   )
                             . ")"
        );
    }
}

1;
