
use 5.014;
use strict;
use warnings;

package Sidef::Types::Char::Chars {

    use parent qw(Sidef::Convert::Convert Sidef::Types::Array::Array);

    sub new {
        my (undef, @chars) = @_;
        bless [@{Sidef::Types::Array::Array->new(@chars)}], __PACKAGE__;
    }

}

1;
