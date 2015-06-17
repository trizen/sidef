package Sidef::Variable::ClassInit {

    use 5.014;

    sub __new__ {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub __set_params__ {
        my ($self, $names) = @_;
        $self->{__VARS__} = $names;
    }

    sub __set_block__ {
        my ($self, $block) = @_;
        $self->{__BLOCK__} = $block;
        $self;
    }

    sub __add_method__ {
        my ($self, $name, $method) = @_;
        $self->{__METHODS__}{$name} = $method;
        $self;
    }

    sub __add_vars__ {
        my ($self, $vars) = @_;
        push @{$self->{__DEF_VARS__}}, @{$vars};
        $self;
    }

    sub def_var {
        my ($self, $name, $value) = @_;
        $self->{__VALS__}{$name} = $value;
        $self;
    }

    sub def_method {
        my ($self, $name, $value) = @_;
        if (ref($value) ne 'Sidef::Types::Block::Code') {
            return $self->def_var($name, $value);
        }
        $self->__add_method__($name, $value);
    }

    sub has_method {
        my ($self, $name) = @_;
        Sidef::Types::Bool::Bool->new(exists $self->{__METHODS__}{$name});
    }

    sub inherit {
        my ($self, $class) = @_;
        my $name = $self->{name};
        foreach my $type (qw(__METHODS__ __VALS__)) {
            foreach my $key (keys %{$class->{$type}}) {
                if (not exists $self->{$type}{$key}) {
                    $self->{$type}{$key} = $class->{$type}{$key};
                }
            }
        }
        push @{$self->{__VARS__}}, @{$class->{__VARS__}};
        $self->{name} = $name;
        $self;
    }

    sub replace {
        my ($self, $class) = @_;
        my $name = $self->{name};
        delete @{$self}{keys %{$self}};
        %{$self} = %{$class};
        $self->{name} = $name;
        $self;
    }

    sub is_a {
        my ($self, $arg) = @_;
        Sidef::Types::Bool::Bool->new(
                                      ref($arg) eq 'Sidef::Variable::ClassInit' || ref($arg) eq 'Sidef::Variable::Class'
                                      ? $self->{name} eq $arg->{name}
                                      : 0
                                     );
    }

    *is_an = \&is_a;

    sub init {
        my ($self, @args) = @_;

        my $class = Sidef::Variable::Class->__new__($self->{name});

        my @default_values = map { $_->{value} } @{$self->{__VARS__}};

        # Init the class variables
        @{$class->{__VARS__}}{map { $_->{name} } @{$self->{__VARS__}}} = @default_values;

        # Set the class arguments
        foreach my $i (0 .. $#{$self->{__VARS__}}) {
            if (ref($args[$i]) eq 'Sidef::Types::Array::Pair') {
                foreach my $pair (@args[$i .. $#args]) {
                    ref($pair) eq 'Sidef::Types::Array::Pair' || do {
                        warn "[WARN] Class init error -- expected a Pair type argument, but got: ", ref($pair), "\n";
                        last;
                    };
                    $self->{__VARS__}[$i]->set_value($class->{__VARS__}{$pair->[0]->get_value} = $pair->[1]->get_value);
                }
                last;
            }

            exists($self->{__VARS__}[$i]->{array}) && do {
                $self->{__VARS__}[$i]->set_value($class->{__VARS__}{$self->{__VARS__}[$i]{name}} =
                                                 Sidef::Types::Array::Array->new(@args[$i .. $#args]));
                next;
            };

            exists($self->{__VARS__}[$i]->{hash}) && do {
                $self->{__VARS__}[$i]->set_value($class->{__VARS__}{$self->{__VARS__}[$i]{name}} =
                                                 Sidef::Types::Hash::Hash->new(@args[$i .. $#args]));
                next;
            };

            $self->{__VARS__}[$i]->set_value($class->{__VARS__}{$self->{__VARS__}[$i]{name}} =
                                             exists($args[$i]) ? $args[$i] : $self->{__VARS__}[$i]->{value});
        }

        # Run the auxiliary code of the class
        $self->{__BLOCK__}->run;

        # Set back the default values for variables
        while (my ($i, $var) = each @{$self->{__VARS__}}) {
            $var->set_value($default_values[$i]);
        }

        # Add 'var' defined variables
        foreach my $var (@{$self->{__DEF_VARS__}}) {
            $class->{__VARS__}{$var->{name}} = $var->get_value;
        }

        # Add some new defined values
        while (my ($key, $value) = each %{$self->{__VALS__}}) {
            $class->{__VARS__}{$key} = $value;
        }

        # Store the class methods
        while (my ($key, $value) = each %{$self->{__METHODS__}}) {
            $class->{method}{$key} = $value;
        }

        # Execute the 'new' method (if exists)
        if (exists $self->{__METHODS__}{new}) {
            $self->{__METHODS__}{new}->call($class, @args);
        }

        $class;
    }

    *new = \&init;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '='}  = \&replace;
        *{__PACKAGE__ . '::' . '+='} = \&inherit;
        *{__PACKAGE__ . '::' . '<'}  = \&inherit;
        *{__PACKAGE__ . '::' . '<<'} = \&inherit;
    }
};

1;
