
use 5.014;
use strict;
use warnings;

package Sidef::Types::Block::For {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub for {
        my ($self, $code) = @_;
        $self->{arg} = $code;
        $self;
    }

    *foreach = \&for;

    sub do {
        my ($self, $code) = @_;
        $code->for($self->{arg});
    }
};

1;
