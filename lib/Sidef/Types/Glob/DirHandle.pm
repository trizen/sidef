package Sidef::Types::Glob::DirHandle {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use Sidef::Types::Bool::Bool;

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

        state $_z1 = require Encode;
        state $_z2 = require File::Spec;

        my $basedir = (
            $self->{basedir} // do {
                $self->{basedir} = $self->{dir}->get_value;
              }
        );

        {
            my $file = CORE::readdir($self->{dir_h}) // return;

            if ($file eq '.' or $file eq '..') {
                redo;
            }

            my $dfile = Encode::decode_utf8($file);
            my $dir = File::Spec->catdir($basedir, $dfile);

            lstat($dir);
            if (-l _) { redo }
            ;    # ignore links

            return (
                    (-d _)
                    ? Sidef::Types::Glob::Dir->new($dir)
                    : Sidef::Types::Glob::File->new(File::Spec->catfile($basedir, $dfile))
                   );
        }

        return;
    }

    *read = \&get_file;

    sub tell {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(telldir($self->{dir_h}));
    }

    sub seek {
        my ($self, $pos) = @_;
        (
         seekdir(
             $self->{dir_h},
             do {
                 local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                 $pos->get_value;
               }
         )
        ) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub rewind {
        my ($self) = @_;
        (rewinddir($self->{dir_h})) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub close {
        my ($self) = @_;
        (closedir($self->{dir_h})) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub chdir {
        my ($self) = @_;
        (chdir($self->{dir_h})) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
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
