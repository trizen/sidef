## package Sidef::Types::Number::NumberInt
package Sidef::Types::Number::Number {

    use 5.014;
    use Math::BigInt;

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
