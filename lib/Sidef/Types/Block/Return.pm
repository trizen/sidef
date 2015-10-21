package Sidef::Types::Block::Return {

    sub new {
        my (undef, @obj) = @_;
        bless {obj => \@obj}, __PACKAGE__;
    }

}

1;
