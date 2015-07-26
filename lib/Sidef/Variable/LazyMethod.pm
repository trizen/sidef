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
        my $call = $self->{method};

        if (ref($call) eq 'Sidef::Types::Block::Code') {
            if ($method eq 'call') {
                return $call->call($self->{obj}, @{$self->{args}}, @args);
            }
            return $call->call($self->{obj}, @{$self->{args}})->$method(@args);
        }

        if (ref($call) ne 'CODE') {
            $call = $call->get_value;
        }

        if ($method eq 'call') {
            return $self->{obj}->$call(@{$self->{args}}, @args);
        }

        $self->{obj}->$call(@{$self->{args}})->$method(@args);
    }

};

1
