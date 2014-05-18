package Sidef::Types::Black::Hole {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub DESTROY  { }
    sub AUTOLOAD { __PACKAGE__->new }
}

1;
