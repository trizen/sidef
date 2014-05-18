package Sidef::Types::Array::HCArray {

    sub new {
        my (undef, @items) = @_;
        bless \@items, __PACKAGE__;
    }

};

1
