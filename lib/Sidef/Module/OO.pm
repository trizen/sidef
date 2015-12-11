package Sidef::Module::OO {

    use 5.014;
    our $AUTOLOAD;

    sub __NEW__ {
        my (undef, $module) = @_;
        bless {module => $module}, __PACKAGE__;
    }

    sub DESTROY {
        return;
    }

    sub AUTOLOAD {
        my ($self, @arg) = @_;

        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        my @args = (
            @arg
            ? (
               map {
                   local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                   ref($_) eq __PACKAGE__ ? $_->{module}
                     : index(ref($_), 'Sidef::') == 0 ? $_->get_value
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
            return (map { Sidef::Perl::Perl->to_sidef($_) } @results);
        }

        Sidef::Perl::Perl->to_sidef($results[0]);
    }
}

1;
