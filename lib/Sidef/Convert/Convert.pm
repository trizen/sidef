
use 5.014;
use strict;
use warnings;

package Sidef::Convert::Convert {

    require Sidef::Init;

    #<<<
    my $array_like = [
        'Sidef::Types::Array::Array',
        'Sidef::Types::Bytes::Bytes',
        'Sidef::Types::Chars::Chars',
    ];
    #>>>

    use overload q{""} => sub {
        my ($type) = ref($_[0]);

        if ($type ~~ $array_like) {

            return $_[0];

            #return Sidef::Types::String::String->new('[' . join(', ', map {$_->{self}} @{$_[0]}) . ']'); #For Debug
        }

        return ${$_[0]};
    };

    sub to_s {
        my ($self) = @_;

        if (ref $self ~~ $array_like) {
            return Sidef::Types::String::String->new(join(' ', @{$self}));
        }

        Sidef::Types::String::String->new("$$self");
    }

    sub to_sd {
        my ($self) = @_;
        Sidef::Types::String::Double->new("$$self");
    }

    sub to_i {
        my ($self) = @_;
        Sidef::Types::Number::Integer->new($$self);
    }

    sub to_float {
        my ($self) = @_;
        Sidef::Types::Number::Float->new($$self);
    }

    sub to_file {
        my ($self) = @_;
        Sidef::Types::Glob::File->new($$self);
    }

    sub to_dir {
        my ($self) = @_;
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

        Sidef::Types::Bytes::Bytes->new(@bytes);
    }

    sub to_chars {
        my ($self) = @_;
        Sidef::Types::Chars::Chars->new(map { Sidef::Types::Char::Char->new($_) } split //, $$self);
    }

    sub to_array {
        my ($self) = @_;
        Sidef::Types::Array::Array->new($self);
    }
}

1;
