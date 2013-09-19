package Sidef::Types::Black::Hole {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub DESTROY  { }
    sub AUTOLOAD { __PACKAGE__->new }
}

1;
