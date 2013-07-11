package Sidef::Types::Byte::Byte {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef::Types::Number::Number
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $byte) = @_;
        $byte = $$byte if ref $byte;
        bless \$byte, __PACKAGE__;
    }

}
