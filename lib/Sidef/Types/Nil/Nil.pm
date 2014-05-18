package Sidef::Types::Nil::Nil {

    use overload 'bool' => sub { };

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
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

}
