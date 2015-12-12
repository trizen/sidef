package Sidef::Types::Glob::DirHandle {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

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

        $self->rewind;

        my @files;
        while (defined(my $file = $self->read)) {
            push @files, $file;
        }
        Sidef::Types::Array::Array->new(@files);
    }

    *read_dir = \&get_files;
    *readdir  = \&get_files;
    *entries  = \&get_files;

    sub get_file {
        my ($self) = @_;

        require Encode;
        require File::Spec;

        {
            my $file = CORE::readdir($self->{dir_h}) // return;

            if ($file eq '.' or $file eq '..') {
                redo;
            }

            my $dfile = Encode::decode_utf8($file);
            my $dir = File::Spec->catdir($self->{dir}->get_value, $dfile);

            lstat($dir);
            if (-l _) { redo }
            ;    # ignore links

            return (
                    (-d _)
                    ? Sidef::Types::Glob::Dir->new($dir)
                    : Sidef::Types::Glob::File->new(File::Spec->catfile($self->{dir}->get_value, $dfile))
                   );
        }

        return;
    }

    *read    = \&get_file;

    sub tell {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(telldir($self->{dir_h}));
    }

    sub seek {
        my ($self, $pos) = @_;
        Sidef::Types::Bool::Bool->new(seekdir($self->{dir_h}, $pos->get_value));
    }

    sub rewind {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(rewinddir($self->{dir_h}));
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

        require Encode;
        while (defined(my $file = CORE::readdir($self->{dir_h}))) {
            if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new(Encode::decode_utf8($file))))) {
                return $res;
            }
        }

        $self;
    }

};

1
