
use 5.014;
use strict;
use warnings;

package Sidef::Types::Array::Array {

    use parent qw(Sidef Sidef::Convert::Convert);

    sub new {
        my ($class, @items) = @_;
        $class = ref($class) if ref($class);
        bless [map { Sidef::Variable::Variable->new(rand, 'var', $_) } @items], $class;
    }

    sub _grep {
        my ($self, $array, $bool) = @_;
        my $new_array = $self->new();

        $self->_is_array($array) || return ($self);

        foreach my $item (@{$self}) {

            my $exists = 0;
            my $value  = $item->get_value;

            if ($array->contains($value)) {
                $exists = 1;
            }

            $new_array->push($value) if ($exists - $bool);
        }

        $new_array;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '-'} = sub {
            my ($self, $array) = @_;
            $self->_grep($array, 1);
        };

        *{__PACKAGE__ . '::' . '&'} = sub {
            my ($self, $array) = @_;
            $self->_grep($array, 0);
        };

        *{__PACKAGE__ . '::' . '<<'} = sub {
            my ($self, $number) = @_;
            $self->_is_number($number, 1, 0) || return $self->new();
            $number->is_positive()
              || do {
                warn "[WARN] Array's method '<<' requires a positive number!\n";
                return $self->new();
              };
            $self->new(map { $_->get_value } CORE::splice(@{$self}, 0, $$number));
        };

        *{__PACKAGE__ . '::' . '>>'} = sub {
            my ($self, $number) = @_;
            $self->_is_number($number, 1, 0) || return $self->new();
            $number->is_positive()
              || do {
                warn "[WARN] Array's method '>>' requires a positive number!\n";
                return $self->new();
              };
            $self->new(map { $_->get_value } CORE::splice(@{$self}, -$$number));
        };

        *{__PACKAGE__ . '::' . '|'} = sub {
            my ($self, $array) = @_;
            my $new_array = $self->new;

            $self->_is_array($array) || return;

            my $add = '+';
            my $xor = '^';
            my $and = '&';
            $self->$xor($array)->$add($self->$and($array));
        };

        *{__PACKAGE__ . '::' . '^'} = sub {
            my ($self, $array) = @_;
            my $new_array = $self->new;

            $self->_is_array($array) || return;

            my $add    = '+';
            my $and    = '&';
            my $substr = '-';
            ($self->$add($array))->$substr($self->$and($array));
        };

        *{__PACKAGE__ . '::' . '+'} = sub {
            my ($self, $array) = @_;

            $self->_is_array($array) || return ($self);
            __PACKAGE__->new(map { $_->get_value } @{$self}, @{$array});
        };

        *{__PACKAGE__ . '::' . '++'} = sub {
            my ($self, $obj) = @_;
            $self->push($obj);
            $self;
        };

        *{__PACKAGE__ . '::' . '--'} = sub {
            my ($self) = @_;
            $self->pop;
            $self;
        };

        *{__PACKAGE__ . '::' . '&&'} = sub {
            my ($self, $array) = @_;

            $self->_is_array($array) || return ($self);

            my $min = $#{$self} > $#{$array} ? $#{$array} : $#{$self};

            my $new_array = $self->new();
            foreach my $i (0 .. $min) {
                $new_array->push($self->[$i]->get_value, $array->[$i]->get_value);
            }

            if ($#{$self} > $#{$array}) {
                foreach my $i ($min + 1 .. $#{$self}) {
                    $new_array->push($self->[$i]->get_value);
                }
            }
            else {
                foreach my $i ($min + 1 .. $#{$array}) {
                    $new_array->push($array->[$i]->get_value);
                }
            }

            $new_array;
        };

        *{__PACKAGE__ . '::' . '=='} = sub {
            my ($self, $array) = @_;

            $self->_is_array($array) || return ($self);

            if ($#{$self} != $#{$array}) {
                return Sidef::Types::Bool::Bool->false;
            }

            foreach my $i (0 .. $#{$self}) {

                my ($x, $y) = ($self->[$i]->get_value, $array->[$i]->get_value);

                if (ref($x) eq ref($y)) {
                    my $method = '==';

                    if (defined $x->can($method)) {
                        if (not $x->$method($y)) {
                            return Sidef::Types::Bool::Bool->false;
                        }
                    }

                }
                else {
                    return Sidef::Types::Bool::Bool->false;
                }
            }

            return Sidef::Types::Bool::Bool->true;
        };

        *{__PACKAGE__ . '::' . '='} = sub {
            my ($self, $arg) = @_;

            if (ref $arg eq 'Sidef::Types::Array::Array') {
                foreach my $i (0 .. $#{$self}) {
                    $arg->[$i] //= Sidef::Variable::Variable->new(rand, 'var', Sidef::Types::Nil::Nil->new);
                    $self->[$i]->set_value($arg->[$i]->get_value);
                }
            }
            else {
                map { $_->set_value($arg) } @{$self};
            }

            $self;
        };

    }

    sub make {
        my ($self, $size, $type) = @_;
        $self->_is_number($size) || return $self;
        $self->new(($type) x $$size);
    }

    sub _min_max {
        my ($self, $method) = @_;

        $#{$self} >= 0 or return Sidef::Types::Nil::Nil->new();

        my $max_item = $self->[0]->get_value;

        foreach my $i (1 .. $#{$self}) {
            my $val = $self->[$i]->get_value;

            if (defined $val->can($method)) {
                $max_item = $val if $val->$method($max_item);
            }
            else {
                warn sprintf("[WARN] %s():Can't find the method '$method' for object '%s'!\n",
                             $method eq '>' ? 'max' : 'min', ref($val));
            }
        }

        return $max_item;
    }

    sub max {
        $_[0]->_min_max('>');
    }

    sub min {
        $_[0]->_min_max('<');
    }

    sub map {
        my ($self, $code) = @_;

        my $exec = Sidef::Exec->new();
        my $var_ref = $exec->execute_expr(expr => $code->{main}[0], class => 'main');

        $self->new(
            map {
                my $val = $_->get_value;
                $var_ref->get_var->set_value($val);
                my @results = $exec->execute(struct => $code);
                $results[-1];
              } @{$self}
        );
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(scalar @{$self});
    }

    *len = \&length;    # alias

    sub offset {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($#{$self});
    }

    sub range {
        my ($self) = @_;
        $self->new(map { Sidef::Types::Number::Number->new($_) } 0 .. $#{$self});
    }

    sub insert {
        my ($self, $index, @objects) = @_;
        $self->_is_number($index) || return $self;
        splice(@{$self}, $$index, 0, @{__PACKAGE__->new(@objects)});
        $self;
    }

    sub contains {
        my ($self, $obj) = @_;

        foreach my $var (@{$self}) {

            my $item = $var->get_value;
            if (ref($item) eq ref($obj)) {
                my $method = '==';
                if (defined $item->can($method)) {
                    if ($item->$method($obj)) {
                        return Sidef::Types::Bool::Bool->true;
                    }
                }
            }
        }

        Sidef::Types::Bool::Bool->false;
    }

    sub pop {
        my ($self, $index) = @_;

        if (defined $index) {
            if ($self->_is_number($index, 1, 1)) {
                $$index <= $#{$self} or do {
                    warn "[WARN] Array index '$$index' is bigger than array's offset '$#{$self}'!\n";
                    return Sidef::Types::Nil::Nil->new();
                };
            }
            else {
                warn
                  sprintf("[WARN] ARRAY's method 'remove' expected a position number object, not '%s'!\n", ref($index));
                return Sidef::Types::Nil::Nil->new();
            }

            return ((splice(@{$self}, $$index, 1))->get_value);
        }

        (pop @{$self})->get_value;
    }

    sub shift {
        my ($self) = @_;
        (shift @{$self})->get_value;
    }

    sub push {
        my ($self, @args) = @_;
        push @{$self}, @{$self->new(@args)};
        return $self;
    }

    sub unshift {
        my ($self, @args) = @_;
        unshift @{$self}, @{$self->new(@args)};
        return $self;
    }

    sub join {
        my ($self, $separator) = @_;
        $self->_is_string($separator) || return $self;
        Sidef::Types::String::String->new(CORE::join($$separator, @{$self}));
    }

    sub reverse {
        my ($self) = @_;
        $self->new(reverse map { $_->get_value } @{$self});
    }

    sub to_hash {
        my ($self) = @_;
        Sidef::Types::Hash::Hash->new(map { $_->get_value } @{$self});
    }

    sub dump {
        my ($self) = @_;

        my $string = Sidef::Types::String::String->new("[");

        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i]->get_value;

            if (defined $item->can('dump')) {
                $$string .= $item->dump();
            }
            else {
                $$string .= $item;
            }
            $$string .= ", " if $i != $#{$self};
        }

        $$string .= "]";
        $string;
    }

}

1;
