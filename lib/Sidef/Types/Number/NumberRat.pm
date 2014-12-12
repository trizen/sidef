## package Sidef::Types::Number::NumberRat
package Sidef::Types::Number::Number {

    use 5.014;
    use Math::BigRat;

    delete @INC{'Sidef/Types/Number/Number.pm'};
    require Sidef::Types::Number::Number;
    *new = \&new_rat;
};

1
