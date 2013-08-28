package Sidef::Convert::Convert {

    # This module is used only as parent!

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef);

    state $array_like = {
                         'Sidef::Types::Array::Array' => 1,
                         'Sidef::Types::Byte::Bytes'  => 1,
                         'Sidef::Types::Char::Chars'  => 1,
                        };

    use overload q{""} => sub {
        my ($type) = ref($_[0]);

        if (exists $array_like->{$type} or $type eq 'Sidef::Types::Hash::Hash') {
            return $_[0];
        }

        return ${$_[0]};
    };

    sub to_s {
        my ($self) = @_;

        if (exists $array_like->{ref $self}) {
            return Sidef::Types::String::String->new(join(' ', map { $_->get_value } @{$self}));
        }

        Sidef::Types::String::String->new("$$self");
    }

    *toString  = \&to_s;
    *to_string = \&to_s;

    sub to_i {
        my ($self) = @_;
        $self->_is_number($self, 0, 1) || $self->_is_string($self) || return;
        Sidef::Types::Number::Number->new(int $$self);
    }

    *to_integer = \&to_i;
    *toInt      = \&to_i;
    *to_int     = \&to_i;
    *toInteger  = \&to_i;

    sub to_num {
        my ($self) = @_;
        $self->_is_number($self, 0, 1) || $self->_is_string($self) || return;
        Sidef::Types::Number::Number->new($$self);
    }

    *toNum = \&to_num;

    sub to_file {
        my ($self) = @_;
        $self->_is_string($self) || return;
        Sidef::Types::Glob::File->new($$self);
    }

    *toFile = \&to_file;

    sub to_dir {
        my ($self) = @_;
        $self->_is_string($self) || return;
        Sidef::Types::Glob::Dir->new($$self);
    }

    *toDir = \&to_dir;

    sub to_bool {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self);
    }

    *toBool = \&to_bool;

    sub to_byte {
        my ($self) = @_;
        $self->_is_number($self, 0, 1) || $self->_is_string($self) || return;
        Sidef::Types::Byte::Byte->new(CORE::ord $$self);
    }

    *toByte = \&to_byte;

    sub to_char {
        my ($self) = @_;
        $self->_is_number($self, 0, 1) || $self->_is_string($self) || return;
        Sidef::Types::Char::Char->new(substr($$self, 0, 1));
    }

    *toChar = \&to_char;

    sub to_bytes {
        my ($self) = @_;

        $self->_is_number($self, 0, 1) || $self->_is_string($self) || return;

        my @bytes = do {
            use bytes;
            map { Sidef::Types::Byte::Byte->new(CORE::ord bytes::substr($$self, $_, 1)) }
              0 .. bytes::length($$self) - 1;
        };

        Sidef::Types::Byte::Bytes->new(@bytes);
    }

    *toBytes = \&to_bytes;

    sub to_chars {
        my ($self) = @_;
        $self->_is_number($self, 0, 1) || $self->_is_string($self) || return;
        Sidef::Types::Char::Chars->new(map { Sidef::Types::Char::Char->new($_) } split //, $$self);
    }

    *toChars = \&to_chars;

    sub to_array {
        my ($self) = @_;
        Sidef::Types::Array::Array->new($self);
    }

    *toArray = \&to_array;
}
