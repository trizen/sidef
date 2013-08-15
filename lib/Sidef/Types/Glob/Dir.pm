package Sidef::Types::Glob::Dir {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef::Convert::Convert);

    sub new {
        my (undef, $dir) = @_;
        $dir = $$dir if ref $dir;
        bless \$dir, __PACKAGE__;
    }

    sub get_value {
        ${$_[0]};
    }

    sub exists {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-e $$self);
    }

    sub split {
        my ($self) = @_;

        require File::Spec;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } File::Spec->splitdir($$self));
    }

    # Returns the parent of the directory
    sub parent {
        my ($self) = @_;

        require File::Basename;
        __PACKAGE__->new(File::Basename::dirname($$self));
    }

    # Remove the directory (works only on empty dirs)
    sub remove {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(rmdir $$self);
    }

    # Remove the directory with all its content
    sub remove_tree {
        my ($self) = @_;

        require File::Path;
        Sidef::Types::Bool::Bool->new(File::Path::remove_tree($$self));
    }

    *removeTree = \&remove_tree;

    # Create directory without parents
    sub create {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(mkdir($$self));
    }

    *make = \&create;

    # Create the directory (with parents, if needed)
    sub create_tree {
        my ($self) = @_;

        require File::Path;
        Sidef::Types::Bool::Bool->new(File::Path::make_path($$self));
    }

    *createTree = \&create_tree;
    *makeTree   = \&create_tree;
    *make_tree  = \&create_tree;

    sub abs_name {
        my ($self) = @_;

        require File::Spec;
        __PACKAGE__->new(File::Spec->rel2abs($$self));
    }

    *absName  = \&abs_name;
    *abs_path = \&abs_name;
    *absPath  = \&abs_name;

    sub open {
        my ($self) = @_;

        opendir(my $dir_h, $$self) or return;
        Sidef::Types::Glob::DirHandle->new(dir_h => $dir_h, dir => $self);
    }

    sub chdir {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(chdir($$self));
    }

    sub chroot {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(chroot($$self));
    }

    *readlink = \&Sidef::Types::Glob::File::readlink;
    *readLink = \&readlink;

    *utime = \&Sidef::Types::Glob::File::utime;

    *stat  = \&Sidef::Types::Glob::File::stat;
    *lstat = \&Sidef::Types::Glob::File::lstat;
}
