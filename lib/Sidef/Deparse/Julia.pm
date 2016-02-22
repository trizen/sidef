package Sidef::Deparse::Julia {

    use utf8;
    use 5.014;

    use List::Util qw(all);
    use Scalar::Util qw(refaddr);

    # This module is highly experimental!
    # ~~~ User discretion is advised ~~~

    my %addr;
    my %type;
    my %const;
    my %top_add;

    sub new {
        my (undef, %args) = @_;

        my %opts = (
            before      => '',
            header      => '',
            top_program => "\n",
            between     => ";\n",
            after       => ";\n",
            namespaces  => [],
            opt         => {},

            environment_name => 'main',

            assignment_ops => {
                               '=' => '=',
                              },

            lazy_ops => {
                '?'  => '?',
                '||' => '||',
                '&&' => '&&',
                ':=' => '//=',

                # '='     => '=',
                '||='   => '||=',
                '&&='   => '&&=',
                '\\\\'  => '//',
                '\\\\=' => '//=',
                        },

            #~ overload_methods => {
            #~ to_str  => q{""},
            #~ to_s    => q{""},
            #~ to_bool => q{bool},
            #~ to_num  => q{0+},
            #~ },

            data_types => {
                qw(
                  Sidef::DataTypes::Array::Array          Sidef_Types_Array_Array
                  Sidef::DataTypes::Array::Pair           Sidef_Types_Array_Pair
                  Sidef::DataTypes::Array::MultiArray     Sidef_Types_Array_MultiArray
                  Sidef::DataTypes::Hash::Hash            Sidef_Types_Hash_Hash
                  Sidef::DataTypes::Regex::Regex          Sidef_Types_Regex_Regex
                  Sidef::DataTypes::String::String        Sidef_Types_String_String
                  Sidef::DataTypes::Number::Number        Sidef_Types_Number_Number
                  Sidef::DataTypes::Number::Complex       Sidef_Types_Number_Complex
                  Sidef::DataTypes::Range::RangeNumber    Sidef_Types_Range_RangeNumber
                  Sidef::DataTypes::Range::RangeString    Sidef_Types_Range_RangeString
                  Sidef::DataTypes::Block::Block          Sidef_Types_Block_Block
                  Sidef::DataTypes::Glob::Socket          Sidef_Types_Glob_Socket
                  Sidef::DataTypes::Glob::Pipe            Sidef_Types_Glob_Pipe
                  Sidef::DataTypes::Glob::Backtick        Sidef_Types_Glob_Backtick
                  Sidef::DataTypes::Glob::DirHandle       Sidef_Types_Glob_DirHandle
                  Sidef::DataTypes::Glob::FileHandle      Sidef_Types_Glob_FileHandle
                  Sidef::DataTypes::Glob::Dir             Sidef_Types_Glob_Dir
                  Sidef::DataTypes::Glob::File            Sidef_Types_Glob_File
                  Sidef::DataTypes::Object::Object        Sidef_Object_Object
                  Sidef::DataTypes::Sidef::Sidef          Sidef
                  Sidef::DataTypes::Variable::LazyMethod  Sidef_Variable_LazyMethod
                  )
            },

            reassign_ops => {map (("$_=" => $_), qw(+ - % * // / & | ^ ** && || << >> ÷))},

            inc_dec_ops => {
                            '++' => 'inc',
                            '--' => 'dec',
                           },
            %args,
                   );

        require File::Spec;
        require File::Basename;

        my $path = File::Spec->catdir(File::Basename::dirname($INC{"Sidef/Deparse/Julia.pm"}), "Julia");
        $opts{header} .= <<"HEADER";
module SidefRuntime

include("$path/Sidef.jl")

HEADER

        if (exists $opts{opt}{P}) {
            my $precision = abs(int($opts{opt}{P}));
            $opts{header} .= "local \$Sidef::Types::Number::Number::PREC = 4*$precision;\n";
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

            $opts{header} .= "local \$Sidef::Types::Number::Number::ROUND = $round;\n";
        }

        %addr    = ();
        %type    = ();
        %top_add = ();
        %const   = ();

        bless \%opts, __PACKAGE__;
    }

    sub _normalize_type {
        $_[0] =~ s/::/_/gr;
    }

    sub make_constant {
        my ($self, $ref, $new_method, $name, @args) = @_;

        '(' . (
            (
             $const{$ref, $#args, @args} //= [
                 $name . @args,
                 do {
                     local $" = ", ";
                     $self->{before} .=
                       "const $name" . @args . " = " . _normalize_type($ref) . (@args ? "(@args);" : '') . "\n";
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

    sub _get_reftype {
        my ($self, $obj) = @_;

        my $ref = ref($obj);
        if (exists $self->{data_types}{$ref}) {
            return $self->{data_types}{$ref};
        }

            $ref eq 'Sidef::Variable::ClassInit'     ? $self->_dump_class_name($obj)
          : $ref eq 'Sidef::Variable::Ref'           ? 'REF'
          : $ref eq 'Sidef::Types::Block::BlockInit' ? 'Sidef::Types::Block::Block'
          :                                            $ref;
    }

    sub _dump_reftype {
        my ($self, $obj) = @_;
        $self->_dump_string($self->_get_reftype($obj));
    }

    sub _dump_string {
        my ($self, $str) = @_;

        state $x = eval { require Data::Dump };
        $x || return ('"' . quotemeta($str) . '"');

        my $d = Data::Dump::quote($str);

        # Make sure that code-points between 128 and 256
        # will be stored internally as UTF-8 strings.
        if ($str =~ /[\200-\400]/) {
            return "do {require Encode; Encode::decode_utf8(Encode::encode_utf8($d))}";
        }

        $d;
    }

    sub _dump_var {
        my ($self, $var, $refaddr) = @_;

        $var->{name} // return 'undef';

        # $var->{in_use} || exists($var->{value}) || exists($var->{ref_type}) || return 'undef';

        #(
        #   exists($var->{array}) ? '@'
        # : exists($var->{hash})  ? '%'
        # :                         '$'
        #)
        #  .
        $var->{name} . ($refaddr // refaddr($var));
    }

    sub _dump_vars {
        my ($self, @vars) = @_;
        '(' . join(', ', map { $self->_dump_var($_) } @vars) . ')';
    }

    sub _dump_init_vars {
        my ($self, $init_obj) = @_;

        my @vars = @{$init_obj->{vars}};
        @vars || return '';

        my @dumped_values = map { exists($_->{value}) ? $self->deparse_expr({self => $_->{value}}) : ('undef') } @vars;

        # Ignore "undef" values
        if (all { $_ eq 'undef' } @dumped_values) {
            @dumped_values = ();
        }

        my @code;
        push @code,
            '('
          . join(', ', map { $self->_dump_var($_) } @vars) . ')'
          . (exists($init_obj->{args}) ? '=' . $self->deparse_args($init_obj->{args}) : '');

        foreach my $var (@vars) {

            ref($var) || next;
            if (exists $var->{array}) {
                my $name = $var->{name} . refaddr($var);
                push @{$self->{block_declarations}}, [$self->{current_block} // -1, 'my @' . $name . ';'];

                # Overwrite with the default values, when the array is empty
                if (exists $var->{value}) {
                    push @code,
                      (   (' ' x $Sidef::SPACES) . '@'
                        . $name . '=('
                        . $self->deparse_expr({self => $var->{value}})
                        . ") if not \@$name;\n");
                }

                push @code, (' ' x $Sidef::SPACES) . "\$$name = Sidef::Types::Array::Array->new(\@$name);\n";

                #$var->{in_use} ||= 1;
                delete $var->{array};
            }
            elsif (exists $var->{hash}) {
                my $name = $var->{name} . refaddr($var);
                push @{$self->{block_declarations}}, [$self->{current_block} // -1, 'my %' . $name . ';'];

                # Overwrite with the default values, when the hash has no keys
                if (exists $var->{value}) {
                    push @code,
                      (   (' ' x $Sidef::SPACES) . '%'
                        . $name . '=('
                        . $self->deparse_expr({self => $var->{value}})
                        . ") if not keys \%$name;\n");
                }

                push @code, (' ' x $Sidef::SPACES) . "\$$name = Sidef::Types::Hash::Hash->new(\%$name);\n";

                #$var->{in_use} ||= 1;
                delete $var->{hash};
            }
            elsif (exists $var->{value}) {
                my $value = $self->deparse_expr({self => $var->{value}});
                if ($value ne '') {
                    push @code, (' ' x $Sidef::SPACES) . "\$$var->{name}" . refaddr($var) . " //= " . $value . ";\n";
                }
            }
        }

        push @{$self->{block_declarations}},
          [ $self->{current_block} // -1,
            '(' . join(', ', map { $self->_dump_var($_) } @vars) . ') = (' . join(',', ('Any') x @vars) . ')'
          ];

        # Return the lvalue variables on assignments
        if (@code > 1 or exists($init_obj->{args})) {

            #push @code, '(' . join(', ', map { $self->_dump_var($_) } @vars) . ')';
            return join(';', @code);

            #return 'CORE::sub : lvalue {' . join(';', @code) . '}->()';
        }

        # Return one var as a list
        '(' . join(', ', @code) . ')';
    }

    sub _dump_class_attributes {
        my ($self, @attrs) = @_;

        my @code;
        foreach my $attr (@attrs) {

            my @vars = @{$attr->{vars}};
            @vars || next;

            my @dumped_vars = map { ref($_) ? $self->_dump_var($_) : $_ } @vars;

            push @code,
              (   'my('
                . join(', ', @dumped_vars) . ')'
                . (exists($attr->{args}) ? '=' . $self->deparse_args($attr->{args}) : ''));
            foreach my $var (@vars) {
                if (exists $var->{value}) {
                    my $value = $self->deparse_expr({self => $var->{value}});
                    if ($value ne '') {
                        push @code, "\$$var->{name}" . refaddr($var) . " //= " . $value . ";";
                    }
                }
            }

        }

        @code ? ((' ' x $Sidef::SPACES) . join(";\n" . (' ' x $Sidef::SPACES), @code) . ";\n") : '';
    }

    sub _dump_func_params {
        my ($self, @vars) = @_;

        @vars || return '';

        my @dumped_vars = map { ref($_) ? $self->_dump_var($_, '') : $_ } @vars;
        join(', ', @dumped_vars);
    }

    sub _dump_sub_init_vars {
        my ($self, $refaddr, @vars) = @_;

        @vars || return '';

        my @dumped_vars = map { ref($_) ? $self->_dump_var($_) : $_ } @vars;

        # Return when all variables are "undef"
        if (all { $_ eq 'undef' } @dumped_vars) {
            return '';
        }

        my $code = '';

        $code .= "_anys$refaddr = Any[]\n";
        $code .= "for i in 1:(" . @dumped_vars . " - length(_$refaddr)) push!(_anys$refaddr, NIL); end\n";
        $code .= "_$refaddr = (_$refaddr..., _anys$refaddr...)\n";
        $code .= (' ' x $Sidef::SPACES) . join(', ', @dumped_vars) . ", = _$refaddr\n";

        #my $code = join(', ', @dumped_vars);
        #my $code = '';

        foreach my $var (@vars) {

            #$code .= (' ' x $Sidef::SPACES) . $self->_dump_var($var) . ' = ' . $self->_dump_var($var, '') . "\n";

            ref($var) || next;
            if (exists $var->{array}) {
                my $name = $var->{name} . refaddr($var);

                # Overwrite with the default values, when the array is empty
                if (exists $var->{value}) {
                    $code .= ('@' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not \@$name;\n");
                }

                $code .= (' ' x $Sidef::SPACES) . "my \$$name = Sidef::Types::Array::Array->new(\@$name);\n";
                delete $var->{array};
            }
            elsif (exists $var->{hash}) {
                my $name = $var->{name} . refaddr($var);

                # Overwrite with the default values, when the hash has no keys
                if (exists $var->{value}) {
                    $code .= ('%' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not keys \%$name;\n");
                }

                $code .= (' ' x $Sidef::SPACES) . "my \$$name = Sidef::Types::Hash::Hash->new(\%$name);\n";
                delete $var->{hash};
            }
            else {

                if (exists $var->{value}) {
                    my $value = $self->deparse_expr({self => $var->{value}});
                    if ($value ne '') {
                        my $name = $var->{name} . refaddr($var);
                        $code .= (' ' x $Sidef::SPACES) . "($name == NIL) && ($name = $value);\n";

                        #$code .= (' ' x $Sidef::SPACES) . "\$$var->{name}" . refaddr($var) . " //= " . $value . ";\n";
                    }
                }
            }
        }

        $code;
    }

    sub _dump_array {
        my ($self, $ref, $array) = @_;
        _normalize_type($ref) . '(Any['
          . join(', ', map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}) } @{$array}) . '])';
    }

    sub _dump_indices {
        my ($self, $array) = @_;
        '[' . join(
            ', ',
            map {
                    ref($_) eq 'Sidef::Types::Number::Number' ? $_->_get_double
                  : ref($_) ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}))
                  : $_
              } @{$array}
          )
          . ']';
    }

    sub _dump_unpacked_indices {
        my ($self, $array) = @_;
        '[' . join(
            ', ',
            map {
                '@{'
                  . (
                     ref($_)
                     ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}))
                     : die "[ERROR] Value '$_' can't be unpacked in Array index!"
                    )
                  . '}'
              } @{$array}
          )
          . ']';
    }

    sub _dump_lookups {
        my ($self, $array) = @_;
        '[' . join(
            ', ',
            map {
                (ref($_) eq 'Sidef::Types::String::String' or ref($_) eq 'Sidef::Types::Number::Number')
                  ? $self->_dump_string($_->get_value)
                  : ref($_) ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}))
                  : $_
              } @{$array}
          )
          . ']';
    }

    sub _dump_unpacked_lookups {
        my ($self, $array) = @_;
        '{' . join(
            ', ',
            map {
                '@{'
                  . (
                     ref($_)
                     ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}))
                     : die "[ERROR] Value '$_' can't be unpacked in Hash lookup!"
                    )
                  . '}'
              } @{$array}
          )
          . '}';
    }

    sub _dump_var_attr {
        my ($self, @vars) = @_;

        'vars => [' . join(
            ', ',
            map {
                    "{ name => "
                  . $self->_dump_string($_->{name})
                  . (exists($_->{slurpy})    ? (", slurpy => " . $_->{slurpy})                       : '')
                  . (exists($_->{ref_type})  ? (", type => " . $self->_dump_reftype($_->{ref_type})) : '')
                  . (exists($_->{has_value}) ? (', has_value => 1')                                  : '')
                  . (
                     exists($_->{where_block})
                     ? (', where_block => sub{'
                        . $self->_dump_sub_init_vars($_->{where_block}{init_vars}{vars}[0])
                        . $self->deparse_generic('', ';', '', $_->{where_block}{code}) . '}')
                     : ''
                    )
                  . (
                     exists($_->{where_expr}) ? (', where_expr => do{' . $self->deparse_expr({self => $_->{where_expr}}) . '}')
                     : ''
                    )
                  . '}'
              } @vars
          )
          . ']' . ', '
          . 'table => {'
          . join(', ', map { $self->_dump_string($vars[$_]{name}) . ' => ' . $_ } 0 .. $#vars) . '}';
    }

    sub _dump_class_name {
        my ($self, $class) = @_;
        join('::', '_', $class->{class}, $class->{name});
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
        $self->deparse_generic('(', ', ', ')', @args);
    }

    sub deparse_block_expr {
        my ($self, @args) = @_;

        $Sidef::SPACES += $Sidef::SPACES_INCR;
        my $code = $self->deparse_generic("begin\n" . (" " x $Sidef::SPACES),
                                          ";\n" . (" " x $Sidef::SPACES),
                                          , "\n" . (" " x ($Sidef::SPACES - $Sidef::SPACES_INCR)) . 'end', @args);
        $Sidef::SPACES -= $Sidef::SPACES_INCR;

        $code;
    }

    sub deparse_statements {
        my ($self, @args) = @_;

        $Sidef::SPACES += $Sidef::SPACES_INCR;
        my $code = $self->deparse_generic("\n" . (" " x $Sidef::SPACES),
                                          ";\n" . (" " x $Sidef::SPACES),
                                          "\n" . (" " x ($Sidef::SPACES - $Sidef::SPACES_INCR)), @args);
        $Sidef::SPACES -= $Sidef::SPACES_INCR;

        $code;
    }

    sub deparse_bare_block {
        my ($self, @args) = @_;

        $Sidef::SPACES += $Sidef::SPACES_INCR;
        my $code = $self->deparse_generic("\n" . (" " x $Sidef::SPACES),
                                          ";\n" . (" " x $Sidef::SPACES),
                                          "\n" . (" " x ($Sidef::SPACES - $Sidef::SPACES_INCR)) . 'end', @args);
        $Sidef::SPACES -= $Sidef::SPACES_INCR;

        $code;
    }

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $code    = '';
        my $obj     = $expr->{self};
        my $refaddr = refaddr($obj);

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $code = join(', ', exists($obj->{self}) ? $self->deparse_expr($obj) : $self->deparse_script($obj));
        }
        elsif ($ref eq 'Sidef::Variable::Variable') {
            if ($obj->{type} eq 'var') {

                my $name = $obj->{name} . $refaddr;

                if ($obj->{name} eq 'ENV') {
                    $self->top_add("require Encode;\n");
                    $self->top_add(  qq{my \$$name = Sidef::Types::Hash::Hash->new}
                                   . qq{(map{Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \%ENV);\n});
                }
                elsif ($obj->{name} eq 'ARGV') {
                    $self->top_add("require Encode;\n");
                    $self->top_add(  qq{my \$$name = Sidef::Types::Array::Array->new}
                                   . qq{(map {Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \@ARGV);\n});
                }

                $code = $self->_dump_var($obj, $refaddr);
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {

                if ($addr{$refaddr}++) {
                    $code = "$obj->{name}$refaddr";
                }
                else {
                    my $block = $obj->{value};

                    # Anonymous function
                    if ($obj->{name} eq '') {
                        $obj->{name} = "__ANON__";
                    }

                    my $name = $obj->{name};

                    # Check for alphanumeric name
                    if (not $obj->{name} =~ /^[_\pL][_\pL\pN]*\z/) {
                        $obj->{name} = '__NONANN__';    # use this name for non-alphanumeric names
                    }

                    # The name of the function
                    $code .= "$obj->{name}$refaddr = ";

                    # Deparse the block of the method/function
                    {
                        local $self->{function} = refaddr($block);
                        local $self->{parent_name} = [$obj->{type}, "$obj->{class}::$name"];
                        push @{$self->{function_declarations}}, [$self->{function}, "$obj->{name}$refaddr = Function"];
                        $code .= $self->deparse_expr({self => $block});
                    }

                    # Check to see if the method/function has kids (can do multiple dispatch)
                    if (exists $obj->{value}{kids}) {
                        chop $code;

                        my @kids = map {
                            local $_->{type} = 'func';
                            "do{" . $self->deparse_expr({self => $_}) . "}";
                        } @{$obj->{value}{kids}};

                        $code .= ', kids => [' . join(', ', @kids) . '])';
                    }

                    # Check the return value (when "-> Type" is specified)
                    if (exists $obj->{returns}) {
                        my $types = '[' . join(', ', map { $self->_dump_reftype($_) } @{$obj->{returns}}) . ']';
                        $code = "do {$code; \$$obj->{name}$refaddr\->{returns} = $types; \$$obj->{name}$refaddr}";
                    }

                    # Memoize the method/function (when "is cached" trait is specified)
                    if ($obj->{cached}) {
                        $self->top_add("require Memoize;\n");
                        $code =
                            "do {$code;\n"
                          . (' ' x $Sidef::SPACES)
                          . "\$$obj->{name}$refaddr\->{code} = Memoize::memoize(\$$obj->{name}${refaddr}->{code}); \$$obj->{name}$refaddr}";
                    }

                    if ($obj->{type} eq 'method') {

                        # Special "AUTOLOAD" method
                        if ($obj->{name} eq 'AUTOLOAD') {
                            $code .= ";\n"
                              . (' ' x $Sidef::SPACES)
                              . "our \$AUTOLOAD;\n"
                              . (' ' x $Sidef::SPACES)
                              . "sub $obj->{name} { my \$self = shift;\n"
                              . (' ' x $Sidef::SPACES)
                              . "my (\$class, \$method) = (\$AUTOLOAD =~ /^(.*[^:])::(.*)\$/);\n"
                              . (' ' x $Sidef::SPACES)
                              . "\$$obj->{name}$refaddr->call(\$self, Sidef::Types::String::String->new(\$class), Sidef::Types::String::String->new(\$method), \@_) }";
                        }

                        # Anonymous method
                        elsif ($obj->{name} eq '__ANON__') {
                            ## don't add anonymous methods to the class,
                            ## but allow them to be defined and used freely
                        }

                        # Other methods
                        else {
                            $code .= ";\n"
                              . (' ' x $Sidef::SPACES)
                              . "state \$_$refaddr = do { no strict 'refs'; *{"
                              . $self->_dump_string("$self->{package_name}::$name")
                              . "} = sub { \$$obj->{name}$refaddr->call(\@_) } }";
                        }

                        # Add the "overload" pragma for some special methods
                        #~ if (exists $self->{overload_methods}{$obj->{name}}) {
                        #~ $code .= ";\n"
                        #~ . (' ' x $Sidef::SPACES)
                        #~ . qq{use overload q{$self->{overload_methods}{$obj->{name}}} => }
                        #~ . $self->_dump_string("$self->{package_name}::$obj->{name}");
                        #~ }
                    }
                }
            }
        }
        elsif ($ref eq 'Sidef::Object::Unary') {
            ## OK
        }
        elsif ($ref eq 'Sidef::Variable::Local') {
            $code = 'local ' . $self->deparse_script($obj->{expr});
        }
        elsif ($ref eq 'Sidef::Variable::Global') {
            $code = '$' . $obj->{class} . '::' . $obj->{name};
        }
        elsif ($ref eq 'Sidef::Variable::ClassVar') {
            $code = '$' . $self->_get_reftype($obj->{class}) . '::' . $obj->{name};
        }
        elsif ($ref eq 'Sidef::Variable::Define') {
            my $name  = $obj->{name} . $refaddr;
            my $value = '(' . $self->{environment_name} . '::' . $name . ')';
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $self->top_add('use constant ' . $name . ' => ' . 'do {' . $self->deparse_script($obj->{expr}) . " };\n");
            }
            $code = $value;
        }
        elsif ($ref eq 'Sidef::Variable::Const') {
            my $name  = $obj->{name} . $refaddr;
            my $value = '(' . $name . ')';
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;

                # Use dynamical constants inside functions
                if (exists $self->{function} or exists $self->{class}) {
                    $self->top_add("use experimental 'lexical_subs';\n");
                    $code = "state sub $name() { state \$_$refaddr"
                      . (defined($obj->{expr}) ? (" = do{" . $self->deparse_script($obj->{expr}) . '}') : '') . " }";
                }

                # Otherwise, use static constants
                else {
                    $code = "sub $name() { state \$_$refaddr"
                      . (defined($obj->{expr}) ? " = do{" . ($self->deparse_script($obj->{expr}) . '}') : '') . "}";
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
                $code = "(state \$$name"
                  . (defined($obj->{expr}) ? (' = do{' . $self->deparse_script($obj->{expr}) . '}') : '') . ")";
            }
            else {
                $code = $value;
            }
        }
        elsif ($ref eq 'Sidef::Variable::ConstInit') {
            $code = join(";\n" . (" " x $Sidef::SPACES), map { $self->deparse_expr({self => $_}) } @{$obj->{vars}});
        }
        elsif ($ref eq 'Sidef::Variable::Init') {
            $code = $self->_dump_init_vars($obj);
        }
        elsif ($ref eq 'Sidef::Variable::ClassInit') {
            if ($addr{$refaddr}++) {
                $code = q{'} . $self->_dump_class_name($obj) . q{'};
            }
            else {
                my $block = $obj->{block};

                $code = "do {package ";

                my $package_name;
                if (ref $obj->{name}) {

                    if (ref $obj->{name} eq 'HASH') {
                        die "[ERROR] Invalid class name: '$obj->{name}' inside namespace '$obj->{class}'";
                    }

                    $code .= ($package_name = ref($obj->{name}));
                }
                else {

                    if ($obj->{name} eq '') {
                        $obj->{name} = '__ANON__' . $refaddr;
                    }

                    $code .= ($package_name = $self->_dump_class_name($obj));
                }

                local $self->{class}            = refaddr($block);
                local $self->{class_name}       = $package_name;
                local $self->{parent_name}      = ['class', $package_name];
                local $self->{package_name}     = $package_name;
                local $self->{inherit}          = $obj->{inherit} if exists $obj->{inherit};
                local $self->{class_vars}       = $obj->{vars} if exists $obj->{vars};
                local $self->{class_struct}     = $obj->{struct} if exists $obj->{struct};
                local $self->{class_attributes} = $obj->{attributes} if exists $obj->{attributes};
                local $self->{ref_class}        = 1 if ref($obj->{name});
                $code .= $self->deparse_expr({self => $block});
                $code .= '; ' . $self->_dump_string($package_name) . '}';
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::BlockInit') {
            if ($addr{$refaddr}++) {
                $code = q{Sidef::Types::Block::Block->new(code => __SUB__, type => 'block'};

                if (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}}) {
                    $code .= ', ' . $self->_dump_var_attr(@{$obj->{init_vars}{vars}});
                }

                $code .= ')';
            }
            else {
                if (%{$obj}) {

                    $Sidef::SPACES += $Sidef::SPACES_INCR;

                    my $is_function = exists($self->{function}) && $self->{function} == $refaddr;
                    my $is_class    = exists($self->{class})    && $self->{class} == $refaddr;

                    local $self->{current_block} = $refaddr;

                    if ($is_class) {
                        $code = " {\n";

                        if ($is_class) {
                            local $" = " ";
                            $code .= " " x $Sidef::SPACES;
                            $code .= "use base qw("
                              . (
                                 exists($self->{inherit})
                                 ? (join(' ', map { ref($_) ? $self->_dump_class_name($_) : $_ } @{$self->{inherit}}) . ' ')
                                 : ''
                                )
                              . ($self->{package_name} eq 'Sidef::Object::Object' ? '' : "Sidef::Object::Object") . ");\n";
                        }

                        if ($is_class and not $self->{ref_class}) {

                            $code .=
                              (" " x $Sidef::SPACES) . "\$new$refaddr = Sidef::Types::Block::Block->new(code => sub {" . "\n";
                            push @{$self->{function_declarations}}, [$refaddr, "my \$new$refaddr;"];

                            $Sidef::SPACES += $Sidef::SPACES_INCR;
                            $code .= $self->_dump_sub_init_vars(@{$self->{class_vars}},
                                                                (map { @{$_->{vars}} } @{$self->{class_struct}}))
                              . $self->_dump_class_attributes(@{$self->{class_attributes}});

                            $code .= (' ' x $Sidef::SPACES) . 'my $self = bless {';
                            foreach my $var (@{$self->{class_vars}},
                                             (map { @{$_->{vars}} } @{$self->{class_attributes}}),
                                             (map { @{$_->{vars}} } @{$self->{class_struct}})) {
                                $code .= qq{"\Q$var->{name}\E"=>} . $self->_dump_var($var) . ', ';
                            }

                            $code .=
                                '}, __PACKAGE__;' . "\n"
                              . (' ' x $Sidef::SPACES)
                              . '$self->init() if $self->can("init");' . "\n"
                              . (' ' x $Sidef::SPACES)
                              . '$self;' . "\n";

                            $Sidef::SPACES -= $Sidef::SPACES_INCR;
                            $code .=
                                (" " x $Sidef::SPACES . "}") . ', '
                              . $self->_dump_var_attr(@{$self->{class_vars}}, map { @{$_->{vars}} } @{$self->{class_struct}})
                              . ", type => "
                              . $self->_dump_string('class')
                              . ", name => "
                              . $self->_dump_string($self->{parent_name}[1]) . ");\n"
                              . (' ' x $Sidef::SPACES)
                              . "state \$_$refaddr = do { no strict 'refs'; *{"
                              . $self->_dump_string("$self->{package_name}\::new")
                              . "} = *{"
                              . $self->_dump_string("$self->{package_name}\::call")
                              . "} = sub { CORE::shift(\@_); \$new$refaddr->call(\@_) } };\n";

                            foreach my $var (@{$self->{class_vars}},
                                             (map { @{$_->{vars}} } @{$self->{class_attributes}}),
                                             (map { @{$_->{vars}} } @{$self->{class_struct}})) {
                                $code .=
                                  (' ' x $Sidef::SPACES) . qq{sub $var->{name} : lvalue { \$_[0]->{"\Q$var->{name}\E"} }\n};
                            }
                        }
                    }
                    else {
                        #$code = 'Sidef::Types::Block::Block->new(';
                        $code = 'Sidef_Types_Block_Block(';
                    }

                    if (not $is_class) {

                        $code .= (" " x ($Sidef::SPACES - $Sidef::SPACES_INCR)) . "function(" .    #(
                                # (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}})
                                # ? $self->_dump_func_params(@{$obj->{init_vars}{vars}})
                                # : ''
                                #)
                          '_' . $refaddr . '::Any...' . ") \n";

                        #$code .= $self->_dump_func_params($obj->{init_vars}{vars}, $refaddr);

                        if (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}}) {
                            $code .= $self->_dump_sub_init_vars($refaddr, @{$obj->{init_vars}{vars}});
                        }

                        if ($is_function) {

                            #$code .= (' ' x $Sidef::SPACES) . 'my @return;' . "\n";
                        }
                    }

                    my @statements = $self->deparse_script($obj->{code});

                    # Localize function declarations
                    if ($is_function) {
                        while (    exists($self->{function_declarations})
                               and @{$self->{function_declarations}}
                               and $self->{function_declarations}[-1][0] != $refaddr) {
                            $code .= (' ' x $Sidef::SPACES) . pop(@{$self->{function_declarations}})->[1] . "\n";
                        }
                    }

                    # Localize variable declarations
                    while (    exists($self->{block_declarations})
                           and @{$self->{block_declarations}}
                           and $self->{block_declarations}[-1][0] == $refaddr) {
                        $code .= (' ' x $Sidef::SPACES) . pop(@{$self->{block_declarations}})->[1] . "\n";
                    }

                    #~ # Make the last statement to be the return value
                    #~ if ($is_function && @statements) {

                    #~ if ($statements[-1] =~ /^\@return = /) {

                    #~ # Make a minor improvement by removing the 'goto'
                    #~ $statements[-1] =~ s/;\h*goto END$refaddr\z//;
                    #~ $statements[-1] =~ s/^\@return = /return/;
                    #~ }
                    #~ else {
                    #~ $statements[-1] = 'return do { ' . $statements[-1] . ' }';
                    #~ }
                    #~ }

                    $code .= (" " x $Sidef::SPACES) . join(";\n" . (" " x $Sidef::SPACES), @statements)

                      #. ($is_function ? (";\n" . (" " x $Sidef::SPACES) . "END$refaddr: \@return;\n") : '') . "\n"
                      . (" " x ($Sidef::SPACES -= $Sidef::SPACES_INCR)) . 'end)';

                    #~ if (not $is_class) {
                    #~ if ($is_function) {
                    #~ $code .= ', '
                    #~ . join(', ',
                    #~ 'type => ' . $self->_dump_string($self->{parent_name}[0]),
                    #~ 'name => ' . $self->_dump_string($self->{parent_name}[1]));
                    #~ }
                    #~ else {
                    #~ $code .= ', '
                    #~ . join(', ',
                    #~ 'type => ' . $self->_dump_string('block'),
                    #~ 'name => ' . $self->_dump_string('__BLOCK__'),);
                    #~ }

                    #~ if (exists $self->{class_name}) {
                    #~ $code .= ', ' . 'class => ' . $self->_dump_string($self->{class_name});
                    #~ }

                    #~ if (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}}) {
                    #~ $code .= ', ' . $self->_dump_var_attr(@{$obj->{init_vars}{vars}});
                    #~ }
                    #~ $code .= ')';
                    #~ }
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
            my $name = $self->_dump_class_name($obj);
            if ($addr{$refaddr}++) {
                $code = $name;
            }
            else {
                $Sidef::SPACES += $Sidef::SPACES_INCR;
                $code =
                    "package $name {\n"
                  . (' ' x $Sidef::SPACES)
                  . "\$new$refaddr = Sidef::Types::Block::Block->new(code => sub {" . "\n"
                  . (' ' x $Sidef::SPACES)
                  . $self->_dump_sub_init_vars(@{$obj->{vars}})
                  . (' ' x ($Sidef::SPACES * 2))
                  . "bless {"
                  . join(", ", map { $self->_dump_string($_->{name}) . " => " . $self->_dump_var($_) } @{$obj->{vars}})
                  . "}, __PACKAGE__" . "\n"
                  . (' ' x $Sidef::SPACES) . "}" . ', '
                  . 'name => '
                  . $self->_dump_string($name) . ', '
                  . 'type => '
                  . $self->_dump_string('struct') . ', '
                  . $self->_dump_var_attr(@{$obj->{vars}}) . ");\n" . ";\n"
                  . (' ' x $Sidef::SPACES)
                  . "state \$_$refaddr = do { no strict 'refs'; *{"
                  . $self->_dump_string("$name\::new")
                  . "} = *{"
                  . $self->_dump_string("$name\::call")
                  . "} = sub { CORE::shift(\@_); \$new$refaddr->call(\@_) } };\n"
                  . (' ' x $Sidef::SPACES)
                  . join("\n" . (' ' x $Sidef::SPACES),
                         map { "sub $_->{name} : lvalue { \$_[0]->{$_->{name}} }" } @{$obj->{vars}})
                  . "\n"
                  . (' ' x ($Sidef::SPACES - $Sidef::SPACES_INCR)) . "}";

                push @{$self->{function_declarations}}, [$refaddr, "my \$new$refaddr;"];

                $Sidef::SPACES -= $Sidef::SPACES_INCR;
            }
        }
        elsif ($ref eq 'Sidef::Types::Number::Number') {
            $code =
              $self->make_constant($ref, 'new', "Number$refaddr", join '/', map { qq{big"$_"} } split /\//, $obj->_get_frac);
        }
        elsif ($ref eq 'Sidef::Types::Number::Inf') {
            $code = $self->make_constant($ref, 'new', "Inf$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::Number::Ninf') {
            $code = $self->make_constant($ref, 'new', "Ninf$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::Number::Nan') {
            $code = $self->make_constant($ref, 'new', "Nan$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::String::String') {
            $code = $self->make_constant($ref, 'new', "String$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Sidef::Types::Array::Array' or $ref eq 'Sidef::Types::Array::HCArray') {
            $code = $self->_dump_array('Sidef::Types::Array::Array', $obj);
        }
        elsif ($ref eq 'Sidef::Types::Bool::Bool') {

            #$code = $self->make_constant($ref, 'new', ${$obj} ? ("true$refaddr", 1) : ("false$refaddr", 0));
            $code = ${$obj} ? 'true' : 'false';
        }
        elsif ($ref eq 'Sidef::Types::Regex::Regex') {
            $code =
              $self->make_constant($ref, 'new', "Regex$refaddr",
                                   $self->_dump_string("$obj->{raw}"),
                                   $self->_dump_string($obj->{flags} . ($obj->{global} ? 'g' : '')));
        }
        elsif ($ref eq 'Sidef::Types::Block::If') {
            foreach my $i (0 .. $#{$obj->{if}}) {
                $code .= ($i == 0 ? 'if' : 'elseif');
                my $info = $obj->{if}[$i];
                $code .= "(" . $self->deparse_args($info->{expr}) . ")" . $self->deparse_statements($info->{block}{code});
            }
            if (exists $obj->{else}) {
                $code .= 'else' . $self->deparse_statements($obj->{else}{block}{code});
            }
            $code .= "end";
        }
        elsif ($ref eq 'Sidef::Types::Block::While') {
            $code = "while" . $self->deparse_args($obj->{expr}) . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Sidef::Types::Block::ForEach') {
            $code = 'each('
              . $self->deparse_generic('', ',', '', $obj->{expr}) . ','
              . $self->deparse_expr({self => $obj->{block}}) . ')';
        }
        elsif ($ref eq 'Sidef::Types::Block::CFor') {
            die "ERROR: the C-for loop is not supported, yet!";
        }
        elsif ($ref eq 'Sidef::Types::Block::ForIn') {
            my $var = $self->deparse_expr({self => $obj->{var}});
            $code =
                'for '
              . $var . ' in '
              . $self->deparse_expr({self => $obj->{array}})
              . '.value '
              . "\nisa($var, Number) && ($var = Sidef_Types_Number_Number($var))\n"
              . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Sidef::Types::Bool::Ternary') {
            $code = '('
              . $self->deparse_script($obj->{cond}) . ' ?'
              . $self->deparse_block_expr($obj->{true}) . ':'
              . $self->deparse_block_expr($obj->{false}) . ')';
        }
        elsif ($ref eq 'Sidef::Variable::NamedParam') {
            $code = $ref . '->new(' . $self->_dump_string($obj->[0]) . ', ' . $self->deparse_args(@{$obj->[1]}) . ')';
        }
        elsif ($ref eq 'Sidef::Types::Nil::Nil') {
            $code = 'Any';
        }
        elsif ($ref eq 'Sidef::Types::Hash::Hash') {
            if (keys(%{$obj})) {
                $code = $ref . '->new(' . join(
                    ', ',
                    map {
                        $self->_dump_string($_) . ' => '
                          . (defined($obj->{$_}) ? $self->deparse_expr({self => $obj->{$_}}) : 'undef')
                      } keys(%{$obj})
                  )
                  . ')';
            }
            else {
                $code = $self->make_constant($ref, 'new', "Hash$refaddr");
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::Do') {
            $code = 'begin ' . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Sidef::Types::Block::Loop') {
            $code = 'while(1) ' . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Sidef::Types::Block::Given') {
            $self->top_add(qq{use experimental 'smartmatch';\n});
            my $dvar = $self->_dump_var($obj->{block}{init_vars}->{vars}[0]);
            $code =
                'do{given (my '
              . $dvar . '='
              . $self->deparse_args($obj->{expr}) . ')'
              . $self->deparse_bare_block($obj->{block}{code}) . '}';
        }
        elsif ($ref eq 'Sidef::Types::Block::When') {
            $code = 'when($_ ~~ ' . $self->deparse_args($obj->{expr}) . ')' . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Sidef::Types::Block::Case') {
            $code = 'when(!!' . $self->deparse_args($obj->{expr}) . ')' . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Sidef::Types::Block::Default') {
            $code = 'default' . $self->deparse_bare_block($obj->{block}->{code});
        }
        elsif ($ref eq 'Sidef::Types::Block::With') {
            my $dvar = $self->_dump_var($obj->{block}{init_vars}->{vars}[0]);
            $code =
                'do{ if (defined(my '
              . $dvar . '='
              . $self->deparse_args($obj->{expr}) . ')) '
              . $self->deparse_bare_block($obj->{block}{code})
              . ' else { } }';
        }
        elsif ($ref eq 'Sidef::Types::Block::Gather') {
            $code =
                "do {my \@_$refaddr;"
              . $self->deparse_bare_block($obj->{block}->{code})
              . "; Sidef::Types::Array::Array->new(\@_$refaddr)}";
        }
        elsif ($ref eq 'Sidef::Types::Block::Take') {
            my $raddr = refaddr($obj->{gather});
            $code = "do { push \@_$raddr," . $self->deparse_args($obj->{expr}) . "; \$_$raddr\[-1] }";
        }
        elsif ($ref eq 'Sidef::Types::Block::Try') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Variable::Ref') {
            ## ok
        }
        elsif ($ref eq 'Sidef::Types::Block::Break') {
            $code = 'break';
        }
        elsif ($ref eq 'Sidef::Types::Block::Next') {
            $code = 'continue';
        }
        elsif ($ref eq 'Sidef::Types::Block::Continue') {
            $code = 'continue';
        }
        elsif ($ref eq 'Sidef::Types::Block::Return') {
            if (not exists $expr->{call}) {

                if (exists $self->{function}) {
                    $code = "goto END$self->{function}";
                }
                else {
                    $code = 'return Sidef::Types::Block::Return->new';
                }
            }
        }
        elsif ($ref eq 'Sidef::Math::Math') {
            $code = $self->make_constant($ref, 'new', "Math$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::Glob::FileHandle') {
            if ($obj->{fh} eq \*STDIN) {
                $code = $self->make_constant($ref, 'new', "STDIN$refaddr", 'fh => \*STDIN');
            }
            elsif ($obj->{fh} eq \*STDOUT) {
                $code = $self->make_constant($ref, 'new', "STDOUT$refaddr", 'fh => \*STDOUT');
            }
            elsif ($obj->{fh} eq \*STDERR) {
                $code = $self->make_constant($ref, 'new', "STDERR$refaddr", 'fh => \*STDERR');
            }
            elsif ($obj->{fh} eq \*ARGV) {
                $code = $self->make_constant($ref, 'new', "ARGF$refaddr", 'fh => \*ARGV');
            }
            else {
                my $data = $self->_dump_string(
                                               do { seek($obj->{fh}, 0, 0); local $/; readline($obj->{fh}) }
                                              );
                $code =
                  $self->make_constant($ref, 'new', "DATA$refaddr", qq{fh => do {open my \$fh, '<:utf8', \\$data; \$fh}});
            }
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
            eval do {
            local \$Sidef::DEPARSER->{before} = '';
            local \$Sidef::DEPARSER->{top_program} = '';
            local \$Sidef::DEPARSER->{_has_constant} = 0;
            local \$Sidef::DEPARSER->{function_declarations} = [];
            local \$Sidef::DEPARSER->{block_declarations} = [];
            \$Sidef::DEPARSER->deparse(
            do {
                local \$Sidef::PARSER->{line} = 0;
                local \$Sidef::PARSER->{file_name} = 'eval($refaddr)';
                local \$Sidef::PARSER->{vars} = \$Sidef::EVALS{$refaddr}{vars};
                local \$Sidef::PARSER->{ref_vars_refs} = \$Sidef::EVALS{$refaddr}{ref_vars_refs};
                \$Sidef::PARSER->parse_script(code => \\(~ . $self->deparse_script($obj->{expr}) . qq~->get_value));
            })}~;
        }
        elsif ($ref eq 'Sidef::Time::Time') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Sys::Sig') {
            $code = $self->make_constant($ref, 'new', "Sig$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::Number::Complex') {

            #$code = $self->make_constant($ref, 'new', "Complex$refaddr", "'" . ${$obj}->Re . "'", "'" . ${$obj}->Im . "'");
            $code = $self->make_constant(
                $ref, 'new', "Complex$refaddr",

                #"'" . $obj->re->get_value . "'",
                #"'" . $obj->im->get_value . "'"
                                        );
        }
        elsif ($ref eq 'Sidef::Types::Array::Pair') {
            if (all { not defined($_) } @{$obj}) {
                $code = $self->make_constant($ref, 'new', "Pair$refaddr");
            }
            else {
                $code =
                    $ref
                  . '->new('
                  . join(', ', map { defined($_) ? $self->deparse_expr({self => $_}) : 'undef' } @{$obj}) . ')';
            }
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
            $code = _normalize_type($ref);
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
                @args == 1
                  or die "[ERROR] Incorrect number of arguments for $obj->{act}\() at"
                  . " $obj->{file} line $obj->{line} (expected 1 argument)\n";

                # Generate code
                $code = qq~do{my \$a$refaddr = do{$args[0]}; \$a$refaddr or CORE::die "$obj->{act}(\$a$refaddr) failed ~
                  . qq~at \Q$obj->{file}\E line $obj->{line}\\n"}~;
            }
            elsif ($obj->{act} eq 'assert_eq' or $obj->{act} eq 'assert_ne') {

                # Check arity
                @args == 2
                  or die "[ERROR] Incorrect number of arguments for $obj->{act}\() at"
                  . " $obj->{file} line $obj->{line} (expected 2 arguments)\n";

                # Generate code
                $code = "do{"
                  . "my \$a$refaddr = do{$args[0]};"
                  . "my \$b$refaddr = do{$args[1]};"
                  . ($obj->{act} eq 'assert_ne' ? qq{CORE::not(\$a$refaddr eq \$b$refaddr)} : qq{\$a$refaddr eq \$b$refaddr})
                  . qq~ or CORE::die "$obj->{act}(\$a$refaddr, \$b$refaddr) failed at \Q$obj->{file}\E line $obj->{line}\\n"}~;
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
        elsif ($ref eq 'Sidef::Object::Object') {
            $code = $self->make_constant($ref, 'new', "Object$refaddr");
        }
        elsif ($ref eq 'Sidef::Variable::LazyMethod') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Array::MultiArray') {
            $code = $self->make_constant($ref, 'new', "MultiArr$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::Glob::Pipe') {
            $code = $self->make_constant($ref, 'new', "Pipe$refaddr", map { $self->_dump_string($_) } @{$obj});
        }
        elsif ($ref eq 'Sidef::Parser') {
            $code = $self->make_constant($ref, 'new', "Parser$refaddr");
        }
        elsif ($ref eq 'Sidef') {
            $code = $self->make_constant($ref, 'new', "Sidef$refaddr");
        }
        elsif ($ref eq 'Sidef::Perl::Perl') {
            $code = $self->make_constant($ref, 'new', "Perl$refaddr");
        }
        elsif ($ref eq 'Sidef::Meta::Unimplemented') {
            $code = qq{CORE::die "Unimplemented at " . } . $self->_dump_string($obj->{file}) . qq{. " line $obj->{line}\\n"};
        }
        elsif (exists $self->{data_types}{$ref}) {
            $code = $self->{data_types}{$ref};
        }

        # Array and hash indices
        if (exists $expr->{ind}) {
            my $limit = $#{$expr->{ind}};
            foreach my $i (0 .. $limit) {

                my $ind = $expr->{ind}[$i];
                if (exists $ind->{array}) {

                    my $pos = $ind->{array};

                    if (substr($code, -1) eq '@') {
                        $code .= $self->_dump_unpacked_indices($pos);
                    }
                    else {
                        $code = $code . $self->_dump_indices($pos);
                    }
                }
                else {

                    my $key = $ind->{hash};

                    if (substr($code, -1) eq '@') {
                        $code .= $self->_dump_unpacked_lookups($key);
                    }
                    else {
                        $code = $code . $self->_dump_lookups($key);
                    }
                }

                if ($i < $limit) {
                    if ($expr->{ind}[$i + 1]{array}) {
                        $code = '(' . $code . ' //= Sidef::Types::Array::Array->new' . ')';
                    }
                    else {
                        $code = '(' . $code . ' //= Sidef::Types::Hash::Hash->new' . ')';
                    }
                }
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {

            my $end = $#{$expr->{call}};
            foreach my $i (0 .. $end) {

                my $call   = $expr->{call}[$i];
                my $method = $call->{method};

                if ($code ne '') {
                    $code = '(' . $code . ')';
                }

                if ($ref eq 'Sidef::Types::Block::Return') {

                    if (exists $self->{function}) {

                        #$code .= 'do {';
                        #if (@{$call->{arg}}) {
                        #    $code .= '@return = ' . $self->deparse_args(@{$call->{arg}}) . ';';
                        #}
                        #$code .= 'goto ' . "END$self->{function}}";

                        ## TODO: add support to return from inner blocks
                        $code .= 'return ' . $self->deparse_args(@{$call->{arg}});
                    }
                    else {
                        $code .= 'return Sidef::Types::Block::Return->new' . $self->deparse_args(@{$call->{arg}});
                    }

                    next;
                }

                # !!!Experimental!!!
                #~ if ($ref eq 'Sidef::Types::Block::Break') {
                #~ $code .= 'return Sidef::Types::Block::Break->new' . $self->deparse_args(@{$call->{arg}});
                #~ next;
                #~ }
                #~ elsif ($ref eq 'Sidef::Types::Block::Next') {
                #~ $code .= 'return Sidef::Types::Block::Next->new' . $self->deparse_args(@{$call->{arg}});
                #~ next;
                #~ }

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

                            #$code = "($var=$var\->$self->{inc_dec_ops}{$method})[0]";
                            $code = "do{my \$ref=\\$var; \$\$ref=\$\$ref\->$self->{inc_dec_ops}{$method}}";
                            next;
                        }
                    }

                    # Postfix ++ and -- operators on variables
                    if (exists($self->{inc_dec_ops}{$method})) {

                        #$code = "do{my \$old=$code; $code=$code\->$self->{inc_dec_ops}{$method}; \$old}";
                        $code =
                          "do{my \$ref=\\$code; my \$value=\$\$ref; \$\$ref=\$value\->$self->{inc_dec_ops}{$method}; \$value}";
                        next;
                    }

                    if (exists($self->{lazy_ops}{$method})) {
                        $code .= $self->{lazy_ops}{$method} . $self->deparse_block_expr(@{$call->{arg}}) . ' ';
                        next;
                    }

                    # Variable assignment (=)
                    if (exists($self->{assignment_ops}{$method})) {
                        $code = "($code$self->{assignment_ops}{$method}" . $self->deparse_args(@{$call->{arg}}) . ")";
                        next;
                    }

                    # Reassignment operators, such as: +=, -=, *=, /=, etc...
                    if (exists $self->{reassign_ops}{$method}) {

                        ## OLD CODE
                        #$code =
                        #"CORE::sub : lvalue {my \$ref=\\$code; \$\$ref=\$\$ref\->\${\\'$self->{reassign_ops}{$method}'}"
                        #. $self->deparse_args(@{$call->{arg}}) . "}->()";

                        $method =~ s/^\^/\$/;
                        $method =~ s/^\*\*/^/;

                        $code = "$code $method " . $self->deparse_args(@{$call->{arg}});

                        #$code =
                        #    "do {my \$ref="
                        #  . ($i == 0 ? '\\' : '')
                        #  . "$code; \$\$ref=\$\$ref\->\${\\'$self->{reassign_ops}{$method}'}"
                        #  . (exists($call->{arg}) ? $self->deparse_args(@{$call->{arg}}) : '') . "; "
                        #  . ($i == $end ? '$' : '')
                        #  . "\$ref}";

                        next;
                    }

                    #~ # != and == methods
                    #~ if ($method eq '==' or $method eq '!=') {
                    #~ $code =
                    #~ '(' . 'do{'
                    #~ . $code
                    #~ . '} eq do{'
                    #~ . $self->deparse_args(@{$call->{arg}}) . '} ? '
                    #~ . (
                    #~ $method eq '!='
                    #~ ? '(Sidef::Types::Bool::Bool::FALSE) : (Sidef::Types::Bool::Bool::TRUE)'
                    #~ : '(Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE)'
                    #~ )
                    #~ . ')';
                    #~ next;
                    #~ }

                    # <=> method
                    if ($method eq '<=>') {
                        $code =
                            '((Sidef::Types::Number::Number::ZERO,'
                          . 'Sidef::Types::Number::Number::ONE,'
                          . 'Sidef::Types::Number::Number::MONE)[do{'
                          . $code
                          . '} cmp do {'
                          . $self->deparse_args(@{$call->{arg}}) . '}])';
                        next;
                    }

                    # !~ and ~~ methods
                    if ($method eq '~~' or $method eq '!~') {
                        $self->top_add(qq{use experimental 'smartmatch';\n});
                        $code =
                            '(' . 'do{'
                          . $code
                          . '} ~~ do{'
                          . $self->deparse_args(@{$call->{arg}}) . '} ? '
                          . (
                             $method eq '!~'
                             ? '(Sidef::Types::Bool::Bool::FALSE) : (Sidef::Types::Bool::Bool::TRUE)'
                             : '(Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE)'
                            )
                          . ')';
                        next;
                    }

                    # ! prefix-unary
                    if ($ref eq 'Sidef::Object::Unary') {
                        if ($method eq '!') {
                            $code = '(do{'
                              . $self->deparse_args(@{$call->{arg}})
                              . '} ? (Sidef::Types::Bool::Bool::FALSE) : (Sidef::Types::Bool::Bool::TRUE))';
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

                        if ($method eq '~') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->not';
                            next;
                        }

                        if ($method eq '√') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->sqrt';
                            next;
                        }

                        if ($method eq 'say' or $method eq '>') {
                            $code = 'say' . $self->deparse_args(@{$call->{arg}});
                            next;
                        }

                        if ($method eq 'print' or $method eq '>>') {
                            $code =
                              'print' . $self->deparse_args(@{$call->{arg}});
                            next;
                        }

                        if ($method eq 'defined') {
                            $code = '(' . $self->deparse_args(@{$call->{arg}}) . ' != Any)';
                            next;
                        }
                    }

                    if (ref($method)) {
                        $code .=
                          '->${\\do{' . $self->deparse_expr(ref($method) eq 'HASH' ? $method : {self => $method}) . '}}';
                    }
                    elsif ($method =~ /^[\pL_]/) {

                        # Exclamation mark (!) at the end of a method
                        if (substr($method, -1) eq '!') {

                            $code =
                                "CORE::sub : lvalue {my \$ref=\\$code; \$\$ref=\$\$ref\->"
                              . substr($method, 0, -1)
                              . (exists($call->{arg}) ? $self->deparse_args(@{$call->{arg}}) : '') . "}->()";

                            #$code =
                            #    "do {my \$ref="
                            #  . ($i == 0 ? '\\' : '')
                            #  . "$code; \$\$ref=\$\$ref\->"
                            #  . substr($method, 0, -1)
                            #  . (exists($call->{arg}) ? $self->deparse_args(@{$call->{arg}}) : '') . "; "
                            #  . ($i == $end ? '$' : '')
                            #  . "\$ref}";

                            next;
                        }

                        # Special case for methods without '->'
                        else {
                            #$code .= '->' if $code ne '';
                            #$code .= $method;
                            $code .= ',';
                        }
                    }
                    else {

                        # Postfix dereference method
                        if ($method eq '@' or $method eq '@*') {
                            $self->top_add(qq{use experimental 'postderef';\n});
                            $code .= '->' . $method;
                        }

                        # Operator-like method call
                        else {
                            #$code .= $method; #'->${\\' . q{'} . $method . q{'} . '}';

                            if ($method eq '^') {
                                $method = '$';
                            }
                            else {
                                if ($method eq '**') {
                                    $method = '^';
                                }
                            }

                            $code .= ',';
                        }
                    }
                }

                if (exists $call->{keyword}) {
                    $code .= $call->{keyword};
                }

                if (exists $call->{arg}) {
                    $code .= $self->deparse_generic('', ',', '', @{$call->{arg}});
                }

                if ($method ne '') {
                    $code = "($method)($code)";
                }

                if (exists $call->{block}) {
                    $code .= $self->deparse_bare_block(@{$call->{block}});
                    next;
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
           . ($self->{_has_constant} ? "};\n" : '')
           . (
              exists($self->{function_declarations})
                && @{$self->{function_declarations}}
              ? ("\n" . join("\n", map { $_->[1] } @{$self->{function_declarations}}) . "\n")
              : ''
             )
           . (
              exists($self->{block_declarations})
                && @{$self->{block_declarations}} ? ("\n" . join("\n", map { $_->[1] } @{$self->{block_declarations}}) . "\n")
              : ''
             )
           . $self->{top_program} . "\n"
           . join($self->{between}, @statements)
           . $self->{after} . "end\n"
        ) =~ s/^\s*/$self->{header}/r;
    }
}

1;
