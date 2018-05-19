package Sidef::Deparse::Sidef {

    use 5.014;
    use Scalar::Util qw(refaddr reftype);

    my %addr;

    sub new {
        my (undef, %args) = @_;

        my %opts = (
            before       => '',
            between      => ";\n",
            after        => ";\n",
            class        => 'main',
            extra_parens => 0,
            namespaces   => [],
            opt          => {},
            data_types   => {
                qw(
                  Sidef::DataTypes::Bool::Bool            Bool
                  Sidef::DataTypes::Array::Array          Array
                  Sidef::DataTypes::Array::Pair           Pair
                  Sidef::DataTypes::Hash::Hash            Hash
                  Sidef::DataTypes::Regex::Regex          Regex
                  Sidef::DataTypes::String::String        String
                  Sidef::DataTypes::Number::Number        Number
                  Sidef::DataTypes::Number::Complex       Complex
                  Sidef::DataTypes::Range::Range          Range
                  Sidef::DataTypes::Range::RangeNumber    RangeNum
                  Sidef::DataTypes::Range::RangeString    RangeStr
                  Sidef::DataTypes::Block::Block          Block
                  Sidef::DataTypes::Glob::Socket          Socket
                  Sidef::DataTypes::Glob::Pipe            Pipe
                  Sidef::DataTypes::Glob::Backtick        Backtick
                  Sidef::DataTypes::Glob::DirHandle       DirHandle
                  Sidef::DataTypes::Glob::FileHandle      FileHandle
                  Sidef::DataTypes::Glob::SocketHandle    SocketHandle
                  Sidef::DataTypes::Glob::Dir             Dir
                  Sidef::DataTypes::Glob::File            File
                  Sidef::DataTypes::Object::Object        Object
                  Sidef::DataTypes::Sidef::Sidef          Sidef
                  Sidef::DataTypes::Object::Lazy          Lazy
                  Sidef::DataTypes::Object::LazyMethod    LazyMethod
                  Sidef::DataTypes::Object::Enumerator    Enumerator

                  Sidef::Math::Math                       Math
                  Sidef::Meta::Glob::ARGF                 ARGF
                  Sidef::Meta::Glob::STDIN                STDIN
                  Sidef::Meta::Glob::STDOUT               STDOUT
                  Sidef::Meta::Glob::STDERR               STDERR
                  Sidef::Parser                           Parser

                  Sidef::Types::Nil::Nil                  nil
                  Sidef::Types::Null::Null                null
                  Sidef::Types::Block::Next               next
                  Sidef::Types::Block::Break              break
                  Sidef::Types::Block::Continue           continue

                  Sidef::Perl::Perl                       Perl
                  Sidef::Time::Time                       Time
                  Sidef::Sys::Sig                         Sig
                  Sidef::Meta::Unimplemented              ...
                  )
            },
            %args,
                   );
        %addr = ();    # reset the `addr` hash
        bless \%opts, __PACKAGE__;
    }

    sub deparse_generic {
        my ($self, $before, $sep, $after, @args) = @_;
        $before . join(
            $sep,
            grep { $_ ne '' }
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

    sub deparse_bare_block {
        my ($self, @args) = @_;

        $Sidef::SPACES += $Sidef::SPACES_INCR;
        my $code = $self->deparse_generic("{(\n" . " " x ($Sidef::SPACES),
                                          ");(\n" . (" " x ($Sidef::SPACES)),
                                          "\n" . (" " x ($Sidef::SPACES - $Sidef::SPACES_INCR)) . ")}", @args);

        $Sidef::SPACES -= $Sidef::SPACES_INCR;

        $code;
    }

    sub _dump_init_vars {
        my ($self, $init_obj, $type) = @_;
        my $code = $type . '(' . $self->_dump_vars(@{$init_obj->{vars}}) . ')';

        if (exists $init_obj->{args}) {
            $code .= '=' . $self->deparse_args($init_obj->{args});
        }

        $code;
    }

    sub _dump_reftype {
        my ($self, $obj) = @_;

        my $ref = ref($obj);

        if (exists $self->{data_types}{$ref}) {
            return $self->{data_types}{$ref};
        }

        ($ref eq 'Sidef::Variable::ClassInit' || $ref eq 'Sidef::Variable::Struct' || $ref eq 'Sidef::Variable::Subset')
          ? $obj->{name}
          : $ref eq 'Sidef::Types::Block::BlockInit' ? 'Block'
          :                                            substr($ref, rindex($ref, '::') + 2);
    }

    sub _dump_vars {
        my ($self, @vars) = @_;
        join(
            ', ',
            map {
                    (exists($_->{array}) ? '*' : exists($_->{hash}) ? ':' : '')
                  . (exists($_->{class}) && $_->{class} ne $self->{class} ? $_->{class} . '::' : '')
                  . (exists($_->{ref_type}) ? ($self->_dump_reftype($_->{ref_type}) . ' ') : '')
                  . $_->{name}
                  . (exists($_->{subset}) ? (' < ' . $self->_dump_reftype($_->{subset})) : '')
                  . (exists($_->{where_block}) ? $self->deparse_expr({self => $_->{where_block}}) : '')
                  . (exists($_->{where_expr}) ? ('(' . $self->deparse_expr({self => $_->{where_expr}}) . ')') : '')
                  . (exists($_->{value}) ? ('=(' . $self->deparse_expr({self => $_->{value}}) . ')') : '')
              } @vars
            );
    }

    sub _dump_string {
        my ($self, $str) = @_;
        Sidef::Types::String::String->new($str)->dump->get_value;
    }

    sub _dump_number {
        my ($self, $num) = @_;

        my ($type, $str) = $num->_dump;

        if ($type eq 'complex') {
            my ($real, $imag) =
              map { $self->_dump_number(Sidef::Types::Number::Number->new($_)) } split(' ', substr($str, 1, -1));
            return "Complex($real, $imag)";
        }

        state $table = {
                        '@inf@'  => q{Inf},
                        '-@inf@' => q{-(Inf)},
                        '@nan@'  => q{NaN},
                       };

        exists($table->{lc($str)}) ? $table->{lc($str)} : do {
            if ($type eq 'float') {
                "$str.float";
            }
            elsif (index($str, '/') != -1) {
                "Number(\"$str\")";
            }
            else {
                $str;
            }
        };
    }

    sub _dump_array {
        my ($self, $array) = @_;
        '[' . join(', ', map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}) } @{$array}) . ']';
    }

    sub _dump_class_name {
        my ($self, $class) = @_;
        ref($class) ? $self->_dump_reftype($class) : $class;
    }

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $code = '';
        my $obj  = $expr->{self};

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $code = join(', ', exists($obj->{self}) ? $self->deparse_expr($obj) : $self->deparse_script($obj));
            if ($self->{extra_parens}) {
                $code = "($code)";
            }
        }
        elsif ($ref eq 'Sidef::Variable::Variable') {
            if (   $obj->{type} eq 'var'
                or $obj->{type} eq 'static'
                or $obj->{type} eq 'const'
                or $obj->{type} eq 'has') {
                $code =
                  $obj->{name} =~ /^[0-9]+\z/
                  ? ('$' . $obj->{name})
                  : (($obj->{class} ne $self->{class} ? ($obj->{class} . '::') : '') . $obj->{name});
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {
                if ($addr{refaddr($obj)}++) {
                    $code =
                      $obj->{name} eq ''
                      ? '__FUNC__'
                      : (($obj->{class} ne $self->{class} ? $obj->{class} . '::' : '') . $obj->{name});
                }
                else {
                    my $block     = $obj->{value};
                    my $in_module = $obj->{class} ne $self->{class};

                    if ($in_module) {
                        $code = "module $obj->{class} {\n";
                        $Sidef::SPACES += $Sidef::SPACES_INCR;
                        $code .= ' ' x $Sidef::SPACES;
                    }

                    $code .= $obj->{type} . ' ' . $obj->{name};
                    local $self->{class} = $obj->{class};
                    my $var_obj = delete $block->{init_vars};

                    $code .= '('
                      . $self->_dump_vars(@{$var_obj->{vars}}[($obj->{type} eq 'method' ? 1 : 0) .. $#{$var_obj->{vars}}])
                      . ') ';

                    if (exists $obj->{cached}) {
                        $code .= 'is cached ';
                    }

                    if (exists $obj->{returns}) {
                        $code .= '-> (' . join(',', map { $self->deparse_expr({self => $_}) } @{$obj->{returns}}) . ') ';
                    }

                    $code .= $self->deparse_expr({self => $block});
                    $block->{init_vars} = $var_obj;

                    if ($in_module) {
                        $code .= "\n}";
                        $Sidef::SPACES -= $Sidef::SPACES_INCR;
                    }
                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::ClassAttr') {
            $code = $self->_dump_init_vars($obj, 'has');
        }
        elsif ($ref eq 'Sidef::Variable::Struct') {
            if ($addr{refaddr($obj)}++) {
                $code = $obj->{name};
            }
            else {
                $code = "struct $obj->{name} {" . $self->_dump_vars(@{$obj->{vars}}) . '}';
            }
        }
        elsif ($ref eq 'Sidef::Variable::Subset') {
            if ($addr{refaddr($obj)}++) {
                $code = $obj->{name};
            }
            else {
                $code =
                    "subset $obj->{name} < "
                  . join(',', map { $self->deparse_expr({self => $_}) } @{$obj->{inherits}})
                  . (exists($obj->{blocks}) ? (' ' . $self->deparse_expr({self => $obj->{blocks}[-1]})) : '');
            }
        }
        elsif ($ref eq 'Sidef::Variable::Local') {
            $code = 'local ' . '(' . $self->deparse_script($obj->{expr}) . ')';
        }
        elsif ($ref eq 'Sidef::Variable::Global') {
            my $name = 'global ' . $obj->{class} . '::' . $obj->{name};
            if (not exists($obj->{inited}) and defined($obj->{expr})) {
                $obj->{inited} = 1;
                $code = $name . '=' . $self->deparse_script($obj->{expr});
            }
            else {
                $code = $name;
            }
        }
        elsif ($ref eq 'Sidef::Variable::ClassVar') {
            $code = $self->_dump_reftype($obj->{class}) . '!' . $obj->{name};
        }
        elsif ($ref eq 'Sidef::Variable::Init') {
            $code = $self->_dump_init_vars($obj, 'var');
        }
        elsif ($ref eq 'Sidef::Variable::ConstInit') {
            $code = join(
                         (
                          $obj->{type} eq 'global'
                          ? ', '
                          : (";\n" . (" " x $Sidef::SPACES))
                         ),
                         map { $self->deparse_expr({self => $_}) } @{$obj->{vars}}
                        );
        }
        elsif ($ref eq 'Sidef::Variable::Define') {
            my $name = $obj->{name};
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $code = "define $name";
                if (defined $obj->{expr}) {
                    $code .= ' = (' . $self->deparse_script($obj->{expr}) . ')';
                }
            }
            else {
                $code = ($obj->{class} ne $self->{class} ? ($obj->{class} . '::') : '') . $name;
            }
        }
        elsif ($ref eq 'Sidef::Variable::Const') {
            my $name = $obj->{name};
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $code = "const $name";
                if (defined $obj->{expr}) {
                    $code .= ' = (' . $self->deparse_script($obj->{expr}) . ')';
                }
            }
            else {
                $code = ($obj->{class} ne $self->{class} ? ($obj->{class} . '::') : '') . $name;
            }
        }
        elsif ($ref eq 'Sidef::Variable::Static') {
            my $name = $obj->{name};
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $code = "static " . ($obj->{class} ne $self->{class} ? ($obj->{class} . '::') : '') . $name;
                if (defined $obj->{expr}) {
                    $code .= ' = (' . $self->deparse_script($obj->{expr}) . ')';
                }
            }
            else {
                $code = ($obj->{class} ne $self->{class} ? ($obj->{class} . '::') : '') . $name;
            }
        }
        elsif ($ref eq 'Sidef::Variable::ClassInit') {
            if ($addr{refaddr($obj)}++) {
                $code = (
                         $obj->{name} eq '' ? '__CLASS__'
                         : $self->_dump_class_name(
                                                     $obj->{class} ne $self->{class} ? ($obj->{class} . '::' . $obj->{name})
                                                   : $obj->{name}
                                                  )
                        );
            }
            else {
                my $block     = $obj->{block};
                my $in_module = $obj->{class} ne $self->{class};

                if ($in_module) {
                    $code = "module $obj->{class} {\n";
                    $Sidef::SPACES += $Sidef::SPACES_INCR;
                    $code .= ' ' x $Sidef::SPACES;
                }

                local $self->{class} = $obj->{class};
                my $name = $self->_dump_class_name($obj->{name});
                $code .= "class " . $name;
                $code .= '(' . $self->_dump_vars(@{$obj->{vars}}) . ')';
                if (exists $obj->{inherit}) {
                    my $inherited = join(', ', grep { $_ ne $name } map { $self->_dump_class_name($_) } @{$obj->{inherit}});
                    if ($inherited ne '') {
                        $code .= ' < ' . $inherited . ' ';
                    }
                }
                $code .= $self->deparse_expr({self => $block});

                if ($in_module) {
                    $code .= "\n}";
                    $Sidef::SPACES -= $Sidef::SPACES_INCR;
                }
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::BlockInit') {
            if ($addr{refaddr($obj)}++) {
                $code = keys(%{$obj}) ? '__BLOCK__' : 'Block';
            }
            else {
                if (keys(%{$obj})) {
                    $code = '{';
                    if (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}}) {
                        my @vars = @{$obj->{init_vars}{vars}};
                        if (@vars) {
                            $code .= '|' . $self->_dump_vars(@vars) . '|';
                        }
                    }

                    $Sidef::SPACES += $Sidef::SPACES_INCR;
                    my @statements = $self->deparse_script($obj->{code});

                    if (@statements) {
                        $statements[-1] = '(' . $statements[-1] . ')';
                    }

                    if (@statements == 1 and length($statements[0]) + $Sidef::SPACES <= 80) {
                        $code .= " $statements[0] }";
                    }
                    else {
                        $code .=
                          @statements
                          ? ("\n"
                             . (" " x $Sidef::SPACES)
                             . join(";\n" . (" " x $Sidef::SPACES), @statements) . "\n"
                             . (" " x ($Sidef::SPACES - $Sidef::SPACES_INCR)) . '}')
                          : '}';
                    }

                    $Sidef::SPACES -= $Sidef::SPACES_INCR;
                }
                else {
                    $code = 'Block';
                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::Ref') {
            if (not exists $expr->{call}) {
                $code = 'Ref';
            }
        }
        elsif ($ref eq 'Sidef::Sys::Sys') {
            $code = exists($obj->{file_name}) ? '' : 'Sys';
        }
        elsif ($ref eq 'Sidef::Meta::PrefixMethod') {
            $code = "::$obj->{name}" . $self->deparse_args($obj->{expr});
        }
        elsif ($ref eq 'Sidef::Meta::Assert') {
            $code = $obj->{act} . $self->deparse_args($obj->{arg});
        }
        elsif ($ref eq 'Sidef::Meta::Error') {
            $code = 'die' . $self->deparse_args($obj->{arg});
        }
        elsif ($ref eq 'Sidef::Meta::Warning') {
            $code = 'warn' . $self->deparse_args($obj->{arg});
        }
        elsif ($ref eq 'Sidef::Eval::Eval') {
            $code = 'eval' . $self->deparse_args($obj->{expr});
        }
        elsif ($ref eq 'Sidef::Variable::NamedParam') {
            $code = $obj->[0] . ':' . $self->deparse_args(@{$obj->[1]});
        }
        elsif ($ref eq 'Sidef::Variable::Label') {
            $code = '@:' . $obj->{name};
        }
        elsif ($ref eq 'Sidef::Types::Block::Given') {
            $code = 'given ' . $self->deparse_args($obj->{expr}) . $self->deparse_expr({self => $obj->{block}});
        }
        elsif ($ref eq 'Sidef::Types::Block::When') {
            $code = 'when(' . $self->deparse_args($obj->{expr}) . ')' . $self->deparse_expr({self => $obj->{block}});
        }
        elsif ($ref eq 'Sidef::Types::Block::Case') {
            $code = 'case(' . $self->deparse_args($obj->{expr}) . ')' . $self->deparse_expr({self => $obj->{block}});
        }
        elsif ($ref eq 'Sidef::Types::Block::Default') {
            $code = 'default' . $self->deparse_bare_block($obj->{block}->{code});
        }
        elsif ($ref eq 'Sidef::Types::Block::With') {
            foreach my $i (0 .. $#{$obj->{with}}) {
                $code .= ($i == 0 ? 'with' : 'orwith');
                my $info = $obj->{with}[$i];
                $code .= $self->deparse_args($info->{expr}) . $self->deparse_expr({self => $info->{block}});
            }
            if (exists $obj->{else}) {
                $code .= 'else' . $self->deparse_bare_block($obj->{else}{block}{code});
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::Return') {
            if (not exists $expr->{call}) {
                $code = 'return';
            }
        }
        elsif ($ref eq 'Sidef::Types::Bool::Ternary') {
            $code = '('
              . $self->deparse_script($obj->{cond}) . ' ? '
              . $self->deparse_args($obj->{true}) . ' : '
              . $self->deparse_args($obj->{false}) . ')';
        }
        elsif ($ref eq 'Sidef::Module::OO') {
            $code = '%s' . $self->_dump_string($obj->{module});
        }
        elsif ($ref eq 'Sidef::Module::Func') {
            $code = '%S' . $self->_dump_string($obj->{module});
        }
        elsif ($ref eq 'Sidef::Types::Array::List') {
            $code = join(', ', map { $self->deparse_expr({self => $_}) } @{$obj});
        }
        elsif ($ref eq 'Sidef::Types::Block::Gather') {
            $code = 'gather ' . $self->deparse_expr({self => $obj->{block}});
        }
        elsif ($ref eq 'Sidef::Types::Block::Take') {
            $code = 'take' . $self->deparse_args($obj->{expr});
        }
        elsif ($ref eq 'Sidef::Types::Block::Do') {
            $code = 'do ' . $self->deparse_expr({self => $obj->{block}});
        }
        elsif ($ref eq 'Sidef::Types::Block::Loop') {
            $code = 'loop ' . $self->deparse_expr({self => $obj->{block}});
        }
        elsif ($ref eq 'Sidef::Types::Block::If') {
            foreach my $i (0 .. $#{$obj->{if}}) {
                $code .= ($i == 0 ? 'if' : 'elsif');
                my $info = $obj->{if}[$i];
                $code .= $self->deparse_args($info->{expr}) . $self->deparse_expr({self => $info->{block}});
            }
            if (exists $obj->{else}) {
                $code .= 'else' . $self->deparse_bare_block($obj->{else}{block}{code});
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::While') {
            $code = "while" . $self->deparse_args($obj->{expr}) . $self->deparse_expr({self => $obj->{block}});
        }
        elsif ($ref eq 'Sidef::Types::Block::ForEach') {
            $code = 'foreach' . $self->deparse_args($obj->{expr}) . $self->deparse_expr({self => $obj->{block}});
        }
        elsif ($ref eq 'Sidef::Types::Block::CFor') {
            $code =
                'for' . '('
              . join(';', map { $self->deparse_args($_) } @{$obj->{expr}}) . ')'
              . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Sidef::Types::Block::ForIn') {
            $code = 'for ' . join(
                ', ',
                map {
                    join(',',
                         map { ($_->{slurpy} ? ($_->{array} ? '*' : ':') : '') . $self->deparse_expr({self => $_}) }
                           @{$_->{vars}})
                      . ' in ('
                      . $self->deparse_expr({self => $_->{expr}}) . ')'
                } @{$obj->{loops}}
              )
              . ' '
              . $self->deparse_bare_block($obj->{block}->{code});
        }
        elsif ($ref eq 'Sidef::Meta::Glob::DATA') {
            $code = 'DATA';
            if (not exists $addr{$obj->{data}}) {
                $self->{after} .= "\n__DATA__\n" . ${$obj->{data}};
                $addr{$obj->{data}} = 1;
            }
        }
        elsif ($ref eq 'Sidef::Variable::Magic') {
            $code = $obj->{name};
        }
        elsif ($ref eq 'Sidef::Types::Hash::Hash') {
            $code = $obj->dump->get_value;
        }
        elsif ($ref eq 'Sidef::Types::Number::Number') {
            $code = $self->_dump_number($obj);
        }
        elsif ($ref eq 'Sidef::Types::Array::Array' or $ref eq 'Sidef::Types::Array::HCArray') {
            $code = $self->_dump_array($obj);
        }
        elsif (exists $self->{data_types}{$ref}) {
            $code = $self->{data_types}{$ref};
        }
        elsif ($ref =~ /^Sidef::/ and UNIVERSAL::can($obj, 'dump')) {
            $code = $obj->dump->get_value;
        }

        # Array and hash indices
        if (exists $expr->{ind}) {
            $code = "($code)";
            foreach my $ind (@{$expr->{ind}}) {
                if (exists $ind->{array}) {
                    $code .= $self->_dump_array($ind->{array});
                }
                else {
                    $code .= '{'
                      . join(',',
                             map { ref($_) eq 'HASH' ? ($self->deparse_expr($_)) : $self->deparse_generic('', '', '', $_) }
                               @{$ind->{hash}})
                      . '}';
                }
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {
            foreach my $i (0 .. $#{$expr->{call}}) {

                my $call   = $expr->{call}[$i];
                my $method = $call->{method};

                if (defined $method and $method eq 'call' and exists $call->{arg}) {
                    undef $method;
                }

                if (defined $method) {

                    if (ref($method) ne '') {
                        $code .= '->'
                          . (
                             '('
                               . $self->deparse_expr(
                                                     ref($method) eq 'HASH'
                                                     ? $method
                                                     : {self => $method}
                                                    )
                               . ')'
                            );

                    }
                    elsif ($method =~ /^[^\W\d]/) {

                        if ($ref eq 'Sidef::Types::Block::BlockInit' and $method eq 'loop') {
                            $code = "loop $code";
                        }
                        else {

                            if ($code ne '') {
                                $code .= '->';
                            }

                            $code .= $method;
                        }

                        if (not exists $call->{arg}) {
                            $code .= '()';
                        }
                    }
                    else {
                        if ($ref eq 'Sidef::Variable::Ref' or $ref eq 'Sidef::Operator::Unary') {
                            $code .= $method;
                        }
                        else {
                            $code = "($code)->$method";
                        }
                    }
                }

                if (exists $call->{keyword}) {
                    if ($code ne '') {
                        if (substr($code, 0, 1) ne '(' or substr($code, -1) ne ')') {
                            $code .= ' ';
                        }
                        else {
                            $code = "($code)";
                        }
                    }
                    $code .= $call->{keyword};
                }

                if (exists $call->{arg}) {
                    $code .= $self->deparse_args(@{$call->{arg}});
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
            my $in_module = $class ne $self->{class};
            local $self->{class} = $class;
            foreach my $i (0 .. $#{$struct->{$class}}) {
                my $expr = $struct->{$class}[$i];
                push @results, ref($expr) eq 'HASH' ? $self->deparse_expr($expr) : $self->deparse_expr({self => $expr});
            }
            if ($in_module) {
                my $spaces = " " x $Sidef::SPACES_INCR;
                s/^/$spaces/gm for @results;
                $results[0] = "module $class {\n" . $results[0];
                $results[-1] .= "\n}";
            }
        }

        wantarray ? @results : $results[-1];
    }

    sub deparse {
        my ($self, $struct) = @_;
        my @statements = $self->deparse_script($struct);
        $self->{before} . join($self->{between}, @statements) . $self->{after};
    }
};

1
