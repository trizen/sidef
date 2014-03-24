package Sidef::Types::Byte::Byte {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef::Types::Number::Number
      );

    sub new {
        my (undef, $byte) = @_;
        bless \(my $b = int($byte)), __PACKAGE__;
    }

}
