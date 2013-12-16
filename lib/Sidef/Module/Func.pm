package Sidef::Module::Func {

    use 5.014;
    use strict;
    use warnings;

    our $AUTOLOAD;

    sub _new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub DESTROY {
        return;
    }

    sub __locate {
        my ($self, $name) = @_;

        no strict 'refs';
        my $mod_space = \%{$self->{module} . '::'};

        if (exists $mod_space->{$name}) {
            return $self->{module} . '::' . $name;
        }

        return;
    }

    sub _var {
        my ($self, $name) = @_;

        if (defined(my $type = $self->__locate($name))) {
            no strict 'refs';
            return ${$type};
        }

        warn qq{[WARN] Variable '$name' is not exported by module: "$self->{module}"!\n};
        return;
    }

    sub _arr {
        my ($self, $name) = @_;

        if (defined(my $type = $self->__locate($name))) {
            no strict 'refs';
            return Sidef::Types::Array::Array->new(@{$type});
        }

        warn qq{[WARN] Array '$name' is not exported by module: "$self->{module}"!\n};
        return;
    }

    sub AUTOLOAD {
        my ($self, @arg) = @_;

        my ($func)   = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);
        my $sub      = \&{$self->{module} . '::' . $func};
        my $autoload = \&{$self->{module} . '::' . 'AUTOLOAD'};

        my $return_array = 0;
        if ($func =~ /:\z/) {
            $return_array = 1;
            chop $func;
        }

        if (defined(&$sub) or defined(&$autoload)) {
            my @results = $sub->(
                @arg
                ? (
                   map {
                           ref($_) =~ /^Sidef::/ && $_->can('get_value') ? $_->get_value
                         : ref($_) eq 'Sidef::Variable::Ref' ? $_->get_var->get_value
                         : $_
                     } @arg
                  )
                : ()
            );

            if ($return_array || @results > 1) {
                return Sidef::Types::Array::Array->new(@results);
            }

            $results[0];
        }
        else {
            warn qq{[WARN] Can't locate function '$func' via package "$self->{module}"!\n};
            return Sidef::Types::Nil::Nil->new;
        }
    }
}

1;
