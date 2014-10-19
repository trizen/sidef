package Sidef::Variable::ClassInit {

    use 5.014;

    sub __new {
        my (undef, $name) = @_;
        bless {name => $name}, __PACKAGE__;
    }

    sub __set_value {
        my ($self, $block, $names) = @_;
        $self->{__BLOCK__} = $block;
        $self->{__VARS__}  = $names;
        $self;
    }

    sub __add_method {
        my ($self, $name, $method) = @_;
        $self->{__METHODS__}{$name} = $method;
        $self;
    }

    sub define_var {
        my ($self, $name, $value) = @_;
        $self->{__VALS__}{$name} = $value;
        $self;
    }

    *def_var         = \&define_var;
    *define_variable = \&define_var;

    sub define_method {
        my ($self, $name, $value) = @_;
        if (ref($value) ne 'Sidef::Types::Block::Code') {
            return $self->define_var($name, $value);
        }
        $self->__add_method($name, $value->copy);
    }

    *def_method = \&define_method;

    sub init {
        my ($self, @args) = @_;

        require Sidef::Variable::Class;
        my $class = Sidef::Variable::Class->__new($self->{name});

        # Init the class variables
        @{$class->{__VARS__}}{map { $_->{name} } @{$self->{__VARS__}}} =
          map { $_->{value} } @{$self->{__VARS__}};

        # Set the class arguments
        while (my ($i, $arg) = each @args) {
            if (ref($arg) eq 'Sidef::Types::Array::Pair') {
                foreach my $pair (@args[$i .. $#args]) {
                    ref($pair) eq 'Sidef::Types::Array::Pair' || do {
                        warn "[WARN]: Class init error -- expected a Pair type argument, but got: ", ref($pair), "\n";
                        last;
                    };
                    $class->{__VARS__}{$pair->first->get_value->get_value} = $pair->second->get_value->get_value;
                }
                last;
            }

            $class->{__VARS__}{$self->{__VARS__}[$i]{name}} = $args[$i];
        }

        # Run the auxiliary code of the class
        $self->{__BLOCK__}->run;

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
            return $self->{__METHODS__}{new}->call($class, @args);
        }

        $class;
    }

    *new = \&init;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+='} = \&define_method;
    }
};

1;
