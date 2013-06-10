
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::Or {

    use parent qw(Sidef);

    sub new {
        my (undef, $val) = @_;
        bless \$val, __PACKAGE__;
    }

    sub true {
        __PACKAGE__->new('true');
    }

    sub false {
        __PACKAGE__->new('false');
    }

    sub is_true {
        Sidef::Types::Bool::Bool->new(${$_[0]} eq 'true');
    }

    sub is_false {
        Sidef::Types::Bool::Bool->new(${$_[0]} eq 'false');
    }

    sub or {
        my ($self, $code) = @_;

        if ($self->is_true) {
            return Sidef::Types::Bool::Bool->true;
        }

        $self->_is_code($code, 1, 1) ? $code->run() : $code;
    }

    sub else {
        my ($self, $code) = @_;
        Sidef::Types::Bool::Bool->new($self->is_true)->else($code);
    }
};

1;
