package Sidef::Variable::LazyMethod {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    our $AUTOLOAD;

    sub new {
        my (undef, %hash) = @_;
        bless \%hash, __PACKAGE__;
    }

    sub to_s {
        my $self = shift;
        local $AUTOLOAD = __PACKAGE__ . '::' . 'to_s';
        $self->AUTOLOAD(@_);
    }

    sub to_b {
        my $self = shift;
        local $AUTOLOAD = __PACKAGE__ . '::' . 'to_b';
        $self->AUTOLOAD(@_);
    }

    sub to_n {
        my $self = shift;
        local $AUTOLOAD = __PACKAGE__ . '::' . 'to_n';
        $self->AUTOLOAD(@_);
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);
        my $call = $self->{method};

        if (ref($call) eq 'Sidef::Types::Block::Block') {
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
