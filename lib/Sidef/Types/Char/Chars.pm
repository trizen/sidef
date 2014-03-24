package Sidef::Types::Char::Chars {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef::Types::Array::Array
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, @chars) = @_;
        bless [@{Sidef::Types::Array::Array->new(@chars)}], __PACKAGE__;
    }

}
