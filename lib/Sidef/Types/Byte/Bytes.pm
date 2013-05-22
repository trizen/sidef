
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bytes::Bytes {

    use parent qw(Sidef::Convert::Convert Sidef::Types::Array::Array);

    sub new {
        my ($class, @bytes) = @_;
        bless \@bytes, $class;
    }

    sub join {
        my ($self) = @_;
        Sidef::Types::String::String->new(join('', map { $_->get_value->chr } @{$self}));
    }

}

1;
