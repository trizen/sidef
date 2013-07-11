package Sidef::Types::Black::Hole {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub DESTROY {
        return;
    }

    sub AUTOLOAD {
        return __PACKAGE__->new();
    }
}

1;
