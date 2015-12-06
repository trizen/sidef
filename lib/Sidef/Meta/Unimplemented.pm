package Sidef::Meta::Unimplemented {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }
};

1;
