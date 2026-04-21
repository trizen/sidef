package Sidef::Deparse::Sidef {

    use utf8;
    use 5.016;
    use Scalar::Util qw(refaddr reftype);

    # Tracks ref addresses to avoid infinite recursion on circular structures.
    # Reset on each new() call.
    my %addr;

    # =========================================================================
    # Sidef internal class name → Sidef source type name
    # =========================================================================

    my %DATA_TYPES = qw(
      Sidef::DataTypes::Bool::Bool            Bool
      Sidef::DataTypes::Array::Array          Array
      Sidef::DataTypes::Array::Pair           Pair
      Sidef::DataTypes::Array::Vector         Vector
      Sidef::DataTypes::Array::Matrix         Matrix
      Sidef::DataTypes::Hash::Hash            Hash
      Sidef::DataTypes::Set::Set              Set
      Sidef::DataTypes::Set::Bag              Bag
      Sidef::DataTypes::Regex::Regex          Regex
      Sidef::DataTypes::String::String        String
      Sidef::DataTypes::Number::Number        Number
      Sidef::DataTypes::Number::Mod           Mod
      Sidef::DataTypes::Number::Gauss         Gauss
      Sidef::DataTypes::Number::Quadratic     Quadratic
      Sidef::DataTypes::Number::Quaternion    Quaternion
      Sidef::DataTypes::Number::Complex       Complex
      Sidef::DataTypes::Number::Polynomial    Polynomial
      Sidef::DataTypes::Number::PolynomialMod PolynomialMod
      Sidef::DataTypes::Number::Fraction      Fraction
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
      Sidef::DataTypes::Perl::Perl            Perl
      Sidef::DataTypes::Object::Object        Object
      Sidef::DataTypes::Sidef::Sidef          Sidef
      Sidef::DataTypes::Object::Lazy          Lazy
      Sidef::DataTypes::Object::LazyMethod    LazyMethod
      Sidef::DataTypes::Object::Enumerator    Enumerator
      Sidef::DataTypes::Variable::NamedParam  NamedParam

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

      Sidef::Time::Time                       Time
      Sidef::Time::Date                       Date
      Sidef::Sys::Sig                         Sig
      Sidef::Sys::Sys                         Sys
      Sidef::Meta::Unimplemented              ...
    );

    # =========================================================================
    # Constructor
    # =========================================================================

    sub new {
        my (undef, %args) = @_;

        my %opts = (
                    before       => '',
                    between      => ";\n",
                    after        => ";\n",
                    class        => 'main',
                    extra_parens => 0,
                    opt          => {},
                    data_types   => {%DATA_TYPES},
                    %args,
                   );

        undef %addr;    # reset address-tracking hash for this deparse run
        bless \%opts, __PACKAGE__;
    }

    # =========================================================================
    # Low-level dump helpers
    # =========================================================================

    sub _dump_string {
        my ($self, $str) = @_;
        Sidef::Types::String::String->new($str)->dump->get_value;
    }

    sub _dump_number {
        my ($self, $num) = @_;

        my ($type, $str) = $num->_dump;

        state $table = {
                        '@inf@'  => 'Inf',
                        '-@inf@' => 'Inf->neg()',
                        '@nan@'  => 'NaN',
                        'inf'    => 'Inf',
                        '-inf'   => 'Inf->neg()',
                        'nan'    => 'NaN',
                       };

        state $special_values = {
                                 '@inf@'  => Sidef::Types::Number::Number->inf,
                                 '-@inf@' => Sidef::Types::Number::Number->ninf,
                                 '@nan@'  => Sidef::Types::Number::Number->nan,
                                };

        if ($type eq 'complex') {
            my ($real, $imag) =
              map { $self->_dump_number($special_values->{lc($_)} // Sidef::Types::Number::Number->new($_)) } split(' ', substr($str, 1, -1));
            return "Complex($real, $imag)";
        }

        $table->{lc($str)} // do {
            if    ($type eq 'float')       { $str . 'f' }
            elsif (index($str, '/') != -1) { qq{Number("$str")} }
            else                           { $str }
        };
    }

    sub _dump_array {
        my ($self, $array) = @_;
        '[' . join(', ', map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}) } @{$array}) . ']';
    }

    sub _dump_reftype {
        my ($self, $obj) = @_;

        my $ref = ref($obj);

        return $self->{data_types}{$ref}
          if exists $self->{data_types}{$ref};

        return $obj->{class} . '::' . $obj->{name}
          if $ref eq 'Sidef::Variable::ClassInit'
          || $ref eq 'Sidef::Variable::Struct'
          || $ref eq 'Sidef::Variable::Subset';

        return 'Block'
          if $ref eq 'Sidef::Types::Block::BlockInit';

        return substr($ref, rindex($ref, '::') + 2);
    }

    sub _dump_vars {
        my ($self, @vars) = @_;

        join(
            ', ',
            map {
                my $v = $_;

                my $prefix =
                    exists($v->{array}) ? '*'
                  : exists($v->{hash})  ? ':'
                  :                       '';

                my $class_prefix =
                  (exists($v->{class}) && $v->{class} ne $self->{class})
                  ? $v->{class} . '::'
                  : '';

                my $type_prefix =
                  (exists($v->{ref_type}) && ($v->{type} eq 'var' || $v->{type} eq 'has'))
                  ? $self->_dump_reftype($v->{ref_type}) . ' '
                  : '';

                my $subset =
                  exists($v->{subset})
                  ? ' < ' . $self->_dump_reftype($v->{subset})
                  : '';

                my $where_block =
                  exists($v->{where_block})
                  ? $self->deparse_expr({self => $v->{where_block}})
                  : '';

                my $where_expr =
                  exists($v->{where_expr})
                  ? '(' . $self->deparse_expr({self => $v->{where_expr}}) . ')'
                  : '';

                my $default =
                  exists($v->{value})
                  ? '=(' . $self->deparse_expr({self => $v->{value}}) . ')'
                  : '';

                $prefix . $class_prefix . $type_prefix . $v->{name} . $subset . $where_block . $where_expr . $default;
              } @vars
            );
    }

    sub _dump_init_vars {
        my ($self, $init_obj) = @_;

        my $type = $init_obj->{vars}[0]{type} // 'var';
        my $code = $type . '(' . $self->_dump_vars(@{$init_obj->{vars}}) . ')';

        $code .= '=' . $self->deparse_args($init_obj->{args})
          if exists $init_obj->{args};

        $code;
    }

    sub _dump_class_name {
        my ($self, $obj) = @_;

        return $self->_dump_reftype($obj->{name}) if ref($obj->{name});
        return ''                                 if $obj->{name} eq '';
        return $obj->{class} . '::' . $obj->{name};
    }

    # =========================================================================
    # Generic deparsing helpers
    # =========================================================================

    sub deparse_generic {
        my ($self, $before, $sep, $after, @args) = @_;

        $before
          . join($sep,
                 grep { $_ ne '' }
                 map  { ref($_) eq 'HASH' ? $self->deparse_script($_) : ref($_) ? $self->deparse_expr({self => $_}) : $self->_dump_string($_) } @args)
          . $after;
    }

    sub deparse_args {
        my ($self, @args) = @_;
        $self->deparse_generic('(', ', ', ')', @args);
    }

    sub deparse_bare_block {
        my ($self, @args) = @_;

        $Sidef::SPACES += $Sidef::SPACES_INCR;

        my $indent       = ' ' x $Sidef::SPACES;
        my $outer_indent = ' ' x ($Sidef::SPACES - $Sidef::SPACES_INCR);

        my $code = $self->deparse_generic("{(\n$indent", ");(\n$indent", "\n${outer_indent})}", @args);

        $Sidef::SPACES -= $Sidef::SPACES_INCR;
        $code;
    }

    # =========================================================================
    # deparse_expr node handlers (one per complex node type)
    # =========================================================================

    sub _deparse_variable {
        my ($self, $expr, $obj, $ref, $refaddr) = @_;

        my $type = $obj->{type};

        if (   $type eq 'var'
            || $type eq 'static'
            || $type eq 'const'
            || $type eq 'has'
            || $type eq 'global') {
            return $obj->{name} =~ /^[0-9]+\z/
              ? '$' . $obj->{name}
              : ($obj->{class} ne $self->{class} ? $obj->{class} . '::' : '') . $obj->{name};
        }

        if ($type eq 'func' || $type eq 'method') {
            if ($addr{$refaddr}++) {
                return $obj->{name} eq ''
                  ? '__FUNC__'
                  : ($obj->{class} ne $self->{class} ? $obj->{class} . '::' : '') . $obj->{name};
            }

            my $block = $obj->{value};
            my $code  = $type . ' ' . $obj->{name};

            local $self->{class} = $obj->{class};
            my $var_obj  = delete $block->{init_vars};
            my $skip     = ($type eq 'method') ? 1 : 0;
            my @sig_vars = @{$var_obj->{vars}}[$skip .. $#{$var_obj->{vars}}];

            $code .= '(' . $self->_dump_vars(@sig_vars) . ') ';
            $code .= 'is cached ' if exists $obj->{cached};

            if (exists $obj->{returns}) {
                my $ret = join(',', map { $self->deparse_expr({self => $_}) } @{$obj->{returns}});
                $code .= "-> ($ret) ";
            }

            $code .= $self->deparse_expr({self => $block});
            $block->{init_vars} = $var_obj;
            return $code;
        }

        return '';
    }

    sub _deparse_struct {
        my ($self, $expr, $obj, $ref, $refaddr) = @_;

        my $name = $self->_dump_class_name($obj);
        return $name if $addr{$refaddr}++;
        return "struct $name" . ' {' . $self->_dump_vars(@{$obj->{vars}}) . '}';
    }

    sub _deparse_subset {
        my ($self, $expr, $obj, $ref, $refaddr) = @_;

        my $name = $self->_dump_class_name($obj);
        return $name if $addr{$refaddr}++;

        my $inherits =
          exists($obj->{inherits})
          ? ' < ' . join(',', map { $self->deparse_expr({self => $_}) } @{$obj->{inherits}})
          : '';

        my $block =
          exists($obj->{block})
          ? ' ' . $self->deparse_expr({self => $obj->{block}})
          : '';

        return "subset $name$inherits$block";
    }

    sub _deparse_class_init {
        my ($self, $expr, $obj, $ref, $refaddr) = @_;

        return $self->_dump_class_name($obj) if $addr{$refaddr}++;

        local $self->{class} = $obj->{class};
        my $block      = $obj->{block};
        my $name       = $self->_dump_class_name($obj);
        my $class_vars = $self->_dump_vars(@{$obj->{vars}});
        my $code       = 'class ' . $name;

        $code .= "($class_vars)" if length($class_vars);

        if (exists $obj->{inherit}) {
            my $inherited = join(', ', grep { $_ ne $name }
                                   map { $self->_dump_class_name($_) } @{$obj->{inherit}});
            $code .= " < $inherited " if $inherited ne '';
        }

        $code .= $self->deparse_expr({self => $block});
        return $code;
    }

    sub _deparse_block_init {
        my ($self, $expr, $obj, $ref, $refaddr) = @_;

        if ($addr{$refaddr}++) {
            return keys(%{$obj}) ? '__BLOCK__' : 'Block';
        }

        return 'Block' unless keys %{$obj};

        my $code = '{';

        if (exists $obj->{init_vars}) {
            $code .= '|' . $self->_dump_vars(@{$obj->{init_vars}{vars}}) . '|';
        }

        $Sidef::SPACES += $Sidef::SPACES_INCR;
        my @statements = $self->deparse_script($obj->{code});

        $statements[-1] = '(' . $statements[-1] . ')' if @statements;

        if (@statements == 1 && length($statements[0]) + $Sidef::SPACES <= 80) {
            $code .= " $statements[0] }";
        }
        elsif (@statements) {
            my $indent       = ' ' x $Sidef::SPACES;
            my $outer_indent = ' ' x ($Sidef::SPACES - $Sidef::SPACES_INCR);
            $code .= "\n$indent" . join(";\n$indent", @statements) . "\n${outer_indent}}";
        }
        else {
            $code .= '}';
        }

        $Sidef::SPACES -= $Sidef::SPACES_INCR;
        return $code;
    }

    sub _deparse_if {
        my ($self, $expr, $obj) = @_;

        my $code = '';
        for my $i (0 .. $#{$obj->{if}}) {
            my $info = $obj->{if}[$i];
            $code .= ($i == 0 ? 'if' : 'elsif') . $self->deparse_args($info->{expr}) . $self->deparse_expr({self => $info->{block}});
        }

        $code .= 'else' . $self->deparse_bare_block($obj->{else}{block}{code})
          if exists $obj->{else};

        return $code;
    }

    sub _deparse_with {
        my ($self, $expr, $obj) = @_;

        my $code = '';
        for my $i (0 .. $#{$obj->{with}}) {
            my $info = $obj->{with}[$i];
            $code .= ($i == 0 ? 'with' : 'orwith') . $self->deparse_args($info->{expr}) . $self->deparse_expr({self => $info->{block}});
        }

        $code .= 'else' . $self->deparse_bare_block($obj->{else}{block}{code})
          if exists $obj->{else};

        return $code;
    }

    sub _deparse_for_in {
        my ($self, $expr, $obj) = @_;

        my $loops = join(
            ', ',
            map {
                my $loop = $_;
                join(',', map { ($_->{slurpy} ? ($_->{array} ? '*' : ':') : '') . $self->deparse_expr({self => $_}) } @{$loop->{vars}}) . ' in ('
                  . $self->deparse_expr({self => $loop->{expr}}) . ')'
            } @{$obj->{loops}}
        );

        return 'for ' . $loops . ' ' . $self->deparse_bare_block($obj->{block}{code});
    }

    sub _deparse_included {
        my ($self, $expr, $obj) = @_;

        my @statements;
        for my $info (@{$obj->{included}}) {
            if ($info->{name} ne '') {    # create a new namespace
                local $self->{class} = $info->{name};
                push @statements, "module $info->{name} " . $self->deparse_bare_block($info->{ast});
            }
            else {                        # included in the current namespace
                push @statements, join(";\n", $self->deparse_script($info->{ast}));
            }
        }

        return join(";\n", @statements);
    }

    # =========================================================================
    # deparse_expr: index and call application
    # =========================================================================

    sub _apply_indices {
        my ($self, $code, $expr) = @_;

        return $code unless exists $expr->{ind};

        $code = "($code)";
        for my $ind (@{$expr->{ind}}) {
            if (exists $ind->{array}) {
                $code .= $self->_dump_array($ind->{array});
            }
            else {
                $code .= '{' . join(',', map { ref($_) eq 'HASH' ? $self->deparse_expr($_) : $self->deparse_generic('', '', '', $_) } @{$ind->{hash}}) . '}';
            }
        }

        return $code;
    }

    # Attempt constant-folding for unary +/- applied to a literal number.
    # Returns the deparsed folded string, or undef if folding is not applicable.
    sub _try_fold_unary {
        my ($self, $ref, $code, $method, $call) = @_;

        return unless $ref eq 'Sidef::Operator::Unary' && $code eq '';

        state $unary_methods = {'-' => 'neg', '+' => undef};
        return unless exists $unary_methods->{$method};

        # Drill down through the argument structure to find a bare Number literal.
        my $data = $call->{arg};
        return unless @$data == 1;

        $data = $data->[0];
        return unless ref($data) eq 'HASH' && keys(%$data) == 1;

        my ($class) = keys(%$data);
        $data = $data->{$class};
        return unless ref($data) eq 'ARRAY' && @$data == 1;

        $data = $data->[0];
        $data = $data->{self}
          if ref($data) eq 'HASH' && keys(%$data) == 1 && exists $data->{self};

        return unless ref($data) eq 'Sidef::Types::Number::Number';

        my $method_name = $unary_methods->{$method};
        return
          $self->deparse_expr(
                              {
                               self => defined($method_name) ? $data->$method_name : $data
                              }
                             );
    }

    sub _apply_calls {
        my ($self, $code, $expr, $ref) = @_;

        return $code unless exists $expr->{call};

        for my $i (0 .. $#{$expr->{call}}) {
            my $call   = $expr->{call}[$i];
            my $method = $call->{method};

            # A method literally named 'call' with arguments: treat as bare invocation.
            if (defined $method && $method eq 'call' && exists $call->{arg}) {
                $code = "($code)"
                  if substr($code, 0, 1) eq '(' && substr($code, -1) eq ')';
                undef $method;
            }

            if (defined $method) {

                # Prefix-colon shorthand (first call only)
                if ($i == 0 && $ref eq 'Sidef::Meta::PrefixColon' && $method eq ':') {
                    $code = ':' . $self->deparse_args(@{$call->{arg}});
                    next;
                }

                if (ref($method) ne '') {

                    # Dynamic/computed method expression
                    $code .= '->(' . $self->deparse_expr(ref($method) eq 'HASH' ? $method : {self => $method}) . ')';
                }
                elsif ($method =~ /^[^\W\d]/) {

                    # Named (word) method
                    if ($ref eq 'Sidef::Types::Block::BlockInit' && $method eq 'loop') {
                        $code = "loop $code";
                    }
                    else {
                        $code .= '->' if $code ne '';
                        $code .= $method;
                    }
                    $code .= '()' unless exists $call->{arg};
                }
                else {
                    # Operator method — try constant-folding first
                    if (defined(my $folded = $self->_try_fold_unary($ref, $code, $method, $call))) {
                        $code = $folded;
                        next;
                    }

                    if ($ref eq 'Sidef::Variable::Ref' || $ref eq 'Sidef::Operator::Unary') {
                        $code .= $method;
                    }
                    else {
                        $code = "($code)->$method";
                    }
                }
            }

            # Optional keyword prefix before argument list
            if (exists $call->{keyword}) {
                if ($code ne '') {
                    if (substr($code, 0, 1) eq '(' && substr($code, -1) eq ')') {
                        $code = "($code)";
                    }
                    else {
                        $code .= ' ';
                    }
                }
                $code .= $call->{keyword};
            }

            $code .= $self->deparse_args(@{$call->{arg}}) if exists $call->{arg};

            if (exists $call->{block}) {
                $code .= $self->deparse_bare_block(@{$call->{block}});
                next;
            }
        }

        return $code;
    }

    # =========================================================================
    # Dispatch table: ref type → handler (populated after all handlers defined)
    # =========================================================================

    my %EXPR_DISPATCH;

    # =========================================================================
    # Main expression deparsing entry point
    # =========================================================================

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $obj     = $expr->{self};
        my $ref     = ref($obj);
        my $refaddr = refaddr($obj);
        my $code    = '';

        if ($ref eq 'HASH') {
            $code = join(
                         ', ', exists($obj->{self})
                         ? $self->deparse_expr($obj)
                         : $self->deparse_script($obj)
                        );
            $code = "($code)" if $self->{extra_parens};
        }
        elsif (my $handler = $EXPR_DISPATCH{$ref}) {
            $code = $self->$handler($expr, $obj, $ref, $refaddr);
        }
        elsif (exists $self->{data_types}{$ref}) {
            $code = $self->{data_types}{$ref};
        }
        elsif ($ref =~ /^Sidef::/ && UNIVERSAL::can($obj, 'dump')) {
            $code = $obj->dump->get_value;
        }

        $code = $self->_apply_indices($code, $expr);
        $code = $self->_apply_calls($code, $expr, $ref);

        return $code;
    }

    # =========================================================================
    # Top-level deparse methods
    # =========================================================================

    sub deparse_script {
        my ($self, $struct) = @_;

        my @results;
        for my $class (keys %$struct) {
            for my $i (0 .. $#{$struct->{$class}}) {
                my $expr = $struct->{$class}[$i];
                push @results, ref($expr) eq 'HASH'
                  ? $self->deparse_expr($expr)
                  : $self->deparse_expr({self => $expr});
            }
        }

        wantarray ? @results : $results[-1];
    }

    sub deparse {
        my ($self, $struct) = @_;
        my @statements = $self->deparse_script($struct);
        $self->{before} . join($self->{between}, grep { $_ ne '' } @statements) . $self->{after};
    }

    # =========================================================================
    # Populate dispatch table (all handlers must be defined above this point)
    # =========================================================================

    {
        # Shared handler: classes that deparse as "ClassName::memberName"
        my $class_or_name = sub {
            my ($self, $expr, $obj) = @_;
            ($obj->{class} ne $self->{class} ? $obj->{class} . '::' : '') . $obj->{name};
        };

        # Shared handler: Array and HCArray both deparse via _dump_array
        my $dump_array = sub {
            my ($self, $expr, $obj) = @_;
            $self->_dump_array($obj);
        };

        %EXPR_DISPATCH = (

            # --- Variables ---------------------------------------------------

            'Sidef::Variable::Variable' => \&_deparse_variable,

            'Sidef::Variable::ClassAttr' => sub { $_[0]->_dump_init_vars($_[2]) },

            'Sidef::Variable::Init' => sub { $_[0]->_dump_init_vars($_[2]) },

            'Sidef::Variable::ConstInit' => sub {
                my ($self, $expr, $obj) = @_;
                my $sep =
                  $obj->{type} eq 'global'
                  ? ', '
                  : ";\n" . ' ' x $Sidef::SPACES;
                join($sep, $self->_dump_init_vars($obj));
            },

            'Sidef::Variable::Const'  => $class_or_name,
            'Sidef::Variable::Static' => $class_or_name,
            'Sidef::Variable::Define' => $class_or_name,

            'Sidef::Variable::ClassVar' => sub {
                my ($self, $expr, $obj) = @_;
                $self->_dump_reftype($obj->{class}) . '!' . $obj->{name};
            },

            'Sidef::Variable::Local' => sub {
                my ($self, $expr, $obj) = @_;
                'local (' . $self->deparse_script($obj->{expr}) . ')';
            },

            'Sidef::Variable::NamedParam' => sub {
                my ($self, $expr, $obj) = @_;
                $obj->{name} . ':' . $self->deparse_args(@{$obj->{value}});
            },

            'Sidef::Variable::Label' => sub {
                my ($self, $expr, $obj) = @_;
                '@:' . $obj->{name};
            },

            'Sidef::Variable::Ref' => sub {
                my ($self, $expr) = @_;
                exists($expr->{call}) ? '' : 'Ref';
            },

            'Sidef::Variable::Magic' => sub {
                my ($self, $expr, $obj) = @_;
                $obj->{dump} // $obj->{name};
            },

            # --- Classes and structures --------------------------------------

            'Sidef::Variable::ClassInit' => \&_deparse_class_init,
            'Sidef::Variable::Struct'    => \&_deparse_struct,
            'Sidef::Variable::Subset'    => \&_deparse_subset,

            # --- Blocks ------------------------------------------------------

            'Sidef::Types::Block::BlockInit' => \&_deparse_block_init,

            'Sidef::Types::Block::Return' => sub {
                my ($self, $expr) = @_;
                exists($expr->{call}) ? '' : 'return';
            },

            'Sidef::Types::Block::Do' => sub {
                my ($self, $expr, $obj) = @_;
                'do ' . $self->deparse_expr({self => $obj->{block}});
            },

            'Sidef::Types::Block::Loop' => sub {
                my ($self, $expr, $obj) = @_;
                'loop ' . $self->deparse_expr({self => $obj->{block}});
            },

            'Sidef::Types::Block::Try' => sub {
                my ($self, $expr, $obj) = @_;
                my $code = 'try ' . $self->deparse_expr({self => $obj->{try}});
                $code .= ' catch ' . $self->deparse_expr({self => $obj->{catch}})
                  if defined $obj->{catch};
                $code;
            },

            'Sidef::Types::Block::If' => \&_deparse_if,

            'Sidef::Types::Block::While' => sub {
                my ($self, $expr, $obj) = @_;
                'while' . $self->deparse_args($obj->{expr}) . $self->deparse_expr({self => $obj->{block}});
            },

            'Sidef::Types::Block::ForEach' => sub {
                my ($self, $expr, $obj) = @_;
                'foreach' . $self->deparse_args($obj->{expr}) . $self->deparse_expr({self => $obj->{block}});
            },

            'Sidef::Types::Block::CFor' => sub {
                my ($self, $expr, $obj) = @_;
                'for(' . join(';', map { $self->deparse_args($_) } @{$obj->{expr}}) . ')' . $self->deparse_bare_block($obj->{block}{code});
            },

            'Sidef::Types::Block::ForIn' => \&_deparse_for_in,

            'Sidef::Types::Block::Given' => sub {
                my ($self, $expr, $obj) = @_;
                'given ' . $self->deparse_args($obj->{expr}) . $self->deparse_expr({self => $obj->{block}});
            },

            'Sidef::Types::Block::When' => sub {
                my ($self, $expr, $obj) = @_;
                'when(' . $self->deparse_args($obj->{expr}) . ')' . $self->deparse_expr({self => $obj->{block}});
            },

            'Sidef::Types::Block::Case' => sub {
                my ($self, $expr, $obj) = @_;
                'case(' . $self->deparse_args($obj->{expr}) . ')' . $self->deparse_expr({self => $obj->{block}});
            },

            'Sidef::Types::Block::Default' => sub {
                my ($self, $expr, $obj) = @_;
                'default' . $self->deparse_bare_block($obj->{block}{code});
            },

            'Sidef::Types::Block::With' => \&_deparse_with,

            'Sidef::Types::Block::Gather' => sub {
                my ($self, $expr, $obj) = @_;
                'gather ' . $self->deparse_expr({self => $obj->{block}});
            },

            'Sidef::Types::Block::Take' => sub {
                my ($self, $expr, $obj) = @_;
                'take' . $self->deparse_args($obj->{expr});
            },

            # --- Control flow / ternary --------------------------------------

            'Sidef::Types::Bool::Ternary' => sub {
                my ($self, $expr, $obj) = @_;
                '(' . $self->deparse_script($obj->{cond}) . ' ? ' . $self->deparse_args($obj->{true}) . ' : ' . $self->deparse_args($obj->{false}) . ')';
            },

            # --- Meta / special syntax ---------------------------------------

            'Sidef::Meta::PrefixMethod' => sub {
                my ($self, $expr, $obj) = @_;
                "::$obj->{name}" . $self->deparse_args($obj->{expr});
            },

            'Sidef::Meta::Assert' => sub {
                my ($self, $expr, $obj) = @_;
                $obj->{act} . $self->deparse_args($obj->{arg});
            },

            'Sidef::Meta::Error' => sub {
                my ($self, $expr, $obj) = @_;
                'die' . $self->deparse_args($obj->{arg});
            },

            'Sidef::Meta::Warning' => sub {
                my ($self, $expr, $obj) = @_;
                'warn' . $self->deparse_args($obj->{arg});
            },

            'Sidef::Meta::Module' => sub {
                my ($self, $expr, $obj) = @_;
                local $self->{class} = $obj->{name};
                "module $obj->{name} " . $self->deparse_bare_block($obj->{block}{code});
            },

            'Sidef::Meta::Included' => \&_deparse_included,

            'Sidef::Meta::Glob::DATA' => sub {
                my ($self, $expr, $obj) = @_;
                if (!exists $addr{$obj->{data}}) {
                    $self->{after} .= "\n__DATA__\n" . ${$obj->{data}};
                    $addr{$obj->{data}} = 1;
                }
                'DATA';
            },

            # --- Eval --------------------------------------------------------

            'Sidef::Eval::Eval' => sub {
                my ($self, $expr, $obj) = @_;
                'eval' . $self->deparse_args($obj->{expr});
            },

            # --- Module imports ----------------------------------------------

            'Sidef::Module::OO' => sub {
                my ($self, $expr, $obj) = @_;
                '%O' . $self->_dump_string($obj->{module});
            },

            'Sidef::Module::Func' => sub {
                my ($self, $expr, $obj) = @_;
                '%S' . $self->_dump_string($obj->{module});
            },

            # --- Literal data types ------------------------------------------

            'Sidef::Types::Number::Number' => sub {
                my ($self, $expr, $obj) = @_;
                $self->_dump_number($obj);
            },

            'Sidef::Types::Array::Array'   => $dump_array,
            'Sidef::Types::Array::HCArray' => $dump_array,

            'Sidef::Types::Array::List' => sub {
                my ($self, $expr, $obj) = @_;
                join(', ', map { $self->deparse_expr({self => $_}) } @{$obj});
            },

            'Sidef::Types::Hash::Hash' => sub {
                my ($self, $expr, $obj) = @_;
                $obj->dump->get_value;
            },
        );
    }
};

1;
