
use 5.014;
use strict;
use warnings;

package Sidef::Types::Number::Integer {

     use parent qw(Sidef::Types::Number::Number);


    sub new {
        my $class = shift;
        my $int   = CORE::int shift;
        bless \$int, $class;
    }

}

1;
