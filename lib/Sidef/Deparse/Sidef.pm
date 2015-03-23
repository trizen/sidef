package Sidef::Deparse::Sidef {

    use 5.014;
    our @ISA = qw(Sidef);
    use Scalar::Util qw(refaddr reftype);

    # This module is under development...

    my %addr;

    sub new {
        my (undef, %args) = @_;

        my %opts = (
                    before         => '',
                    between        => ";\n",
                    after          => ";\n",
                    spaces_num     => 4,
                    namespaces     => [],
                    obj_with_block => {
                                       'Sidef::Types::Bool::While' => {
                                                                       while => 1,
                                                                      },
                                      },
                    %args,
                   );

        %addr = ();    # reset the addr map
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
                    (exists($_->{multi}) ? '*' : '')
                  . $_->{name}
                  . (ref($_->{value}) eq 'Sidef::Types::Nil::Nil' ? '' : ('=' . $self->deparse_expr({self => $_->{value}})))
              } @vars
            );
    }

    sub _dump_array {
        my ($self, $array) = @_;
        '[' . join(', ', map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_->get_value}) } @{$array}) . ']';
    }

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $code = '';
        my $obj  = $expr->{self};

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $code = join(', ', $self->deparse($obj));
        }
        elsif ($ref eq 'Sidef::Variable::Variable') {
            if ($obj->{type} eq 'var' or $obj->{type} eq 'static' or $obj->{type} eq 'const') {
                $code = $obj->{name} =~ /^[0-9]+\z/ ? ('$' . $obj->{name}) : $obj->{name};
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {
                if ($addr{refaddr($obj)}++) {
                    $code = $obj->{name} eq '' ? '__FUNC__' : $obj->{name};
                }
                else {
                    my $block = $obj->{value};
                    $code = "$obj->{type} $obj->{name}";
                    my $vars = delete $block->{init_vars};
                    $code .= '(' . $self->_dump_init_vars(@{$vars}[($obj->{type} eq 'method' ? 1 : 0) .. $#{$vars} - 1]) . ')';
                    $code .= $self->deparse_expr({self => $block});
                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::Struct') {
            if ($addr{refaddr($obj)}++) {
                $code = $obj->{__NAME__};
            }
            else {
                my @vars;
                foreach my $key (sort keys %{$obj}) {
                    next if $key eq '__NAME__';
                    push @vars, $obj->{$key};
                }
                $code = "struct $obj->{__NAME__} {" . $self->_dump_vars(@vars) . '}';
            }
        }
        elsif ($ref eq 'Sidef::Variable::InitMy') {
            $code = "my $obj->{name}";
        }
        elsif ($ref eq 'Sidef::Variable::My') {
            $code = "$obj->{name}";
        }
        elsif ($ref eq 'Sidef::Variable::Init') {
            $code = "$obj->{vars}[0]{type}\(" . $self->_dump_init_vars($obj) . ')';
        }
        elsif ($ref eq 'Sidef::Variable::ClassInit') {
            if ($addr{refaddr($obj)}++) {
                $code = $obj->{name};
            }
            else {
                my $block = $obj->{__BLOCK__};
                $code = "class $obj->{name}";
                my $vars = $obj->{__VARS__};
                $code .= '(' . $self->_dump_vars(@{$vars}) . ')';
                if (exists $obj->{inherit}) {
                    $code .= ' << ' . join(', ', @{$obj->{inherit}}) . ' ';
                }
                $code .= $self->deparse_expr({self => $block});
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::Code') {
            if ($addr{refaddr($obj)}++) {
                $code = %{$obj} ? '__BLOCK__' : 'Block';
            }
            else {
                if (%{$obj}) {
                    $code = '{';
                    if (exists($obj->{init_vars}) and @{$obj->{init_vars}} > 1) {
                        my $vars = $obj->{init_vars};
                        $code .= '|' . $self->_dump_init_vars(@{$vars}[0 .. $#{$vars} - 1]) . "|";
                    }
                    $code .= "\n";
                    $self->{spaces} += $self->{spaces_num};
                    my @statements = $self->deparse($obj->{code});
                    $code .=
                        (" " x $self->{spaces})
                      . join(";\n" . (" " x $self->{spaces}), @statements) . "\n"
                      . (" " x ($self->{spaces} -= $self->{spaces_num})) . '}';
                }
                else {
                    $code = 'Block';
                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::Ref') {
            ## ok
        }
        elsif ($ref eq 'Sidef::Sys::Sys') {
            $code = 'Sys';
        }
        elsif ($ref eq 'Sidef::Parser') {
            $code = 'Parser';
        }
        elsif ($ref eq 'Sidef') {
            $code = 'Sidef';
        }
        elsif ($ref eq 'Sidef::Variable::LazyMethod') {
            $code = 'LazyMethod';
        }
        elsif ($ref eq 'Sidef::Types::Glob::Fcntl') {
            $code = 'Fcntl';
        }
        elsif ($ref eq 'Sidef::Types::Block::Break') {
            if (not exists $expr->{call}) {
                $code = 'break';
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::Next') {
            $code = 'next';
        }
        elsif ($ref eq 'Sidef::Types::Block::Continue') {
            $code = 'continue';
        }
        elsif ($ref eq 'Sidef::Types::Block::Return') {
            if (not exists $expr->{call}) {
                $code = 'return';
            }
        }
        elsif ($ref eq 'Sidef::Math::Math') {
            $code = 'Math';
        }
        elsif ($ref eq 'Sidef::Types::Glob::FileHandle') {
            if ($obj->{fh} eq \*STDIN) {
                $code = 'STDIN';
            }
            elsif ($obj->{fh} eq \*STDOUT) {
                $code = 'STDOUT';
            }
            elsif ($obj->{fh} eq \*STDERR) {
                $code = 'STDERR';
            }
            elsif ($obj->{fh} eq \*ARGV) {
                $code = 'ARGF';
            }
            else {
                $code = 'DATA';
            }
        }
        elsif ($ref eq 'Sidef::Variable::Magic') {

            state $magic_vars = {
                                 \$.  => '$.',
                                 \$?  => '$?',
                                 \$$  => '$$',
                                 \$^T => '$^T',
                                 \$|  => '$|',
                                 \$!  => '$!',
                                 \$"  => '$"',
                                 \$\  => '$\\',
                                 \$/  => '$/',
                                 \$;  => '$;',
                                 \$,  => '$,',
                                 \$^O => '$^O',
                                 \$^X => '$^PERL',
                                 \$0  => '$0',
                                 \$(  => '$(',
                                 \$)  => '$)',
                                 \$<  => '$<',
                                 \$>  => '$>',
                                };

            if (exists $magic_vars->{$obj->{ref}}) {
                $code = $magic_vars->{$obj->{ref}};
            }
        }
        elsif ($ref eq 'Sidef::Types::Hash::Hash') {
            $code = 'Hash';
        }
        elsif ($ref eq 'Sidef::Types::Glob::Socket') {
            $code = 'Socket';
        }
        elsif ($ref eq 'Sidef::Perl::Perl') {
            $code = 'Perl';
        }
        elsif ($ref eq 'Sidef::Time::Time') {
            $code = 'Time';
        }
        elsif ($ref eq 'Sidef::Sys::SIG') {
            $code = 'Sig';
        }
        elsif ($ref eq 'Sidef::Types::Number::Complex') {
            $code = 'Complex';
        }
        elsif ($ref eq 'Sidef::Types::Array::Pair') {
            $code = 'Pair';
        }
        elsif ($ref eq 'Sidef::Types::Regex::Regex') {
            $code .= $obj->dump->get_value;
        }
        elsif ($ref eq 'Sidef::Types::Number::Number') {
            local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
            $code = $obj->get_value;
        }
        elsif ($ref eq 'Sidef::Types::Array::Array' or $ref eq 'Sidef::Types::Array::HCArray') {
            $code .= $self->_dump_array($obj);
        }
        elsif ($obj->can('dump')) {
            $code = $obj->dump->get_value;

            if ($ref eq 'Sidef::Types::Glob::Backtick') {
                if (${$obj} eq '') {
                    $code = 'Backtick';
                }
            }
            elsif ($ref eq 'Sidef::Types::Glob::File') {
                if (${$obj} eq '') {
                    $code = 'File';
                }
            }
            elsif ($ref eq 'Sidef::Types::Glob::Dir') {
                if (${$obj} eq '') {
                    $code = 'Dir';
                }
            }
            elsif ($ref eq 'Sidef::Types::Char::Char') {
                if (${$obj} eq '') {
                    $code = 'Char';
                }
            }
            elsif ($ref eq 'Sidef::Types::String::String') {
                if (${$obj} eq '') {
                    $code = 'String';
                }
            }
            elsif ($ref eq 'Sidef::Types::Array::MultiArray') {
                if ($#{$obj} == -1) {
                    $code = 'MultiArr';
                }
            }
            elsif ($ref eq 'Sidef::Types::Glob::Pipe') {
                if ($#{$obj} == -1) {
                    $code = 'Pipe';
                }
            }
        }

        # Indices
        if (exists $expr->{ind}) {
            foreach my $ind (@{$expr->{ind}}) {
                $code .= $self->_dump_array($ind);
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {
            foreach my $call (@{$expr->{call}}) {
                my $method = $call->{method};

                if ($code eq 'Hash' and $method eq ':') {
                    $method = 'new';
                }
                elsif ($code =~ /\.\w+\z/ && $method =~ /^[?!:]/) {
                    $code = '(' . $code . ')';
                }
                elsif ($code =~ /^\w+\z/ and $method eq ':') {
                    $code = '(' . $code . ')';
                }

                if (ref($method) eq 'HASH') {
                    $code .= '.(' . $self->deparse_expr($method) . ')';
                }
                elsif ($method =~ /^[[:alpha:]_]/) {
                    $code .= '.' if $code ne '';
                    $code .= $method;
                }
                else {
                    $code .= $method;
                }

                if (exists $call->{arg}) {
                    $code .= '(' . join(
                        ', ',
                        map {
                            ref($_) eq 'HASH' ? $self->deparse($_)
                              : exists($self->{obj_with_block}{$ref})
                              && exists($self->{obj_with_block}{$ref}{$method}) ? $self->deparse_expr({self => $_->{code}})
                              : $ref eq 'Sidef::Types::Block::For'
                              && $#{$call->{arg}} == 2
                              && ref($_) eq 'Sidef::Types::Block::Code' ? $self->deparse_expr($_->{code})
                              : ref($_) ? $self->deparse_expr({self => $_})
                              : Sidef::Types::String::String->new($_)->dump
                          } @{$call->{arg}}
                      )
                      . ')';
                }
            }
        }

        $code;
    }

    sub deparse {
        my ($self, $struct) = @_;

        my @results;
        foreach my $class (grep exists $struct->{$_}, @{$self->{namespaces}}, 'main') {
            foreach my $i (0 .. $#{$struct->{$class}}) {
                my $expr = $struct->{$class}[$i];
                push @results, ref($expr) eq 'HASH' ? $self->deparse_expr($expr) : $self->deparse_expr({self => $expr});
            }
        }

        wantarray ? @results : $results[-1];
    }
};

1
