## package Sidef::Types::Number::NumberRat
package Sidef::Types::Number::Number {

    use 5.014;
    use strict;
    use warnings;

    no warnings 'redefine';

    use Math::BigRat try => 'GMP,Pari';

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $num) = @_;

        ref($num) eq 'Math::BigRat'
          ? (bless \$num, __PACKAGE__)
          : (bless \Math::BigRat->new($num), __PACKAGE__);
    }

};

1
