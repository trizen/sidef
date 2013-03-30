use 5.014;
use strict;
use warnings;

package Sidef::Convert::Convert {

    use overload q{""} => sub { ${$_[0]} };

    sub to_s {
        my ($self) = @_;
        String->new("$$self");
    }

    sub to_i {
        my ($self) = @_;
        Number::Integer->new($$self);
    }

    sub to_f {
        my ($self) = @_;
        Number::Float->new($$self);
    }

    sub to_b {
        my ($self) = @_;
        $$self ? Bool->true : Bool->false;
    }
}

1;
