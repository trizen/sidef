package Sidef::Types::Byte::Byte {

    use 5.014;
    use parent qw(
      Sidef::Types::Number::Number
      );

    sub new {
        my (undef, $byte) = @_;
        bless \Math::BigInt->new($byte), __PACKAGE__;
    }

    *call = \&new;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Byte.new(' . $self->get_value . ')');
    }
};

1
