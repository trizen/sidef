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

    sub get_value {
        $_[0]->{dir_h};
    }

    sub dir {
        $_[0]{dir};
    }

    *parent = \&dir;

    sub get_files {
        my ($self) = @_;

        require Cwd;
        require File::Spec;

        my $curdir = Cwd::getcwd();
        CORE::chdir($self->{dir_h});

        my $array = Sidef::Types::Array::Array->new(
            map {
                my $file = File::Spec->rel2abs($_);
                (-d $file)
                  ? Sidef::Types::Glob::Dir->new($file)
                  : Sidef::Types::Glob::File->new($file);
              } readdir($self->{dir_h})
        );

        CORE::chdir($curdir);
        $array;
    }

    *getFiles = \&get_files;
    *read_dir = \&get_files;
    *readdir  = \&get_files;
    *readDir  = \&get_files;

    sub get_file {
        my ($self) = @_;

        my $file;
        if (defined($file = CORE::readdir($self->{dir_h}))) {

            require Cwd;
            my $curdir = Cwd::getcwd();
            CORE::chdir($self->{dir_h});

            require File::Spec;
            $file = File::Spec->rel2abs($file);
            $file =
              (-d $file)
              ? Sidef::Types::Glob::Dir->new($file)
              : Sidef::Types::Glob::File->new($file);

            CORE::chdir($curdir);
        }

        $file;
    }

    *getFile = \&get_file;
    *read    = \&get_file;

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
        my ($var_ref) = $code->init_block_vars();

        while (defined(my $file = CORE::readdir($self->{dir_h}))) {
            $var_ref->set_value(Sidef::Types::String::String->new($file));
            if (defined(my $res = $code->_run_code)) {
                return $res;
            }
        }

        $self;
    }

}
