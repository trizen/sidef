package Sidef::Types::Glob::Dir {

    use 5.014;

    use parent qw(Sidef::Types::Glob::File);

    sub new {
        my (undef, $dir) = @_;
        if (@_ > 2) {
            shift(@_);
            state $x = require File::Spec;
            $dir = File::Spec->catdir(map { "$_" } @_);
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

    sub up {
        my ($self) = @_;
        state $x = require File::Spec;
        __PACKAGE__->new(File::Spec->catdir(ref($self) ? $$self : (), File::Spec->updir));
    }

    sub split {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        state $x = require File::Spec;
        Sidef::Types::Array::Array->new([map { Sidef::Types::String::String->new($_) } File::Spec->splitdir("$self")]);
    }

    # Returns the parent of the directory
    sub parent {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        state $x = require File::Basename;
        __PACKAGE__->new(File::Basename::dirname("$self"));
    }

    # Remove the directory (works only on empty dirs)
    sub remove {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        CORE::rmdir("$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *delete = \&remove;
    *unlink = \&remove;

    # Remove the directory with all its content
    sub remove_tree {
        ref($_[0]) || shift(@_);
        my ($self) = @_;

        state $x = require File::Path;
        (File::Path::remove_tree("$self")) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    # Create directory without parents
    sub create {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (CORE::mkdir("$self")) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *make  = \&create;
    *mkdir = \&create;

    # Create the directory (with parents, if needed)
    sub create_tree {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        state $x = require File::Path;
        my $path = "$self";
        -d $path                           ? (Sidef::Types::Bool::Bool::TRUE)
          : (File::Path::make_path($path)) ? (Sidef::Types::Bool::Bool::TRUE)
          :                                  (Sidef::Types::Bool::Bool::FALSE);
    }

    *make_tree = \&create_tree;
    *mktree    = \&create_tree;
    *make_path = \&create_tree;
    *mkpath    = \&create_tree;

    sub open {
        ref($_[0]) || shift(@_);
        my ($self, $fh_ref, $err_ref) = @_;

        my $success = opendir(my $dir_h, "$self");
        my $error   = $!;
        my $dir_obj = Sidef::Types::Glob::DirHandle->new($dir_h, $self);

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
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (chdir("$self")) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub chroot {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (chroot("$self")) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub concat {
        ref($_[0]) || shift(@_);
        my ($self, $file) = @_;

        state $x = require File::Spec;
        ref($file) eq 'Sidef::Types::Glob::File'
          ? $file->new(File::Spec->catfile("$self", "$file"))
          : __PACKAGE__->new(File::Spec->catdir("$self", "$file"));
    }

    *catfile = \&concat;

    sub is_empty {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        CORE::opendir(my $dir_h, "$self") || return undef;
        while (defined(my $file = CORE::readdir $dir_h)) {
            next if $file eq '.' or $file eq '..';
            return (Sidef::Types::Bool::Bool::FALSE);
        }
        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Dir(' . ${Sidef::Types::String::String->new("$self")->dump} . ')');
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+'} = \&concat;
    }

};

1
