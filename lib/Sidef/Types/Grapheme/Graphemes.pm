package Sidef::Types::Grapheme::Graphemes {

    use parent qw(
      Sidef::Types::Array::Array
      );

    use overload q{""} => \&dump;

    sub new {
        my (undef, @graphemes) = @_;
        bless \@graphemes, __PACKAGE__;
    }

    sub call {
        my ($self, @strings) = @_;
        $self->new(map { Sidef::Types::Grapheme::Grapheme->new($_) } map { /\X/g } @strings);
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Graphemes(' . join(', ', map { $_->dump->get_value } @{$self}) . ')');
    }
};

1
