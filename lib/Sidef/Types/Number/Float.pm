
use 5.014;
use strict;
use warnings;

package Sidef::Types::Number::Float {

     use parent qw(Sidef::Types::Number::Number);


     sub new {
        my ($class, $float) = @_;
        bless \$float, $class;
    }

}

1;
