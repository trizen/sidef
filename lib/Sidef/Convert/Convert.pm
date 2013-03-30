use 5.014;
use strict;
use warnings;

package Sidef::Convert::Convert {

    use overload q{""} => sub { ${ $_[0] } };

    require Sidef::Types::Bool::Bool;
    require Sidef::Types::Array::Array;
    require Sidef::Types::Number::Float;
    require Sidef::Types::String::Single;
    require Sidef::Types::String::Double;
    require Sidef::Types::Number::Integer;

    sub to_s {
        my ($self) = @_;
        Sidef::Types::String::Single->new("$$self");
    }

    sub to_sd {
        my($self) = @_;
        Sidef::Types::String::Double->new("$$self");
    }

    sub to_i {
        my ($self) = @_;
        Sidef::Types::Number::Integer->new($$self);
    }

    sub to_f {
        my ($self) = @_;
        Sidef::Types::Number::Float->new($$self);
    }

    sub to_b {
        my ($self) = @_;
        $$self
        ? Sidef::Types::Bool::Bool->true
        : Sidef::Types::Bool::Bool->false;
    }

    sub to_a {
        my($self) = @_;
        Sidef::Types::Array::Array->new($self);
    }
}

1;
