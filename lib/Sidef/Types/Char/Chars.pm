package Sidef::Types::Char::Chars {

    our @ISA = qw(
      Sidef::Types::Array::Array
      );

    sub new {
        my (undef, @chars) = @_;
        bless [@{Sidef::Types::Array::Array->new(@chars)}], __PACKAGE__;
    }

    sub call {
        my ($self, $string) = @_;
        $self->new(map { Sidef::Types::Char::Char->new($_) } split //, $string);
    }
};

1
