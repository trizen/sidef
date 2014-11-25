package Sidef::Variable::Ref {

    use 5.014;

    sub new {
        my (undef, $var) = @_;
        bless {var => $var}, __PACKAGE__;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '\\'} = *{__PACKAGE__ . '::' . '&'} = sub {
            my ($self, $var) = ($_[0], $_[-1]);

            if (ref $var eq 'Sidef::Variable::Variable') {
                return $self->new($var);
            }

            warn sprintf("[WARN] '%s' is not a variable!\n", ref($var));
            $self;
        };

        *{__PACKAGE__ . '::' . '*'} = sub {
            my ($self, $var_ref) = ($_[0], $_[-1]);

            if (ref($var_ref) eq 'Sidef::Variable::Variable') {
                $var_ref = $var_ref->get_value;
            }

            if (ref($var_ref) eq ref($self)) {
                return Sidef::Variable::Variable->new(name => '', type => 'var', value => $var_ref->{var});
            }

            warn sprintf("[WARN] '%s' is not a variable reference!\n", ref($var_ref));
            $self;
        };

        foreach my $method (qw(-- ++)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                $_[0]->{var}->$method;
            };
        }

    }

    sub get_var {
        $_[0]{var};
    }

};

1;
