
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Variable {

    sub new {
        my ($class, $var, $value) = @_;
        bless {
               name  => $var,
               value => $value,
              }, $class;
    }

    sub get_name {
        my ($self) = @_;
        return $self->{name};
    }

    sub set_value {
        my ($self, $value) = @_;
        $self->{value} = $value;
    }

    sub get_value {
        my ($self) = @_;
        return $self->{value};
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '='} = sub {
            my ($self, $obj) = @_;
            return $self->set_value($obj);
        };

    }

};

1;
