package Sidef::Variable::Struct {

    use 5.014;

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }
}

1
