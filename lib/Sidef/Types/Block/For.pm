package Sidef::Types::Block::For {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub for {
        my ($self, @args) = @_;
        $self->{arg} = \@args;
        $self;
    }

    *foreach = \&for;

    sub do {
        my ($self, $code) = @_;
        $code->for(@{$self->{arg}});
    }
}
