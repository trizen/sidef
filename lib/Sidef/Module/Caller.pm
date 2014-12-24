package Sidef::Module::Caller {

    use 5.014;
    our $AUTOLOAD;

    sub _new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub DESTROY {
        return;
    }

    sub AUTOLOAD {
        my ($self, @arg) = @_;
        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        if ($method eq '') {
            return Sidef::Module::Func->_new(module => $self->{module});
        }

        my @results;
        eval {
            @results = $self->{module}->$method(
                @arg
                ? (
                   map {
                           ref($_) =~ /^Sidef::/ && $_->can('get_value') ? $_->get_value
                         : ref($_) eq 'Sidef::Variable::Ref' ? $_->get_var->get_value
                         : ref($_) eq __PACKAGE__            ? $_->{module}
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

        my $result = $results[0];
        if (ref($result) && eval { $result->can('can') }) {
            return $self->_new(module => ($result));
        }

        Sidef::Perl::Perl->to_sidef($result);
    }
}

1;
