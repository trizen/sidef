package Sidef::Types::Block::Try {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef);

    sub new {
        bless {catch => 0}, __PACKAGE__;
    }

    sub try {
        my ($self, $code) = @_;
        $self->_is_code($code) || return;

        my $error = 0;
        local $SIG{__WARN__} = sub { $error = 1 };

        $self->{val} = eval { $code->run };

        if ($@ || $error) {
            $self->{catch} = 1;
        }

        $self;
    }

    sub catch {
        my ($self, $code) = @_;
        $self->_is_code($code) || return;
        $self->{catch} ? $code->run : $self->{val};
    }

};

1
