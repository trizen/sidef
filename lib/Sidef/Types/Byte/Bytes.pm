package Sidef::Types::Byte::Bytes {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      Sidef::Types::Array::Array
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, @bytes) = @_;
        bless [@{Sidef::Types::Array::Array->new(@bytes)}], __PACKAGE__;
    }

    sub join {
        my ($self) = @_;

        require Encode;
        Sidef::Types::String::String->new(Encode::decode_utf8(join('', map { $_->get_value->chr } @{$self})));
    }

}
