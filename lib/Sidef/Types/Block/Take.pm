package Sidef::Types::Block::Take {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }
}

1;
