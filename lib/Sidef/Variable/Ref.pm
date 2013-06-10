
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Ref {

    sub new {
        my (undef, $var) = @_;
        bless {var => $var}, __PACKAGE__;
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

            if (ref($var_ref) eq 'Sidef::Variable::Variable') {
                $var_ref = $var_ref->get_value;
            }

            if (ref($var_ref) eq ref($self)) {
                return Sidef::Variable::Variable->new(rand, 'var', $var_ref->{var});
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
