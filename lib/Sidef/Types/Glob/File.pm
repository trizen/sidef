
use 5.014;
use strict;
use warnings;

package Sidef::Types::Glob::File {

    use Sidef::Init;

    sub new {
        my ($class, $file) = @_;

        bless {name => $file,}, $class;
    }

    sub size {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(-s $self->name);
    }

    sub name {
        $self->{name};
    }

    sub open {
        my ($self, $mode) = @_;
        $mode = ${$mode} if ref $mode;

        open my $fh, $mode, $self->name;
        Sidef::Types::Glob::FileHandle->new(fh   => $fh,
                                            name => $self->name,);
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
