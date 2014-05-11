package Sidef::Types::Block::Break {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {depth => 1}, __PACKAGE__;
    }

    sub break {
        my ($self, $depth) = @_;
        $self->{depth} = defined($depth) ? $$depth : 1;
        $self;
    }

}

1;
