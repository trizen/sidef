package Sidef::Variable::InitMy {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        my (undef, $name) = @_;
        bless {name => $name}, __PACKAGE__;
    }

    sub get_name {
        $_[0]->{name};
    }

};

1;
