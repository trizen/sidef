package Sidef::Deparse::Perl {

    use utf8;
    use 5.014;

    use Scalar::Util qw(refaddr);
    use Sidef::Types::Number::Number;

    my %addr;
    my %type;
    my %const;
    my %top_add;

    sub new {
        my (undef, %args) = @_;

        my %opts = (
            before      => '',
            header      => '',
            top_program => '',
            between     => ';',
            after       => ';',
            namespaces  => [],
            opt         => {},

            environment_name => 'main',

            assignment_ops => {
                               '=' => '=',
                              },

            lazy_ops => {
                         '?'     => '?',
                         '||'    => '||',
                         '&&'    => '&&',
                         ':='    => '//=',
                         '||='   => '||=',
                         '&&='   => '&&=',
                         '\\\\'  => '//',
                         '\\\\=' => '//=',
                        },

            overload_methods => {
                                 '=='  => 'eq',
                                 '<=>' => 'cmp',
                                 '~~'  => '~~',
                                },

            data_types => {
                qw(
                  Sidef::DataTypes::Bool::Bool            Sidef::Types::Bool::Bool
                  Sidef::DataTypes::Array::Array          Sidef::Types::Array::Array
                  Sidef::DataTypes::Array::Pair           Sidef::Types::Array::Pair
                  Sidef::DataTypes::Hash::Hash            Sidef::Types::Hash::Hash
                  Sidef::DataTypes::Regex::Regex          Sidef::Types::Regex::Regex
                  Sidef::DataTypes::String::String        Sidef::Types::String::String
                  Sidef::DataTypes::Number::Number        Sidef::Types::Number::Number
                  Sidef::DataTypes::Number::Complex       Sidef::Types::Number::Complex
                  Sidef::DataTypes::Range::Range          Sidef::Types::Range::Range
                  Sidef::DataTypes::Range::RangeNumber    Sidef::Types::Range::RangeNumber
                  Sidef::DataTypes::Range::RangeString    Sidef::Types::Range::RangeString
                  Sidef::DataTypes::Block::Block          Sidef::Types::Block::Block
                  Sidef::DataTypes::Glob::Socket          Sidef::Types::Glob::Socket
                  Sidef::DataTypes::Glob::Pipe            Sidef::Types::Glob::Pipe
                  Sidef::DataTypes::Glob::Backtick        Sidef::Types::Glob::Backtick
                  Sidef::DataTypes::Glob::DirHandle       Sidef::Types::Glob::DirHandle
                  Sidef::DataTypes::Glob::FileHandle      Sidef::Types::Glob::FileHandle
                  Sidef::DataTypes::Glob::SocketHandle    Sidef::Types::Glob::SocketHandle
                  Sidef::DataTypes::Glob::Dir             Sidef::Types::Glob::Dir
                  Sidef::DataTypes::Glob::File            Sidef::Types::Glob::File
                  Sidef::DataTypes::Object::Object        Sidef::Object::Object
                  Sidef::DataTypes::Sidef::Sidef          Sidef
                  Sidef::DataTypes::Object::Lazy          Sidef::Object::Lazy
                  Sidef::DataTypes::Object::LazyMethod    Sidef::Object::LazyMethod
                  Sidef::DataTypes::Object::Enumerator    Sidef::Object::Enumerator
                  )
            },

            reassign_ops => {map (("$_=" => $_), qw(+ - % * // / & | ^ ** && || << >> ÷))},

            inc_dec_ops => {
                            '++' => 'inc',
                            '--' => 'dec',
                           },
            %args,
                   );

        $opts{header} .= <<"HEADER";

use utf8;
use ${\($] <= 5.026 ? $] : 5.026)};

HEADER

        if (exists $opts{opt}{P}) {
            my $precision = abs(int($opts{opt}{P}));
            $opts{header} .= "BEGIN { \$Sidef::Types::Number::Number::PREC = 4*$precision; }";
        }

        if (exists $opts{opt}{M}) {
            my $round = unpack('A*', lc($opts{opt}{M}) =~ s/^\s+//r);

            if ($round eq 'zero') {
                $round = 1;
            }
            elsif ($round eq '+inf') {
                $round = 2;
            }
            elsif ($round eq '-inf') {
                $round = 3;
            }
            elsif ($round eq 'inf') {    # away from zero
                $round = 4;
            }
            else {
                $round = 0;
            }

            $opts{header} .= "local \$Sidef::Types::Number::Number::ROUND = $round;";
        }

        %addr    = ();
        %type    = ();
        %top_add = ();
        %const   = ();

        bless \%opts, __PACKAGE__;
    }

    sub make_constant {
        my ($self, $ref, $new_method, $name, @args) = @_;

        if (not $self->{_has_constant}) {
            $self->{_has_constant} = 1;
            $self->{before} .= "use constant {";
        }

        '(' . $self->{environment_name} . '::' . (
            (
             $const{$ref, $#args, @args} //= [
                 $name . @args,
                 do {
                     local $" = ',';
                     $self->{before} .= $name . @args . '=>' . $ref . "->$new_method(@args),";
                   }
             ]
            )->[0]
              . ')'
        );
    }

    sub top_add {
        my ($self, $line) = @_;
        if (not exists $top_add{$line}) {
            undef $top_add{$line};
            $self->{top_program} .= $line;
        }
    }

    sub load_mod {
        my ($self, $mod) = @_;
        $self->top_add(
                       $self->{opt}{c}
                       ? qq{main::__load_sidef_module__("$mod");}
                       : "use $mod;"
                      );
    }

    sub _get_reftype {
        my ($self, $obj) = @_;

        my $ref = ref($obj);

        if (exists $self->{data_types}{$ref}) {
            my $target = $self->{data_types}{$ref};

            $self->{_reftype_cache}{$ref} //= do {
                $self->load_mod($target);
                1;
            };

            return $target;
        }

        ($ref eq 'Sidef::Variable::Struct' || $ref eq 'Sidef::Variable::Subset')
          ? ($self->_dump_class_name($obj) . refaddr($obj))
          : $ref eq 'Sidef::Variable::ClassInit'
          ? (ref($obj->{name}) ? $self->_dump_class_name($obj->{name}) : $self->_dump_class_name($obj))
          : $ref eq 'Sidef::Variable::Ref'           ? 'REF'
          : $ref eq 'Sidef::Types::Block::BlockInit' ? 'Sidef::Types::Block::Block'
          :                                            $ref;
    }

    sub _dump_reftype {
        my ($self, $obj) = @_;
        $self->_dump_string($self->_get_reftype($obj));
    }

    sub _dump_string {
        qq{"\Q$_[1]\E"};
    }

    sub _dump_op_call {
        my ($self, $method) = @_;

        my $name = 'OP' . join('', unpack('C*', $method)) . refaddr($self);
        my $line = "BEGIN { \$$self->{environment_name}\::$name = " . $self->_dump_string($method) . '};';
        $self->top_add($line);
        '->$' . $self->{environment_name} . '::' . $name;
    }

    sub _dump_var {
        my ($self, $var, $refaddr) = @_;

        $var->{name} eq '' and return 'undef';

        (
           exists($var->{array}) ? '@'
         : exists($var->{hash})  ? '%'
         :                         '$'
        )
          . $var->{name}
          . ($refaddr // refaddr($var));
    }

    sub _dump_vars {
        my ($self, @vars) = @_;
        '(' . join(',', map { $self->_dump_var($_) } @vars) . ')';
    }

    sub _dump_init_vars {
        my ($self, $init_obj) = @_;

        my @vars = @{$init_obj->{vars}};
        @vars || return '';

        my @code;

        push @code,
            '('
          . join(',', map { $self->_dump_var($_) } @vars) . ')'
          . (exists($init_obj->{args}) ? '=' . $self->deparse_args($init_obj->{args}) : '');

        foreach my $var (@vars) {

            ref($var) || next;
            if (exists $var->{array}) {
                my $name = $var->{name} . refaddr($var);
                push @{$self->{block_declarations}}, [$self->{current_block} // -1, 'my @' . $name . ';'];

                # Overwrite with the default values, when the array is empty
                if (exists $var->{value}) {
                    push @code, ('@' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not \@$name;");
                }

                $self->load_mod('Sidef::Types::Array::Array');
                push @code, "\$$name = bless(\\\@$name, 'Sidef::Types::Array::Array');";
                delete $var->{array};
            }
            elsif (exists $var->{hash}) {
                my $name = $var->{name} . refaddr($var);
                push @{$self->{block_declarations}}, [$self->{current_block} // -1, 'my %' . $name . ';'];

                # Overwrite with the default values, when the hash has no keys
                if (exists $var->{value}) {
                    push @code, ('%' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not keys \%$name;");
                }

                $self->load_mod('Sidef::Types::Hash::Hash');
                push @code, "\$$name = bless(\\\%$name, 'Sidef::Types::Hash::Hash');";
                delete $var->{hash};
            }
            elsif (exists $var->{value}) {
                my $value = $self->deparse_expr({self => $var->{value}});
                if ($value ne '') {
                    push @code, "\$$var->{name}" . refaddr($var) . "//=$value;";
                }
            }
        }

        push @{$self->{block_declarations}},
          [$self->{current_block} // -1, 'my(' . join(',', map { $self->_dump_var($_) } @vars) . ')' . ';'];

        # Return the lvalue variables on assignments
        if (@code > 1 or exists($init_obj->{args})) {
            push @code, '(' . join(',', map { $self->_dump_var($_) } @vars) . ')';
            return 'CORE::sub:lvalue{' . join(';', @code) . '}->()';
        }

        # Return one var as a list
        '(' . join(',', @code) . ')';
    }

    sub _dump_class_attributes {
        my ($self, @attrs) = @_;

        my %seen;
        my @code;
        foreach my $attr (reverse @attrs) {

            my @vars = @{$attr->{vars}};
            @vars || next;

            my @dumped_vars = map { ref($_) ? $self->_dump_var($_) : $_ } grep { !$seen{$_->{name}}++ } @vars;

            @dumped_vars || next;

            unshift @code,
              (   'my('
                . join(',', @dumped_vars) . ')'
                . (exists($attr->{args}) ? '=' . $self->deparse_args($attr->{args}) : ''));
            foreach my $var (@vars) {
                if (exists $var->{value}) {
                    my $value = $self->deparse_expr({self => $var->{value}});
                    if ($value ne '') {
                        push @code, "\$$var->{name}" . refaddr($var) . "//=$value;";
                    }
                }
            }

        }

        @code ? (join(';', @code) . ';') : '';
    }

    sub _dump_sub_init_vars {
        my ($self, @vars) = @_;

        @vars || return '';

        my @dumped_vars = map { ref($_) ? $self->_dump_var($_) : $_ } @vars;
        my $code = "my(" . join(',', @dumped_vars) . ')=@_;';

        my $valid;
        foreach my $var (@vars) {

            $valid || (shift(@dumped_vars) eq 'undef' ? next : ($valid ||= 1));

            ref($var) || next;
            if (exists $var->{array}) {
                my $name = $var->{name} . refaddr($var);

                # Overwrite with the default values, when the array is empty
                if (exists $var->{value}) {
                    $code .= ('@' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not \@$name;");
                }

                $self->load_mod('Sidef::Types::Array::Array');
                $code .= "my \$$name = bless(\\\@$name, 'Sidef::Types::Array::Array');";
                delete $var->{array};
            }
            elsif (exists $var->{hash}) {
                my $name = $var->{name} . refaddr($var);

                # Overwrite with the default values, when the hash has no keys
                if (exists $var->{value}) {
                    $code .= ('%' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not keys \%$name;");
                }

                $self->load_mod('Sidef::Types::Hash::Hash');
                $code .= "my \$$name = bless(\\\%$name, 'Sidef::Types::Hash::Hash');";
                delete $var->{hash};
            }
            elsif (exists $var->{value}) {
                my $value = $self->deparse_expr({self => $var->{value}});
                if ($value ne '') {
                    $code .= "\$$var->{name}" . refaddr($var) . "//=$value;";
                }
            }
        }

        $valid ? $code : '';
    }

    sub _dump_array {
        my ($self, $ref, $array) = @_;
        $self->load_mod($ref);
        'bless([' . join(',', map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}) } @{$array}) . "], '$ref')";
    }

    sub _dump_indices {
        my ($self, $array) = @_;

        join(
            ',',
            grep { $_ ne '' } map {
                ref($_) eq 'Sidef::Types::Number::Number'
                  ? Sidef::Types::Number::Number::__numify__($$_)
                  : ref($_)
                  ? ('(map { ref($_) eq "Sidef::Types::Number::Number" ? Sidef::Types::Number::Number::__numify__($$_) '
                     . ': do {my$sub=UNIVERSAL::can($_, "..."); '
                     . 'defined($sub) ? $sub->($_) : CORE::int($_) } } '
                     . ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_})) . ')')
                  : $_
            } @{$array}
        );
    }

    sub _dump_lookups {
        my ($self, $array) = @_;

        join(
            ',',
            grep { $_ ne '' } map {
                (ref($_) eq 'Sidef::Types::String::String' or ref($_) eq 'Sidef::Types::Number::Number')
                  ? $self->_dump_string("$_")
                  : ref($_) ?    ('(map { ref($_) eq "Sidef::Types::String::String" ? $$_ : "$_" }'
                               . ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_})) . ')')
                  : qq{"\Q$_\E"}
            } @{$array}
        );
    }

    sub _dump_var_attr {
        my ($self, @vars) = @_;

        'vars=>[' . join(
            ',',
            map {
                    '{name=>'
                  . $self->_dump_string($_->{name})
                  . (exists($_->{slurpy})    ? (',slurpy=>' . $_->{slurpy})                       : '')
                  . (exists($_->{ref_type})  ? (',type=>' . $self->_dump_reftype($_->{ref_type})) : '')
                  . (exists($_->{subset})    ? (',subset=>' . $self->_dump_reftype($_->{subset})) : '')
                  . (exists($_->{has_value}) ? (',has_value=>1')                                  : '')
                  . (
                    exists($_->{subset_blocks}) ? (
                       ',subset_blocks=>[' . join(
                           ',',
                           map {
                               $self->{_subset_cache}{refaddr($_)} //=
                                   'sub{'
                                 . $self->_dump_sub_init_vars($_->{init_vars}{vars}[0])
                                 . $self->deparse_generic('', ';', '', $_->{code}) . '}'
                           } @{$_->{subset_blocks}}
                         )
                         . ']'
                      )
                    : ''
                    )
                  . (
                     exists($_->{where_block})
                     ? (',where_block=>sub{'
                        . $self->_dump_sub_init_vars($_->{where_block}{init_vars}{vars}[0])
                        . $self->deparse_generic('', ';', '', $_->{where_block}{code}) . '}')
                     : ''
                    )
                  . (
                     exists($_->{where_expr}) ? (',where_expr=>do{' . $self->deparse_expr({self => $_->{where_expr}}) . '}')
                     : ''
                    )
                  . '}'
              } @vars
          )
          . ']' . ','
          . 'table=>{'
          . join(',', map { $self->_dump_string($vars[$_]{name}) . '=>' . $_ } 0 .. $#vars) . '}';
    }

    sub _get_inherited_stuff {
        my ($self, $classes, $callback) = @_;

        my @vars;
        foreach my $class (@{$classes}) {
            push @vars, $callback->($class);
            if (exists $class->{inherit}) {
                unshift @vars, $self->_get_inherited_stuff($class->{inherit}, $callback);
            }
        }

        @vars;
    }

    sub _dump_class_name {
        my ($self, $class) = @_;
        join('::',
             $self->{environment_name},
             $class->{class} || 'main',
             $class->{name}  || (Sidef::normalize_type(ref($class)) . refaddr($class)));
    }

    sub deparse_generic {
        my ($self, $before, $sep, $after, @args) = @_;
        $before . join(
            $sep,
            map {
                    ref($_) eq 'HASH' ? $self->deparse_script($_)
                  : ref($_) ? $self->deparse_expr({self => $_})
                  : $self->_dump_string($_)
              } @args
          )
          . $after;
    }

    sub deparse_args {
        my ($self, @args) = @_;
        $self->deparse_generic('(', ',', ')', @args);
    }

    sub deparse_bare_block {
        my ($self, @args) = @_;
        my $code = $self->deparse_generic('{', ';', '}', @args);
        $code;
    }

    sub deparse_block_with_scope {
        my ($self, $obj) = @_;

        my $refaddr = refaddr($obj);
        local $self->{current_block} = $refaddr;

        my @statements = join(';', $self->deparse_script($obj->{code}));

        my $code = '{';

        # Localize variable declarations
        while (    exists($self->{block_declarations})
               and @{$self->{block_declarations}}
               and $self->{block_declarations}[-1][0] == $refaddr) {
            $code .= pop(@{$self->{block_declarations}})->[1];
        }

        $code . join(';', @statements) . '}';
    }

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $code    = '';
        my $obj     = $expr->{self};
        my $refaddr = refaddr($obj);

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $code = join(',', exists($obj->{self}) ? $self->deparse_expr($obj) : $self->deparse_script($obj));
        }
        elsif ($ref eq 'Sidef::Variable::Variable') {
            if ($obj->{type} eq 'var' or $obj->{type} eq 'has') {

                my $name = $obj->{name} . $refaddr;

                if ($obj->{name} eq 'ENV') {
                    $self->top_add("require Encode;");
                    $self->top_add(  qq{my \$$name = Sidef::Types::Hash::Hash->new}
                                   . qq{(map{Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \%ENV);});
                }
                elsif ($obj->{name} eq 'ARGV') {
                    $self->top_add("require Encode;");
                    $self->top_add(  qq{my \$$name = Sidef::Types::Array::Array->new}
                                   . qq{([map {Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \@ARGV]);});
                }

                $code = $self->_dump_var($obj, $refaddr);
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {

                if ($addr{$refaddr}++) {
                    $code = "\$$obj->{name}$refaddr";
                }
                else {
                    my $block = $obj->{value};

                    # Anonymous function
                    if ($obj->{name} eq '') {
                        $obj->{name} = "__FUNC__";
                    }

                    my $name = $obj->{name};

                    # Check for alphanumeric name
                    if (not $obj->{name} =~ /^[^\W\d]\w*+\z/) {
                        $obj->{name} = '__NONANN__';    # use this name for non-alphanumeric names
                    }

                    # The name of the function
                    $code .= "\$$obj->{name}$refaddr";

                    # Deparse the block of the method/function
                    {
                        local $self->{function}          = refaddr($block);
                        local $self->{parent_name}       = [$obj->{type}, $name];
                        local $self->{current_namespace} = $obj->{class};
                        push @{$self->{function_declarations}}, [$self->{function}, "my \$$obj->{name}$refaddr;"];

                        if ($self->{ref_class}) {
                            push @{$self->{function_declarations}},
                              [ $self->{function},
                                qq{state \$$obj->{name}_code$refaddr = UNIVERSAL::can("\Q$self->{class_name}\E", "\Q$name\E");}
                              ];
                        }

                        if ((my $content = $self->deparse_expr({self => $block})) ne '') {
                            $code .= "=$content";
                        }
                    }

                    # Check to see if the method/function has kids (can do multiple dispatch)
                    if (exists $obj->{value}{kids}) {
                        chop $code;
                        my @kids = map {
                            local $_->{type}   = 'func';
                            local $_->{is_kid} = 1;
                            'do{' . $self->deparse_expr({self => $_}) . '}';
                        } @{$obj->{value}{kids}};

                        $code .= ',kids=>[' . join(',', @kids);

                        if ($self->{ref_class}) {
                            $code .= qq{,(defined(\$$obj->{name}_code$refaddr)?}
                              . qq{Sidef::Types::Block::Block->new(code=>\$$obj->{name}_code$refaddr):())};
                        }

                        $code .= '])';
                    }
                    elsif ($self->{ref_class}) {
                        chop $code;
                        $code .= qq{,(defined(\$$obj->{name}_code$refaddr)?(kids=>[}
                          . qq{Sidef::Types::Block::Block->new(code=>\$$obj->{name}_code$refaddr)]):()))};
                    }

                    # Check the return value (when "-> Type" is specified)
                    if (exists $obj->{returns}) {
                        my $types = '[' . join(',', map { $self->_dump_reftype($_) } @{$obj->{returns}}) . ']';
                        $code = "do{$code;\$$obj->{name}$refaddr\->{returns}=$types;\$$obj->{name}$refaddr}";
                    }

                    # Memoize the method/function (when "is cached" trait is specified)
                    if ($obj->{cached}) {
                        $self->top_add("require Memoize;");
                        $code =
                            "do{$code;"
                          . "\$$obj->{name}$refaddr\->{code}=Memoize::memoize(\$$obj->{name}${refaddr}->{code});\$$obj->{name}$refaddr}";
                    }

                    if ($obj->{type} eq 'func' and not $obj->{is_kid}) {

                        # Special "MAIN" function
                        if ($obj->{name} eq 'MAIN') {
                            $self->top_add('require Encode;');
                            $code .=
                              ";Sidef::Variable::GetOpt->new([map{Encode::decode_utf8(\$_)}\@ARGV],\$$obj->{name}$refaddr)";
                        }

                    }
                    elsif ($obj->{type} eq 'method') {

                        # Special "AUTOLOAD" method
                        if ($obj->{name} eq 'AUTOLOAD') {
                            $code .= ';'
                              . "our\$AUTOLOAD;"
                              . "sub $obj->{name} {my\$self=shift;"
                              . "my(\$class,\$method)=(\$AUTOLOAD=~/^(.*[^:])::(.*)\$/);"
                              . "\$$obj->{name}$refaddr->call(\$self,Sidef::Types::String::String->new(\$class),Sidef::Types::String::String->new(\$method),\@_)}";
                        }

                        # Anonymous method
                        elsif ($obj->{name} eq '__FUNC__') {
                            ## don't add anonymous methods to the class,
                            ## but allow them to be defined and used freely
                        }

                        # Other methods
                        else {
                            $code .= ";"
                              . "state\$_$refaddr=do{no strict 'refs';"
                              . "\$$self->{package_name}::__SIDEF_CLASS_METHODS__{'$name'} = \$$obj->{name}$refaddr;"
                              . '*{'
                              . $self->_dump_string("$self->{package_name}::$name")
                              . "}=sub{\$$obj->{name}$refaddr->call(\@_)}}";
                        }

                        # Add the "overload" pragma for some special methods
                        if (exists $self->{overload_methods}{$name}) {
                            my $overload_name = $self->{overload_methods}{$name};
                            $code .= ";"
                              . qq(use overload q{$overload_name} =>)
                              . q(sub{my($first,$second,$swap)=@_;)
                              . q(if($swap){($first,$second)=($second,$first)})
                              . q($first)
                              . $self->_dump_op_call($name)
                              . q(($second)};);
                        }

                    }
                }
            }
        }
        elsif ($ref eq 'Sidef::Operator::Unary') {
            ## OK
        }
        elsif ($ref eq 'Sidef::Variable::Local') {
            $code = 'local ' . (defined($obj->{expr}) ? $self->deparse_args($obj->{expr}) : '()');
        }
        elsif ($ref eq 'Sidef::Variable::Global') {
            my $name = '$' . $obj->{class} . '::' . $obj->{name};
            if (not exists($obj->{inited}) and defined($obj->{expr})) {
                $obj->{inited} = 1;
                $code = $name . '=do{' . $self->deparse_script($obj->{expr}) . '}';
            }
            else {
                $code = $name;
            }
        }
        elsif ($ref eq 'Sidef::Variable::ClassVar') {
            $code = '$' . $self->_get_reftype($obj->{class}) . '::' . $obj->{name};
        }
        elsif ($ref eq 'Sidef::Variable::Define') {
            my $name  = $obj->{name} . $refaddr;
            my $value = '(' . $self->{environment_name} . '::' . $name . ')';
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $self->top_add('use constant ' . $name . '=>do{' . $self->deparse_script($obj->{expr}) . '};');
            }
            $code = $value;
        }
        elsif ($ref eq 'Sidef::Variable::Const') {
            my $name  = $obj->{name} . $refaddr;
            my $value = '(' . $name . ')';
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;

                # Use dynamical constants inside functions
                if (exists($self->{function}) or (exists($self->{class}) and $] >= 5.022)) {

                    # This is no longer needed in Perl>=5.25.2
                    $] < 5.025002 && $self->top_add(q{use feature 'lexical_subs'; no warnings 'experimental::lexical_subs';});

                    # XXX: this is known to cause segmentation faults in perl-5.18.* and perl-5.20.* when used in a class
                    $code = "my sub $name(){state\$_$refaddr"
                      . (defined($obj->{expr}) ? ('=do{' . $self->deparse_script($obj->{expr}) . '}') : '') . '}';
                }

                # Otherwise, use static constants
                else {
                    $code = "sub $name(){state\$_$refaddr"
                      . (defined($obj->{expr}) ? ('=do{' . $self->deparse_script($obj->{expr}) . '}') : '') . '}';
                }
            }
            else {
                $code = $value;
            }
        }
        elsif ($ref eq 'Sidef::Variable::Static') {
            my $name  = $obj->{name} . $refaddr;
            my $value = "\$$name";
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $code =
                  "(state\$$name" . (defined($obj->{expr}) ? ('=do{' . $self->deparse_script($obj->{expr}) . '}') : '') . ')';
            }
            else {
                $code = $value;
            }
        }
        elsif ($ref eq 'Sidef::Variable::ConstInit') {
            $code = join(($obj->{type} eq 'global' ? ',' : ';'), map { $self->deparse_expr({self => $_}) } @{$obj->{vars}});
        }
        elsif ($ref eq 'Sidef::Variable::Init') {
            $code = $self->_dump_init_vars($obj);
        }
        elsif ($ref eq 'Sidef::Variable::ClassInit') {
            my $name = $self->_get_reftype($obj);
            if ($addr{$refaddr}++) {
                $code = q{'} . $name . q{'};
            }
            else {
                my $block = $obj->{block};

                $code = 'do{package ';

                my $package_name;
                if (ref $obj->{name}) {
                    $code .= ($package_name = $self->_get_reftype($obj->{name}));
                }
                else {
                    $code .= ($package_name = $name);
                }

                local $self->{class}            = refaddr($block);
                local $self->{class_name}       = $package_name;
                local $self->{parent_name}      = ['class', $package_name];
                local $self->{package_name}     = $package_name;
                local $self->{inherit}          = $obj->{inherit} if exists $obj->{inherit};
                local $self->{class_vars}       = $obj->{vars} if exists $obj->{vars};
                local $self->{class_attributes} = $obj->{attributes} if exists $obj->{attributes};
                local $self->{ref_class}        = 1 if ref($obj->{name});
                $code .= $self->deparse_expr({self => $block});
                $code .= ";'$package_name'}";
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::BlockInit') {
            if ($addr{$refaddr}++) {
                $code = "state\$_$refaddr=" . q{Sidef::Types::Block::Block->new(code=>__SUB__,type=>'block'};

                if (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}}) {
                    $code .= ',' . $self->_dump_var_attr(@{$obj->{init_vars}{vars}});
                }

                $code .= ')';
            }
            else {
                if (%{$obj}) {

                    my $is_function = exists($self->{function}) && $self->{function} == $refaddr;
                    my $is_class    = exists($self->{class})    && $self->{class} == $refaddr;

                    local $self->{current_block} = $refaddr;

                    if ($is_class) {
                        $code = '{';

                        if ($is_class) {
                            my $class_name = $self->{class_name};
                            my $base_pkgs = (
                                             exists($self->{inherit})
                                             ? (
                                                join(' ',
                                                     grep { $_ ne $class_name }
                                                     map { ref($_) ? $self->_get_reftype($_) : $_ } @{$self->{inherit}})
                                               )
                                             : ''
                                            )
                              . (exists($self->{ref_class}) ? '' : ' Sidef::Object::Object');

                            if ($base_pkgs ne '') {
                                $code .= "use parent qw(-norequire $base_pkgs);";
                            }
                        }

                        ## TODO: find a simpler and more elegant solution
                        if ($is_class and not exists($self->{ref_class})) {

                            my @class_vars = do {
                                my %seen;
                                reverse grep { !$seen{$_->{name}}++ }
                                  reverse(
                                          exists($self->{inherit})
                                          ? $self->_get_inherited_stuff($self->{inherit},
                                                                        sub { exists($_[0]->{vars}) ? @{$_[0]->{vars}} : () })
                                          : (),
                                          @{$self->{class_vars}}
                                         );
                            };

                            my @class_attributes = do {
                                my %seen;
                                (
                                 exists($self->{inherit})
                                 ? $self->_get_inherited_stuff(
                                                              $self->{inherit},
                                                              sub { exists($_[0]->{attributes}) ? @{$_[0]->{attributes}} : () }
                                   )
                                 : (),
                                 (exists($self->{class_attributes}) ? @{$self->{class_attributes}} : ())
                                );
                            };

                            $code .= "\$new$refaddr=Sidef::Types::Block::Block->new(code=>sub{";
                            push @{$self->{function_declarations}}, [$refaddr, "my \$new$refaddr;"];

                            $code .=
                              $self->_dump_sub_init_vars(@class_vars) . $self->_dump_class_attributes(@class_attributes);

                            my @class_var_attributes = do {
                                my %seen;
                                reverse(grep { !$seen{$_->{name}}++ } map { @{$_->{vars}} } reverse(@class_attributes));
                            };

                            $code .= 'my$self=bless{';
                            foreach my $var (@class_vars, @class_var_attributes) {
                                $code .= qq{"\Q$var->{name}\E"=>} . $self->_dump_var($var) . ', ';
                            }

                            $code .=
                              '},__PACKAGE__;' . 'if(defined(my$sub=UNIVERSAL::can($self,"init"))){$sub->($self)}' . '$self;';

                            $code .=
                                '},'
                              . $self->_dump_var_attr(@class_vars)
                              . ',type=>'
                              . $self->_dump_string('class')
                              . ',name=>'
                              . $self->_dump_string($self->{parent_name}[1]) . ');'
                              . "state\$_$refaddr=do{no strict 'refs';*{"
                              . $self->_dump_string("$self->{package_name}\::new") . '}=*{'
                              . $self->_dump_string("$self->{package_name}\::call")
                              . "}=sub{CORE::shift(\@_);\$new$refaddr->call(\@_)}};";

                            foreach my $var (@class_vars, @class_var_attributes) {
                                $code .= qq{sub $var->{name}:lvalue{\$_[0]->{"\Q$var->{name}\E"}}};
                            }
                        }
                    }
                    else {
                        $code = 'Sidef::Types::Block::Block->new(';
                    }

                    if (not $is_class) {

                        $code .= 'code=>sub{';

                        if (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}}) {
                            $code .= $self->_dump_sub_init_vars(@{$obj->{init_vars}{vars}});
                        }

                        if ($is_function) {
                            $code .= 'my @return;';
                        }
                    }

                    my @statements = $self->deparse_script($obj->{code});

                    # Localize function declarations
                    if ($is_function) {
                        while (    exists($self->{function_declarations})
                               and @{$self->{function_declarations}}
                               and $self->{function_declarations}[-1][0] != $refaddr) {
                            $code .= pop(@{$self->{function_declarations}})->[1];
                        }
                    }

                    # Localize variable declarations
                    while (    exists($self->{block_declarations})
                           and @{$self->{block_declarations}}
                           and $self->{block_declarations}[-1][0] == $refaddr) {
                        $code .= pop(@{$self->{block_declarations}})->[1];
                    }

                    # Make the last statement to be the return value
                    if ($is_function && @statements) {
                        $statements[-1] = 'return do{' . $statements[-1] . '}';
                    }

                    $code .= join(';', @statements) . ($is_function ? (';' . "END$refaddr: \@return;") : '') . '}';

                    if (not $is_class) {
                        if ($is_function) {
                            $code .= ','
                              . join(',',
                                     'type=>' . $self->_dump_string($self->{parent_name}[0]),
                                     'name=>' . $self->_dump_string($self->{parent_name}[1]));
                        }
                        else {
                            $code .= ','
                              . join(',', 'type=>' . $self->_dump_string('block'),
                                     'name=>' . $self->_dump_string('__BLOCK__'),);
                        }

                        if (exists $self->{class_name}) {
                            $code .= ',class=>' . $self->_dump_string($self->{class_name});
                        }

                        if (exists($self->{current_namespace}) and $self->{current_namespace} ne 'main') {
                            $code .= ',namespace=>' . $self->_dump_string($self->{current_namespace});
                        }

                        if (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}}) {
                            $code .= ',' . $self->_dump_var_attr(@{$obj->{init_vars}{vars}});
                        }
                        $code .= ')';
                    }
                }
                else {
                    $code = q{'Sidef::Types::Block::Block'};
                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::ClassAttr') {
            ## ok
        }
        elsif ($ref eq 'Sidef::Variable::Struct') {
            my $name = $self->_get_reftype($obj);
            if ($addr{$refaddr}++) {
                $code = "'$name'";
            }
            else {
                $code =
                    "do{package $name {"
                  . "\$new$refaddr=Sidef::Types::Block::Block->new(code=>sub{"
                  . $self->_dump_sub_init_vars(@{$obj->{vars}})
                  . 'bless{'
                  . join(',', map { $self->_dump_string($_->{name}) . '=>' . $self->_dump_var($_) } @{$obj->{vars}})
                  . "},__PACKAGE__" . '},'
                  . 'name=>'
                  . $self->_dump_string($name) . ','
                  . 'type=>'
                  . $self->_dump_string('struct') . ','
                  . $self->_dump_var_attr(@{$obj->{vars}}) . ');'
                  . "state \$_$refaddr = do{no strict 'refs';*{"
                  . $self->_dump_string("$name\::new") . "}=*{"
                  . $self->_dump_string("$name\::call")
                  . "}=sub{CORE::shift(\@_);\$new$refaddr->call(\@_)}};"
                  . join('', map { "sub $_->{name}:lvalue{\$_[0]->{$_->{name}}}" } @{$obj->{vars}})
                  . "};'$name'}";

                push @{$self->{function_declarations}}, [$refaddr, "my\$new$refaddr;"];
            }
        }
        elsif ($ref eq 'Sidef::Variable::Subset') {
            my $name = $self->_get_reftype($obj);
            if ($addr{$refaddr}++) {
                $code = "'$name'";
            }
            else {
                my @parents = map { $self->_get_reftype($_) } @{$obj->{inherits}};
                $code = qq{do{package $name {use parent qw(-norequire @parents)};'$name'}};
            }
        }
        elsif ($ref eq 'Sidef::Types::Number::Number') {
            my ($type, $content) = $obj->_dump;

            if (    $type eq 'int'
                and CORE::int($content) eq $content
                and $content >= 0
                and $content < Sidef::Types::Number::Number::ULONG_MAX) {
                $code = $self->make_constant($ref, '_set_uint', "Number$refaddr", "'$content'");
            }
            elsif (    $type eq 'int'
                   and CORE::int($content) eq $content
                   and $content < 0
                   and $content > Sidef::Types::Number::Number::LONG_MIN) {
                $code = $self->make_constant($ref, '_set_int', "Number$refaddr", "'$content'");
            }
            else {
                $code = $self->make_constant($ref, '_set_str', "Number$refaddr", "'$type'", "'$content'");
            }
        }
        elsif ($ref eq 'Sidef::Types::String::String') {
            $code = $self->make_constant($ref, 'new', "String$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Sidef::Types::Array::Array' or $ref eq 'Sidef::Types::Array::HCArray') {
            $code = $self->_dump_array('Sidef::Types::Array::Array', $obj);
        }
        elsif ($ref eq 'Sidef::Types::Bool::Bool') {
            $code = 'Sidef::Types::Bool::Bool::' . (${$obj} ? 'TRUE' : 'FALSE');
        }
        elsif ($ref eq 'Sidef::Types::Regex::Regex') {
            $code =
              $self->make_constant($ref, 'new', "Regex$refaddr",
                                   $self->_dump_string("$obj->{raw}"),
                                   $self->_dump_string($obj->{flags} . ($obj->{global} ? 'g' : '')));
        }
        elsif ($ref eq 'Sidef::Types::Block::If') {
            $code = 'do{';
            foreach my $i (0 .. $#{$obj->{if}}) {
                $code .= ($i == 0 ? 'if' : 'elsif');
                my $info = $obj->{if}[$i];
                my $vars = join(',', map { $self->_dump_var($_) } @{$info->{block}{init_vars}{vars}});
                my $arg  = $self->deparse_args($info->{expr});

                if ($vars) {
                    $arg = "(my ($vars) = $arg)[-1]";
                }

                $code .= '(' . $arg . ')' . $self->deparse_block_with_scope($info->{block});
            }
            if (exists $obj->{else}) {
                $code .= 'else' . $self->deparse_block_with_scope($obj->{else}{block});
            }
            $code .= '}';
        }
        elsif ($ref eq 'Sidef::Types::Block::While') {
            my $vars = join(',', map { $self->_dump_var($_) } @{$obj->{block}{init_vars}{vars}});
            my $arg = $self->deparse_args($obj->{expr});

            if ($vars) {
                $arg = "(my ($vars) = $arg)[-1]";
            }

            $code = 'while(' . $arg . ')' . $self->deparse_block_with_scope($obj->{block});
        }
        elsif ($ref eq 'Sidef::Types::Block::ForEach') {
            $code = $self->deparse_args($obj->{expr}) . '->each' . '(' . $self->deparse_expr({self => $obj->{block}}) . ')';
        }
        elsif ($ref eq 'Sidef::Types::Block::CFor') {
            $code = 'for('
              . join(';', map { $self->deparse_args($_) } @{$obj->{expr}}) . ')'
              . $self->deparse_block_with_scope($obj->{block});
        }
        elsif ($ref eq 'Sidef::Types::Block::ForIn') {
            $self->load_mod('Sidef::Types::Block::Block');

            my @vars = map { $self->_dump_sub_init_vars(@{$_->{vars}}) } @{$obj->{loops}};
            my $block = 'do' . $self->deparse_block_with_scope($obj->{block});

            my @loops = @{$obj->{loops}};

            $code = $block;

            while (@loops) {

                my $loop = pop(@loops);
                my $vars = pop @vars;
                my $expr = $self->deparse_args($loop->{expr});

                my $multi = 0;
                if (
                    @{$loop->{vars}} > 1
                    or (@{$loop->{vars}} == 1
                        and exists($loop->{vars}[0]{slurpy}))
                  ) {
                    $multi = 1;
                }

                $code =
                    'Sidef::Types::Block::Block::_iterate(sub { '
                  . 'my ($item) = @_; '
                  . 'local @_ = '
                  . ($multi ? '@{('      : '') . '$item'
                  . ($multi ? ')->to_a}' : '')
                  . "; $vars; $code }, $expr)"
                  . (@loops ? ' // last' : '') . ';';
            }
        }
        elsif ($ref eq 'Sidef::Types::Bool::Ternary') {
            $code = '('
              . $self->deparse_script($obj->{cond}) . '?'
              . $self->deparse_args($obj->{true}) . ':'
              . $self->deparse_args($obj->{false}) . ')';
        }
        elsif ($ref eq 'Sidef::Variable::NamedParam') {
            $code = $ref . '->new(' . $self->_dump_string($obj->[0]) . ', ' . $self->deparse_args(@{$obj->[1]}) . ')';
        }
        elsif ($ref eq 'Sidef::Types::Nil::Nil') {
            $code = 'undef';
        }
        elsif ($ref eq 'Sidef::Types::Hash::Hash') {
            $self->load_mod($ref);
            $code = 'bless({' . join(
                ',',
                map {
                    $self->_dump_string($_) . '=>'
                      . (defined($obj->{$_}) ? $self->deparse_expr({self => $obj->{$_}}) : 'undef')
                } sort(keys(%{$obj}))
              )
              . "}, '$ref')";
        }
        elsif ($ref eq 'Sidef::Meta::PrefixMethod') {
            $code = 'do{my($self,@args)=' . $self->deparse_args($obj->{expr}) . ';$self->' . $obj->{name} . '(@args)}';
        }
        elsif ($ref eq 'Sidef::Types::Block::Do') {
            $code = 'do' . $self->deparse_block_with_scope($obj->{block});
        }
        elsif ($ref eq 'Sidef::Types::Block::Loop') {
            $code = 'while(1)' . $self->deparse_block_with_scope($obj->{block});
        }
        elsif ($ref eq 'Sidef::Types::Block::Given') {
            $self->top_add(q{no warnings 'experimental::smartmatch';});

            my $vars = join(',', map { $self->_dump_var($_) } @{$obj->{block}{init_vars}{vars}});

            $code =
                "sub { my \@given_values; my \$continue = 1; my \$given_value = (my ($vars) = "
              . $self->deparse_args($obj->{expr})
              . ')[-1];' . 'do'
              . $self->deparse_block_with_scope($obj->{block})
              . '; wantarray ? @given_values : $given_values[-1] }->()';
        }
        elsif ($ref eq 'Sidef::Types::Block::When') {
            my $vars = join(',', map { $self->_dump_var($_) } @{$obj->{block}{init_vars}{vars}});
            my $arg = $self->deparse_args($obj->{expr});

            if ($vars) {
                $arg = "(my ($vars) = $arg)[-1]";
            }

            $code =
                "if (\$continue) {my \$t = $arg;"
              . "if (defined(\$given_value) ? defined(\$t) ? (\$given_value ~~ \$t) : 0 : 1) {"
              . "\$continue = 0; \@given_values = do"
              . $self->deparse_block_with_scope($obj->{block}) . "}};";
        }
        elsif ($ref eq 'Sidef::Types::Block::Case') {
            my $vars = join(',', map { $self->_dump_var($_) } @{$obj->{block}{init_vars}{vars}});
            my $arg = $self->deparse_args($obj->{expr});

            if ($vars) {
                $arg = "(my ($vars) = $arg)[-1]";
            }

            $code =
                "if (\$continue and $arg) { \$continue = 0;"
              . "\@given_values = do"
              . $self->deparse_block_with_scope($obj->{block}) . '}';
        }
        elsif ($ref eq 'Sidef::Types::Block::Default') {
            $code =
              "if (\$continue) { \$continue = 0; \@given_values = do" . $self->deparse_block_with_scope($obj->{block}) . '}';
        }
        elsif ($ref eq 'Sidef::Types::Block::Continue') {
            $code = '$continue = 1';
        }
        elsif ($ref eq 'Sidef::Types::Block::With') {
            $code = 'do{';
            foreach my $i (0 .. $#{$obj->{with}}) {
                $code .= ($i == 0 ? 'if' : 'elsif');
                my $info = $obj->{with}[$i];
                my $vars = join(',', map { $self->_dump_var($_) } @{$info->{block}{init_vars}{vars}});
                $code .=
                    "(defined((my ($vars) = do{"
                  . $self->deparse_args($info->{expr})
                  . '})[-1]))'
                  . $self->deparse_block_with_scope($info->{block});
            }
            if (exists $obj->{else}) {
                $code .= 'else' . $self->deparse_block_with_scope($obj->{else}{block});
            }
            $code .= '}';
        }
        elsif ($ref eq 'Sidef::Types::Block::Gather') {
            $self->load_mod("Sidef::Types::Array::Array");
            $code =
                "do{my \@_$refaddr;" . 'do'
              . $self->deparse_block_with_scope($obj->{block})
              . "; bless(\\\@_$refaddr, 'Sidef::Types::Array::Array')}";
        }
        elsif ($ref eq 'Sidef::Types::Block::Take') {
            my $raddr = refaddr($obj->{gather});
            $code = "do{ push \@_$raddr," . $self->deparse_args($obj->{expr}) . "; \$_$raddr\[-1] }";
        }
        elsif ($ref eq 'Sidef::Types::Block::Try') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Variable::Ref') {
            ## ok
        }
        elsif ($ref eq 'Sidef::Types::Block::Break') {
            $code = 'last';
        }
        elsif ($ref eq 'Sidef::Types::Block::Next') {
            $code = 'next';
        }
        elsif ($ref eq 'Sidef::Types::Block::Return') {

            # This is no longer supported
            if (not exists $expr->{call}) {

                if (exists $self->{function}) {
                    $code = "goto END$self->{function}";
                }
                else {
                    $code = "return;";
                }
            }
        }
        elsif ($ref eq 'Sidef::Math::Math') {
            $code = $self->make_constant($ref, 'new', "Math$refaddr");
        }
        elsif ($ref eq 'Sidef::Meta::Glob::STDIN') {
            $code = $self->make_constant('Sidef::Types::Glob::FileHandle', 'new', "STDIN$refaddr", '\*STDIN');
        }
        elsif ($ref eq 'Sidef::Meta::Glob::STDOUT') {
            $code = $self->make_constant('Sidef::Types::Glob::FileHandle', 'new', "STDOUT$refaddr", '\*STDOUT');
        }
        elsif ($ref eq 'Sidef::Meta::Glob::STDERR') {
            $code = $self->make_constant('Sidef::Types::Glob::FileHandle', 'new', "STDERR$refaddr", '\*STDERR');
        }
        elsif ($ref eq 'Sidef::Meta::Glob::ARGF') {
            $code = $self->make_constant('Sidef::Types::Glob::FileHandle', 'new', "ARGF$refaddr", '\*ARGV');
        }
        elsif ($ref eq 'Sidef::Meta::Glob::DATA') {
            require Encode;
            my $data = $self->_dump_string(Encode::encode_utf8(${$obj->{data}}));
            $code = $self->make_constant('Sidef::Types::Glob::FileHandle', 'new',
                                         "DATA$refaddr",                   qq{do{open my \$fh, '<:utf8', \\$data; \$fh}});
        }
        elsif ($ref eq 'Sidef::Variable::Magic') {
            $code = $obj->{name};
        }
        elsif ($ref eq 'Sidef::Types::Glob::Socket') {
            $code = $self->make_constant($ref, 'new', "Socket$refaddr");
        }
        elsif ($ref eq 'Sidef::Eval::Eval') {
            $Sidef::EVALS{$refaddr} = $obj;
            $code = qq~
            eval do{
            local \$Sidef::DEPARSER->{before} = '';
            local \$Sidef::DEPARSER->{top_program} = '';
            local \$Sidef::DEPARSER->{_has_constant};
            local \$Sidef::DEPARSER->{function_declarations} = [];
            local \$Sidef::DEPARSER->{block_declarations} = [];
            \$Sidef::DEPARSER->deparse(
            do{
                local \$Sidef::PARSER->{line} = 0;
                local \$Sidef::PARSER->{file_name} = 'eval($refaddr)';
                local \$Sidef::PARSER->{vars} = \$Sidef::EVALS{$refaddr}{vars};
                local \$Sidef::PARSER->{ref_vars_refs} = \$Sidef::EVALS{$refaddr}{ref_vars_refs};
                \$Sidef::PARSER->parse_script(code => do{my\$o=~ . $self->deparse_args($obj->{expr}) . qq~;\\"\$o"});
            })}~;
        }
        elsif ($ref eq 'Sidef::Time::Time') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Sys::Sig') {
            $code = $self->make_constant($ref, 'new', "Sig$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::Number::Complex') {
            my ($real, $imag) = $obj->reals;
            my $name = "Complex$refaddr";
            $self->top_add(  "use constant $name => $ref\->new("
                           . join(',', $self->deparse_expr({self => $real}), $self->deparse_expr({self => $imag}))
                           . ');');
            $code = "($self->{environment_name}\::$name)";
        }
        elsif ($ref eq 'Sidef::Types::Array::Pair') {
            $code =
              $ref . '->new(' . join(',', map { defined($_) ? $self->deparse_expr({self => $_}) : 'undef' } @{$obj}) . ')';
        }
        elsif ($ref eq 'Sidef::Types::Null::Null') {
            $code = $self->make_constant($ref, 'new', "Null$refaddr");
        }
        elsif ($ref eq 'Sidef::Module::OO') {
            $code = $self->make_constant($ref, '__NEW__', "MOD_OO$refaddr", $self->_dump_string($obj->{module}));
        }
        elsif ($ref eq 'Sidef::Module::Func') {
            $code = $self->make_constant($ref, '__NEW__', "MOD_F$refaddr", $self->_dump_string($obj->{module}));
        }
        elsif ($ref eq 'Sidef::Types::Range::RangeNumber' or $ref eq 'Sidef::Types::Range::RangeString') {
            $code = $self->make_constant(
                $ref, 'new',
                "Range$refaddr",
                map {
                    my ($type, $content) = $obj->{$_}->_dump;
                    'Sidef::Types::Number::Number->_set_str(' . "'$type', '$content'" . ')'
                } ('from', 'to', 'step')
            );
        }
        elsif ($ref eq 'Sidef::Types::Glob::Backtick') {
            $code = $self->make_constant($ref, 'new', "Backtick$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Sidef::Types::Glob::File') {
            $code = $self->make_constant($ref, 'new', "File$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Sidef::Types::Glob::Dir') {
            $code = $self->make_constant($ref, 'new', "Dir$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Sidef::Sys::Sys') {
            $code = $self->make_constant($ref, 'new', "Sys$refaddr");
        }
        elsif ($ref eq 'Sidef::Meta::Assert') {
            my @args = $self->deparse_script($obj->{arg});

            if ($obj->{act} eq 'assert') {

                # Check arity
                @args > 2
                  and die "[ERROR] Incorrect number of arguments for $obj->{act}\() at"
                  . " $obj->{file} line $obj->{line} (expected 1 or 2 arguments)\n";

                # Generate code
                $code =
                    qq~do{my \$a$refaddr = do{$args[0]}; ~
                  . qq~my \$m$refaddr = do{$args[1]} // "$obj->{act}(\$a$refaddr)";~
                  . qq~\$a$refaddr or CORE::die "\$m$refaddr failed ~
                  . qq~at \Q$obj->{file}\E line $obj->{line}\\n"}~;
            }
            elsif ($obj->{act} eq 'assert_eq' or $obj->{act} eq 'assert_ne') {

                # Check arity
                @args > 3
                  and die "[ERROR] Incorrect number of arguments for $obj->{act}\() at"
                  . " $obj->{file} line $obj->{line} (expected 2 or 3 arguments)\n";

                # Generate code
                $code = "do{"
                  . "my \$a$refaddr = do{$args[0]};"
                  . "my \$b$refaddr = do{$args[1]};"
                  . "my \$m$refaddr = do{$args[2]} // ('$obj->{act}('."
                  . qq~join(', ',map{UNIVERSAL::can(\$_,'dump') ? \$_->dump : \$_}(\$a$refaddr, \$b$refaddr)) . ')');~
                  . ($obj->{act} eq 'assert_ne' ? qq{!(\$a$refaddr eq \$b$refaddr)} : qq{\$a$refaddr eq \$b$refaddr})
                  . qq~ or CORE::die "\$m$refaddr~
                  . qq~ failed at \Q$obj->{file}\E line $obj->{line}\\n"}~;
            }
        }
        elsif ($ref eq 'Sidef::Meta::Error') {
            my @args = $self->deparse_args($obj->{arg});
            $code = qq~do{CORE::die(@args, " at \Q$obj->{file}\E line $obj->{line}\\n")}~;
        }
        elsif ($ref eq 'Sidef::Meta::Warning') {
            my @args = $self->deparse_args($obj->{arg});
            $code = qq~((CORE::warn(@args, " at \Q$obj->{file}\E line $obj->{line}\\n")) ? ~
              . qq~(Sidef::Types::Bool::Bool::FALSE) : (Sidef::Types::Bool::Bool::TRUE))~;
        }
        elsif ($ref eq 'Sidef::Types::Glob::Pipe') {
            $code = $self->make_constant($ref, 'new', "Pipe$refaddr", map { $self->_dump_string($_) } @{$obj});
        }
        elsif ($ref eq 'Sidef::Parser') {
            $code = '$Sidef::PARSER';
        }
        elsif ($ref eq 'Sidef::Perl::Perl') {
            $code = $self->make_constant($ref, 'new', "Perl$refaddr");
        }
        elsif ($ref eq 'Sidef::Meta::Unimplemented') {
            $code = qq{CORE::die "Unimplemented at " . } . $self->_dump_string($obj->{file}) . qq{. " line $obj->{line}\\n"};
        }
        elsif (exists $self->{data_types}{$ref}) {
            my $mod = $self->{data_types}{$ref};
            $self->{_reftype_cache}{$mod} //= do {
                $self->load_mod($mod);
                1;
            };
            $code = "'" . $mod . "'";
        }

        # Array and hash indices
        if (exists $expr->{ind}) {
            my $limit = $#{$expr->{ind}};
            foreach my $i (0 .. $limit) {

                my $ind = $expr->{ind}[$i];
                if (exists $ind->{array}) {
                    my $indices = $self->_dump_indices($ind->{array});

                    $code = '@{(' . $code . ')}';

                    if ($indices ne '') {
                        $code .= "[$indices]";
                    }
                }
                else {
                    my $keys = $self->_dump_lookups($ind->{hash});

                    if ($keys eq '') {
                        $code = '%{(' . $code . ')}';
                    }
                    else {
                        $code = "\@{$code}{$keys}";
                    }
                }

                if ($i < $limit) {
                    if ($expr->{ind}[$i + 1]{array}) {
                        $self->load_mod('Sidef::Types::Array::Array');
                        $code = "($code//=bless([], 'Sidef::Types::Array::Array'))";
                    }
                    else {
                        $self->load_mod('Sidef::Types::Hash::Hash');
                        $code = "($code//=bless({}, 'Sidef::Types::Hash::Hash'))";
                    }
                }
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {

            my $unary;
            my $end = $#{$expr->{call}};

            foreach my $i (0 .. $end) {

                my $call   = $expr->{call}[$i];
                my $method = $call->{method};

                if ($code ne '') {
                    $code = '(' . $code . ')';
                }

                # Optimization for hashes
                if (
                        $ref eq 'Sidef::DataTypes::Hash::Hash'
                    and $i == 0
                    and (   $method eq 'call'
                         or $method eq 'new'
                         or $method eq ':')
                  ) {
                    $code = 'bless({' . $self->deparse_args(@{$call->{arg}}) . "}, '$self->{data_types}{$ref}')";
                    next;
                }

                # Handle the return statement
                if ($ref eq 'Sidef::Types::Block::Return') {

                    if (exists $self->{function}) {
                        $code .= 'do{';
                        if (@{$call->{arg}}) {
                            $code .= '@return=' . $self->deparse_args(@{$call->{arg}}) . ';';
                        }
                        $code .= 'goto ' . "END$self->{function}}";
                    }
                    else {
                        $code .= 'return' . $self->deparse_args(@{$call->{arg}});
                    }

                    next;
                }

                if (defined $method) {

                    if ($ref eq 'Sidef::Variable::Ref') {    # variable refs

                        # Variable refencing
                        if ($method eq '\\' or $method eq '&') {
                            $code = '\\' . $self->deparse_args(@{$call->{arg}});
                            next;
                        }

                        # Variable dereferencing
                        elsif ($method eq '*') {
                            $code = '${' . $self->deparse_args(@{$call->{arg}}) . '}';
                            next;
                        }

                        # Prefix ++ and -- operators on variables
                        elsif (exists $self->{inc_dec_ops}{$method}) {
                            my $var = $self->deparse_args(@{$call->{arg}});
                            $code = "do{my\$r=\\$var;\$\$r=\$\$r\->$self->{inc_dec_ops}{$method}}";
                            next;
                        }
                    }

                    # Postfix ++ and -- operators on variables
                    if (exists($self->{inc_dec_ops}{$method})) {
                        $code = "do{my\$r=\\$code;my\$v=\$\$r;\$\$r=\$v\->$self->{inc_dec_ops}{$method};\$v}";
                        next;
                    }

                    if (exists($self->{lazy_ops}{$method})) {
                        $code .= $self->{lazy_ops}{$method} . 'do' . $self->deparse_bare_block(@{$call->{arg}});
                        next;
                    }

                    # Variable assignment (=)
                    if (exists($self->{assignment_ops}{$method})) {
                        $code = "($code$self->{assignment_ops}{$method}" . $self->deparse_args(@{$call->{arg}}) . ")[-1]";
                        next;
                    }

                    # Reassignment operators, such as: +=, -=, *=, /=, etc...
                    if (exists $self->{reassign_ops}{$method}) {
                        $code =
                            "CORE::sub:lvalue{my\$r=\\$code;\$\$r=\$\$r"
                          . $self->_dump_op_call($self->{reassign_ops}{$method})
                          . $self->deparse_args(@{$call->{arg}}) . '}->()';
                        next;
                    }

                    # != and == methods
                    if ($method eq '==' or $method eq '!=') {
                        $code =
                            'do{my$bool='
                          . $code . 'eq'
                          . $self->deparse_args(@{$call->{arg}})
                          . ';ref($bool)?$bool:($bool?Sidef::Types::Bool::Bool::TRUE:Sidef::Types::Bool::Bool::FALSE)}'
                          . ($method eq '!=' ? '->not' : '');
                        next;
                    }

                    # !~ and ~~ methods
                    if ($method eq '~~' or $method eq '!~') {
                        $self->top_add(q{no warnings 'experimental::smartmatch';});
                        $code =
                            'do{my$bool=do{'
                          . $code
                          . '}~~do{'
                          . $self->deparse_args(@{$call->{arg}})
                          . '};ref($bool)?$bool:($bool?Sidef::Types::Bool::Bool::TRUE:Sidef::Types::Bool::Bool::FALSE)}'
                          . ($method eq '!~' ? '->not' : '');
                        next;
                    }

                    # <=> method
                    if ($method eq '<=>') {
                        $code =
                            'do{my$cmp='
                          . $code . 'cmp'
                          . $self->deparse_args(@{$call->{arg}})
                          . ';ref($cmp)?$cmp:($cmp<0?Sidef::Types::Number::Number::MONE:'
                          . '$cmp>0?Sidef::Types::Number::Number::ONE:Sidef::Types::Number::Number::ZERO)}';
                        next;
                    }

                    # Unary prefix operator
                    if ($ref eq 'Sidef::Operator::Unary' and !$unary) {

                        $unary = 1;    # once per call

                        if ($method eq '!') {
                            $code = '('
                              . $self->deparse_args(@{$call->{arg}})
                              . '?Sidef::Types::Bool::Bool::FALSE:Sidef::Types::Bool::Bool::TRUE)';
                            next;
                        }

                        if ($method eq '-') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->neg';
                            next;
                        }

                        if ($method eq '+') {
                            $code = $self->deparse_args(@{$call->{arg}});
                            next;
                        }

                        if ($method eq '@') {
                            $self->load_mod('Sidef::Types::Array::Array');
                            $code =
                                '(do{my$obj='
                              . $self->deparse_args(@{$call->{arg}})
                              . ';my$sub=UNIVERSAL::can($obj, "to_a"); '
                              . 'defined($sub) ? $sub->($obj) : bless([$obj], "Sidef::Types::Array::Array")})';
                            next;
                        }

                        if ($method eq '@|') {
                            $code =
                                '(do{my$obj='
                              . $self->deparse_args(@{$call->{arg}})
                              . ';my$sub=UNIVERSAL::can($obj, "..."); '
                              . 'defined($sub) ? $sub->($obj) : $obj })';
                            next;
                        }

                        if ($method eq '~') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->not';
                            next;
                        }

                        if ($method eq '√') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->sqrt';
                            next;
                        }

                        if ($method eq '^') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->range';
                            next;
                        }

                        if ($method eq 'say' or $method eq '>') {
                            $code =
                                '((CORE::say'
                              . $self->deparse_args(@{$call->{arg}})
                              . ')?Sidef::Types::Bool::Bool::TRUE:Sidef::Types::Bool::Bool::FALSE)';
                            next;
                        }

                        if ($method eq 'print' or $method eq '>>') {
                            $code =
                                '((CORE::print'
                              . $self->deparse_args(@{$call->{arg}})
                              . ')?Sidef::Types::Bool::Bool::TRUE:Sidef::Types::Bool::Bool::FALSE)';
                            next;
                        }

                        if ($method eq 'defined') {
                            $code =
                                '((CORE::defined'
                              . $self->deparse_args(@{$call->{arg}})
                              . ')?Sidef::Types::Bool::Bool::TRUE:Sidef::Types::Bool::Bool::FALSE)';
                            next;
                        }
                    }

                    if (ref($method)) {
                        $code .=
                          '->${\\do{' . $self->deparse_expr(ref($method) eq 'HASH' ? $method : {self => $method}) . '}}';
                    }
                    elsif ($method =~ /^[^\W\d]/) {

                        # Exclamation mark (!) at the end of a method
                        if (substr($method, -1) eq '!') {
                            $code =
                                "CORE::sub:lvalue{my\$r=\\$code;\$\$r=\$\$r\->"
                              . substr($method, 0, -1)
                              . (exists($call->{arg}) ? $self->deparse_args(@{$call->{arg}}) : '') . '}->()';
                            next;
                        }

                        # Special case for methods without '->'
                        else {
                            $code .= '->' if $code ne '';
                            $code .= $method;
                        }
                    }
                    else {
                        ## Old way:
                        #$code .= '->${\\' . q{'} . $method . q{'} . '}';

                        ## New way:
                        $code .= $self->_dump_op_call($method);
                    }
                }

                if (exists $call->{keyword}) {
                    $code .= $call->{keyword};
                }

                if (exists $call->{arg}) {
                    $code .= $self->deparse_args(@{$call->{arg}});
                }
            }
        }

        $code;
    }

    sub deparse_script {
        my ($self, $struct) = @_;

        my @results;

        foreach my $class (grep exists $struct->{$_}, @{$self->{namespaces}}, 'main') {

            my $max = $#{$struct->{$class}};
            foreach my $i (0 .. $max) {
                my $expr = $struct->{$class}[$i];

                push @results, ref($expr) eq 'HASH' ? $self->deparse_expr($expr) : $self->deparse_expr({self => $expr});

                if (
                    $i > 0
                    and (
                         ref($expr) eq 'Sidef::Variable::Label'
                         or (    ref($struct->{$class}[$i - 1]) eq 'HASH'
                             and ref($struct->{$class}[$i - 1]{self}) eq 'Sidef::Variable::Label')
                        )
                  ) {
                    $results[-1] =
                      (ref($expr) eq 'Sidef::Variable::Label' ? $expr->{name} : $struct->{$class}[$i - 1]{self}->{name}) . ':'
                      . $results[-1];
                }
                elsif (
                       $i == $max
                       and (ref($expr) eq 'Sidef::Variable::Label'
                            or (ref($expr) eq 'HASH' and ref($expr->{self}) eq 'Sidef::Variable::Label'))
                  ) {
                    $results[-1] = (ref($expr) eq 'Sidef::Variable::Label' ? $expr->{name} : $expr->{self}{name}) . ':';
                }
            }
        }

        wantarray ? @results : $results[-1];
    }

    sub deparse {
        my ($self, $struct) = @_;
        my @statements = $self->deparse_script($struct);

        (
             $self->{before}
           . ($self->{_has_constant} ? '};' : '')
           . (
              exists($self->{function_declarations})
                && @{$self->{function_declarations}} ? join('', map { $_->[1] } @{$self->{function_declarations}})
              : ''
             )
           . (
              exists($self->{block_declarations})
                && @{$self->{block_declarations}} ? join('', map { $_->[1] } @{$self->{block_declarations}})
              : ''
             )
           . $self->{top_program}
           . join($self->{between}, @statements)
           . $self->{after}
        ) =~ s/^\s*/$self->{header}/r;
    }
}

1;
