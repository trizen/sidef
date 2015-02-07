package Sidef::Deparse::Perl {

    use 5.014;
    our @ISA = qw(Sidef);
    use Scalar::Util qw(refaddr reftype);

    # This module is under development...

    sub new {
        my (undef, %opts) = @_;
        bless \%opts, __PACKAGE__;
    }

    sub _dump_init_vars {
        my ($self, @init_vars) = @_;
        $self->_dump_vars(map { @{$_->{vars}} } @init_vars);
    }

    sub _dump_vars {
        my ($self, @vars) = @_;
        join(
            ', ',
            map {
                    '$'
                  . $_->{name}
                  . (ref($_->{value}) eq 'Sidef::Types::Nil::Nil' ? '' : ('=' . $self->deparse_expr({self => $_->{value}})))
              } @vars
            );
    }

    my %req;

    sub _require {
        my ($self, $module) = @_;
        if (not exists $req{$module}) {
            undef $req{$module};
            return "require $module;";
        }
        '';
    }

    my %func;
    my %class;

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $code = '';
        my $obj  = $expr->{self};

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $code = join(', ', $self->deparse($obj));
        }
        elsif ($ref eq "Sidef::Variable::Variable") {
            if ($obj->{type} eq 'var') {
                $code = '$' . $obj->{name};
            }
            elsif ($obj->{type} eq 'func') {
                if ($func{refaddr($obj)}++) {
                    $code = $obj->{name};
                }
                else {
                    my $block = $obj->{value};
                    $code = "sub $obj->{name}";
                    $code .= $self->deparse_expr({self => $block});

                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::Init') {
            $code = 'var(' . $self->_dump_init_vars($obj) . ')';
        }
        elsif ($ref eq 'Sidef::Variable::ClassInit') {
            if ($class{refaddr($obj)}++) {
                $code = $obj->{name};
            }
            else {
                my $block = $obj->{__BLOCK__};
                $code = "class $obj->{name}";
                my $vars = $obj->{__VARS__};
                $code .= '(' . $self->_dump_vars(@{$vars}) . ')';
                $code .= $self->deparse_expr({self => $block});
            }
        }
        elsif ($ref eq 'Sidef::Variable::Ref') {
            ## ok
        }
        elsif ($ref eq 'Sidef::Sys::Sys') {
            $code = 'Sys';
        }
        elsif ($ref eq 'Sidef::Types::Bool::If') {
            $code .= $self->_require($ref);
            $code .= $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Block::Code') {
            $code = '{';
            $code .= "\n";
            $self->{spaces} += 4;
            my @statements = $self->deparse($obj->{code});
            $code .= (" " x $self->{spaces}) . do {
                if (exists($obj->{init_vars}) and @{$obj->{init_vars}} > 1) {
                    my $vars = delete $obj->{init_vars};
                    'my (' . $self->_dump_init_vars(@{$vars}[0 .. $#{$vars} - 1]) . ') = @_;' . "\n" . (" " x $self->{spaces});
                }
              }
              . join(";\n" . (" " x $self->{spaces}), @statements) . "\n" . (" " x ($self->{spaces} -= 4)) . '}';
        }
        elsif ($ref eq 'Sidef::Types::Number::Number') {
            local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
            $code = $obj->get_value;
        }
        elsif (reftype($obj) eq 'SCALAR') {
            $code = $obj->dump->get_value;
        }

        # Indices
        if (exists $expr->{ind}) {
            $code .= "#[#indices#]#";    # needs work
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {
            foreach my $call (@{$expr->{call}}) {
                if ($call->{method} eq 'HASH') {

                }
                elsif ($call->{method} =~ /^[[:alpha:]_]/) {
                    $code .= do {
                        my $method = $call->{method};
                        if (exists $func{refaddr($obj)}) {

                        }
                        else {
                            $code .= '->' if $code ne '';
                            $call->{method};
                        }
                    };
                }
                else {
                    $code .= $call->{method};
                }

                if (exists $call->{arg}) {
                    $code .= '(' . join(
                        ', ',
                        map {
                                ref($_) eq 'HASH' ? $self->deparse($_)
                              : ref($_) ? $self->deparse_expr({self => $_})
                              : Sidef::Types::String::String->new($_)->dump
                          } @{$call->{arg}}
                      )
                      . ')';
                }
            }
        }

        ref($code) ? '###' . $code . '###' : $code eq '' ? '#~#' . $obj . '#~#' : $code;
    }

    sub deparse {
        my ($self, $struct) = @_;

        my @results;
        foreach my $class (grep exists $struct->{$_}, @{$self->{namespaces}}, 'main') {
            foreach my $i (0 .. $#{$struct->{$class}}) {
                my $expr = $struct->{$class}[$i];
                push @results, $self->deparse_expr($expr);
            }
        }

        wantarray ? @results : $results[-1];
    }
};

1
