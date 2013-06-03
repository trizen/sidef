
use 5.014;
use strict;
use warnings;

package Sidef::Types::Nil::Nil {

    use parent qw(Sidef Sidef::Convert::Convert);

    sub new {
        my $class = shift;
        $class = ref($class) if ref($class);
        bless \(my $nil = 'nil'), $class;
    }

    sub dump {
        Sidef::Types::String::String->new('nil');
    }

}

1;
