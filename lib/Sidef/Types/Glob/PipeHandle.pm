package Sidef::Types::Glob::PipeHandle {

    use 5.014;
    use strict;
    use warnings;

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
        $_[0]{pipe};
    }

    *parent = \&pipe;

    sub readline {
        my ($self) = @_;
        (my $line = readline $self->{pipe_h}) // return;
        Sidef::Types::String::String->new($line);
    }

    *read     = \&readline;
    *readLine = \&readline;

    sub read_all {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } CORE::readline $self->{pipe_h});
    }

    *get_lines = \&read_all;
    *getLines  = \&read_all;
    *readAll   = \&read_all;

    sub close {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(close $self->{pipe_h});
    }

}
