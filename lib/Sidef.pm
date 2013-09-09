
use 5.014;
use strict;
use warnings;

package Sidef {

    our $VERSION = 0.01;

    {
        my %types = (
                     bool    => {class => {'Sidef::Types::Bool::Bool'     => 1}},
                     code    => {class => {'Sidef::Types::Block::Code'    => 1}},
                     hash    => {class => {'Sidef::Types::Hash::Hash'     => 1}},
                     number  => {class => {'Sidef::Types::Number::Number' => 1}, type => 'SCALAR'},
                     var_ref => {class => {'Sidef::Variable::Ref'         => 1}},
                     file    => {class => {'Sidef::Types::Glob::File'     => 1}, type => 'SCALAR'},
                     dir     => {class => {'Sidef::Types::Glob::Dir'      => 1}, type => 'SCALAR'},
                     regex   => {class => {'Sidef::Types::Regex::Regex'   => 1}},
                     string => {
                                class => {
                                          'Sidef::Types::String::String' => 1,
                                          'Sidef::Types::Char::Char'     => 1,
                                         },
                                type => 'SCALAR'
                               },
                     array => {
                               type  => 'ARRAY',
                               class => {
                                         'Sidef::Types::Array::Array' => 1,
                                         'Sidef::Types::Chars::Chars' => 1,
                                         'Sidef::Types::Bytes::Bytes' => 1,
                                        }
                              },
                    );

        no strict 'refs';

        foreach my $type (keys %types) {
            *{__PACKAGE__ . '::' . '_is_' . $type} = sub {

                my ($self, $obj, $strict_obj, $dont_warn) = @_;

                if (exists $types{$type}{class}{ref($obj)}) {
                    return 1;
                }
                else {
                    my ($sub) = [caller(1)]->[3] =~ /^.*[^:]::(.+)$/;

                    if (!$dont_warn) {

                        my $ref_obj = [caller(0)]->[0];

                        warn sprintf("[WARN] %sbject '%s' expected an object of type '$type', but got '%s'!\n",
                                     ($sub eq '__ANON__' ? 'O' : sprintf("The method '%s' from o", $sub)),
                                     $ref_obj, ref($obj) || "an undefined object");
                    }

                    if (!$strict_obj) {
                        if (defined $obj and exists $types{$type}{type} and $obj->isa($types{$type}{type})) {
                            return 1;
                        }
                    }
                }

                $dont_warn ? (return) : (die "[ERROR] Can't continue...\n");
            };
        }

        foreach my $method (['!=', 1], ['==', 0]) {

            *{__PACKAGE__ . '::' . $method->[0]} = sub {
                my ($self, $arg) = @_;

                my $call = $method->[0];
                my $bool = $method->[1];

                ref($self) ne ref($arg)
                  and return Sidef::Types::Bool::Bool->new($bool);

                if (not defined($self) or ref($self) eq 'Sidef::Types::Nil::Nil') {
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
