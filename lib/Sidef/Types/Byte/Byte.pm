
use 5.014;
use strict;
use warnings;

package Sidef::Types::Byte::Byte {

    use parent qw(Sidef::Convert::Convert Sidef::Types::Number::Number);

    sub new {
        my (undef, $byte) = @_;
        $byte = $$byte if ref $byte;
        bless \$byte, __PACKAGE__;
    }

}

1;
