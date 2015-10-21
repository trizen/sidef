package Sidef::Variable::Define {
    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }
}

1;
