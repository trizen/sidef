
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::If {

    use parent qw(Sidef Sidef::Types::Block::Do);

    require Sidef::Exec;
    my $exec = Sidef::Exec->new();

    sub new {
        bless {do_block => 0}, __PACKAGE__;
    }

    sub if {
        my ($self, $arg) = @_;

        my @results = $exec->execute(struct => $arg);
        my $bool = $results[-1];

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

};

1;
