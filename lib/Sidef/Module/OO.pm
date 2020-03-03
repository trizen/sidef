package Sidef::Module::OO {

    use utf8;
    use 5.016;
    our $AUTOLOAD;

    use overload q{""} => sub {
        my ($self) = @_;
        overload::StrVal($self->{module}) ? "$self->{module}" : $self;
    };

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

        my $multi_values = wantarray;

        my @results = do {
            local *UNIVERSAL::AUTOLOAD;
            $multi_values ? ($self->{module}->$method(@args)) : (scalar $self->{module}->$method(@args));
        };

        $multi_values // return;

        @results = map { Sidef::Perl::Perl->to_sidef($_) } @results;

        if (@results > 1) {
            return ($multi_values ? @results : Sidef::Types::Array::Array->new(\@results));
        }

        $results[0];
    }
}

1;
