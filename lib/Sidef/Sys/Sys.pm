
use 5.014;
use strict;
use warnings;

package Sidef::Sys::Sys {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub exit {
        my ($self, $code) = @_;
        exit($code // 0);
    }

};

1;
