
use 5.014;
use strict;
use warnings;

package Sidef::Types::String::String {

    use parent qw(
        Sidef::Convert::Convert
    );

    require Sidef::Types::Array::Array;

    sub new{
        my ($class, $hash_ref) = @_;
        bless $hash_ref, $class;
    }

    sub keys {
        return Sidef::Types::Array::Array->new([keys %{$hash_ref}]);
    }

    sub values {
        return Sidef::Types::Array::Array->new([values %{$hash_ref}]);
    }
};

1;
