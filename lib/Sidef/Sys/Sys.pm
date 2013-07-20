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

    sub print {
        my ($self, @rest) = @_;
        Sidef::Types::Bool::Bool->new(print @rest);
    }

    sub printh {
        my ($self, $fh, @rest) = @_;

        if (ref($fh) eq 'GLOB') {
            return Sidef::Types::Bool::Bool->new(print {$fh} @rest);
        }
        elsif (ref($fh) =~ /^Sidef::Types::Glob::/ and $fh->can('print')) {
            return $fh->print(@rest);
        }

        warn "[WARN] Sys.printh(): invalid handle object!\n";
        return;
    }

    sub println {
        my ($self, @rest) = @_;
        say @rest;
    }

}
