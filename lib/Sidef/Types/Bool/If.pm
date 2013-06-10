
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::If {

    use parent qw(Sidef);

    sub new {
        bless {do_block => 0}, __PACKAGE__;
    }

    sub if {
        my ($self, $arg) = @_;

        if ($self->_is_code($arg, 1, 1)) {
            $arg = $arg->run;
        }

        $self->_is_bool($arg) || return $self;
        $self->{do_block} = $arg ? 1 : 0;

        $self;
    }

    sub elsif {
        my ($self, $code) = @_;
        $self->if($code);
    }

    sub else {
        my ($self, $code) = @_;
        $self->{do_block} = 1;
        $self->do($code);
    }

    sub do {
        my ($self, $code) = @_;

        $self->_is_code($code) || do {
            $self->{do_block} = 0;
            return $self;
        };

        if ($self->{do_block}) {
            if(ref($code->run) eq 'Sidef::Types::Block::Continue'){
                $self->{do_block} = 0;
                return $self;
            }
            return Sidef::Types::Black::Hole->new();
        }

        $self;
    }

};

1;
