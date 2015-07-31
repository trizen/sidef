package Sidef::Types::Block::Next {

    sub new {
        bless {depth => 1}, __PACKAGE__;
    }

    sub next {
        my ($self, $depth) = @_;
        $self->{depth} = ref($depth) ? $depth->get_value : 1;
        $self;
    }

}

1;
