package Sidef::Types::Block::Switch {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      Sidef::Types::Block::Do
      );

    sub new {
        my (undef, $obj) = @_;
        bless {obj => $obj, do_block => 0}, __PACKAGE__;
    }

    sub when {
        my ($self, $arg) = @_;

        if (ref($self->{obj}) eq ref($arg)) {
            state $method = '==';

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

    sub case {
        my ($self, $arg) = @_;

        if (ref($arg) eq 'Sidef::Types::Bool::Bool') {
            if ($arg->is_true) {
                $self->{do_block} = 1;
            }
        }
        else {
            return $self->when($arg);
        }

        $self;
    }

    sub default {
        my ($self, $code) = @_;
        $self->{do_block} = 1;
        $self->do($code);
    }

    *else = \&default;

    sub end {
        Sidef::Types::Black::Hole->new;
    }

    sub value {
        my ($self) = @_;
        $self->{obj};
    }

}
