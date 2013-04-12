
use 5.014;
use strict;
use warnings;

package Sidef::Types::Glob::FileHandle {

    use Sidef::Init;

    sub new {
        my ($class, %opt) = @_;

        bless {
               fh   => $opt{fh},
               file => $opt{file},
              }, $class;
    }

    sub write {
        my ($self, $string) = @_;

        (print {$self->{fh}} $string)    # auto convertion to string
          ? Sidef::Types::Bool::Bool->true
          : Sidef::Types::Bool::Bool->false;
    }

    sub readline {
        my ($self) = @_;
        my $line = readline $self->{fh};
        Sidef::Types::String::String->new($line);
    }

    *read_line = \&readline;             # alias for readline

    sub file {
        my ($self) = @_;
        $self->{file};
    }

    sub close {
        my ($self) = @_;

        (close $self->{fh})
          ? Sidef::Types::Bool::Bool->true
          : Sidef::Types::Bool::Bool->false;
    }

};

1;
