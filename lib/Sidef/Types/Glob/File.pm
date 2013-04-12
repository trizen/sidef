
use 5.014;
use strict;
use warnings;

package Sidef::Types::Glob::File {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my ($class, $file) = @_;
        bless \$file, $class;
    }

    sub size {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(-s $$self);
    }

    sub exists {
        my ($self) = @_;
        idef::Types::Bool::Bool->new(-e $$self);
    }

    sub is_binary {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-B $$self);
    }

    sub is_text {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(not $self->is_binary);
    }

    sub is_file {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-f $$self);
    }

    sub name {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }

    sub basename {
        my ($self) = @_;

        require File::Basename;
        Sidef::Types::String::String->new(File::Basename::basename($$self));
    }

    sub dirname {
        my ($self) = @_;

        require File::Basename;
        Sidef::Types::Glob::Dir->new(File::Basename::dirname($$self));
    }

    sub abs_name {
        my ($self) = @_;

        require Cwd;
        __PACKAGE__->new(Cwd::abs_path($$self));
    }

    sub open {
        my ($self, $mode) = @_;
        $mode = ${$mode} if ref $mode;

        open my $fh, $mode, $$self;
        Sidef::Types::Glob::FileHandle->new(fh   => $fh,
                                            file => $self,);
    }

    sub open_r {
        my ($self) = @_;
        $self->open('<');
    }

    sub open_w {
        my ($self) = @_;
        $self->open('>');
    }

    sub open_a {
        my ($self) = @_;
        $self->open('>>');
    }

};

1;
