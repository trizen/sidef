package Sidef::Types::Block::Break {

    sub new {
        bless {depth => 1}, __PACKAGE__;
    }

    sub break {
        my ($self, $depth) = @_;
        $self->{depth} = ref($depth) ? $depth->get_value : 1;
        $self;
    }

}

1;
