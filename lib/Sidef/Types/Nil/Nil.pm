package Sidef::Types::Nil::Nil {

    sub new {
        bless \(my $nil = undef), __PACKAGE__;
    }

    sub get_value {
        undef;
    }
};

1
