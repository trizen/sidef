package Sidef::Module::Func {

    use utf8;
    use 5.016;
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

        my ($func) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        my @args = (
                    @arg
                    ? (map { index(ref($_), 'Sidef::') == 0 ? $_->get_value : $_ } @arg)
                    : ()
                   );

        my $multi_values = wantarray;

        my @results = do {
            local *UNIVERSAL::AUTOLOAD;
            no strict 'refs';
            $multi_values ? (($self->{module} . '::' . $func)->(@args)) : scalar(($self->{module} . '::' . $func)->(@args));
        };

        $multi_values // return;

        if (@results > 1) {
            @results = map { Sidef::Perl::Perl->to_sidef($_) } @results;
            return ($multi_values ? @results : Sidef::Types::Array::Array->new(\@results));
        }

        Sidef::Perl::Perl->to_sidef($results[0]);
    }
}

1;
