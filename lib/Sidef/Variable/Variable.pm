package Sidef::Variable::Variable {

    use utf8;
    use 5.014;

    use overload q{""} => sub {
        $_[0]->get_value;
    };

    our $AUTOLOAD;
    my $nil = Sidef::Types::Nil::Nil->new;

    sub new {
        my (undef, %opt) = @_;
        $opt{value} //= $nil;
        bless \%opt, __PACKAGE__;
    }

    sub _is_defined {    # faster (used internally)
        my ($self) = @_;

        exists($self->{stack}) && do {
            $self = $self->{stack}[-1];
        };

        ref($self->{value}) ne 'Sidef::Types::Nil::Nil';
    }

    sub is_defined {
        my ($self) = @_;

        exists($self->{stack}) && do {
            $self = $self->{stack}[-1];
        };

        Sidef::Types::Bool::Bool->new(ref($self->{value}) ne 'Sidef::Types::Nil::Nil');
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

    sub __nonexistent_method {
        my ($self, $method, $obj) = @_;
        warn sprintf(qq{[WARN] Can't find the method "$method" for object "%s"!\n}, ref($obj));
        return;
    }

    sub __set_value {
        my ($self, $obj) = @_;

        $#_ > 1 && ($obj = $_[-1]);

        if ($self->{type} eq "var" or $self->{type} eq "static") {
            return $self->set_value($obj);
        }

        if ($self->{type} eq "const") {
            if (not exists $self->{inited}) {
                return $self->set_value($obj);
            }
            return $self->get_value;
        }

        if ($self->{type} eq 'func') {
            if (ref $obj eq 'Sidef::Types::Block::Code') {
                return $self->set_value($obj);
            }
            warn "[WARN] Can't assign the '", ref($obj),
              "' object to function '$self->{name}'!\n" . "An object of type 'Sidef::Types::Block::Code' was expected.\n";
            return $self->get_value;
        }

        warn "[WARN] Invalid variable type: '$self->{type}'.\n";    # this should not happen
        $obj;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '='} = \&__set_value;

        *{__PACKAGE__ . '::' . '\\\\'} = sub {
            my ($self, $code) = @_;

            if ($self->_is_defined) {
                return $self;
            }

            Sidef::Types::Block::Code->new($code)->run;
        };

        foreach my $operator (qw(:= \\\\=)) {
            *{__PACKAGE__ . '::' . $operator} = sub {
                my ($self, $code) = @_;

                if (not $self->_is_defined) {
                    $self->__set_value(Sidef::Types::Block::Code->new($code)->run);
                }

                $operator eq ':=' ? $self : $self->get_value;
            };
        }

        foreach my $operator (qw(++ --)) {
            *{__PACKAGE__ . '::' . $operator} = sub {
                my ($self, $arg) = @_;
                my $value = $self->get_value;
                my $sub;
                ref($value) && defined($sub = $value->can($operator))
                  ? $self->__set_value($value->$sub($arg))
                  : $self->__nonexistent_method($operator, $arg);
                $value;

            };
        }

        foreach my $operator (qw(+ - % * / & | ^ ** && || << >> ÷)) {
            *{__PACKAGE__ . '::' . $operator . '='} = sub {
                my ($self, $arg) = @_;
                my $value = $self->get_value;
                my $sub;
                ref($value) && defined($sub = $value->can($operator))
                  ? $self->__set_value($value->$sub($arg))
                  : $self->__nonexistent_method($operator, $arg);
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

        my $suffix;
        if ($method =~ /^[[:alpha:]]/ && $method =~ tr/!:?//) {
            $suffix = chop $method;
        }

        if (ref($value) && (defined(my $sub = $value->can($method) // ($value->can('AUTOLOAD') ? $method : ())))) {
            my $result = $value->$sub(@args);

            if (defined($suffix)) {
                if ($suffix eq '!') {    # modifies the variable in place
                    $self->__set_value($result);
                    return $self;
                }

                if ($suffix eq ':') {    # returns the self variable
                    return $self;
                }

                if ($suffix eq '?') {    # asks for a boolean value
                    return ref($result) eq 'Sidef::Types::Bool::Bool'
                      ? $result
                      : Sidef::Types::Bool::Bool->new($result);
                }
            }

            if ($self->{type} eq 'func' and exists $self->{returns}) {
                ref($result) eq ref($self->{returns}) || do {
                    die "[ERROR] Return-type error from function '$self->{name}': returned '", ref($result),
                      "', but expected '", ref($self->{returns}), "'!\n";
                };
            }

            return $result;
        }
        else {
            $self->__nonexistent_method($method, $value);
        }

        return;
    }
}

1;
