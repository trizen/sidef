
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::Or {

    require Sidef::Exec;
    my $exec = Sidef::Exec->new();

    sub new {
        my ($class, $val) = @_;
        bless \$val, $class;
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

        my @results = $exec->execute(struct => $code);
        return $results[-1];
    }

    sub else {
        my ($self, $code) = @_;
        Sidef::Types::Bool::Bool->new($self->is_true)->else($code);
    }
};

1;
