package Sidef::Types::Array::List {

    use parent qw(
      Sidef::Object::Object
      );

    sub new {
        shift;
        bless \@_, __PACKAGE__;
    }
};

1
