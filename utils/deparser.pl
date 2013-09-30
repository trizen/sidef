package Sidef::Deparser {

    use utf8;
    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub deparse_obj {
        my ($self, $expr) = @_;

        if (exists $expr->{self}) {
            my $self_obj = $expr->{self};

            my $ref = ref($self_obj);
            if ($ref eq 'HASH') {
                return $self->deparse($self_obj);
            }
            elsif ($ref eq 'Sidef::Types::Block::Code') {

                if (defined($self->{current_block}) and $self_obj eq $self->{current_block}) {
                    return '__BLOCK__';
                }

                local $self->{current_block} = $self_obj;
                return '{', $self->deparse($self_obj), '}';
            }
            elsif ($ref eq 'Sidef::Variable::Ref') {
                return;
            }
            elsif ($ref eq 'Sidef::Types::String::String') {
                return q{"} . $$self_obj =~ s{\n}{\\n}gr . q{"};    # needs work
            }
            elsif ($ref eq 'Sidef::Variable::Init') {
                my @vars = map { $_->{name} } @{$self_obj->{vars}};
                return (@vars > 1 ? sprintf('var (%s)', join(', ', @vars)) : "var $vars[0]");
            }
            elsif ($ref eq 'Sidef::Variable::Variable') {
                return $self_obj->{name};
            }
            elsif ($ref eq 'Sidef::Types::Bool::If') {
                return;
            }
            elsif ($ref eq 'Sidef::Sys::Sys') {
                return 'Sys';
            }
            else {
                say "\nCan't handle: $ref\n";
            }
        }

        die "Invalid object!\n";
    }

    sub deparse_expr {
        my ($self, $expr) = @_;

        my @line = $self->deparse_obj($expr);

        if (exists $expr->{call}) {

            foreach my $call (@{$expr->{call}}) {

                my $method = $call->{method};
                my @method = $self->deparse_obj(ref($method) eq 'HASH' ? $method : {self => $method});
                chop($_), substr($_, 0, 1, '') for @method;

                if (@line && @method && $method[0] =~ /^\w/) {
                    push @line, '.';
                }

                push @line, @method;

                if (exists $call->{arg}) {

                    while (@{$call->{arg}}) {
                        my $arg = shift @{$call->{arg}};

                        push @line, '(';
                        push @line, $self->deparse_obj({self => $arg});

                        if (@{$call->{arg}}) {
                            push @line, ',';
                        }

                        push @line, ')';
                    }
                }
            }

            push @line, ';';
        }

        return @line;
    }

    sub deparse {
        my ($self, $struct) = @_;

        my @tokens;

        foreach my $key ((grep { $_ ne 'main' } keys %{$struct}), 'main') {
            foreach my $i (0 .. $#{$struct->{$key}}) {
                my $expr = $struct->{$key}[$i];
                push @tokens, $self->deparse_expr($expr);
            }
        }

        return \@tokens;
    }
};

#
## The main package
#

package main {

    use 5.014;
    use strict;
    use warnings;
    use lib '../lib';

    binmode(STDOUT, ':encoding(UTF-8)');
    binmode(STDERR, ':encoding(UTF-8)');
    binmode(STDIN,  ':encoding(UTF-8)');

    ((!@ARGV) || (not -f $ARGV[0])) && die "usage: $0 [script.sf]\n";

    my $script = $ARGV[0];

    require Sidef::Parser;
    my $parser = Sidef::Parser->new(script_name => '/deparser/');

    my $struct = $parser->parse_script(
        code => do {
            open my $fh, '<:encoding(UTF-8)', $script;
            local $/;
            <$fh>;
          }
    );

    my $deparser = Sidef::Deparser->new();
    my $array    = $deparser->deparse($struct);

    {

        my $info = {indent => 0, space => "\t"};

        sub make_string {
            my ($array_ref) = @_;

            my $string = $info->{space} x $info->{indent};

            for (my $i = 0 ; $i <= $#{$array_ref} ; $i++) {
                my $item = $array_ref->[$i];

                if (ref $item eq 'ARRAY') {
                    ++$info->{indent};

                    if ($i > 0 && $array_ref->[$i - 1] eq '(') {
                        local $info->{indent} = 0;
                        local $info->{solid}  = 1;
                        $string .= make_string($item);
                    }
                    else {
                        $string .= make_string($item);
                    }

                    --$info->{indent};
                }
                else {

                    if ($item eq '}') {
                        --$info->{indent};
                    }

                    $string .= $item;

                    if ($item eq ';') {
                        $string .= $info->{solid} ? '' : "\n";
                        $string .= $info->{space} x (
                                                       $i == $#{$array_ref}
                                                     ? $info->{indent} - 1
                                                     : $info->{indent}
                                                    );
                    }
                    elsif ($item eq '{') {
                        $string .= "\n";

                        # remove the block private variable
                        splice(@{$array_ref->[$i + 1]}, 0, 5);
                    }

                }
            }

            $string;
        }
    }

    my $code = make_string($array);
    print $code;
}
