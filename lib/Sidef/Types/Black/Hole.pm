package Sidef::Types::Black::Hole {

    sub new {
        bless {value => $_[1]}, __PACKAGE__;
    }

    sub DESTROY  { }
    sub AUTOLOAD { __PACKAGE__->new }
}

1;
