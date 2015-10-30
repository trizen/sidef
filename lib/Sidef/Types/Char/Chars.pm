package Sidef::Types::Char::Chars {

    use parent qw(
      Sidef::Types::Array::Array
      );

    use overload q{""} => \&dump;

    sub new {
        my (undef, @chars) = @_;
        bless \@chars, __PACKAGE__;
    }

    sub call {
        my ($self, @strings) = @_;
        $self->new(map { Sidef::Types::Char::Char->new($_) } split(//, join('', @strings)));
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Chars(' . join(', ', map { $_->dump->get_value } @{$self}) . ')');
    }
};

1
