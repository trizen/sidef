
use 5.014;
use strict;
use warnings;

package Sidef::Types::Byte::Byte {

    use parent qw(Sidef::Convert::Convert Sidef::Types::Number::Number);

    sub new {
        my ($class, $byte) = @_;
        $byte  = $$byte      if ref $byte;
        $class = ref($class) if ref($class);
        bless \$byte, $class;
    }

}

1;
