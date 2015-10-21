package Sidef::Types::Block::CodeInit {

    sub new {
        my (undef, $ast) = @_;
        bless {code => $ast}, __PACKAGE__;
    }

};

1;
