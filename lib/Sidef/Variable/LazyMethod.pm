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

    {
        no strict 'refs';
        foreach my $meth (qw(say print println)) {
            *{__PACKAGE__ . '::' . $meth} = sub {
                my $self = shift;
                local $AUTOLOAD = __PACKAGE__ . '::' . $meth;
                $self->AUTOLOAD(@_);
              }
        }
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
