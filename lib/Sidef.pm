
use 5.006;
use strict;
use warnings;

package Sidef {

    {
        my %types = (
            number => {class => [qw(Sidef::Types::Number::Number)], type => 'SCALAR'},
            string => {class => [qw(Sidef::Types::String::String)], type => 'SCALAR'},
            array  => {
                type  => 'ARRAY',
                class => [
                    qw(
                      Sidef::Types::Array::Array
                      Sidef::Types::Chars::Chars
                      Sidef::Types::Bytes::Bytes
                      )
                ],
            },
        );

        no strict 'refs';

        foreach my $type (keys %types) {
            *{__PACKAGE__ . '::' . '_is_' . $type} = sub {
                my ($self, $obj) = @_;
                if (ref($obj) ~~ $types{$type}{class}) {
                    return 1;
                }
                else {
                    my ($sub) = [caller(1)]->[3] =~ /^.+::(.*)/;

                    warn sprintf("[%s] Object of type '$type' was expected, but got %s.\n",
                                 ($sub eq '__ANON__' ? 'WARN' : $sub), ref($obj) || "an undefined object");

                    if ($obj->isa($types{$type}{type})) {
                        return 1;
                    }
                }
                return;
            };
        }
    }

};

1;
