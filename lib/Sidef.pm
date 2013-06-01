
use 5.006;
use strict;
use warnings;

package Sidef {

    {
        my %types = (
            number => [qw(Sidef::Types::Number::Number)],
            string => [qw(Sidef::Types::String::String)],
            array  => [
                qw(
                  Sidef::Types::Array::Array
                  Sidef::Types::Char::Chars
                  Sidef::Types::Byte::Bytes
                  )
            ],
        );

        no strict 'refs';

        foreach my $type (keys %types) {
            *{__PACKAGE__ . '::' . '_is_' . $type} = sub {
                my ($self, $obj) = @_;
                if (ref($obj) ~~ $types{$type}) {
                    return 1;
                }
                else {
                    my ($sub) = [caller(1)]->[3] =~ /^.+::(.*)/;
                    warn sprintf("[%s] Object of type '$type' was expected, but got %s.\n",
                                 ($sub eq '__ANON__' ? 'WARN' : $sub), ref($obj) || "an undefined object");
                }
                return;
            };
        }
    }

};

1;
