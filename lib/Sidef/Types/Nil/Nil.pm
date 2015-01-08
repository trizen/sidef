package Sidef::Types::Nil::Nil {

    use overload
      'bool' => sub { },
      q{""}  => sub { '' };

    our @ISA = qw(
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
