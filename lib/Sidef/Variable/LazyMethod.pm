package Sidef::Variable::LazyMethod {

    our @ISA = qw(Sidef);
    our $AUTOLOAD;

    sub new {
        my (undef, %hash) = @_;
        bless \%hash, __PACKAGE__;
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        if ($method eq 'call') {
            return $self->{obj}->${$self->{method}}(@{$self->{args}}, @args);
        }

        $self->{obj}->${$self->{method}}(@{$self->{args}})->$method(@args);
    }

};

1
