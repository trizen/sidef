use 5.014;
use strict;
use warnings;

package Sidef::Types::Number::Float {

     use parent qw(Sidef::Convert::Convert);

     sub new{
        my($class, $regex, $mod) = @_;

        $mod //= q{^};
        my $qre = qr{(?$mod:$regex)};

        bless $qre, $class;
    }

}

1;
