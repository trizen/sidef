package Sidef::Types::Char::Chars {

    our @ISA = qw(
      Sidef::Types::Array::Array
      );

    sub new {
        my (undef, @chars) = @_;
        bless [@{Sidef::Types::Array::Array->new(@chars)}], __PACKAGE__;
    }

}
