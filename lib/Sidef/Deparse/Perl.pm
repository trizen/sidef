package Sidef::Deparse::Perl {

    use utf8;
    use 5.016;

    use Scalar::Util qw(refaddr);
    use Sidef::Types::Number::Number;

    #----------------------------------------------------------------------
    # Configuration & Defaults
    #----------------------------------------------------------------------

    my %addr;
    my %top_add;

    my %constant_number_cache;
    my %constant_string_cache;

    # Move static configuration out of 'new'
    my %DEFAULT_OPTS = (
                        before           => '',
                        header           => '',
                        top_program      => '',
                        between          => ';',
                        after            => ';',
                        opt              => {},
                        environment_name => 'main',
                       );

    my %ASSIGNMENT_OPS = ('=' => '=',);

    my %LAZY_OPS = (
                    '?'     => '?',
                    '||'    => '||',
                    '&&'    => '&&',
                    ':='    => '//=',
                    '||='   => '||=',
                    '&&='   => '&&=',
                    '\\\\'  => '//',
                    '\\\\=' => '//=',
                   );

    my %OVERLOAD_METHODS = (
                            '=='  => 'eq',
                            '<=>' => 'cmp',
                           );

    my %REASSIGN_OPS = map { ("$_=", $_) } qw(+ - % * // / & | ^ ** && || << >> ÷);

    my %INC_DEC_OPS = (
                       '++' => 'inc',
                       '--' => 'dec',
                      );

    my %COMPOSITE_CONSTANTS = (
        'Sidef::Types::Range::RangeNumber' => {name => 'RangeNum',   fields => [qw(from to step)]},
        'Sidef::Types::Range::RangeString' => {name => 'RangeStr',   fields => [qw(from to step)]},
        'Sidef::Types::Number::Gauss'      => {name => 'Gauss',      fields => [qw(a b)]},
        'Sidef::Types::Number::Quadratic'  => {name => 'Quadratic',  fields => [qw(a b w)]},
        'Sidef::Types::Number::Quaternion' => {name => 'Quaternion', fields => [qw(a b c d)]},
        'Sidef::Types::Number::Fraction'   => {name => 'Fraction',   fields => [qw(a b)]},
        'Sidef::Types::Number::Mod'        => {name => 'Mod',        fields => [qw(n m)]},
                              );

    my %DATA_TYPES = (
                      'Sidef::DataTypes::Bool::Bool'            => 'Sidef::Types::Bool::Bool',
                      'Sidef::DataTypes::Array::Array'          => 'Sidef::Types::Array::Array',
                      'Sidef::DataTypes::Array::Pair'           => 'Sidef::Types::Array::Pair',
                      'Sidef::DataTypes::Array::Vector'         => 'Sidef::Types::Array::Vector',
                      'Sidef::DataTypes::Array::Matrix'         => 'Sidef::Types::Array::Matrix',
                      'Sidef::DataTypes::Hash::Hash'            => 'Sidef::Types::Hash::Hash',
                      'Sidef::DataTypes::Set::Set'              => 'Sidef::Types::Set::Set',
                      'Sidef::DataTypes::Set::Bag'              => 'Sidef::Types::Set::Bag',
                      'Sidef::DataTypes::Regex::Regex'          => 'Sidef::Types::Regex::Regex',
                      'Sidef::DataTypes::String::String'        => 'Sidef::Types::String::String',
                      'Sidef::DataTypes::Number::Number'        => 'Sidef::Types::Number::Number',
                      'Sidef::DataTypes::Number::Mod'           => 'Sidef::Types::Number::Mod',
                      'Sidef::DataTypes::Number::Gauss'         => 'Sidef::Types::Number::Gauss',
                      'Sidef::DataTypes::Number::Quadratic'     => 'Sidef::Types::Number::Quadratic',
                      'Sidef::DataTypes::Number::Quaternion'    => 'Sidef::Types::Number::Quaternion',
                      'Sidef::DataTypes::Number::Complex'       => 'Sidef::Types::Number::Complex',
                      'Sidef::DataTypes::Number::Polynomial'    => 'Sidef::Types::Number::Polynomial',
                      'Sidef::DataTypes::Number::PolynomialMod' => 'Sidef::Types::Number::PolynomialMod',
                      'Sidef::DataTypes::Number::Fraction'      => 'Sidef::Types::Number::Fraction',
                      'Sidef::DataTypes::Range::Range'          => 'Sidef::Types::Range::Range',
                      'Sidef::DataTypes::Range::RangeNumber'    => 'Sidef::Types::Range::RangeNumber',
                      'Sidef::DataTypes::Range::RangeString'    => 'Sidef::Types::Range::RangeString',
                      'Sidef::DataTypes::Block::Block'          => 'Sidef::Types::Block::Block',
                      'Sidef::DataTypes::Glob::Socket'          => 'Sidef::Types::Glob::Socket',
                      'Sidef::DataTypes::Glob::Pipe'            => 'Sidef::Types::Glob::Pipe',
                      'Sidef::DataTypes::Glob::Backtick'        => 'Sidef::Types::Glob::Backtick',
                      'Sidef::DataTypes::Glob::DirHandle'       => 'Sidef::Types::Glob::DirHandle',
                      'Sidef::DataTypes::Glob::FileHandle'      => 'Sidef::Types::Glob::FileHandle',
                      'Sidef::DataTypes::Glob::SocketHandle'    => 'Sidef::Types::Glob::SocketHandle',
                      'Sidef::DataTypes::Glob::Dir'             => 'Sidef::Types::Glob::Dir',
                      'Sidef::DataTypes::Glob::File'            => 'Sidef::Types::Glob::File',
                      'Sidef::DataTypes::Perl::Perl'            => 'Sidef::Types::Perl::Perl',
                      'Sidef::DataTypes::Object::Object'        => 'Sidef::Object::Object',
                      'Sidef::DataTypes::Sidef::Sidef'          => 'Sidef',
                      'Sidef::DataTypes::Object::Lazy'          => 'Sidef::Object::Lazy',
                      'Sidef::DataTypes::Object::LazyMethod'    => 'Sidef::Object::LazyMethod',
                      'Sidef::DataTypes::Object::Enumerator'    => 'Sidef::Object::Enumerator',
                      'Sidef::DataTypes::Variable::NamedParam'  => 'Sidef::Variable::NamedParam',
                      'Sidef::Meta::PrefixColon'                => 'Sidef::Types::Hash::Hash',
                      'Sidef::Sys::Sig'                         => 'Sidef::Sys::Sig',
                      'Sidef::Sys::Sys'                         => 'Sidef::Sys::Sys',
                      'Sidef::Math::Math'                       => 'Sidef::Math::Math',
                      'Sidef::Time::Time'                       => 'Sidef::Time::Time',
                      'Sidef::Time::Date'                       => 'Sidef::Time::Date',
                     );

    # Dispatch table mapping ref types to method names
    my %handlers = (
                    'Sidef::Variable::Variable'      => '_deparse_variable',
                    'Sidef::Operator::Unary'         => '_deparse_unary_ok',
                    'Sidef::Variable::Local'         => '_deparse_local',
                    'Sidef::Variable::ClassVar'      => '_deparse_class_var',
                    'Sidef::Variable::Define'        => '_deparse_define',
                    'Sidef::Variable::Const'         => '_deparse_const',
                    'Sidef::Variable::Static'        => '_deparse_static',
                    'Sidef::Variable::ConstInit'     => '_deparse_const_init',
                    'Sidef::Variable::Init'          => '_deparse_init',
                    'Sidef::Variable::ClassInit'     => '_deparse_class_init',
                    'Sidef::Types::Block::BlockInit' => '_deparse_block_init',
                    'Sidef::Variable::ClassAttr'     => '_deparse_class_attr_ok',
                    'Sidef::Variable::Struct'        => '_deparse_struct',
                    'Sidef::Variable::Subset'        => '_deparse_subset',
                    'Sidef::Types::Number::Number'   => '_deparse_number',
                    'Sidef::Types::String::String'   => '_deparse_string',
                    'Sidef::Types::Array::Array'     => '_deparse_array',
                    'Sidef::Types::Array::HCArray'   => '_deparse_array',
                    'Sidef::Types::Array::Vector'    => '_deparse_vector',
                    'Sidef::Types::Array::Matrix'    => '_deparse_matrix',
                    'Sidef::Types::Bool::Bool'       => '_deparse_bool',
                    'Sidef::Types::Regex::Regex'     => '_deparse_regex',
                    'Sidef::Types::Block::If'        => '_deparse_if',
                    'Sidef::Types::Block::While'     => '_deparse_while',
                    'Sidef::Types::Block::ForEach'   => '_deparse_foreach',
                    'Sidef::Types::Block::CFor'      => '_deparse_cfor',
                    'Sidef::Types::Block::ForIn'     => '_deparse_forin',
                    'Sidef::Types::Bool::Ternary'    => '_deparse_ternary',
                    'Sidef::Variable::NamedParam'    => '_deparse_named_param',
                    'Sidef::Types::Nil::Nil'         => '_deparse_nil',
                    'Sidef::Types::Hash::Hash'       => '_deparse_hash',
                    'Sidef::Meta::PrefixMethod'      => '_deparse_prefix_method',
                    'Sidef::Types::Block::Do'        => '_deparse_do',
                    'Sidef::Types::Block::Loop'      => '_deparse_loop',
                    'Sidef::Types::Block::Given'     => '_deparse_given',
                    'Sidef::Types::Block::When'      => '_deparse_when',
                    'Sidef::Types::Block::Case'      => '_deparse_case',
                    'Sidef::Types::Block::Default'   => '_deparse_default',
                    'Sidef::Types::Block::Continue'  => '_deparse_continue',
                    'Sidef::Types::Block::With'      => '_deparse_with',
                    'Sidef::Types::Block::Gather'    => '_deparse_gather',
                    'Sidef::Types::Block::Take'      => '_deparse_take',
                    'Sidef::Types::Block::Try'       => '_deparse_try',
                    'Sidef::Variable::Ref'           => '_deparse_ref_ok',
                    'Sidef::Types::Block::Break'     => '_deparse_break',
                    'Sidef::Types::Block::Next'      => '_deparse_next',
                    'Sidef::Types::Block::Return'    => '_deparse_return',
                    'Sidef::Meta::Glob::STDIN'       => '_deparse_stdin',
                    'Sidef::Meta::Glob::STDOUT'      => '_deparse_stdout',
                    'Sidef::Meta::Glob::STDERR'      => '_deparse_stderr',
                    'Sidef::Meta::Glob::ARGF'        => '_deparse_argf',
                    'Sidef::Meta::Glob::DATA'        => '_deparse_data',
                    'Sidef::Variable::Magic'         => '_deparse_magic',
                    'Sidef::Eval::Eval'              => '_deparse_eval',
                    'Sidef::Types::Number::Complex'  => '_deparse_complex',
                    'Sidef::Types::Array::Pair'      => '_deparse_pair',
                    'Sidef::Types::Null::Null'       => '_deparse_null',
                    'Sidef::Module::OO'              => '_deparse_module_oo',
                    'Sidef::Module::Func'            => '_deparse_module_func',
                    'Sidef::Types::Perl::Perl'       => '_deparse_perl_code',
                    'Sidef::Types::Glob::Backtick'   => '_deparse_backtick',
                    'Sidef::Types::Glob::File'       => '_deparse_file',
                    'Sidef::Types::Glob::Dir'        => '_deparse_dir',
                    'Sidef::Meta::Module'            => '_deparse_meta_module',
                    'Sidef::Meta::Included'          => '_deparse_included',
                    'Sidef::Meta::Assert'            => '_deparse_assert',
                    'Sidef::Meta::Error'             => '_deparse_error',
                    'Sidef::Meta::Warning'           => '_deparse_warning',
                    'Sidef::Types::Glob::Pipe'       => '_deparse_pipe',
                    'Sidef::Parser'                  => '_deparse_parser',
                    'Sidef::Meta::Unimplemented'     => '_deparse_unimplemented',
                    'Sidef::Variable::Label'         => '_deparse_label',
                    'Sidef::Perl::Builtin'           => '_deparse_builtin',
                   );

    sub new {
        my (undef, %args) = @_;

        # Merge defaults with args
        my %opts = (%DEFAULT_OPTS, %args);

        # Assign pointers to static config maps (for back-compat if $self uses them)
        $opts{assignment_ops}   = \%ASSIGNMENT_OPS;
        $opts{lazy_ops}         = \%LAZY_OPS;
        $opts{overload_methods} = \%OVERLOAD_METHODS;
        $opts{data_types}       = \%DATA_TYPES;
        $opts{reassign_ops}     = \%REASSIGN_OPS;
        $opts{inc_dec_ops}      = \%INC_DEC_OPS;

        $opts{header} .= <<"HEADER";

use utf8;
use strict;
use feature qw(state unicode_strings unicode_eval evalbytes);
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
            my %modes = (
                         'zero'  => 1,
                         '+inf'  => 2,
                         '-inf'  => 3,
                         'inf'   => 4,
                         'faith' => 5,
                        );
            $round = $modes{$round} // 0;
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

        if (exists $DATA_TYPES{$ref}) {
            my $target = $DATA_TYPES{$ref};

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
            $str =~ s/([\\\"\@\$])/\\$1/g;
            return qq("$str") if ($str !~ /[^\040-\176]/);    # fast exit

            $str =~ s/([\a\b\t\n\f\r\e])/$esc{$1}/g;
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
          . $var->{name}
          . ($var->{type} eq 'global' ? '' : ($opt{refaddr} // refaddr($var)));
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
                if (exists $var->{value}) {
                    push @code, ('@' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not \@$name;");
                }
                $self->load_mod('Sidef::Types::Array::Array');
                push @code, "\$$name = bless(\\\@$name, 'Sidef::Types::Array::Array');";
            }
            elsif (exists $var->{hash}) {
                push @{$self->{block_declarations}}, [$self->{current_block} // -1, $decl . '%' . $name . ';'];
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

        if (@code > 1 or exists($init_obj->{args})) {
            push @code, '(' . join(',', map { $self->_dump_var($_) } @vars) . ')';
            return 'CORE::sub:lvalue{' . join(';', @code) . '}->()';
        }

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
                    if (exists $var->{value}) {
                        push @code, ('@' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not \@$name;");
                    }
                    $self->load_mod('Sidef::Types::Array::Array');
                    push @code, "my \$$name = bless(\\\@$name, 'Sidef::Types::Array::Array');";
                }
                elsif (exists $var->{hash}) {
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
                if (exists $var->{value}) {
                    $code .= ('@' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not \@$name;");
                }
                $self->load_mod('Sidef::Types::Array::Array');
                $code .= "my \$$name = bless(\\\@$name, 'Sidef::Types::Array::Array');";
            }
            elsif (exists $var->{hash}) {
                my $name = $var->{name} . refaddr($var);
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
        'bless([' . join(',', grep { $_ ne '' } map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}) } @{$array}) . "], '${ref}')";
    }

    sub _dump_indices {
        my ($self, $array) = @_;

        my @indices;

        foreach my $entry (@{$array}) {
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
            ) . "}";
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

    #----------------------------------------------------------------------
    # Handler Methods (Extracted from old massive if/else)
    #----------------------------------------------------------------------

    sub _deparse_variable {
        my ($self, $obj, $refaddr) = @_;
        my $code = '';

        if ($obj->{type} eq 'func' or $obj->{type} eq 'method') {

            if ($obj->{name} eq '') {
                $obj->{name} = "__FUNC__";
            }

            my $name      = $obj->{name};
            my $alphaname = $obj->{name};

            local $obj->{type} = 'func' if exists($obj->{parent});

            if (not $obj->{name} =~ /^[^\W\d]\w*+\z/) {
                $alphaname = '__NONANN__';
            }

            if ($addr{$refaddr}++) {
                $code = "\$$alphaname$refaddr";
            }
            else {
                my $block = $obj->{value};
                $code .= "\$${alphaname}$refaddr";

                {
                    local $self->{function}          = refaddr($block);
                    local $self->{parent_name}       = [$obj->{type}, $name];
                    local $self->{current_namespace} = $obj->{class};

                    push @{$self->{function_declarations}}, [$self->{function}, "my \$${alphaname}$refaddr;", ($self->{opt}{i} ? 1 : ($self->{depth} // 0))];

                    if ($self->{ref_class} and !exists($obj->{parent})) {
                        push @{$self->{function_declarations}},
                          [ $self->{function},
                            qq{state \$${alphaname}_code$refaddr = UNIVERSAL::can("\Q$self->{class_name}\E", "\Q$name\E");},
                            $self->{depth} // 0
                          ];
                    }
                    if ((my $content = $self->deparse_expr({self => $block})) ne '') {
                        $code .= "=$content";
                    }
                }

                if (exists $obj->{parent}) {
                    my $name = $self->deparse_expr({self => $obj->{parent}});
                    $code = "do{CORE::push(\@{" . $name . "->{kids} //= []}, do{$code});$name}";
                }
                elsif ($self->{ref_class}) {
                    chop $code;
                    $code .=
                      qq{,(defined(\$${alphaname}_code$refaddr)?(fallback=>} . qq{Sidef::Types::Block::Block->new(code=>\$${alphaname}_code$refaddr)):()))};
                }

                if (exists $obj->{returns}) {
                    my $types = '[' . join(',', map { $self->_dump_reftype($_) } @{$obj->{returns}}) . ']';
                    $code = "do{$code;\$${alphaname}$refaddr\->{returns}=$types;\$${alphaname}$refaddr}";
                }

                if ($obj->{cached}) {
                    $code = "do{$code;" . "\$${alphaname}$refaddr\->cache;\$${alphaname}$refaddr}";
                }

                if ($obj->{type} eq 'func' and !$obj->{parent}) {
                    if (${alphaname} eq 'MAIN') {
                        $self->top_add('require Encode;');
                        $self->{after} .= "Sidef::Variable::GetOpt->new([map{Encode::decode_utf8(\$_)}\@ARGV],\$${alphaname}$refaddr);";
                    }
                }
                elsif ($obj->{type} eq 'method') {
                    if (${alphaname} eq 'AUTOLOAD') {
                        $code .= ';'
                          . "our\$AUTOLOAD;"
                          . "sub ${alphaname} {my\$self=shift;"
                          . "my(\$class,\$method)=(\$AUTOLOAD=~/^(.*[^:])::(.*)\$/);"
                          . "\$${alphaname}$refaddr->call(\$self,Sidef::Types::String::String->new(\$class),Sidef::Types::String::String->new(\$method),\@_)}";
                    }
                    elsif (${alphaname} eq '__FUNC__') {

                        # Anonymous
                    }
                    else {
                        $code .= ";"
                          . "state\$_$refaddr=do{no strict 'refs';"
                          . "\$$self->{package_name}::__SIDEF_CLASS_METHODS__{'${name}'} = \$${alphaname}$refaddr;" . '*{'
                          . $self->_dump_string("$self->{package_name}::$name")
                          . "}=sub{\$${alphaname}$refaddr->call(\@_)}}";
                    }

                    if (exists $OVERLOAD_METHODS{$name}) {
                        my $overload_name = $OVERLOAD_METHODS{$name};
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
                $self->top_add(qq{my \$$name = Sidef::Types::Hash::Hash->new} . qq{(map{Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \%ENV);});
            }
            elsif ($obj->{name} eq 'ARGV') {
                $self->top_add("require Encode;");
                $self->top_add(
                          qq{my \$$name = Sidef::Types::Array::Array->new} . qq{([map {Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \@ARGV]);});
            }

            $code = $self->_dump_var($obj, refaddr => $refaddr);
        }
        return $code;
    }

    sub _deparse_local {
        my ($self, $obj) = @_;
        'local ' . (defined($obj->{expr}) ? $self->deparse_args($obj->{expr}) : '()');
    }

    sub _deparse_class_var {
        my ($self, $obj) = @_;
        '$' . $self->_get_reftype($obj->{class}) . '::' . $obj->{name};
    }

    sub _deparse_define {
        my ($self, $obj, $refaddr) = @_;
        my $name = $obj->{name} . $refaddr;
        if (not $addr{$refaddr}++) {
            $self->top_add('use constant ' . $name . '=>do{' . $self->_dump_static_var($obj, $refaddr) . '};');
        }
        '(' . $self->{environment_name} . '::' . $name . ')';
    }

    sub _deparse_const {
        my ($self, $obj, $refaddr) = @_;
        my $name = $obj->{name} . $refaddr;
        if ($addr{$refaddr}++) {
            return "\$$name\->()";
        }
        else {
            my $code = $self->_dump_static_var($obj, $refaddr);
            return "my \$$name = sub { $code }; \$$name\->()";
        }
    }

    sub _deparse_static {
        my ($self, $obj, $refaddr) = @_;
        my $name = $obj->{name} . $refaddr;
        if ($addr{$refaddr}++) {
            return "\$$name";
        }
        else {
            return '(' . $self->_dump_static_var($obj, $refaddr) . ')';
        }
    }

    sub _deparse_const_init {
        my ($self, $obj) = @_;
        join(($obj->{type} eq 'global' ? ',' : ';'), map { $self->deparse_expr({self => $_}) } @{$obj->{vars}});
    }

    sub _deparse_init {
        my ($self, $obj) = @_;
        $self->_dump_init_vars($obj);
    }

    sub _deparse_class_init {
        my ($self, $obj, $refaddr) = @_;
        my $name = $self->_get_reftype($obj);
        if ($addr{$refaddr}++) {
            return q{'} . $name . q{'};
        }
        else {
            my $block = $obj->{block};
            my $code  = 'do{package ';
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
            return $code;
        }
    }

    sub _deparse_block_init {
        my ($self, $obj, $refaddr) = @_;
        my $code = '';

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
        return $code;
    }

    sub _deparse_struct {
        my ($self, $obj, $refaddr) = @_;
        my $name = $self->_get_reftype($obj);
        if ($addr{$refaddr}++) {
            return "'${name}'";
        }
        else {
            my $code =
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
            return $code;
        }
    }

    sub _deparse_subset {
        my ($self, $obj, $refaddr) = @_;
        my $name = $self->_get_reftype($obj);

        if ($addr{$refaddr}++) {
            return "'${name}'";
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

            return
                "do{package $name {use parent qw(-norequire @parents);"
              . "my \$sub = sub { $subset_block };"
              . "do{ no strict 'refs'; *{__PACKAGE__ . '::' . '__subset_validation__'} = \$sub };"
              . "};'${name}'}";
        }
    }

    sub _deparse_number {
        my ($self, $obj, $refaddr, $ref) = @_;
        my ($type, $content) = $obj->_dump;
        if ($type eq 'int') {
            return ($constant_number_cache{$content} //= $self->make_constant($ref, '_set_int', "Number", args => ["'${content}'"], sub => 1));
        }
        else {
            return ($constant_number_cache{join(' ', $type, $content)} //=
                    $self->make_constant($ref, '_set_str', "Number", args => ["'${type}'", "'${content}'"], sub => 1));
        }
    }

    sub _deparse_string {
        my ($self, $obj, $refaddr, $ref) = @_;
        return ($constant_string_cache{$$obj} //= $self->make_constant($ref, 'new', "String", args => [$self->_dump_string($$obj)]));
    }

    sub _deparse_array {
        my ($self, $obj, $refaddr, $ref) = @_;
        return $self->_dump_array($ref eq 'Sidef::Types::Array::HCArray' ? 'Sidef::Types::Array::Array' : $ref, $obj);
    }
    sub _deparse_vector { $_[0]->_dump_array('Sidef::Types::Array::Vector', $_[1]) }
    sub _deparse_matrix { $_[0]->_dump_array('Sidef::Types::Array::Matrix', $_[1]) }

    sub _deparse_bool {
        my ($self, $obj) = @_;
        return 'Sidef::Types::Bool::Bool::' . (${$obj} ? 'TRUE' : 'FALSE');
    }

    sub _deparse_regex {
        my ($self, $obj, $refaddr, $ref) = @_;
        return
          $self->make_constant($ref, 'new', "Regex",
                               args => [$self->_dump_string("$obj->{raw}"), $self->_dump_string($obj->{flags} . ($obj->{global} ? 'g' : ''))]);
    }

    sub _deparse_if {
        my ($self, $obj) = @_;
        my $code = 'do{';
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
        return $code;
    }

    sub _deparse_while {
        my ($self, $obj) = @_;
        my $vars = join(',', map { $self->_dump_var($_) } @{$obj->{block}{init_vars}{vars}});
        my $arg  = $self->deparse_args($obj->{expr});
        if ($vars) {
            $arg = "(my ($vars) = $arg)[-1]";
        }
        return 'while(' . $arg . ')' . $self->deparse_block_with_scope($obj->{block});
    }

    sub _deparse_foreach {
        my ($self, $obj) = @_;
        return $self->deparse_args($obj->{expr}) . '->each' . '(' . $self->deparse_expr({self => $obj->{block}}) . ')';
    }

    sub _deparse_cfor {
        my ($self, $obj) = @_;
        return 'for(' . join(';', map { $self->deparse_args($_) } @{$obj->{expr}}) . ')' . $self->deparse_block_with_scope($obj->{block});
    }

    sub _deparse_forin {
        my ($self, $obj) = @_;
        $self->load_mod('Sidef::Types::Block::Block');
        my @vars  = map { $self->_dump_sub_init_vars(@{$_->{vars}}) } @{$obj->{loops}};
        my $block = 'do' . $self->deparse_block_with_scope($obj->{block});
        my @loops = @{$obj->{loops}};
        my $code  = $block;
        while (@loops) {
            my $loop  = pop(@loops);
            my $vars  = pop @vars;
            my $expr  = $self->deparse_args($loop->{expr});
            my $multi = 0;
            if (@{$loop->{vars}} > 1 or (@{$loop->{vars}} == 1 and exists($loop->{vars}[0]{slurpy}))) {
                $multi = 1;
            }
            $code =
                'Sidef::Types::Block::Block::_iterate(sub { '
              . ($multi ? 'local @_ = @{$_[0]->to_a};' : '')
              . "$vars; $code }, $expr)"
              . (@loops ? ' // last' : '');
        }
        return $code;
    }

    sub _deparse_ternary {
        my ($self, $obj) = @_;
        return '(' . $self->deparse_script($obj->{cond}) . '?' . $self->deparse_args($obj->{true}) . ':' . $self->deparse_args($obj->{false}) . ')';
    }

    sub _deparse_named_param {
        my ($self, $obj, $refaddr, $ref) = @_;
        return $ref . '->new(' . $self->_dump_string($obj->{name}) . ', ' . $self->deparse_args(@{$obj->{value}}) . ')';
    }
    sub _deparse_nil { 'undef' }

    sub _deparse_hash {
        my ($self, $obj, $refaddr, $ref) = @_;
        $self->load_mod($ref);
        return
            'bless({'
          . join(',', map { $self->_dump_string($_) . '=>' . (defined($obj->{$_}) ? $self->deparse_expr({self => $obj->{$_}}) : 'undef') } sort(keys(%{$obj})))
          . "}, '${ref}')";
    }

    sub _deparse_prefix_method {
        my ($self, $obj) = @_;
        return 'do{my($self,@args)=' . $self->deparse_args($obj->{expr}) . ';$self->' . $obj->{name} . '(@args)}';
    }

    sub _deparse_do {
        my ($self, $obj) = @_;
        return 'do' . $self->deparse_block_with_scope($obj->{block});
    }

    sub _deparse_loop {
        my ($self, $obj) = @_;
        return 'while(1)' . $self->deparse_block_with_scope($obj->{block});
    }

    sub _deparse_given {
        my ($self, $obj) = @_;
        my $vars = join(',', map { $self->_dump_var($_) } @{$obj->{block}{init_vars}{vars}});
        return
            "sub { my \@given_values; my \$continue = 1; my \$given_value = (my ($vars) = "
          . $self->deparse_args($obj->{expr})
          . ')[-1];' . 'do'
          . $self->deparse_block_with_scope($obj->{block})
          . '; wantarray ? @given_values : $given_values[-1] }->()';
    }

    sub _deparse_when {
        my ($self, $obj) = @_;
        my $vars = join(',', map { $self->_dump_var($_) } @{$obj->{block}{init_vars}{vars}});
        my $arg  = $self->deparse_args($obj->{expr});
        if ($vars) {
            $arg = "(my ($vars) = $arg)[-1]";
        }
        return
            "if (\$continue) {my \$t = $arg;"
          . "if (defined(\$given_value) ? defined(\$t) ? Sidef::Object::Object::smartmatch(\$given_value, \$t) : 0 : 1) {"
          . "\$continue = 0; \@given_values = do"
          . $self->deparse_block_with_scope($obj->{block}) . "}};";
    }

    sub _deparse_case {
        my ($self, $obj) = @_;
        my $vars = join(',', map { $self->_dump_var($_) } @{$obj->{block}{init_vars}{vars}});
        my $arg  = $self->deparse_args($obj->{expr});
        if ($vars) {
            $arg = "(my ($vars) = $arg)[-1]";
        }
        return "if (\$continue and $arg) { \$continue = 0;" . "\@given_values = do" . $self->deparse_block_with_scope($obj->{block}) . '}';
    }

    sub _deparse_default {
        my ($self, $obj) = @_;
        return "if (\$continue) { \$continue = 0; \@given_values = do" . $self->deparse_block_with_scope($obj->{block}) . '}';
    }
    sub _deparse_continue { '$continue = 1' }

    sub _deparse_with {
        my ($self, $obj) = @_;
        my $code = 'do{';
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
        return $code;
    }

    sub _deparse_gather {
        my ($self, $obj, $refaddr) = @_;
        $self->load_mod("Sidef::Types::Array::Array");
        return "do{my \@_$refaddr;" . 'do' . $self->deparse_block_with_scope($obj->{block}) . "; bless(\\\@_$refaddr, 'Sidef::Types::Array::Array')}";
    }

    sub _deparse_take {
        my ($self, $obj) = @_;
        my $raddr = refaddr($obj->{gather});
        return "do{ push \@_$raddr," . $self->deparse_args($obj->{expr}) . "; \$_$raddr\[-1] }";
    }

    sub _deparse_try {
        my ($self, $obj, $refaddr, $ref) = @_;
        return
            $ref
          . '->new->try('
          . $self->deparse_expr({self => $obj->{try}})
          . ')->catch('
          . (defined($obj->{catch}) ? $self->deparse_expr({self => $obj->{catch}}) : '') . ')';
    }
    sub _deparse_ref_ok        { '' }
    sub _deparse_class_attr_ok { '' }
    sub _deparse_unary_ok      { '' }
    sub _deparse_break         { 'last' }
    sub _deparse_next          { 'next' }

    sub _deparse_return {
        my ($self, $obj, $refaddr, $ref, $expr) = @_;
        if (not exists $expr->{call}) {
            if (exists $self->{function}) {
                return "goto END$self->{function}";
            }
            else {
                return "return;";
            }
        }
        return '';
    }

    sub _deparse_stdin  { $_[0]->make_constant('Sidef::Types::Glob::FileHandle', 'new', "STDIN",  args => ['\*STDIN']) }
    sub _deparse_stdout { $_[0]->make_constant('Sidef::Types::Glob::FileHandle', 'new', "STDOUT", args => ['\*STDOUT']) }
    sub _deparse_stderr { $_[0]->make_constant('Sidef::Types::Glob::FileHandle', 'new', "STDERR", args => ['\*STDERR']) }
    sub _deparse_argf   { $_[0]->make_constant('Sidef::Types::Glob::FileHandle', 'new', "ARGF",   args => ['\*ARGV']) }

    sub _deparse_data {
        my ($self, $obj) = @_;
        require Encode;
        my $data = $self->_dump_string(Encode::encode_utf8(${$obj->{data}}));
        return $self->make_constant('Sidef::Types::Glob::FileHandle', 'new', "DATA", args => [qq{do{open my \$fh, '<:utf8', \\$data; \$fh}}]);
    }
    sub _deparse_magic { $_[1]->{name} }

    sub _deparse_eval {
        my ($self, $obj, $refaddr) = @_;
        $Sidef::EVALS{$refaddr} = $obj;
        return qq~
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

    sub _deparse_complex {
        my ($self, $obj, $refaddr, $ref) = @_;
        my ($real, $imag) = $obj->reals;
        my $name = "Complex$refaddr";
        $self->top_add("use constant $name => $ref\->new(" . join(',', $self->deparse_expr({self => $real}), $self->deparse_expr({self => $imag})) . ');');
        return "($self->{environment_name}\::$name)";
    }

    sub _deparse_pair {
        my ($self, $obj, $refaddr, $ref) = @_;
        return $ref . '->new(' . join(',', map { defined($_) ? $self->deparse_expr({self => $_}) : 'undef' } @{$obj}) . ')';
    }

    sub _deparse_null {
        my ($self, $obj, $refaddr, $ref) = @_;
        return $self->make_constant($ref, 'new', "Null", args => []);
    }

    sub _deparse_module_oo {
        my ($self, $obj, $refaddr, $ref) = @_;
        return $self->make_constant($ref, '__NEW__', "ModuleOO", args => [$self->_dump_string($obj->{module})]);
    }

    sub _deparse_module_func {
        my ($self, $obj, $refaddr, $ref) = @_;
        return $self->make_constant($ref, '__NEW__', "ModuleFunc", args => [$self->_dump_string($obj->{module})]);
    }

    sub _deparse_perl_code {
        my ($self, $obj, $refaddr, $ref) = @_;
        return $self->make_constant($ref, 'new', "PerlCode", args => [$self->_dump_string(${$obj})]);
    }

    sub _deparse_backtick {
        my ($self, $obj, $refaddr, $ref) = @_;
        return $self->make_constant($ref, 'new', "Backtick", args => [$self->_dump_string(${$obj})]);
    }

    sub _deparse_file {
        my ($self, $obj, $refaddr, $ref) = @_;
        return $self->make_constant($ref, 'new', "File", args => [$self->_dump_string(${$obj})]);
    }

    sub _deparse_dir {
        my ($self, $obj, $refaddr, $ref) = @_;
        return $self->make_constant($ref, 'new', "Dir", args => [$self->_dump_string(${$obj})]);
    }

    sub _deparse_meta_module {
        my ($self, $obj) = @_;
        return substr($self->deparse_bare_block($obj->{block}{code}), 1, -1);
    }

    sub _deparse_included {
        my ($self, $obj) = @_;
        my $code = '';
        foreach my $info (@{$obj->{included}}) {
            $code .= join(';', $self->deparse_script($info->{ast})) . ';';
        }
        return $code;
    }

    sub _deparse_assert {
        my ($self, $obj, $refaddr) = @_;
        my @args = $self->deparse_script($obj->{arg});

        if ($obj->{act} eq 'assert') {
            @args > 2
              and die "[ERROR] Incorrect number of arguments for $obj->{act}\() at" . " $obj->{file} line $obj->{line} (expected 1 or 2 arguments)\n";
            my $msg = $args[1] // 'undef';
            return
                qq~do{my \$a$refaddr = do{$args[0]}; ~
              . qq~\$a$refaddr or CORE::die((do{$msg} // "$obj->{act}(\$a$refaddr)") . " failed ~
              . qq~at \Q$obj->{file}\E line $obj->{line}\\n")}~;
        }
        elsif ($obj->{act} eq 'assert_eq' or $obj->{act} eq 'assert_ne') {
            @args > 3
              and die "[ERROR] Incorrect number of arguments for $obj->{act}\() at" . " $obj->{file} line $obj->{line} (expected 2 or 3 arguments)\n";
            return
                "do{"
              . "my \$a$refaddr = do{$args[0]};"
              . "my \$b$refaddr = do{$args[1]};"
              . ($obj->{act} eq 'assert_ne' ? qq{!(\$a$refaddr eq \$b$refaddr)} : qq{\$a$refaddr eq \$b$refaddr})
              . qq~ or CORE::die((~
              . (defined($args[2]) ? "do{$args[2]}" : "undef")
              . qq~// ('$obj->{act}('.~
              . qq~join(', ',map{(ref(\$_) && UNIVERSAL::can(\$_,'dump')) ? \$_->dump : \$_}(\$a$refaddr, \$b$refaddr)) . ')'))~
              . qq~." failed at \Q$obj->{file}\E line $obj->{line}\\n")}~;
        }
        return '';
    }

    sub _deparse_error {
        my ($self, $obj) = @_;
        my @args = $self->deparse_args($obj->{arg});
        return qq~do{CORE::die(@args, " at \Q$obj->{file}\E line $obj->{line}\\n")}~;
    }

    sub _deparse_warning {
        my ($self, $obj) = @_;
        my @args = $self->deparse_args($obj->{arg});
        return qq~((CORE::warn(@args, " at \Q$obj->{file}\E line $obj->{line}\\n")) ? ~
          . qq~(Sidef::Types::Bool::Bool::FALSE) : (Sidef::Types::Bool::Bool::TRUE))~;
    }

    sub _deparse_pipe {
        my ($self, $obj, $refaddr, $ref) = @_;
        return $self->make_constant($ref, 'new', "Pipe", args => [map { $self->_dump_string($_) } @{$obj}]);
    }

    sub _deparse_parser { '$Sidef::PARSER' }

    sub _deparse_unimplemented {
        my ($self, $obj) = @_;
        return qq{CORE::die "Unimplemented at " . } . $self->_dump_string($obj->{file}) . qq{. " line $obj->{line}\\n"};
    }
    sub _deparse_label   { $_[1]->{name} . ': ' }
    sub _deparse_builtin { '' }

    #----------------------------------------------------------------------
    # Main logic
    #----------------------------------------------------------------------

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $code    = '';
        my $obj     = $expr->{self};
        my $refaddr = refaddr($obj);

        # Self obj
        my $ref = ref($obj) || return '';

        if (exists $handlers{$ref}) {
            my $method = $handlers{$ref};
            $code = $self->$method($obj, $refaddr, $ref, $expr);
        }
        elsif ($ref eq 'HASH') {
            $code = join(',', exists($obj->{self}) ? $self->deparse_expr($obj) : $self->deparse_script($obj));
        }
        elsif (exists($COMPOSITE_CONSTANTS{$ref})) {
            my $data = $COMPOSITE_CONSTANTS{$ref};
            $code = $self->make_constant(
                                         $ref, 'new',
                                         $data->{name},
                                         new  => 1,
                                         args => [map { $self->deparse_expr({self => $obj->{$_}}) } @{$data->{fields}}]
                                        );
        }
        elsif (exists $DATA_TYPES{$ref}) {
            my $mod = $DATA_TYPES{$ref};
            $self->{_reftype_cache}{$mod} //= do {
                $self->load_mod($mod);
                1;
            };
            $code = "'" . $mod . "'";
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
                    $code = 'bless({' . $self->deparse_args(@{$call->{arg}}) . "}, '$DATA_TYPES{$ref}')";
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
                        elsif (exists $INC_DEC_OPS{$method}) {
                            my $var = $self->deparse_args(@{$call->{arg}});
                            $code = "do{my\$r=\\$var;\$\$r=\$\$r\->$INC_DEC_OPS{$method}}";
                            next;
                        }
                    }

                    # Postfix ++ and -- operators on variables
                    if (exists($INC_DEC_OPS{$method})) {
                        $code = "do{my\$r=\\$code;my\$v=\$\$r;\$\$r=\$v\->$INC_DEC_OPS{$method};\$v}";
                        next;
                    }

                    if (exists($LAZY_OPS{$method})) {
                        $code .= $LAZY_OPS{$method} . $self->deparse_args(@{$call->{arg}});
                        next;
                    }

                    # Variable assignment (=)
                    if (exists($ASSIGNMENT_OPS{$method})) {
                        $code = "($code$ASSIGNMENT_OPS{$method}" . $self->deparse_args(@{$call->{arg}}) . ")[-1]";
                        next;
                    }

                    # Reassignment operators, such as: +=, -=, *=, /=, etc...
                    if (exists $REASSIGN_OPS{$method}) {
                        $code =
                            "CORE::sub:lvalue{my\$r=\\$code;\$\$r=\$\$r"
                          . $self->_dump_op_call($REASSIGN_OPS{$method})
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

        if ($code eq '') {
            $code = '()';
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
