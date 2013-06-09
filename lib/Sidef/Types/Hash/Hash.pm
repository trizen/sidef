
use 5.014;
use strict;
use warnings;

package Sidef::Types::Hash::Hash {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my ($class, %hash) = @_;
        $class = ref($class) if ref($class);
        bless \%hash, $class;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '+'} = sub {
            my ($self, $hash) = @_;
            $self->_is_hash($hash) || return $self;
            $self->new(%{$self}, %{$hash});
        };
    }

    sub keys {
        my ($hash_ref) = @_;
        Sidef::Types::Array::Array->new(keys %{$hash_ref});
    }

    sub values {
        my ($hash_ref) = @_;
        Sidef::Types::Array::Array->new(values %{$hash_ref});
    }

    sub map {
        my ($self, $keys, $struct) = @_;

        for (my $i = 0 ; $i <= $#{$struct} ; $i += 2) {
            my ($key, $value) = @{$struct}[$i, $i + 1];

            $self->{$key} //= $self->new();
            foreach my $i (0 .. $#{$keys}) {
                $self->{$key}{$keys->[$i]} = $value->get_value->[$i];
            }
        }

        return $self;
    }

    sub flip {
        my ($self) = @_;

        my $new_hash = $self->new();
        @{$new_hash}{CORE::values %{$self}} =
          (map { Sidef::Types::String::String->new($_) } CORE::keys %{$self});
        $new_hash;
    }
};

1;
