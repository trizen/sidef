package Sidef::Module::OO {

    use utf8;
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
                   ? (map { ref($_) eq __PACKAGE__ ? $_->{module} : index(ref($_), 'Sidef::') == 0 ? $_->get_value : $_ } @arg)
                   : ()
        );

        my @results = do {
            local *UNIVERSAL::AUTOLOAD;
            $self->{module}->$method(@args);
        };

        my $multi_values = wantarray // return;

        if (@results > 1) {
            @results = map { Sidef::Perl::Perl->to_sidef($_) } @results;
            return ($multi_values ? @results : Sidef::Types::Array::Array->new(\@results));
        }

        Sidef::Perl::Perl->to_sidef($results[0]);
    }
}

1;
