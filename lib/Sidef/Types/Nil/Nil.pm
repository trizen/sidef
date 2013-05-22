
use 5.014;
use strict;
use warnings;

package Sidef::Types::Nil::Nil {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my $class = shift;
        bless \(my $nil = undef), $class;
    }

}

1;
