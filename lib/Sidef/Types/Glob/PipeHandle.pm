
use 5.014;
use strict;
use warnings;

# NEEDS WORK!!!

package Sidef::Types::Glob::PipeHandle {

    use Sidef::Init;

    sub new {
        my ($class, %opt) = @_;

        bless {
               pipe_h  => $opt{pipe_h},
               command => $opt{command},
              }, $class;
    }

    sub command {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->{command});
    }

    sub close {
        my ($self) = @_;
        (close $self->{pipe_h})
          ? Sidef::Types::Bool::Bool->true
          : Sidef::Types::Bool::Bool->false;
    }

};

1;
