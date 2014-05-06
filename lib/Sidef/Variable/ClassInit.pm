package Sidef::Variable::ClassInit {

    use 5.014;
    use strict;
    use warnings;

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

    sub define_method {
        my ($self, $method_name, $code) = @_;
        $self->__add_method($method_name, $code->copy);
    }

    *def_method = \&define_method;

    sub init {
        my ($self, @args) = @_;

        require Sidef::Variable::Class;
        my $class = Sidef::Variable::Class->__new($self->{name});
        @{$class->{__NAMES__}}{@{$self->{__VARS__}}} = @args;

        # Run the auxiliary code of the class
        $self->{__BLOCK__}->run;

        # Store the class methods
        while (my ($key, $value) = each %{$self->{__METHODS__}}) {
            $class->{method}{$key} = $value;
        }

        # Execute the 'new' method (if exists)
        if (exists $self->{__METHODS__}{new}) {
            ($self->{__METHODS__}{new})->call($class, @args);
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
