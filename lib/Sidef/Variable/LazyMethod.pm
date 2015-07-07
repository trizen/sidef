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
        my $call = ref($self->{method}) eq 'CODE' ? $self->{method} : $self->{method}->get_value;

        if ($method eq 'call') {
            return $self->{obj}->$call(@{$self->{args}}, @args);
        }

        $self->{obj}->$call(@{$self->{args}})->$method(@args);
    }

};

1
