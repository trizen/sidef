
use 5.014;
use strict;
use warnings;

package Sidef::Types::Hash::Hash {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my ( $class, $hash_ref ) = @_;
        bless $hash_ref, $class;
    }

    sub keys {
        my ($hash_ref) = @_;
        return Sidef::Types::Array::Array->new( [ keys %{$hash_ref} ] );
    }

    sub values {
        my ($hash_ref) = @_;
        return Sidef::Types::Array::Array->new( [ values %{$hash_ref} ] );
    }
};

1;
