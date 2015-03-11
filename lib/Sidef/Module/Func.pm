package Sidef::Module::Func {

    use 5.014;
    our $AUTOLOAD;

    sub __NEW__ {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub DESTROY {
        return;
    }

    sub __LOCATE__ {
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

        if (defined(my $type = $self->__LOCATE__($name))) {
            no strict 'refs';
            return ${$type};
        }

        warn qq{[WARN] Variable '$name' is not exported by module: "$self->{module}"!\n};
        return;
    }

    sub _arr {
        my ($self, $name) = @_;

        if (defined(my $type = $self->__LOCATE__($name))) {
            no strict 'refs';
            return Sidef::Types::Array::Array->new(@{$type});
        }

        warn qq{[WARN] Array '$name' is not exported by module: "$self->{module}"!\n};
        return;
    }

    sub AUTOLOAD {
        my ($self, @arg) = @_;

        my ($func) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);
        my @results;

        eval {
            @results = (\&{$self->{module} . '::' . $func})->(
                @arg
                ? (
                   map {
                       local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                       ref($_) eq 'Sidef::Variable::Ref'
                         ? do {
                           my $obj = $_->get_var->get_value;
                           ref $obj eq 'Sidef::Types::Hash::Hash' ? $obj->{data} //= {} : $obj;
                         }
                         : ref($_) =~ /^Sidef::/ && $_->can('get_value') ? $_->get_value
                         : $_
                     } @arg
                  )
                : ()
            );
        };

        if ($@) {
            warn $@;
            return;
        }

        if (@results > 1) {
            return Sidef::Types::Array::Array->new(map { Sidef::Perl::Perl->to_sidef($_) } @results);
        }

        Sidef::Perl::Perl->to_sidef($results[0]);
    }
}

1;
