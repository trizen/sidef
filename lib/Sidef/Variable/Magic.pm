package Sidef::Variable::Magic {

    sub new {
        my (undef, $name) = @_;
        bless {name => $name}, __PACKAGE__;
    }

}

1;
