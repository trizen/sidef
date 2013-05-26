
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Variable {

    use overload q{""} => sub {
        $_[0]->get_value;
    };

    sub new {
        my ($class, $var, $type, $value) = @_;

        bless {
               name  => $var,
               type  => $type,
               value => $value,
              }, $class;
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
                warn "Constant $self->{name} cannot be changed.\n";
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
            else {
                warn "Invalid type: $self->{type}.\n";
            }
        };

        *{__PACKAGE__ . '::' . ':='} = sub {
            my ($self, $obj) = @_;

            if (not defined $self->{value} or ref $self->{value} eq 'Sidef::Types::Nil::Nil') {
                my $method = \&{__PACKAGE__ . '::' . '='};
                return $self->$method($obj);
            }

            return $self->{value};
        };

        *{__PACKAGE__ . '::' . '+='} = sub {
            my ($self, $arg) = @_;

            my ($method) = '+';
            $self->set_value($self->get_value->$method($arg));
            $self;
        };

        *{__PACKAGE__ . '::' . '-='} = sub {
            my ($self, $arg) = @_;

            my ($method) = '-';
            $self->set_value($self->get_value->$method($arg));
            $self;
        };

        *{__PACKAGE__ . '::' . '%='} = sub {
            my ($self, $arg) = @_;

            my ($method) = '%';
            $self->set_value($self->get_value->$method($arg));
            $self;
        };

        *{__PACKAGE__ . '::' . '*='} = sub {
            my ($self, $arg) = @_;

            my ($method) = '*';
            $self->set_value($self->get_value->$method($arg));
            $self;
        };

        *{__PACKAGE__ . '::' . '/='} = sub {
            my ($self, $arg) = @_;

            my ($method) = '/';
            $self->set_value($self->get_value->$method($arg));
            $self;
        };

        *{__PACKAGE__ . '::' . '**='} = sub {
            my ($self, $arg) = @_;

            my ($method) = '**';
            $self->set_value($self->get_value->$method($arg));
            $self;
        };

        *{__PACKAGE__ . '::' . '++'} = sub {
            my ($self) = @_;

            my ($method) = '+';
            $self->set_value($self->get_value->$method(Sidef::Types::Number::Number->new(1)));
            $self;
        };

        *{__PACKAGE__ . '::' . '--'} = sub {
            my ($self) = @_;

            my ($method) = '-';
            $self->set_value($self->get_value->$method(Sidef::Types::Number::Number->new(1)));
            $self;
        };

    }
};

1;
