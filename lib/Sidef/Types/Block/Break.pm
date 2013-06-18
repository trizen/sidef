
use 5.014;
use strict;
use warnings;

package Sidef::Types::Block::Break {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub break {
        $_[0];
    }
};

1;
