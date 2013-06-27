
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::While {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub while {
        my ($self, $code) = @_;
        $self->{arg} = $code;
        $self;
    }

    sub do {
        my ($self, $code) = @_;
        $code->while($self->{arg});
    }

};

1;
