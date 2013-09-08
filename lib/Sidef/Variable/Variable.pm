package Sidef::Variable::Variable {

    use utf8;
    use 5.014;
    use strict;
    use warnings;

    no warnings 'recursion';

    use overload q{""} => sub {
        $_[0]->get_value;
    };

    our $AUTOLOAD;

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
          and ref($self->{value}) ne 'Sidef::Types::Nil::Nil';
    }

    sub _get_name {
        $_[0]{name};
    }

    sub set_value {
        $_[0]{value} = $_[1];
    }

    sub get_value {
        $_[0]{value};
    }

    sub get_type {
        $_[0]{type};
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '='} = sub {
            my ($self, $obj) = @_;

            $#_ > 1 && ($obj = $_[-1]);

            if ($self->{type} eq "var") {
                return $self->set_value($obj);
            }
            elsif ($self->{type} eq "const") {
                if (not defined $self->{value}) {
                    return $self->set_value($obj);
                }

                #warn "Constant '$self->{name}' cannot be changed.\n";
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
                  . "An object of type 'Sidef::Types::Block::Code' was expected.\n";
            }
            else {
                warn "Invalid variable type: '$self->{type}'.\n";
            }

            return $obj;
        };

        *{__PACKAGE__ . '::' . ':='} = sub {
            my ($self, $code) = @_;

            if (not $self->is_defined) {
                my $method = '=';
                return $self->$method(Sidef::Types::Block::Code->new($code)->run);
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

        foreach my $operator (qw(-- ++)) {
            *{__PACKAGE__ . '::' . $operator} = sub {
                my ($self, $arg) = @_;

                my ($method) = '=';
                my $value = $self->get_value;

                if (ref($value) and eval { $value->can($operator) }) {
                    $self->$method($self->get_value->$operator($arg));
                }
                else {
                    warn sprintf(qq{[WARN] Can't find the method "$operator" for %s!\n},
                                 defined($value) ? ('object ' . ref($value)) : 'an undefined object');
                }

                $self;
            };
        }

        foreach my $operator (qw(+ - % * / & | ^ ** && || << >> ÷)) {

            *{__PACKAGE__ . '::' . $operator . '='} = sub {
                my ($self, $arg) = @_;

                my $method = '=';
                my $value  = $self->get_value;

                if (ref($value) and eval { $value->can($operator) }) {
                    $self->$method($self->get_value->$operator($arg));
                }
                else {
                    warn sprintf(qq{[WARN] Can't find the method "$operator=" for %s!\n},
                                 defined($value) ? ('object ' . ref($value)) : 'an undefined object');
                }
                $self;
            };
        }

    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        #if ($AUTOLOAD eq __PACKAGE__ . '::') {
        #    return $self;
        #}

        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.+)$/);
        my $value = $self->get_value;

        my $method_type = 0;
        if ($method =~ /^[[:alpha:]]/) {
            if (substr($method, -1) eq '!') {
                $method_type = 1;
                chop $method;
            }
            elsif (substr($method, -1) eq ':') {
                $method_type = 2;
                chop $method;
            }
        }

        if (ref($value) && ($value->can($method) || $value->can('AUTOLOAD'))) {
            my @results = $value->$method(@args);

            if ($method_type == 1) {
                my $method = '=';
                $self->$method(@results);
                return $self->new(rand, 'var', $self);
            }
            elsif ($method_type == 2) {
                return $self->new(rand, 'var', $self);
            }

            return $results[-1];
        }
        else {
            warn qq{[WARN] Inexistent method '$method' for }
              . (
                 ref($value)
                 ? ("object " . ref($value))
                 : ("an undefined object!")
                )
              . "\n";
        }

        return;
    }
};

1;
