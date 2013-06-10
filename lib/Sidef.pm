
use 5.006;
use strict;
use warnings;

no if $] >= 5.018, warnings => "experimental::smartmatch";

package Sidef {

    {
        my %types = (
            bool   => {class => [qw(Sidef::Types::Bool::Bool)]},
            code   => {class => [qw(Sidef::Types::Block::Code)]},
            hash   => {class => [qw(Sidef::Types::Hash::Hash)]},
            number => {class => [qw(Sidef::Types::Number::Number)], type => 'SCALAR'},
            string => {class => [qw(Sidef::Types::String::String)], type => 'SCALAR'},
            array => {
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

                my ($self, $obj, $strict_obj, $dont_warn) = @_;

                if (ref($obj) ~~ $types{$type}{class}) {
                    return 1;
                }
                else {
                    my ($sub) = [caller(1)]->[3] =~ /^.+::(.*)/;

                    if (!$dont_warn) {
                        warn sprintf("[%s] Object of type '$type' was expected, but got '%s'!\n",
                                     ($sub eq '__ANON__' ? 'WARN' : $sub), ref($obj) || "an undefined object");
                    }

                    if (!$strict_obj) {
                        if (defined $obj and exists $types{$type}{type} and $obj->isa($types{$type}{type})) {
                            return 1;
                        }
                    }
                }
                return;
            };
        }

        foreach my $method (['!=', 1], ['==', 0]) {

            *{__PACKAGE__ . '::' . $method->[0]} = sub {
                my ($self, $arg) = @_;

                my $call = $method->[0];
                my $bool = $method->[1];

                ref($self) ne ref($arg)
                  and return Sidef::Types::Bool::Bool->new($bool);

                if (ref($self) eq 'Sidef::Types::Nil::Nil') {
                    return Sidef::Types::Bool::Bool->new(!$bool);
                }
                elsif (ref($self) eq 'Sidef::Types::Bool::Bool') {
                    return Sidef::Types::Bool::Bool->new(($$self eq $$arg) - $bool);
                }

                return Sidef::Types::Bool::Bool->new($bool);
            };
        }
    }

    sub new {
        bless {}, __PACKAGE__;
    }

};

1;
