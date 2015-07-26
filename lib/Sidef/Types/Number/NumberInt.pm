## package Sidef::Types::Number::NumberInt
package Sidef::Types::Number::Number {

    use 5.014;
    use Math::BigInt;

    delete $INC{'Sidef/Types/Number/Number.pm'};
    require Sidef::Types::Number::Number;
    *new = \&new_int;
};

1
