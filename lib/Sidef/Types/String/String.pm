
use 5.014;
use strict;
use warnings;

package Sidef::Types::String::String {

    use parent qw(Sidef::Convert::Convert);

    sub uc {
        my ($self) = @_;
        Sidef::Types::String::Single->new(CORE::uc $$self);
    }

    sub lc {
        my ($self) = @_;
        Sidef::Types::String::Single->new(CORE::lc $$self);
    }

    sub reverse {
        my ($self) = @_;
        Sidef::Types::String::Single->new(scalar CORE::reverse $$self);
    }

    sub say {
        my ($self) = @_;

        (CORE::say $$self)
          ? Sidef::Types::Bool::Bool->true
          : Sidef::Types::Bool::Bool->false;
    }

    sub print {
        my ($self) = @_;
        (CORE::print $$self)
          ? Sidef::Types::Bool::Bool->true
          : Sidef::Types::Bool::Bool->false;
    }

    sub stat_file {
        my($self) = @_;
        Sidef::Types::Glob::File->new($$self);
    }

    sub stat_dir {
        my($self) = @_;
        Sidef::Types::Glob::Dir->new($$self);
    }
}

1;
