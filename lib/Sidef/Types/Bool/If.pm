
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::If {

    use parent qw(Sidef Sidef::Types::Block::Do);

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

};

1;
