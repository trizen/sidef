package Sidef::Types::Block::Return {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub return {
        my ($self, @obj) = @_;
        $self->{obj} = @obj > 1 ? Sidef::Types::Array::List->new(@obj) : $obj[0];
        $self;
    }

}

1;
