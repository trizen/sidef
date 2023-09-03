package Sidef::Deparse::Perl {

    use utf8;
    use 5.016;

    use Scalar::Util qw(refaddr);
    use Sidef::Types::Number::Number;

    my %addr;
    my %top_add;

    my %constant_number_cache;
    my %constant_string_cache;

    my %composite_constants = (
        'Sidef::Types::Range::RangeNumber' => {
                                               name   => 'RangeNum',
                                               fields => [qw(from to step)],
                                              },

        'Sidef::Types::Range::RangeString' => {
                                               name   => 'RangeStr',
                                               fields => [qw(from to step)],
                                              },

        'Sidef::Types::Number::Gauss' => {
                                          name   => 'Gauss',
                                          fields => [qw(a b)],
                                         },

        'Sidef::Types::Number::Quadratic' => {
                                              name   => 'Quadratic',
                                              fields => [qw(a b w)],
                                             },

        'Sidef::Types::Number::Quaternion' => {
                                               name   => 'Quaternion',
                                               fields => [qw(a b c d)],
                                              },

        'Sidef::Types::Number::Fraction' => {
                                             name   => 'Fraction',
                                             fields => [qw(a b)],
                                            },

        'Sidef::Types::Number::Mod' => {
                                        name   => 'Mod',
                                        fields => [qw(n m)],
                                       },
                              );

    sub new {
        my (undef, %args) = @_;

        my %opts = (
            before      => '',
            header      => '',
            top_program => '',
            between     => ';',
            after       => ';',
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
                                },

            data_types => {
                qw(
                  Sidef::DataTypes::Bool::Bool            Sidef::Types::Bool::Bool
                  Sidef::DataTypes::Array::Array          Sidef::Types::Array::Array
                  Sidef::DataTypes::Array::Pair           Sidef::Types::Array::Pair
                  Sidef::DataTypes::Array::Vector         Sidef::Types::Array::Vector
                  Sidef::DataTypes::Array::Matrix         Sidef::Types::Array::Matrix
                  Sidef::DataTypes::Hash::Hash            Sidef::Types::Hash::Hash
                  Sidef::DataTypes::Set::Set              Sidef::Types::Set::Set
                  Sidef::DataTypes::Set::Bag              Sidef::Types::Set::Bag
                  Sidef::DataTypes::Regex::Regex          Sidef::Types::Regex::Regex
                  Sidef::DataTypes::String::String        Sidef::Types::String::String
                  Sidef::DataTypes::Number::Number        Sidef::Types::Number::Number
                  Sidef::DataTypes::Number::Mod           Sidef::Types::Number::Mod
                  Sidef::DataTypes::Number::Gauss         Sidef::Types::Number::Gauss
                  Sidef::DataTypes::Number::Quadratic     Sidef::Types::Number::Quadratic
                  Sidef::DataTypes::Number::Quaternion    Sidef::Types::Number::Quaternion
                  Sidef::DataTypes::Number::Complex       Sidef::Types::Number::Complex
                  Sidef::DataTypes::Number::Polynomial    Sidef::Types::Number::Polynomial
                  Sidef::DataTypes::Number::Fraction      Sidef::Types::Number::Fraction
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
                  Sidef::DataTypes::Perl::Perl            Sidef::Types::Perl::Perl
                  Sidef::DataTypes::Object::Object        Sidef::Object::Object
                  Sidef::DataTypes::Sidef::Sidef          Sidef
                  Sidef::DataTypes::Object::Lazy          Sidef::Object::Lazy
                  Sidef::DataTypes::Object::LazyMethod    Sidef::Object::LazyMethod
                  Sidef::DataTypes::Object::Enumerator    Sidef::Object::Enumerator
                  Sidef::DataTypes::Variable::NamedParam  Sidef::Variable::NamedParam

                  Sidef::Meta::PrefixColon                Sidef::Types::Hash::Hash

                  Sidef::Sys::Sig                         Sidef::Sys::Sig
                  Sidef::Sys::Sys                         Sidef::Sys::Sys
                  Sidef::Math::Math                       Sidef::Math::Math

                  Sidef::Time::Time                       Sidef::Time::Time
                  Sidef::Time::Date                       Sidef::Time::Date
                  )
            },

            reassign_ops => {map { ("$_=", $_) } qw(+ - % * // / & | ^ ** && || << >> ÷)},

            inc_dec_ops => {
                            '++' => 'inc',
                            '--' => 'dec',
                           },
            %args,
        );

        $opts{header} .= <<"HEADER";

use utf8;
use ${\($] <= 5.026 ? $] : 5.026)};
local \$| = 1;   # autoflush

HEADER

        if (defined $opts{opt}{w}) {
            $opts{header} .= '$SIG{__WARN__} = sub { require Carp; Carp::cluck(@_) };';
        }

        if (defined $opts{opt}{W}) {
            $opts{header} .= '$SIG{__DIE__} = $SIG{__WARN__} = sub { require Carp; Carp::confess(@_) };';
        }

        if (exists $opts{opt}{P}) {
            my $precision = abs(int($opts{opt}{P}));
            $opts{header} .= "BEGIN { \$Sidef::Types::Number::Number::PREC = 4*$precision };";
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
            elsif ($round eq 'faith') {
                $round = 5;
            }
            else {
                $round = 0;
            }

            $opts{header} .= "BEGIN { \$Sidef::Types::Number::Number::ROUND = $round };";
        }

        undef %addr;
        undef %top_add;

        undef %constant_number_cache;
        undef %constant_string_cache;

        bless \%opts, __PACKAGE__;
    }

    sub make_constant {
        my ($self, $ref, $new_method, $name, %opt) = @_;

        my $rel_name  = $name . join('_', map { refaddr(\$_) } @{$opt{args}}) . CORE::int(CORE::rand(~0));
        my $full_name = $self->{environment_name} . '::' . $rel_name;

        if (not $self->{_has_constant}) {
            $self->{_has_constant} = 1;
            $self->{before} .= "use constant {";
        }

        if ($opt{new}) {
            if ($self->{_has_constant}) {
                $self->{before} .= '};';
            }
            $self->{_has_constant} = 1;
            $self->{before} .= "use constant {";
        }

        $self->{before} .= "$rel_name => $ref" . ($opt{sub} ? '::' : '->') . "$new_method(" . join(',', @{$opt{args}}) . "),";
        "($full_name)";
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

        ($ref eq 'Sidef::Variable::Struct' || $ref eq 'Sidef::Variable::Subset') ? $self->_dump_class_name($obj)
          : $ref eq 'Sidef::Variable::ClassInit'     ? (ref($obj->{name}) ? $self->_dump_class_name($obj->{name}) : $self->_dump_class_name($obj))
          : $ref eq 'Sidef::Variable::Ref'           ? 'REF'
          : $ref eq 'Sidef::Types::Block::BlockInit' ? 'Sidef::Types::Block::Block'
          :                                            $ref;
    }

    sub _dump_reftype {
        my ($self, $obj) = @_;
        $self->_dump_string($self->_get_reftype($obj));
    }

    {
        my %esc = (
                   "\a" => "\\a",
                   "\b" => "\\b",
                   "\t" => "\\t",
                   "\n" => "\\n",
                   "\f" => "\\f",
                   "\r" => "\\r",
                   "\e" => "\\e",
                  );

        sub _dump_string {
            my ($self, $str) = @_;

            # Function by Gisle Aas, copied from `Data::Dump` (thanks).

            $str =~ s/([\\\"\@\$])/\\$1/g;
            return qq("$str") if ($str !~ /[^\040-\176]/);    # fast exit

            $str =~ s/([\a\b\t\n\f\r\e])/$esc{$1}/g;

            # no need for 3 digits in escape for these
            $str =~ s/([\0-\037])(?!\d)/sprintf('\\%o',ord($1))/eg;

            $str =~ s/([\0-\037\177-\377])/sprintf('\\x%02X',ord($1))/eg;
            $str =~ s/([^\040-\176])/sprintf('\\x{%X}',ord($1))/eg;

            return qq("$str");
        }
    }

    sub _dump_op_call {
        my ($self, $method) = @_;

        my $name = 'OP' . join('', unpack('C*', $method)) . refaddr($self);
        my $line = "BEGIN { \$$self->{environment_name}\::$name = " . $self->_dump_string($method) . '};';
        $self->top_add($line);
        '->$' . $self->{environment_name} . '::' . $name;
    }

    sub _dump_var {
        my ($self, $var, %opt) = @_;

        $var->{name} eq '' and return 'undef';

        (
         $opt{init}
         ? (
              exists($var->{array}) ? '@'
            : exists($var->{hash})  ? '%'
            :                         '$'
           )
         : '$'
        )
          . ($var->{type} eq 'global' ? ($var->{class} . '::') : '')

          . $var->{name} . ($var->{type} eq 'global' ? '' : ($opt{refaddr} // refaddr($var)));
    }

    sub _dump_init_vars {
        my ($self, $init_obj) = @_;

        my @vars = @{$init_obj->{vars}};

        if (!@vars or $vars[0]{type} eq 'del') {
            return '';
        }

        my @code;

        push @code,
            '('
          . join(',', map { $self->_dump_var($_, init => 1) } @vars) . ')'
          . (exists($init_obj->{args}) ? '=' . $self->deparse_args($init_obj->{args}) : '');

        foreach my $var (@vars) {

            ref($var) || next;

            my $name = $var->{name} . refaddr($var);
            my $decl = 'my ';

            if ($var->{type} eq 'global') {
                $name = $var->{class} . '::' . $var->{name};
                $decl = '';
            }

            if (exists $var->{array}) {

                push @{$self->{block_declarations}}, [$self->{current_block} // -1, $decl . '@' . $name . ';'];

                # Overwrite with the default values, when the array is empty
                if (exists $var->{value}) {
                    push @code, ('@' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not \@$name;");
                }

                $self->load_mod('Sidef::Types::Array::Array');
                push @code, "\$$name = bless(\\\@$name, 'Sidef::Types::Array::Array');";
            }
            elsif (exists $var->{hash}) {

                push @{$self->{block_declarations}}, [$self->{current_block} // -1, $decl . '%' . $name . ';'];

                # Overwrite with the default values, when the hash has no keys
                if (exists $var->{value}) {
                    push @code, ('%' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not keys \%$name;");
                }

                $self->load_mod('Sidef::Types::Hash::Hash');
                push @code, "\$$name = bless(\\\%$name, 'Sidef::Types::Hash::Hash');";
            }
            elsif (exists $var->{value}) {
                my $value = $self->deparse_expr({self => $var->{value}});
                if ($value ne '') {
                    push @code, "\$$name//=$value;";
                }
            }
        }

        if (my @non_globals = grep { $_->{type} ne 'global' } @vars) {
            push @{$self->{block_declarations}}, [$self->{current_block} // -1, 'my(' . join(',', map { $self->_dump_var($_) } @non_globals) . ')' . ';'];
        }

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

            my @dumped_vars = map { ref($_) ? $self->_dump_var($_, init => 1) : $_ } grep { !$seen{$_->{name}}++ } @vars;

            @dumped_vars || next;

            unshift @code, ('my(' . join(',', @dumped_vars) . ')' . (exists($attr->{args}) ? '=' . $self->deparse_args($attr->{args}) : ''));

            foreach my $var (@vars) {

                my $name = $var->{name} . refaddr($var);

                if (exists $var->{array}) {

                    # Overwrite with the default values, when the array is empty
                    if (exists $var->{value}) {
                        push @code, ('@' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not \@$name;");
                    }

                    $self->load_mod('Sidef::Types::Array::Array');
                    push @code, "my \$$name = bless(\\\@$name, 'Sidef::Types::Array::Array');";
                }
                elsif (exists $var->{hash}) {

                    # Overwrite with the default values, when the hash has no keys
                    if (exists $var->{value}) {
                        push @code, ('%' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not keys \%$name;");
                    }

                    $self->load_mod('Sidef::Types::Hash::Hash');
                    push @code, "my \$$name = bless(\\\%$name, 'Sidef::Types::Hash::Hash');";
                }
                elsif (exists $var->{value}) {
                    my $value = $self->deparse_expr({self => $var->{value}});
                    if ($value ne '') {
                        push @code, "\$$name//=$value;";
                    }
                }
            }

        }

        @code ? (join(';', @code) . ';') : '';
    }

    sub _dump_sub_init_vars {
        my ($self, @vars) = @_;

        @vars || return '';

        my @dumped_vars = map { ref($_) ? $self->_dump_var($_, init => 1) : $_ } @vars;
        my $code        = "my(" . join(',', @dumped_vars) . ')=@_;';

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
            }
            elsif (exists $var->{hash}) {
                my $name = $var->{name} . refaddr($var);

                # Overwrite with the default values, when the hash has no keys
                if (exists $var->{value}) {
                    $code .= ('%' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not keys \%$name;");
                }

                $self->load_mod('Sidef::Types::Hash::Hash');
                $code .= "my \$$name = bless(\\\%$name, 'Sidef::Types::Hash::Hash');";
            }
            elsif (exists $var->{value}) {
                my $value = $self->deparse_expr({self => $var->{value}});
                if ($value ne '') {
                    $code .= "\$$var->{name}" . refaddr($var) . "//=$value;";
                }
            }
        }

        $code .= '();';
        $valid ? $code : '';
    }

    sub _dump_array {
        my ($self, $ref, $array) = @_;
        $self->load_mod($ref);
        'bless([' . join(',', map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}) } @{$array}) . "], '${ref}')";
    }

    sub _dump_indices {
        my ($self, $array) = @_;

        my @indices;

        foreach my $entry (@{$array}) {

            # Optimization: when the index is just a number parsed as an expression
            if (ref($entry) eq 'HASH' and exists($entry->{self}) and scalar(keys %$entry) == 1) {
                my $obj = $entry->{self};
                if (ref($obj) eq 'HASH' and scalar(keys %$obj) == 1 and !exists($obj->{self})) {
                    foreach my $class (keys %$obj) {
                        my $statements = $obj->{$class};
                        scalar(@$statements) == 1 or next;
                        $obj = $statements->[0];
                        ref($obj) eq 'HASH'     or next;
                        scalar(keys %$obj) == 1 or next;
                        exists($obj->{self})    or next;
                        $obj = $obj->{self};
                        if (ref($obj) eq 'Sidef::Types::Number::Number') {
                            $entry = $obj;
                        }
                    }
                }
            }

            if (ref($entry) eq 'Sidef::Types::Number::Number') {
                push @indices, (ref($$entry) ? CORE::int(Sidef::Types::Number::Number::__numify__($$entry)) : $$entry);
            }
            elsif (ref($entry)) {
                my $str = $self->deparse_expr(ref($entry) eq 'HASH' ? $entry : {self => $entry});

                if ($str ne '') {
                    push @indices,
                      (   '(map { ref($_) eq "Sidef::Types::Number::Number" ? '
                        . '(ref($$_) ? Sidef::Types::Number::Number::__numify__($$_) : $$_) '
                        . ': do {my$sub=ref($_) && UNIVERSAL::can($_, "..."); '
                        . '$sub ? $sub->($_) : CORE::int($_) } } '
                        . $str
                        . ')');
                }
            }
            else {
                push @indices, $entry;
            }
        }

        join(',', @indices);
    }

    sub _dump_lookups {
        my ($self, $array) = @_;

        my @indices;

        foreach my $entry (@{$array}) {

            # Optimization: when the index is just a string or a number parsed as an expression
            if (ref($entry) eq 'HASH' and exists($entry->{self}) and scalar(keys %$entry) == 1) {
                my $obj = $entry->{self};
                if (ref($obj) eq 'HASH' and scalar(keys %$obj) == 1 and !exists($obj->{self})) {
                    foreach my $class (keys %$obj) {
                        my $statements = $obj->{$class};
                        scalar(@$statements) == 1 or next;
                        $obj = $statements->[0];
                        ref($obj) eq 'HASH'     or next;
                        scalar(keys %$obj) == 1 or next;
                        exists($obj->{self})    or next;
                        $obj = $obj->{self};
                        if (ref($obj) eq 'Sidef::Types::String::String' or ref($obj) eq 'Sidef::Types::Number::Number') {
                            $entry = $obj;
                        }
                    }
                }
            }

            if (ref($entry) eq 'Sidef::Types::String::String') {
                push @indices, $self->_dump_string($$entry);
            }
            elsif (ref($entry) eq 'Sidef::Types::Number::Number') {
                push @indices, $self->_dump_string("$entry");
            }
            elsif (ref($entry)) {
                my $str = $self->deparse_expr(ref($entry) eq 'HASH' ? $entry : {self => $entry});

                if ($str ne '') {
                    push @indices, ('(map { ref($_) eq "Sidef::Types::String::String" ? $$_ : "$_" } ' . $str . ')');
                }
            }
            else {
                push @indices, $self->_dump_string($entry);
            }
        }

        join(',', @indices);
    }

    sub _dump_var_attr {
        my ($self, @vars) = @_;

        'vars=>[' . join(
            ',',
            map {
                    '{name=>'
                  . $self->_dump_string($_->{name})
                  . (exists($_->{slurpy})    ? (',slurpy=>' . $_->{slurpy})                       : '')
                  . (exists($_->{array})     ? (',array=>' . $_->{array})                         : '')
                  . (exists($_->{ref_type})  ? (',type=>' . $self->_dump_reftype($_->{ref_type})) : '')
                  . (exists($_->{subset})    ? (',subset=>' . $self->_dump_reftype($_->{subset})) : '')
                  . (exists($_->{has_value}) ? (',has_value=>1')                                  : '')
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
          . ']'
          . ','
          . 'table=>{'
          . join(',', map { $self->_dump_string($vars[$_]{name}) . '=>' . $_ } 0 .. $#vars) . '}';
    }

    sub _get_inherited_stuff {
        my ($self, $classes, $callback) = @_;

        my @vars;
        foreach my $class (@{$classes}) {
            push @vars, $callback->($class);
            if (defined $class->{inherit}) {
                unshift @vars, $self->_get_inherited_stuff($class->{inherit}, $callback);
            }
        }

        @vars;
    }

    sub _dump_class_name {
        my ($self, $class) = @_;

        join('::',
             $self->{environment_name},
             refaddr($class->{parent} || $class),
             $class->{class} || 'main',
             $class->{name}  || (Sidef::normalize_type(ref($class)) . refaddr($class)));
    }

    sub _dump_static_var {
        my ($self, $var, $refaddr) = @_;

        if ($var->{array}) {
            $self->load_mod("Sidef::Types::Array::Array");
        }
        elsif ($var->{hash}) {
            $self->load_mod("Sidef::Types::Hash::Hash");
        }

        "state\$$var->{name}$refaddr=do{my \@data = ("
          . (defined($var->{value}) ? $self->deparse_script($var->{value}) : '') . ');'
          . (
             $var->{slurpy}
             ? (
                $var->{array}
                ? "bless(\\\@data, 'Sidef::Types::Array::Array')"
                : "bless({\@data}, 'Sidef::Types::Hash::Hash')"
               )
             : "\$data[0]"
            )
          . "}";
    }

    sub deparse_generic {
        my ($self, $before, $sep, $after, @args) = @_;
        $before
          . join($sep, map { ref($_) eq 'HASH' ? $self->deparse_script($_) : ref($_) ? $self->deparse_expr({self => $_}) : $self->_dump_string($_) } @args)
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

    sub localize_declarations {
        my ($self, $refaddr) = @_;

        my $code = '';

        # Localize variable declarations
        while (    exists($self->{block_declarations})
               and @{$self->{block_declarations}}
               and $self->{block_declarations}[-1][0] == $refaddr) {
            $code .= pop(@{$self->{block_declarations}})->[1];
        }

        # Localize function declarations
        while (    exists($self->{function_declarations})
               and @{$self->{function_declarations}}
               and $self->{function_declarations}[-1][0] != $refaddr) {
            $self->{depth} <= $self->{function_declarations}[-1][2] or last;
            $code .= pop(@{$self->{function_declarations}})->[1];
        }

        $code;
    }

    sub deparse_block_with_scope {
        my ($self, $obj) = @_;

        my $refaddr = refaddr($obj);
        local $self->{current_block} = $refaddr;
        local $self->{depth}         = ($self->{depth} // 0) + 1;

        my @statements = join(';', $self->deparse_script($obj->{code}));

        my $code = '{';
        $code .= $self->localize_declarations($refaddr);
        $code . join(';', @statements) . '}';
    }

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $code    = '';
        my $obj     = $expr->{self};
        my $refaddr = refaddr($obj);

        # Self obj
        my $ref = ref($obj) || return '';
        if ($ref eq 'HASH') {
            $code = join(',', exists($obj->{self}) ? $self->deparse_expr($obj) : $self->deparse_script($obj));
        }
        elsif ($ref eq 'Sidef::Variable::Variable') {
            if ($obj->{type} eq 'func' or $obj->{type} eq 'method') {

                # Anonymous function
                if ($obj->{name} eq '') {
                    $obj->{name} = "__FUNC__";
                }

                my $name      = $obj->{name};
                my $alphaname = $obj->{name};

                # Set type to `func` when the method is a kid
                local $obj->{type} = 'func' if exists($obj->{parent});

                # Check for alphanumeric name
                if (not $obj->{name} =~ /^[^\W\d]\w*+\z/) {
                    $alphaname = '__NONANN__';    # use this name for non-alphanumeric names
                }

                if ($addr{$refaddr}++) {
                    $code = "\$$alphaname$refaddr";
                }
                else {
                    my $block = $obj->{value};

                    # The name of the function
                    $code .= "\$${alphaname}$refaddr";

                    # Deparse the block of the method/function
                    {
                        local $self->{function}          = refaddr($block);
                        local $self->{parent_name}       = [$obj->{type}, $name];
                        local $self->{current_namespace} = $obj->{class};

                        push @{$self->{function_declarations}}, [$self->{function}, "my \$${alphaname}$refaddr;", $self->{depth} // 0];

#<<<
                        if ($self->{ref_class} and !exists($obj->{parent})) {
                            push @{$self->{function_declarations}},
                              [ $self->{function},
                                qq{state \$${alphaname}_code$refaddr = UNIVERSAL::can("\Q$self->{class_name}\E", "\Q$name\E");},
                                $self->{depth} // 0
                              ];
                        }
#>>>
                        if ((my $content = $self->deparse_expr({self => $block})) ne '') {
                            $code .= "=$content";
                        }
                    }

                    # Check if the method/function is a kid (can do multiple dispatch)
                    if (exists $obj->{parent}) {
                        my $name = $self->deparse_expr({self => $obj->{parent}});
                        $code = "do{CORE::push(\@{" . $name . "->{kids} //= []}, do{$code});$name}";
                    }

                    # Check if the method is a parent and it's defined inside a buit-in class
                    elsif ($self->{ref_class}) {
                        chop $code;
                        $code .=
                          qq{,(defined(\$${alphaname}_code$refaddr)?(fallback=>} . qq{Sidef::Types::Block::Block->new(code=>\$${alphaname}_code$refaddr)):()))};
                    }

                    # Check the return value (when "-> Type" is specified)
                    if (exists $obj->{returns}) {
                        my $types = '[' . join(',', map { $self->_dump_reftype($_) } @{$obj->{returns}}) . ']';
                        $code = "do{$code;\$${alphaname}$refaddr\->{returns}=$types;\$${alphaname}$refaddr}";
                    }

                    # Memoize the method/function (when "is cached" trait is specified)
                    if ($obj->{cached}) {
                        $code = "do{$code;" . "\$${alphaname}$refaddr\->cache;\$${alphaname}$refaddr}";
                    }

                    if ($obj->{type} eq 'func' and !$obj->{parent}) {

                        # Special "MAIN" function
                        if (${alphaname} eq 'MAIN') {
                            $self->top_add('require Encode;');
                            $self->{after} .= "Sidef::Variable::GetOpt->new([map{Encode::decode_utf8(\$_)}\@ARGV],\$${alphaname}$refaddr);";
                        }
                    }
                    elsif ($obj->{type} eq 'method') {

                        # Special "AUTOLOAD" method
                        if (${alphaname} eq 'AUTOLOAD') {
                            $code .= ';'
                              . "our\$AUTOLOAD;"
                              . "sub ${alphaname} {my\$self=shift;"
                              . "my(\$class,\$method)=(\$AUTOLOAD=~/^(.*[^:])::(.*)\$/);"
                              . "\$${alphaname}$refaddr->call(\$self,Sidef::Types::String::String->new(\$class),Sidef::Types::String::String->new(\$method),\@_)}";
                        }

                        # Anonymous method
                        elsif (${alphaname} eq '__FUNC__') {
                            ## don't add anonymous methods to the class,
                            ## but allow them to be defined and used freely
                        }

                        # Other methods
                        else {
                            $code .= ";"
                              . "state\$_$refaddr=do{no strict 'refs';"
                              . "\$$self->{package_name}::__SIDEF_CLASS_METHODS__{'${name}'} = \$${alphaname}$refaddr;" . '*{'
                              . $self->_dump_string("$self->{package_name}::$name")
                              . "}=sub{\$${alphaname}$refaddr->call(\@_)}}";
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
            else {

                my $name = $obj->{name} . $refaddr;

                if ($obj->{name} eq 'ENV') {
                    $self->top_add("require Encode;");
                    $self->top_add(
                                qq{my \$$name = Sidef::Types::Hash::Hash->new} . qq{(map{Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \%ENV);});
                }
                elsif ($obj->{name} eq 'ARGV') {
                    $self->top_add("require Encode;");
                    $self->top_add(
                          qq{my \$$name = Sidef::Types::Array::Array->new} . qq{([map {Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \@ARGV]);});
                }

                $code = $self->_dump_var($obj, refaddr => $refaddr);
            }
        }
        elsif ($ref eq 'Sidef::Operator::Unary') {
            ## OK
        }
        elsif ($ref eq 'Sidef::Variable::Local') {
            $code = 'local ' . (defined($obj->{expr}) ? $self->deparse_args($obj->{expr}) : '()');
        }
        elsif ($ref eq 'Sidef::Variable::ClassVar') {
            $code = '$' . $self->_get_reftype($obj->{class}) . '::' . $obj->{name};
        }
        elsif ($ref eq 'Sidef::Variable::Define') {
            my $name  = $obj->{name} . $refaddr;
            my $value = '(' . $self->{environment_name} . '::' . $name . ')';

            if (not $addr{$refaddr}++) {
                $self->top_add('use constant ' . $name . '=>do{' . $self->_dump_static_var($obj, $refaddr) . '};');
            }
            $code = $value;
        }
        elsif ($ref eq 'Sidef::Variable::Const') {
            my $name = $obj->{name} . $refaddr;

            if ($addr{$refaddr}++) {
                $code = "\$$name\->()";
            }
            else {
                $code = $self->_dump_static_var($obj, $refaddr);
                $code = "my \$$name = sub { $code }; \$$name\->()";
            }
        }
        elsif ($ref eq 'Sidef::Variable::Static') {
            my $name  = $obj->{name} . $refaddr;
            my $value = "\$$name";

            if ($addr{$refaddr}++) {
                $code = $value;
            }
            else {
                $code = '(' . $self->_dump_static_var($obj, $refaddr) . ')';
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
                local $self->{inherit}          = $obj->{inherit};
                local $self->{class_vars}       = $obj->{vars};
                local $self->{class_attributes} = $obj->{attributes};
                local $self->{ref_class}        = ref($obj->{name}) ? 1 : 0;

                $code .= $self->deparse_expr({self => $block});
                $code .= ";'${package_name}'}";
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::BlockInit') {
            if ($addr{$refaddr}++) {
                $code = "(\$block$refaddr)";
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
                                             defined($self->{inherit})
                                             ? (
                                                join(' ', grep { $_ ne $class_name }
                                                       map { ref($_) ? $self->_get_reftype($_) : $_ } @{$self->{inherit}})
                                               )
                                             : ''
                                            )
                              . ($self->{ref_class} ? '' : ' Sidef::Object::Object');

                            if ($base_pkgs ne '') {
                                $code .= "use parent qw(-norequire $base_pkgs);";
                            }
                        }

                        if ($is_class and $self->{ref_class}) {
                            push @{$self->{function_declarations}}, [$refaddr, "", $self->{depth} // 0];
                        }

                        # TODO: find a simpler and more elegant solution
                        if ($is_class and not $self->{ref_class}) {

                            my @self_class_vars = @{$self->{class_vars}};
                            my @inherited_class_vars = (
                                                        defined($self->{inherit})
                                                        ? $self->_get_inherited_stuff($self->{inherit}, sub { exists($_[0]->{vars}) ? @{$_[0]->{vars}} : () })
                                                        : (),
                                                       );

                            my @self_class_attr = (defined($self->{class_attributes}) ? @{$self->{class_attributes}} : ());

                            my @inherited_class_attr = (
                                defined($self->{inherit})
                                ? $self->_get_inherited_stuff(
                                    $self->{inherit},
                                    sub {
                                        defined($_[0]->{attributes}) ? @{$_[0]->{attributes}} : ();
                                    }
                                  )
                                : ()
                            );

                            #~ @inherited_class_vars = ();
                            #~ @inherited_class_attr = ();

                            my %in_self;
                            foreach my $var (@self_class_vars) {
                                $in_self{$var->{name}} = 1;
                            }
                            foreach my $attr (@self_class_attr) {
                                foreach my $var (@{$attr->{vars}}) {
                                    $in_self{$var->{name}} = 1;
                                }
                            }

                            my @class_vars =
                              ((grep { !$in_self{$_->{name}} } @inherited_class_vars), @self_class_vars);
                            my @class_attr = (@inherited_class_attr, @self_class_attr);

                            $code .= "\$new$refaddr=Sidef::Types::Block::Block->new(code=>sub{";
                            push @{$self->{function_declarations}}, [$refaddr, "my \$new$refaddr;", $self->{depth} // 0];

                            $code .= $self->_dump_sub_init_vars(@class_vars) . $self->_dump_class_attributes(@class_attr);

                            my @class_var_attributes = do {
                                my %seen;
                                grep { !$seen{$_->{name}}++ } reverse

                                  ((map { @{$_->{vars}} } @inherited_class_attr), (map { @{$_->{vars}} } @self_class_attr));
                            };

                            $code .= 'my$self=bless{';
                            foreach my $var (
                                do {
                                    my %seen;
                                    grep { !$seen{$_->{name}}++ } (reverse(@class_vars), @class_var_attributes);
                                }
                              ) {
                                $code .= qq{"\Q$var->{name}\E"=>} . $self->_dump_var($var) . ', ';
                            }

                            $code .= '},__PACKAGE__;' . 'if(defined(my$sub=UNIVERSAL::can($self,"init"))){$sub->($self)}' . '$self;';

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
                        push @{$self->{function_declarations}}, [$refaddr, "my \$block$refaddr;", $self->{depth} // 0];
                        $code = "\$block$refaddr=" . 'Sidef::Types::Block::Block->new(';
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

                    local $self->{depth} = ($self->{depth} // 0) + 1;

                    my @statements = $self->deparse_script($obj->{code});

                    $code .= $self->localize_declarations($refaddr);

                    # Make the last statement to be the return value
                    if ($is_function && @statements) {
                        $statements[-1] = 'return do{' . $statements[-1] . '}';
                    }

                    $code .= join(';', @statements) . ($is_function ? (';' . "END$refaddr: \@return;") : '') . '}';

                    if (not $is_class) {
                        if ($is_function) {
                            $code .=
                              ',' . join(',', 'type=>' . $self->_dump_string($self->{parent_name}[0]), 'name=>' . $self->_dump_string($self->{parent_name}[1]));
                        }
                        else {
                            $code .= ',' . join(',', 'type=>' . $self->_dump_string('block'), 'name=>' . $self->_dump_string('__BLOCK__'),);
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
                $code = "'${name}'";
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
                  . "};'${name}'}";

                push @{$self->{function_declarations}}, [$refaddr, "my\$new$refaddr;", $self->{depth} // 0];
            }
        }
        elsif ($ref eq 'Sidef::Variable::Subset') {

            my $name = $self->_get_reftype($obj);

            if ($addr{$refaddr}++) {
                $code = "'${name}'";
            }
            else {

                my @parents;

                if (exists $obj->{inherits}) {
                    @parents = map { $self->_get_reftype($_) } @{$obj->{inherits}};
                }

                my $parents_check = '';

                if (@parents) {
                    $parents_check .= "foreach my \$class (qw(@parents)) {";
                    $parents_check .= "my \$code = UNIVERSAL::can(\$class, '__subset_validation__');";
                    $parents_check .= "(\$code ? \$code->(\@_) : 1) || return;";
                    $parents_check .= "};";
                }

                my $subset_block = '';

                if (exists($obj->{block})) {
                    my $block = $obj->{block};
                    $subset_block .= $self->_dump_sub_init_vars($block->{init_vars}{vars}[0]);
                    $subset_block .= $parents_check;
                    $subset_block .= $self->deparse_generic('', ';', '', $block->{code});
                }
                else {
                    $subset_block = "$parents_check; 1;";
                }

                $code =
                    "do{package $name {use parent qw(-norequire @parents);"
                  . "my \$sub = sub { $subset_block };"
                  . "do{ no strict 'refs'; *{__PACKAGE__ . '::' . '__subset_validation__'} = \$sub };"
                  . "};'${name}'}";
            }
        }
        elsif ($ref eq 'Sidef::Types::Number::Number') {
            my ($type, $content) = $obj->_dump;
            if ($type eq 'int') {
                $code =
                  ($constant_number_cache{$content} //= $self->make_constant($ref, '_set_int', "Number", args => ["'${content}'"], sub => 1));
            }
            else {
                $code = ($constant_number_cache{join(' ', $type, $content)} //=
                         $self->make_constant($ref, '_set_str', "Number", args => ["'${type}'", "'${content}'"], sub => 1));
            }
        }
        elsif ($ref eq 'Sidef::Types::String::String') {
            $code =
              ($constant_string_cache{$$obj} //= $self->make_constant($ref, 'new', "String", args => [$self->_dump_string($$obj)]));
        }
        elsif ($ref eq 'Sidef::Types::Array::Array' or $ref eq 'Sidef::Types::Array::HCArray') {
            $code = $self->_dump_array('Sidef::Types::Array::Array', $obj);
        }
        elsif ($ref eq 'Sidef::Types::Array::Vector') {
            $code = $self->_dump_array('Sidef::Types::Array::Vector', $obj);
        }
        elsif ($ref eq 'Sidef::Types::Array::Matrix') {
            $code = $self->_dump_array('Sidef::Types::Array::Matrix', $obj);
        }
        elsif ($ref eq 'Sidef::Types::Bool::Bool') {
            $code = 'Sidef::Types::Bool::Bool::' . (${$obj} ? 'TRUE' : 'FALSE');
        }
        elsif ($ref eq 'Sidef::Types::Regex::Regex') {
            $code =
              $self->make_constant($ref, 'new', "Regex",
                                   args => [$self->_dump_string("$obj->{raw}"), $self->_dump_string($obj->{flags} . ($obj->{global} ? 'g' : ''))]);
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

            # TODO: add support for slurpy parameters.
            # Example: while (expr) {|*arr| ... }

#<<<
            # Concept for the above TODO
            # However, this does not localize variables correctly to the body of the `while` loop.
            # For example: `scripts/Tests/dynamic_block_scoping.sf` will fail.
            #~ my $arg;
            #~ if (exists($obj->{block}{init_vars}) and @{$obj->{block}{init_vars}{vars}}) {
                #~ local $obj->{block}{init_vars}{args} = $obj->{expr};
                #~ $arg = $self->_dump_init_vars($obj->{block}{init_vars});
            #~ }
            #~ else {
                #~ $arg = $self->deparse_args($obj->{expr});
            #~ }
#>>>

            my $vars = join(',', map { $self->_dump_var($_) } @{$obj->{block}{init_vars}{vars}});
            my $arg  = $self->deparse_args($obj->{expr});

            if ($vars) {
                $arg = "(my ($vars) = $arg)[-1]";
            }

            $code = 'while(' . $arg . ')' . $self->deparse_block_with_scope($obj->{block});
        }
        elsif ($ref eq 'Sidef::Types::Block::ForEach') {
            $code = $self->deparse_args($obj->{expr}) . '->each' . '(' . $self->deparse_expr({self => $obj->{block}}) . ')';
        }
        elsif ($ref eq 'Sidef::Types::Block::CFor') {
            $code = 'for(' . join(';', map { $self->deparse_args($_) } @{$obj->{expr}}) . ')' . $self->deparse_block_with_scope($obj->{block});
        }
        elsif ($ref eq 'Sidef::Types::Block::ForIn') {
            $self->load_mod('Sidef::Types::Block::Block');

            my @vars  = map { $self->_dump_sub_init_vars(@{$_->{vars}}) } @{$obj->{loops}};
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
                  . ($multi ? 'local @_ = @{$_[0]->to_a};' : '')
                  . "$vars; $code }, $expr)"
                  . (@loops ? ' // last' : '');
            }
        }
        elsif ($ref eq 'Sidef::Types::Bool::Ternary') {
            $code = '(' . $self->deparse_script($obj->{cond}) . '?' . $self->deparse_args($obj->{true}) . ':' . $self->deparse_args($obj->{false}) . ')';
        }
        elsif ($ref eq 'Sidef::Variable::NamedParam') {
            $code = $ref . '->new(' . $self->_dump_string($obj->{name}) . ', ' . $self->deparse_args(@{$obj->{value}}) . ')';
        }
        elsif ($ref eq 'Sidef::Types::Nil::Nil') {
            $code = 'undef';
        }
        elsif ($ref eq 'Sidef::Types::Hash::Hash') {
            $self->load_mod($ref);
            $code = 'bless({'
              . join(',',
                     map { $self->_dump_string($_) . '=>' . (defined($obj->{$_}) ? $self->deparse_expr({self => $obj->{$_}}) : 'undef') } sort(keys(%{$obj})))
              . "}, '${ref}')";
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
            my $arg  = $self->deparse_args($obj->{expr});

            if ($vars) {
                $arg = "(my ($vars) = $arg)[-1]";
            }

            $code =
                "if (\$continue) {my \$t = $arg;"
              . "if (defined(\$given_value) ? defined(\$t) ? Sidef::Object::Object::smartmatch(\$given_value, \$t) : 0 : 1) {"
              . "\$continue = 0; \@given_values = do"
              . $self->deparse_block_with_scope($obj->{block}) . "}};";
        }
        elsif ($ref eq 'Sidef::Types::Block::Case') {
            my $vars = join(',', map { $self->_dump_var($_) } @{$obj->{block}{init_vars}{vars}});
            my $arg  = $self->deparse_args($obj->{expr});

            if ($vars) {
                $arg = "(my ($vars) = $arg)[-1]";
            }

            $code = "if (\$continue and $arg) { \$continue = 0;" . "\@given_values = do" . $self->deparse_block_with_scope($obj->{block}) . '}';
        }
        elsif ($ref eq 'Sidef::Types::Block::Default') {
            $code = "if (\$continue) { \$continue = 0; \@given_values = do" . $self->deparse_block_with_scope($obj->{block}) . '}';
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
                $code .= "(defined((my ($vars) = do{" . $self->deparse_args($info->{expr}) . '})[-1]))' . $self->deparse_block_with_scope($info->{block});
            }
            if (exists $obj->{else}) {
                $code .= 'else' . $self->deparse_block_with_scope($obj->{else}{block});
            }
            $code .= '}';
        }
        elsif ($ref eq 'Sidef::Types::Block::Gather') {
            $self->load_mod("Sidef::Types::Array::Array");
            $code = "do{my \@_$refaddr;" . 'do' . $self->deparse_block_with_scope($obj->{block}) . "; bless(\\\@_$refaddr, 'Sidef::Types::Array::Array')}";
        }
        elsif ($ref eq 'Sidef::Types::Block::Take') {
            my $raddr = refaddr($obj->{gather});
            $code = "do{ push \@_$raddr," . $self->deparse_args($obj->{expr}) . "; \$_$raddr\[-1] }";
        }
        elsif ($ref eq 'Sidef::Types::Block::Try') {
            $code =
                $ref
              . '->new->try('
              . $self->deparse_expr({self => $obj->{try}})
              . ')->catch('
              . (defined($obj->{catch}) ? $self->deparse_expr({self => $obj->{catch}}) : '') . ')';
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
        elsif ($ref eq 'Sidef::Meta::Glob::STDIN') {
            $code = $self->make_constant('Sidef::Types::Glob::FileHandle', 'new', "STDIN", args => ['\*STDIN']);
        }
        elsif ($ref eq 'Sidef::Meta::Glob::STDOUT') {
            $code = $self->make_constant('Sidef::Types::Glob::FileHandle', 'new', "STDOUT", args => ['\*STDOUT']);
        }
        elsif ($ref eq 'Sidef::Meta::Glob::STDERR') {
            $code = $self->make_constant('Sidef::Types::Glob::FileHandle', 'new', "STDERR", args => ['\*STDERR']);
        }
        elsif ($ref eq 'Sidef::Meta::Glob::ARGF') {
            $code = $self->make_constant('Sidef::Types::Glob::FileHandle', 'new', "ARGF", args => ['\*ARGV']);
        }
        elsif ($ref eq 'Sidef::Meta::Glob::DATA') {
            require Encode;
            my $data = $self->_dump_string(Encode::encode_utf8(${$obj->{data}}));
            $code = $self->make_constant('Sidef::Types::Glob::FileHandle', 'new', "DATA", args => [qq{do{open my \$fh, '<:utf8', \\$data; \$fh}}]);
        }
        elsif ($ref eq 'Sidef::Variable::Magic') {
            $code = $obj->{name};
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
                local \@{\$Sidef::PARSER}{keys \%{\$Sidef::EVALS{$refaddr}{parser}}} = values \%{\$Sidef::EVALS{$refaddr}{parser}};
                local \$Sidef::PARSER->{line} = 1;
                local \$Sidef::PARSER->{eval_mode} = 1;
                local \$Sidef::PARSER->{file_name} = 'eval($refaddr)';
                #local \$Sidef::PARSER->{vars} = \$Sidef::EVALS{$refaddr}{vars};
                #local \$Sidef::PARSER->{ref_vars_refs} = \$Sidef::EVALS{$refaddr}{ref_vars_refs};
                \$Sidef::PARSER->parse_script(code => do{my\$o=~ . $self->deparse_args($obj->{expr}) . qq~;\\"\$o"});
            })}~;
        }
        elsif ($ref eq 'Sidef::Types::Number::Complex') {
            my ($real, $imag) = $obj->reals;
            my $name = "Complex$refaddr";
            $self->top_add("use constant $name => $ref\->new(" . join(',', $self->deparse_expr({self => $real}), $self->deparse_expr({self => $imag})) . ');');
            $code = "($self->{environment_name}\::$name)";
        }
        elsif ($ref eq 'Sidef::Types::Array::Pair') {
            $code =
              $ref . '->new(' . join(',', map { defined($_) ? $self->deparse_expr({self => $_}) : 'undef' } @{$obj}) . ')';
        }
        elsif ($ref eq 'Sidef::Types::Null::Null') {
            $code = $self->make_constant($ref, 'new', "Null", args => []);
        }
        elsif ($ref eq 'Sidef::Module::OO') {
            $code = $self->make_constant($ref, '__NEW__', "ModuleOO", args => [$self->_dump_string($obj->{module})]);
        }
        elsif ($ref eq 'Sidef::Module::Func') {
            $code = $self->make_constant($ref, '__NEW__', "ModuleFunc", args => [$self->_dump_string($obj->{module})]);
        }
        elsif ($ref eq 'Sidef::Types::Perl::Perl') {
            $code = $self->make_constant($ref, 'new', "PerlCode", args => [$self->_dump_string(${$obj})]);
        }
        elsif (exists($composite_constants{$ref})) {
            my $data = $composite_constants{$ref};
            $code = $self->make_constant(
                                         $ref, 'new',
                                         $data->{name},
                                         new  => 1,
                                         args => [map { $self->deparse_expr({self => $obj->{$_}}) } @{$data->{fields}}]
                                        );
        }
        elsif ($ref eq 'Sidef::Types::Glob::Backtick') {
            $code = $self->make_constant($ref, 'new', "Backtick", args => [$self->_dump_string(${$obj})]);
        }
        elsif ($ref eq 'Sidef::Types::Glob::File') {
            $code = $self->make_constant($ref, 'new', "File", args => [$self->_dump_string(${$obj})]);
        }
        elsif ($ref eq 'Sidef::Types::Glob::Dir') {
            $code = $self->make_constant($ref, 'new', "Dir", args => [$self->_dump_string(${$obj})]);
        }
        elsif ($ref eq 'Sidef::Meta::Module') {
            ## local $self->{depth} = -999_999_999;
            $code = substr($self->deparse_bare_block($obj->{block}{code}), 1, -1);
        }
        elsif ($ref eq 'Sidef::Meta::Included') {
            foreach my $info (@{$obj->{included}}) {
                $code .= join(';', $self->deparse_script($info->{ast})) . ';';
            }
        }
        elsif ($ref eq 'Sidef::Meta::Assert') {
            my @args = $self->deparse_script($obj->{arg});

            if ($obj->{act} eq 'assert') {

                # Check arity
                @args > 2
                  and die "[ERROR] Incorrect number of arguments for $obj->{act}\() at" . " $obj->{file} line $obj->{line} (expected 1 or 2 arguments)\n";

                my $msg = $args[1] // 'undef';

                # Generate code
                $code =
                    qq~do{my \$a$refaddr = do{$args[0]}; ~
                  . qq~\$a$refaddr or CORE::die((do{$msg} // "$obj->{act}(\$a$refaddr)") . " failed ~
                  . qq~at \Q$obj->{file}\E line $obj->{line}\\n")}~;
            }
            elsif ($obj->{act} eq 'assert_eq' or $obj->{act} eq 'assert_ne') {

                # Check arity
                @args > 3
                  and die "[ERROR] Incorrect number of arguments for $obj->{act}\() at" . " $obj->{file} line $obj->{line} (expected 2 or 3 arguments)\n";

                # Generate code
                $code = "do{"
                  . "my \$a$refaddr = do{$args[0]};"
                  . "my \$b$refaddr = do{$args[1]};"
                  . ($obj->{act} eq 'assert_ne' ? qq{!(\$a$refaddr eq \$b$refaddr)} : qq{\$a$refaddr eq \$b$refaddr})
                  . qq~ or CORE::die((~
                  . (defined($args[2]) ? "do{$args[2]}" : "undef")
                  . qq~// ('$obj->{act}('.~
                  . qq~join(', ',map{(ref(\$_) && UNIVERSAL::can(\$_,'dump')) ? \$_->dump : \$_}(\$a$refaddr, \$b$refaddr)) . ')'))~
                  . qq~." failed at \Q$obj->{file}\E line $obj->{line}\\n")}~;
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
            $code = $self->make_constant($ref, 'new', "Pipe", args => [map { $self->_dump_string($_) } @{$obj}]);
        }
        elsif ($ref eq 'Sidef::Parser') {
            $code = '$Sidef::PARSER';
        }
        elsif ($ref eq 'Sidef::Meta::Unimplemented') {
            $code = qq{CORE::die "Unimplemented at " . } . $self->_dump_string($obj->{file}) . qq{. " line $obj->{line}\\n"};
        }
        elsif ($ref eq 'Sidef::Variable::Label') {
            $code = $obj->{name} . ': ';
        }
        elsif (exists $self->{data_types}{$ref}) {
            my $mod = $self->{data_types}{$ref};
            $self->{_reftype_cache}{$mod} //= do {
                $self->load_mod($mod);
                1;
            };
            $code = "'" . $mod . "'";
        }
        elsif ($ref eq 'Sidef::Perl::Builtin') {
            ## ok
        }
        else {
            die "[PERL DEPARSER BUG] Unknown object of type <<$ref>>";
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
                        $code = "\@{($code)}{$keys}";
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
                    (
                     $ref eq 'Sidef::DataTypes::Hash::Hash' and $i == 0 and (   $method eq 'call'
                                                                             or $method eq 'new')
                    )
                    or ($ref eq 'Sidef::Meta::PrefixColon' and $method eq ':')
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

                    if ($ref eq 'Sidef::Variable::Ref') {    # variables

                        # Variable referencing
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
                        $code .= $self->{lazy_ops}{$method} . $self->deparse_args(@{$call->{arg}});
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
                          . ';ref($bool) ? $bool : ($bool ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE)}'
                          . ($method eq '!=' ? '->not' : '');
                        next;
                    }

                    # !~ and ~~ methods
                    if ($method eq '~~' or $method eq '!~') {
                        $self->top_add(q{no warnings 'experimental::smartmatch';});
                        $code =
                            'do{my$bool=Sidef::Object::Object::smartmatch(do{'
                          . $code
                          . '}, do{'
                          . $self->deparse_args(@{$call->{arg}})
                          . '});ref($bool) ? $bool : ($bool ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE)}'
                          . ($method eq '!~' ? '->not' : '');
                        next;
                    }

                    # <=> method
                    if ($method eq '<=>') {
                        $code =
                            'do{my$cmp='
                          . $code . 'cmp'
                          . $self->deparse_args(@{$call->{arg}})
                          . ';ref($cmp) ? $cmp : defined($cmp) ? (($cmp<0) ? Sidef::Types::Number::Number::MONE : '
                          . '($cmp>0) ? Sidef::Types::Number::Number::ONE : Sidef::Types::Number::Number::ZERO) : undef}';
                        next;
                    }

                    # Unary prefix operator
                    if ($ref eq 'Sidef::Operator::Unary' and !$unary) {

                        $unary = 1;    # once per call

                        if ($method eq '!') {
                            $code = '(' . $self->deparse_args(@{$call->{arg}}) . '? Sidef::Types::Bool::Bool::FALSE : Sidef::Types::Bool::Bool::TRUE)';
                            next;
                        }

                        if ($method eq '-') {

                            # Constant-folding: negate the literal number
                            my $data = $call->{arg};
                            if (scalar(@$data) == 1 and ref($data->[0]) eq 'HASH' and scalar(keys %{$data->[0]}) == 1) {
                                $data = $data->[0];
                                my ($class) = keys(%$data);
                                $data = $data->{$class};
                                if (ref($data) eq 'ARRAY' and scalar(@$data) == 1) {
                                    $data = $data->[0];
                                    if (ref($data) eq 'HASH' and scalar(keys %$data) == 1 and exists($data->{self})) {
                                        $data = $data->{self};
                                    }
                                    if (ref($data) eq 'Sidef::Types::Number::Number') {
                                        $code = $self->deparse_expr({self => $data->neg});
                                        next;
                                    }
                                }
                            }

                            $code = $self->deparse_args(@{$call->{arg}}) . '->neg';
                            next;
                        }

                        if ($method eq '+') {
                            $code = 'scalar' . $self->deparse_args(@{$call->{arg}});
                            next;
                        }

                        if ($method eq '@') {
                            $self->load_mod('Sidef::Types::Array::Array');
                            $code =
                                '(do{my$obj='
                              . $self->deparse_args(@{$call->{arg}})
                              . ';my$sub=ref($obj) && UNIVERSAL::can($obj, "to_a"); '
                              . '$sub ? $sub->($obj) : bless([$obj], "Sidef::Types::Array::Array")})';
                            next;
                        }

                        if ($method eq '@|') {
                            $code =
                                '(do{my$obj='
                              . $self->deparse_args(@{$call->{arg}})
                              . ';my$sub=ref($obj) && UNIVERSAL::can($obj, "..."); '
                              . '$sub ? $sub->($obj) : $obj })';
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
                              '((CORE::say' . $self->deparse_args(@{$call->{arg}}) . ') ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE)';
                            next;
                        }

                        if ($method eq 'print' or $method eq '>>') {
                            $code =
                              '((CORE::print' . $self->deparse_args(@{$call->{arg}}) . ') ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE)';
                            next;
                        }

                        if ($method eq 'defined') {
                            $code =
                                '((CORE::defined'
                              . $self->deparse_args(@{$call->{arg}})
                              . ') ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE)';
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

                    if ($call->{keyword} eq 'if') {
                        $code = $self->deparse_args(@{$call->{arg}}) . '&&' . $code;
                        next;
                    }

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

        foreach my $class (keys %$struct) {

            my $max = $#{$struct->{$class}};
            foreach my $i (0 .. $max) {
                my $expr = $struct->{$class}[$i];
                push @results, ref($expr) eq 'HASH' ? $self->deparse_expr($expr) : $self->deparse_expr({self => $expr});
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
              exists($self->{function_declarations}) && @{$self->{function_declarations}} ? join('', map { $_->[1] } @{$self->{function_declarations}})
              : ''
             )
           . (
              exists($self->{block_declarations}) && @{$self->{block_declarations}} ? join('', map { $_->[1] } @{$self->{block_declarations}})
              : ''
             )
           . $self->{top_program}
           . join($self->{between}, @statements)
           . $self->{after}
        ) =~ s/^\s*/$self->{header}/r;
    }
}

1;
