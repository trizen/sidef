package Sidef::Variable::Variable {

    use utf8;
    use 5.014;
    use strict;
    use warnings;

    no warnings 'recursion';

    #use overload q{""} => sub {
    #    $_[0]->get_value;
    #};

    our $AUTOLOAD;
    my $nil = Sidef::Types::Nil::Nil->new;

    sub new {
        my (undef, $var, $type, $value) = @_;

        bless {
               name  => $var,
               type  => $type,
               value => $value // $nil,
              },
          __PACKAGE__;
    }

    sub _is_defined {    # faster (used internally)
        my ($self) = @_;

        if (exists $self->{stack}) {
            $self = $self->{stack}[-1];
        }

        defined $self->{value}
          and ref($self->{value}) ne 'Sidef::Types::Nil::Nil';
    }

    sub is_defined {
        my ($self) = @_;

        if (exists $self->{stack}) {
            $self = $self->{stack}[-1];
        }

        Sidef::Types::Bool::Bool->new(defined $self->{value} and ref($self->{value}) ne 'Sidef::Types::Nil::Nil');
    }

    sub _get_name {
        $_[0]{name};
    }

    sub _stack_depth {
        my ($self) = @_;
        exists($self->{stack}) ? $#{$self->{stack}} + 1 : -1;
    }

    sub _stack_vals {
        my ($self) = @_;
        exists($self->{stack})
          ? Sidef::Types::Array::Array->new(map { $_->get_value } @{$self->{stack}})
          : ();
    }

    sub set_value {
        my ($self, $obj) = @_;

        if (exists $self->{stack}) {
            $self = $self->{stack}[-1];
        }

        $self->{value} = $obj;
    }

    sub get_value {
        my ($self) = @_;

        if (exists $self->{stack}) {
            $self = $self->{stack}[-1];
        }

        $self->{value};
    }

    sub get_type {
        my ($self) = @_;
        if (exists $self->{stack}) {
            $self = $self->{stack}[-1];
        }
        $self->{type};
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '='} = sub {
            my ($self, $obj) = @_;

            $#_ > 1 && ($obj = $_[-1]);

            if ($self->{type} eq "var" or $self->{type} eq "static") {
                return $self->set_value($obj);
            }
            elsif ($self->{type} eq "const") {
                if (not exists $self->{inited}) {
                    return $self->set_value($obj);
                }

                #warn "Constant '$self->{name}' cannot be changed.\n";
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

            $obj;
        };

        *{__PACKAGE__ . '::' . ':='} = sub {
            my ($self, $code) = @_;

            if (not $self->_is_defined) {
                my $method = '=';
                $self->$method(Sidef::Types::Block::Code->new($code)->run);
            }

            $self->new(rand, 'var', $self);
        };

        *{__PACKAGE__ . '::' . '\\\\'} = sub {
            my ($self, $code) = @_;

            if ($self->_is_defined) {
                return $self;
            }

            Sidef::Types::Block::Code->new($code)->run;
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

        foreach my $operator (qw(< > >= <= ^^ $$)) {

            *{__PACKAGE__ . '::' . '?' . $operator . '='} = sub {
                my ($self, $arg) = @_;

                if (ref($arg) and eval { $arg->can($operator) }) {
                    my $method = '=';
                    if ($arg->$operator($self->get_value)) {
                        $self->$method($arg);
                    }
                }
                else {
                    warn sprintf(qq{[WARN] Can't find the method "$operator" for %s!\n},
                                 defined($arg) ? ('object ' . ref($arg)) : 'an undefined object');
                }

                $self;
            };

            *{__PACKAGE__ . '::' . $operator . '?='} = sub {
                my ($self, $arg) = @_;

                my $value = $self->get_value;

                if (ref($value) and eval { $value->can($operator) }) {
                    my $method = '=';
                    if ($value->$operator($arg)) {
                        $self->$method($arg);
                    }
                }
                else {
                    warn sprintf(qq{[WARN] Can't find the method "$operator" for %s!\n},
                                 defined($arg) ? ('object ' . ref($arg)) : 'an undefined object');
                }

                $self;
            };
        }

        foreach my $operator (qw(+ - % * / & | ^ ** && || << >> ÷)) {

            *{__PACKAGE__ . '::' . $operator . '='} = sub {
                my ($self, $arg) = @_;

                my $value = $self->get_value;

                if (ref($value) and eval { $value->can($operator) }) {
                    my $method = '=';
                    $self->$method($self->get_value->$operator($arg));
                }
                else {
                    warn sprintf(qq{[WARN] Can't find the method "$operator" for %s!\n},
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

        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);
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
            elsif (substr($method, -1) eq '?') {
                $method_type = 3;
                chop $method;
            }
        }

        if (ref($value) && ($value->can($method) || $value->can('AUTOLOAD'))) {
            my @results = $value->$method(@args);

            if ($method_type == 1) {    # (!) modifies the variable in place
                my $method = '=';
                $self->$method(@results);
                return $self->new(rand, 'var', $self);
            }
            elsif ($method_type == 2) {    # (:) returns the self variable
                return $self->new(rand, 'var', $self);
            }
            elsif ($method_type == 3) {    # (?) asks for a boolean value
                my $result = $results[-1];
                return ref($result) eq 'Sidef::Types::Bool::Bool'
                  ? $result
                  : Sidef::Types::Bool::Bool->new($result);
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
