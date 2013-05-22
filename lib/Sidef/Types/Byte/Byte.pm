
use 5.014;
use strict;
use warnings;

package Sidef::Types::Byte::Byte {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my($class, $byte) = @_;
        bless \$byte, $class;
    }

    sub chr {
        my($self) = @_;
        return Sidef::Types::String::String->new(chr $$self);
    }

}

1;
