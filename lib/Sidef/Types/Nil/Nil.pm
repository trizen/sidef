
use 5.014;
use strict;
use warnings;

package Sidef::Types::Nil::Nil {

    use parent qw(Sidef::Convert::Convert Sidef::Types::String::String);

    sub new {
        my $class = shift;
        bless \(my $nil = 'nil'), $class;
    }

    sub dump {
        Sidef::Types::String::String->new('nil');
    }

}

1;
