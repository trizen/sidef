
use 5.014;
use strict;
use warnings;

package Sidef::Types::Block::Given {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub given {
        my ($self, $expr) = @_;
        Sidef::Types::Block::Switch->new($expr);
    }

};

1;
