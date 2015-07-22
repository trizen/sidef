package Sidef::Module::OO {

    use 5.014;
    our $AUTOLOAD;

    sub __NEW__ {
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
            return Sidef::Module::Func->__NEW__(module => $self->{module});
        }

        my @args = (
            @arg
            ? (
               map {
                   local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                       ref($_) eq __PACKAGE__            ? $_->{module}
                     : ref($_) eq 'Sidef::Variable::Ref' ? $_->get_var->get_value
                     : ref($_) =~ /^Sidef::/             ? $_->get_value
                     : $_
                 } @arg
              )
            : ()
        );

        my @results = do {
            local *UNIVERSAL::AUTOLOAD;
            $self->{module}->$method(@args);
        };

        if (@results > 1) {
            return Sidef::Types::Array::List->new(map { Sidef::Perl::Perl->to_sidef($_) } @results);
        }

        my $result = $results[0];
        if (ref($result) && eval { $result->can('can') }) {
            return $self->__NEW__(module => ($result));
        }

        Sidef::Perl::Perl->to_sidef($result);
    }
}

1;
