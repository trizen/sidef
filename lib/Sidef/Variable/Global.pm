package Sidef::Variable::Global {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

};

1;
