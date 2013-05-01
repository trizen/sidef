
use 5.014;
use strict;
use warnings;

package Sidef::Types::Array::Array {

    sub new {
        my ($class) = @_;
        bless [], $class;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '-'} = sub {
            my ($array_1, $array_2) = @_;

            use overload q{""} => sub { ${$_[0]} };
            __PACKAGE__->new([grep { not $_ ~~ $array_2 } @{$array_1}]);
        };
    }

    sub pop {
        my ($self) = @_;
        pop @{$self};
    }
}

1;
