package Sidef::Types::Glob::Dir {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Glob::File
    );

    require Encode;
    require File::Spec;

    sub new {
        my (undef, $dir) = @_;
        if (@_ > 2) {
            shift(@_);
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
        __PACKAGE__->new(File::Spec->rootdir);
    }

    sub home {
        my ($self) = @_;

        my $home = $ENV{HOME} || $ENV{LOGDIR};

        if (not $home and $^O ne 'MSWin32') {
            $home = (getpwuid($<))[7];
        }

        $home ? __PACKAGE__->new($home) : do {
            state $x = require File::HomeDir;
            __PACKAGE__->new(File::HomeDir->my_home);
        };
    }

    sub tmp {
        __PACKAGE__->new(File::Spec->tmpdir);
    }

    *temp = \&tmp;

    sub mktemp {
        my ($self, %opts) = @_;
        state $x = require File::Temp;
        __PACKAGE__->new(File::Temp::tempdir(CLEANUP => 1, %opts));
    }

    *make_tmp  = \&mktemp;
    *make_temp = \&mktemp;

    sub find {
        my ($self, $arg) = @_;
        state $x = require File::Find;

        my @files;
        my $ref      = ref($arg // '');
        my $is_block = $ref eq 'Sidef::Types::Block::Block';

        File::Find::find(
            sub {
                my $file = Encode::decode_utf8($File::Find::name);

                if (-d $file) {
                    $file = __PACKAGE__->new($file);
                }
                else {
                    $file = Sidef::Types::Glob::File->new($file);
                }

                $is_block ? $arg->run($file) : push(@files, $file);
            },
            $$self
        );

        $is_block ? $self : Sidef::Types::Array::Array->new(\@files);
    }

    *browse = \&find;

    sub cwd {
        state $x = require Cwd;
        __PACKAGE__->new(Encode::decode_utf8(Cwd::getcwd()));
    }

    sub pwd {
        __PACKAGE__->new(File::Spec->curdir);
    }

    sub up {
        my ($self) = @_;
        __PACKAGE__->new(Encode::decode_utf8(File::Spec->catdir(ref($self) ? Encode::encode_utf8($$self) : (), File::Spec->updir)));
    }

    sub split {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
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

        $success ? $dir_obj : undef;
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

    sub to_str {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }

    *to_s = \&to_str;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+'} = \&concat;
    }

};

1
