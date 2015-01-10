package Sidef::Types::Glob::Dir {

    use 5.014;

    use parent qw(
      Sidef::Types::String::String
      );

    sub new {
        my (undef, $dir) = @_;
        ref($dir) && return $dir->to_dir;
        bless \$dir, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        ${$_[0]};
    }

    sub root {
        my ($self) = @_;

        require File::Spec;
        __PACKAGE__->new(File::Spec->rootdir);
    }

    *rootdir = \&root;

    sub home {
        my ($self) = @_;

        my $home =
             $ENV{HOME}
          || $ENV{LOGDIR}
          || (getpwuid($<))[7]
          || `echo -n ~`;

        defined($home) ? __PACKAGE__->new($home) : do {
            require File::HomeDir;
            __PACKAGE__->new(File::HomeDir->my_home);
        };
    }

    *homedir  = \&home;
    *home_dir = \&home;

    sub tmp {
        require File::Spec;
        __PACKAGE__->new(File::Spec->tmpdir);
    }

    *tmpdir   = \&tmp;
    *tempdir  = \&tmp;
    *temp     = \&tmp;
    *temp_dir = \&tmp;
    *tmp_dir  = \&tmp;

    sub cwd {
        require Cwd;
        __PACKAGE__->new(Cwd::getcwd());
    }

    *cur_dir           = \&cwd;
    *cur               = \&cwd;
    *current_directory = \&cwd;
    *current_dir       = \&cwd;

    sub pwd {
        require File::Spec;
        __PACKAGE__->new(File::Spec->curdir);
    }

    sub split {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        require File::Spec;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } File::Spec->splitdir($self->get_value));
    }

    # Returns the parent of the directory
    sub parent {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        require File::Basename;
        __PACKAGE__->new(File::Basename::dirname($self->get_value));
    }

    # Remove the directory (works only on empty dirs)
    sub remove {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(rmdir $self->get_value);
    }

    *delete = \&remove;
    *unlink = \&remove;

    # Remove the directory with all its content
    sub remove_tree {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        require File::Path;
        Sidef::Types::Bool::Bool->new(File::Path::remove_tree($self->get_value));
    }

    *removeTree = \&remove_tree;

    # Create directory without parents
    sub create {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(mkdir($self->get_value));
    }

    *make  = \&create;
    *mkdir = \&create;

    # Create the directory (with parents, if needed)
    sub create_tree {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        require File::Path;
        Sidef::Types::Bool::Bool->new(File::Path::make_path($self->get_value));
    }

    *createTree = \&create_tree;
    *makeTree   = \&create_tree;
    *make_tree  = \&create_tree;
    *mktree     = \&create_tree;
    *make_path  = \&create_tree;
    *mkpath     = \&create_tree;

    sub open {
        my ($self, $var_ref) = @_;

        if (@_ == 3) {
            ($self, $var_ref) = ($var_ref, $_[2]);
        }

        my $success = opendir(my $dir_h, $self->get_value);
        my $dir_obj = Sidef::Types::Glob::DirHandle->new(dir_h => $dir_h, dir => $self);

        if (defined $var_ref) {
            $var_ref->get_var->set_value($dir_obj);

            return $success
              ? Sidef::Types::Bool::Bool->true
              : Sidef::Types::Bool::Bool->false;
        }

        $success ? $dir_obj : ();
    }

    sub chdir {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(chdir($self->get_value));
    }

    sub chroot {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(chroot($self->get_value));
    }

    sub concat {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        require File::Spec;
        $file->new(File::Spec->catdir($self->get_value, $file->get_value));
    }

    *catfile = \&concat;

    sub is_empty {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        CORE::opendir(my $dir_h, $self->get_value) || return;
        while (defined(my $file = CORE::readdir $dir_h)) {
            next if $file eq '.' or $file eq '..';
            return Sidef::Types::Bool::Bool->false;
        }
        Sidef::Types::Bool::Bool->true;
    }

    *isEmpty = \&is_empty;

    # exists
    *exists = \&Sidef::Types::Glob::File::exists;

    # is_dir
    *is_directory = \&Sidef::Types::Glob::File::is_directory;
    *is_dir       = \&is_directory;
    *isDir        = \&is_directory;
    *isDirectory  = \&is_directory;

    # readlink
    *readlink = \&Sidef::Types::Glob::File::readlink;
    *readLink = \&readlink;

    # utime
    *utime = \&Sidef::Types::Glob::File::utime;

    # stat/lstat
    *stat  = \&Sidef::Types::Glob::File::stat;
    *lstat = \&Sidef::Types::Glob::File::lstat;

    # rel_name
    *rel_name = \&Sidef::Types::Glob::File::rel_name;
    *rel      = \&rel_name;
    *relname  = \&rel_name;
    *relName  = \&rel_name;
    *abs2rel  = \&rel_name;

    # abs_name
    *abs_name = \&Sidef::Types::Glob::File::abs_name;
    *abs      = \&abs_name;
    *absname  = \&abs_name;
    *absName  = \&abs_name;
    *rel2abs  = \&abs_name;
    *abs_path = \&abs_name;
    *absPath  = \&abs_name;

    # is abs
    *is_absolute = \&Sidef::Types::Glob::File::is_absolute;
    *is_abs      = \&is_absolute;

    # rename
    *rename    = \&Sidef::Types::Glob::File::rename;
    *rename_to = \&rename;
    *renameTo  = \&rename;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Dir.new(' . ${Sidef::Types::String::String->new($self->get_value)->dump} . ')');
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+'} = \&concat;
    }

};

1
