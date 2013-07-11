package Sidef::Types::Glob::FileHandle {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef);

    sub new {
        my (undef, %opt) = @_;

        bless {
               fh   => $opt{fh},
               file => $opt{file},
              },
          __PACKAGE__;
    }

    sub get_value {
        $_[0]->{fh};
    }

    sub file {
        $_[0]{file};
    }

    *parent = \&file;

    sub is_on_tty {
        Sidef::Types::Bool::Bool->new(-t $_[0]{fh});
    }

    *isOnTty = \&is_on_tty;

    sub stdout {
        __PACKAGE__->new(fh   => \*STDOUT,
                         file => Sidef::Types::Nil::Nil->new,);
    }

    sub stderr {
        __PACKAGE__->new(fh   => \*STDERR,
                         file => Sidef::Types::Nil::Nil->new,);
    }

    sub stdin {
        __PACKAGE__->new(fh   => \*STDIN,
                         file => Sidef::Types::Nil::Nil->new,);
    }

    sub write {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new(print {$self->{fh}} $string);
    }

    sub readline {
        my ($self) = @_;
        my $line = CORE::readline $self->{fh};
        defined($line) ? Sidef::Types::String::String->new($line) : Sidef::Types::Nil::Nil->new();
    }

    *read     = \&readline;
    *readLine = \&readline;

    sub read_all {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } CORE::readline($self->{fh}));
    }

    *get_lines = \&read_all;
    *getLines  = \&read_all;

    sub eof {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(eof $self->{fh});
    }

    sub tell {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(tell($self->{fh}));
    }

    sub seek {
        my ($self, $pos, $whence) = @_;

        (not $self->_is_number($pos) or not $self->_is_number($whence))
          && return Sidef::Types::Bool::Bool->false;

        Sidef::Types::Bool::Bool->new(seek($self->{fh}, $$pos, $$whence));
    }

    sub close {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(close $self->{fh});
    }

    sub stat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->stat($self->{fh}, $self);
    }

    sub lstat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->lstat($self->{fh}, $self);
    }
}
