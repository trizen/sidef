package Sidef::Deparse::Sidef;

use utf8;
use 5.016;

use Scalar::Util qw(refaddr);

use Sidef::Parser ();

# ---------------------------------------------------------------------------
# Sidef::Deparse::Sidef
#
# Converts the AST created by Sidef::Parser back into (human-readable) Sidef code.
#
# The purpose of the generated code is to show how the parser understands the program: the
# precedence of the operators is never used. Every operator expression that is the operand
# of another operator is parenthesized, so `1 + 2 * 3` is written as `1 + (2 * 3)`, and
# `a - b - c` as `(a - b) - c`. The parser creates the same AST from the generated code.
#
# Every expression is deparsed into a pair:
#
#     ($code, $precedence)
#
# where $precedence is the binding strength of the outermost construct of $code (see
# Sidef::Parser::infix_precedence). It is used for deciding when the parentheses are required
# (an operand that is not an atom is always parenthesized, including the right-hand side of
# `var x = ...` and the argument of `return`).
#
# Overview of the AST (see Sidef::Parser):
#
#   script    = { namespace => [ statement, ... ] }
#   statement = { self => OBJECT | script, call => [ ... ], ind => [ ... ] }
#   call      = { method => NAME, arg => [ ... ] }   a method call, an operator or a hyper-operator
#             | { keyword => if|while|and|or, arg => [ expr ] }
#   ind       = { array => [ statement, ... ] } | { hash => [ statement, ... ] }
#
# The index operations are applied first, and then the calls.
#
# Options of the constructor:
#
#   before, between, after   text placed before, between and after the statements
#   class                    the current namespace (default: main)
#   indent                   number of spaces used for each level of indentation (default: 4)
#   data_types               maps the name of a Perl class to the name of the type in Sidef
# ---------------------------------------------------------------------------

use constant {
    P_ASSIGN  => Sidef::Parser::PREC_ASSIGN(),
    P_TERNARY => Sidef::Parser::PREC_TERNARY(),
    P_WORD_OP => Sidef::Parser::PREC_WORD_OP(),

    # `return x`, `var x = 1`, ...: a prefix keyword followed by an expression
    P_RETURN => Sidef::Parser::PREC_ASSIGN() - 1,

    # `-x`, `!x`, `\x`, ...: a prefix operator applied on an operand
    P_PREFIX => Sidef::Parser::PREC_OPERAND() + 1,

    # literals, variables, calls, indices, parenthesized expressions, blocks
    P_ATOM => Sidef::Parser::PREC_OPERAND() + 2,
};

# =========================================================================
# Sidef internal class name → Sidef source type name
# =========================================================================

my %DATA_TYPES = qw(
  Sidef::DataTypes::Bool::Bool                   Bool
  Sidef::DataTypes::Array::Array                 Array
  Sidef::DataTypes::Array::Pair                  Pair
  Sidef::DataTypes::Array::Vector                Vector
  Sidef::DataTypes::Array::Matrix                Matrix
  Sidef::DataTypes::Hash::Hash                   Hash
  Sidef::DataTypes::Set::Set                     Set
  Sidef::DataTypes::Set::Bag                     Bag
  Sidef::DataTypes::Regex::Regex                 Regex
  Sidef::DataTypes::String::String               String
  Sidef::DataTypes::Number::Number               Number
  Sidef::DataTypes::Number::Mod                  Mod
  Sidef::DataTypes::Number::Gauss                Gauss
  Sidef::DataTypes::Number::Quadratic            Quadratic
  Sidef::DataTypes::Number::Quaternion           Quaternion
  Sidef::DataTypes::Number::Complex              Complex
  Sidef::DataTypes::Number::Polynomial           Polynomial
  Sidef::DataTypes::Number::PolynomialMod        PolynomialMod
  Sidef::DataTypes::Number::Fraction             Fraction
  Sidef::DataTypes::Range::Range                 Range
  Sidef::DataTypes::Range::RangeNumber           RangeNum
  Sidef::DataTypes::Range::RangeString           RangeStr
  Sidef::DataTypes::Block::Block                 Block
  Sidef::DataTypes::Glob::Socket                 Socket
  Sidef::DataTypes::Glob::Pipe                   Pipe
  Sidef::DataTypes::Glob::Backtick               Backtick
  Sidef::DataTypes::Glob::DirHandle              DirHandle
  Sidef::DataTypes::Glob::FileHandle             FileHandle
  Sidef::DataTypes::Glob::SocketHandle           SocketHandle
  Sidef::DataTypes::Glob::Dir                    Dir
  Sidef::DataTypes::Glob::File                   File
  Sidef::DataTypes::Perl::Perl                   Perl
  Sidef::DataTypes::Object::Object               Object
  Sidef::DataTypes::Sidef::Sidef                 Sidef
  Sidef::DataTypes::Object::Lazy                 Lazy
  Sidef::DataTypes::Object::LazyMethod           LazyMethod
  Sidef::DataTypes::Object::Enumerator           Enumerator
  Sidef::DataTypes::Variable::NamedParam         NamedParam

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
# Operator tables
# =========================================================================

# Postfix operators that are not followed by an operand
my %POSTFIX_OPS = map { $_ => 1 } qw(-- ++ ... ! !!);

# Operators of the range family are written without spaces: 1..10
my %TIGHT_OPS = map { $_ => 1 } qw(.. ^.. ..^);

# Prefix operators that are written in the function style: say(x), @(x), ...
# (the argument is always parenthesized, which makes them behave like a function call).
my %FUNCTION_STYLE = map { $_ => 1 } ('say', 'print', 'defined', '>', '>>', '+', '@', '@|', ':');

# Objects that start a call chain with a prefix operator: `-x`, `\x`, `:(x)`, `return x`, ...
my %PREFIX_CLASS = map { $_ => 1 } qw(
  Sidef::Operator::Unary
  Sidef::Variable::Ref
  Sidef::Meta::PrefixColon
  Sidef::Types::Block::Return
  Sidef::Perl::Builtin
);

# Hyper-operators, as they are stored in the AST: method name => [syntax of the binary form, postfix form]
#
#   %s is replaced with the operator (e.g.: `+` or `add`)
#
# See %HYPER_OPS and $OPERATORS_RE in Sidef::Parser.
my %HYPER_OPS = (
                 map_operator     => ['»%s»',  '»%s()»'],
                 pam_operator     => ['«%s«',  undef],
                 unroll_operator  => ['»%s«',  undef],
                 reduce_operator  => [undef,   '«%s»'],
                 zip_operator     => ['~Z%s',  undef],
                 wise_operator    => ['~W%s',  undef],
                 scalar_operator  => ['~S%s',  undef],
                 rscalar_operator => ['~RS%s', undef],
                 cross_operator   => ['~X%s',  undef],
                );

# Interpolated strings: "text #{expr}", %X"command #{expr}", %Perl"code #{expr}"
#
# The command and the Perl code are executed automatically (the call of the method `run` is part of the syntax).
my %INTERPOLATED = (
    'Sidef::DataTypes::String::String' => ['',      0],
    'Sidef::DataTypes::Glob::File'     => ['%F',    0],
    'Sidef::DataTypes::Glob::Dir'      => ['%D',    0],
    'Sidef::DataTypes::Glob::Backtick' => ['%X',    1],
    'Sidef::DataTypes::Perl::Perl'     => ['%Perl', 1],
                   );

# =========================================================================
# Constructor
# =========================================================================

sub new {
    my (undef, %args) = @_;

    my %opts = (
                before     => '',
                between    => "\n",
                after      => "\n",
                class      => 'main',
                indent     => 4,
                opt        => {},
                data_types => {%DATA_TYPES},
                %args,
               );

    # Internal state of a deparse run
    $opts{_seen}      = {};    # the ref addresses of the definitions that were already deparsed (avoids infinite recursion)
    $opts{_depth}     = 0;     # the current level of indentation
    $opts{_in_interp} = 0;     # true inside "#{...}"

    bless \%opts, __PACKAGE__;
}

# =========================================================================
# Small helpers
# =========================================================================

# Wraps the code in parentheses when its precedence is lower than $min.
sub _paren_if {
    my ($code, $prec, $min) = @_;
    return ($code,     $prec) if $prec >= $min;
    return ("($code)", P_ATOM);
}

# The code ends with a method name that has no arguments, such as: `x.foo`
sub _ends_bare {
    my ($code) = @_;
    $code =~ /(?<!\.)\.[^\W\d]\w*+!?\z/;
}

sub _indent_str {
    my ($self, $extra) = @_;
    ' ' x (($self->{_depth} + ($extra // 0)) * $self->{indent});
}

# Returns the object wrapped by redundant groups, such as: {self => {main => [{self => OBJ}]}}
# A group that can't be simplified is returned as it is.
sub _peel {
    my ($x) = @_;

    while (ref($x) eq 'HASH') {
        if (exists $x->{self}) {
            return $x if keys(%$x) != 1;
            $x = $x->{self};
        }
        else {
            my @statements = map { ref($_) eq 'ARRAY' ? @{$_} : () } values %$x;
            return $x if @statements != 1;
            $x = $statements[0];
        }
    }

    return $x;
}

# The statements of a script: { namespace => [ statement, ... ] }
sub _statements {
    my ($self, $script) = @_;
    map { ref($script->{$_}) eq 'ARRAY' ? @{$script->{$_}} : () } sort keys %$script;
}

# =========================================================================
# Strings and numbers
# =========================================================================

my %ESCAPES = (
               "\\" => '\\\\',
               '"'  => '\\"',
               "\n" => '\\n',
               "\t" => '\\t',
               "\r" => '\\r',
               "\e" => '\\e',
               "\a" => '\\a',
               "\f" => '\\f',
              );

# Escapes a string for being used inside double quotes
sub _escape {
    my ($self, $str) = @_;

    $str =~ s{([\\"\n\t\r\e\a\f])}{$ESCAPES{$1}}g;
    $str =~ s{#(?=\{)}{\\#}g;                                                                   # no interpolation
    $str =~ s{([\x00-\x1f\x7f-\x9f\x{2028}\x{2029}\x{FEFF}])}{sprintf('\\x{%x}', ord($1))}ge;

    return $str;
}

sub _dump_string {
    my ($self, $str) = @_;
    return '"' . $self->_escape($str) . '"';
}

# Returns the code of a number object and its precedence
sub _number_code {
    my ($self, $num) = @_;

    my ($type, $str) = $num->_dump;

    state $table = {
                    '@inf@'  => 'Inf',
                    '-@inf@' => '-Inf',
                    '@nan@'  => 'NaN',
                    'inf'    => 'Inf',
                    '-inf'   => '-Inf',
                    'nan'    => 'NaN',
                   };

    state $special_values = {
                             '@inf@'  => Sidef::Types::Number::Number->inf,
                             '-@inf@' => Sidef::Types::Number::Number->ninf,
                             '@nan@'  => Sidef::Types::Number::Number->nan,
                            };

    my $code;

    if ($type eq 'complex') {
        my ($real, $imag) =
          map { ($self->_number_code($special_values->{lc($_)} // Sidef::Types::Number::Number->new($_)))[0] }
          split(' ', substr($str, 1, -1));

        $code = (
                 ($real eq '0' and $imag =~ /^[0-9]+(?:\.[0-9]+)?\z/)
                 ? $imag . 'i'
                 : "Complex($real, $imag)"
                );
    }
    elsif (exists $table->{lc($str)}) {
        $code = $table->{lc($str)};
    }
    elsif ($type eq 'float') {
        $code = $str . 'f';
    }
    elsif (index($str, '/') != -1) {
        $code = qq{Number("$str")};
    }
    else {
        $code = $str;
    }

    return ($code, ($code =~ /^-/ ? P_PREFIX : P_ATOM));
}

# Returns the name of the type of an object: Str, Num, MyClass, ...
sub _dump_reftype {
    my ($self, $obj) = @_;

    my $ref = ref($obj);

    return $self->{data_types}{$ref}
      if exists $self->{data_types}{$ref};

    return $self->_class_name($obj)
      if $ref eq 'Sidef::Variable::ClassInit'
      || $ref eq 'Sidef::Variable::Struct'
      || $ref eq 'Sidef::Variable::Subset';

    return 'Block'
      if $ref eq 'Sidef::Types::Block::BlockInit';

    return substr($ref, rindex($ref, '::') + 2);
}

# The name of a class, struct or subset (qualified when it's from another namespace)
sub _class_name {
    my ($self, $obj) = @_;

    my $name = $obj->{name};

    return $self->_dump_reftype($name) if ref($name);
    return ''                          if !defined($name) or $name eq '';

    # A class with the name of a built-in class must be qualified (main::String)
    if (Sidef::Parser::is_built_in_class($name)) {
        return ($obj->{class} // $self->{class}) . '::' . $name;
    }

    return $self->_qualified($obj->{class}, $name);
}

sub _qualified {
    my ($self, $class, $name) = @_;
    (defined($class) && $class ne $self->{class}) ? "${class}::$name" : $name;
}

# =========================================================================
# Declarations: variables, parameters and attributes
# =========================================================================

# A parameter or a variable that has an extra information, which requires the parenthesized syntax
sub _has_extras {
    my ($v) = @_;
    scalar grep { exists $v->{$_} } qw(value subset where_block where_expr);
}

# The variable is the topic variable `_` of a block, without any other attribute
sub _is_topic_var {
    my ($v) = @_;
    $v->{name} eq '_' and not grep { exists $v->{$_} } qw(value subset where_block where_expr ref_type array hash);
}

# Declaration of one variable: `Str name < Subset {...}(...) = value`
sub _var_decl {
    my ($self, $v) = @_;

    my $code = '';

    $code .= '*' if exists $v->{array};
    $code .= ':' if exists $v->{hash};

    $code .= $self->_qualified($v->{class}, '');

    if (exists($v->{ref_type}) and ($v->{type} eq 'var' or $v->{type} eq 'has')) {
        $code .= $self->_dump_reftype($v->{ref_type}) . ' ';
    }

    $code .= $v->{name};

    if (exists $v->{subset}) {
        $code .= ' < ' . $self->_dump_reftype($v->{subset});
    }

    if (exists $v->{where_block}) {
        $code .= ' ' . $self->_block($v->{where_block}, topic => 1);
    }

    if (exists $v->{where_expr}) {
        $code .= '(' . join(', ', $self->_stmts($v->{where_expr})) . ')';
    }

    if (exists $v->{value}) {
        my ($c, $p) = $self->_any($v->{value});
        ($c) = _paren_if($c, $p, P_ATOM);
        $code .= ' = ' . $c;
    }

    return $code;
}

# Declaration of a list of variables
sub _vars_code {
    my ($self, @vars) = @_;
    join(', ', map { $self->_var_decl($_) } @vars);
}

# =========================================================================
# Statements, groups and arguments
# =========================================================================

# Returns the code of each statement of a script (the empty statements are removed)
sub _stmts {
    my ($self, $script) = @_;

    my @results;
    foreach my $statement ($self->_statements($script)) {

        my $obj = _peel($statement);

        # The included files are spliced into the list of statements
        if (ref($obj) eq 'Sidef::Meta::Included') {
            push @results, $self->_included_statements($obj);
        }
        else {
            push @results, ($self->_any($statement))[0];
        }
    }

    return grep { $_ ne '' } @results;
}

# Deparses a statement, a group of statements or an object: ($code, $precedence)
sub _any {
    my ($self, $x) = @_;

    if (ref($x) eq 'HASH') {
        return exists($x->{self}) ? $self->_node($x) : $self->_group($x);
    }

    return $self->_node({self => $x});
}

# A group is the result of parenthesized expressions: (a, b, c)
# A group with only one statement is the same as the statement.
sub _group {
    my ($self, $script) = @_;

    my @items = grep { $_->[0] ne '' } map { [$self->_any($_)] } $self->_statements($script);

    @items or return ('()', P_ATOM);
    @items == 1 and return @{$items[0]};

    return ('(' . join(', ', map { $_->[0] } @items) . ')', P_ATOM);
}

# The code of the arguments of a call, without the parentheses
sub _args_code {
    my ($self, @args) = @_;

    return
      join(', ', grep { $_ ne '' }
             map { ref($_) eq 'HASH' ? $self->_stmts($_) : ref($_) ? ($self->_any($_))[0] : $self->_dump_string($_) } @args);
}

# The code of the elements of an array (each element is a statement or an object)
sub _elements_code {
    my ($self, @elements) = @_;
    return join(', ', grep { $_ ne '' } map { ($self->_any($_))[0] } @elements);
}

# The condition of a control-flow statement: (a, b)
sub _cond {
    my ($self, $expr) = @_;
    '(' . join(', ', ref($expr) eq 'HASH' ? $self->_stmts($expr) : (($self->_any($expr))[0])) . ')';
}

# The expression of a `for x in EXPR {...}` loop, which is parenthesized only when it's necessary
sub _loop_expr {
    my ($self, $expr) = @_;

    my @statements = $self->_statements($expr);

    if (@statements == 1) {
        my ($code, $prec) = $self->_any($expr);

        # `(...)` is parsed alone, and `x.method {...}` would be parsed as a call with a block
        if ($prec >= P_ATOM and $code !~ /^\(/ and $code !~ /\n/ and $code !~ /\}\z/ and not _ends_bare($code)) {
            return $code;
        }

        return "($code)";
    }

    return $self->_cond($expr);
}

# =========================================================================
# Blocks
# =========================================================================

# Joins the statements of a script or of a block.
# A blank line is added around the definitions (functions, classes, ...) and around
# the multi-line statements of the top-level.
sub _join_statements {
    my ($self, $statements, $between, $indent) = @_;

    $indent //= '';

    my $code = '';
    my $prev;

    foreach my $statement (@{$statements}) {

        if (defined $prev) {
            my $blank = 0;

            if ($between eq "\n") {
                my $multiline  = sub { $_[0] =~ /\n/ };
                my $definition = sub { $_[0] =~ /^(?:func|method|class|module|struct|subset)\b/ and $_[0] =~ /\n/ };
                $blank = 1 if ($definition->($prev) or $definition->($statement));
                $blank = 1 if (!length($indent) and ($multiline->($prev) or $multiline->($statement)));
            }

            $code .= $between . ($blank ? "\n" : '');
        }

        $code .= $indent . $statement;
        $prev = $statement;
    }

    return $code;
}

# Creates the code of a block, from the code of its parameters and of its statements.
#
# Options: multiline (always put the statements on separate lines)
sub _block_text {
    my ($self, $params, $statements, %opt) = @_;

    my $header = ($params ne '' ? " $params" : '');

    if (!@{$statements}) {
        return '{' . ($params ne '' ? "$header " : '') . '}';
    }

    if (    @{$statements} == 1
        and not $opt{multiline}
        and $statements->[0] !~ /\n/
        and length($statements->[0]) <= 70) {
        return '{' . ($params ne '' ? "$header " : ' ') . $statements->[0] . ' }';
    }

    my $inner = $self->_indent_str(1);
    return '{' . $header . "\n" . $self->_join_statements($statements, "\n", $inner) . "\n" . $self->_indent_str(0) . '}';
}

# Deparses a block object (Sidef::Types::Block::BlockInit)
#
# Options:
#   topic     the block was parsed with the topic variable `_`, which is not written
#   params    write the parameters of the block (default: true)
#   multiline see _block_text()
sub _block {
    my ($self, $block, %opt) = @_;

    keys(%{$block}) || return 'Block';

    if ($self->{_seen}{refaddr($block)}++) {
        return '__BLOCK__';
    }

    my $params = '';
    if (($opt{params} // 1) and exists $block->{init_vars}) {
        my @vars = @{$block->{init_vars}{vars}};
        if (not($opt{topic} and @vars == 1 and _is_topic_var($vars[0]))) {
            $params = '|' . $self->_vars_code(@vars) . '|';
        }
    }

    my @statements = do {
        local $self->{_depth} = $self->{_depth} + 1;
        $self->_stmts($block->{code} // {});
    };

    return $self->_block_text($params, \@statements, multiline => $opt{multiline});
}

# A block that is parsed without parameters (the body of a control-flow statement)
sub _body {
    my ($self, $block) = @_;
    $self->_block($block, params => 0, multiline => 1);
}

# Deparses a script as the content of a block
sub _script_block {
    my ($self, $script, %opt) = @_;

    my @statements = do {
        local $self->{_depth} = $self->{_depth} + 1;
        $self->_stmts($script);
    };

    return $self->_block_text('', \@statements, %opt);
}

# =========================================================================
# Handlers for the objects that can be the `self` of an expression
#
# Each handler returns ($code, $precedence).
# =========================================================================

sub _h_variable {
    my ($self, $obj) = @_;

    my $type = $obj->{type};

    if ($type eq 'func' or $type eq 'method') {
        return $self->_h_function($obj);
    }

    return (
              ($obj->{name} =~ /^[0-9]+\z/)
            ? ('$' . $obj->{name})
            : $self->_qualified($obj->{class}, $obj->{name}), P_ATOM
           );
}

# The definition of a function or of a method (or a reference to it, inside its own body)
sub _h_function {
    my ($self, $obj) = @_;

    my $type = $obj->{type};
    my $name = $obj->{name};

    if ($self->{_seen}{refaddr($obj)}++) {
        return (($name eq '' ? ($type eq 'method' ? '__METHOD__' : '__FUNC__') : $self->_qualified($obj->{class}, $name)), P_ATOM);
    }

    my $block = $obj->{value};
    my @vars  = @{$block->{init_vars}{vars} // []};

    shift(@vars) if $type eq 'method';    # the first variable is `self`

    my $code = $type;
    $code .= ' ' . $self->_qualified($obj->{class}, $name) if $name ne '';
    my $params = $self->_vars_code(@vars);
    $code .= "($params)"  if ($params ne '' or $name eq '');
    $code .= ' is cached' if exists $obj->{cached};

    if (exists $obj->{returns}) {
        my @types = map { ($self->_any($_))[0] } @{$obj->{returns}};
        $code .= ' -> ' . (@types == 1 ? $types[0] : '(' . join(', ', @types) . ')');
    }

    $code .= ' ' . $self->_body($block);

    return ($code, P_ATOM);
}

sub _h_init {
    my ($self, $obj) = @_;

    my @vars = @{$obj->{vars}};
    my $type = $vars[0]{type} // 'var';

    my $code = $type . ' ';

    if (@vars == 1 and not grep { _has_extras($_) } @vars) {
        $code .= $self->_vars_code(@vars);
    }
    else {
        $code .= '(' . $self->_vars_code(@vars) . ')';
    }

    if (exists $obj->{args}) {
        my ($c, $p) = $self->_any($obj->{args});
        ($c) = _paren_if($c, $p, P_ATOM);
        $code .= ' = ' . $c;
    }

    return ($code, P_RETURN);
}

# const, static and define
sub _h_const_init {
    my ($self, $obj) = @_;

    my @vars = @{$obj->{vars}};
    my $type = $obj->{type} // $vars[0]{type};

    my $code = $type . ' ';

    if (@vars == 1 and not grep { exists $vars[0]{$_} } qw(subset where_block where_expr)) {
        $code .= $self->_vars_code(@vars);
    }
    else {
        $code .= '(' . $self->_vars_code(@vars) . ')';
    }

    return ($code, P_RETURN);
}

sub _h_named_param {
    my ($self, $obj) = @_;

    # The value is parenthesized, unless it's an atom: name: (a + b)
    my $value = join(', ', map { my ($c, $p) = $self->_any($_); (_paren_if($c, $p, P_ATOM))[0] } @{$obj->{value}});

    return ($obj->{name} . ': ' . $value, P_ASSIGN);
}

sub _h_class_init {
    my ($self, $obj) = @_;

    my $name = $self->_class_name($obj);

    if ($self->{_seen}{refaddr($obj)}++) {
        return ($name ne '' ? $name : '__CLASS__', P_ATOM);
    }

    my $code = 'class';
    $code .= ' ' . $name if $name ne '';

    my $params = $self->_vars_code(@{$obj->{vars} // []});
    $code .= "($params)" if $params ne '';

    if (exists $obj->{inherit}) {
        my @parents = grep { $_ ne $name and $_ ne '' }
          map { ref($_) eq 'Sidef::Variable::ClassInit' ? $self->_class_name($_) : $self->_dump_reftype($_) } @{$obj->{inherit}};
        $code .= ' < ' . join(', ', @parents) if @parents;
    }

    $code .= ' ' . $self->_body($obj->{block});

    return ($code, P_ATOM);
}

sub _h_struct {
    my ($self, $obj) = @_;

    my $name = $self->_class_name($obj);

    return ($name, P_ATOM) if $self->{_seen}{refaddr($obj)}++;

    my $vars = $self->_vars_code(@{$obj->{vars}});

    return ('struct ' . ($name ne '' ? "$name " : '') . '{' . ($vars ne '' ? " $vars " : '') . '}', P_ATOM);
}

sub _h_subset {
    my ($self, $obj) = @_;

    my $name = $self->_class_name($obj);

    return ($name, P_ATOM) if $self->{_seen}{refaddr($obj)}++;

    my $code = "subset $name";

    if (exists $obj->{inherits}) {
        $code .= ' < ' . join(', ', map { ($self->_any($_))[0] } @{$obj->{inherits}});
    }

    if (exists $obj->{block}) {
        $code .= ' ' . $self->_block($obj->{block}, topic => 1, multiline => 1);
    }

    return ($code, P_ATOM);
}

sub _h_block_init {
    my ($self, $obj) = @_;
    return ($self->_block($obj, topic => 1), P_ATOM);
}

# if / elsif / else  and  with / orwith / else
sub _conditional {
    my ($self, $obj, $key, $first, $next, %opt) = @_;

    my $code = '';

    foreach my $i (0 .. $#{$obj->{$key}}) {
        my $info = $obj->{$key}[$i];
        $code .= ($i == 0 ? $first : " $next") . ' ' . $self->_cond($info->{expr}) . ' ' . $self->_block($info->{block}, %opt, multiline => 1);
    }

    if (exists $obj->{else}) {
        $code .= ' else ' . $self->_body($obj->{else}{block});
    }

    return ($code, P_ATOM);
}

sub _h_if {
    my ($self, $obj) = @_;
    $self->_conditional($obj, 'if', 'if', 'elsif');
}

sub _h_with {
    my ($self, $obj) = @_;
    $self->_conditional($obj, 'with', 'with', 'orwith', topic => 1);
}

sub _h_for_in {
    my ($self, $obj) = @_;

    my @loops;
    foreach my $loop (@{$obj->{loops}}) {
        my $vars = join(', ', map { ($_->{slurpy} ? ($_->{array} ? '*' : ':') : '') . $self->_qualified($_->{class}, $_->{name}) } @{$loop->{vars}});
        push @loops, "$vars in " . $self->_loop_expr($loop->{expr});
    }

    return ('for ' . join(', ', @loops) . ' ' . $self->_body($obj->{block}), P_ATOM);
}

sub _h_for_each {
    my ($self, $obj) = @_;

    my $cond = $self->_cond($obj->{expr});

    # `for (a, b)` is not a `foreach` loop
    my @statements = $self->_statements($obj->{expr});
    my $keyword    = (@statements == 1 ? 'for' : 'foreach');

    return ("$keyword $cond " . $self->_block($obj->{block}, topic => 1, multiline => 1), P_ATOM);
}

sub _h_cfor {
    my ($self, $obj) = @_;

    my $parts = join('; ', map { $_ eq '' ? '()' : $_ } map { join(', ', $self->_stmts($_)) } @{$obj->{expr}});

    return ("for ($parts) " . $self->_body($obj->{block}), P_ATOM);
}

sub _h_try {
    my ($self, $obj) = @_;

    my $code = 'try ' . $self->_body($obj->{try});

    if (defined $obj->{catch}) {
        $code .= ' catch ' . $self->_block($obj->{catch}, multiline => 1);
    }

    return ($code, P_ATOM);
}

sub _h_keyword_block {
    my ($keyword) = @_;
    return sub {
        my ($self, $obj) = @_;
        ("$keyword " . $self->_body($obj->{block}), P_ATOM);
    };
}

sub _h_condition_block {
    my ($keyword, %opt) = @_;
    return sub {
        my ($self, $obj) = @_;
        ("$keyword " . $self->_cond($obj->{expr}) . ' ' . $self->_block($obj->{block}, %opt, multiline => 1), P_ATOM);
    };
}

sub _h_ternary {
    my ($self, $obj) = @_;

    my @parts;
    foreach my $key (qw(cond true false)) {
        my ($code, $prec) = $self->_any($obj->{$key});
        ($code) = _paren_if($code, $prec, P_ATOM);
        push @parts, $code;
    }

    return ("$parts[0] ? $parts[1] : $parts[2]", P_TERNARY);
}

sub _h_module {
    my ($self, $obj) = @_;

    local $self->{class} = $obj->{name};

    return ("module $obj->{name} " . $self->_body($obj->{block}), P_ATOM);
}

# The code of the statements of the included files
sub _included_statements {
    my ($self, $obj) = @_;

    my @statements;
    foreach my $info (@{$obj->{included}}) {
        if ($info->{name} ne '') {    # a new namespace
            local $self->{class} = $info->{name};
            push @statements, "module $info->{name} " . $self->_script_block($info->{ast}, multiline => 1);
        }
        else {                        # included in the current namespace
            push @statements, $self->_stmts($info->{ast});
        }
    }

    return @statements;
}

sub _h_included {
    my ($self, $obj) = @_;

    my @statements = $self->_included_statements($obj);

    # The first line is indented by the caller
    my $indent = $self->_indent_str(0);
    my $code   = $self->_join_statements(\@statements, "\n", $indent);
    $code =~ s/^\Q$indent\E//;

    return ($code, P_ATOM);
}

sub _h_data {
    my ($self, $obj) = @_;

    if (!exists $self->{_seen}{$obj->{data}}) {
        $self->{after} .= "\n__DATA__\n" . ${$obj->{data}};
        $self->{_seen}{$obj->{data}} = 1;
    }

    return ('DATA', P_ATOM);
}

# Keyword followed by parenthesized arguments: die(...), warn(...), eval(...), assert(...)
sub _h_keyword_args {
    my ($keyword, $field, $use_keyword_field) = @_;
    return sub {
        my ($self, $obj) = @_;
        my $word = $use_keyword_field ? $obj->{$use_keyword_field} : $keyword;
        ($word . '(' . $self->_args_code($obj->{$field}) . ')', P_ATOM);
    };
}

sub _h_array {
    my ($self, $obj) = @_;
    return ('[' . $self->_elements_code(@{$obj}) . ']', P_ATOM);
}

# Array and hash literals have no `self` that needs parentheses, but they are indexed
sub _h_number {
    my ($self, $obj) = @_;
    return $self->_number_code($obj);
}

sub _h_return_static {
    my ($self, $obj, $node) = @_;
    return exists($node->{call}) ? ('', P_ATOM) : ('return', P_RETURN);
}

sub _h_prefix_static {
    my ($name) = @_;
    return sub {
        my ($self, $obj, $node) = @_;
        return exists($node->{call}) ? ('', P_ATOM) : ($name, P_ATOM);
    };
}

# =========================================================================
# Dispatch table
# =========================================================================

my %HANDLER;

{
    my $const_name = sub {
        my ($self, $obj) = @_;
        ($self->_qualified($obj->{class}, $obj->{name}), P_ATOM);
    };

    %HANDLER = (

        'Sidef::Variable::Variable'  => \&_h_variable,
        'Sidef::Variable::Init'      => \&_h_init,
        'Sidef::Variable::ClassAttr' => \&_h_init,
        'Sidef::Variable::ConstInit' => \&_h_const_init,

        'Sidef::Variable::Const'  => $const_name,
        'Sidef::Variable::Static' => $const_name,
        'Sidef::Variable::Define' => $const_name,

        'Sidef::Variable::NamedParam' => \&_h_named_param,

        'Sidef::Variable::ClassVar' => sub {
            my ($self, $obj) = @_;
            ($self->_dump_reftype($obj->{class}) . '!' . $obj->{name}, P_ATOM);
        },

        'Sidef::Variable::Local' => sub {
            my ($self, $obj) = @_;
            my ($c,    $p)   = $self->_any($obj->{expr});
            ($c) = _paren_if($c, $p, P_ATOM);
            ("local $c", P_PREFIX);
        },

        'Sidef::Variable::Label' => sub { ('@:' . $_[1]{name},         P_ATOM) },
        'Sidef::Variable::Magic' => sub { ($_[1]{dump} // $_[1]{name}, P_ATOM) },
        'Sidef::Variable::Ref'   => _h_prefix_static('Ref'),

        'Sidef::Variable::ClassInit' => \&_h_class_init,
        'Sidef::Variable::Struct'    => \&_h_struct,
        'Sidef::Variable::Subset'    => \&_h_subset,

        'Sidef::Types::Block::BlockInit' => \&_h_block_init,
        'Sidef::Types::Block::Return'    => \&_h_return_static,
        'Sidef::Operator::Unary'         => sub { ('', P_ATOM) },
        'Sidef::Meta::PrefixColon'       => sub { ('', P_ATOM) },
        'Sidef::Perl::Builtin'           => sub { ('', P_ATOM) },

        'Sidef::Types::Block::Do'      => sub { ('do ' . $_[0]->_block($_[1]{block}, params => 0), P_ATOM) },
        'Sidef::Types::Block::Loop'    => _h_keyword_block('loop'),
        'Sidef::Types::Block::Gather'  => _h_keyword_block('gather'),
        'Sidef::Types::Block::Default' => _h_keyword_block('default'),
        'Sidef::Types::Block::Try'     => \&_h_try,

        'Sidef::Types::Block::If'      => \&_h_if,
        'Sidef::Types::Block::With'    => \&_h_with,
        'Sidef::Types::Block::While'   => _h_condition_block('while'),
        'Sidef::Types::Block::ForEach' => \&_h_for_each,
        'Sidef::Types::Block::CFor'    => \&_h_cfor,
        'Sidef::Types::Block::ForIn'   => \&_h_for_in,

        'Sidef::Types::Block::Given' => _h_condition_block('given', topic => 1),
        'Sidef::Types::Block::When'  => _h_condition_block('when'),
        'Sidef::Types::Block::Case'  => _h_condition_block('case'),

        'Sidef::Types::Block::Take' => sub {
            my ($self, $obj) = @_;
            ('take(' . $self->_args_code($obj->{expr}) . ')', P_ATOM);
        },

        'Sidef::Types::Bool::Ternary' => \&_h_ternary,

        'Sidef::Meta::PrefixMethod' => sub {
            my ($self, $obj) = @_;
            ("::$obj->{name}(" . $self->_args_code($obj->{expr}) . ')', P_ATOM);
        },

        'Sidef::Meta::Assert'  => _h_keyword_args(undef,  'arg', 'act'),
        'Sidef::Meta::Error'   => _h_keyword_args('die',  'arg'),
        'Sidef::Meta::Warning' => _h_keyword_args('warn', 'arg'),
        'Sidef::Eval::Eval'    => _h_keyword_args('eval', 'expr'),

        'Sidef::Meta::Module'     => \&_h_module,
        'Sidef::Meta::Included'   => \&_h_included,
        'Sidef::Meta::Glob::DATA' => \&_h_data,

        'Sidef::Module::OO'   => sub { ('%O' . $_[0]->_dump_string($_[1]{module}), P_ATOM) },
        'Sidef::Module::Func' => sub { ('%S' . $_[0]->_dump_string($_[1]{module}), P_ATOM) },

        'Sidef::Types::Number::Number' => \&_h_number,

        'Sidef::Types::String::String' => sub { ($_[0]->_dump_string(${$_[1]}), P_ATOM) },
        'Sidef::Types::Glob::File'     => sub { ($_[0]->_quote_raw('f', ${$_[1]}), P_ATOM) },
        'Sidef::Types::Glob::Dir'      => sub { ($_[0]->_quote_raw('d', ${$_[1]}), P_ATOM) },

        'Sidef::Types::Array::Array'   => \&_h_array,
        'Sidef::Types::Array::HCArray' => \&_h_array,

        'Sidef::Types::Array::List' => sub {
            my ($self, $obj) = @_;
            ('(' . $self->_elements_code(@{$obj}) . ')', P_ATOM);
        },
    );
}

# =========================================================================
# Expressions
# =========================================================================

# Deparses the `self` object of an expression
sub _self {
    my ($self, $obj, $node) = @_;

    my $ref = ref($obj);

    # The statements that don't generate code (e.g.: `import`)
    if ($ref eq '') {
        return (defined($obj) && $obj !~ /^[0-9]+\z/) ? ($self->_dump_string($obj), P_ATOM) : ('', P_ATOM);
    }

    if ($ref eq 'HASH') {
        return $self->_any($obj);
    }

    if (my $handler = $HANDLER{$ref}) {
        return $self->$handler($obj, $node);
    }

    if (exists $self->{data_types}{$ref}) {
        return ($self->{data_types}{$ref}, P_ATOM);
    }

    if ($ref =~ /^Sidef::/ and UNIVERSAL::can($obj, 'dump')) {
        my $code = $obj->dump->get_value;
        return ($code, ($code =~ /^-/ ? P_PREFIX : P_ATOM));
    }

    return ($self->_dump_reftype($obj), P_ATOM);
}

# Quote-like operators, without interpolation: %f(file)  %x(command)  %perl(code)
sub _quote_raw {
    my ($self, $operator, $str) = @_;
    $str =~ s{([\\()])}{\\$1}g;
    return "%$operator($str)";
}

# Deparses an interpolated string: "text #{expr} text"
# Returns nothing when the string can't be written as a literal.
sub _interpolated {
    my ($self, $call) = @_;

    my $args = $call->{arg} // return;

    my %saved = %{$self->{_seen}};

    my $string = '';
    foreach my $arg (@{$args}) {

        if (!ref($arg)) {
            $string .= $self->_escape($arg);
        }
        elsif (ref($arg) eq 'Sidef::Types::Block::Do') {

            my $code = do {
                local $self->{_in_interp} = 1;
                join('; ', $self->_stmts($arg->{block}{code} // {}));
            };

            $string .= '#{' . $code . '}';
        }
        else {
            $self->{_seen} = \%saved;
            return;
        }
    }

    return '"' . $string . '"';
}

# Deparses an expression: {self => OBJECT, call => [...], ind => [...]}
sub _node {
    my ($self, $node) = @_;

    my $obj   = $node->{self};
    my $ref   = ref($obj);
    my $calls = $node->{call};

    my ($code, $prec);
    my $start = 0;

    if (    $calls
        and @{$calls}
        and ref($calls->[0]) eq 'HASH'
        and defined($calls->[0]{method})
        and !ref($calls->[0]{method})) {

        my $method = $calls->[0]{method};

        # "text #{expr}"
        if ($method eq 'interpolate' and exists $INTERPOLATED{$ref}) {
            my ($prefix, $runs) = @{$INTERPOLATED{$ref}};

            if (defined(my $string = $self->_interpolated($calls->[0]))) {
                ($code, $prec, $start) = ($prefix . $string, P_ATOM, 1);

                if ($runs) {
                    if (@{$calls} > 1 and ($calls->[1]{method} // '') eq 'run' and not exists $calls->[1]{arg}) {
                        $start = 2;
                    }
                    else {
                        ($code, $prec, $start) = (undef, undef, 0);
                    }
                }
            }
        }

        # `command` and %perl(code) are executed with the method `run`
        if (    ($ref eq 'Sidef::Types::Glob::Backtick' or $ref eq 'Sidef::Types::Perl::Perl')
            and $method eq 'run'
            and not exists $calls->[0]{arg}) {
            ($code, $prec, $start) = ($self->_quote_raw(($ref =~ /Backtick/ ? 'x' : 'perl'), $$obj), P_ATOM, 1);
        }
    }

    if (!defined $code) {
        ($code, $prec) = $self->_self($obj, $node);
    }

    # `_.method` is the same as `.method`
    my $topic_call = 0;
    if (    $ref eq 'Sidef::Variable::Variable'
        and $obj->{name} eq '_'
        and $obj->{type} eq 'var'
        and $calls
        and @{$calls}
        and $start == 0
        and !exists($node->{ind})
        and defined($calls->[0]{method})
        and !ref($calls->[0]{method})
        and $calls->[0]{method} =~ /^[^\W\d]/
        and $calls->[0]{method} ne 'call'
        and !exists($HYPER_OPS{$calls->[0]{method}})) {
        ($code, $topic_call) = ('', 1);
    }

    if (exists $node->{ind}) {

        # `(a{x})[i]` is not the same as `a{x}[i]`: the second one auto-vivifies `a{x}`
        my $base = _peel($obj);
        ($code, $prec) = ("($code)", P_ATOM) if (ref($base) eq 'HASH' and exists($base->{self}) and exists($base->{ind}));

        ($code, $prec) = $self->_apply_indices($code, $prec, $node->{ind});
    }

    if ($calls and @{$calls} > $start) {
        local $self->{_topic_call} = $topic_call;
        ($code, $prec) = $self->_apply_calls($code, $prec, $node, $start);
    }

    return ($code, $prec);
}

# =========================================================================
# Indices: x[...], x{...}
# =========================================================================

# The key of a hash lookup: :name, "text" or an expression
sub _lookup_key {
    my ($self, $key) = @_;

    my $obj = _peel($key);

    my $str =
       !ref($obj)                                   ? $obj
      : ref($obj) eq 'Sidef::Types::String::String' ? $$obj
      :                                               undef;

    if (defined($str) and $str =~ /^[A-Za-z_][A-Za-z_0-9]*\z/) {
        return ':' . $str;
    }

    return ref($key) ? ($self->_any($key))[0] : $self->_dump_string($key);
}

sub _apply_indices {
    my ($self, $code, $prec, $indices) = @_;

    ($code) = _paren_if($code, $prec, P_ATOM);

    foreach my $ind (@{$indices}) {

        if (exists $ind->{array}) {
            $code .= '[' . $self->_elements_code(@{$ind->{array}}) . ']';
        }
        else {
            # `x.method{...}` would be parsed as a call with a block
            $code .= '()' if _ends_bare($code);
            $code .= '{' . join(', ', map { $self->_lookup_key($_) } @{$ind->{hash}}) . '}';
        }
    }

    return ($code, P_ATOM);
}

# =========================================================================
# Calls, operators and keywords
# =========================================================================

# Deparses a binary operator applied on the code from the left.
# The operands are always parenthesized, unless they are atoms.
sub _binary {
    my ($self, %opt) = @_;

    my ($left) = _paren_if($opt{code}, $opt{prec}, P_ATOM);

    my ($right, $right_prec) = $self->_any($opt{arg});
    ($right) = _paren_if($right, $right_prec, P_ATOM);

    my $sep = ($opt{tight} and substr($right, 0, 1) ne '.') ? '' : ' ';

    return ($left . $sep . $opt{op} . $sep . $right, $opt{op_prec});
}

# Prefix operators and keywords, at the beginning of a call chain:
#   -x   !x   \x   *x   ++x   say(x)   :(x)   return x   goto x
sub _prefix_call {
    my ($self, $ref, $call, $has_more) = @_;

    my $method = $call->{method};
    my $arg    = ref($call->{arg}) ? $call->{arg}[0] : undef;

    # return, goto
    if ($ref eq 'Sidef::Types::Block::Return' or $ref eq 'Sidef::Perl::Builtin') {

        my $keyword = ($ref eq 'Sidef::Perl::Builtin' ? 'goto' : 'return');

        if (!defined($arg) or (ref($arg) eq 'HASH' and !%{$arg})) {
            return ($keyword, P_RETURN);
        }

        my ($c, $p) = $self->_any($arg);
        ($c) = _paren_if($c, $p, P_ATOM);

        return ("$keyword $c", P_RETURN);
    }

    # say x, print x  (a list operator, with only one argument that doesn't start with parenthesis)
    # say(x), defined(x), @(x), :(x), ...
    if ($FUNCTION_STYLE{$method}) {

        my @statements = (ref($arg) eq 'HASH' ? $self->_statements($arg) : ());

        # The argument is deparsed only once (the definitions are deparsed only once)
        if (@statements == 1 and ($method eq 'say' or $method eq 'print')) {
            my ($c, $p) = $self->_any($arg);

            if (not $has_more and $p >= P_ATOM and $c ne '' and $c !~ /^[(<]/) {
                return ("$method $c", P_RETURN);
            }

            return ("$method($c)", P_ATOM);
        }

        return ("$method(" . $self->_args_code(defined($arg) ? $arg : ()) . ')', P_ATOM);
    }

    my $operand = _peel($arg);

    # Constant folding of the unary minus (and plus), applied on a number
    if (($method eq '-' or $method eq '+') and $ref eq 'Sidef::Operator::Unary' and ref($operand) eq 'Sidef::Types::Number::Number') {
        return $self->_number_code($method eq '-' ? $operand->neg : $operand);
    }

    my ($c, $p) = $self->_any($arg);

    # The argument is always parenthesized, unless it's an atom: -(x ** 2)
    ($c) = _paren_if($c, $p, P_ATOM);

    # Avoid creating other operators (e.g.: `- -x` => `--x`)
    if ($method !~ /^[!~]\z/ and substr($c, 0, 1) eq substr($method, -1)) {
        $c = "($c)";
    }

    return ($method . $c, P_PREFIX);
}

sub _apply_calls {
    my ($self, $code, $prec, $node, $start) = @_;

    my $obj   = $node->{self};
    my $ref   = ref($obj);
    my $calls = $node->{call};

    foreach my $i ($start .. $#{$calls}) {

        my $call = $calls->[$i];

        # Keyword operators: if, while, and, or
        if (exists $call->{keyword}) {

            my $keyword = $call->{keyword};
            my $kprec   = Sidef::Parser::keyword_precedence($keyword);

            # `x if y` and `x while y` are applied on the whole statement from the left
            if ($keyword eq 'and' or $keyword eq 'or') {
                ($code) = _paren_if($code, $prec, P_ATOM);
            }

            my ($arg, $arg_prec) = $self->_any($call->{arg}[0]);

            if ($keyword eq 'while' and $ref eq 'Sidef::Types::Block::Do') {    # do {...} while (...)
                $arg = "($arg)";
            }
            else {
                ($arg) = _paren_if($arg, $arg_prec, P_ATOM);
            }

            ($code, $prec) = ("$code $keyword $arg", $kprec);
            next;
        }

        my $method = $call->{method};

        # A prefix operator, at the beginning of the chain
        if ($i == 0 and $PREFIX_CLASS{$ref} and defined($method)) {
            ($code, $prec) = $self->_prefix_call($ref, $call, $i < $#{$calls});
            next;
        }

        my $n_args = (exists($call->{arg}) ? scalar(@{$call->{arg}}) : 0);

        # A method with a computed name: x.(name)(...)
        if (ref($method)) {
            ($code) = _paren_if($code, $prec, P_ATOM);
            $code .= '.(' . ($self->_any($method))[0] . ')';
            $code .= '(' . $self->_args_code(@{$call->{arg}}) . ')' if $n_args;
            $prec = P_ATOM;
            next;
        }

        # A call of an object: x(...)
        if ($method eq 'call') {
            ($code) = _paren_if($code, $prec, P_ATOM);

            if (_ends_bare($code)) {    # x.method(...) would pass the arguments to the method
                $code .= ($n_args ? '()(' . $self->_args_code(@{$call->{arg}}) . ')' : '.call');
            }
            else {
                $code .= '(' . ($n_args ? $self->_args_code(@{$call->{arg}}) : '') . ')';
            }

            $prec = P_ATOM;
            next;
        }

        # Hyper-operators: x »+» y,  x ~Z+ y,  x «+»
        if (exists($HYPER_OPS{$method}) and $n_args >= 1 and !ref($call->{arg}[0])) {

            my ($op,     @rest)    = @{$call->{arg}};
            my ($binary, $postfix) = @{$HYPER_OPS{$method}};

            if (@rest == 1 and defined $binary) {
                ($code, $prec) =
                  $self->_binary(
                                 code    => $code,
                                 prec    => $prec,
                                 op      => sprintf($binary, $op),
                                 op_prec => P_WORD_OP,
                                 arg     => $rest[0],
                                );
                next;
            }

            if (@rest == 0 and defined $postfix) {
                ($code) = _paren_if($code, $prec, P_ATOM);
                $code .= sprintf($postfix, $op);
                $prec = P_ATOM;
                next;
            }
        }

        # A method call: x.name, x.name(...), x.name {...}
        if ($method =~ /^[^\W\d]/) {

            my $function_style = 0;

            if ($code eq '' and $i == $start and $self->{_topic_call}) {    # .method
                $code = ".$method";
            }
            elsif ($code eq '') {                                           # a function-style call, without an object
                $code           = $method;
                $function_style = 1;
            }
            else {
                ($code) = _paren_if($code, $prec, P_ATOM);
                $code .= '.' . $method;
            }

            if ($n_args) {
                my @args = @{$call->{arg}};
                if (@args == 1 and ref($args[0]) eq 'Sidef::Types::Block::BlockInit') {
                    $code .= ' ' . $self->_block($args[0], topic => 1);
                }
                else {
                    $code .= '(' . $self->_args_code(@args) . ')';
                }
            }
            elsif ($function_style) {
                $code .= '()';
            }

            $prec = P_ATOM;
            next;
        }

        # Postfix operators: x++  n!
        if ($n_args == 0 and exists $POSTFIX_OPS{$method}) {
            ($code) = _paren_if($code, $prec, P_ATOM);
            $code .= $method;
            $prec = P_ATOM;
            next;
        }

        # Infix operators: x + y
        if ($n_args == 1) {

            my ($op_prec) = Sidef::Parser::infix_precedence($method, 'op');

            ($code, $prec) =
              $self->_binary(
                             code    => $code,
                             prec    => $prec,
                             op      => $method,
                             op_prec => $op_prec,
                             arg     => $call->{arg}[0],
                             tight   => exists($TIGHT_OPS{$method}),
                            );

            next;
        }

        # An operator used as a method: x.+(a, b)
        ($code) = _paren_if($code, $prec, P_ATOM);
        $code .= ".$method(" . ($n_args ? $self->_args_code(@{$call->{arg}}) : '') . ')';
        $prec = P_ATOM;
    }

    return ($code, $prec);
}

# =========================================================================
# Public interface
# =========================================================================

# Deparses an expression and returns its code
sub deparse_expr {
    my ($self, $expr) = @_;
    return ($self->_any($expr))[0];
}

# Deparses a script and returns the list with the code of each statement
# (or the code of the last statement, in scalar context)
sub deparse_script {
    my ($self, $script) = @_;

    my @results = $self->_stmts($script);

    wantarray ? @results : $results[-1];
}

sub deparse {
    my ($self, $script) = @_;

    undef %{$self->{_seen}};

    my @statements = $self->deparse_script($script);

    $self->{before} . $self->_join_statements(\@statements, $self->{between}) . $self->{after};
}

1
