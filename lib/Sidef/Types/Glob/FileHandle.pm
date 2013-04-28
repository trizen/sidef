
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
        Sidef::Types::Bool::Bool->new(print {$self->{fh}} $string)  ;
    }

    sub readline {
        my ($self) = @_;
        my $line = readline $self->{fh};
        Sidef::Types::String::String->new($line);
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
