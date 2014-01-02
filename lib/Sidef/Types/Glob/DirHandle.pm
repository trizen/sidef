package Sidef::Types::Glob::DirHandle {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef);

    sub new {
        my (undef, %opt) = @_;

        bless {
               dir_h => $opt{dir_h},
               dir   => $opt{dir},
              },
          __PACKAGE__;
    }

    sub dir {
        $_[0]{dir};
    }

    *parent = \&dir;

    sub get_files {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } readdir($self->{dir_h}));
    }

    *getFiles = \&get_files;

    sub get_file {
        my ($self) = @_;
        (my $file = readdir($self->{dir_h})) // return;
        Sidef::Types::Glob::File->new($file);
    }

    *getFile = \&get_file;

    sub tell {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(telldir($self->{dir_h}));
    }

    sub seek {
        my ($self, $pos) = @_;
        $self->_is_number($pos) || return;
        Sidef::Types::Bool::Bool->new(seekdir($self->{dir_h}, $$pos));
    }

    sub close {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(closedir($self->{dir_h}));
    }

    sub chdir {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(chdir($self->{dir_h}));
    }

    sub stat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->stat($self->{dir_h}, $self);
    }

    sub lstat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->lstat($self->{dir_h}, $self);
    }

    sub each {
        my ($self, $code) = @_;
        $self->_is_code($code) || return;

        while (defined(my $file = CORE::readdir($self->{dir_h}))) {
            if (ref($code->call(Sidef::Types::String::String->new($file))) eq 'Sidef::Types::Block::Break') {
                last;
            }
        }

        $self;
    }

}
