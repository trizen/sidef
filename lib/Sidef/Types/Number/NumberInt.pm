package Sidef::Types::Number::Number {

    use 5.014;
    use strict;
    use warnings;

    no warnings 'redefine';

    use Math::BigInt try => 'GMP,Pari';

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $num) = @_;

        ref($num) eq 'Math::BigInt'
          ? (bless \$num, __PACKAGE__)
          : (bless \Math::BigInt->new(CORE::int($num // 0)), __PACKAGE__);
    }

};

1
