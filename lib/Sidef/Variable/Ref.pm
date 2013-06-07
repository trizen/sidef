
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Ref {

    sub new {
        my ($class, $var) = @_;
        $class = ref($class) if ref($class);
        bless {var => $var}, $class;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '\\'} = sub {
            my ($self, $var) = @_;

            if (ref $var eq 'Sidef::Variable::Variable') {
                return $self->new($var);
            }
            else {
                warn sprintf("[WARN] '%s' is not a variable object!\n", ref($var));
            }

            $self;
        };

        *{__PACKAGE__ . '::' . '*'} = sub {
            my ($self, $var_ref) = @_;

            if (ref($var_ref) eq 'Sidef::Variable::Variable' and ref($var_ref->get_value) eq ref($self)) {
                return Sidef::Variable::Variable->new(rand, 'var', $var_ref->get_value->{var});
            }
            else {
                warn sprintf("[WARN] '%s' is not a reference object!\n", ref($var_ref));
            }

            $self;
        };
    }

    sub get_var {
        my ($self) = @_;
        $self->{var};
    }

};

1;
