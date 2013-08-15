package Sidef::Types::Block::Next {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub next {
        $_[0];
    }

}

1;
