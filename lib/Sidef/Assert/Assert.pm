package Sidef::Assert::Assert {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }
};

1;
