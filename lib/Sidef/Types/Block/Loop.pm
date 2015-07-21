package Sidef::Types::Block::Loop {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub loop {
        $_[1]->loop;
    }
};

1
