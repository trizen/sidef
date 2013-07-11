package Sidef::Types::Block::Continue {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub continue {
        $_[0];
    }

}

1;
