
use 5.014;
use strict;
use warnings;
no warnings 'recursion';

package Sidef::Types::Bool::While {

    use parent qw(Sidef);
    require Sidef::Types::Block::Do;

    sub new {
        bless {do_block => 0}, __PACKAGE__;
    }

    sub while {
        my ($self, $code) = @_;

        $self->_is_code($code) || return $self;
        $self->{code} = $code;

        my $bool = $code->run;
        $self->_is_bool($bool) || return $self;

        $self->{do_block} = $bool ? 1 : 0;

        defined $self->{do_code} ? $self->do($self->{do_code}) : $self;
    }

    sub do {
        my ($self, $code) = @_;

        if ($self->{do_block}) {
            my $do = Sidef::Types::Block::Do->new;
            $do->{do_block} = $self->{do_block};
            $do->do($code);

            $self->{do_code} = $code;
            $self->while($self->{code});
        }

        $self;
    }
};

1;
