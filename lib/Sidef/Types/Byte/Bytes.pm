
use 5.014;
use strict;
use warnings;

package Sidef::Types::Byte::Bytes {

    use autouse 'Encode' => qw(decode_utf8($;$));
    use parent qw(Sidef::Convert::Convert Sidef::Types::Array::Array);

    sub new {
        my ($class, @bytes) = @_;
        $class = ref($class) if ref($class);
        bless [@{Sidef::Types::Array::Array->new(@bytes)}], $class;
    }

    sub join {
        my ($self) = @_;
        Sidef::Types::String::String->new(decode_utf8(join('', map { $_->get_value->chr } @{$self})));
    }

}

1;
