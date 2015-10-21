package Sidef::Variable::Init {

    sub new {
        my (undef, @vars) = @_;
        bless {vars => \@vars}, __PACKAGE__;
    }

};

1;
