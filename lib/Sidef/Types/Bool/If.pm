package Sidef::Types::Bool::If {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      Sidef::Types::Block::Do
      );

    sub new {
        bless {do_block => 0}, __PACKAGE__;
    }

    sub if {
        my ($self, $arg) = @_;

        my $bool = Sidef::Types::Block::Code->new($arg)->run;
        $self->_is_bool($bool) || return $self;
        $self->{do_block} = $bool ? 1 : 0;

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

}
