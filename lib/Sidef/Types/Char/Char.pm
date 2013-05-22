
use 5.014;
use strict;
use warnings;

package Sidef::Types::Char::Char {

    use parent qw(Sidef::Convert::Convert Sidef::Types::String::String);

    sub new {
        my ($class, $char) = @_;
        bless \$char, $class;
    }

}

1;
