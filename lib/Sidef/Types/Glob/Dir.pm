
use 5.014;
use strict;
use warnings;

package Sidef::Types::Glob::Dir {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my ($class, $dir) = @_;
        bless \$dir, $class;
    }

    # Returns the parent of a directory
    sub parent {
        my ($self) = @_;

        require File::Basename;
        __PACKAGE__->new(File::Basename::dirname($$self));
    }

    # Remove a directory (works only on empty dirs)
    sub remove {
        my ($self) = @_;

        (rmdir $$self)
          ? Sidef::Types::Bool::Bool->true
          : Sidef::Types::Bool::Bool->false;
    }

    # Remove directory with all its content
    sub remove_tree {
        my ($self) = @_;

        require File::Path;
        File::Path::remove_tree($$self)
          ? Sidef::Types::Bool::Bool->true
          : Sidef::Types::Bool::Bool->false;
    }

    # Create a directory (with parents, if needed)
    sub create {
        my ($self) = @_;

        require File::Path;
        File::Path::make_path($$self)
          ? Sidef::Types::Bool::Bool->true
          : Sidef::Types::Bool::Bool->false;
    }

};

1;
