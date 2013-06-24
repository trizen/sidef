
use 5.014;
use strict;
use warnings;

package Sidef::Module::Caller {

    our $AUTOLOAD;

    sub _new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub AUTOLOAD {
        my ($self, @arg) = @_;

        my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);

        if ($method eq '') {
            return Sidef::Module::Func->_new(module => $self->{module});
        }

        if ($self->{module}->can($method)) {
            my $value = $self->{module}->$method(
                @arg
                ? (
                   map {
                       ref($_) =~ /^Sidef::/ && $_->can('get_value')
                         ? $_->get_value
                         : $_
                     } @arg
                  )
                : ()
            );

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

};

1;
