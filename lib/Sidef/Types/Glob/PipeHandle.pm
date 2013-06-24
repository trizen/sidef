
use 5.014;
use strict;
use warnings;

# NEEDS WORK!!!

package Sidef::Types::Glob::PipeHandle {

    sub new {
        my (undef, %opt) = @_;

        bless {
               pipe_h => $opt{pipe_h},
               pipe   => $opt{pipe},
              },
          __PACKAGE__;
    }

    sub get_value {
        $_[0]->{pipe_h};
    }

    sub pipe {
        my ($self) = @_;
        $self->{pipe};
    }

    sub readline {
        my ($self) = @_;
        my $line = readline $self->{pipe_h};
        defined($line) ? Sidef::Types::String::String->new($line) : Sidef::Types::Nil::Nil->new();
    }

    sub close {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(close $self->{pipe_h});
    }

};

1;
