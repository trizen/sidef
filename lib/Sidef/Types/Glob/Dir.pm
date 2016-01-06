package Sidef::Types::Glob::Dir {

    use 5.014;

    use parent qw(
      Sidef::Convert::Convert
      Sidef::Types::Glob::File
      );

    sub new {
        my (undef, $dir) = @_;
        if (@_ > 2) {
            state $x = require File::Spec;
            $dir = File::Spec->catdir(map { ref($_) ? $_->to_dir->get_value : $_ } @_[1 .. $#_]);
        }
        elsif (ref($dir)) {
            return $dir->to_dir;
        }
        bless \$dir, __PACKAGE__;
    }

    *call = \&new;

    sub get_value { ${$_[0]} }
    sub to_dir    { $_[0] }

    sub root {
        my ($self) = @_;

        state $x = require File::Spec;
        __PACKAGE__->new(File::Spec->rootdir);
    }

    sub home {
        my ($self) = @_;

        my $home =
             $ENV{HOME}
          || $ENV{LOGDIR}
          || (getpwuid($<))[7]
          || `echo -n ~`;

        defined($home) ? __PACKAGE__->new($home) : do {
            state $x = require File::HomeDir;
            __PACKAGE__->new(File::HomeDir->my_home);
        };
    }

    sub tmp {
        state $x = require File::Spec;
        __PACKAGE__->new(File::Spec->tmpdir);
    }

    *temp = \&tmp;

    sub cwd {
        state $x = require Cwd;
        __PACKAGE__->new(Cwd::getcwd());
    }

    sub pwd {
        state $x = require File::Spec;
        __PACKAGE__->new(File::Spec->curdir);
    }

    sub split {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        state $x = require File::Spec;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } File::Spec->splitdir($self->get_value));
    }

    # Returns the parent of the directory
    sub parent {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        state $x = require File::Basename;
        __PACKAGE__->new(File::Basename::dirname($self->get_value));
    }

    # Remove the directory (works only on empty dirs)
    sub remove {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (rmdir $self->get_value) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *delete = \&remove;
    *unlink = \&remove;

    # Remove the directory with all its content
    sub remove_tree {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        state $x = require File::Path;
        (File::Path::remove_tree($self->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    # Create directory without parents
    sub create {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (mkdir($self->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *make  = \&create;
    *mkdir = \&create;

    # Create the directory (with parents, if needed)
    sub create_tree {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        state $x = require File::Path;
        my $path = $self->get_value;
        -d $path                           ? (Sidef::Types::Bool::Bool::TRUE)
          : (File::Path::make_path($path)) ? (Sidef::Types::Bool::Bool::TRUE)
          :                                  (Sidef::Types::Bool::Bool::FALSE);
    }

    *make_tree = \&create_tree;
    *mktree    = \&create_tree;
    *make_path = \&create_tree;
    *mkpath    = \&create_tree;

    sub open {
        my ($self, $fh_ref, $err_ref) = @_;

        my $success = opendir(my $dir_h, $self->get_value);
        my $error   = $!;
        my $dir_obj = Sidef::Types::Glob::DirHandle->new(dir_h => $dir_h, dir => $self);

        if (defined $fh_ref) {
            ${$fh_ref} = $dir_obj;

            return $success
              ? (Sidef::Types::Bool::Bool::TRUE)
              : do {
                defined($err_ref) && do { ${$err_ref} = Sidef::Types::String::String->new($error) };
                (Sidef::Types::Bool::Bool::FALSE);
              };
        }

        $success ? $dir_obj : ();
    }

    *open_r = \&open;

    sub open_w  { ... }
    sub open_rw { ... }

    sub chdir {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (chdir($self->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub chroot {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (chroot($self->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub concat {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        state $x = require File::Spec;
        $file->new(File::Spec->catdir($self->get_value, $file->get_value));
    }

    *catfile = \&concat;

    sub is_empty {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        CORE::opendir(my $dir_h, $self->get_value) || return;
        while (defined(my $file = CORE::readdir $dir_h)) {
            next if $file eq '.' or $file eq '..';
            return (Sidef::Types::Bool::Bool::FALSE);
        }
        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Dir(' . ${Sidef::Types::String::String->new($self->get_value)->dump} . ')');
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+'} = \&concat;
    }

};

1
