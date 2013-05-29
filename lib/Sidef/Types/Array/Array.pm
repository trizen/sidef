
use 5.014;
use strict;
use warnings;

package Sidef::Types::Array::Array {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my ($class, @items) = @_;
        bless [map { Sidef::Variable::Variable->new(rand, 'var', $_) } @items], $class;
    }

    sub _get_array { [@{$_[0]}] }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '-'} = sub {

            my ($self, $array) = @_;
            my $new_array = __PACKAGE__->new();

            foreach my $item (@{$self}) {

                my $exists = 0;
                foreach my $min_item (@{$array->_get_array}) {
                    if ($min_item->get_value eq $item->get_value) {
                        $exists = 1;
                        last;
                    }
                }

                $new_array->push($item->get_value) if not $exists;
            }

            return $new_array;
        };

        *{__PACKAGE__ . '::' . '+'} = sub {
            my ($self, $array) = @_;
            __PACKAGE__->new(map { $_->get_value } @{$self}, @{$array->_get_array});
        };

        *{__PACKAGE__ . '::' . '++'} = sub {
            my ($self, $obj) = @_;
            $self->push(ref $obj ? $obj : Sidef::Types::Nil::Nil->new());
            $self;
        };

        *{__PACKAGE__ . '::' . '--'} = sub {
            my ($self) = @_;
            $self->pop;
            $self;
        };

        *{__PACKAGE__ . '::' . '=='} = sub {
            my ($self, $array) = @_;

            if ($#{$self} != $#{$array->_get_array}) {
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

    sub max {
        my ($self) = @_;

        my $method   = '>';
        my $max_item = $self->[0]->get_value;

        foreach my $i (1 .. $#{$self}) {
            my $val = $self->[$i]->get_value;

            if (defined $val->can($method)) {
                $max_item = $val if $val->$method($max_item);
            }
            else {
                warn "[WARN] Can't find the method '$method' for object '", ref($self->[$i]->get_value), "'!\n";
            }
        }

        return $max_item;
    }

    sub map {
        my ($self, $code) = @_;

        my $exec = Sidef::Exec->new();
        my $variable = $exec->execute_expr(expr => $code->{main}[0], class => 'main');

        __PACKAGE__->new(
            map {
                $variable->alias($_);
                my $val = $_->get_value;
                $variable->set_value(ref $val eq 'Sidef::Variable::Variable' ? $val->get_value : $val);
                my @results = $exec->execute(struct => $code);
                $results[-1];
              } @{$self}
        );
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Integer->new(scalar @{$self});
    }

    *len = \&length;    # alias

    sub insert {
        my ($self, $index, @objects) = @_;
        splice(@{$self}, $index->_get_number, 0, @{__PACKAGE__->new(@objects)});
        $self;
    }

    sub pop {
        my ($self) = @_;
        pop @{$self};
    }

    sub shift {
        my ($self) = @_;
        shift @{$self};
    }

    sub push {
        my ($self, @args) = @_;
        push @{$self}, @{__PACKAGE__->new(@args)};
        return $self;
    }

    sub unshift {
        my ($self, @args) = @_;
        unshift @{$self}, @{__PACKAGE__->new(@args)};
        return $self;
    }

    sub join {
        my ($self, $separator) = @_;
        Sidef::Types::String::String->new(CORE::join($separator->_get_string, @{$self}));
    }

    sub reverse {
        my ($self) = @_;
        __PACKAGE__->new(reverse @{$self});
    }

}

1;
