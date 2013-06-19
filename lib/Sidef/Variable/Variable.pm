
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Variable {

    use overload q{""} => sub {
        $_[0]->get_value;
    };

    sub new {
        my (undef, $var, $type, $value) = @_;

        bless {
               name  => $var,
               type  => $type,
               value => $value,
              },
          __PACKAGE__;
    }

    sub is_defined {
        my ($self) = @_;
        defined $self->{value}
          and ref $self->{value} ne 'Sidef::Types::Nil::Nil';
    }

    sub get_name {
        my ($self) = @_;
        $self->{name};
    }

    sub set_value {
        my ($self, $value) = @_;
        $self->{value} = $value;
    }

    sub get_value {
        my ($self) = @_;
        $self->{value};
    }

    sub get_type {
        my ($self) = @_;
        $self->{type};
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '='} = sub {
            my ($self, $obj) = @_;

            if ($self->{type} eq "const") {
                if (not defined $self->{value}) {
                    return $self->set_value($obj);
                }
                warn "Constant '$self->{name}' cannot be changed.\n";
            }
            elsif ($self->{type} eq "var") {
                return $self->set_value($obj);
            }
            elsif ($self->{type} eq "char") {
                return $self->set_value($obj->to_chars);
            }
            elsif ($self->{type} eq "byte") {
                return $self->set_value($obj->to_bytes);
            }
            elsif ($self->{type} eq 'func') {
                if (ref $obj eq 'Sidef::Types::Block::Code') {
                    return $self->set_value($obj);
                }
                warn "Can't assign the '", ref($obj), "' object to the function '$self->{name}'!\n"
                  . "I was expecting an object of type 'Sidef::Types::Block::Code' instead.\n";
            }
            else {
                warn "Invalid variable type: '$self->{type}'.\n";
            }

            return $obj;
        };

        *{__PACKAGE__ . '::' . ':='} = sub {
            my ($self, $obj) = @_;

            if (not $self->is_defined) {
                my $method = \&{__PACKAGE__ . '::' . '='};
                return $self->$method($obj);
            }

            return $self->{value};
        };

        *{__PACKAGE__ . '::' . '\\\\'} = sub {
            my ($self, $arg) = @_;
            if ($self->is_defined) {
                return $self;
            }
            return $arg;
        };

        *{__PACKAGE__ . '::' . '++'} = sub {
            my ($self, $arg) = @_;

            my ($method) = '++';
            $self->set_value($self->get_value->$method($arg));
            $self;
        };

        *{__PACKAGE__ . '::' . '--'} = sub {
            my ($self) = @_;

            my ($method) = '--';
            $self->set_value($self->get_value->$method);
            $self;
        };

        foreach my $operator (qw(+ - % * / & | ^ ** && || )) {

            *{__PACKAGE__ . '::' . $operator . '='} = sub {
                my ($self, $arg) = @_;

                my $value = $self->get_value;
                if (defined $value and $value->can($operator)) {
                    $self->set_value($self->get_value->$operator($arg));
                }
                else {
                    warn sprintf("[WARN] Can't find the method $operator= for %s!\n",
                                 defined($value) ? ('object ' . ref($value)) : 'an undefined object');
                }
                $self;
            };

        }

    }
};

1;
