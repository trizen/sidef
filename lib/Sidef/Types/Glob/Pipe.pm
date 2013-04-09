
use 5.014;
use strict;
use warnings;

# NEEDS WORK!!!

package Sidef::Types::Glob::Pipe {

    use Sidef::Init;

    sub new {
        my ($class, $command) = @_;

        bless {command => $command,}, $class;
    }

    sub open {
        my ($self, $mode) = @_;
        open my $pipe_h, $mode, $self->{command};
        return
          Sidef::Types::Glob::PipeHandle->new(pipe_h  => $pipe_h,
                                              command => $self->{command},);
    }

    sub open_r {
        my ($self) = @_;
        $self->open('-|');
    }

    sub open_w {
        my ($self) = @_;
        $self->open('|-');
    }

};

1;
