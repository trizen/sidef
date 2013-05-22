
use 5.014;
use strict;
use warnings;

package Sidef::Types::Chars::Chars {

    use parent qw(Sidef::Convert::Convert Sidef::Types::Array::Array);

    sub new {
        my ($class, @chars) = @_;
        bless \@chars, $class;
    }

}

1;
