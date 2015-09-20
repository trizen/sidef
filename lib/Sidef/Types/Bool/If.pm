package Sidef::Types::Bool::If {

    use 5.014;
    use parent qw(
      Sidef::Types::Block::Do
      );

    sub new {
        bless {do_block => 0}, __PACKAGE__;
    }

    sub if {
        my ($self, @args) = @_;
        ($self->{do_block} = $args[-2] ? 1 : 0) ? $self->do($args[-1]) : $self;
    }

    *call  = \&if;
    *elsif = \&if;

    sub else {
        my ($self, $code) = @_;
        $self->{do_block} = 1;
        $self->do($code);
    }

};

1
