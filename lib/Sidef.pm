package Sidef {

    use 5.014;
    our $VERSION = 0.03;

    package UNIVERSAL {

        sub get_value {
            $_[0];
        }

        our $AUTOLOAD;
        sub DESTROY { }

        sub AUTOLOAD {
            my ($self, @args) = @_;

            $self = ref($self) if ref($self);
            $self =~ /^Sidef::/ or return;
            eval { require $self =~ s{::}{/}rg . '.pm' };

            if ($@) {
                die "[AUTOLOAD] $@";
            }

            my $func = \&{$AUTOLOAD};
            if (defined(&$func)) {
                return $func->($self, @args);
            }

            warn "[AUTOLOAD] Undefined function: $AUTOLOAD";
            return;
        }
    }

    {
        my %types = (
                     bool   => {class => {'Sidef::Types::Bool::Bool'  => 1}},
                     code   => {class => {'Sidef::Types::Block::Code' => 1}},
                     hash   => {class => {'Sidef::Types::Hash::Hash'  => 1}},
                     number => {
                                class => {
                                          'Sidef::Types::Number::Number'  => 1,
                                          'Sidef::Types::Number::Complex' => 1,
                                          'Sidef::Types::Byte::Byte'      => 1,
                                         },
                                type => 'SCALAR',
                               },
                     var_ref => {class => {'Sidef::Variable::Ref' => 1}},
                     file    => {
                              class => {'Sidef::Types::Glob::File' => 1},
                              type  => 'SCALAR',
                             },
                     fh  => {class => {'Sidef::Types::Glob::FileHandle' => 1}},
                     dir => {
                             class => {'Sidef::Types::Glob::Dir' => 1},
                             type  => 'SCALAR',
                            },
                     regex => {class => {'Sidef::Types::Regex::Regex' => 1}},
                     pair  => {
                              class => {'Sidef::Types::Array::Pair' => 1},
                              type  => 'ARRAY',
                             },
                     string => {
                                class => {
                                          'Sidef::Types::String::String' => 1,
                                          'Sidef::Types::Char::Char'     => 1,
                                         },
                                type => 'SCALAR',
                               },
                     array => {
                               class => {
                                         'Sidef::Types::Array::Array' => 1,
                                         'Sidef::Types::Array::Range' => 1,
                                         'Sidef::Types::Char::Chars'  => 1,
                                         'Sidef::Types::Byte::Bytes'  => 1,
                                        },
                               type => 'ARRAY',
                              },
                    );

        no strict 'refs';

        foreach my $type (keys %types) {
            *{__PACKAGE__ . '::' . '_is_' . $type} = sub {
                exists($types{$type}{class}{ref($_[1])}) ? 1 : 0;
            };
        }

        foreach my $method (['!=', 1], ['==', 0]) {

            *{__PACKAGE__ . '::' . $method->[0]} = sub {
                my ($self, $arg) = @_;

                if (not defined($arg)
                    and ref($self) eq 'Sidef::Types::Nil::Nil') {
                    return Sidef::Types::Bool::Bool->new(!$method->[1]);
                }

                ref($self) ne ref($arg)
                  and return Sidef::Types::Bool::Bool->new($method->[1]);

                require Scalar::Util;
                if (Scalar::Util::reftype($self) eq 'SCALAR') {
                    return Sidef::Types::Bool::Bool->new(($$self eq $$arg) - $method->[1]);
                }

                return Sidef::Types::Bool::Bool->new($method->[1]);
            };
        }

        sub def_method {
            my ($self, $name, $block) = @_;
            *{ref($self) . '::' . $name} = sub {
                $block->call(@_);
            };
        }

        *__add_method__ = \&def_method;
        *define_method  = \&def_method;

        sub method {
            my ($self, $method, @args) = @_;
            Sidef::Variable::LazyMethod->new(obj => $self, method => $method, args => \@args);
        }

        sub METHODS {
            my ($self) = @_;
            Sidef::Types::Array::Array->new(
                map { Sidef::Types::String::String->new($_) }
                  sort { lc($a =~ tr/_//dr) cmp lc($b =~ tr/_//dr) or $a cmp $b } grep {
                          $_ ne '__ANON__'
                      and $_ ne 'ISA'
                      and $_ ne 'BEGIN'
                      and $_ ne 'AUTOLOAD'
                      and $_ ne 'DESTROY'
                  } keys %{ref($self) . '::'}
            );
        }
    }

    sub new {
        bless {}, __PACKAGE__;
    }

    sub super_join {
        my ($self, @args) = @_;
        $self->new(
            CORE::join(
                '',
                map {
                    eval { ${ref($_) eq 'Sidef::Variable::Class' ? $_->to_s : $_} }
                      // $_
                  } @args
            )
        );
    }

    sub respond_to {
        my ($self, $method) = @_;
        Sidef::Types::Bool::Bool->new($self->can($method));
    }

    *respondTo = \&respond_to;

    sub is_a {
        my ($self, $obj) = @_;
        Sidef::Types::Bool::Bool->new(ref($self) eq ref($obj));
    }

    *is_an = \&is_a;

    sub _get_indent_level {
        my $pkgname = ref(shift());

        my ($j, $i) = (1, 0);
        while (1) {
            last unless defined caller($i);
            ++$j if (scalar caller($i++) eq $pkgname);
        }

        return ($j, " " x 2);
    }

};

1;
