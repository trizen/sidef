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

        push @{$self->{__BLOCK__}{code}{$self->{name}}},
          {
            self => {
                     $self->{name} => [
                                       {
                                        self => Sidef::Variable::Variable->new($$method_name, 'func', $code->copy)
                                       }
                                      ]
                    }
          };
    }

    *def_method = \&define_method;

    sub init {
        my ($self, @args) = @_;

        require Sidef::Variable::Class;
        my $class = Sidef::Variable::Class->__new($self->{name});
        @{$class->{__NAMES__}}{@{$self->{__VARS__}}} = @args;

        # Run the auxiliary code of the class
        $self->{__BLOCK__}->run;

        # I don't like this, but... it works!
        my @init_methods;
        foreach my $function (@{$self->{__BLOCK__}{code}{$self->{name}}}) {
            if (    ref $function eq 'HASH'
                and ref(my $func = $function->{self}{$self->{name}}[0]{self}) eq 'Sidef::Variable::Variable') {
                if ($func->{type} eq 'func') {

                    # If the function has a special name, store it as init method
                    if ($func->{name} eq 'new') {
                        push @init_methods, $func;
                        next;
                    }

                    # Otherwise, store it as normal method
                    $class->{functions}{$func->{name}} = $func;
                }
            }
        }

        foreach my $method (@init_methods) {
            $method->call($class, @args);
        }

        $class;
    }

    *new = \&init;
};

1;
