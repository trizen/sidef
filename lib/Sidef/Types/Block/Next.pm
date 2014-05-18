package Sidef::Types::Block::Next {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub next {
        $_[0];
    }

}

1;
