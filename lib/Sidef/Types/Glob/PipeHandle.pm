
use 5.014;
use strict;
use warnings;

# NEEDS WORK!!!

package Sidef::Types::Glob::PipeHandle {

    sub new {
        my ($class, %opt) = @_;

        bless {
               pipe_h => $opt{pipe_h},
               pipe   => $opt{pipe},
              }, $class;
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
