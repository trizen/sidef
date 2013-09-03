package Sidef::Types::Bool::If {

    use 5.014;
    use strict;
    use warnings;

    no warnings 'recursion';

    our @ISA = qw(
      Sidef
      Sidef::Types::Block::Do
      );

    sub new {
        bless {do_block => 0}, __PACKAGE__;
    }

    sub if {
        my ($self, $arg) = @_;
        $self->{do_block} = Sidef::Types::Block::Code->new($arg)->run ? 1 : 0;
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
