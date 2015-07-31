package Sidef::Types::Block::Given {

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
