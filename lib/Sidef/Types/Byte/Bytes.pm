package Sidef::Types::Byte::Bytes {

    use 5.014;
    use parent qw(
      Sidef::Types::Array::Array
      );

    use overload q{""} => \&dump;

    sub new {
        my (undef, @bytes) = @_;
        bless \@bytes, __PACKAGE__;
    }

    sub call {
        my ($self, @strings) = @_;
        my $string = CORE::join('', @strings);
        state $x = require bytes;
        $self->new(map { Sidef::Types::Byte::Byte->new(CORE::ord bytes::substr($string, $_, 1)) }
                   0 .. bytes::length($string) - 1);
    }

    sub join {
        my ($self) = @_;
        state $x = require Encode;
        Sidef::Types::String::String->new(
            eval {
                Encode::decode_utf8(CORE::join('', map { CORE::chr($_) } @{$self}));
              } // return
        );
    }

    sub encode {
        my ($self, $encoding) = @_;
        state $x = require Encode;
        $encoding = defined($encoding) ? $encoding->get_value : 'UTF-8';
        Sidef::Types::String::String->new(
            eval {
                Encode::decode($encoding, CORE::join('', map { CORE::chr($_) } @{$self}));
              } // return
        );
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Bytes.new(' . CORE::join(', ', map { $_->dump->get_value } @{$self}) . ')');
    }
};

1
