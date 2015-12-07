package Sidef::Types::Null::Null {

    use overload
      q{bool} => sub { },
      q{0+}   => sub { 0 },
      q{""}   => sub { '' };

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    sub new {
        bless \(my $nil = undef), __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        undef;
    }

    sub dump {
        Sidef::Types::String::String->new('null');
    }
};

1
