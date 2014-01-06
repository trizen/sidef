package Sidef::Variable::ClassInit {

    use 5.014;
    use strict;
    use warnings;

    sub __new {
        my (undef, $name) = @_;
        bless {name => $name}, __PACKAGE__;
    }

    sub __set_value {
        my ($self, $block, @names) = @_;
        $self->{__BLOCK__} = $block;
        $self->{__VARS__}  = \@names;
        $self;
    }

    sub define_method {
        my ($self, $method_name, $code) = @_;

        require Data::Dump;
        push @{$self->{__BLOCK__}{code}{$self->{name}}},
          {self =>
            {$self->{name} => [{self => Sidef::Variable::Variable->new($$method_name, 'func', eval Data::Dump::pp($code))}]}
          };
    }

    sub init {
        my ($self, @args) = @_;

        require Sidef::Variable::Class;
        my $class = Sidef::Variable::Class->__new($self->{name});
        @{$class->{__NAMES__}}{@{$self->{__VARS__}}} = @args;

        # Run the auxiliary code of the class
        $self->{__BLOCK__}->run;

        # I don't like this, but... it works!
        foreach my $function (@{$self->{__BLOCK__}{code}{$self->{name}}}) {
            if (    ref $function eq 'HASH'
                and ref(my $func = $function->{self}{$self->{name}}[0]{self}) eq 'Sidef::Variable::Variable') {
                if ($func->{type} eq 'func') {

                    # Call the function if its name is 'new';
                    if ($func->{name} eq 'new') {
                        $func->call($class, @args);
                        next;
                    }

                    # Otherwise, store it.
                    $class->{functions}{$func->{name}} = $func;
                }
            }
        }

        $class;
    }

    *new = \&init;
};

1;
