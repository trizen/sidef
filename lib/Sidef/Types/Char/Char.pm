
use 5.014;
use strict;
use warnings;

package Sidef::Types::Char::Char {

    use parent qw(Sidef::Types::String::String Sidef::Convert::Convert);

    sub new {
        my (undef, $char) = @_;
        $char = $$char if ref $char;
        bless \$char, __PACKAGE__;
    }

}

1;
