
use 5.014;
use strict;
use warnings;

package Sidef::Types::Char::Char {

    use parent qw(Sidef::Convert::Convert Sidef::Types::String::String);

    sub new {
        my (undef, $char) = @_;
        $char = $$char if ref $char;
        bless \$char, __PACKAGE__;
    }

}

1;
