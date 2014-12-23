package Sidef::Types::Byte::Byte {

    our @ISA = qw(
      Sidef::Types::Number::Number
      );

    sub new {
        my (undef, $byte) = @_;
        require Math::BigInt;
        bless \Math::BigInt->new($byte), __PACKAGE__;
    }

    *call = \&new;
};

1
