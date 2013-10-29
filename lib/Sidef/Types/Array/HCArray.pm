package Sidef::Types::Array::HCArray {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        my (undef, @items) = @_;
        bless \@items, __PACKAGE__;
    }

};

1
