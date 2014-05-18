package Sidef::Types::Byte::Bytes {

    our @ISA = qw(
      Sidef::Types::Array::Array
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
