package Sidef::Types::Grapheme::Grapheme {

    use parent qw(
      Sidef::Convert::Convert
      Sidef::Types::String::String
      );

    sub new {
        my (undef, $char) = @_;
        ref($char) && return $char->to_grapheme;
        $char //= "\0";
        bless \$char, __PACKAGE__;
    }

    sub call {
        my ($self, $char) = @_;
        $self->new("$char" =~ /^(\X)/ ? $1 : "\0");
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(q{Grapheme(} . $self->to_s->dump->get_value . q{)});
    }
};

1
