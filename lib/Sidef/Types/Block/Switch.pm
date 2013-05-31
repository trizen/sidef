
use 5.014;
use strict;
use warnings;

package Sidef::Types::Block::Switch {

    require Sidef::Exec;
    my $exec = Sidef::Exec->new();

    sub new {
        my ($class, $obj) = @_;
        bless {obj => $obj, continue => 1, do_block => 0}, $class;
    }

    sub when {
        my ($self, $arg) = @_;

        return $self if not $self->{continue};

        if (ref $arg eq 'Sidef::Types::Block::Code') {
            my @results = $exec->execute(struct => $arg);
            $arg = $results[-1];
        }

        if (ref($self->{obj}) eq ref($arg)) {
            my ($method) = '==';

            if ($self->{obj}->$method($arg)) {
                $self->{continue} = 0;
                $self->{do_block} = 1;
                return $self;
            }
        }

        $self->{continue} = 1;
        return $self;
    }

    sub do {
        my ($self, $block) = @_;

        if ($self->{do_block}) {
            $self->{do_block} = 0;
            $exec->execute(struct => $block);
        }

        return $self;
    }

    sub default {
        my ($self, $code) = @_;

        if ($self->{continue}) {
            $self->{continue} = 0;
            $exec->execute(struct => $code);
        }

        $self;
    }

    sub end {
        my ($self) = @_;
        $self->{continue} = 0;
        $self->{do_block} = 0;
        $self;
    }

    sub value {
        my ($self) = @_;
        $self->{obj};
    }

};

1;
