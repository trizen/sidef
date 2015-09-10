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

            my $ref = ref($var);
            if ($ref eq 'Sidef::Variable::Variable' or $ref eq 'Sidef::Variable::ClassVar') {
                return $self->new($var);
            }

            warn sprintf("[WARN] '%s' is not a variable!\n", $ref);
            $self;
        };

        *{__PACKAGE__ . '::' . '*'} = sub {
            my ($self, $var_ref) = ($_[0], $_[-1]);

            if (ref($var_ref) eq ref($self)) {
                return $var_ref->{var};
            }

            warn sprintf("[WARN] '%s' is not a variable reference!\n", ref($var_ref));
            $self;
        };

        *{__PACKAGE__ . '::' . '='} = sub {
            my ($self, $value) = @_;
            state $method = '=';
            $self->{var}->$method($value);
        };

        foreach my $method (qw(-- ++)) {
            *{__PACKAGE__ . '::' . $method} = sub {
                my ($self, $var) = @_;
                $var = $var->{var} if ref($var) eq __PACKAGE__;
                if (ref($var) eq 'Sidef::Variable::Variable' or ref($var) eq 'Sidef::Variable::ClassVar') {
                    $var->$method;
                    $var->get_value;
                }
                else {
                    $var->$method;
                }
            };
        }

    }

    sub get_var {
        $_[0]{var};
    }

    sub lvalue {
        my ($self, $var) = @_;

        my $ref = ref($var);
        if ($ref eq 'Sidef::Variable::Variable' or $ref eq 'Sidef::Variable::ClassVar') {
            return $var->new(name => $var->{name}, type => $var->{type}, value => $var);
        }

        warn sprintf("[WARN] '%s' is not a variable!\n", $ref);
        $var;
    }

};

1;
