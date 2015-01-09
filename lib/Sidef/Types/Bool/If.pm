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
        $self->{do_block} = $args[-1] ? 1 : 0;
        $self;
    }

    *call = \&if;

    sub elsif {
        my ($self, $code) = @_;
        $self->{do_block} = Sidef::Types::Block::Code->new($code)->run ? 1 : 0;
        $self;
    }

    *elseif = \&elsif;

    sub else {
        my ($self, $code) = @_;
        $self->{do_block} = 1;
        $self->do($code);
    }

};

1
