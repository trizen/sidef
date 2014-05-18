package Sidef::Types::Block::Continue {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub continue {
        $_[0];
    }

}

1;
