package Sidef::Variable::LocalInit {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

};

1;
