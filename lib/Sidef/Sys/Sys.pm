package Sidef::Sys::Sys {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub exit {
        my ($self, $code) = @_;
        exit($code // 0);
    }

    sub osname {
        my ($self) = @_;
        Sidef::Types::String::String->new($^O);
    }

    *osName = \&osname;

    sub sidef {
        my ($self) = @_;

        require File::Spec;
        Sidef::Types::String::String->new(File::Spec->rel2abs($0));
    }

}
