package Sidef::Types::Nil::Nil {

    use 5.014;
    use strict;
    use warnings;

    use overload 'bool' => sub { };

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        bless \(my $nil = 'nil'), __PACKAGE__;
    }

    sub get_value {
        undef;
    }

    sub dump {
        Sidef::Types::String::String->new('nil');
    }

}
