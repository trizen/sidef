
use 5.014;
use strict;
use warnings;

package Sidef::Types::Char::Chars {

    use parent qw(Sidef::Convert::Convert Sidef::Types::Array::Array);

    sub new {
        my ($class, @chars) = @_;
        $class = ref($class) if ref($class);
        bless [@{Sidef::Types::Array::Array->new(@chars)}], $class;
    }

}

1;
