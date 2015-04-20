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

        require Encode;
        require File::Spec;

        Sidef::Types::Array::Array->new(
            map {
                my $dir = File::Spec->catdir($self->{dir}, $_);
                (-d $dir)
                  ? Sidef::Types::Glob::Dir->new(Encode::decode_utf8($dir))
                  : Sidef::Types::Glob::File->new(Encode::decode_utf8(File::Spec->catfile($self->{dir}, $_)));
              } readdir($self->{dir_h})
        );
    }

    *getFiles = \&get_files;
    *read_dir = \&get_files;
    *readdir  = \&get_files;
    *readDir  = \&get_files;
    *entries  = \&get_files;

    sub get_file {
        my ($self) = @_;

        if (defined(my $file = CORE::readdir($self->{dir_h}))) {

            require Encode;
            require File::Spec;
            my $dir = File::Spec->catdir($self->{dir}, $file);
            return (
                    (-d $dir)
                    ? Sidef::Types::Glob::Dir->new(Encode::decode_utf8($dir))
                    : Sidef::Types::Glob::File->new(Encode::decode_utf8(File::Spec->catfile($self->{dir}, $file)))
                   );
        }

        return;
    }

    *getFile = \&get_file;
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
        my ($var_ref) = $code->init_block_vars();

        require Encode;
        while (defined(my $file = CORE::readdir($self->{dir_h}))) {
            $var_ref->set_value(Sidef::Types::String::String->new(Encode::decode_utf8($file)));
            if (defined(my $res = $code->_run_code)) {
                $code->pop_stack();
                return $res;
            }
        }

        $code->pop_stack();
        $self;
    }

};

1
