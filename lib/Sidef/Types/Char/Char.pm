package Sidef::Types::Char::Char {

    use parent qw(
      Sidef::Convert::Convert
      Sidef::Types::String::String
      );

    sub new {
        my (undef, $char) = @_;
        ref($char) && return $char->to_char;
        $char //= "\0";
        bless \$char, __PACKAGE__;
    }

    sub call {
        my ($self, $char) = @_;
        $self->new(chr ord $char);
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(q{Char(} . $self->to_s->dump->get_value . q{)});
    }
};

1
