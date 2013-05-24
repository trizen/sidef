
use 5.014;
use strict;
use warnings;

package Sidef::Types::Array::Array {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my ($class, @items) = @_;
        bless \@items, $class;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '-'} = sub {

            my ($self, $array) = @_;
            my $new_array = __PACKAGE__->new();

            foreach my $item (@{$self}) {

                my $exists = 0;
                foreach my $min_item (@{$array}) {
                    if ($min_item->get_value eq $item->get_value) {
                        $exists = 1;
                        last;
                    }
                }

                $new_array->push($item) if not $exists;
            }

            return $new_array;
        };

        *{__PACKAGE__ . '::' . '+'} = sub {
            my ($self, $array) = @_;
            __PACKAGE__->new(@{$self}, @{$array});
        };

        *{__PACKAGE__ . '::' . '='} = sub {
            my ($self, $arg) = @_;

            if (ref $arg eq 'Sidef::Types::Array::Array') {
                foreach my $i (0 .. $#{$self}) {
                    $self->[$i]->set_value($arg->[$i]);
                }
            }
            else {
                map { $_->set_value($arg) } @{$self};
            }

            $self;
        };
    }

    sub len {
        my ($self) = @_;
        Sidef::Types::Number::Integer->new(scalar @{$self});
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
        push @{$self}, @args;
        return $self;
    }

    sub join {
        my ($self, $separator) = @_;
        Sidef::Types::String::String->new(CORE::join($$separator, @{$self}));
    }

    sub reverse {
        my ($self, $separator) = @_;
        __PACKAGE__->new(reverse @{$self});
    }

}

1;
