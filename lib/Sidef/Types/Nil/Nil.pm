package Sidef::Types::Nil::Nil {

    use overload
      q{bool} => sub { },
      q{""}   => sub { '' };

    use parent qw(
      Sidef::Object::Object
      );

    sub new {
        bless \(my $nil = undef), __PACKAGE__;
    }

    sub get_value {
        undef;
    }

    sub dump {
        Sidef::Types::String::String->new('nil');
    }
};

1
