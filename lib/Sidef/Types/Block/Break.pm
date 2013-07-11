package Sidef::Types::Block::Break {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub break {
        $_[0];
    }

}

1;
