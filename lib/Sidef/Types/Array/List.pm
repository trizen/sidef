package Sidef::Types::Array::List {

    sub new {
        shift;
        bless \@_, __PACKAGE__;
    }
};

1
