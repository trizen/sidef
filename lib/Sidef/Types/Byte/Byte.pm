package Sidef::Types::Byte::Byte {

    use 5.014;
    use strict;
    use warnings;

    require Math::BigInt;

    our @ISA = qw(
      Sidef::Types::Number::Number
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $byte) = @_;
        bless \Math::BigInt->new($byte), __PACKAGE__;
    }

}
