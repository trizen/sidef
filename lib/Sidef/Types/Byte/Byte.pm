package Sidef::Types::Byte::Byte {

    our @ISA = qw(
      Sidef::Types::Number::Number
      );

    sub new {
        my (undef, $byte) = @_;
        bless \(my $b = int($byte)), __PACKAGE__;
    }

}
