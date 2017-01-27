package Sidef::Types::Glob::DirHandle {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use Sidef::Types::Bool::Bool;

    sub new {
        my (undef, $dh, $dir) = @_;

        bless {
               dh  => $dh,
               dir => $dir,
              },
          __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        $_[0]{dh};
    }

    sub dir {
        $_[0]{dir};
    }

    sub get_files {
        my ($self) = @_;

        $self->rewind;

        my @files;
        while (defined(my $file = $self->read)) {
            push @files, $file;
        }
        Sidef::Types::Array::Array->new(\@files);
    }

    *read_dir = \&get_files;
    *readdir  = \&get_files;
    *entries  = \&get_files;

    sub get_file {
        my ($self) = @_;

        state $_z1 = require Encode;
        state $_z2 = require File::Spec;

        my $basedir = ($self->{basedir} //= "$self->{dir}");

        {
            my $file = CORE::readdir($self->{dh}) // return undef;

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

        return undef;
    }

    *read = \&get_file;

    sub tell {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(telldir($self->{dh}));
    }

    sub seek {
        my ($self, $pos) = @_;
        seekdir($self->{dh}, CORE::int($pos))
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub rewind {
        my ($self) = @_;
        rewinddir($self->{dh})
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub close {
        my ($self) = @_;
        closedir($self->{dh})
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub chdir {
        my ($self) = @_;
        CORE::chdir($self->{dh})
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub stat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->stat($self->{dh}, $self);
    }

    sub lstat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->lstat($self->{dh}, $self);
    }

    sub iter {
        my ($self) = @_;

        state $x = require Encode;
        Sidef::Types::Block::Block->new(
            code => sub {
                Sidef::Types::String::String->new(Encode::decode_utf8(CORE::readdir($self->{dh}) // return undef));
            }
        );
    }

    sub each {
        my ($self, $code) = @_;

        state $x = require Encode;
        while (defined(my $file = CORE::readdir($self->{dh}))) {
            $code->run(Sidef::Types::String::String->new(Encode::decode_utf8($file)));
        }

        $self;
    }

};

1
