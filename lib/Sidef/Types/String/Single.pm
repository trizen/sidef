
use 5.014;
use strict;
use warnings;

package Sidef::Types::String::Single {

    use parent qw(Sidef::Convert::Convert);

sub new{
    my($class, $str) = @_;
    bless \$str, $class;
}

}

1;
