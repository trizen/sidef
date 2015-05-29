package Sidef::Types::Byte::Bytes {

    use parent qw(
      Sidef::Types::Array::Array
      );

    use overload q{""} => \&dump;

    sub new {
        my (undef, @bytes) = @_;
        bless [@{Sidef::Types::Array::Array->new(@bytes)}], __PACKAGE__;
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
                Encode::decode_utf8(CORE::join('', map { CORE::chr($_->get_value) } @{$self}));
              } // return
        );
    }

    sub encode {
        my ($self, $encoding) = @_;
        require Encode;
        $encoding = defined($encoding) ? $encoding->get_value : 'UTF-8';
        Sidef::Types::String::String->new(
            eval {
                Encode::decode($encoding, CORE::join('', map { CORE::chr($_->get_value) } @{$self}));
              } // return
        );
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(
                                       'Bytes.new(' . CORE::join(', ', map { $_->get_value->dump->get_value } @{$self}) . ')');
    }
};

1
