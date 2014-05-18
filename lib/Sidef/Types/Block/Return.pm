package Sidef::Types::Block::Return {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub return {
        my ($self, $obj) = @_;
        $self->{obj} = $obj;
        $self;
    }

}

1;
