package Sidef::Deparser {

    use 5.014;
    our @ISA = qw(Sidef);
    use Scalar::Util qw(refaddr reftype);

    # This module is under development...

    sub new {
        my (undef, %opts) = @_;
        bless \%opts, __PACKAGE__;
    }

    sub _indent {
        my $i = 4;
        1 while (caller($i++));
        ' ' x (2 * log($i) / log(2));    # needs work
    }

    sub _dump_vars {
        my (@vars) = @_;
        join(', ', map { $_->{name} } map { @{$_->{vars}} } @vars);
    }

    my %addr;

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
                $code = $obj->{name};
            }
            elsif ($obj->{type} eq 'func') {
                if ($addr{refaddr($obj)}++) {
                    $code = $obj->{name};
                }
                else {
                    my $block = $obj->{value};
                    $code = "func $obj->{name}";
                    my $vars = delete $block->{init_vars};
                    $code .= '(' . _dump_vars(@{$vars}[0 .. $#{$vars} - 1]) . ')';
                    $code .= $self->deparse_expr({self => $block});
                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::Init') {
            $code = 'var(' . join(', ', map { $_->{name} } @{$obj->{vars}}) . ')';
        }
        elsif ($ref eq 'Sidef::Variable::Ref') {
            ## ok
        }
        elsif ($ref eq 'Sidef::Sys::Sys') {
            $code = 'Sys';
        }
        elsif ($ref eq 'Sidef::Types::Block::Code') {
            $code = '{';
            if (exists($obj->{init_vars}) and @{$obj->{init_vars}} > 1) {
                my $vars = $obj->{init_vars};
                $code .= '|' . _dump_vars(@{$vars}[0 .. $#{$vars} - 1]) . "|";
            }
            $code .= "\n";
            my $space      = pop @{$self->{spaces}};
            my @statements = $self->deparse($obj->{code});
            my $sp         = pop @{$self->{spaces}};
            $code .= $sp . join(";\n" . pop(@{$self->{spaces}}), @statements) . "\n" . $space . '}';
        }
        elsif ($ref eq 'Sidef::Types::Number::Number') {
            $code = $obj->dump;
        }
        elsif (reftype($obj) eq 'SCALAR') {
            $code = $obj->dump;
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {
            foreach my $call (@{$expr->{call}}) {
                if ($call->{method} eq 'HASH') {

                }
                elsif ($call->{method} =~ /^[[:alpha:]_]/) {
                    $code .= ".$call->{method}";
                }
                else {
                    $code .= "$call->{method}";
                }

                if (exists $call->{arg}) {
                    $code .= '('
                      . join(', ', map { ref($_) eq 'HASH' ? $self->deparse($_) : $self->deparse_expr($_) } @{$call->{arg}})
                      . ')';
                }
            }
        }

        $code;
    }

    sub deparse {
        my ($self, $struct) = @_;

        push @{$self->{spaces}}, _indent();

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
