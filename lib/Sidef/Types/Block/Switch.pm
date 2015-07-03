package Sidef::Types::Block::Switch {

    use 5.014;
    use parent qw(
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
            if ($self->{obj}->$method($arg)->get_value) {
                $self->{do_block} = 1;
            }
        }

        $self;
    }

    sub case {
        my ($self, $arg) = @_;

        if (ref($arg) eq 'Sidef::Types::Bool::Bool') {
            if ($arg->get_value) {
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
        $code // return $self;
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

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '>'} = \&when;
        *{__PACKAGE__ . '::' . '?'} = \&case;
        *{__PACKAGE__ . '::' . ':'} = \&default;
    }

};

1
