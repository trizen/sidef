package Sidef::Types::Block::Return {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub return {
        my ($self, $obj) = @_;
        $self->{obj} = $obj;
        $self;
    }

    sub get_obj {
        $_[0]->{obj};
    }
}

1;
