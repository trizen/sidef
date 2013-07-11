package Sidef::Types::Glob::Pipe {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        my (undef, @command) = @_;
        bless \@command, __PACKAGE__;
    }

    sub get_value {
        [map { $_->get_value } @{$_[0]}];
    }

    sub command {
        my ($self) = @_;

        $#{$self} == 0
          ? $self->[0]
          : Sidef::Types::Array::Array->new(@{$self});
    }

    sub open {
        my ($self, $mode) = @_;
        $mode = $$mode if ref($mode);

        open my $pipe_h, $mode, map { $_->get_value } @{$self};
        Sidef::Types::Glob::PipeHandle->new(pipe_h => $pipe_h, pipe => $self);
    }

    sub open_r {
        my ($self) = @_;
        $self->open('-|');
    }

    sub open_w {
        my ($self) = @_;
        $self->open('|-');
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Pipe.new(' . join(', ', map { $_->dump } @{$self}) . ')');
    }
}

1;
