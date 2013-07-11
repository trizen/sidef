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
            return Sidef::Types::String::String->new(join(' ', @{$self}));
        }

        Sidef::Types::String::String->new("$$self");
    }

    sub to_i {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(int $$self);
    }

    sub to_file {
        my ($self) = @_;
        $self->_is_string($self) || return $self;
        Sidef::Types::Glob::File->new($$self);
    }

    sub to_dir {
        my ($self) = @_;
        $self->_is_string($self) || return $self;
        Sidef::Types::Glob::Dir->new($$self);
    }

    sub to_bool {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self);
    }

    sub to_byte {
        my ($self) = @_;
        Sidef::Types::Byte::Byte->new(CORE::ord $$self);
    }

    sub to_char {
        my ($self) = @_;
        Sidef::Types::Char::Char->new(substr($$self, 0, 1));
    }

    sub to_bytes {
        my ($self) = @_;

        my @bytes = do {
            use bytes;
            map { Sidef::Types::Byte::Byte->new(CORE::ord bytes::substr($$self, $_, 1)) }
              0 .. bytes::length($$self) - 1;
        };

        Sidef::Types::Byte::Bytes->new(@bytes);
    }

    sub to_chars {
        my ($self) = @_;
        Sidef::Types::Char::Chars->new(map { Sidef::Types::Char::Char->new($_) } split //, $$self);
    }

    sub to_array {
        my ($self) = @_;
        Sidef::Types::Array::Array->new($self);
    }
}
