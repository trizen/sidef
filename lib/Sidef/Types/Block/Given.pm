package Sidef::Types::Block::Given {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub given {
        my ($self, $expr) = @_;
        Sidef::Types::Block::Switch->new($expr);
    }

    *switch = \&given;
}

1;
