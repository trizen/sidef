package Sidef::Deparse::Perl;

use utf8;
use 5.016;

use Scalar::Util qw(refaddr);
use Sidef::Types::Number::Number;

# ---------------------------------------------------------------------------
# Sidef::Deparse::Perl
#
# Translates the AST produced by Sidef::Parser into Perl code.
#
# Overview
# --------
#
#   deparse()           the entry point: returns the code of a whole program
#   deparse_script()    a sequence of statements (a hash: namespace => [statements])
#   deparse_expr()      one expression: {self => OBJ, ind => [...], call => [...]}
#                         1. the object itself       (`_node_*` handlers, one per node type)
#                         2. the indices             (`_apply_indices`)
#                         3. the method calls        (`_apply_calls`)
#
# The generated code is assembled from these parts (see `_program`):
#
#   header        the pragmas: `use strict`, etc.
#   preamble      the lines that must be executed first: `use Module;`, `use constant`, BEGIN blocks
#   declarations  the `my` declarations that are hoisted at the beginning of a scope
#   statements    the program itself
#   trailer       the code that runs at the end of the program
#
# Hoisted declarations
# --------------------
#
# An expression of the AST can declare variables in the middle of a statement, but
# a Perl `my` variable is visible only to the next statements. For this reason, all the
# declarations are collected in the scope (see `_with_scope`) of the block that contains them
# and they are emitted at the beginning of that block.
#
# Names
# -----
#
# Every variable, function and class gets a unique number (see `_id`), which is appended
# to its name: `var x` becomes `$x_1`.
#
# Classes
# -------
#
# A class is compiled into a single call of Sidef::Object::Class->declare(), which receives the
# declarative description of the class (parents, parameters, attributes, initializers).
# The inheritance, the construction of the objects and the accessors are implemented
# at run-time, by Sidef::Object::Class.
# ---------------------------------------------------------------------------

#----------------------------------------------------------------------
# Static configuration
#----------------------------------------------------------------------

my %DEFAULT_OPTIONS = (
                       before           => '',
                       header           => '',
                       between          => ';',
                       after            => ';',
                       opt              => {},
                       environment_name => 'main',
                      );

# Operators that are compiled into the lazy Perl operators
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

# Methods that are exposed to Perl as overloaded operators
my %OVERLOAD_METHODS = (
                        '=='  => 'eq',
                        '<=>' => 'cmp',
                       );

# Operators like `+=`, which are compiled to `$x = $x + ...`
my %REASSIGN_OPS = map { ("$_=", $_) } qw(+ - % * // / & | ^ ** && || << >> ÷);

my %INC_DEC_OPS = (
                   '++' => 'inc',
                   '--' => 'dec',
                  );

# Objects that are created from other constants: type => [name, fields]
my %COMPOSITE_CONSTANTS = (
    'Sidef::Types::Range::RangeNumber' => ['RangeNum',   qw(from to step)],
    'Sidef::Types::Range::RangeString' => ['RangeStr',   qw(from to step)],
    'Sidef::Types::Number::Gauss'      => ['Gauss',      qw(a b)],
    'Sidef::Types::Number::Quadratic'  => ['Quadratic',  qw(a b p q)],
    'Sidef::Types::Number::Quaternion' => ['Quaternion', qw(a b c d)],
    'Sidef::Types::Number::Fraction'   => ['Fraction',   qw(a b)],
    'Sidef::Types::Number::Mod'        => ['Mod',        qw(n m)],
                          );

# The built-in data types (used as values, as types of variables, etc.)
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

# The node handlers: type of the node => method
my %NODE_HANDLERS = (

    # Variables and declarations
    'Sidef::Variable::Variable'   => '_node_variable',
    'Sidef::Variable::Local'      => '_node_local',
    'Sidef::Variable::ClassVar'   => '_node_class_var',
    'Sidef::Variable::Define'     => '_node_define',
    'Sidef::Variable::Const'      => '_node_const',
    'Sidef::Variable::Static'     => '_node_static',
    'Sidef::Variable::ConstInit'  => '_node_const_init',
    'Sidef::Variable::Init'       => '_node_init',
    'Sidef::Variable::Magic'      => '_node_magic',
    'Sidef::Variable::Label'      => '_node_label',
    'Sidef::Variable::NamedParam' => '_node_named_param',

    # Classes, structs, subsets and blocks
    'Sidef::Variable::ClassInit'     => '_node_class_init',
    'Sidef::Variable::ClassAttr'     => '_node_empty',
    'Sidef::Variable::Struct'        => '_node_struct',
    'Sidef::Variable::Subset'        => '_node_subset',
    'Sidef::Types::Block::BlockInit' => '_node_block_init',

    # Operators that are handled in `_apply_calls`
    'Sidef::Operator::Unary' => '_node_empty',
    'Sidef::Variable::Ref'   => '_node_empty',
    'Sidef::Perl::Builtin'   => '_node_empty',

    # Literals and containers
    'Sidef::Types::Number::Number'  => '_node_number',
    'Sidef::Types::Number::Complex' => '_node_complex',
    'Sidef::Types::String::String'  => '_node_string',
    'Sidef::Types::Array::Array'    => '_node_array',
    'Sidef::Types::Array::HCArray'  => '_node_array',
    'Sidef::Types::Array::Vector'   => '_node_vector',
    'Sidef::Types::Array::Matrix'   => '_node_matrix',
    'Sidef::Types::Array::Pair'     => '_node_pair',
    'Sidef::Types::Hash::Hash'      => '_node_hash',
    'Sidef::Types::Bool::Bool'      => '_node_bool',
    'Sidef::Types::Regex::Regex'    => '_node_regex',
    'Sidef::Types::Nil::Nil'        => '_node_nil',
    'Sidef::Types::Null::Null'      => '_node_null',
    'Sidef::Types::Perl::Perl'      => '_node_perl_code',
    'Sidef::Types::Glob::Backtick'  => '_node_backtick',
    'Sidef::Types::Glob::File'      => '_node_file',
    'Sidef::Types::Glob::Dir'       => '_node_dir',
    'Sidef::Types::Glob::Pipe'      => '_node_pipe',
    'Sidef::Module::OO'             => '_node_module_oo',
    'Sidef::Module::Func'           => '_node_module_func',

    # Control flow
    'Sidef::Types::Block::If'       => '_node_if',
    'Sidef::Types::Block::With'     => '_node_with',
    'Sidef::Types::Block::While'    => '_node_while',
    'Sidef::Types::Block::ForEach'  => '_node_foreach',
    'Sidef::Types::Block::CFor'     => '_node_cfor',
    'Sidef::Types::Block::ForIn'    => '_node_forin',
    'Sidef::Types::Bool::Ternary'   => '_node_ternary',
    'Sidef::Types::Block::Do'       => '_node_do',
    'Sidef::Types::Block::Loop'     => '_node_loop',
    'Sidef::Types::Block::Given'    => '_node_given',
    'Sidef::Types::Block::When'     => '_node_when',
    'Sidef::Types::Block::Case'     => '_node_case',
    'Sidef::Types::Block::Default'  => '_node_default',
    'Sidef::Types::Block::Continue' => '_node_continue',
    'Sidef::Types::Block::Gather'   => '_node_gather',
    'Sidef::Types::Block::Take'     => '_node_take',
    'Sidef::Types::Block::Try'      => '_node_try',
    'Sidef::Types::Block::Break'    => '_node_break',
    'Sidef::Types::Block::Next'     => '_node_next',
    'Sidef::Types::Block::Return'   => '_node_return',

    # Special objects
    'Sidef::Meta::Glob::STDIN'   => '_node_stdin',
    'Sidef::Meta::Glob::STDOUT'  => '_node_stdout',
    'Sidef::Meta::Glob::STDERR'  => '_node_stderr',
    'Sidef::Meta::Glob::ARGF'    => '_node_argf',
    'Sidef::Meta::Glob::DATA'    => '_node_data',
    'Sidef::Meta::PrefixMethod'  => '_node_prefix_method',
    'Sidef::Meta::Module'        => '_node_meta_module',
    'Sidef::Meta::Included'      => '_node_included',
    'Sidef::Meta::Assert'        => '_node_assert',
    'Sidef::Meta::Error'         => '_node_error',
    'Sidef::Meta::Warning'       => '_node_warning',
    'Sidef::Meta::Unimplemented' => '_node_unimplemented',
    'Sidef::Eval::Eval'          => '_node_eval',
    'Sidef::Parser'              => '_node_parser',
                    );

#----------------------------------------------------------------------
# Constructor
#----------------------------------------------------------------------

sub new {
    my (undef, %args) = @_;

    my $self = bless({%DEFAULT_OPTIONS, %args}, __PACKAGE__);

    $self->{environment_name} = 'main' if not length($self->{environment_name} // '');
    $self->{opt} //= {};

    $self->{preamble}      = [];    # the lines that are executed first
    $self->{preamble_seen} = {};    # to avoid duplicates
    $self->{frames}        = [];    # the stack of scopes (see `_with_scope`)
    $self->{ids}           = {};    # refaddr => [number, object]
    $self->{id_counter}    = 0;
    $self->{declared}      = {};    # the functions, blocks and classes that have been emitted
    $self->{cache}         = {};    # the cache of the constants
    $self->{counters}      = {};    # the counters for the names of the constants

    $self->{header} .= $self->_default_header;
    return $self;
}

# The pragmas and the options (-w, -W, -P, -M) of the generated program
sub _default_header {
    my ($self) = @_;

    my $opt = $self->{opt};

    my $header = <<'HEADER';

use utf8;
use strict;
use feature qw(state unicode_strings unicode_eval evalbytes);
local $| = 1;   # autoflush

HEADER

    if (defined $opt->{w}) {
        $header .= '$SIG{__WARN__} = sub { require Carp; Carp::cluck(@_) };';
    }

    if (defined $opt->{W}) {
        $header .= '$SIG{__DIE__} = $SIG{__WARN__} = sub { require Carp; Carp::confess(@_) };';
    }

    if (exists $opt->{P}) {
        my $precision = abs(int($opt->{P}));
        $header .= "BEGIN { \$Sidef::Types::Number::Number::PREC = 4*$precision };";
    }

    if (exists $opt->{M}) {
        my $round = unpack('A*', lc($opt->{M}) =~ s/^\s+//r);
        my %modes = (
                     'zero'  => 1,
                     '+inf'  => 2,
                     '-inf'  => 3,
                     'inf'   => 4,
                     'faith' => 5,
                    );
        $header .= 'BEGIN { $Sidef::Types::Number::Number::ROUND = ' . ($modes{$round} // 0) . ' };';
    }

    return $header;
}

#----------------------------------------------------------------------
# Output assembly: the preamble, the scopes and the names
#----------------------------------------------------------------------

# Adds a line to the preamble (once)
sub _prelude {
    my ($self, $line) = @_;
    if (not $self->{preamble_seen}{$line}++) {
        push @{$self->{preamble}}, $line;
    }
    return;
}

# Loads a Sidef module
sub load_mod {
    my ($self, $module) = @_;
    $self->_prelude($self->{opt}{c} ? qq{main::__load_sidef_module__("$module");} : "use $module;");
    return;
}

# Declares something in the nearest scope: it will be emitted at the beginning of that scope.
sub _hoist {
    my ($self, $code) = @_;
    push @{$self->{frames}[-1]{declarations}}, $code;
    return;
}

# Runs a callback in a new scope. Returns the hoisted declarations, followed by what the callback returns.
sub _with_scope {
    my ($self, $callback) = @_;

    push @{$self->{frames}}, {declarations => []};

    my @result = eval { $callback->() };
    my $error  = $@;

    my $frame = pop @{$self->{frames}};
    die $error if $error;

    return (join('', @{$frame->{declarations}}), @result);
}

# The code of a block of statements, with its declarations: `{...}`
sub _scoped_block {
    my ($self,         $callback) = @_;
    my ($declarations, $code)     = $self->_with_scope($callback);
    return '{' . $declarations . $code . '}';
}

# A unique number for each object of the AST (the objects are kept alive, which ensures the uniqueness)
sub _id {
    my ($self, $obj) = @_;
    my $entry = ($self->{ids}{refaddr($obj)} //= [++$self->{id_counter}, $obj]);
    return $entry->[0];
}

# Returns true the first time it's called for an object
sub _first_time {
    my ($self, $obj, $what) = @_;
    return !$self->{declared}{$what // ''}{refaddr($obj)}++;
}

# The name of a variable, without the sigil
sub _bare_name {
    my ($self, $var) = @_;

    return $var->{class} . '::' . $var->{name} if $var->{type} eq 'global';
    return $var->{name} . '_' . $self->_id($var);
}

# The Perl expression of a variable: `$name`
sub _var {
    my ($self, $var) = @_;
    $var->{name} eq '' and return 'undef';
    return '$' . $self->_bare_name($var);
}

# The Perl variable that stores the value of a declaration: `@name` and `%name` for the slurpy variables
sub _var_container {
    my ($self, $var) = @_;
    $var->{name} eq '' and return 'undef';
    return (exists($var->{array}) ? '@' : exists($var->{hash}) ? '%' : '$') . $self->_bare_name($var);
}

# A constant that holds an object: `use constant NAME => Class->method(ARGS)`
# Returns the code that gives access to the constant.
sub _constant {
    my ($self, %opt) = @_;

    my $cache = (defined($opt{cache}) ? \$self->{cache}{$opt{label}}{$opt{cache}} : \my $unused);

    return $$cache if defined $$cache;

    my $name = $opt{label} . ++$self->{counters}{$opt{label}};
    my $call = $opt{class} . ($opt{function} ? '::' : '->') . $opt{method} . '(' . join(',', @{$opt{args} // []}) . ')';

    $self->_prelude("use constant $name => $call;");

    return ($$cache = "($self->{environment_name}\::$name)");
}

# The method call that is used for the operators: `->$OP1`
sub _op_call {
    my ($self, $method) = @_;

    my $name = ($self->{cache}{op}{$method} //= 'OP' . ++$self->{counters}{op});
    my $var  = "$self->{environment_name}\::$name";

    $self->_prelude("BEGIN { \$$var = " . $self->_dump_string($method) . ' };');
    return '->$' . $var;
}

#----------------------------------------------------------------------
# Strings
#----------------------------------------------------------------------

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

    # The Perl double-quoted string with the given content
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

#----------------------------------------------------------------------
# Types, names of the classes
#----------------------------------------------------------------------

# The name of the Perl package of an object that defines a type: a class, a struct or a subset
sub _named_package {
    my ($self, $obj) = @_;

    my $root = $obj;
    while (ref($root) and ref($root) ne 'HASH' and exists($root->{parent}) and ref($root->{parent})) {
        $root = $root->{parent};    # a class that is declared again, lives in the same package
    }

    return
      join('::',
           $self->{environment_name},
           $self->_id($root),
           $obj->{class} || 'main',
           (length($obj->{name} // '') ? $obj->{name} : Sidef::normalize_type(ref($obj)) . $self->_id($obj)));
}

# The Perl package of a class (the built-in classes are extended in place)
sub _class_package {
    my ($self, $class) = @_;

    if (ref($class->{name})) {
        return $self->_type_name($class->{name});
    }

    return $self->_named_package($class);
}

# The key of the declaration of a class, in the registry of Sidef::Object::Class.
# It depends only on the object of the AST, which makes it valid across deparsers
# (the interactive mode deparses every line with a new deparser).
sub _class_key {
    my ($self, $class) = @_;
    return 'class#' . refaddr($class);
}

# The Perl type (a package) that corresponds to an object of the AST
sub _type_name {
    my ($self, $obj) = @_;

    my $ref = ref($obj);

    if (exists $DATA_TYPES{$ref}) {
        my $type = $DATA_TYPES{$ref};
        $self->load_mod($type);
        return $type;
    }

    return
        ($ref eq 'Sidef::Variable::Struct' or $ref eq 'Sidef::Variable::Subset') ? $self->_named_package($obj)
      : $ref eq 'Sidef::Variable::ClassInit'                                     ? $self->_class_package($obj)
      : $ref eq 'Sidef::Variable::Ref'                                           ? 'REF'
      : $ref eq 'Sidef::Types::Block::BlockInit'                                 ? 'Sidef::Types::Block::Block'
      :                                                                            $ref;
}

sub _type_string {
    my ($self, $obj) = @_;
    return $self->_dump_string($self->_type_name($obj));
}

#----------------------------------------------------------------------
# Statements and expressions: the generic helpers
#----------------------------------------------------------------------

# A list of AST items, deparsed and joined: statements, expressions and strings
sub _deparse_list {
    my ($self, $before, $separator, $after, @items) = @_;

    return
        $before
      . join($separator, map { ref($_) eq 'HASH' ? $self->deparse_script($_) : ref($_) ? $self->deparse_expr({self => $_}) : $self->_dump_string($_) } @items)
      . $after;
}

# A list of arguments: `(a, b, c)`
sub deparse_args {
    my ($self, @args) = @_;
    return $self->_deparse_list('(', ',', ')', @args);
}

# The code of an expression that is stored in a variable of the AST (a struct or an object)
sub _deparse_value {
    my ($self, $value) = @_;
    return $self->deparse_expr({self => $value});
}

# The statements of a block, joined: `a; b; c`
sub _statements {
    my ($self, $block_code) = @_;
    return join(';', $self->deparse_script($block_code));
}

# A block with its own scope: `{...}`
sub _deparse_scoped {
    my ($self, $block) = @_;
    return $self->_scoped_block(sub { $self->_statements($block->{code}) });
}

# The variables of the block, as a list: `$a_1,$b_2`
sub _block_vars {
    my ($self, $block) = @_;
    return join(',', map { $self->_var($_) } @{$block->{init_vars}{vars} // []});
}

# `expr` or `(my ($a,$b) = expr)[-1]`, when the block declares variables
sub _condition {
    my ($self, $expr, $block) = @_;

    my $arg  = $self->deparse_args($expr);
    my $vars = $self->_block_vars($block);

    return ($vars ne '' ? "(my ($vars) = $arg)[-1]" : $arg);
}

#----------------------------------------------------------------------
# Declaration of variables
#----------------------------------------------------------------------

# The code that gives the initial value to a variable, after the binding of the arguments:
# the default value and the conversion of the slurpy variables into objects
sub _initialize_var {
    my ($self, $var, %opt) = @_;

    my $my = ($opt{declare} ? 'my ' : '');

    my $name  = $self->_bare_name($var);
    my $value = (exists($var->{value}) ? $self->_deparse_value($var->{value}) : '');
    my $code  = '';

    if (exists $var->{array}) {
        $code .= "\@$name=($value) if not \@$name;" if $value ne '';
        $self->load_mod('Sidef::Types::Array::Array');
        $code .= "$my\$$name = bless(\\\@$name, 'Sidef::Types::Array::Array');";
    }
    elsif (exists $var->{hash}) {
        $code .= "\%$name=($value) if not keys \%$name;" if $value ne '';
        $self->load_mod('Sidef::Types::Hash::Hash');
        $code .= "$my\$$name = bless(\\\%$name, 'Sidef::Types::Hash::Hash');";
    }
    elsif ($value ne '') {
        $code .= "\$$name//=$value;";
    }

    return $code;
}

# Declaration of variables: `var a, b = 1, 2`
sub _node_init {
    my ($self, $init) = @_;

    my @vars = @{$init->{vars}};

    if (!@vars or $vars[0]{type} eq 'del') {
        return '';
    }

    my $args = (exists($init->{args}) ? '=' . $self->deparse_args($init->{args}) : '');
    my @code = ('(' . join(',', map { $self->_var_container($_) } @vars) . ')' . $args);

    foreach my $var (@vars) {

        # The containers of the slurpy variables
        if ($var->{type} ne 'global') {
            my $name = $self->_bare_name($var);
            $self->_hoist("my \@$name;") if exists $var->{array};
            $self->_hoist("my \%$name;") if exists $var->{hash};
        }

        my $code = $self->_initialize_var($var);
        push @code, $code if $code ne '';
    }

    if (my @lexicals = grep { $_->{type} ne 'global' } @vars) {
        $self->_hoist('my(' . join(',', map { $self->_var($_) } @lexicals) . ');');
    }

    # The result is a list of lvalues
    if (@code > 1 or exists($init->{args})) {
        push @code, '(' . join(',', map { $self->_var($_) } @vars) . ')';
        return 'CORE::sub:lvalue{' . join(';', @code) . '}->()';
    }

    return '(' . $code[0] . ')';
}

# The binding of the arguments of a function to its parameters: `my($a, @b) = @_;`
sub _bind_params {
    my ($self, @vars) = @_;

    @vars or return '';

    my $code = 'my(' . join(',', map { $self->_var_container($_) } @vars) . ')=@_;';

    foreach my $var (@vars) {
        $code .= $self->_initialize_var($var, declare => 1);
    }

    # The binding must not be the result of an empty block
    return $code . '();';
}

# The binding of the fields of an object to the lexical variables: `my($a, $b) = @{$self}{"a", "b"};`
sub _bind_fields {
    my ($self, @vars) = @_;

    @vars or return '';

    return 'my(' . join(',', map { $self->_var($_) } @vars) . ')=@{$self}{' . join(',', map { $self->_dump_string($_->{name}) } @vars) . '};';
}

# The description of a parameter, used at run-time for the validation of the arguments
sub _param_descriptor {
    my ($self, $var) = @_;

    my @fields = ('name=>' . $self->_dump_string($var->{name}));

    push @fields, 'slurpy=>' . $var->{slurpy}                      if exists $var->{slurpy};
    push @fields, 'array=>' . $var->{array}                        if exists $var->{array};
    push @fields, 'type=>' . $self->_type_string($var->{ref_type}) if exists $var->{ref_type};
    push @fields, 'subset=>' . $self->_type_string($var->{subset}) if exists $var->{subset};
    push @fields, 'has_value=>1'                                   if exists $var->{has_value};

    if (exists $var->{where_block}) {
        push @fields, 'where_block=>' . $self->_closure($var->{where_block});
    }

    if (exists $var->{where_expr}) {
        push @fields, 'where_expr=>do{' . $self->deparse_expr({self => $var->{where_expr}}) . '}';
    }

    return '{' . join(',', @fields) . '}';
}

# The descriptors of a list of parameters: `vars=>[...],table=>{...}`
sub _param_descriptors {
    my ($self, @vars) = @_;
    return '[' . join(',', map { $self->_param_descriptor($_) } @vars) . ']';
}

sub _param_table {
    my ($self, @vars) = @_;
    return '{' . join(',', map { $self->_dump_string($vars[$_]{name}) . '=>' . $_ } 0 .. $#vars) . '}';
}

# A closure from a block of the AST that has one parameter: `sub{my($_)=@_; ...}`
sub _closure {
    my ($self, $block) = @_;

    my ($declarations, $code) = $self->_with_scope(
        sub {
            $self->_bind_params(@{$block->{init_vars}{vars}}[0]) . $self->_statements($block->{code});
        }
    );

    return 'sub{' . $declarations . $code . '}';
}

#----------------------------------------------------------------------
# Static variables, constants and `local`
#----------------------------------------------------------------------

# The code that computes the value of `define`, `const` and `static`
sub _static_value {
    my ($self, $var) = @_;

    if ($var->{array}) {
        $self->load_mod('Sidef::Types::Array::Array');
    }
    elsif ($var->{hash}) {
        $self->load_mod('Sidef::Types::Hash::Hash');
    }

    my $value = (defined($var->{value}) ? scalar($self->deparse_script($var->{value})) : '');

    return
        'state$'
      . $self->_bare_name($var)
      . "=do{my \@data = ($value);"
      . (
         $var->{slurpy}
         ? (
            $var->{array}
            ? "bless(\\\@data, 'Sidef::Types::Array::Array')"
            : "bless({\@data}, 'Sidef::Types::Hash::Hash')"
           )
         : "\$data[0]"
        ) . '}';
}

sub _node_define {
    my ($self, $var) = @_;

    my $name = $self->_bare_name($var);

    if ($self->_first_time($var, 'define')) {
        my ($declarations, $value) = $self->_with_scope(sub { $self->_static_value($var) });
        $self->_prelude("use constant $name=>do{" . $declarations . $value . '};');
    }

    return "($self->{environment_name}\::$name)";
}

sub _node_const {
    my ($self, $var) = @_;

    my $name = '$' . $self->_bare_name($var);

    if ($self->_first_time($var, 'const')) {
        $self->_hoist("my $name;");
        return "($name//=sub{" . $self->_static_value($var) . "})->()";
    }

    return "$name\->()";
}

sub _node_static {
    my ($self, $var) = @_;

    if ($self->_first_time($var, 'static')) {
        return '(' . $self->_static_value($var) . ')';
    }

    return '$' . $self->_bare_name($var);
}

sub _node_const_init {
    my ($self, $obj) = @_;
    return join(($obj->{type} eq 'global' ? ',' : ';'), map { $self->_deparse_value($_) } @{$obj->{vars}});
}

sub _node_local {
    my ($self, $obj) = @_;
    return 'local ' . (defined($obj->{expr}) ? $self->deparse_args($obj->{expr}) : '()');
}

sub _node_class_var {
    my ($self, $obj) = @_;
    return '$' . $self->_type_name($obj->{class}) . '::' . $obj->{name};
}

# Variables, functions and methods
sub _node_variable {
    my ($self, $var) = @_;

    if ($var->{type} eq 'func' or $var->{type} eq 'method') {
        return $self->_callable($var);
    }

    my $name = $self->_bare_name($var);

    # The predefined variables
    if ($var->{name} eq 'ENV' and $self->_first_time($var, 'predefined')) {
        $self->_prelude('require Encode;');
        $self->_prelude(qq{my \$$name = Sidef::Types::Hash::Hash->new(map{Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \%ENV);});
    }
    elsif ($var->{name} eq 'ARGV' and $self->_first_time($var, 'predefined')) {
        $self->_prelude('require Encode;');
        $self->_prelude(qq{my \$$name = Sidef::Types::Array::Array->new([map {Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \@ARGV]);});
    }

    return $self->_var($var);
}

sub _node_magic { $_[1]->{name} }
sub _node_label { $_[1]->{name} . ': ' }
sub _node_empty { '' }

#----------------------------------------------------------------------
# Functions and methods
#----------------------------------------------------------------------

# The code of a function or of a method. It's a variable that holds a Sidef::Types::Block::Block object.
sub _callable {
    my ($self, $obj) = @_;

    if ($obj->{name} eq '') {
        $obj->{name} = '__FUNC__';
    }

    my $name  = $obj->{name};
    my $alpha = ($name =~ /^[^\W\d]\w*+\z/ ? $name : '__NONANN__');
    my $var   = '$' . $alpha . '_' . $self->_id($obj);

    # A method that is defined again (a multimethod) is a function
    local $obj->{type} = 'func' if exists($obj->{parent});

    my $type = $obj->{type};

    # Already emitted: just the variable
    $self->_first_time($obj, 'callable') or return $var;

    my $block = $obj->{value};
    my $code  = $var;

    {
        local $self->{function}          = $self->_id($block);
        local $self->{parent_name}       = [$type, $name];
        local $self->{current_namespace} = $obj->{class};

        $self->_hoist("my $var;");

        # Built-in class that is extended: the original method is kept as a fallback
        local $self->{block_extra} = undef;
        if ($self->{ref_class} and !exists($obj->{parent})) {
            my $original = '$' . $alpha . '_code_' . $self->_id($obj);
            $self->_hoist(qq{state $original = UNIVERSAL::can(} . $self->_dump_string($self->{class_name}) . ',' . $self->_dump_string($name) . ');');
            $self->{block_extra} = ",(defined($original)?(fallback=>Sidef::Types::Block::Block->new(code=>$original)):())";
        }

        if ((my $content = $self->_deparse_value($block)) ne '') {
            $code .= "=$content";
        }
    }

    # A function that is defined again: it's added to the first one
    if (exists $obj->{parent}) {
        my $parent = $self->_deparse_value($obj->{parent});
        $code = "do{CORE::push(\@{" . $parent . "->{kids} //= []}, do{$code});$parent}";
    }

    if (exists $obj->{returns}) {
        my $types = '[' . join(',', map { $self->_type_string($_) } @{$obj->{returns}}) . ']';
        $code = "do{$code;$var\->{returns}=$types;$var}";
    }

    if ($obj->{cached}) {
        $code = "do{$code;$var\->cache;$var}";
    }

    if ($type eq 'func' and !$obj->{parent}) {
        if ($alpha eq 'MAIN') {
            $self->_prelude('require Encode;');
            $self->{after} .= "Sidef::Variable::GetOpt->new([map{Encode::decode_utf8(\$_)}\@ARGV],$var);";
        }
    }
    elsif ($type eq 'method') {
        my $install = $self->_install_method($obj, $alpha, $var);
        $code .= ";$install" if $install ne '';
    }

    return $code;
}

# The code that makes a method of a class available as a Perl method
sub _install_method {
    my ($self, $obj, $alpha, $var) = @_;

    my $name    = $obj->{name};
    my $package = $self->{package_name};

    my $code = '';

    if ($alpha eq 'AUTOLOAD') {
        return
            'our$AUTOLOAD;'
          . "sub AUTOLOAD {my\$self=shift;"
          . "my(\$class,\$method)=(\$AUTOLOAD=~/^(.*[^:])::(.*)\$/);"
          . "$var->call(\$self,Sidef::Types::String::String->new(\$class),Sidef::Types::String::String->new(\$method),\@_)}";
    }

    # Anonymous method
    if ($alpha eq '__FUNC__') {
        return '';
    }

    $code .=
        'state$_'
      . $self->_id($obj)
      . '=do{no strict \'refs\';'
      . "\$${package}::__SIDEF_CLASS_METHODS__{"
      . $self->_dump_string($name)
      . "}=$var;" . '*{'
      . $self->_dump_string("$package\::$name")
      . "}=sub{$var\->call(\@_)}}";

    if (exists $OVERLOAD_METHODS{$name}) {
        $code .=
            ';'
          . "use overload q{$OVERLOAD_METHODS{$name}} =>"
          . 'sub{my($first,$second,$swap)=@_;'
          . 'if($swap){($first,$second)=($second,$first)}'
          . '$first'
          . $self->_op_call($name)
          . '($second)};';
    }

    return $code;
}

# Blocks: the code of a function, of a method or of an anonymous block
sub _node_block_init {
    my ($self, $obj) = @_;

    my $id = $self->_id($obj);

    # Already emitted
    $self->_first_time($obj, 'block') or return "(\$block_$id)";

    # An empty block is the type
    %{$obj} or return q{'Sidef::Types::Block::Block'};

    my $var         = "\$block_$id";
    my $is_function = (defined($self->{function}) and $self->{function} == $id);

    local $self->{current_block} = $id;

    $self->_hoist("my $var;");

    my $extra = ($is_function ? ($self->{block_extra} // '') : '');
    local $self->{block_extra} = undef;

    my $has_params = (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}});

    my ($declarations, $body) = $self->_with_scope(
        sub {
            my $code = ($has_params ? $self->_bind_params(@{$obj->{init_vars}{vars}}) : '');

            $code .= 'my @return;' if $is_function;

            my @statements = $self->deparse_script($obj->{code});

            if ($is_function and @statements) {
                $statements[-1] = 'return do{' . $statements[-1] . '}';
            }

            return $code . join(';', @statements) . ($is_function ? ";END_$id: \@return;" : '');
        }
    );

    my @attributes;

    if ($is_function) {
        push @attributes, 'type=>' . $self->_dump_string($self->{parent_name}[0]), 'name=>' . $self->_dump_string($self->{parent_name}[1]);
    }
    else {
        push @attributes, 'type=>' . $self->_dump_string('block'), 'name=>' . $self->_dump_string('__BLOCK__');
    }

    if (defined $self->{class_name}) {
        push @attributes, 'class=>' . $self->_dump_string($self->{class_name});
    }

    if (defined($self->{current_namespace}) and $self->{current_namespace} ne 'main') {
        push @attributes, 'namespace=>' . $self->_dump_string($self->{current_namespace});
    }

    if ($has_params) {
        my @vars = @{$obj->{init_vars}{vars}};
        push @attributes, 'vars=>' . $self->_param_descriptors(@vars), 'table=>' . $self->_param_table(@vars);
    }

    return "$var=Sidef::Types::Block::Block->new(code=>sub{" . $declarations . $body . '},' . join(',', @attributes) . $extra . ')';
}

sub _node_return {
    my ($self, $obj, $expr) = @_;

    # The `return` with arguments is handled by `_apply_calls`
    exists($expr->{call}) and return '';

    if (defined $self->{function}) {
        return "goto END_$self->{function}";
    }

    return 'return;';
}

sub _node_break    { 'last' }
sub _node_next     { 'next' }
sub _node_continue { '$continue = 1' }

#----------------------------------------------------------------------
# Literals and containers
#----------------------------------------------------------------------

sub _node_number {
    my ($self, $obj) = @_;

    my ($type, $content) = $obj->_dump;

    if ($type eq 'int') {
        return
          $self->_constant(
                           class    => ref($obj),
                           method   => '_set_int',
                           label    => 'Number',
                           function => 1,
                           args     => ["'${content}'"],
                           cache    => $content,
                          );
    }

    return
      $self->_constant(
                       class    => ref($obj),
                       method   => '_set_str',
                       label    => 'Number',
                       function => 1,
                       args     => ["'${type}'", "'${content}'"],
                       cache    => "$type $content",
                      );
}

sub _node_string {
    my ($self, $obj) = @_;
    return
      $self->_constant(
                       class  => ref($obj),
                       method => 'new',
                       label  => 'String',
                       args   => [$self->_dump_string($$obj)],
                       cache  => $$obj,
                      );
}

sub _node_complex {
    my ($self, $obj)  = @_;
    my ($real, $imag) = $obj->reals;
    return
      $self->_constant(
                       class  => ref($obj),
                       method => 'new',
                       label  => 'Complex',
                       args   => [$self->_deparse_value($real), $self->_deparse_value($imag)],
                      );
}

sub _node_regex {
    my ($self, $obj) = @_;
    return
      $self->_constant(
                       class  => ref($obj),
                       method => 'new',
                       label  => 'Regex',
                       args   => [$self->_dump_string("$obj->{raw}"), $self->_dump_string($obj->{flags} . ($obj->{global} ? 'g' : ''))],
                      );
}

# Objects that are created with a string: files, directories, backticks, etc.
sub _string_constant {
    my ($self, $obj, $label, $method) = @_;
    return
      $self->_constant(
                       class  => ref($obj),
                       method => $method // 'new',
                       label  => $label,
                       args   => [$self->_dump_string(${$obj})],
                      );
}

sub _node_perl_code { $_[0]->_string_constant($_[1], 'PerlCode') }
sub _node_backtick  { $_[0]->_string_constant($_[1], 'Backtick') }
sub _node_file      { $_[0]->_string_constant($_[1], 'File') }
sub _node_dir       { $_[0]->_string_constant($_[1], 'Dir') }

sub _node_pipe {
    my ($self, $obj) = @_;
    return $self->_constant(class => ref($obj), method => 'new', label => 'Pipe', args => [map { $self->_dump_string($_) } @{$obj}]);
}

sub _node_null {
    my ($self, $obj) = @_;
    return $self->_constant(class => ref($obj), method => 'new', label => 'Null');
}

sub _node_module_oo {
    my ($self, $obj) = @_;
    return $self->_constant(class => ref($obj), method => '__NEW__', label => 'ModuleOO', args => [$self->_dump_string($obj->{module})]);
}

sub _node_module_func {
    my ($self, $obj) = @_;
    return $self->_constant(class => ref($obj), method => '__NEW__', label => 'ModuleFunc', args => [$self->_dump_string($obj->{module})]);
}

sub _node_nil { 'undef' }

sub _node_bool {
    my ($self, $obj) = @_;
    return 'Sidef::Types::Bool::Bool::' . (${$obj} ? 'TRUE' : 'FALSE');
}

# The array-like objects: `bless([...], 'Class')`
sub _array_literal {
    my ($self, $class, $array) = @_;
    $self->load_mod($class);
    return 'bless([' . join(',', grep { $_ ne '' } map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}) } @{$array}) . "], '${class}')";
}

sub _node_array {
    my ($self, $obj) = @_;
    return $self->_array_literal((ref($obj) eq 'Sidef::Types::Array::HCArray' ? 'Sidef::Types::Array::Array' : ref($obj)), $obj);
}

sub _node_vector { $_[0]->_array_literal('Sidef::Types::Array::Vector', $_[1]) }
sub _node_matrix { $_[0]->_array_literal('Sidef::Types::Array::Matrix', $_[1]) }

sub _node_pair {
    my ($self, $obj) = @_;
    return ref($obj) . '->new(' . join(',', map { defined($_) ? $self->_deparse_value($_) : 'undef' } @{$obj}) . ')';
}

sub _node_hash {
    my ($self, $obj) = @_;
    my $class = ref($obj);
    $self->load_mod($class);
    return
        'bless({'
      . join(',', map { $self->_dump_string($_) . '=>' . (defined($obj->{$_}) ? $self->_deparse_value($obj->{$_}) : 'undef') } sort(keys(%{$obj})))
      . "}, '${class}')";
}

sub _node_named_param {
    my ($self, $obj) = @_;
    return ref($obj) . '->new(' . $self->_dump_string($obj->{name}) . ', ' . $self->deparse_args(@{$obj->{value}}) . ')';
}

#----------------------------------------------------------------------
# Control flow
#----------------------------------------------------------------------

sub _node_if {
    my ($self, $obj) = @_;

    my $code = 'do{';

    foreach my $i (0 .. $#{$obj->{if}}) {
        my $info = $obj->{if}[$i];
        $code .= ($i == 0 ? 'if' : 'elsif') . '(' . $self->_condition($info->{expr}, $info->{block}) . ')' . $self->_deparse_scoped($info->{block});
    }

    if (exists $obj->{else}) {
        $code .= 'else' . $self->_deparse_scoped($obj->{else}{block});
    }

    return $code . '}';
}

sub _node_with {
    my ($self, $obj) = @_;

    my $code = 'do{';

    foreach my $i (0 .. $#{$obj->{with}}) {
        my $info = $obj->{with}[$i];
        my $vars = $self->_block_vars($info->{block});
        $code .= ($i == 0 ? 'if' : 'elsif');
        $code .= "(defined((my ($vars) = do{" . $self->deparse_args($info->{expr}) . '})[-1]))' . $self->_deparse_scoped($info->{block});
    }

    if (exists $obj->{else}) {
        $code .= 'else' . $self->_deparse_scoped($obj->{else}{block});
    }

    return $code . '}';
}

sub _node_while {
    my ($self, $obj) = @_;
    return 'while(' . $self->_condition($obj->{expr}, $obj->{block}) . ')' . $self->_deparse_scoped($obj->{block});
}

sub _node_foreach {
    my ($self, $obj) = @_;
    return $self->deparse_args($obj->{expr}) . '->each(' . $self->_deparse_value($obj->{block}) . ')';
}

sub _node_cfor {
    my ($self, $obj) = @_;
    return 'for(' . join(';', map { $self->deparse_args($_) } @{$obj->{expr}}) . ')' . $self->_deparse_scoped($obj->{block});
}

sub _node_forin {
    my ($self, $obj) = @_;

    $self->load_mod('Sidef::Types::Block::Block');

    my @loops = @{$obj->{loops}};
    my @binds = map { $self->_bind_params(@{$_->{vars}}) } @loops;

    my $code = 'do' . $self->_deparse_scoped($obj->{block});

    while (@loops) {
        my $loop = pop(@loops);
        my $bind = pop(@binds);
        my $expr = $self->deparse_args($loop->{expr});

        my $multi = (@{$loop->{vars}} > 1 or (@{$loop->{vars}} == 1 and exists($loop->{vars}[0]{slurpy})));

        $code =
          'Sidef::Types::Block::Block::_iterate(sub { ' . ($multi ? 'local @_ = @{$_[0]->to_a};' : '') . "$bind; $code }, $expr)" . (@loops ? ' // last' : '');
    }

    return $code;
}

sub _node_ternary {
    my ($self, $obj) = @_;
    return '(' . scalar($self->deparse_script($obj->{cond})) . '?' . $self->deparse_args($obj->{true}) . ':' . $self->deparse_args($obj->{false}) . ')';
}

sub _node_do {
    my ($self, $obj) = @_;
    return 'do' . $self->_deparse_scoped($obj->{block});
}

sub _node_loop {
    my ($self, $obj) = @_;
    return 'while(1)' . $self->_deparse_scoped($obj->{block});
}

sub _node_given {
    my ($self, $obj) = @_;

    my $vars = $self->_block_vars($obj->{block});

    return
        "sub { my \@given_values; my \$continue = 1; my \$given_value = (my ($vars) = "
      . $self->deparse_args($obj->{expr})
      . ')[-1];' . 'do'
      . $self->_deparse_scoped($obj->{block})
      . '; wantarray ? @given_values : $given_values[-1] }->()';
}

sub _node_when {
    my ($self, $obj) = @_;

    my $arg = $self->_condition($obj->{expr}, $obj->{block});

    return
        "if (\$continue) {my \$t = $arg;"
      . "if (defined(\$given_value) ? defined(\$t) ? Sidef::Object::Object::smartmatch(\$given_value, \$t) : 0 : 1) {"
      . "\$continue = 0; \@given_values = do"
      . $self->_deparse_scoped($obj->{block}) . "}};";
}

sub _node_case {
    my ($self, $obj) = @_;
    my $arg = $self->_condition($obj->{expr}, $obj->{block});
    return "if (\$continue and $arg) { \$continue = 0;" . "\@given_values = do" . $self->_deparse_scoped($obj->{block}) . '}';
}

sub _node_default {
    my ($self, $obj) = @_;
    return "if (\$continue) { \$continue = 0; \@given_values = do" . $self->_deparse_scoped($obj->{block}) . '}';
}

sub _node_gather {
    my ($self, $obj) = @_;
    $self->load_mod('Sidef::Types::Array::Array');
    my $id = $self->_id($obj);
    return "do{my \@_$id;do" . $self->_deparse_scoped($obj->{block}) . "; bless(\\\@_$id, 'Sidef::Types::Array::Array')}";
}

sub _node_take {
    my ($self, $obj) = @_;
    my $id = $self->_id($obj->{gather});
    return "do{ push \@_$id," . $self->deparse_args($obj->{expr}) . "; \$_$id\[-1] }";
}

sub _node_try {
    my ($self, $obj) = @_;
    return
      ref($obj) . '->new->try(' . $self->_deparse_value($obj->{try}) . ')->catch(' . (defined($obj->{catch}) ? $self->_deparse_value($obj->{catch}) : '') . ')';
}

#----------------------------------------------------------------------
# Classes
#
# A class is declared with a single call of Sidef::Object::Class->declare(),
# which implements the inheritance, the construction and the accessors.
# See Sidef::Object::Class for the rules.
#----------------------------------------------------------------------

sub _node_class_init {
    my ($self, $obj) = @_;

    my $package = $self->_class_package($obj);

    # Already declared: the class is its name
    $self->_first_time($obj, 'class') or return $self->_dump_string($package);

    my $ref_class = (ref($obj->{name}) ? 1 : 0);    # a built-in class that is extended

    local $self->{package_name} = $package;
    local $self->{class_name}   = $package;
    local $self->{ref_class}    = $ref_class;

    my $body = $self->_scoped_block(
        sub {
            my $declaration = ($ref_class ? $self->_extend_builtin($obj, $package) : $self->_class_declaration($obj, $package));
            return $declaration . $self->_statements($obj->{block}{code});
        }
    );

    return "do{package $package $body;" . $self->_dump_string($package) . '}';
}

# The call that declares a class (or a struct)
sub _declare_call {
    my ($self, %opt) = @_;

    $self->load_mod('Sidef::Object::Class');

    my @params = @{$opt{params}};
    my @attrs  = @{$opt{attrs} // []};

    my @fields = (
                  'key=>' . $self->_dump_string($opt{key}),
                  'package=>' . $self->_dump_string($opt{package}),
                  'name=>' . $self->_dump_string(Sidef::normalize_type($opt{package})),
                  'type=>' . $self->_dump_string($opt{type}),
                  'parents=>[' . join(',', map { $self->_dump_string($_) } @{$opt{parents} // []}) . ']',
                  'params=>' . $self->_param_descriptors(@params),
                  'attrs=>[' . join(',', map { $self->_dump_string($_->{name}) } map { @{$_->{vars}} } @attrs) . ']',
                  'defaults=>' . $self->_defaults_closure(@params),
                  'build=>' . $self->_build_closure(\@params, \@attrs),
                 );

    return 'Sidef::Object::Class->declare(' . join(',', @fields) . ');';
}

sub _class_declaration {
    my ($self, $obj, $package) = @_;

    my @parents = map { $self->_class_key($_) }
      grep { ref($_) eq 'Sidef::Variable::ClassInit' and not ref($_->{name}) } @{$obj->{inherit} // []};

    return
      $self->_declare_call(
                           key     => $self->_class_key($obj),
                           package => $package,
                           type    => 'class',
                           parents => \@parents,
                           params  => $obj->{vars}       // [],
                           attrs   => $obj->{attributes} // [],
                          );
}

# A built-in class that is extended: it only gets new parents (its methods are installed in place)
sub _extend_builtin {
    my ($self, $obj, $package) = @_;

    my @parents = map { $self->_class_package($_) }
      grep { ref($_) eq 'Sidef::Variable::ClassInit' and not ref($_->{name}) } @{$obj->{inherit} // []};

    @parents or return '';

    $self->load_mod('Sidef::Object::Class');
    return 'Sidef::Object::Class->extend(' . join(',', map { $self->_dump_string($_) } $package, @parents) . ');';
}

# The closure that evaluates the default values of the parameters.
# It's called for every class of the hierarchy, with the set of the fields that the class owns.
sub _defaults_closure {
    my ($self, @params) = @_;

    my @with_value = grep { exists $_->{value} } @params;

    @with_value or return 'undef';

    my ($declarations, $code) = $self->_with_scope(
        sub {
            my $code = $self->_bind_fields(@params);

            foreach my $var (@with_value) {

                my $name  = $self->_var($var);
                my $field = $self->_dump_string($var->{name});
                my $value = $self->_deparse_value($var->{value});

                if (exists $var->{array}) {
                    $code .= "if(\$own->{$field} and not \@{\$self->{$field}}){\@{\$self->{$field}}=($value)}";
                }
                elsif (exists $var->{hash}) {
                    $code .= "if(\$own->{$field} and not keys \%{\$self->{$field}}){\%{\$self->{$field}}=($value)}";
                }
                else {
                    $code .= "if(\$own->{$field}){$name//=$value;\$self->{$field}=$name}";
                }
            }

            return $code;
        }
    );

    return 'sub{my($self,$own)=@_;' . $declarations . $code . '}';
}

# The closure that evaluates the attributes (`has`) of a class
sub _build_closure {
    my ($self, $params, $attrs) = @_;

    @{$attrs} or return 'undef';

    my ($declarations, $code) = $self->_with_scope(
        sub {
            my $code = $self->_bind_fields(@{$params});

            foreach my $attr (@{$attrs}) {

                my @vars = @{$attr->{vars}};
                @vars or next;

                foreach my $var (@vars) {
                    my $name = $self->_bare_name($var);
                    $self->_hoist("my \$$name;");
                    $self->_hoist("my \@$name;") if exists $var->{array};
                    $self->_hoist("my \%$name;") if exists $var->{hash};
                }

                my @fields = map { $self->_dump_string($_->{name}) } @vars;
                my $when   = join(' or ', map { "\$own->{$_}" } @fields);
                my $args   = (exists($attr->{args}) ? $self->deparse_args($attr->{args}) : '()');

                my $statement = '(' . join(',', map { $self->_var_container($_) } @vars) . ")=$args;";
                $statement .= join('', map { $self->_initialize_var($_) } @vars);

                foreach my $i (0 .. $#vars) {
                    $statement .= "\$self->{$fields[$i]}=" . $self->_var($vars[$i]) . " if \$own->{$fields[$i]};";
                }

                $code .= "if($when){$statement}";
            }

            return $code;
        }
    );

    return 'sub{my($self,$own)=@_;' . $declarations . $code . '}';
}

# Structs are classes without inheritance and attributes
sub _node_struct {
    my ($self, $obj) = @_;

    my $package = $self->_named_package($obj);

    $self->_first_time($obj, 'struct') or return $self->_dump_string($package);

    return 'do{'
      . $self->_declare_call(
                             key     => 'struct#' . refaddr($obj),
                             package => $package,
                             type    => 'struct',
                             params  => $obj->{vars} // [],
                            )
      . $self->_dump_string($package) . '}';
}

# Subsets: a package with a validation function
sub _node_subset {
    my ($self, $obj) = @_;

    my $package = $self->_named_package($obj);

    $self->_first_time($obj, 'subset') or return $self->_dump_string($package);

    my @parents = map { $self->_type_name($_) } @{$obj->{inherits} // []};

    my $parents_check = '';
    if (@parents) {
        $parents_check =
          'foreach my $class (qw(@parents)) {' . q{my $code = UNIVERSAL::can($class, '__subset_validation__');} . '($code ? $code->(@_) : 1) || return;' . '};';
        $parents_check =~ s/\@parents/@parents/;
    }

    my ($declarations, $body) = $self->_with_scope(
        sub {
            if (exists $obj->{block}) {
                my $block = $obj->{block};
                return $self->_bind_params($block->{init_vars}{vars}[0]) . $parents_check . $self->_statements($block->{code});
            }
            return "$parents_check 1;";
        }
    );

    return
        "do{package $package {use parent qw(-norequire @parents);"
      . "my \$sub = sub {$declarations$body};"
      . "do{ no strict 'refs'; *{__PACKAGE__ . '::' . '__subset_validation__'} = \$sub };" . '};'
      . $self->_dump_string($package) . '}';
}

#----------------------------------------------------------------------
# Special objects
#----------------------------------------------------------------------

sub _filehandle_constant {
    my ($self, $label, $glob) = @_;
    return $self->_constant(class => 'Sidef::Types::Glob::FileHandle', method => 'new', label => $label, args => [$glob], cache => $label);
}

sub _node_stdin  { $_[0]->_filehandle_constant('STDIN',  '\*STDIN') }
sub _node_stdout { $_[0]->_filehandle_constant('STDOUT', '\*STDOUT') }
sub _node_stderr { $_[0]->_filehandle_constant('STDERR', '\*STDERR') }
sub _node_argf   { $_[0]->_filehandle_constant('ARGF',   '\*ARGV') }

sub _node_data {
    my ($self, $obj) = @_;
    require Encode;
    my $data = $self->_dump_string(Encode::encode_utf8(${$obj->{data}}));
    return $self->_filehandle_constant('DATA', qq{do{open my \$fh, '<:utf8', \\$data; \$fh}});
}

sub _node_parser { '$Sidef::PARSER' }

sub _node_prefix_method {
    my ($self, $obj) = @_;
    return 'do{my($self,@args)=' . $self->deparse_args($obj->{expr}) . ';$self->' . $obj->{name} . '(@args)}';
}

# The statements of a module, without braces
sub _node_meta_module {
    my ($self, $obj) = @_;
    return $self->_statements($obj->{block}{code});
}

sub _node_included {
    my ($self, $obj) = @_;
    return join('', map { $self->_statements($_->{ast}) . ';' } @{$obj->{included}});
}

sub _node_assert {
    my ($self, $obj) = @_;

    my $id   = $self->_id($obj);
    my @args = $self->deparse_script($obj->{arg});
    my $at   = "at \Q$obj->{file}\E line $obj->{line}";

    if ($obj->{act} eq 'assert') {
        @args > 2 and die "[ERROR] Incorrect number of arguments for $obj->{act}() $at (expected 1 or 2 arguments)\n";
        my $msg = $args[1] // 'undef';
        return
            qq~do{my \$a$id = do{$args[0]}; ~
          . qq~\$a$id or CORE::die((do{$msg} // "$obj->{act}(\$a$id)") . " failed ~
          . qq~at \Q$obj->{file}\E line $obj->{line}\\n")}~;
    }

    if ($obj->{act} eq 'assert_eq' or $obj->{act} eq 'assert_ne') {
        @args > 3 and die "[ERROR] Incorrect number of arguments for $obj->{act}() $at (expected 2 or 3 arguments)\n";
        return
            "do{"
          . "my \$a$id = do{$args[0]};"
          . "my \$b$id = do{$args[1]};"
          . ($obj->{act} eq 'assert_ne' ? qq{!(\$a$id eq \$b$id)} : qq{\$a$id eq \$b$id})
          . qq~ or CORE::die((~
          . (defined($args[2]) ? "do{$args[2]}" : "undef")
          . qq~// ('$obj->{act}('.~
          . qq~join(', ',map{(ref(\$_) && UNIVERSAL::can(\$_,'dump')) ? \$_->dump : \$_}(\$a$id, \$b$id)) . ')'))~
          . qq~." failed at \Q$obj->{file}\E line $obj->{line}\\n")}~;
    }

    return '';
}

sub _node_error {
    my ($self, $obj) = @_;
    my $args = $self->deparse_args($obj->{arg});
    return qq~do{CORE::die($args, " at \Q$obj->{file}\E line $obj->{line}\\n")}~;
}

sub _node_warning {
    my ($self, $obj) = @_;
    my $args = $self->deparse_args($obj->{arg});
    return qq~((CORE::warn($args, " at \Q$obj->{file}\E line $obj->{line}\\n")) ? ~ . qq~(Sidef::Types::Bool::Bool::FALSE) : (Sidef::Types::Bool::Bool::TRUE))~;
}

sub _node_unimplemented {
    my ($self, $obj) = @_;
    return qq{CORE::die "Unimplemented at " . } . $self->_dump_string($obj->{file}) . qq{ . " line $obj->{line}\\n"};
}

# eval(): the code is parsed and deparsed at run-time, with the state of the parser at the call site
sub _node_eval {
    my ($self, $obj) = @_;

    my $id = $self->_id($obj);
    $Sidef::EVALS{$id} = $obj;

    return "eval(Sidef::Deparse::Perl::__eval__($id, do{my\$o=" . $self->deparse_args($obj->{expr}) . ';"$o"}))';
}

# Called by the generated code of `eval`: returns the Perl code of a string of Sidef code
sub __eval__ {
    my ($id, $source) = @_;

    my $info     = $Sidef::EVALS{$id};
    my $parser   = $Sidef::PARSER;
    my $deparser = $Sidef::DEPARSER;

    my $ast = do {
        local @{$parser}{keys %{$info->{parser}}} = values %{$info->{parser}};
        local $parser->{line}                     = 1;
        local $parser->{eval_mode}                = 1;
        local $parser->{file_name}                = "eval($id)";
        $parser->parse_script(code => \$source);
    };

    return $deparser->deparse_nested($ast);
}

#----------------------------------------------------------------------
# Indices: array[...] and hash{...}
#----------------------------------------------------------------------

# When the entry is a wrapper of a single literal of one of the given types, returns the literal
sub _unwrap_literal {
    my ($self, $entry, $types) = @_;

    ref($entry) eq 'HASH' and exists($entry->{self}) and keys(%$entry) == 1 or return $entry;

    my $obj = $entry->{self};
    ref($obj) eq 'HASH' and keys(%$obj) == 1 and !exists($obj->{self}) or return $entry;

    my ($statements) = values %$obj;
    ref($statements) eq 'ARRAY' and @$statements == 1 or return $entry;

    my $statement = $statements->[0];
    ref($statement) eq 'HASH' and keys(%$statement) == 1 and exists($statement->{self}) or return $entry;

    return ($types->{ref($statement->{self})} ? $statement->{self} : $entry);
}

sub _dump_indices {
    my ($self, $array) = @_;

    my @indices;

    foreach my $entry (@{$array}) {

        $entry = $self->_unwrap_literal($entry, {'Sidef::Types::Number::Number' => 1});

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

    return join(',', @indices);
}

sub _dump_lookups {
    my ($self, $array) = @_;

    my @keys;

    foreach my $entry (@{$array}) {

        $entry = $self->_unwrap_literal($entry, {'Sidef::Types::String::String' => 1, 'Sidef::Types::Number::Number' => 1});

        if (ref($entry) eq 'Sidef::Types::String::String') {
            push @keys, $self->_dump_string($$entry);
        }
        elsif (ref($entry) eq 'Sidef::Types::Number::Number') {
            push @keys, $self->_dump_string("$entry");
        }
        elsif (ref($entry)) {
            my $str = $self->deparse_expr(ref($entry) eq 'HASH' ? $entry : {self => $entry});

            if ($str ne '') {
                push @keys, ('(map { ref($_) eq "Sidef::Types::String::String" ? $$_ : "$_" } ' . $str . ')');
            }
        }
        else {
            push @keys, $self->_dump_string($entry);
        }
    }

    return join(',', @keys);
}

sub _apply_indices {
    my ($self, $code, $indices) = @_;

    my $limit = $#{$indices};

    foreach my $i (0 .. $limit) {

        my $ind = $indices->[$i];

        if (exists $ind->{array}) {
            my $list = $self->_dump_indices($ind->{array});
            $code = '@{(' . $code . ')}';
            $code .= "[$list]" if $list ne '';
        }
        else {
            my $keys = $self->_dump_lookups($ind->{hash});
            $code = ($keys eq '' ? '%{(' . $code . ')}' : "\@{($code)}{$keys}");
        }

        # Autovivification of the intermediate containers
        if ($i < $limit) {
            if ($indices->[$i + 1]{array}) {
                $self->load_mod('Sidef::Types::Array::Array');
                $code = "($code//=bless([], 'Sidef::Types::Array::Array'))";
            }
            else {
                $self->load_mod('Sidef::Types::Hash::Hash');
                $code = "($code//=bless({}, 'Sidef::Types::Hash::Hash'))";
            }
        }
    }

    return $code;
}

#----------------------------------------------------------------------
# Method calls and operators
#----------------------------------------------------------------------

sub _bool_code {
    my ($self, $code) = @_;
    return "(($code) ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE)";
}

# The prefix operators (!, -, +, @, ...) applied on the argument of the call.
# Returns nothing for the operators that are not special.
sub _unary_operator {
    my ($self, $method, $call) = @_;

    my $args = sub { $self->deparse_args(@{$call->{arg} // []}) };

    if ($method eq '!') {
        return '(' . $args->() . '? Sidef::Types::Bool::Bool::FALSE : Sidef::Types::Bool::Bool::TRUE)';
    }

    if ($method eq '-') {

        # Constant folding: the negation of a number literal
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
                    return $self->_deparse_value($data->neg);
                }
            }
        }

        return $args->() . '->neg';
    }

    if ($method eq '+') {
        return 'scalar' . $args->();
    }

    if ($method eq '@') {
        $self->load_mod('Sidef::Types::Array::Array');
        return
            '(do{my$obj='
          . $args->()
          . ';my$sub=ref($obj) && UNIVERSAL::can($obj, "to_a"); '
          . '$sub ? $sub->($obj) : bless([$obj], "Sidef::Types::Array::Array")})';
    }

    if ($method eq '@|') {
        return '(do{my$obj=' . $args->() . ';my$sub=ref($obj) && UNIVERSAL::can($obj, "..."); ' . '$sub ? $sub->($obj) : $obj })';
    }

    return $args->() . '->not'   if $method eq '~';
    return $args->() . '->sqrt'  if $method eq '√';
    return $args->() . '->range' if $method eq '^';

    if ($method eq 'say' or $method eq '>') {
        return $self->_bool_code('CORE::say' . $args->());
    }

    if ($method eq 'print' or $method eq '>>') {
        return $self->_bool_code('CORE::print' . $args->());
    }

    if ($method eq 'defined') {
        return $self->_bool_code('CORE::defined' . $args->());
    }

    return;
}

# The operators and the calls that are compiled into special code.
# Returns the new code, or nothing when the call is an ordinary method call.
sub _special_call {
    my ($self, $ref, $code, $call, $index, $unary) = @_;

    my $method = $call->{method};
    my @args   = @{$call->{arg} // []};

    # Hash literals: Hash(...) and :(...)
    if (   ($ref eq 'Sidef::DataTypes::Hash::Hash' and $index == 0 and ($method eq 'call' or $method eq 'new'))
        or ($ref eq 'Sidef::Meta::PrefixColon' and $method eq ':')) {
        return 'bless({' . $self->deparse_args(@args) . "}, '$DATA_TYPES{$ref}')";
    }

    # The return statement
    if ($ref eq 'Sidef::Types::Block::Return') {

        if (defined $self->{function}) {
            my $result = $code . 'do{';
            $result .= '@return=' . $self->deparse_args(@args) . ';' if @args;
            return $result . "goto END_$self->{function}}";
        }

        return $code . 'return' . $self->deparse_args(@args);
    }

    defined($method) or return;

    # Variable references: \x, &x, *x, ++x, --x
    if ($ref eq 'Sidef::Variable::Ref') {

        return '\\' . $self->deparse_args(@args)       if ($method eq '\\' or $method eq '&');
        return '${' . $self->deparse_args(@args) . '}' if $method eq '*';

        if (exists $INC_DEC_OPS{$method}) {
            my $var = $self->deparse_args(@args);
            return "do{my\$r=\\$var;\$\$r=\$\$r\->$INC_DEC_OPS{$method}}";
        }
    }

    # Postfix ++ and --
    if (exists $INC_DEC_OPS{$method}) {
        return "do{my\$r=\\$code;my\$v=\$\$r;\$\$r=\$v\->$INC_DEC_OPS{$method};\$v}";
    }

    if (exists $LAZY_OPS{$method}) {
        return $code . $LAZY_OPS{$method} . $self->deparse_args(@args);
    }

    if ($method eq '=') {
        return "($code=" . $self->deparse_args(@args) . ")[-1]";
    }

    # Reassignment operators: +=, -=, *=, /=, ...
    if (exists $REASSIGN_OPS{$method}) {
        return "CORE::sub:lvalue{my\$r=\\$code;\$\$r=\$\$r" . $self->_op_call($REASSIGN_OPS{$method}) . $self->deparse_args(@args) . '}->()';
    }

    # == and !=
    if ($method eq '==' or $method eq '!=') {
        return
            'do{my$bool='
          . $code . 'eq'
          . $self->deparse_args(@args)
          . ';ref($bool) ? $bool : ($bool ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE)}'
          . ($method eq '!=' ? '->not' : '');
    }

    # ~~ and !~
    if ($method eq '~~' or $method eq '!~') {
        return
            'do{my$bool=Sidef::Object::Object::smartmatch(do{'
          . $code
          . '}, do{'
          . $self->deparse_args(@args)
          . '});ref($bool) ? $bool : ($bool ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE)}'
          . ($method eq '!~' ? '->not' : '');
    }

    # <=>
    if ($method eq '<=>') {
        return
            'do{my$cmp='
          . $code . 'cmp'
          . $self->deparse_args(@args)
          . ';ref($cmp) ? $cmp : defined($cmp) ? (($cmp<0) ? Sidef::Types::Number::Number::MONE : '
          . '($cmp>0) ? Sidef::Types::Number::Number::ONE : Sidef::Types::Number::Number::ZERO) : undef}';
    }

    # The prefix operators
    if ($ref eq 'Sidef::Operator::Unary' and not ${$unary}) {
        ${$unary} = 1;    # only the first call of the chain
        return $self->_unary_operator($method, $call);
    }

    return;
}

# An ordinary method call, with its optional arguments or keyword
sub _generic_call {
    my ($self, $code, $call) = @_;

    my $method = $call->{method};

    if (defined $method) {

        if (ref($method)) {
            $code .= '->${\\do{' . $self->deparse_expr(ref($method) eq 'HASH' ? $method : {self => $method}) . '}}';
        }
        elsif ($method =~ /^[^\W\d]/) {

            # A method that ends with `!` modifies the object in place
            if (substr($method, -1) eq '!') {
                return
                    "CORE::sub:lvalue{my\$r=\\$code;\$\$r=\$\$r\->"
                  . substr($method, 0, -1)
                  . (exists($call->{arg}) ? $self->deparse_args(@{$call->{arg}}) : '') . '}->()';
            }

            $code .= '->' if $code ne '';
            $code .= $method;
        }
        else {
            $code .= $self->_op_call($method);
        }
    }

    if (exists $call->{keyword}) {

        if ($call->{keyword} eq 'if') {
            return $self->deparse_args(@{$call->{arg} // []}) . '&&' . $code;
        }

        $code .= $call->{keyword};
    }

    if (exists $call->{arg}) {
        $code .= $self->deparse_args(@{$call->{arg}});
    }

    return $code;
}

sub _apply_calls {
    my ($self, $ref, $code, $calls) = @_;

    my $unary;

    foreach my $i (0 .. $#{$calls}) {

        my $call = $calls->[$i];

        if ($code ne '') {
            $code = '(' . $code . ')';
        }

        my $special = $self->_special_call($ref, $code, $call, $i, \$unary);

        $code = (defined($special) ? $special : $self->_generic_call($code, $call));
    }

    return $code;
}

#----------------------------------------------------------------------
# Main logic
#----------------------------------------------------------------------

# Deparses an expression: {self => OBJECT, ind => [...], call => [...]}
sub deparse_expr {
    my ($self, $expr) = @_;

    my $obj = $expr->{self};
    my $ref = ref($obj) || return '';

    my $code;

    if (exists $NODE_HANDLERS{$ref}) {
        my $method = $NODE_HANDLERS{$ref};
        $code = $self->$method($obj, $expr);
    }
    elsif ($ref eq 'HASH') {
        $code = join(',', exists($obj->{self}) ? $self->deparse_expr($obj) : $self->deparse_script($obj));
    }
    elsif (exists $COMPOSITE_CONSTANTS{$ref}) {
        my ($label, @fields) = @{$COMPOSITE_CONSTANTS{$ref}};
        $code = $self->_constant(
                                 class  => $ref,
                                 method => 'new',
                                 label  => $label,
                                 args   => [map { $self->_deparse_value($obj->{$_}) } @fields],
                                );
    }
    elsif (exists $DATA_TYPES{$ref}) {
        my $module = $DATA_TYPES{$ref};
        $self->load_mod($module);
        $code = "'$module'";
    }
    else {
        die "[PERL DEPARSER BUG] Unknown object of type <<$ref>>";
    }

    if (exists $expr->{ind}) {
        $code = $self->_apply_indices($code, $expr->{ind});
    }

    if (exists $expr->{call}) {
        $code = $self->_apply_calls($ref, $code, $expr->{call});
    }

    return ($code eq '' ? '()' : $code);
}

# Deparses a sequence of statements: {namespace => [statement, ...]}
# In scalar context, returns the last statement.
sub deparse_script {
    my ($self, $struct) = @_;

    my @results;

    foreach my $namespace (sort keys %{$struct}) {
        foreach my $expr (@{$struct->{$namespace}}) {
            push @results, $self->deparse_expr(ref($expr) eq 'HASH' ? $expr : {self => $expr});
        }
    }

    return (wantarray ? @results : $results[-1]);
}

sub _program {
    my ($self, $ast, %opt) = @_;

    my ($declarations, @statements) = $self->_with_scope(sub { $self->deparse_script($ast) });

    my $code = $self->{before} . join('', @{$self->{preamble}}) . $declarations . join($self->{between}, @statements) . $self->{after};

    return ($opt{header} ? ($code =~ s/^\s*/$self->{header}/r) : $code);
}

# Deparses the AST of a program
sub deparse {
    my ($self, $ast) = @_;
    return $self->_program($ast, header => 1);
}

# Deparses a piece of code at run-time (see `eval`), in the context of the program that is running
sub deparse_nested {
    my ($self, $ast) = @_;

    local $self->{before}   = '';
    local $self->{after}    = '';
    local $self->{preamble} = [];
    local $self->{frames}   = [];

    return $self->_program($ast, header => 0);
}

1
