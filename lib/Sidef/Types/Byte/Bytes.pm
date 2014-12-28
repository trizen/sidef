package Sidef::Types::Byte::Bytes {

    our @ISA = qw(
      Sidef::Types::Array::Array
      );

    sub new {
        my (undef, @bytes) = @_;
        bless [@{Sidef::Types::Array::Array->new(@bytes)}];
    }

    sub call {
        my ($self, @strings) = @_;
        my $string = CORE::join('', @strings);
        my @bytes = do {
            use bytes;
            map { Sidef::Types::Byte::Byte->new(CORE::ord bytes::substr($string, $_, 1)) } 0 .. bytes::length($string) - 1;
        };
        $self->new(@bytes);
    }

    sub join {
        my ($self) = @_;
        require Encode;
        Sidef::Types::String::String->new(
            eval {
                Encode::decode_utf8(join('', map { CORE::chr($_->get_value) } @{$self}));
              } // return
        );
    }
};

1
