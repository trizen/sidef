
use 5.014;
use strict;
use warnings;

package Sidef::Types::Block::Switch {

    use parent qw(Sidef Sidef::Types::Block::Do);

    sub new {
        my (undef, $obj) = @_;
        bless {obj => $obj, do_block => 0}, __PACKAGE__;
    }

    sub when {
        my ($self, $arg) = @_;

        if (ref($arg) eq 'Sidef::Types::Block::Code') {
            $arg = $arg->run;
        }

        if (ref($self->{obj}) eq ref($arg)) {
            my ($method) = '==';

            if ($self->{obj}->can($method)) {
                if ($self->{obj}->$method($arg)) {
                    $self->{do_block} = 1;
                }
            }
            else {
                warn sprintf("[WARN]: when(): Can't find the equal (==) method for object '%s'!\n", ref($self->{obj}));
            }
        }

        $self;
    }

    sub default {
        my ($self, $code) = @_;
        $self->{do_block} = 1;
        $self->do($code);
    }

    sub end {
        my ($self) = @_;
        Sidef::Types::Black::Hole->new();
    }

    sub value {
        my ($self) = @_;
        $self->{obj};
    }

};

1;
