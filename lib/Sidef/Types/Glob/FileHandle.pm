
use 5.014;
use strict;
use warnings;

package Sidef::Types::Glob::FileHandle {

    use Sidef::Init;

    sub new {
        my (undef, %opt) = @_;

        bless {
               fh   => $opt{fh},
               file => $opt{file},
              },
          __PACKAGE__;
    }

    sub write {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new(print {$self->{fh}} $string);
    }

    sub readline {
        my ($self) = @_;
        my $line = readline $self->{fh};
        defined($line) ? Sidef::Types::String::String->new($line) : Sidef::Types::Nil::Nil->new();
    }

    sub file {
        my ($self) = @_;
        $self->{file};
    }

    sub close {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(close $self->{fh});
    }

};

1;
