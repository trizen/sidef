
use 5.014;
use strict;
use warnings;

package Sidef::Convert::Convert {

    use Sidef::Init;
    use overload q{""} => sub { ${$_[0]} };

    sub to_s {
        my ($self) = @_;
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

    sub to_f {
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

    sub to_b {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self);
    }

    sub to_a {
        my ($self) = @_;
        Sidef::Types::Array::Array->new($self);
    }
}

1;
