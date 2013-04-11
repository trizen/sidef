
use 5.014;
use strict;
use warnings;

package Sidef::Types::Glob::FileHandle {

    use Sidef::Init;

    sub new {
        my ($class, %opt) = @_;

        bless {
               fh   => $opt{fh},
               name => $opt{name},
              }, $class;
    }

    sub write {
        my($self, $string) = @_;
        print {$self->{fh}} $string;    # auto convert
    }

    sub readline {
        my ($self) = @_;
        my $line = readline $self->{fh};
        Sidef::Types::String::Single->new($line);
    }

    *read_line = \&readline;    # alias for readline

    sub file {
        my ($self) = @_;
        $self->{file};
    }

    sub file_name {
        my ($self) = @_;
        Self::Types::String::Single->new($self->{name});
    }

    sub close {
        my ($self) = @_;
        (close $self->{fh})
          ? Sidef::Types::Bool::Bool->true
          : Sidef::Types::Bool::Bool->false;
    }

};

1;
