
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

    sub keys {
        my ($hash_ref) = @_;
        return Sidef::Types::Array::Array->new(keys %{$hash_ref});
    }

    sub values {
        my ($hash_ref) = @_;
        return Sidef::Types::Array::Array->new(values %{$hash_ref});
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
};

1;
