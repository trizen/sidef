package Sidef::Variable::NamedParam {

    sub new {
        my (undef, $name, @args) = @_;
        bless [$name, \@args], __PACKAGE__;
    }
}

1;
