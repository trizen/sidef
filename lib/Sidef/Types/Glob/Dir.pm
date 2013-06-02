
use 5.014;
use strict;
use warnings;

package Sidef::Types::Glob::Dir {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my ($class, $dir) = @_;
        $dir = $$dir if ref $dir;
        bless \$dir, $class;
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

    # Create directory without parents
    sub create {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(mkdir($$self));
    }

    # Create the directory (with parents, if needed)
    sub create_tree {
        my ($self) = @_;

        require File::Path;
        Sidef::Types::Bool::Bool->new(File::Path::make_path($$self));
    }

    sub abs_name {
        my ($self) = @_;

        require File::Spec;
        __PACKAGE__->new(File::Spec->rel2abs($$self));
    }

};

1;
