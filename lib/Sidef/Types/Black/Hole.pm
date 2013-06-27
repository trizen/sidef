
use 5.014;
use strict;
use warnings;

package Sidef::Types::Black::Hole {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub DESTROY {
        return;
    }

    sub AUTOLOAD {
        return __PACKAGE__->new();
    }
};

1;
