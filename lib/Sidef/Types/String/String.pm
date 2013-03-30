
use 5.016;
use strict;
use warnings;

package Sidef::Types::String::String {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my ($class, $str) = @_;
        bless \$str, $class;
    }

    sub uc {
        my ($self) = @_;
        __PACKAGE__->new(CORE::uc $$self);
    }

    sub lc {
        my ($self) = @_;
        __PACKAGE__->new(CORE::lc $$self);
    }

    sub reverse {
        my ($self) = @_;
        __PACKAGE__->new(scalar CORE::reverse $$self);
    }

    sub print {
        my($self) = @_;
        (CORE::print $$self) ? Bool->true : Bool->false;
    }
}

1;
