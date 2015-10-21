package Sidef::Types::Block::Break {

    sub new {
        my (undef, $depth) = @_;
        bless {depth => (ref($depth) ? $depth->get_value : 1)}, __PACKAGE__;
    }
}

1;
