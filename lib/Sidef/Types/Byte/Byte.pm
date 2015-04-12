package Sidef::Types::Byte::Byte {

    use parent qw(
      Sidef::Types::Number::Number
      );

    sub new {
        my (undef, $byte) = @_;
        require Math::BigInt;
        bless \Math::BigInt->new($byte), __PACKAGE__;
    }

    *call = \&new;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Byte.new(' . $self->get_value . ')');
    }
};

1
