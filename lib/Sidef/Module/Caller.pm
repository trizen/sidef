
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

        return if $AUTOLOAD =~ /::DESTROY$/;
        (my $method = $AUTOLOAD) =~ s/.*:://;

        my $value = $self->{module}->$method(@arg ? (map { $_->get_value } @arg) : ());

        if (ref($value) && eval { $value->can('can') }) {
            $self->_new(module => ($value));
        }
        else {
            return $value;
        }
    }

};

1;
