package Sidef::Types::Char::Char {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef::Types::String::String
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $char) = @_;
        $char = $$char if ref $char;
        bless \$char, __PACKAGE__;
    }

}
