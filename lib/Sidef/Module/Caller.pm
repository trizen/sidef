package Sidef::Module::Caller {

    use 5.014;
    use strict;
    use warnings;

    our $AUTOLOAD;

    sub _new {
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
            return Sidef::Module::Func->_new(module => $self->{module});
        }

        my $return_array = 0;
        if ($method =~ /:\z/) {
            $return_array = 1;
            chop $method;
        }

        if ($self->{module}->can($method) || $self->{module}->can('AUTOLOAD')) {
            my @values = $self->{module}->$method(
                @arg
                ? (
                   map {
                           ref($_) =~ /^Sidef::/ && $_->can('get_value') ? $_->get_value
                         : ref($_) eq 'Sidef::Variable::Ref' ? $_->get_var->get_value
                         : $_
                     } @arg
                  )
                : ()
            );

            if ($return_array || @values > 1) {
                return Sidef::Types::Array::Array->new(@values);
            }

            my $value = $values[0];

            if (ref($value) && eval { $value->can('can') }) {
                return $self->_new(module => ($value));
            }
            else {
                return $value;
            }
        }
        else {
            warn sprintf(qq{[WARN] Can't locate object method "$method" via package "%s"\n},
                         (ref($self->{module}) ? ref($self->{module}) : $self->{module}));
            return;
        }
    }
}

1;
