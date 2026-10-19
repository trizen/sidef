package Sidef::Parser;

use utf8;
use 5.016;

use Sidef::Types::Bool::Bool;
use List::Util   qw(first);
use Scalar::Util qw(refaddr);

# ---------------------------------------------------------------------------
# Sidef::Parser
#
# A recursive-descent parser that builds the AST (nested hashes and objects) which is
# used by the deparsers (Sidef::Deparse::Sidef and Sidef::Deparse::Perl).
#
# From the highest to the lowest level:
#
#   parse_script   a sequence of statements, until the end of the code or a closing delimiter
#   parse_obj      an expression, with the operator precedence (parse_operand + parse_infix)
#   parse_operand  a term with its prefix operator, calls, indices and method calls
#   parse_expr     a single term: literals, keywords, declarations, variables (it dispatches
#                  to the `_parse_*` handlers)
#
# The code is always passed as a reference (`code => \$code`) and the parsers move
# `pos($code)` forward. When the code is invalid, they die with fatal_error().
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Operator precedence
#
# The precedence of the binary operators is similar to the one from Ruby.
# The operators are listed from the highest to the lowest precedence:
#
#   terms, .method, [...], {...}, (...)                      postfix:   n!  x++  list...
#   !  ~  \  unary+  *  √  ^  @  @|  (prefix operators)      PREC_OPERAND
#   **                                                       PREC_POW         (right)
#   unary -                                                  (its argument is parsed at PREC_POW)
#   *  /  //  %  %%  ÷  ...                                  PREC_MUL  (`//` is the integer division)
#   +  -                                                     PREC_ADD
#   <<  >>                                                   PREC_SHIFT
#   ..  ^..  ..^                                             PREC_RANGE
#   a `method` b,  |>  |>>  |X>  |Z>,  »op»  ~Zop  ~Xop ...  PREC_WORD_OP    (chained from left to right)
#   &                                                        PREC_BITAND
#   |  ^                                                     PREC_BITOR
#   <  <=  >  >=  ∈ ...                                      PREC_RELATIONAL
#   ==  !=  <=>  ~~  =~  !~ ...                              PREC_EQUALITY
#   &&                                                       PREC_ANDAND
#   ||  \\  (defined-or)                                      PREC_OROR
#   :  ：  ⫶  (pair constructors)                            PREC_PAIR
#   ?:                                                       PREC_TERNARY     (right)
#   =                                                        PREC_ASSIGN      (right)
#   +=  -=  *=  :=  ||=  etc.                                PREC_ASSIGN      (left: `x += 1 *= 2` is `(x += 1) *= 2`)
#   and                                                      PREC_AND
#   or                                                       PREC_OR
#   if  while  (statement modifiers)                         PREC_STMT
#   expr -> method                                           PREC_ARROW       (applies on the whole expression from its left)
#
# Some examples:
#
#   2 + 3 * 4            is  2 + (3 * 4)
#   -2 ** 2              is  -(2 ** 2)
#   x & 1 == 0           is  (x & 1) == 0
#   1..n+1               is  1..(n+1)
#   x ~~ 1..5            is  x ~~ (1..5)
#   1..9 `by` 2          is  (1..9) `by` 2
#   a.len `add` 2 == 3   is  (a.len `add` 2) == 3
#   var x = "a":1        is  var x = ("a":1)
#   a || b ? c : d       is  (a || b) ? c : d
#   a = b ? c : d        is  a = (b ? c : d)
#   a and b or c         is  (a and b) or c
#
# Unlike Ruby, `and` binds tighter than `or`, as in all the other languages.
# ---------------------------------------------------------------------------

use constant {
              PREC_ARROW      => 5,
              PREC_STMT       => 10,
              PREC_OR         => 20,
              PREC_AND        => 30,
              PREC_NOT        => 35,
              PREC_ASSIGN     => 50,
              PREC_TERNARY    => 60,
              PREC_PAIR       => 65,
              PREC_OROR       => 80,
              PREC_ANDAND     => 90,
              PREC_EQUALITY   => 100,
              PREC_RELATIONAL => 110,
              PREC_BITOR      => 120,
              PREC_BITAND     => 130,
              PREC_WORD_OP    => 140,
              PREC_RANGE      => 150,
              PREC_SHIFT      => 160,
              PREC_ADD        => 170,
              PREC_MUL        => 180,
              PREC_POW        => 200,
              PREC_OPERAND    => 100_000,    # parse only an operand (no infix operators)
             };

# Precedence and associativity (L = left, R = right) of the infix operators.
my %INFIX_PREC;

{
    my @table = (
                 [PREC_POW,        'R', '**'],
                 [PREC_MUL,        'L', '*',  '/',   '//', '%', '%%', '÷', '×', '⋅', '∙', '∘', '∩', '⊗', '∣', '∤'],
                 [PREC_ADD,        'L', '+',  '-',   '−',  '∪', '∖',  '⊕', '⊖', '⊎'],
                 [PREC_SHIFT,      'L', '<<', '>>',  '≪',  '≫'],
                 [PREC_RANGE,      'L', '..', '^..', '..^'],
                 [PREC_WORD_OP,    'L', '|>', '|>>', '|X>', '|Z>'],
                 [PREC_BITAND,     'L', '&'],
                 [PREC_OPERAND,    'L', ':='],
                 [PREC_BITOR,      'L', '|',  '^',  '⊻'],
                 [PREC_RELATIONAL, 'L', '<',  '>',  '<=',  '>=', '≤',   '≥',   '∈', '∉', '∋', '∌', '⊂', '⊃', '⊄',  '⊅', '⊆', '⊇', '⊈', '⊉'],
                 [PREC_EQUALITY,   'L', '==', '!=', '<=>', '~~', '<~>', '=~=', '≅', '≠', '≡', '≢', '≈', '≉', '=~', '!~'],
                 [PREC_ANDAND,     'L', '&&', '∧'],
                 [PREC_OROR,       'L', '||', '\\\\', '∨'],
                 [PREC_PAIR,       'L', ':',  '：',    '⫶'],
                 [PREC_ASSIGN,     'R', '='],
                 [PREC_ASSIGN,     'L', '||=', '&&=', '//=', '\\\\=', '+=', '-=', '*=', '/=', '÷=', '%=', '**=', '^=', '|=', '&=', '<<=', '>>='],
                );

    foreach my $row (@table) {
        my ($prec, $assoc, @ops) = @{$row};
        $INFIX_PREC{$_} = [$prec, $assoc] for @ops;
    }
}

# Comparison operators that can be chained: `a < b <= c`  =>  `a < b && b <= c`
# (the middle operands are evaluated only once)
my %CHAIN_CLASS = (
                   '<'  => 'relational',
                   '>'  => 'relational',
                   '<=' => 'relational',
                   '>=' => 'relational',
                   '≤'  => 'relational',
                   '≥'  => 'relational',
                   '==' => 'equality',
                   '!=' => 'equality',
                   '≠'  => 'equality',
                  );

# Closing delimiters: [counter of the open delimiters, name, opening delimiter]
my %CLOSING_DELIMITERS = (
    ']' => ['right_brackets', 'right bracket', '['],
    '}' => ['curly_brackets', 'curly bracket', '{'],
    ')' => ['parentheses',    'parenthesis',   '('],
                         );

# Precedence of the keyword operators
my %KEYWORD_PREC = (
                    'if'     => PREC_STMT,
                    'while'  => PREC_STMT,
                    'unless' => PREC_STMT,
                    'until'  => PREC_STMT,
                    'or'     => PREC_OR,
                    'and'    => PREC_AND,
                   );

# ---------------------------------------------------------------------------
# Lexical tables and regular expressions (shared by all the parser objects)
# ---------------------------------------------------------------------------

# Postfix operators
my %POSTFIX_OPS = map { $_ => 1 } qw(-- ++ ... ! !!);

# Hyper-operators: type => [takes args, method name]
my %HYPER_OPS = (
                 map     => [1, 'map_operator'],
                 pam     => [1, 'pam_operator'],
                 zip     => [1, 'zip_operator'],
                 wise    => [1, 'wise_operator'],
                 scalar  => [1, 'scalar_operator'],
                 rscalar => [1, 'rscalar_operator'],
                 cross   => [1, 'cross_operator'],
                 unroll  => [1, 'unroll_operator'],
                 reduce  => [0, 'reduce_operator'],
                 lmap    => [0, 'map_operator'],
                );

# Static objects: keywords and special variables that are replaced by objects
my $STATIC_OBJ_RE = qr{\G
    (?:
           nil\b                          (?{ state $x = bless({}, 'Sidef::Types::Nil::Nil') })
         | null\b                         (?{ state $x = Sidef::Types::Null::Null->new })
         | true\b                         (?{ Sidef::Types::Bool::Bool::TRUE })
         | false\b                        (?{ Sidef::Types::Bool::Bool::FALSE })
         | next\b                         (?{ state $x = bless({}, 'Sidef::Types::Block::Next') })
         | break\b                        (?{ state $x = bless({}, 'Sidef::Types::Block::Break') })
         | Block\b                        (?{ state $x = bless({}, 'Sidef::DataTypes::Block::Block') })
         | Backtick\b                     (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::Backtick') })
         | ARGF\b                         (?{ state $x = bless({}, 'Sidef::Meta::Glob::ARGF') })
         | STDIN\b                        (?{ state $x = bless({}, 'Sidef::Meta::Glob::STDIN') })
         | STDOUT\b                       (?{ state $x = bless({}, 'Sidef::Meta::Glob::STDOUT') })
         | STDERR\b                       (?{ state $x = bless({}, 'Sidef::Meta::Glob::STDERR') })
         | Bool\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Bool::Bool') })
         | FileHandle\b                   (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::FileHandle') })
         | DirHandle\b                    (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::DirHandle') })
         | SocketHandle\b                 (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::SocketHandle') })
         | Dir\b                          (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::Dir') })
         | File\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::File') })
         | Arr(?:ay)?+\b                  (?{ state $x = bless({}, 'Sidef::DataTypes::Array::Array') })
         | Pair\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Array::Pair') })
         | Vec(?:tor)?\b                  (?{ state $x = bless({}, 'Sidef::DataTypes::Array::Vector') })
         | Matrix\b                       (?{ state $x = bless({}, 'Sidef::DataTypes::Array::Matrix') })
         | Hash\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Hash::Hash') })
         | Set\b                          (?{ state $x = bless({}, 'Sidef::DataTypes::Set::Set') })
         | Bag\b                          (?{ state $x = bless({}, 'Sidef::DataTypes::Set::Bag') })
         | Str(?:ing)?+\b                 (?{ state $x = bless({}, 'Sidef::DataTypes::String::String') })
         | Num(?:ber)?+\b                 (?{ state $x = bless({}, 'Sidef::DataTypes::Number::Number') })
         | Mod\b                          (?{ state $x = bless({}, 'Sidef::DataTypes::Number::Mod') })
         | Gauss\b                        (?{ state $x = bless({}, 'Sidef::DataTypes::Number::Gauss') })
         | Quadratic\b                    (?{ state $x = bless({}, 'Sidef::DataTypes::Number::Quadratic') })
         | Quaternion\b                   (?{ state $x = bless({}, 'Sidef::DataTypes::Number::Quaternion') })
         | Poly(?:nomial)?\b              (?{ state $x = bless({}, 'Sidef::DataTypes::Number::Polynomial') })
         | Poly(?:nomial)?Mod\b           (?{ state $x = bless({}, 'Sidef::DataTypes::Number::PolynomialMod') })
         | Frac(?:tion)?\b                (?{ state $x = bless({}, 'Sidef::DataTypes::Number::Fraction') })
         | Inf\b                          (?{ state $x = Sidef::Types::Number::Number->inf })
         | NaN\b                          (?{ state $x = Sidef::Types::Number::Number->nan })
         | Infi\b                         (?{ state $x = Sidef::Types::Number::Complex->new(0, Sidef::Types::Number::Number->inf) })
         | NaNi\b                         (?{ state $x = Sidef::Types::Number::Complex->new(0, Sidef::Types::Number::Number->nan) })
         | RangeNum(?:ber)?+\b            (?{ state $x = bless({}, 'Sidef::DataTypes::Range::RangeNumber') })
         | RangeStr(?:ing)?+\b            (?{ state $x = bless({}, 'Sidef::DataTypes::Range::RangeString') })
         | Range\b                        (?{ state $x = bless({}, 'Sidef::DataTypes::Range::Range') })
         | Socket\b                       (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::Socket') })
         | Pipe\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::Pipe') })
         | Ref\b                          (?{ state $x = bless({}, 'Sidef::Variable::Ref') })
         | NamedParam\b                   (?{ state $x = bless({}, 'Sidef::DataTypes::Variable::NamedParam') })
         | Lazy\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Object::Lazy') })
         | LazyMethod\b                   (?{ state $x = bless({}, 'Sidef::DataTypes::Object::LazyMethod') })
         | Enumerator\b                   (?{ state $x = bless({}, 'Sidef::DataTypes::Object::Enumerator') })
         | Complex\b                      (?{ state $x = bless({}, 'Sidef::DataTypes::Number::Complex') })
         | Regexp?\b                      (?{ state $x = bless({}, 'Sidef::DataTypes::Regex::Regex') })
         | Object\b                       (?{ state $x = bless({}, 'Sidef::DataTypes::Object::Object') })
         | Sidef\b                        (?{ state $x = bless({}, 'Sidef::DataTypes::Sidef::Sidef') })
         | Sig\b                          (?{ state $x = bless({}, 'Sidef::Sys::Sig') })
         | Sys\b                          (?{ state $x = bless({}, 'Sidef::Sys::Sys') })
         | Perl\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Perl::Perl') })
         | Math\b                         (?{ state $x = bless({}, 'Sidef::Math::Math') })
         | Time\b                         (?{ state $x = Sidef::Time::Time->new })
         | Date\b                         (?{ state $x = Sidef::Time::Date->new })
         | \$\.                           (?{ state $x = bless({name => '$.'}, 'Sidef::Variable::Magic') })
         | \$\?                           (?{ state $x = bless({name => '$?'}, 'Sidef::Variable::Magic') })
         | \$\$                           (?{ state $x = bless({name => '$$'}, 'Sidef::Variable::Magic') })
         | \$\^T\b                        (?{ state $x = bless({name => '$^T'}, 'Sidef::Variable::Magic') })
         | \$\|                           (?{ state $x = bless({name => '$|'}, 'Sidef::Variable::Magic') })
         | \$!                            (?{ state $x = bless({name => '$!'}, 'Sidef::Variable::Magic') })
         | \$"                            (?{ state $x = bless({name => '$"'}, 'Sidef::Variable::Magic') })
         | \$\\                           (?{ state $x = bless({name => '$\\'}, 'Sidef::Variable::Magic') })
         | \$@                            (?{ state $x = bless({name => '$@'}, 'Sidef::Variable::Magic') })
         | \$%                            (?{ state $x = bless({name => '$%'}, 'Sidef::Variable::Magic') })
         | \$~                            (?{ state $x = bless({name => '$~'}, 'Sidef::Variable::Magic') })
         | \$/                            (?{ state $x = bless({name => '$/'}, 'Sidef::Variable::Magic') })
         | \$&                            (?{ state $x = bless({name => '$&'}, 'Sidef::Variable::Magic') })
         | \$'                            (?{ state $x = bless({name => '$\''}, 'Sidef::Variable::Magic') })
         | \$`                            (?{ state $x = bless({name => '$`'}, 'Sidef::Variable::Magic') })
         | \$:                            (?{ state $x = bless({name => '$:'}, 'Sidef::Variable::Magic') })
         | \$\]                           (?{ state $x = bless({name => '$]'}, 'Sidef::Variable::Magic') })
         | \$\[                           (?{ state $x = bless({name => '$['}, 'Sidef::Variable::Magic') })
         | \$;                            (?{ state $x = bless({name => '$;'}, 'Sidef::Variable::Magic') })
         | \$,                            (?{ state $x = bless({name => '$,'}, 'Sidef::Variable::Magic') })
         | \$\^O\b                        (?{ state $x = bless({name => '$^O'}, 'Sidef::Variable::Magic') })
         | \$\^PERL\b                     (?{ state $x = bless({name => '$^X', dump => '$^PERL'}, 'Sidef::Variable::Magic') })
         | (?:\$0|\$\^SIDEF)\b            (?{ state $x = bless({name => '$0', dump => '$^SIDEF'}, 'Sidef::Variable::Magic') })
         | \$\)                           (?{ state $x = bless({name => '$)'}, 'Sidef::Variable::Magic') })
         | \$\(                           (?{ state $x = bless({name => '$('}, 'Sidef::Variable::Magic') })
         | \$<                            (?{ state $x = bless({name => '$<'}, 'Sidef::Variable::Magic') })
         | \$>                            (?{ state $x = bless({name => '$>'}, 'Sidef::Variable::Magic') })
         | ∞                              (?{ state $x = Sidef::Types::Number::Number->inf })
    ) (?!::)
}x;

# Prefix operators and control-flow keywords: (object, takes an argument, matched text)
my $PREFIX_OBJ_RE = qr{\G
  (?:
      if\b                                       (?{ bless({}, 'Sidef::Types::Block::If') })
    | with\b                                     (?{ bless({}, 'Sidef::Types::Block::With') })
    | while\b                                    (?{ bless({}, 'Sidef::Types::Block::While') })
    | unless\b                                   (?{ bless({}, 'Sidef::Types::Block::If') })
    | until\b                                    (?{ bless({}, 'Sidef::Types::Block::While') })
    | foreach\b                                  (?{ bless({}, 'Sidef::Types::Block::ForEach') })
    | for\b                                      (?{ bless({}, 'Sidef::Types::Block::For') })
    | return\b                                   (?{ state $x = bless({}, 'Sidef::Types::Block::Return') })
    | read\b                                     (?{ state $x = Sidef::Sys::Sys->new })
    | goto\b                                     (?{ state $x = bless({}, 'Sidef::Perl::Builtin') })
    | (?:[*\\]|\+\+|--)                          (?{ state $x = bless({}, 'Sidef::Variable::Ref') })
    | (?:>>?|\@\|?|[√+~!\-\^]|
        (?:
            say
          | print
          | defined
        )\b)                                     (?{ state $x = bless({}, 'Sidef::Operator::Unary') })
    | :                                          (?{ state $x = bless({}, 'Sidef::Meta::PrefixColon') })
  )
}x;

# Quote-like operators: [is double-quoted, method name, class name]
my $QUOTE_OPERATORS_RE = qr{\G
 (?:
    # String
     (?: ['‘‚’] | %q\b. )                                      (?{ [qw(0 new Sidef::Types::String::String)] })
    |(?: ["“„”] | %(?:Q\b. | (?!\w). ))                        (?{ [qw(1 new Sidef::Types::String::String)] })

    # File
    | %f\b.                                                    (?{ [qw(0 new Sidef::Types::Glob::File)] })
    | %F\b.                                                    (?{ [qw(1 new Sidef::Types::Glob::File)] })

    # Dir
    | %d\b.                                                    (?{ [qw(0 new Sidef::Types::Glob::Dir)] })
    | %D\b.                                                    (?{ [qw(1 new Sidef::Types::Glob::Dir)] })

    # Pipe
    | %p\b.                                                    (?{ [qw(0 pipe Sidef::Types::Glob::Pipe)] })
    | %P\b.                                                    (?{ [qw(1 pipe Sidef::Types::Glob::Pipe)] })

    # Backtick
    | %x\b.                                                    (?{ [qw(0 new Sidef::Types::Glob::Backtick)] })
    | (?: %X\b. | ` )                                          (?{ [qw(1 new Sidef::Types::Glob::Backtick)] })

    # Bytes
    | %b\b.                                                    (?{ [qw(0 bytes Sidef::Types::Array::Array)] })
    | %B\b.                                                    (?{ [qw(1 bytes Sidef::Types::Array::Array)] })

    # Chars
    | %c\b.                                                    (?{ [qw(0 chars Sidef::Types::Array::Array)] })
    | %C\b.                                                    (?{ [qw(1 chars Sidef::Types::Array::Array)] })

    # Graphemes
    | %g\b.                                                    (?{ [qw(0 graphemes Sidef::Types::Array::Array)] })
    | %G\b.                                                    (?{ [qw(1 graphemes Sidef::Types::Array::Array)] })

    # Symbols
    | %[Os]\b.                                                 (?{ [qw(0 __NEW__ Sidef::Module::OO)] })
    | %S\b.                                                    (?{ [qw(0 __NEW__ Sidef::Module::Func)] })

    # Arbitrary Perl code
    | %perl\b.                                                 (?{ [qw(0 new Sidef::Types::Perl::Perl)] })
    | %Perl\b.                                                 (?{ [qw(1 new Sidef::Types::Perl::Perl)] })
 )
}xs;

# Names of the built-in classes (they can't be redefined)
my %BUILT_IN_CLASSES = map { $_ => 1 } qw(
  File                  FileHandle            Dir                   DirHandle
  Arr                   Array                 Pair                  Vec
  Vector                Matrix                Enumerator            Hash
  Set                   Bag                   Str                   String
  Num                   Number                Poly                  Polynomial
  PolyMod               PolynomialMod         Frac                  Fraction
  Mod                   Gauss                 Quadratic             Quaternion
  Range                 RangeStr              RangeString           RangeNum
  RangeNumber           Complex               Math                  Pipe
  Ref                   Socket                SocketHandle          Bool
  Sys                   Sig                   Regex                 Regexp
  Time                  Date                  Perl                  Sidef
  Object                Parser                Block                 Backtick
  Lazy                  LazyMethod            NamedParam            true
  false                 nil                   null
);

# Reserved words (they can't be used as variable names)
my %KEYWORDS = map { $_ => 1 } qw(
  next                  break                 return                for
  foreach               if                    elsif                 else
  unless                until                 not                   with
  orwith                while                 given                 continue
  import                include               eval                  read
  die                   warn                  assert                assert_eq
  assert_ne             local                 global                var
  del                   const                 func                  enum
  class                 static                define                struct
  subset                module                DATA                  ARGV
  ARGF                  ENV                   STDIN                 STDOUT
  STDERR                __FILE__              __LINE__              __END__
  __DATA__              __TIME__              __DATE__              __NAMESPACE__
  __COMPILED__          __OPTIMIZED__
);

# Words that have a special meaning in parse_expr(). Any other plain identifier
# is a variable, which allows skipping all the other checks (see `parse_expr`).
my @SPECIAL_WORDS = qw(
  say print defined goto unless until not do loop try catch gather take
  when case default has method eval Parser Inf NaN Infi NaNi
  Arr Array Vec Vector Str String Num Number Poly Polynomial
  PolyMod PolynomialMod Frac Fraction Regex Regexp elif elseif
  RangeNum RangeNumber RangeStr RangeString
);

# Small regular expressions
my $MATCH_FLAGS_RE  = qr{[msixpogcaludn]+};
my $VAR_NAME_RE     = qr/[^\W\d]\w*+(?>::[^\W\d]\w*)*/;
my $METHOD_NAME_RE  = qr/[^\W\d]\w*+!?/;
my $VAR_INIT_SEP_RE = qr/\G\h*(?:=>|[=:])\h*/;

# The code of an interpolation block: #{ ... }
# It can contain balanced brackets, and nested strings ("...", '...', `...`) which
# can use the same delimiter as the string that contains the block. The nested
# double-quoted strings can have interpolation blocks too.
my $INTERPOLATION_RE = qr{
    (?(DEFINE)
        (?<sf_interp> \# \{ (?&sf_code) \} )
        (?<sf_code>
            (?>
                [^"'`\\\{\}\(\)\[\]\#]++
              | \\ .
              | (?&sf_dq)
              | (?&sf_sq)
              | (?&sf_bt)
              | \{ (?&sf_code) \}
              | \( (?&sf_code) \)
              | \[ (?&sf_code) \]
              | \#
            )*+
        )
        (?<sf_dq> " (?> [^\\"\#]++ | \\ . | \# (?!\{) | (?&sf_interp) )*+ " )
        (?<sf_sq> ' (?> [^\\']++ | \\ . )*+ ' )
        (?<sf_bt> ` (?> [^\\`]++ | \\ . )*+ ` )
    )
}xs;

# Unescapes the delimiters (\" => ") in the code of an interpolation block,
# but not inside the nested strings (they are parsed again later).
sub _unescape_block {
    my ($block, $delims) = @_;

    return $block =~ s{
        $INTERPOLATION_RE
        (?<str> (?&sf_dq) | (?&sf_sq) | (?&sf_bt) )
      | \\ (?: (?<esc> [$delims] ) | . )
    }{ $+{esc} // $+{str} // $& }gexsr;
}

# Unescapes the delimiters (\" => ") in the content of a string that has interpolation blocks.
# $delims is a quotemeta'd list of delimiter characters.
sub _unescape_interpolated {
    my ($string, $delims) = @_;

    return $string =~ s{
        $INTERPOLATION_RE
        (?<block> \# \{ (?&sf_code) \} )
      | \\ (?: (?<esc> [$delims] ) | . )
    }{ $+{esc} // (defined($+{block}) ? _unescape_block($+{block}, $delims) : $&) }gexsr;
}

# Operators (the longest prefix first), including the hyper-operators and the method-like operators
my $OPERATORS_RE = do {
    local $" = q{|};

    # Longest prefix first
    my @operators = map { quotemeta } qw(

      ||= ||
      &&= &&

      ^.. ..^

      %% ≅
      ~~ !~
      <~>
      <=> =~=
      <<= >>=
      << >>
      |>> |> |X> |Z>
      |= |
      &= &
      == =~
      := =
      <= >= < >
      ++ --
      += +
      -= -
      //= //
      /= / ÷= ÷
      **= **
      %= %
      ^= ^
      *= *
      ...
      != ..
      \\\\= \\\\
      !! !
      : ： ⫶
      « » ~
    );

    qr{
        (?(DEFINE)
            (?<ops>
                  @operators
                | \p{Block: Mathematical_Operators}
                | \p{Block: Supplemental_Mathematical_Operators}
            )
        )

          »(?<unroll>[^\W\d]\w*+|(?&ops))«                # unroll operator (e.g.: »add« or »+«)
        | >>(?<unroll>[^\W\d]\w*+|(?&ops))<<              # unroll operator (e.g.: >>add<< or >>+<<)

        | ~X(?<cross>[^\W\d]\w*+|(?&ops)|)                # cross operator          (e.g.: ~X or ~X+)
        | ~Z(?<zip>[^\W\d]\w*+|(?&ops)|)                  # zip operator            (e.g.: ~Z or ~Z+)
        | ~W(?<wise>[^\W\d]\w*+|(?&ops)|)                 # wise operator           (e.g.: ~W or ~W+)
        | ~S(?<scalar>[^\W\d]\w*+|(?&ops)|)               # scalar operator         (e.g.: ~S or ~S+)
        | ~RS(?<rscalar>[^\W\d]\w*+|(?&ops)|)             # reverse scalar operator (e.g.: ~RS or ~RS/)

        | »(?<map>[^\W\d]\w*+|(?&ops))»                   # mapping operator (e.g.: »add» or »+»)
        | >>(?<map>[^\W\d]\w*+|(?&ops))>>                 # mapping operator (e.g.: >>add>> or >>+>>)

        | «(?<pam>[^\W\d]\w*+|(?&ops))«                   # reverse mapping operator (e.g.: «add« or «+«)
        | <<(?<pam>[^\W\d]\w*+|(?&ops))<<                 # reverse mapping operator (e.g.: <<add<< or <<+<<)

        | »(?<lmap>[^\W\d]\w*+|(?&ops))\(\)»              # mapping operator (e.g.: »add()» or »+()»)
        | >>(?<lmap>[^\W\d]\w*+|(?&ops))\(\)>>            # mapping operator (e.g.: >>add()>> or >>+()>>)

        | <<(?<reduce>[^\W\d]\w*+|(?&ops))>>              # reduce operator (e.g.: <<add>> or <<+>>)
        | «(?<reduce>[^\W\d]\w*+|(?&ops))»                # reduce operator (e.g.: «add» or «+»)

        | `(?<op>[^\W\d]\w*+!?)`                          # method-like operator (e.g.: `add` or `add!`)
        | (?<op>(?&ops))                                  # primitive operator   (e.g.: +, -, *, /)
    }x;
};

# Reference: https://en.wikipedia.org/wiki/International_variation_in_quotation_marks
my %DELIM_PAIRS = qw~
  ( )       [ ]       { }       < >
  « »       » «       ‹ ›       › ‹
  „ ”       “ ”       ‘ ’       ‚ ’
  〈 〉     ﴾ ﴿       〈 〉     《 》
  「 」     『 』     【 】     〔 〕
  〖 〗     〘 〙     〚 〛     ⸨ ⸩
  ⌈ ⌉       ⌊ ⌋       〈 〉     ❨ ❩
  ❪ ❫       ❬ ❭       ❮ ❯       ❰ ❱
  ❲ ❳       ❴ ❵       ⟅ ⟆       ⟦ ⟧
  ⟨ ⟩       ⟪ ⟫       ⟬ ⟭       ⟮ ⟯
  ⦃ ⦄       ⦅ ⦆       ⦇ ⦈       ⦉ ⦊
  ⦋ ⦌       ⦍ ⦎       ⦏ ⦐       ⦑ ⦒
  ⦗ ⦘       ⧘ ⧙       ⧚ ⧛       ⧼ ⧽
  ~;

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

sub new {
    my (undef, %opts) = @_;

    my %options = (
        line          => 1,
        inc           => [],
        class         => 'main',            # a.k.a. namespace
        vars          => {'main' => []},    # the variables of the current scope, by namespace
        ref_vars_refs => {'main' => []},    # the chain of enclosing scopes (nearest first)
        seen_names    => {},                # the names that were declared (see `find_var`)
        EOT           => [],                # the pending here-documents

        postfix_ops      => {%POSTFIX_OPS},
        hyper_ops        => {%HYPER_OPS},
        built_in_classes => {%BUILT_IN_CLASSES},
        keywords         => {%KEYWORDS},
        delim_pairs      => {%DELIM_PAIRS},

        static_obj_re      => $STATIC_OBJ_RE,
        prefix_obj_re      => $PREFIX_OBJ_RE,
        quote_operators_re => $QUOTE_OPERATORS_RE,
        match_flags_re     => $MATCH_FLAGS_RE,
        var_name_re        => $VAR_NAME_RE,
        method_name_re     => $METHOD_NAME_RE,
        var_init_sep_re    => $VAR_INIT_SEP_RE,
        operators_re       => $OPERATORS_RE,

        %opts,
    );

    $options{special_words} //= {map { $_ => 1 } (keys(%{$options{keywords}}), keys(%{$options{built_in_classes}}), @SPECIAL_WORDS)};

    $options{ref_vars} = $options{vars};
    $options{file_name}   //= '-';
    $options{script_name} //= '-';

    bless \%options, __PACKAGE__;
}

# Messages that start the error reports
my @ERROR_QUIPS = (

    "Your code forgot how to 'human.' Please give it some structure!",
    "Were you trying to summon Cthulhu, or is this just a typo?",
    "This line of code is in denial. It doesn't want to cooperate.",
    "Parser has encountered a disturbance in the Force. It appears your code has gone to the dark side.",
    "Code drunk. Fix before it starts ordering random APIs online.",
    "Did you mean to do that? Because your code just broke the Matrix.",
    "Your syntax seems to have taken a coffee break.",
    "Your code is trying to summon Skynet. Abort while you can!",
    "This isn’t a Choose Your Own Adventure. Stick to the script!",
    "Well, that’s not going to work. Try again, friend.",

    "If this is what you meant, we need to have a talk.",
    "Uh-oh! Looks like your code slipped on a banana peel.",
    "Your code is having an existential crisis. It doesn’t know who it is anymore.",
    "Something’s wrong… but hey, at least you tried!",
    "The code didn’t like that. In fact, it’s offended.",
    "You’re one typo away from greatness. Unfortunately, this isn’t it.",
    "Well, that’s awkward. Let’s pretend that didn’t happen.",
    "Your code needs more coffee. Or maybe you do.",

    "I have no idea what I just read.",
    "Oops! The parser is confused and needs a moment to reboot its brain.",
    "The code is speaking in riddles. Try again in plain text.",
    "Parser ran out of breadcrumbs to follow your logic trail.",
    "It’s like trying to read a book with missing pages.",
    "The code went that way… and then it didn’t.",
    "Parser gave up. It’s currently hiding under the desk.",
    "It’s not you, it’s… okay, it’s definitely you.",
    "Parser needs a map and a flashlight to navigate this code.",
    "Parser has encountered a wild puzzle. It refuses to continue without a cheat sheet.",

    "Your code just sent me on a wild goose chase. No geese found.",
    "The parser tried to follow the logic, but it got lost in the spaghetti code.",
    "Your code just opened a wormhole. Destination: unknown.",
    "I’ve parsed Shakespeare, but this? This is next level.",
    "The parser tripped over a missing semicolon and is now in the fetal position.",
    "This code smells… like it’s on fire. Someone grab an extinguisher!",
    "The parser and the code had a staring contest. The parser blinked first.",
    "Parser has lost the plot. Please send a clearer script.",
    "The code just threw a plot twist. Even the parser didn’t see that coming.",
    "It tried to make sense of your code, then rage quit.",

    "The code ventured into the unknown… and didn’t leave a map.",
    "The parser tried to keep up, but your code is like a soap opera—too many plot twists.",
    "Your code is speaking Parseltongue. I need an interpreter.",
    "The parser has encountered an enigma wrapped in a mystery, coded in confusion.",
    "The parser felt a great disturbance in the code, as if thousands of bugs cried out in terror.",
    "The code just ghosted me. No clues, no closure, nothing.",
    "Parser tangled in a logic loop. Send help. Or snacks.",
    "The code is playing hide and seek. The parser isn’t winning.",
    "The parser tried reasoning with the code, but it’s ignoring all logic.",
    "Parser has encountered Schrödinger’s code. It’s both broken and not broken, but we won’t know until you fix it.",
                  );

# ---------------------------------------------------------------------------
# Error reporting
# ---------------------------------------------------------------------------

sub fatal_error {
    my ($self, %opt) = @_;

    my ($error_line, $point, $column) = $self->_error_context($opt{code} // '', $opt{pos} // 0);

    my $error = sprintf("%s\n\nFile : %s\nLine : %s : %s\nError: %s\n\n" . ("~" x 80) . "\n%s\n",
                        $ERROR_QUIPS[rand @ERROR_QUIPS],
                        $self->{file_name} // '-',
                        $opt{line} // $self->{line},
                        $column, join(', ', grep { defined } $opt{error}, $opt{reason}), $error_line);

    $error .= ' ' x ($point) . '^' . "\n" . ('~' x 80) . "\n";

    if (defined $opt{hint}) {
        $error .= "[!] Hint: $opt{hint}\n";
    }

    if (exists($opt{var})) {
        $error .= $self->_similar_names($opt{var});
    }

    die $error;
}

# Returns the source line of an error, the position of the pointer in this line (starting at 0)
# and the column of the error (starting at 1). Long lines are cut around the error.
sub _error_context {
    my ($self, $code, $pos) = @_;

    $pos = 0             if $pos < 0;
    $pos = length($code) if $pos > length($code);

    my $start  = ($pos > 0 ? rindex($code, "\n", $pos - 1) + 1 : 0);
    my $point  = $pos - $start;
    my $column = $point + 1;

    my $error_line = (split(/\R/, substr($code, $start, $point + 80)))[0] // '';

    if (length($error_line) > 80 && $point > 60) {
        my $from = $point - 40;
        my $rem  = $point + 40 - length($error_line);

        $from -= $rem;
        $point = 40 + $rem;

        $error_line = substr($error_line, $from, 80);
    }

    return ($error_line, $point, $column);
}

# Suggestions for an undeclared name: the declared names, the keywords and the built-in classes
# that are similar to it (e.g.: `retrun` => `return`)
sub _similar_names {
    my ($self, $var) = @_;

    my ($name, $class) = $self->get_name_and_class($var);

    my %seen;
    my @names;

    foreach my $scope ($self->{vars}{$class}, @{$self->{ref_vars_refs}{$class}}) {
        foreach my $declared (@{$scope}) {
            next if ref $declared eq 'ARRAY';
            if (!$seen{$declared->{name}}++) {
                push @names, $declared->{name};
            }
        }
    }

    $class = ($class eq 'main' ? '' : $class . '::');

    if ($class eq '') {
        foreach my $word (sort(keys(%{$self->{keywords}}), keys(%{$self->{built_in_classes}}))) {
            next                if substr($word, 0, 2) eq '__';
            push(@names, $word) if !$seen{$word}++;
        }
    }

    if (my @candidates = Sidef::best_matches($name, [grep { $_ ne $name } @names])) {
        return ("[?] Did you mean: " . join("\n" . (' ' x 18), map { $class . $_ } sort(@candidates)) . "\n");
    }

    return '';
}

use constant REDO_PARSE => \'redo';    # returned by a handler to parse the expression again

# Fails when the name is a keyword or the name of a built-in class
sub _check_reserved_name {
    my ($self, $code, $name, $pos) = @_;

    if (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name})) {
        $self->fatal_error(
                           code  => $code,
                           pos   => $pos,
                           error => "`$name` is either a keyword or a predefined variable!",
                          );
    }

    return;
}

# ---------------------------------------------------------------------------
# Scopes and declared names
# ---------------------------------------------------------------------------

# Declares a new variable (or function, class, etc.) in the current scope
sub _unshift_var {
    my ($self, $class_name, $entry) = @_;
    unshift @{$self->{vars}{$class_name}}, $entry;
    $self->{seen_names}{$class_name}{$entry->{name}} = 1;
    return;
}

# Finds a declared name, starting with the current scope and continuing with the enclosing scopes.
# In list context it also returns true when the name was found in the current scope.
sub find_var {
    my ($self, $var_name, $class) = @_;

    # Fast exit: no variable with this name was ever declared in this namespace
    exists($self->{seen_names}{$class}{$var_name}) or return;

    foreach my $var (@{$self->{vars}{$class}}) {
        next if ref $var eq 'ARRAY';
        if ($var->{name} eq $var_name) {
            return (wantarray ? ($var, 1) : $var);
        }
    }

    # The enclosing scopes (from the nearest to the farthest)
    foreach my $scope (@{$self->{ref_vars_refs}{$class}}) {
        foreach my $var (@{$scope}) {
            next if ref $var eq 'ARRAY';
            if ($var->{name} eq $var_name) {
                return (wantarray ? ($var, 0) : $var);
            }
        }
    }

    return;
}

# Warns about the variables that were declared, but never used.
sub check_declarations {
    my ($self, $hash_ref) = @_;

    foreach my $class (grep { $_ eq 'main' } keys %{$hash_ref}) {

        my $array_ref = $hash_ref->{$class};

        foreach my $variable (@{$array_ref}) {
            if (ref $variable eq 'ARRAY') {
                $self->check_declarations({$class => $variable});
            }
            elsif ($self->{interactive} or $self->{eval_mode}) {
                ## Everything is OK in interactive mode
            }
            elsif (   $variable->{count} == 0
                   && $variable->{type} ne 'class'
                   && $variable->{type} ne 'func'
                   && $variable->{type} ne 'method'
                   && $variable->{type} ne 'global'
                   && $variable->{name} ne 'self'
                   && $variable->{name} ne ''
                   && $variable->{type} ne 'del'
                   && chr(ord $variable->{name}) ne '_') {

                warn '[WARNING] '
                  . "$variable->{type} '$variable->{name}' has been declared, but not used again at "
                  . "$self->{file_name} line $variable->{line}\n";
            }
        }
    }
}

# Splits a name into its namespace and its basename: `Foo::bar` => (bar, Foo)
sub get_name_and_class {
    my ($self, $var_name) = @_;

    $var_name // return ('', $self->{class});

    my $rindex = rindex($var_name, '::');
    $rindex != -1
      ? (substr($var_name, $rindex + 2), substr($var_name, 0, $rindex))
      : ($var_name, $self->{class});
}

# ---------------------------------------------------------------------------
# Whitespace, comments, and quoted strings
# ---------------------------------------------------------------------------

sub parse_whitespace {
    my ($self, %opt) = @_;

    my $found_space = -1;
    local *_ = $opt{code};
    {
        ++$found_space;

        # Fast exit: the next character can't start whitespace or a comment
        if (!/\G(?=[\s#\/\x{200B}])/) {
            return ($found_space > 0 ? 1 : ());
        }

        # Whitespace
        if (/\G(?=\s)/) {

            # Horizontal space
            if (/\G\h+/gc) {
                redo;
            }

            # Generic line
            if (/\G\R/gc) {
                ++$self->{line};

                # Here-documents
                while (@{$self->{EOT}}) {
                    $self->_read_heredoc(shift(@{$self->{EOT}}), code => $opt{code});
                }

                /\G\h+/gc;
                redo;
            }

            # Vertical space
            if (/\G\v+/gc) {    # should not reach here
                redo;
            }
        }

        # ZERO WIDTH SPACE
        # https://www.fileformat.info/info/unicode/char/200b/index.htm
        if (/\G\x{200B}+/gc) {
            redo;
        }

        # Embedded comments (https://docs.raku.org/language/syntax#Multi-line_/_embedded_comments)
        if (/\G#`(?=[[:punct:]])/gc) {
            $self->get_quoted_string(code => $opt{code});
            redo;
        }

        # One-line comment
        if (/\G#.*/gc) {
            redo;
        }

        # Multi-line C comment
        if (m{\G/\*}gc) {
            $self->_skip_c_comment(code => $opt{code});
            redo;
        }

        if ($found_space > 0) {
            return 1;
        }

        return;
    }
}

# Reads the content of a here-document that starts on the next line
sub _read_heredoc {
    my ($self, $eot, %opt) = @_;

    local *_ = $opt{code};

    my $name   = $eot->{name};
    my $indent = $eot->{indent};

    my $spaces = 0;
    my $acc    = '';
    until (/\G\Q$name\E(?:\R|\z)/gc) {

        if (/\G(.*)/gc) {
            $acc .= "$1\n";
        }

        # Indentation is true
        if ($indent && /\G\R(\h*)\Q$name\E(?:\R|\z)/gc) {
            $spaces = length($1);
            ++$self->{line};
            last;
        }

        /\G\R/gc
          ? ++$self->{line}
          : $self->fatal_error(
                               error => "can't find string terminator <<$name>> anywhere before end-of-file",
                               code  => $_,
                               pos   => $eot->{pos},
                               line  => $eot->{line},
                              );
    }

    if ($indent and $spaces > 0) {
        $acc =~ s/^\h{1,$spaces}//gm;
    }

    ++$self->{line};
    push @{$eot->{obj}{$self->{class}}},
      {
        self => (
                 $eot->{type} == 0
                 ? Sidef::Types::String::String->new($acc)
                 : Sidef::Types::String::String->new($acc)->apply_escapes($self)
                )
      };

    return;
}

# Skips a multi-line C comment (the opening `/*` was consumed)
sub _skip_c_comment {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my ($comment_pos, $comment_line) = (pos($_) - 2, $self->{line});
    while (1) {
        m{\G.*?\*/}gc && last;
        /\G.+/gc
          || (
              /\G\R/gc
              ? $self->{line}++
              : $self->fatal_error(
                                   error => "can't find the end of the multi-line comment",
                                   code  => $_,
                                   pos   => $comment_pos,
                                   line  => $comment_line,
                                  )
             );
    }

    return;
}

# Moves back to the end of the last statement, before the whitespace that was skipped.
sub backtrack_whitespace {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    # Backtrack the removal of whitespace
    while (1) {
        my $s = substr($_, pos($_) - 1, 1);

        if ($s =~ /\R/) {
            $self->{line} -= 1;
            pos($_) -= 1;
            last;
        }
        elsif ($s =~ /\h/) {
            pos($_) -= 1;
        }
        else {
            last;
        }
    }
}

# Parses a string that starts with any delimiter (including the paired ones) and returns its content.
#
# With `interpolate => 1`, the `#{...}` blocks are skipped as a whole, so they can contain
# the delimiter of the string (inside nested strings, or as a plain character).
sub get_quoted_string {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    /\G(?=\s)/ && $self->parse_whitespace(code => $opt{code});

    my $delim;
    if (/\G(?=(.))/) {
        $delim = $1;
        if ($delim eq '\\' && /\G\\(.*?)\\/gsc) {
            return $1;
        }
    }
    else {
        my $pos = pos($_) // 0;
        $self->fatal_error(
                           error => qq{can't find the beginning of a string quote delimiter},
                           code  => $_,
                           pos   => $pos,
                          );
    }

    my $orig_pos    = pos($_);
    my $beg_delim   = quotemeta $delim;
    my $pair_delim  = exists($self->{delim_pairs}{$delim}) ? $self->{delim_pairs}{$delim} : ();
    my $interpolate = $opt{interpolate};

    my $string = '';
    if (defined $pair_delim) {

        my $end_delim = quotemeta $pair_delim;
        my $re_delim  = $beg_delim . $end_delim;

        if (
            $interpolate
            and m{\G
                $INTERPOLATION_RE
                (?<main> $beg_delim
                    (?<content>
                        (?>
                            [^\\$re_delim\#]++
                          | \\ .
                          | \# (?!\{)
                          | (?&sf_interp)
                          | (?&main)
                        )*+
                    )
                $end_delim )
            }xsgc
          ) {
            my $content = $+{content};
            $string = (
                       index($content, '#{') == -1
                       ? $content =~ s/\\([$re_delim])/$1/gr
                       : _unescape_interpolated($content, $re_delim)
                      );
        }
        elsif (m{\G(?<main>$beg_delim((?>[^\\$re_delim]*+(?>\\.[^\\$re_delim]*|(?&main)){0,}){0,})$end_delim)}sgc) {
            $string = $2 =~ s/\\([$re_delim])/$1/gr;
        }
    }
    elsif (
        $interpolate
        and m{\G
            $INTERPOLATION_RE
            $beg_delim
            (?<content>
                (?>
                    [^\\$beg_delim\#]++
                  | \\ .
                  | \# (?!\{)
                  | (?&sf_interp)
                )*+
            )
            (?= $beg_delim )
        }xsgc
      ) {
        my $content = $+{content};
        $string = (
                   index($content, '#{') == -1
                   ? $content =~ s/\\([$beg_delim])/$1/gr
                   : _unescape_interpolated($content, $beg_delim)
                  );
    }
    elsif (m{\G$beg_delim((?>[^\\$beg_delim]*+(?>\\.[^\\$beg_delim]*){0,}){0,})}sgc) {
        $string = $1 =~ s/\\([$beg_delim])/$1/gr;
    }

    (defined($pair_delim) ? /\G(?<=\Q$pair_delim\E)/ : /\G$beg_delim/gc)
      || $self->fatal_error(
                            error => sprintf(qq{can't find the quoted string terminator <<%s>>}, $pair_delim // $delim),
                            code  => $_,
                            pos   => $orig_pos,
                           );

    $self->{line} += $string =~ s/\R\K//g if not $opt{no_count_line};
    return $string;
}

# Parses a quoted list of words and returns an array-ref with them: %w(a b c)
sub get_quoted_words {
    my ($self, %opt) = @_;

    my $string = $self->get_quoted_string(code => $opt{code}, no_count_line => 1);
    $self->parse_whitespace(code => \$string);

    my @words;
    while ($string =~ /\G((?>[^\s\\]+|\\.)++)/gcs) {
        push @words, $1 =~ s{\\#}{#}gr;
        $self->parse_whitespace(code => \$string);
    }

    return \@words;
}

# Parses the opening delimiter of a list of declarations: `(`, `|`, etc. Returns the closing delimiter.
sub parse_delim {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $cache_key = (exists($opt{ignore_delim}) ? join('', sort keys %{$opt{ignore_delim}}) : '');

    my $regex = (
        $self->{_delim_re}{$cache_key} //= do {
            my @delims = ('|', keys(%{$self->{delim_pairs}}));
            if (exists $opt{ignore_delim}) {
                @delims = grep { not exists $opt{ignore_delim}{$_} } @delims;
            }
            local $" = "";
            qr/\G([@delims])\h*/;
        }
    );

    my $end_delim;
    if (/$regex/gc) {
        $end_delim = $self->{delim_pairs}{$1} // $1;
        $self->parse_whitespace(code => $opt{code});
    }

    return $end_delim;
}

# ---------------------------------------------------------------------------
# Declaration lists: variables, parameters and class attributes
# ---------------------------------------------------------------------------

sub get_init_vars {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $end_delim = $self->parse_delim(%opt);

    my @vars;
    my %classes;
    my @added_refs;

    while (   /\G(?<type>$self->{var_name_re}\h+$self->{var_name_re})\h*/goc
           || /\G([*:]?$self->{var_name_re})\h*/goc
           || (defined($end_delim) && /\G(?=[({])/)) {

        my $declaration = $1;

        if ($opt{with_vals} && defined($end_delim)) {

            # Add the variable into the symbol table
            if (defined $declaration) {

                my ($name, $class_name) = $self->get_name_and_class((split(' ', $declaration))[-1]);

                ++$classes{$class_name};
                my $entry = {
                             obj   => '',
                             name  => $name,
                             count => 0,
                             type  => $opt{type},
                             line  => $self->{line},
                            };
                $self->_unshift_var($class_name, $entry);
                push @added_refs, $entry;
            }

            if (/\G<<?\h*/gc) {
                my ($var) = /\G($self->{var_name_re})\h*/goc;
                $var // $self->fatal_error(
                                           code  => $_,
                                           pos   => pos($_),
                                           error => 'expected a subset name',
                                          );
                $declaration .= " < $var ";
            }

            if (/\G(?=\{)/) {
                my $pos = pos($_);
                $self->parse_block(code => $opt{code}, topic_var => 1);
                $declaration .= substr($_, $pos, pos($_) - $pos);
            }
            elsif (/\G(?=\()/) {
                my $pos = pos($_);
                $self->parse_arg(code => $opt{code});
                $declaration .= substr($_, $pos, pos($_) - $pos);
            }

            if (/$self->{var_init_sep_re}/goc) {
                my $pos = pos($_);
                local $self->{no_pipe_op} = (defined($end_delim) && $end_delim eq '|') ? 1 : 0;
                $self->parse_obj(code => $opt{code}, multiline => 1);
                $declaration .= '=' . substr($_, $pos, pos($_) - $pos);
            }
        }

        push @vars, $declaration;

        (defined($end_delim) && (/\G\h*,\h*/gc || /\G\h*(?:#.*)?+(?=\R)/gc)) || last;

        $self->parse_whitespace(code => $opt{code});
    }

    my %to_remove = map { refaddr($_) => 1 } @added_refs;

    # Remove the newly added variables
    foreach my $class_name (keys %classes) {
        my $scope = $self->{vars}{$class_name};
        @{$scope} = grep { not exists $to_remove{refaddr($_)} } @{$scope};
    }

    $self->parse_whitespace(code => $opt{code});

    defined($end_delim)
      && (
          /\G\h*\Q$end_delim\E/gc
          || $self->fatal_error(
                                code  => $_,
                                pos   => pos($_),
                                error => "can't find the closing delimiter: `$end_delim`",
                               )
         );

    return \@vars;
}

# Parses a list of declarations, such as `a, Num b = 1, *args` and returns an array-ref of variable objects.
# Options: type (var, global, del, has, ...), params, private, callback.
sub parse_init_vars {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $end_delim = $self->parse_delim(%opt);

    my @var_objs;
    my @scoped;
    my %seen_params;
    while (   /\G(?<type>$self->{var_name_re})\h+($self->{var_name_re})\h*/goc
           || /\G([*:]?)($self->{var_name_re})\h*/goc
           || (defined($end_delim) && /\G(?=[({])/)) {
        my ($attr, $name) = ($1, $2);
        my $name_pos = $-[2] // pos($_);

        my $ref_type = (defined($+{type}) ? $self->_parse_variable_type($+{type}, $name, code => $opt{code}) : undef);

        my ($subset);
        if (ref($ref_type) eq 'Sidef::Variable::Subset') {
            $subset = $ref_type;
            undef $ref_type;
        }

        my ($var_name, $class_name) = $self->get_name_and_class($name);

        if (    $opt{params}
            and $var_name ne ''
            and substr($var_name, 0, 1) ne '_'
            and $seen_params{$var_name}++) {
            $self->fatal_error(
                               code   => $_,
                               pos    => $name_pos,
                               error  => "duplicate parameter name `$var_name`",
                               reason => "each parameter must have a different name",
                              );
        }

        if ($opt{type} eq 'del') {
            my $var = $self->find_var($var_name, $class_name);

            if (not defined($var)) {
                $self->fatal_error(
                                   code  => $_,
                                   pos   => pos($_) - length($name),
                                   var   => ($class_name . '::' . $var_name),
                                   error => "attempt to delete non-existent variable `$name`",
                                  );
            }
        }

        $self->_check_reserved_name($_, $var_name, $-[2]);

        if (defined($end_delim)) {
            $subset = $self->_parse_variable_subset(code => $opt{code}) // $subset;
        }

        my ($value, $where_expr, $where_block);
        if (defined($end_delim)) {
            ($value, $where_expr, $where_block) = $self->_parse_variable_initializer($end_delim, code => $opt{code});
        }

#<<<
        my $obj = bless(
                        {
                         name => $var_name,
                         type => $opt{type},
                         (defined($ref_type) ? (ref_type => $ref_type) : ()),
                         (defined($subset)   ? (subset   => $subset)   : ()),
                         class => $class_name,
                         defined($value) ? (value => $value, has_value => 1) : (),
                         defined($attr)
                         ? ($attr eq '*' ? (array => 1, slurpy => 1)
                          : $attr eq ':' ? (hash  => 1, slurpy => 1) : ())
                         : (),
                         defined($where_block)   ? (where_block   => $where_block)   : (),
                         defined($where_expr)    ? (where_expr    => $where_expr)    : (),
                        },
                        'Sidef::Variable::Variable'
                       );
#>>>

        if (exists($opt{callback})) {
            $opt{callback}->($obj);
        }

        if (!$opt{private} and $var_name ne '') {
            $self->_unshift_var(
                                $class_name,
                                {
                                 obj   => $obj,
                                 name  => $var_name,
                                 count => 0,
                                 type  => $opt{type},
                                 line  => $self->{line},
                                }
                               );
        }

        # The parameters of a class or of a struct are visible in the default values of the next parameters
        elsif ($opt{scoped} and $var_name ne '') {
            my $entry = {
                         obj   => $obj,
                         name  => $var_name,
                         count => 1,
                         type  => $opt{type},
                         line  => $self->{line},
                        };
            $self->_unshift_var($class_name, $entry);
            push @scoped, [$class_name, $entry];
        }

        if ($var_name eq '') {
            $obj->{name} = '__ANON__' . refaddr($obj);
        }

        push @var_objs, $obj;
        (defined($end_delim) && (/\G\h*,\h*/gc || /\G\h*(?:#.*)?+(?=\R)/gc)) || last;

        if ($opt{params} and $obj->{slurpy}) {
            $self->fatal_error(
                               error => "can't declare more parameters after a slurpy parameter",
                               code  => $_,
                               pos   => pos($_),
                              );
        }

        $self->parse_whitespace(code => $opt{code});
    }

    $self->parse_whitespace(code => $opt{code}) if defined($end_delim);

    defined($end_delim)
      && (
          /\G\h*\Q$end_delim\E/gc
          || $self->fatal_error(
                                code  => $_,
                                pos   => pos($_),
                                error => "can't find the closing delimiter: `$end_delim`",
                               )
         );

    # The parameters are not visible after the declaration
    foreach my $item (@scoped) {
        my ($class_name, $entry) = @{$item};
        @{$self->{vars}{$class_name}} = grep { refaddr($_) != refaddr($entry) } @{$self->{vars}{$class_name}};
    }

    return \@var_objs;
}

# The type of a variable: `var Type name`
sub _parse_variable_type {
    my ($self, $type, $name, %opt) = @_;

    local *_ = $opt{code};

    my $obj = $self->parse_expr(code => \$type);

    if (not defined($obj) or ref($obj) eq 'HASH') {
        $self->fatal_error(
                           code   => $_,
                           pos    => pos($_),
                           error  => "invalid type <<$type>> for variable `$name`",
                           reason => "expected a type, such as: Str, Num, File, etc...",
                          );
    }

    return $obj;
}

# The subset of a variable: `var name < Subset` or `var name << Subset`
# Returns nothing when there is no subset.
sub _parse_variable_subset {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    m{\G<<?\h*}gc || return;

    my ($subset_name) = /\G($self->{var_name_re})/goc;

    $subset_name // $self->fatal_error(
                                       code  => $_,
                                       pos   => pos($_),
                                       error => "expected the name of the subset",
                                      );

    my $code = $subset_name;
    my $obj  = $self->parse_expr(code => \$code);

    (defined($obj) and ref($obj) ne 'HASH')
      || $self->fatal_error(
                            code  => $_,
                            pos   => pos($_),
                            error => "expected a subset or a type",
                           );

    return $obj;
}

# The `where` condition and the default value of a variable
# Returns: (default value, `where` expression, `where` block)
sub _parse_variable_initializer {
    my ($self, $end_delim, %opt) = @_;

    local *_ = $opt{code};

    my ($value, $where_expr, $where_block);

    if (/\G\h*(?=\{)/gc) {
        $where_block = $self->parse_block(code => $opt{code}, topic_var => 1);
    }
    elsif (/\G\h*(?=\()/gc) {
        $where_expr = $self->parse_arg(code => $opt{code});
    }

    if (/$self->{var_init_sep_re}/goc) {
        local $self->{no_pipe_op} = ($end_delim eq '|') ? 1 : 0;
        my $obj = $self->parse_obj(code => $opt{code}, multiline => 1);
        $value = (
                  ref($obj) eq 'HASH'
                  ? $obj
                  : {$self->{class} => [{self => $obj}]}
                 );
    }

    return ($value, $where_expr, $where_block);
}

# ---------------------------------------------------------------------------
# Delimited constructs: (...), [...], {...}
# ---------------------------------------------------------------------------

sub parse_arg {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    if (/\G\(/gc) {
        my $p    = pos($_);
        my $line = $self->{line};
        local $self->{parentheses} = 1;
        local $self->{no_pipe_op}  = 0;
        local $self->{no_pair_op}  = 0;
        my $obj = $self->parse_script(code => $opt{code});

        $self->{parentheses}
          && $self->fatal_error(
                                code   => $_,
                                pos    => $p - 1,
                                error  => "unbalanced parenthesis",
                                reason => "the `(` opened here has no matching `)`",
                                line   => $line,
                               );

        return $obj;
    }

    return;
}

# Parses the content of an array in brackets: [...]
sub parse_array {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    if (/\G\[/gc) {
        my $p    = pos($_);
        my $line = $self->{line};
        local $self->{right_brackets} = 1;
        local $self->{no_pipe_op}     = 0;
        local $self->{no_pair_op}     = 0;
        my $obj = $self->parse_script(code => $opt{code});

        $self->{right_brackets}
          && $self->fatal_error(
                                code   => $_,
                                pos    => $p - 1,
                                error  => "unbalanced right bracket",
                                reason => "the `[` opened here has no matching `]`",
                                line   => $line,
                               );

        return $obj;
    }

    return;
}

# Parses the content of a hash lookup, in curly brackets: {...}
sub parse_lookup {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    if (/\G\{/gc) {
        my $p    = pos($_);
        my $line = $self->{line};
        local $self->{curly_brackets} = 1;
        local $self->{no_pipe_op}     = 0;
        local $self->{no_pair_op}     = 0;
        my $obj = $self->parse_script(code => $opt{code});

        $self->{curly_brackets}
          && $self->fatal_error(
                                code   => $_,
                                pos    => $p - 1,
                                error  => "unbalanced curly bracket",
                                reason => "the `{` opened here has no matching `}`",
                                line   => $line,
                               );

        return $obj;
    }

    return;
}

# Parses a block in curly brackets: {...}
#
# Options: topic_var (declares the variable `_`), with_vars (the block parameters: {|a, b| ...}),
# is_module, init_code (the parameters are parsed from another string), no_brace.
sub parse_block {
    my ($self, %opt) = @_;

    local *_ = $opt{code};
    if (defined($opt{no_brace}) or /\G\{/gc) {

        # The position of the opening curly bracket
        my $p    = (defined($opt{no_brace}) ? $opt{no_brace} + 1 : pos($_));
        my $line = $self->{line};

        local $self->{curly_brackets} = 1;
        local $self->{no_pipe_op}     = 0;
        local $self->{no_pair_op}     = 0;

        my $class_name = $self->{class};

        if ($opt{is_module}) {
            $class_name = $opt{prev_class};
        }

        my $ref = $self->{vars}{$class_name} //= [];

        # The enclosing scope becomes the nearest one in the chain, and a new scope is created
        unshift @{$self->{ref_vars_refs}{$class_name}}, $ref;
        unshift @{$ref},                                [];

        $self->{vars}{$class_name} = $ref->[0];

        my $block = bless({}, 'Sidef::Types::Block::BlockInit');

        # Parse whitespace (if any)
        $self->parse_whitespace(code => $opt{code});

        my $has_vars;
        my $var_objs = [];

        if (($opt{topic_var} || $opt{with_vars}) && (defined($opt{init_code}) || /\G(?=\|)/)) {
            $has_vars = 1;
            $var_objs = $self->parse_init_vars(
                                               params => 1,
                                               code   => (defined($opt{init_code}) ? $opt{init_code} : $opt{code}),
                                               type   => 'var',
                                              );
        }

        # Special '_' variable
        if ($opt{topic_var} and not $has_vars) {
            my $code = '_';
            $has_vars = 1;
            $var_objs = $self->parse_init_vars(code => \$code, type => 'var');
        }

        local $self->{current_block} = $block if $has_vars;

        my $obj = $self->parse_script(code => $opt{code});

        $self->{curly_brackets}
          && $self->fatal_error(
                                code   => $_,
                                pos    => $p - 1,
                                error  => "unbalanced curly bracket",
                                reason => "the `{` opened here has no matching `}`",
                                line   => $line,
                               );

        if ($has_vars) {
            $block->{init_vars} = bless({vars => $var_objs}, 'Sidef::Variable::Init');
        }

        $block->{code} = $obj;
        shift @{$self->{ref_vars_refs}{$class_name}};
        $self->{vars}{$class_name} = $ref;

        return $block;
    }

    return;
}

# ---------------------------------------------------------------------------
# Expressions (parse_expr dispatches to the handlers below)
# ---------------------------------------------------------------------------

sub parse_expr {
    my ($self, %opt) = @_;

    local *_ = $opt{code};
    {
        $self->parse_whitespace(code => $opt{code});

        # End of an expression, or end of the script
        if (/\G;/gc || /\G\z/) {
            return;
        }

        # Fast paths for the most common tokens (decimal numbers and plain identifiers),
        # which skip all the other checks
        if (not $self->{no_fast_path}) {

            if (/\G(?=[0-9])/) {
                return $self->_parse_number(code => $opt{code});
            }

            if (    /\G(?=[^\W\d])/
                and /\G([^\W\d]\w*+)(?!::|![^\W\d]|:(?![=:])|\h*=>)/
                and not exists($self->{special_words}{$1})
                and index($1, '__') != 0) {
                return $self->_parse_variable_access(code => $opt{code});
            }
        }

        if (/$self->{quote_operators_re}/goc) {
            return $self->_parse_quote_operator(code => $opt{code}, info => $^R);
        }

        # Object as expression
        if (/\G(?=\()/) {
            return $self->parse_arg(code => $opt{code});
        }

        # Block as object
        if (/\G(?=\{)/) {
            return $self->parse_block(code => $opt{code}, topic_var => 1);
        }

        # Array as object
        if (/\G(?=\[)/) {
            return $self->_parse_array_literal(code => $opt{code});
        }

        # Bareword followed by a fat comma or preceded by a colon
        if (   /\G:(\w+)/gc
            || /\G([^\W\d]\w*+)(?=\h*=>)/gc) {

            return Sidef::Types::String::String->new($1);
        }

        # Bareword followed by a colon becomes a NamedParam with the bareword
        # on the LHS
        if (/\G([^\W\d]\w*+):(?![=:])/gc) {
            my $name = $1;
            my $obj  = $self->parse_obj(code => $opt{code});
            return Sidef::Variable::NamedParam->new($name, $obj);
        }

        # Declaration of variables (global and lexical)
        if (/\G(var|global|del)\b\h*/gc) {
            return $self->_parse_variable_declaration(code => $opt{code}, match => $1);
        }

        # "has" class attributes
        if (exists($self->{current_class}) and /\Ghas\b\h*/gc) {
            return $self->_parse_class_attributes(code => $opt{code});
        }

        # Declaration of constants and static variables
        if (/\G(define|const|static)\b\h*/gc) {
            return $self->_parse_constant_declaration(code => $opt{code}, match => $1);
        }

        # Struct declaration
        if (/\Gstruct\b\h*/gc) {
            return $self->_parse_struct(code => $opt{code});
        }

        # Subset declaration
        if (/\Gsubset\b\h*/gc) {
            return $self->_parse_subset(code => $opt{code});
        }

        # Declaration of enums
        if (/\Genum\b\h*/gc) {
            return $self->_parse_enum(code => $opt{code});
        }

        # Local variables
        if (/\Glocal\b\h*/gc) {
            return $self->_parse_local(code => $opt{code});
        }

        # Declaration of classes, methods and functions
        if (
               /\G(func|class)\b\h*/gc
            || /\G(->)\h*/gc
            || (exists($self->{current_class})
                && /\G(method)\b\h*/gc)
          ) {
            return $self->_parse_function_or_class(code => $opt{code}, match => $1);
        }

        # "given(expr) {...}" construct
        if (/\Ggiven\b\h*/gc) {
            return $self->_parse_given(code => $opt{code});
        }

        # "when(expr) {...}" construct
        if (exists($self->{current_given}) && /\Gwhen\b\h*/gc) {
            return $self->_parse_when(code => $opt{code});
        }

        # "case(expr) {...}" construct
        if (exists($self->{current_given}) && /\Gcase\b\h*/gc) {
            return $self->_parse_case(code => $opt{code});
        }

        # "default {...}" or "else { ... }" construct for `given/when`
        if (exists($self->{current_given}) && /\G(?:default|else)\h*(?=\{)/gc) {
            my $block = $self->parse_block(code => $opt{code});
            return bless({block => $block}, 'Sidef::Types::Block::Default');
        }

        # `continue` keyword inside a given/when construct
        if (exists($self->{current_given}) && /\Gcontinue\b/gc) {
            state $x = bless({}, 'Sidef::Types::Block::Continue');
            return $x;
        }

        # "do {...}" and "loop {...}" constructs
        if (/\G(do|loop)\h*(?=\{)/gc) {
            my $class = ($1 eq 'do' ? 'Sidef::Types::Block::Do' : 'Sidef::Types::Block::Loop');
            return bless({block => $self->parse_block(code => $opt{code})}, $class);
        }

        # "try/catch" construct
        if (/\Gtry\h*(?=\{)/gc) {
            return $self->_parse_try(code => $opt{code});
        }

        # "gather/take" construct
        if (/\Ggather\h*(?=\{)/gc) {
            return $self->_parse_gather(code => $opt{code});
        }

        if (exists($self->{current_gather}) and /\Gtake\b\h*/gc) {

            my $obj = $self->_parse_arg_or_obj(code => $opt{code});

            return bless({expr => $obj, gather => $self->{current_gather}}, 'Sidef::Types::Block::Take');
        }

        # Declaration of a module
        if (/\Gmodule\b\h*/gc) {
            return $self->_parse_module(code => $opt{code});
        }

        if (/\Gimport\b\h*/gc) {
            return $self->_parse_import(code => $opt{code});
        }

        if (/\Ginclude\b\h*/gc) {
            my $included = $self->_parse_include(code => $opt{code});
            redo if (ref($included) and refaddr($included) == refaddr(REDO_PARSE));
            return $included;
        }

        # Numbers
        if (/\G(?=\.?[0-9]|[⁰¹²³⁴⁵⁶⁷⁸⁹])/) {
            my $number = $self->_parse_number(code => $opt{code});
            return $number if defined($number);
        }

        # Prefix `...`
        if (/\G\.\.\./gc) {
            return
              bless(
                    {
                     line => $self->{line},
                     file => $self->{file_name},
                    },
                    'Sidef::Meta::Unimplemented'
                   );
        }

        # Implicit method call on special variable: "_"
        if (/\G\./) {
            return $self->_parse_implicit_topic_call(code => $opt{code});
        }

        # Quoted words, numbers, vectors and matrices
        # %w(...), %i(...), %n(...), %v(...), %m(...), «...», <...>
        if (/\G%([wWinvm])\b/gc || /\G(?=(«|<(?!<)))/) {
            return $self->_parse_quoted_words(code => $opt{code}, match => $1);
        }

        # Prefix method call (`::name(...)` or `::name ...`)
        if (/\G::($self->{var_name_re})\h*/goc) {
            return $self->_parse_prefix_method_call(code => $opt{code}, match => $1);
        }

        if (/($self->{prefix_obj_re})\h*/goc) {
            return ($^R, 1, $1);
        }

        # Assertions
        if (/\G(assert(?:_(?:eq|ne))?+)\b\h*/gc) {
            return $self->_parse_assert(code => $opt{code}, match => $1);
        }

        # Function-style `not(...)`: it is applied only on the parenthesized expression
        if (/\Gnot(?=\()/gc) {
            return $self->_negate($self->parse_arg(code => $opt{code}));
        }

        # Logical `not` (it has a lower precedence than comparisons: `not a == b` is `not (a == b)`)
        if (/\Gnot\b\h*/gc) {
            return $self->_parse_not(code => $opt{code});
        }

        # die/warn
        if (/\G(die|warn)\b\h*/gc) {
            return $self->_parse_die_warn(code => $opt{code}, match => $1);
        }

        # Eval keyword
        if (/\Geval\b\h*/gc) {
            return $self->_parse_eval(code => $opt{code});
        }

        if (/\GParser\b/gc) {
            return $self;
        }

        # Regular expression
        if (m{\G(?=/)} || /\G%r\b/gc) {
            return $self->_parse_regex_literal(code => $opt{code});
        }

        # Class variable in form of `Class!var_name`
        if (/\G($self->{var_name_re})!($self->{var_name_re})/goc) {
            my ($class_name, $var_name) = ($1, $2);
            my $class_obj = $self->parse_expr(code => \$class_name);
            return (bless {class => $class_obj, name => $var_name}, 'Sidef::Variable::ClassVar');
        }

        # Static object (like String or nil)
        if (/$self->{static_obj_re}/goc) {
            return $^R;
        }

        # Special constants
        if (/\G(__MAIN__|__FILE__|__DATE__|__TIME__|__LINE__|__COMPILED__|__OPTIMIZED__)\b/gc) {
            return $self->_parse_magic_constant(code => $opt{code}, match => $1);
        }

        if (/\G__(?:END|DATA)__\b\h*+\R?/gc) {
            if (exists $self->{'__DATA__'}) {
                $self->{'__DATA__'} = substr($_, pos);
            }
            pos($_) = length($_);
            return;
        }

        if (/\GDATA\b/gc) {
            return (
                $self->{static_objects}{'__DATA__'} //= do {
                    bless({data => \$self->{'__DATA__'}}, 'Sidef::Meta::Glob::DATA');
                }
            );
        }

        # Beginning of a here-document (<<"EOT", <<'EOT', <<EOT)
        if (/\G<<(-)?+(?=\S)/gc) {
            return $self->_parse_heredoc(code => $opt{code}, match => $1);
        }

        # Constants that depend on the context: __BLOCK__, __FUNC__, __CLASS__, __METHOD__, etc.
        if (/\G__/) {
            my $constant = $self->_parse_context_constant(code => $opt{code});
            return $constant if defined($constant);
        }

        # Misplaced keywords (for better error messages)
        $self->_check_misplaced_keyword(code => $opt{code});

        # Variable access
        if (/\G(?=[^\W\d])/) {
            my $variable = $self->_parse_variable_access(code => $opt{code});
            return $variable if defined($variable);
        }

        # Regex variables ($1, $2, ...)
        if (/\G\$([0-9]+)\b/gc) {
            $self->fatal_error(
                               code  => $_,
                               pos   => (pos($_) - length($1)),
                               error => "regex capture-variables are not supported",
                              );
        }

        /\G\$/gc && redo;

        return;
    }
}

# Quote-like operators: strings, files, directories, pipes, backticks, bytes, chars, etc.
sub _parse_quote_operator {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my ($double_quoted, $method, $package) = @{$opt{info}};

    pos($_) -= 1;
    my ($string, $pos) = $self->get_quoted_string(code => $opt{code}, interpolate => $double_quoted);

    # Special case for array-like objects (bytes and chars)
    my @array_like;
    if ($method ne 'new' and $method ne '__NEW__') {
        @array_like = ($package, $method);
        $package    = 'Sidef::Types::String::String';
        $method     = 'new';
    }

    if ($package eq 'Sidef::Module::Func' or $package eq 'Sidef::Module::OO') {
        if ($string !~ /^$self->{var_name_re}\z/) {
            $self->fatal_error(
                               code   => $_,
                               pos    => (pos($_) - length($string) - 1),
                               error  => "invalid symbol declaration",
                               reason => "expected a variable-like name",
                              );
        }
    }

    my $obj = (
        $double_quoted
        ? do {
            state $str = Sidef::Types::String::String->new;    # load the string module
            Sidef::Types::String::String::apply_escapes($package->$method($string), $self);
          }
        : $package->$method($string =~ s{\\\\}{\\}gr)
    );

    # Special case for backticks and Perl code (add method 'run')
    if ($package eq 'Sidef::Types::Glob::Backtick' or $package eq 'Sidef::Types::Perl::Perl') {
        my $struct =
            $double_quoted && ref($obj) eq 'HASH'
          ? $obj
          : {
             $self->{class} => [
                                {
                                 self => $obj,
                                 call => [],
                                }
                               ]
            };

        push @{$struct->{$self->{class}}[-1]{call}}, {method => 'run'};
        $obj = $struct;
    }
    elsif (@array_like) {
        if ($double_quoted and ref($obj) eq 'HASH') {
            push @{$obj->{$self->{class}}[-1]{call}}, {method => $array_like[1]};
        }
        else {
            my $method = $array_like[1];
            $obj = $obj->$method;
        }
    }

    return $obj;
}

# Array as object
sub _parse_array_literal {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my @array;
    my $obj = $self->parse_array(code => $opt{code});

    if (ref($obj->{$self->{class}}) eq 'ARRAY') {
        push @array, @{$obj->{$self->{class}}};
    }

    return bless(\@array, 'Sidef::Types::Array::HCArray');
}

# Numbers: super-script integers, binary/hexadecimal/octal numbers, and decimal numbers
sub _parse_number {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    # Super-script power
    if (/\G([⁰¹²³⁴⁵⁶⁷⁸⁹]+)/gc) {
        my $num = ($1 =~ tr/⁰¹²³⁴⁵⁶⁷⁸⁹/0-9/r);
        return Sidef::Types::Number::Number::_set_int($num);
    }

    # Binary, hexadecimal and octal numbers
    if (/\G0(b[10_]*|x[0-9A-Fa-f_]*|o[0-7_]*|[0-7_]+)\b/gc) {
        my $num = $1 =~ tr/_//dr;
        return
          Sidef::Types::Number::Number->new(
                                              $num =~ /^b/ ? (substr($num, 1) || 0, 2)
                                            : $num =~ /^o/ ? (substr($num, 1) || 0, 8)
                                            : $num =~ /^x/ ? (substr($num, 1) || 0, 16)
                                            :                ($num            || 0, 8)
                                           );
    }

    # Integer or float number
    if (/\G((?=\.?[0-9])[0-9_]*+(?:\.[0-9_]++)?(?:[Ee](?:[+-]?+[0-9_]+))?)/gc) {
        my $num_text = $1;
        my $num      = $1 =~ tr/_//dr;

        # A number can't be directly followed by letters (e.g.: `0b102`, `12abc`)
        if (/\G(?![if]\b)(?=[^\W\d])/) {
            my ($rest) = /\G(\w+)/;
            $self->fatal_error(
                               code   => $_,
                               pos    => pos($_) - length($num_text),
                               error  => "invalid numeric literal `$num_text$rest`",
                               reason => "unexpected `$rest` after the number `$num_text`",
                              );
        }

        if (/\Gi\b/gc) {    # imaginary
            return Sidef::Types::Number::Complex->new(0, $num);
        }
        elsif (/\Gf\b/gc) {    # floating-point
            return Sidef::Types::Number::Number::_set_str('float', $num);
        }

        return (
                $num =~ /^-?[0-9]+\z/
                ? Sidef::Types::Number::Number::_set_int($num)
                : Sidef::Types::Number::Number->new($num)
               );
    }

    return;
}

# Quoted words, numbers, vectors and matrices
# %w(...), %i(...), %n(...), %v(...), %m(...), «...», <...>
sub _parse_quoted_words {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my ($type) = $opt{match};
    my $strings = $self->get_quoted_words(code => $opt{code});

    if ($type eq 'w' or $type eq '<') {
        my @list = map { Sidef::Types::String::String->new(s{\\(?=[\\#\s])}{}gr) } @{$strings};
        return Sidef::Types::Array::Array->new(\@list);
    }

    if ($type eq 'i') {
        my @list = map { Sidef::Types::Number::Number->new(s{\\(?=[\\#\s])}{}gr)->int }
          split(/[\s,]+/, join(' ', @$strings));
        return Sidef::Types::Array::Array->new(\@list);
    }

    if ($type eq 'n') {
        my @list =
          map { Sidef::Types::Number::Number->new(s{\\(?=[\\#\s])}{}gr) } split(/[\s,]+/, join(' ', @$strings));
        return Sidef::Types::Array::Array->new(\@list);
    }

    if ($type eq 'v') {
        my @list =
          map { Sidef::Types::Number::Number->new(s{\\(?=[\\#\s])}{}gr) } split(/[\s,]+/, join(' ', @$strings));
        return Sidef::Types::Array::Vector->new(@list);    # this must be passed as a list
    }

    if ($type eq 'm') {
        my @matrix;
        my $data = join(' ', @$strings);
        foreach my $line (split(/\s*;\s*/, $data)) {
            my @row = map { Sidef::Types::Number::Number->new(s{\\(?=[\\#\s])}{}gr) } split(/[\s,]+/, $line);
            push @matrix, Sidef::Types::Array::Array->new(\@row);
        }
        return Sidef::Types::Array::Matrix->new(@matrix);
    }

    my ($inline_expression, @objs);
    foreach my $item (@{$strings}) {
        my $str = Sidef::Types::String::String->new($item)->apply_escapes($self);
        $inline_expression ||= ref($str) eq 'HASH';
        push @objs, $str;
    }

    return (
            $inline_expression
            ? bless([map { {self => $_} } @objs], 'Sidef::Types::Array::HCArray')
            : Sidef::Types::Array::Array->new(\@objs)
           );
}

# Beginning of a here-document (<<"EOT", <<'EOT', <<EOT)
sub _parse_heredoc {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $indent = $opt{match} ? 1 : 0;
    my ($name, $type) = (undef, 1);

    my $pos = pos($_);
    if (/\G(?=(['"„]))/) {
        $type = 0 if $1 eq q{'};
        my $str = $self->get_quoted_string(code => $opt{code});
        $name = $str;
    }
    elsif (/\G(\w+)/gc) {
        $name = $1;
    }
    else {
        $self->fatal_error(
                           error  => "invalid 'here-doc' declaration",
                           reason => "expected an alpha-numeric token after '<<'",
                           code   => $_,
                           pos    => pos($_)
                          );
    }

    my $obj = {$self->{class} => []};
    push @{$self->{EOT}},
      {
        name   => $name,
        indent => $indent,
        type   => $type,
        obj    => $obj,
        pos    => $pos,
        line   => $self->{line},
      };

    return $obj;
}

# Regular expression
sub _parse_regex_literal {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $beg_pos = pos($_);
    my $string  = $self->get_quoted_string(code => $opt{code});
    my $flags   = (/\G($self->{match_flags_re})/goc ? $1 : undef);

    my $regex = eval { Sidef::Types::Regex::Regex->new($string, $flags) };

    if (not defined $regex) {
        my $reason = (split(/\R/, $@ // ''))[0] // 'unknown error';
        $reason =~ s/ at \S+ line \d+\.?.*//s;
        $self->fatal_error(
                           code   => $_,
                           pos    => $beg_pos,
                           error  => "invalid regular expression",
                           reason => $reason,
                          );
    }

    return $regex;
}

# Special constants: __MAIN__, __FILE__, __DATE__, __TIME__, __LINE__, __COMPILED__, __OPTIMIZED__
sub _parse_magic_constant {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $name = $opt{match};

    if ($name eq '__MAIN__') {
        if (-e $self->{script_name}) {
            state $x = require Cwd;
            return Sidef::Types::String::String->new(Cwd::abs_path($self->{script_name}));
        }
        return Sidef::Types::String::String->new($self->{script_name});
    }

    if ($name eq '__FILE__') {
        if (-e $self->{file_name}) {
            state $x = require Cwd;
            return Sidef::Types::String::String->new(Cwd::abs_path($self->{file_name}));
        }
        return Sidef::Types::String::String->new($self->{file_name});
    }

    if ($name eq '__DATE__') {
        my (undef, undef, undef, $day, $mon, $year) = localtime;
        return Sidef::Types::String::String->new(join('-', $year + 1900, map { sprintf "%02d", $_ } $mon + 1, $day));
    }

    if ($name eq '__TIME__') {
        my ($sec, $min, $hour) = localtime;
        return Sidef::Types::String::String->new(join(':', map { sprintf "%02d", $_ } $hour, $min, $sec));
    }

    if ($name eq '__LINE__') {
        return Sidef::Types::Number::Number->new($self->{line});
    }

    if ($name eq '__COMPILED__') {
        return Sidef::Types::Bool::Bool->new($self->{opt}{R} eq 'Perl' or $self->{opt}{c});
    }

    if ($name eq '__OPTIMIZED__') {
        return Sidef::Types::Bool::Bool->new(($self->{opt}{O} || 0) > 0);
    }

    return;
}

# Constants that depend on the context (the names that don't match anything are variables)
sub _parse_context_constant {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    if (exists($self->{current_block}) && /\G__BLOCK__\b/gc) {
        return $self->{current_block};
    }

    if (/\G__NAMESPACE__\b/gc) {
        return Sidef::Types::String::String->new($self->{class});
    }

    if (exists($self->{current_function})) {
        /\G__FUNC__\b/gc      && return $self->{current_function};
        /\G__FUNC_NAME__\b/gc && return Sidef::Types::String::String->new($self->{current_function}{name});
    }

    if (exists($self->{current_class})) {
        /\G__CLASS__\b/gc      && return $self->{current_class};
        /\G__CLASS_NAME__\b/gc && return Sidef::Types::String::String->new($self->{class_name});
    }

    if (exists($self->{current_method})) {
        /\G__METHOD__\b/gc      && return $self->{current_method};
        /\G__METHOD_NAME__\b/gc && return Sidef::Types::String::String->new($self->{current_method}{name});
    }

    return;
}

# Implicit method call on special variable: "_"
sub _parse_implicit_topic_call {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    if (defined(my $var = $self->find_var('_', $self->{class}))) {
        $var->{count}++;
        return $var->{obj};
    }

    if (/\G\.(?!\.)(?!\h*(?:$self->{method_name_re}|[(\$])|\s*$self->{operators_re})/o) {
        $self->fatal_error(
                           code   => $_,
                           pos    => pos($_),
                           error  => "incomplete method call",
                           reason => "expected a method name after `.`",
                          );
    }

    $self->fatal_error(
                       code  => $_,
                       pos   => pos($_),
                       error => q{attempt of using an implicit method call on an inexistent "_" variable},
                       hint => q{a leading `.method` is the method call on the topic variable `_`, which exists only inside blocks, such as: arr.each { .say }},
                      );
}

# Prefix method call (`::name(...)` or `::name ...`)
sub _parse_prefix_method_call {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $name = $opt{match};

    my $pos = pos($_);
    my $arg = $self->_parse_arg_or_obj(code => $opt{code});

    if (not exists($arg->{$self->{class}})) {
        $self->fatal_error(
                           code  => $_,
                           pos   => ($pos - length($name)),
                           var   => $name,
                           error => "attempt to call method <$name> on an undefined value",
                          );
    }

    return
      bless {
             name => $name,
             expr => $arg,
            },
      'Sidef::Meta::PrefixMethod';
}

# Assertions
sub _parse_assert {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $action = $opt{match};

    my $arg = $self->_parse_arg_or_obj(code => $opt{code});

    return
      bless(
            {
             arg  => $arg,
             act  => $action,
             line => $self->{line},
             file => $self->{file_name},
            },
            'Sidef::Meta::Assert'
           );
}

# Logical `not` (it has a lower precedence than comparisons: `not a == b` is `not (a == b)`)
sub _parse_not {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $arg = $self->parse_obj(code => $opt{code}, prec => PREC_NOT);

    $arg // $self->fatal_error(
                               code  => $_,
                               pos   => pos($_),
                               error => "expected an expression after `not`",
                              );

    return $self->_negate($arg);
}

# die/warn
sub _parse_die_warn {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $action = $opt{match};

    my $arg = $self->_parse_arg_or_obj(code => $opt{code});

    return
      bless(
            {
             arg  => $arg,
             line => $self->{line},
             file => $self->{file_name},
            },
            $action eq 'die'
            ? "Sidef::Meta::Error"
            : "Sidef::Meta::Warning"
           );
}

# Eval keyword
sub _parse_eval {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $obj = $self->_parse_arg_or_obj(code => $opt{code});

#<<<
    return bless(
        {
         expr   => $obj,
         parser => Sidef::Object::Object::dclone(scalar {%$self}),

         #vars          => {$self->{class} => [@{$self->{vars}{$self->{class}}}]},
         #ref_vars_refs => {$self->{class} => [@{$self->{ref_vars_refs}{$self->{class}}}]},

        }, 'Sidef::Eval::Eval');
#>>>
}

# Misplaced keywords: the better error messages, for the keywords that can't be used as variables
sub _check_misplaced_keyword {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    # Misplaced keywords (for better error messages)
    if (/\G(elsif|else|orwith)\b/gc) {
        my $word = $1;
        $self->fatal_error(
                           code   => $_,
                           pos    => pos($_) - length($word),
                           error  => "unexpected `$word`",
                           reason => (
                                      $word eq 'orwith'
                                      ? "`orwith` must follow a `with` statement"
                                      : "`$word` must follow an `if` statement"
                                     ),
                          );
    }

    if (/\G(elif|elseif)\b/gc) {
        my $word = $1;
        $self->fatal_error(
                           code  => $_,
                           pos   => pos($_) - length($word),
                           error => "unknown keyword `$word`",
                           hint  => "use `elsif` (or `else if`) instead",
                          );
    }

    if (/\Gcatch\h*(?=\{)/gc) {
        $self->fatal_error(
                           code   => $_,
                           pos    => pos($_) - 5,
                           error  => "unexpected `catch`",
                           reason => "`catch` must follow a `try` block",
                          );
    }

    if (   /\G(when|case)\h*(?=\()/gc
        || /\G(default)\h*(?=\{)/gc
        || /\G(continue)\b/gc) {
        my $word = $1;
        if ($word eq 'continue' or not defined $self->find_var($word, $self->{class})) {
            $self->fatal_error(
                               code   => $_,
                               pos    => pos($_) - length($word),
                               error  => "unexpected `$word`",
                               reason => "`$word` can only be used inside a `given(...) {...}` block",
                              );
        }
        pos($_) -= length($word);
        /\G\Q$word\E\h*/gc;
    }

    return;
}

# Variable access
sub _parse_variable_access {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    /\G($self->{var_name_re})/goc || return;

    my $len_var = length($1);
    my ($name, $class) = $self->get_name_and_class($1);

    # A declared variable
    if (defined(my $var = $self->find_var($name, $class))) {

        if ($var->{type} eq 'del') {
            $self->fatal_error(
                               code  => $_,
                               pos   => (pos($_) - length($name)),
                               var   => ($class . '::' . $name),
                               error => "attempt to use the deleted variable <$name>",
                              );
        }

        $var->{count}++;
        return $var->{obj};
    }

    # The predefined variables
    if ($name eq 'ARGV' or $name eq 'ENV') {

        my $type     = 'var';
        my $variable = bless({name => $name, type => $type, class => $class}, 'Sidef::Variable::Variable');

        $self->_unshift_var(
                            $class,
                            {
                             obj   => $variable,
                             name  => $name,
                             count => 1,
                             type  => $type,
                             line  => $self->{line},
                            }
                           );

        return $variable;
    }

    # Class instance variables
    if (ref($self->{current_class}) eq 'Sidef::Variable::ClassInit'
        and defined(my $var = first { $_->{name} eq $name } $self->_class_fields($self->{current_class}))) {
        my $result = $self->_parse_class_instance_variable($var, $name, $class, code => $opt{code});
        return $result if defined($result);
    }

    # Implicit declaration of a global variable
    if (/\G(?=\h*:?=(?![=~>]))/) {

        if (not $self->{interactive}) {
            warn "[WARNING] Implicit declaration of global variable `$name`" . " at $self->{file_name} line $self->{line}\n";
        }

        my $code = "global $name";
        return $self->parse_expr(code => \$code);
    }

    # Method call in functional style (deprecated -- use `::name()` instead)
    if ($len_var == length($name)) {
        return $self->_parse_functional_call($name, $class, code => $opt{code});
    }

    # Undeclared variable
    $self->fatal_error(
                       code  => $_,
                       pos   => (pos($_) - length($name)),
                       var   => ($class . '::' . $name),
                       error => "variable <$class\::$name> is not declared in the current scope",
                      );
}

# The fields (parameters and attributes) of a class, including the inherited ones.
# The fields of the class itself come first, then the ones of its parents, from left to right.
sub _class_fields {
    my ($self, $class, $seen) = @_;

    $seen //= {};
    $seen->{refaddr($class)}++ and return;

    my @fields = (@{$class->{vars} // []}, map { @{$_->{vars}} } @{$class->{attributes} // []});

    foreach my $parent (@{$class->{inherit} // []}) {
        if (ref($parent) eq 'Sidef::Variable::ClassInit' and not ref($parent->{name})) {
            push @fields, $self->_class_fields($parent, $seen);
        }
    }

    return @fields;
}

# A class variable that is used inside the class: it's the same as `self.name` inside a method.
# Returns nothing when the variable should be handled as an ordinary variable.
sub _parse_class_instance_variable {
    my ($self, $var, $name, $class, %opt) = @_;

    local *_ = $opt{code};

    if (exists $self->{current_method}) {
        if (defined(my $self_var = $self->find_var('self', $class))) {

            if ($self->{opt}{k}) {
                print STDERR "[INFO] `$name` is parsed as `self.$name` at $self->{file_name} line $self->{line}\n";
            }

            $self_var->{count}++;
            return
              scalar {
                      $self->{class} => [
                                         {
                                          self => $self_var->{obj},
                                          ind  => [{hash => [$name]}],
                                         }
                                        ]
                     };
        }

        return;
    }

    if (exists $self->{allow_class_variable}) {
        return $var;
    }

    if ($var->{type} eq 'has') {
        $self->fatal_error(
                           error => "class variable <<$var->{name}>> can't be used outside a method",
                           pos   => (pos($_) - length($name)),
                           var   => $var,
                           code  => $_,
                          );
    }

    # this should not happen
    $self->fatal_error(
                       error => "can't use undeclared variable <<$var->{name}>> in this context",
                       pos   => (pos($_) - length($name)),
                       var   => $var,
                       code  => $_,
                      );
}

# A call in the functional style: `name(...)`, which is the same as `::name(...)`
sub _parse_functional_call {
    my ($self, $name, $class, %opt) = @_;

    local *_ = $opt{code};

    if ($self->{opt}{k}) {
        print STDERR "[INFO] `$name` is parsed as a prefix method-call at $self->{file_name} line $self->{line}\n";
    }

    if ($self->{allow_class_variable}) {
        return $name;
    }

    my $pos = pos($_);
    my $arg = (
               /\G\h*+(?=\()/gc
               ? $self->parse_arg(code => $opt{code})
               : $self->fatal_error(
                                    code  => $_,
                                    pos   => ($pos - length($name)),
                                    var   => ($class . '::' . $name),
                                    error => "variable <$name> is not declared in the current scope",
                                   )
              );

    if (not exists($arg->{$self->{class}})) {
        $self->fatal_error(
                           code  => $_,
                           pos   => ($pos - length($name)),
                           var   => $name,
                           error => "attempt to call method <$name> on an undefined value",
                          );
    }

    return
      bless {
             name => $name,
             expr => $arg,
            },
      'Sidef::Meta::PrefixMethod';
}

# ---------------------------------------------------------------------------
# Declarations: variables, constants, structs, subsets, enums
# ---------------------------------------------------------------------------

# Declaration of variables (global and lexical)
sub _parse_variable_declaration {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $type     = $opt{match};
    my $vars     = $self->parse_init_vars(code => $opt{code}, type => $type);
    my $init_obj = bless({vars => $vars}, 'Sidef::Variable::Init');

    @{$vars}
      || $self->fatal_error(
                            code   => $_,
                            pos    => pos($_),
                            error  => "expected a variable name after `$type`",
                            reason => "a variable name can contain letters, digits and underscores, but it can't start with a digit",
                           );

    if (/\G\h*=\h*/gc) {

        my $args = $self->parse_obj(code => $opt{code}, multiline => 1);

        $args // $self->fatal_error(
                                    code  => $_,
                                    pos   => pos($_),
                                    error => "expected an expression after variable declaration",
                                   );

        $init_obj->{args} = $args;
    }

    return $init_obj;
}

# "has" class attributes
sub _parse_class_attributes {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    local $self->{allow_class_variable} = 0;

    my $vars = $self->parse_init_vars(
                                      code    => $opt{code},
                                      type    => 'has',
                                      private => 1,
                                     );

    foreach my $var (@{$vars}) {
        my $name = $var->{name};
        $self->_check_reserved_name($_, $name, (pos($_) - length($name)));
    }

    my $args;
    if (/\G\h*=\h*/gc) {
        $args = $self->parse_obj(code => $opt{code}, multiline => 1);
        $args // $self->fatal_error(
                                    code  => $_,
                                    pos   => pos($_) - 2,
                                    error => qq{expected an expression after "=" in `has` declaration},
                                   );
    }

    my $obj = bless {vars => $vars, defined($args) ? (args => $args) : ()}, 'Sidef::Variable::ClassAttr';
    push @{$self->{current_class}{attributes}}, $obj;
    return $obj;
}

# Declaration of constants and static variables
sub _parse_constant_declaration {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $type = $opt{match};
    my $line = $self->{line};

    my @var_objs;

    my $callback = sub {
        my ($v) = @_;

        my $name       = $v->{name};
        my $class_name = $v->{class};

        my $var = (
                     $type eq 'define' ? bless($v, 'Sidef::Variable::Define')
                   : $type eq 'static' ? bless($v, 'Sidef::Variable::Static')
                   : $type eq 'const'  ? bless($v, 'Sidef::Variable::Const')
                   :                     die "[PARSER ERROR] Invalid variable type: $type"
                  );

        push @var_objs, $var;

        $self->_unshift_var(
                            $class_name,
                            {
                             obj   => $var,
                             name  => $name,
                             count => 0,
                             type  => $type,
                             line  => $line,
                            }
                           );
    };

    my $vars = $self->parse_init_vars(
                                      code     => $opt{code},
                                      type     => $type,
                                      private  => 1,
                                      callback => $callback,
                                     );

    foreach my $var (@var_objs) {
        my $name = $var->{name};
        $self->_check_reserved_name($_, $name, (pos($_) - length($name)));
    }

    if (@var_objs == 1 and /\G\h*=\h*/gc) {

        my $var = $var_objs[0];
        my $obj = $self->parse_obj(code => $opt{code}, multiline => 1);

        $obj // $self->fatal_error(
                                   code  => $_,
                                   pos   => pos($_) - 2,
                                   error => qq{expected an expression after $type "$var->{name}"},
                                  );

        $var->{value} = $obj;
    }

    my $const_init = bless({vars => \@var_objs, type => $type}, 'Sidef::Variable::ConstInit');

    if (/\G\h*=\h*/gc) {
        $self->fatal_error(
                           code  => $_,
                           pos   => pos($_) - 2,
                           error => qq{the correct syntax is: `$type(x = ..., y = ...)`},
                          );
    }

    return $const_init;
}

# Struct declaration
sub _parse_struct {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my ($name, $class_name);
    if (/\G($self->{var_name_re})\h*/goc) {
        ($name, $class_name) = $self->get_name_and_class($1);
    }

    defined($name) and $self->_check_reserved_name($_, $name, pos($_) - length($name));

    my $struct = bless(
                       {
                        name  => $name,
                        class => $class_name,
                       },
                       'Sidef::Variable::Struct'
                      );

    if (defined $name) {
        $self->_unshift_var(
                            $class_name,
                            {
                             obj   => $struct,
                             name  => $name,
                             count => 0,
                             type  => 'struct',
                             line  => $self->{line},
                            }
                           );
    }

    my $vars = $self->parse_init_vars(
                                      code    => $opt{code},
                                      type    => 'var',
                                      private => 1,
                                      scoped  => 1,
                                     );

    $struct->{vars} = $vars;

    return $struct;
}

# Subset declaration
sub _parse_subset {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my ($name, $class_name);
    if (/\G($self->{var_name_re})\h*/goc) {
        ($name, $class_name) = $self->get_name_and_class($1);
    }
    else {
        $self->fatal_error(
                           code  => $_,
                           pos   => pos($_),
                           error => "expected a name after the keyword 'subset'",
                          );
    }

    $self->_check_reserved_name($_, $name, (pos($_) - length($name)));

    my $subset = bless({name => $name, class => $class_name}, 'Sidef::Variable::Subset');

    $self->_unshift_var(
                        $class_name,
                        {
                         obj   => $subset,
                         name  => $name,
                         count => 0,
                         type  => 'subset',
                         line  => $self->{line},
                        }
                       );

    # Inheritance
    if (/\G<<?\h*/gc) {
        {
            my ($name) = /\G($self->{var_name_re})\h*/goc;

            $name // $self->fatal_error(
                                        code  => $_,
                                        pos   => pos($_),
                                        error => "expected a type name for subsetting",
                                       );

            my $code = $name;
            my $type = $self->parse_expr(code => \$code);

            push @{$subset->{inherits}}, $type;

            /\G,\h*/gc && redo;
        }
    }

    if (/\G(?=\{)/) {
        my $block = $self->parse_block(code => $opt{code}, topic_var => 1);
        $subset->{block} = $block;
    }

    return $subset;
}

# Declaration of enums
sub _parse_enum {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $vars = $self->parse_init_vars(
                                      code    => $opt{code},
                                      type    => 'var',
                                      private => 1,
                                     );

    @{$vars}
      || $self->fatal_error(
                            code  => $_,
                            pos   => pos($_),
                            error => q{expected one or more variable names after <enum>},
                           );

    my $value = Sidef::Types::Number::Number::_set_int(-1);

    foreach my $var (@{$vars}) {
        my $name = $var->{name};

        if (ref $var->{value} eq 'HASH') {
            $var->{value} = $var->{value}{$self->{class}}[-1]{self};
        }

        $value =
            $var->{has_value}
          ? $var->{value}
          : $value->inc;

        $self->_check_reserved_name($_, $name, (pos($_) - length($name)));

        $self->_unshift_var(
                            $self->{class},
                            {
                             obj   => $value,
                             name  => $name,
                             count => 0,
                             type  => 'enum',
                             line  => $self->{line},
                            }
                           );
    }

    return $value;
}

# Local variables
sub _parse_local {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $expr = $self->parse_obj(code => $opt{code}, prec => PREC_OPERAND);

    $expr // $self->fatal_error(
                                code  => $_,
                                pos   => pos($_),
                                error => "expected a variable after `local`",
                               );

    return bless({expr => $expr}, 'Sidef::Variable::Local');
}

# ---------------------------------------------------------------------------
# Declarations: classes, functions and methods
# ---------------------------------------------------------------------------

# Declaration of classes, methods and functions
sub _parse_function_or_class {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $type =
        $opt{match} eq '->'
      ? exists($self->{current_class}) && !(exists($self->{current_method}))
          ? 'method'
          : 'func'
      : $opt{match};

    my ($name, $class_name, $built_in_obj) = $self->_parse_declaration_name($type, code => $opt{code});

    my ($obj, $has_kids, $parent) = $self->_declare_function_or_class($type, $name, $class_name, $built_in_obj, code => $opt{code});

    if ($type eq 'class') {
        $self->_parse_class_definition($obj, $name, $built_in_obj, code => $opt{code});
    }
    else {
        $self->_parse_function_definition($obj, $type, $name, $has_kids, $parent, code => $opt{code});
    }

    return $obj;
}

# Parses the name of a class, function or method: returns (name, namespace, built-in object)
sub _parse_declaration_name {
    my ($self, $type, %opt) = @_;

    local *_ = $opt{code};

    my $name       = '';
    my $class_name = $self->{class};
    my $built_in_obj;

    if ($type eq 'class' and /\G($self->{var_name_re})\h*/gco) {

        $name = $1;

        if (exists($self->{built_in_classes}{$name}) and /\G(?=[{<])/) {

            my ($obj) = $self->parse_expr(code => \$name);

            if (defined($obj)) {
                $name         = '';
                $built_in_obj = $obj;
            }
        }
        else {
            ($name, $class_name) = $self->get_name_and_class($1);
        }
    }

    if ($type eq 'method') {
        $name = (
                   /\G($self->{method_name_re})\h*/goc ? $1
                 : /\G($self->{operators_re})\h*/goc   ? $+
                 :                                       ''
                );
        ($name, $class_name) = $self->get_name_and_class($name);
    }
    elsif ($type ne 'class') {
        $name = /\G($self->{var_name_re})\h*/goc ? $1 : '';
        ($name, $class_name) = $self->get_name_and_class($name);
    }

    if ($type ne 'method' and $type ne 'class') {
        $self->_check_reserved_name($_, $name, $-[0]);
    }

    return ($name, $class_name, $built_in_obj);
}

# Creates the object of a class, function or method, and registers it in the current scope
# Returns: (object, true when it's a new definition of an existing function, the existing function)
sub _declare_function_or_class {
    my ($self, $type, $name, $class_name, $built_in_obj, %opt) = @_;

    local *_ = $opt{code};

    my $obj =
        ($type eq 'func' or $type eq 'method') ? bless({name => $name, type => $type, class => $class_name}, 'Sidef::Variable::Variable')
      : $type eq 'class' ? bless({name => ($built_in_obj // $name), class => $class_name}, 'Sidef::Variable::ClassInit')
      : $self->fatal_error(
                           error  => "invalid type",
                           reason => "expected a magic thing to happen",
                           code   => $_,
                           pos    => pos($_),
                          );

    if ($name ne '') {
        my $var = $self->find_var($name, $class_name);

        if (defined($var) and $var->{type} eq 'class') {
            $obj->{parent} = $var->{obj};
            push @{$obj->{inherit}}, ref($var->{obj}{name}) ? $var->{obj}{name} : $var->{obj};
        }
    }

    my $has_kids = 0;
    my $parent;
    if (($type eq 'method' or $type eq 'func') and $name ne '') {
        my $var = $self->find_var($name, $class_name);

        # A function or a method must be declared in the same scope
        if (defined($var) and $var->{obj}{type} eq $type) {

            $parent   = $var->{obj};
            $has_kids = 1;

            $parent->{has_kids} = 1;
            $obj->{parent}      = $parent;
        }
    }

    if (not $has_kids) {
        $self->_unshift_var(
                            $class_name,
                            {
                             obj   => $obj,
                             name  => $name,
                             count => 0,
                             type  => $type,
                             line  => $self->{line},
                            }
                           );
    }

    return ($obj, $has_kids, $parent);
}

# Parses the parameters, the inheritance list and the block of a class
sub _parse_class_definition {
    my ($self, $obj, $name, $built_in_obj, %opt) = @_;

    local *_ = $opt{code};

    my $var_names =
      $self->parse_init_vars(
                             code         => $opt{code},
                             params       => 1,
                             private      => 1,
                             scoped       => 1,
                             type         => 'has',
                             ignore_delim => {
                                              '{' => 1,
                                              '<' => 1,
                                             },
                            );

    # Set the class parameters
    $obj->{vars} = $var_names;

    $self->_parse_class_inheritance($obj, code => $opt{code});

    /\G\h*(?=\{)/gc
      || $self->fatal_error(
                            error  => "invalid class declaration",
                            reason => "expected: class $name(...){...}",
                            code   => $_,
                            pos    => pos($_)
                           );

    local $self->{class_name}    = (defined($built_in_obj) ? ref($built_in_obj) : $obj->{name});
    local $self->{current_class} = $built_in_obj // $obj;
    my $block = $self->parse_block(code => $opt{code});

    # Set the block of the class
    $obj->{block} = $block;

    return;
}

# Class inheritance: class Name(...) << Name1, Name2
sub _parse_class_inheritance {
    my ($self, $obj, %opt) = @_;

    local *_ = $opt{code};

    # Class inheritance (class Name(...) << Name1, Name2)
    if (/\G\h*<<?\h*/gc) {
        while (/\G($self->{var_name_re})\h*/gco) {
            my ($name, $class_name) = $self->get_name_and_class($1);
            if (defined(my $class = $self->find_var($name, $class_name))) {
                if ($class->{type} eq 'class') {

                    # Detect inheritance from the same class
                    if (refaddr($obj) == refaddr($class->{obj})) {
                        $self->fatal_error(
                                           error => "Inheriting from the same class is not allowed",
                                           code  => $_,
                                           pos   => pos($_) - length($name) - 1,
                                          );
                    }

                    ++$class->{count};
                    push @{$obj->{inherit}}, $class->{obj};
                }
                else {
                    $self->fatal_error(
                                       error  => "this is not a class",
                                       reason => "expected a class name",
                                       code   => $_,
                                       pos    => pos($_) - length($name) - 1,
                                      );
                }
            }
            elsif (exists $self->{built_in_classes}{$name}) {
                $self->fatal_error(
                                   error  => "Inheriting from built-in classes is not supported",
                                   reason => "`$name` is a built-in class",
                                   code   => $_,
                                   pos    => pos($_) - length($name) - 1,
                                  );
            }
            else {
                $self->fatal_error(
                                   error  => "can't find `$name` class",
                                   reason => "expected an existent class name",
                                   var    => ($class_name . '::' . $name),
                                   code   => $_,
                                   pos    => pos($_) - length($name) - 1,
                                  );
            }

            /\G,\h*/gc;
        }
    }

    return;
}

# Parses the signature, the traits, the return types and the block of a function or a method
sub _parse_function_definition {
    my ($self, $obj, $type, $name, $has_kids, $parent, %opt) = @_;

    local *_ = $opt{code};

    my $var_names = do {
        local $self->{allow_class_variable} = 1 if $type eq 'method';
        $self->get_init_vars(
                             code         => $opt{code},
                             with_vals    => 1,
                             ignore_delim => {
                                              '{' => 1,
                                              '-' => 1,
                                             }
                            );
    };

    $self->_parse_function_traits($obj, $type, code => $opt{code});
    $self->_parse_return_types($obj, $type, $name, code => $opt{code});

    my $brace_pos;
    (/\G\h*(?=\{)/gc and ($brace_pos = pos($_)) and /\G\{\h*/gc)
      || $self->fatal_error(
                            error  => "invalid `$type` declaration",
                            reason => "expected: $type $name(...){...}",
                            code   => $_,
                            pos    => pos($_)
                           );

    local $self->{$type eq 'func' ? 'current_function' : 'current_method'} = $has_kids ? $parent : $obj;
    my $args = '|' . join(',', $type eq 'method' ? 'self' : (), @{$var_names}) . ' |';

    # The parameters are parsed from a separate string, to avoid copying the rest of the code
    my $block = $self->parse_block(
                                   code      => $opt{code},
                                   with_vars => 1,
                                   init_code => \$args,
                                   no_brace  => $brace_pos,
                                  );

    # Set the block of the function/method
    $obj->{value} = $block;

    return;
}

# Functions and method traits (example: "is cached")
sub _parse_function_traits {
    my ($self, $obj, $type, %opt) = @_;

    local *_ = $opt{code};

    if (/\G\h*is\h+(?=\w)/gc) {
        while (/\G(\w+)/gc) {
            my $trait = $1;
            if ($trait eq 'cached') {
                $obj->{cached} = 1;
            }

            else {
                $self->fatal_error(
                                   error => "Unknown $type trait: $trait",
                                   code  => $_,
                                   pos   => pos($_),
                                  );
            }

            /\G\h*,\h*/gc || last;
        }
    }

    return;
}

# Function return type: func name(...) -> Type {...}
sub _parse_return_types {
    my ($self, $obj, $type, $name, %opt) = @_;

    local *_ = $opt{code};

    if (/\G\h*->\h*/gc) {

        my @ref;
        if (/\G\(/gc) {    # multiple types
            while (1) {
                my ($ref) = $self->parse_expr(code => $opt{code});
                push @ref, $ref;

                /\G\s*\)/gc && last;
                /\G\s*,\s*/gc
                  || $self->fatal_error(
                                        error  => "invalid return-type for $type $self->{class_name}<<$name>>",
                                        reason => "expected a comma",
                                        code   => $_,
                                        pos    => pos($_),
                                       );
            }
        }
        else {    # only one type
            my ($ref) = $self->parse_expr(code => $opt{code});
            push @ref, $ref;
        }

        foreach my $ref (@ref) {
            if (ref($ref) eq 'HASH') {
                $self->fatal_error(
                                   error  => "invalid return-type for $type $self->{class_name}<<$name>>",
                                   reason => "expected a valid type, such as: Str, Num, Arr, etc...",
                                   code   => $_,
                                   pos    => pos($_),
                                  );
            }
        }

        $obj->{returns} = \@ref;
    }

    return;
}

# ---------------------------------------------------------------------------
# Control flow: given/when, try/catch, gather/take
# ---------------------------------------------------------------------------

# "given(expr) {...}" construct
sub _parse_given {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $expr = $self->_parse_arg_or_obj(code => $opt{code});

    $expr // $self->fatal_error(
                                error  => "invalid declaration of the `given/when` construct",
                                reason => "expected `given(expr) {...}`",
                                code   => $_,
                                pos    => pos($_),
                               );

    my $given_obj = bless({expr => $expr}, 'Sidef::Types::Block::Given');
    local $self->{current_given} = $given_obj;
    my $block = (
                 /\G\h*(?=\{)/gc
                 ? $self->parse_block(code => $opt{code}, topic_var => 1)
                 : $self->fatal_error(
                                      error => "expected a block after `given(expr)`",
                                      code  => $_,
                                      pos   => pos($_),
                                     )
                );

    $given_obj->{block} = $block;

    return $given_obj;
}

# "when(expr) {...}" construct
sub _parse_when {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $expr = $self->_parse_arg_or_obj(code => $opt{code});

    $expr // $self->fatal_error(
                                error  => "invalid declaration of the `when` construct",
                                reason => "expected `when(expr) {...}`",
                                code   => $_,
                                pos    => pos($_),
                               );

    my $block = (
                 /\G\h*(?=\{)/gc
                 ? $self->parse_block(code => $opt{code}, with_vars => 1)
                 : $self->fatal_error(
                                      error => "expected a block after `when(expr)`",
                                      code  => $_,
                                      pos   => pos($_),
                                     )
                );

    return bless({expr => $expr, block => $block}, 'Sidef::Types::Block::When');
}

# "case(expr) {...}" construct
sub _parse_case {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $expr = $self->_parse_arg_or_obj(code => $opt{code});

    $expr // $self->fatal_error(
                                error  => "invalid declaration of the `case` construct",
                                reason => "expected `case(expr) {...}`",
                                code   => $_,
                                pos    => pos($_),
                               );

    my $block = (
                 /\G\h*(?=\{)/gc
                 ? $self->parse_block(code => $opt{code}, with_vars => 1)
                 : $self->fatal_error(
                                      error => "expected a block after `case(expr)`",
                                      code  => $_,
                                      pos   => pos($_),
                                     )
                );

    return bless({expr => $expr, block => $block}, 'Sidef::Types::Block::Case');
}

# "try/catch" construct
sub _parse_try {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $try_block = $self->parse_block(code => $opt{code});
    my $obj       = bless({try => $try_block}, 'Sidef::Types::Block::Try');

    $self->parse_whitespace(code => $opt{code});

    if (/\Gcatch\h*(?=\{)/gc) {
        $obj->{catch} = $self->parse_block(code => $opt{code}, with_vars => 1);
    }
    else {
        $self->backtrack_whitespace(code => $opt{code});
    }

    return $obj;
}

# "gather/take" construct
sub _parse_gather {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $obj = bless({}, 'Sidef::Types::Block::Gather');

    local $self->{current_gather} = $obj;

    my $block = $self->parse_block(code => $opt{code});
    $obj->{block} = $block;

    return $obj;
}

# ---------------------------------------------------------------------------
# Modules, imports and includes
# ---------------------------------------------------------------------------

# Declaration of a module
sub _parse_module {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $name =
      /\G($self->{var_name_re})\h*/goc
      ? $1
      : $self->fatal_error(
                           error  => "invalid module declaration",
                           reason => "expected a name",
                           code   => $_,
                           pos    => pos($_)
                          );

    $self->parse_whitespace(code => $opt{code});

    if (/\G(?=\{)/) {
        my $prev_class = $self->{class};
        local $self->{class} = $name;
        my $obj = $self->parse_block(code => $opt{code}, is_module => 1, prev_class => $prev_class);

        return
          bless {
                 name  => $name,
                 block => $obj
                },
          'Sidef::Meta::Module';
    }
    else {
        $self->fatal_error(
                           error  => "invalid module declaration",
                           reason => "expected: module $name {...}",
                           code   => $_,
                           pos    => pos($_)
                          );
    }
}

# Imports variables from another namespace: import Name1, Name2
sub _parse_import {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $import_pos = pos($_);

    my $var_names = $self->get_init_vars(code      => $opt{code},
                                         with_vals => 0);

    $self->backtrack_whitespace(code => $opt{code});

    @{$var_names}
      || $self->fatal_error(
                            code  => $_,
                            pos   => $import_pos,
                            error => "expected a variable-like name for importing!",
                           );

    foreach my $var_name (@{$var_names}) {
        my ($name, $class) = $self->get_name_and_class($var_name);

        if ($class eq ($self->{class})) {
            $self->fatal_error(
                               code  => $_,
                               pos   => $import_pos,
                               error => "can't import '${class}::${name}' into the same namespace",
                              );
        }

        my $var = $self->find_var($name, $class);

        if (not defined $var) {
            $self->fatal_error(
                               code  => $_,
                               pos   => $import_pos,
                               error => "variable '${class}::${name}' does not exists",
                              );
        }

        $var->{count}++;

        $self->_unshift_var(
                            $self->{class},
                            {
                             obj   => $var->{obj},
                             name  => $name,
                             count => 0,
                             type  => $var->{type},
                             line  => $self->{line},
                            }
                           );
    }

    return 1;
}

# Parses an include statement: `include Module::Name` or `include "file.sf"`
sub _parse_include {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $include_pos = pos($_);

    $self->_init_include_paths;

    my @abs_filenames;

    if (/\G($self->{var_name_re})/gc) {
        my $module = $self->_find_module_file($1, $include_pos, code => $opt{code});

        # The module is already available -- skip
        defined($module) || return REDO_PARSE;

        push @abs_filenames, $module;
    }
    else {
        push @abs_filenames, $self->_resolve_include_files($include_pos, code => $opt{code});
    }

    return $self->_load_included_files(\@abs_filenames, $include_pos, code => $opt{code});
}

# The directories where the included files are searched
sub _init_include_paths {
    my ($self) = @_;

    state $x = do {
        require Cwd;
        require File::Spec;
        require File::Basename;
    };

    if (@{$self->{inc}} == 0) {
        push @{$self->{inc}}, split(':', $ENV{SIDEF_INC}) if exists($ENV{SIDEF_INC});

        push @{$self->{inc}}, File::Spec->catdir(File::Basename::dirname(Cwd::abs_path($0)), File::Spec->updir, 'share', 'sidef');

        if (-f $self->{script_name}) {
            push @{$self->{inc}}, File::Basename::dirname(Cwd::abs_path($self->{script_name}));
        }

        push @{$self->{inc}}, File::Spec->curdir;
    }
    return;
}

# Finds the file of a module: returns [path, module name], or nothing when the module is already available
sub _find_module_file {
    my ($self, $var_name, $include_pos, %opt) = @_;

    local *_ = $opt{code};

    # The module is defined in the current file -- skip
    if (exists $self->{ref_vars}{$var_name}) {
        return;
    }

    # The module was already included -- skip
    if (exists $Sidef::INCLUDED{$var_name}) {
        return;
    }

    my @path     = split(/::/, $var_name);
    my $mod_path = File::Spec->catfile(@path[0 .. $#path - 1], $path[-1] . '.sm');

    $Sidef::INCLUDED{$var_name} = $mod_path;

    my ($full_path, $found_module);
    foreach my $inc_dir (@{$self->{inc}}) {
        if (    -e ($full_path = File::Spec->catfile($inc_dir, $mod_path))
            and -f _
            and -r _ ) {
            $found_module = 1;
            last;
        }
    }

    $found_module // $self->fatal_error(
                                        code  => $_,
                                        pos   => $include_pos,
                                        error => "can't find the module '${mod_path}' anywhere in ['" . join("', '", @{$self->{inc}}) . "']",
                                       );

    return [$full_path, $var_name];
}

# Resolves the files of an include expression: returns a list of [path]
sub _resolve_include_files {
    my ($self, $include_pos, %opt) = @_;

    local *_ = $opt{code};

    my $orig_dir  = Cwd::getcwd();
    my $orig_file = Cwd::abs_path($self->{file_name});
    my $file_dir  = File::Basename::dirname($orig_file);

    # The working directory is restored when the guard is destroyed (even when an error is thrown)
    my $restore_dir;
    if ($orig_dir ne $file_dir) {
        if (chdir($file_dir)) {
            $restore_dir = bless(sub { chdir($orig_dir) }, 'Sidef::Parser::DirectoryGuard');
        }
    }

    my $expr = do {
        my ($obj) = $self->parse_expr(code => $opt{code});
        $obj;
    };

    my @files = (
        ref($expr) eq 'HASH'
        ? do {
            map { $_->{self} }
            map { @{$_->{self}->{$self->{class}}} }
            map { @{$expr->{$_}} }
              keys %{$expr};
          }
        : $expr
    );

    my @resolved = map {
        my $filename = $_;

        if (index(ref($filename), 'Sidef::') == 0) {
            $filename = $filename->get_value;
        }

        ref($filename) ne ''
          and $self->fatal_error(
                                 code  => ${$opt{code}},
                                 pos   => $include_pos,
                                 error => 'include-error: invalid value of type "' . ref($filename) . '" (expected a string)',
                                );

        my @files;
        foreach my $file (glob($filename)) {

            my $resolved = 0;
            foreach my $base ('', @{$self->{inc}}) {
                my $abs_path = File::Spec->rel2abs($file, $base) // next;

                if (-f $abs_path) {
                    push @files, $abs_path;
                    $resolved = 1;
                    last;
                }
            }

            if (!$resolved) {
                $self->fatal_error(
                                   code  => ${$opt{code}},
                                   pos   => $include_pos,
                                   error => "include-error: could not resolve path to file `$file`",
                                  );
            }
        }

        foreach my $file (@files) {
            if (exists $Sidef::INCLUDED{$file}) {
                $self->fatal_error(
                                   code  => ${$opt{code}},
                                   pos   => $include_pos,
                                   error => "include-error: circular inclusion of file `$file`",
                                  );
            }
        }

        map { [$_] } @files
    } @files;

    return @resolved;
}

# Parses the included files: returns a `Sidef::Meta::Included` object
sub _load_included_files {
    my ($self, $abs_filenames, $include_pos, %opt) = @_;

    local *_ = $opt{code};

    my @included;

    foreach my $pair (@{$abs_filenames}) {

        my ($full_path, $name) = @{$pair};

        open(my $fh, '<:utf8', $full_path)
          || $self->fatal_error(
                                code  => ${$opt{code}},
                                pos   => $include_pos,
                                error => "can't open file `$full_path`: $!"
                               );

        my $content = do { local $/; <$fh> };
        close $fh;

        utf8::downgrade($content, 1);    # faster to parse, when there are no wide characters

        next if $Sidef::INCLUDED{$full_path};

        local $self->{class}               = $name if defined $name;    # new namespace
        local $self->{line}                = 1;
        local $self->{file_name}           = $full_path;
        local $Sidef::INCLUDED{$full_path} = 1;

        my $ast = $self->parse_script(code => \$content);

        push @included,
          {
            name => $name,
            file => $full_path,
            ast  => $ast,
          };
    }

    return bless({included => \@included}, 'Sidef::Meta::Included');
}

# ---------------------------------------------------------------------------
# Operands: prefix operators, control-flow statements, calls and indices
# ---------------------------------------------------------------------------

sub parse_operand {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    if (not($opt{multiline}) and /\G\h*(?=\R)/gc) {
        $self->fatal_error(
                           code  => $_,
                           pos   => pos($_) - 1,
                           error => "unexpected end-of-statement",
                          );
    }

    my ($obj, $obj_key, $method) = $self->parse_expr(code => $opt{code});

    defined($obj) || return;

    my %struct = ($self->{class} => [{self => $obj}]);
    my $wrap;

    # for (var in array) { ... }
    my $for_paren = 0;
    if (ref($obj) eq 'Sidef::Types::Block::For'
        and /\G\h*\((?=\h*[*:]?$self->{var_name_re}(?:\h*,\h*[*:]?$self->{var_name_re})*\h+(?:in|∈)\b)/goc) {
        $for_paren = 1;
        /\G\h*/gc;
    }

    # for var in array { ... }
    if ($for_paren or (ref($obj) eq 'Sidef::Types::Block::For' and /\G\h*(?=[*:]?$self->{var_name_re})/goc)) {
        $self->_parse_for_in_loop($obj, $for_paren, code => $opt{code});
    }

    # A prefix operator or a control-flow keyword, followed by an argument
    elsif ($obj_key) {
        $wrap = $self->_parse_prefix_expression($obj, $method, \%struct, code => $opt{code});
    }

    $self->_parse_postfix(\%struct, $obj, code => $opt{code});

    return (wantarray ? (\%struct, $wrap) : \%struct);
}

# Parses the argument of a prefix operator or of a keyword (e.g.: -x, !x, say x, return x, if (x) {...})
sub _parse_prefix_arg {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $obj    = $opt{obj};
    my $method = $opt{method};
    my $ref    = ref($obj);

    # Bare `return` (without a value): `return`, `return;`, `return if cond`, `cond or return`
    if ($ref eq 'Sidef::Types::Block::Return'
        and /\G(?=\h*(?:[;})\]#]|\R|\z|(?:if|unless|while|until|and|or)\b))/) {
        return {};
    }

    # Block constructs: if (...) {...}, while (...) {...}, for (...) {...}, etc.
    if ($ref =~ /^Sidef::Types::Block::(?:If|With|While|ForEach|For)\z/) {
        return (
                /\G(?=\()/
                ? $self->parse_arg(code => $opt{code})
                : $self->parse_obj(code => $opt{code}, prec => PREC_ASSIGN)
               );
    }

    # Function-style operators: say (...), print (...), defined (...), @(...), :(...)
    # The operator is applied only on the parenthesized expression, and any method call
    # that follows is applied on the result: `@(1..2).combinations(2)` is `(@(1..2)).combinations(2)`
    if (
        $ref eq 'Sidef::Meta::PrefixColon'
        or (
            $ref eq 'Sidef::Operator::Unary'
            and (   $method eq 'say'
                 or $method eq 'print'
                 or $method eq 'defined'
                 or $method eq '>'
                 or $method eq '>>'
                 or $method eq '+'
                 or $method eq '@'
                 or $method eq '@|')
           )
      ) {
        if (/\G(?=\()/) {
            return $self->parse_arg(code => $opt{code});
        }
    }

    # Prefix operators (! ~ \ + * √ ^ @ @|) are applied on the next operand: `!a == b` is `(!a) == b`
    my $prec = PREC_OPERAND;

    if ($ref eq 'Sidef::Operator::Unary') {
        if ($method eq '-') {    # `-a ** b` is `-(a ** b)`
            $prec = PREC_POW;
        }
        elsif ($method eq 'defined') {    # named unary operator: `defined a + 1` is `defined(a + 1)`
            $prec = PREC_SHIFT;
        }
        elsif ($method eq 'say' or $method eq 'print' or $method eq '>' or $method eq '>>') {    # list operators
            $prec = PREC_ASSIGN;
        }
        elsif ($method eq '@' or $method eq '@|') {
            $prec = PREC_RANGE;
        }
    }
    elsif ($ref eq 'Sidef::Variable::Ref' or $ref eq 'Sidef::Meta::PrefixColon') {
        $prec = PREC_OPERAND;
    }
    else {    # return, read, goto
        $prec = PREC_ASSIGN;
    }

    return $self->parse_obj(code => $opt{code}, prec => $prec);
}

# Parses the argument of a prefix operator or of a control-flow keyword.
# Returns true when the result is a new operand (a call of a prefix operator).
sub _parse_prefix_expression {
    my ($self, $obj, $method, $struct, %opt) = @_;

    local *_ = $opt{code};

    my $arg = $self->_parse_prefix_arg(code => $opt{code}, obj => $obj, method => $method);

    defined($arg)
      || $self->fatal_error(
                            code  => $_,
                            error => "expected an argument. Did you mean '$method()' instead?",
                            pos   => pos($_) - 1,
                           );

    my $ref = ref($obj);

    if ($ref eq 'Sidef::Types::Block::For') {
        $self->_parse_for_statement($obj, $arg, code => $opt{code});
    }
    elsif ($ref eq 'Sidef::Types::Block::ForEach') {
        $obj->{block} = $self->_parse_control_block(
                                                    "invalid declaration of the `foreach` loop",
                                                    "expected a block after `foreach(...)`",
                                                    code       => $opt{code},
                                                    block_opts => {topic_var => 1},
                                                   );
        $obj->{expr} = $arg;
    }
    elsif ($ref eq 'Sidef::Types::Block::If') {

        # `unless (cond) {...}` is the same as `if (!cond) {...}`
        $arg = $self->_negate($arg) if $method eq 'unless';

        $self->_parse_conditional_statement(
                                            $obj, $arg,
                                            code       => $opt{code},
                                            name       => 'if',
                                            list       => 'if',
                                            next_re    => qr/\G(?:elsif|else\h+if)\h*(?=\()/,
                                            next_name  => 'elsif',
                                            block_opts => {with_vars => 1},
                                           );
    }
    elsif ($ref eq 'Sidef::Types::Block::With') {
        $self->_parse_conditional_statement(
                                            $obj, $arg,
                                            code       => $opt{code},
                                            name       => 'with',
                                            list       => 'with',
                                            next_re    => qr/\Gorwith\h*(?=\()/,
                                            next_name  => 'orwith',
                                            block_opts => {topic_var => 1},
                                           );
    }
    elsif ($ref eq 'Sidef::Types::Block::While') {

        # `until (cond) {...}` is the same as `while (!cond) {...}`
        $arg = $self->_negate($arg) if $method eq 'until';

        $obj->{block} = $self->_parse_control_block(
                                                    "invalid declaration of the `while` statement",
                                                    "expected a block after `while(...)`",
                                                    code       => $opt{code},
                                                    block_opts => {with_vars => 1},
                                                   );
        $obj->{expr} = $arg;
    }
    else {
        push @{$struct->{$self->{class}}[-1]{call}}, {method => $method, arg => [$arg]};
        return 1;    # the result of a prefix operator is a new operand
    }

    return 0;
}

# Parses a `for` loop with variables: for var in array {...}
sub _parse_for_in_loop {
    my ($self, $obj, $for_paren, %opt) = @_;

    local *_ = $opt{code};

    my $class_name = $self->{class};

    my @loops;
    {
        my @vars;
        while (/\G([*:])?($self->{var_name_re})/gc) {

            my $type = $1;
            my $name = $2;
            push @vars,
              bless(
                    {
                     name  => $name,
                     type  => 'var',
                     class => $class_name,
                     (
                      $type
                      ? (
                         slurpy => 1,
                         ($type eq '*' ? (array => 1) : (hash => 1)),
                        )
                      : ()
                     ),
                    },
                    'Sidef::Variable::Variable'
                   );

            $self->_unshift_var(
                                $class_name,
                                {
                                 obj   => $vars[-1],
                                 name  => $name,
                                 count => 1,
                                 type  => 'var',
                                 line  => $self->{line},
                                }
                               );

            $type && last;
            /\G\h*,\h*/gc || last;
        }

        /\G\h*(?:in|∈|=|)\h*/gc
          || $self->fatal_error(
                                error => "expected the token <<in>> after variable declaration in for-loop",
                                code  => $_,
                                pos   => pos($_),
                               );

        my $expr = $self->_parse_arg_or_obj(code => $opt{code});

        push @loops,
          {
            vars => \@vars,
            expr => $expr,
          };

        /\G\h*,\h*/gc && redo;
    }

    if ($for_paren) {
        $self->parse_whitespace(code => $opt{code});
        /\G\)/gc
          || $self->fatal_error(
                                error => "unbalanced parenthesis in the `for` loop",
                                code  => $_,
                                pos   => pos($_),
                               );
    }

    my $block = (
                 /\G\h*(?=\{)/gc
                 ? $self->parse_block(code => $opt{code})
                 : $self->fatal_error(
                                      error  => "invalid declaration of the `for` loop",
                                      reason => "expected a block after the loop expression: for x in expr { ... }",
                                      code   => $_,
                                      pos    => pos($_),
                                     )
                );

    # Remove the for-loop variables from the outer scope
#<<<
    my %loop_vars = map {
        map { refaddr($_) => 1 } @{$_->{vars}}
    } @loops;

    @{$self->{vars}{$class_name}} = grep {
           ref($_) ne 'HASH'
        or not exists $loop_vars{refaddr($_->{obj})}
    } @{$self->{vars}{$class_name}};
#>>>

    # Store the info
    $obj->{block} = $block;
    $obj->{loops} = \@loops;

    # Re-bless the $obj into a different class
    bless $obj, 'Sidef::Types::Block::ForIn';

    return;
}

# Parses the rest of a `for` loop: `for(;;) {...}` or `for(...) {...}`
sub _parse_for_statement {
    my ($self, $obj, $arg, %opt) = @_;

    local *_ = $opt{code};

    my $class = $self->{class};

    # for(init; condition; step) {...}
    if ($#{$arg->{$class}} == 2) {

        my @arg = map {
            { $class => [$_] }
        } @{$arg->{$class}};

        $obj->{block} = $self->_parse_control_block("invalid declaration of the `for` loop", "expected a block after `for(;;)`", code => $opt{code},);
        $obj->{expr}  = \@arg;

        bless $obj, 'Sidef::Types::Block::CFor';
    }

    # for(array) {...}
    elsif ($#{$arg->{$class}} == 0) {

        $obj->{block} = $self->_parse_control_block(
                                                    "invalid declaration of the `for` loop",
                                                    "expected a block after `for(...)`",
                                                    code       => $opt{code},
                                                    block_opts => {topic_var => 1},
                                                   );
        $obj->{expr} = $arg;

        bless $obj, 'Sidef::Types::Block::ForEach';
    }

    else {
        $self->fatal_error(
                           code  => $_,
                           pos   => pos($_) - 1,
                           error => "invalid declaration of the `for` loop: incorrect number of arguments",
                          );
    }

    return;
}

# Parses the blocks of an `if` (`elsif`, `else`) or a `with` (`orwith`, `else`) statement
sub _parse_conditional_statement {
    my ($self, $obj, $arg, %opt) = @_;

    local *_ = $opt{code};

    my ($name, $list, $next_name) = @opt{qw(name list next_name)};

    my $block = $self->_parse_control_block(
                                            "invalid declaration of the `$name` statement",
                                            "expected a block after `$name(...)`",
                                            code       => $opt{code},
                                            block_opts => $opt{block_opts},
                                           );

    push @{$obj->{$list}}, {expr => $arg, block => $block};

    # elsif(...) {...} / orwith(...) {...}
    while (1) {

        $self->parse_whitespace(code => $opt{code});

        /$opt{next_re}/gc || last;

        my $next_arg = $self->parse_arg(code => $opt{code});
        $self->parse_whitespace(code => $opt{code});

        my $next_block = $self->parse_block(code => $opt{code}, %{$opt{block_opts}}) // $self->fatal_error(
                                                                                                        code  => $_,
                                                                                                        pos   => pos($_) - 1,
                                                                                                        error => "invalid declaration of the `$name` statement",
                                                                                                        reason => "expected a block after `$next_name(...)`",
        );

        push @{$obj->{$list}}, {expr => $next_arg, block => $next_block};
    }

    # else {...}
    if (/\Gelse\h*(?=\{)/gc) {
        $obj->{else}{block} = $self->parse_block(code => $opt{code});
    }

    $self->backtrack_whitespace(code => $opt{code});

    return;
}

# Parses a block that follows the condition of a control-flow statement
sub _parse_control_block {
    my ($self, $error, $reason, %opt) = @_;

    local *_ = $opt{code};

    /\G\h*(?=\{)/gc
      || $self->fatal_error(
                            code   => $_,
                            pos    => pos($_) - 1,
                            error  => $error,
                            reason => $reason,
                           );

    return $self->parse_block(code => $opt{code}, %{$opt{block_opts} // {}});
}

# Parses the calls, the indices and the postfix operators that follow an operand
sub _parse_postfix {
    my ($self, $struct, $obj, %opt) = @_;

    local *_ = $opt{code};

    {
        # Method call
        if (/\G\h*(?=\.\s*(?:$self->{method_name_re}|[(\$]))/ogc) {
            my $methods = $self->parse_methods(code => $opt{code});
            push @{$struct->{$self->{class}}[-1]{call}}, @{$methods};
            redo;
        }

        # Method call on the next line (leading dot):
        #
        #   obj
        #     .method1
        #     .method2(...)
        #
        # A leading dot at the beginning of a statement is the implicit method
        # call on the special variable `_`. When this variable doesn't exist,
        # the dot continues the expression from the previous line.
        # if (/\G(?=(?:[ \t]*(?:#[^\r\n]*)?\R)+\s*\.(?![.0-9]))/
        #    and not defined($self->find_var('_', $self->{class}))) {
        #    $self->parse_whitespace(code => $opt{code});
        #    redo;
        # }

        # Operators used with the method-call syntax: `a .+ b`, or `a \.` followed by
        # the operator on the next line. The operator binds tighter than any other operator.
        if (/\G\h*(?:\\(?!\\)\s*)?(?=\.(?!\.)\s*(?:$self->{operators_re}))/ogc) {
            my $methods = $self->parse_methods(code => $opt{code});
            push @{$struct->{$self->{class}}[-1]{call}}, @{$methods};
            redo;
        }

        # Code extended on a newline
        if (/\G\h*\\(?!\\)/gc) {
            $self->parse_whitespace(code => $opt{code});
            redo;
        }

        # Object call
        if (/\G\h*(?=\()/gc) {
            my $arg = $self->parse_arg(code => $opt{code});

            push @{$struct->{$self->{class}}[-1]{call}},
              {
                method => 'call',
                (%{$arg} ? (arg => [$arg]) : ())
              };

            redo;
        }

        # Do-while construct
        if (ref($obj) eq 'Sidef::Types::Block::Do' and /\G\h*(while|until)\b/gc) {
            my $kind = $1;
            my $arg  = $self->parse_obj(code => $opt{code});
            $arg = $self->_negate($arg) if $kind eq 'until';
            push @{$struct->{$self->{class}}[-1]{call}}, {keyword => 'while', arg => [$arg]};
        }

        # Parse array and hash fetchers ([...] and {...})
        if (/\G\.\h*(?=[\[\{])/gc or 1) {
            $self->parse_suffixes(code => $opt{code}, struct => $struct) && redo;
        }

        # Postfix operators (e.g.: x++, x--, n!, n!!, x...)
        if (defined(my $token = $self->_peek_operator(code => $opt{code}, postfix_only => 1))) {
            $self->append_method(
                                 array   => \@{$struct->{$self->{class}}[-1]{call}},
                                 method  => $token->{method},
                                 op_type => $token->{op_type},
                                );
            redo;
        }
    }

    return;
}

# Parses a chain of method calls (the first one can be preceded by an arrow): .name(...).name2
sub parse_methods {
    my ($self, %opt) = @_;

    my @methods;
    local *_ = $opt{code};
    my $orig_pos = pos($_);

    # After an arrow (`->`), the first method name is not preceded by a dot
    my $arrow = $opt{arrow};

    {

        # Parse escape character + whitespace
        /\G\h*\\(?!\\)/gc and $self->parse_whitespace(code => $opt{code});

        # Method calls introduced by a dot (e.g.: `.name`, `.name(...)`, `.+(...)`).
        # The infix operators are handled by parse_infix().
        if ($arrow ? ($arrow = 0, 1) : /\G\.(?!\.)/gc) {    # a single dot (`...` and `..` are operators)
            my ($method, $req_arg, $op_type) = $self->get_method_name(code => $opt{code});

            if (defined($method)) {

                my $has_arg;
                if (/\G\h*(?=[({])/gc || $req_arg) {
                    my $arg = (
                                 $req_arg   ? $self->parse_obj(code => $opt{code}, multiline => 1, prec => PREC_BITOR)
                               : /\G(?=\()/ ? $self->parse_arg(code => $opt{code})
                               : /\G(?=\{)/ ? $self->parse_block(code => $opt{code}, topic_var => 1)
                               :              die "[PARSER ERROR] Something is wrong in the if condition"
                              );

                    if (defined $arg) {
                        $has_arg = 1;
                        $self->append_method(
                                             array   => \@methods,
                                             method  => $method,
                                             arg     => $arg,
                                             op_type => $op_type,
                                            );
                    }
                    else {
                        $self->fatal_error(
                                           code  => $_,
                                           pos   => $orig_pos,
                                           error => "operator `$method` requires a right-side operand",
                                          );
                    }
                }

                $has_arg || do {
                    $self->append_method(
                                         array   => \@methods,
                                         method  => $method,
                                         op_type => $op_type,
                                        );
                };
                redo;
            }
        }
    }

    return \@methods;
}

# Parses the indices and the calls that follow an expression: [...], {...}, (...)
sub parse_suffixes {
    my ($self, %opt) = @_;

    my $struct = $opt{struct};
    local *_ = $opt{code};

    my $parsed = 0;

    if (/\G(?=[\{\[])/) {
#<<<
        $struct->{$self->{class}}[-1]{self} = {
                    $self->{class} => [
                        {
                         self => $struct->{$self->{class}}[-1]{self},
                         exists($struct->{$self->{class}}[-1]{call})
                            ? (call => delete $struct->{$self->{class}}[-1]{call})
                            : (),
                         exists($struct->{$self->{class}}[-1]{ind})
                            ? (ind => delete $struct->{$self->{class}}[-1]{ind})
                            : (),
                        }
                    ]
        };
#>>>
    }

    {
        if (/\G(?=\{)/) {
            while (/\G(?=\{)/) {
                my $lookup = $self->parse_lookup(code => $opt{code});
                push @{$struct->{$self->{class}}[-1]{ind}}, {hash => $lookup->{$self->{class}}};
            }

            $parsed ||= 1;
            redo;
        }

        if (/\G(?=\[)/) {
            while (/\G(?=\[)/) {
                my ($ind) = $self->parse_expr(code => $opt{code});
                push @{$struct->{$self->{class}}[-1]{ind}}, {array => $ind};
            }

            $parsed ||= 1;
            redo;
        }

        if (/\G\h*(?=\()/gc) {
#<<<
            $struct->{$self->{class}}[-1]{self} = {
                    $self->{class} => [
                        {
                         self => $struct->{$self->{class}}[-1]{self},
                         exists($struct->{$self->{class}}[-1]{call})
                            ? (call => delete $struct->{$self->{class}}[-1]{call})
                            : (),
                         exists($struct->{$self->{class}}[-1]{ind})
                            ? (ind => delete $struct->{$self->{class}}[-1]{ind})
                            : (),
                        }
                    ]
            };
#>>>

            my $arg = $self->parse_arg(code => $opt{code});

            push @{$struct->{$self->{class}}[-1]{call}},
              {
                method => 'call',
                (%{$arg} ? (arg => [$arg]) : ())
              };

            redo;
        }
    }

    $parsed;
}

# Appends a method (or an operator) with its optional argument, to a list of calls.
sub append_method {
    my ($self, %opt) = @_;

    # Hyper-operator
    if (exists $self->{hyper_ops}{$opt{op_type}}) {
        push @{$opt{array}},
          {
            method => $self->{hyper_ops}{$opt{op_type}}[1],
            arg    => [$opt{method}],
          };
    }

    # Basic operator/method
    else {
        push @{$opt{array}}, {method => $opt{method}};
    }

    # Append the argument (if any)
    if (exists($opt{arg}) and (%{$opt{arg}} || ($opt{method} =~ /^$self->{operators_re}\z/))) {
        push @{$opt{array}[-1]{arg}}, $opt{arg};
    }
}

## get_method_name() returns the following values:
# 1st: method/operator (or undef)
# 2nd: a true value if the operator requires an argument
# 3rd: type of operator (defined in $self->{hyper_ops})
sub get_method_name {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    # Parse whitespace
    $self->parse_whitespace(code => $opt{code});

    # Alpha-numeric method name
    if (/\G((?:SUPER::)*$self->{method_name_re})/goc) {
        return ($1, 0, '');
    }

    # Super-script power
    if (/\G(?=[⁰¹²³⁴⁵⁶⁷⁸⁹])/) {
        return ('**', 1, 'op');
    }

    # Operator-like method name
    if (m{\G$self->{operators_re}}goc) {
        my ($key) = keys(%+);
        return (
                $+,
                (
                 exists($self->{hyper_ops}{$key})
                 ? $self->{hyper_ops}{$key}[0]
                 : not(exists $self->{postfix_ops}{$+})
                ),
                $key
               );
    }

    # Method name as expression
    my ($obj) = $self->parse_expr(code => $opt{code});
    return ({self => $obj // return}, 0, '');
}

# Parses an expression, using the operator precedence rules.
#
# The `prec` option sets the minimum precedence of the operators that are consumed.
# By default, a full expression is parsed (everything that binds tighter than
# a comma). The statement-level expressions (see parse_script) also consume the
# pair constructors and the keyword operators (if, while, and, or).
# Parses a parenthesized list of arguments `(...)`, or any other expression
sub _parse_arg_or_obj {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    return (/\G(?=\()/ ? $self->parse_arg(code => $opt{code}) : $self->parse_obj(code => $opt{code}));
}

# Returns the logical negation of an expression: `!(expr)`
sub _negate {
    my ($self, $expr) = @_;
    scalar {
            $self->{class} => [
                               {
                                self => bless({}, 'Sidef::Operator::Unary'),
                                call => [{method => '!', arg => [$expr]}],
                               }
                              ]
           };
}

# ---------------------------------------------------------------------------
# Operators: precedence climbing
# ---------------------------------------------------------------------------

sub parse_obj {
    my ($self, %opt) = @_;

    my ($struct, $wrap) = $self->parse_operand(%opt);

    defined($struct) || return;

    return
      $self->parse_infix(
                         code   => $opt{code},
                         struct => $struct,
                         wrap   => $wrap,
                         prec   => $opt{prec} // PREC_ASSIGN,
                        );
}

# Parses the infix operators that follow an operand, using precedence climbing.
#
#   struct => the operand (as returned by parse_operand)
#   wrap   => true when the operand is a prefix-operator expression
#   prec   => the minimum precedence of the operators that are consumed
#
# The operators of the same precedence are chained, from left to right, in the
# list of calls of the left-hand side:  a + b - c  =>  {self => a, call => [+b, -c]}
# while the right-hand sides are parsed recursively:  a + b * c  =>  {self => a, call => [+(b*c)]}
sub parse_infix {
    my ($self, %opt) = @_;

    my $struct   = $opt{struct};
    my $wrap     = $opt{wrap};
    my $min_prec = $opt{prec} // PREC_ASSIGN;

    local *_ = $opt{code};

    return $struct if $min_prec >= PREC_OPERAND;

    # A pending chain of comparisons: `a < b < c`
    my $chain;

    while (1) {

        # Fast exit: the end of an expression
        if (/\G\h*(?:[;,)\]}]|\z)/) {
            last;
        }

        # Arrow method call: `expr -> method(...)`
        # It has the lowest precedence and it is applied on the whole expression
        # from its left (e.g.: `^10 -> map {...}` is the same as `(^10).map {...}`).
        if ($min_prec <= PREC_ARROW and /\G\h*(?:\\(?!\\)\s*)?->\h*/gc) {
            $self->_flush_chain(\$struct, \$chain) if defined $chain;
            $struct = $self->_parse_arrow_call(($wrap ? $self->_wrap_operand($struct) : $struct), code => $opt{code});
            $wrap   = 0;
            next;
        }

        # Ternary operator (the `?` is allowed to be on the next line)
        if ($min_prec <= PREC_TERNARY and /\G(?=\s*\?)/) {
            $self->_flush_chain(\$struct, \$chain) if defined $chain;
            $struct = $self->_parse_ternary($struct, code => $opt{code});
            $wrap   = 0;
            next;
        }

        my $token = $self->_peek_operator(code => $opt{code}) // last;

        # Keyword operators: if, unless, while, until, and, or
        if ($token->{kind} eq 'keyword') {

            my $name = $token->{name};
            my $prec = $KEYWORD_PREC{$name};

            if ($prec < $min_prec) {
                pos($_) = $token->{start};
                last;
            }

            $self->_flush_chain(\$struct, \$chain) if defined $chain;

            my $arg = $self->parse_obj(code => $opt{code}, prec => $prec + 1);

            $arg // $self->fatal_error(
                                       code  => $_,
                                       pos   => $token->{start},
                                       error => "keyword `$name` requires a right-side expression",
                                      );

            if ($wrap) {
                $struct = $self->_wrap_operand($struct);
                $wrap   = 0;
            }

            # `unless` and `until` are the negated forms of `if` and `while`
            if ($name eq 'unless' or $name eq 'until') {
                $arg  = $self->_negate($arg);
                $name = ($name eq 'unless' ? 'if' : 'while');
            }

            push @{$struct->{$self->{class}}[-1]{call}}, {keyword => $name, arg => [$arg]};
            next;
        }

        # Infix and postfix operators
        my ($method, $req_arg, $op_type) = @{$token}{qw(method req_arg op_type)};

        # Hyper-operator with an empty argument list (e.g.: `x »name»()`): it is a postfix operator
        if ($req_arg and $op_type ne 'op' and /\G\h*\(\h*\)/gc) {
            $req_arg = 0;
        }

        # Postfix operator, applied on the whole left-hand side
        if (not $req_arg) {

            # Postfix operators that are not attached to the operand apply on the entire expression
            if ($min_prec > PREC_ARROW) {
                pos($_) = $token->{start};
                last;
            }

            $self->_flush_chain(\$struct, \$chain) if defined $chain;

            $self->append_method(
                                 array   => \@{$struct->{$self->{class}}[-1]{call}},
                                 method  => $method,
                                 op_type => $op_type,
                                );
            next;
        }

        my ($prec, $assoc) = $self->_infix_info($token);

        if ($prec < $min_prec) {
            pos($_) = $token->{start};
            last;
        }

        my $arg = $self->parse_obj(
                                   code      => $opt{code},
                                   multiline => 1,
                                   prec      => ($assoc eq 'R' ? $prec : $prec + 1),
                                  );

        $arg // $self->fatal_error(
                                   code  => $_,
                                   pos   => $token->{start},
                                   error => "operator `$method` requires a right-side operand",
                                  );

        # The result of a prefix operator is a new operand
        if ($wrap) {
            $struct = $self->_wrap_operand($struct);
            $wrap   = 0;
        }

        # Comparison operators that can be chained: `a < b < c`
        my $chain_class = ($op_type eq 'op' ? $CHAIN_CLASS{$method} : undef);

        if (defined $chain_class) {

            if (defined($chain) and $chain->{class} eq $chain_class) {
                push @{$chain->{ops}},      $method;
                push @{$chain->{operands}}, $arg;
            }
            else {
                $self->_flush_chain(\$struct, \$chain) if defined $chain;
                $chain = {
                          class    => $chain_class,
                          operands => [$struct, $arg],
                          ops      => [$method],
                         };
            }

            next;
        }

        $self->_flush_chain(\$struct, \$chain) if defined $chain;

        $self->append_method(
                             array   => \@{$struct->{$self->{class}}[-1]{call}},
                             method  => $method,
                             arg     => $arg,
                             op_type => $op_type,
                            );
    }

    $self->_flush_chain(\$struct, \$chain) if defined $chain;

    return $struct;
}

# Makes an expression the operand of another expression
sub _wrap_operand {
    my ($self, $struct) = @_;
    return {$self->{class} => [{self => $struct}]};
}

# Looks ahead (on the current line) for an infix operator, a postfix operator,
# or one of the keyword operators (`if`, `while`, `and`, `or`).
#
# When something is found, the position is left right after the token and
# a hash-ref describing it is returned. Otherwise, the position is restored
# and nothing is returned.
#
# The `start` field is the position where the token was found (after any whitespace),
# which can be used for putting the token back: `pos($_) = $token->{start}`.
sub _peek_operator {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $start = pos($_) // 0;
    my $tight = 1;              # true when there is no whitespace before the operator

    if ($opt{postfix_only}) {

        # The postfix operators that bind to the operand must be attached to it
        # (e.g.: `n!`, `x++`, `list...`) and they start with one of: - + . ! » « < >
        /\G(?=[-+.!»«<>])/ or return;
    }
    else {

        # Fast exit: the end of an expression
        /\G\h*(?:[;,)\]}\r\n]|\z)/ and return;

        while (1) {

            # Horizontal whitespace, zero width spaces and inline C comments
            if (/\G(?:\h+|\x{200B}+|\/\*(?:(?!\*\/)[^\n\r])*+\*\/)/gc) {
                $tight = 0;
                next;
            }

            # Code extended on a newline (the backslash is consumed for good)
            if (/\G\\(?!\\)/gc) {
                $self->parse_whitespace(code => $opt{code});
                $start = pos($_);
                $tight = 0;
                next;
            }

            last;
        }

        # Fast exit: the end of an expression, or a token that can't be an operator
        if (/\G(?:[;,)\]}\n\r]|\z)/ or (/\G(?=[\w"'\$\[{(])/ and !/\G(?:if|unless|while|until|and|or)\b/)) {
            pos($_) = $start;
            return;
        }

        # Keyword operators
        if (/\G(if|unless|while|until|and|or)\b/gc) {
            return {kind => 'keyword', name => $1, start => $start, tight => $tight};
        }

        # Super-script power (e.g.: x²), only when attached to the operand
        if ($tight and /\G(?=[⁰¹²³⁴⁵⁶⁷⁸⁹])/) {
            return {kind => 'op', method => '**', req_arg => 1, op_type => 'op', start => $start, tight => 1};
        }
    }

    # The operators start with one of these characters (the full regex is expensive)
    if (
           /\G(?=[-|&^.%~!<=:>+\/÷*\\：«»`\x{2200}-\x{22FF}\x{2A00}-\x{2AFF}])/
        && /\G(?![=-]>)/    # not '=>' or '->'
        && (
            /\G(?=$self->{operators_re})/o                      # operator
            || /\G\.\h*(?!\.\.)(?=$self->{operators_re})/gco    # dot followed by operator
           )
      ) {

        my ($method, $req_arg, $op_type) = $self->get_method_name(code => $opt{code});

        if (
                defined($method)
            and not ref($method)
            and not($method eq '|'      and $self->{no_pipe_op})    # `|` is the delimiter in `{|a, b| ...}`
            and not($self->{no_pair_op} and ($method eq ':' or $method eq '：' or $method eq '⫶')) and not($opt{postfix_only} and $req_arg)
          ) {
            return {
                    kind    => 'op',
                    method  => $method,
                    req_arg => $req_arg,
                    op_type => $op_type,
                    start   => $start,
                    tight   => $tight,
                   };
        }
    }

    pos($_) = $start;
    return;
}

# Returns the precedence and the associativity of an infix operator
sub _infix_info {
    my ($self, $token) = @_;
    return infix_precedence(@{$token}{qw(method op_type)});
}

# Returns (precedence, associativity) of an infix operator or method-like operator.
#
# This is a plain function (not a method), which is also used by Sidef::Deparse::Sidef,
# in order to generate code that uses the same precedence rules as the parser.
#
#   $method  the operator, as it appears in the AST (e.g.: '+', '..', 'add')
#   $op_type the type of the operator: 'op' (default) or the name of a hyper-operator
sub infix_precedence {
    my ($method, $op_type) = @_;

    $op_type //= 'op';

    # The hyper-operators (e.g.: »+», ~Z*, ~X+) have the same precedence as the pipe
    # operators (|>, |>>, |X>, |Z>) and the method-like operators (a `method` b).
    # They are chained from left to right, which allows writing pipelines such as:
    #   x |>> :cos ~Z* y |> :sum
    if ($op_type ne 'op') {
        return (PREC_WORD_OP, 'L');
    }

    my $info = $INFIX_PREC{$method};

    if (not defined $info) {
        if ($method =~ /^[^\W\d]/) {    # `method`-like operators
            $info = [PREC_WORD_OP, 'L'];
        }
        elsif ($method =~ /=\z/ and exists $INFIX_PREC{substr($method, 0, -1)}) {    # e.g.: ∪=
            $info = [PREC_ASSIGN, 'L'];
        }
        else {                                                                       # any other operator
            $info = [PREC_ADD, 'L'];
        }
    }

    return @{$info};
}

# Returns the precedence of a keyword operator: if, unless, while, until, and, or
sub keyword_precedence {
    my ($keyword) = @_;
    return $KEYWORD_PREC{$keyword};
}

# Returns true when the name is the name of a built-in class (String, Array, Number, etc.)
sub is_built_in_class {
    my ($name) = @_;
    return exists $BUILT_IN_CLASSES{$name};
}

# Parses an arrow call (the arrow was consumed): `-> method(...)`
sub _parse_arrow_call {
    my ($self, $struct, %opt) = @_;

    local *_ = $opt{code};

    my $methods = $self->parse_methods(code => $opt{code}, arrow => 1);

    @{$methods}
      || $self->fatal_error(
                            error => 'incomplete method name',
                            code  => $_,
                            pos   => pos($_) - 1,
                           );

    push @{$struct->{$self->{class}}[-1]{call}}, @{$methods};

    # Calls and indices applied on the result: `x -> method(...)(...)`, `x -> method(...)[...]`
    $self->parse_suffixes(code => $opt{code}, struct => $struct);

    return $struct;
}

# Parses the ternary operator: `cond ? true : false`
sub _parse_ternary {
    my ($self, $cond, %opt) = @_;

    local *_ = $opt{code};

    $self->parse_whitespace(code => $opt{code});
    /\G\?/gc;
    $self->parse_whitespace(code => $opt{code});

    # The `:` that follows is the one from the ternary operator, not a pair constructor
    my $true = do {
        local $self->{no_pair_op} = 1;
        $self->parse_obj(code => $opt{code}, multiline => 1, prec => PREC_ASSIGN);
    };

    $true // $self->fatal_error(
                                code   => $_,
                                pos    => pos($_),
                                error  => "invalid usage of the ternary operator",
                                reason => "expected an expression after '?'",
                               );

    $self->parse_whitespace(code => $opt{code});

    /\G:/gc
      || $self->fatal_error(
                            code   => $_,
                            pos    => pos($_),
                            error  => "invalid usage of the ternary operator",
                            reason => "expected ':'",
                           );

    $self->parse_whitespace(code => $opt{code});

    my $false = $self->parse_obj(code => $opt{code}, multiline => 1, prec => PREC_TERNARY);

    $false // $self->fatal_error(
                                 code   => $_,
                                 pos    => pos($_),
                                 error  => "invalid usage of the ternary operator",
                                 reason => "expected an expression after ':'",
                                );

    my $node = bless(
                     {
                      cond  => $cond,
                      true  => $true,
                      false => $false,
                     },
                     'Sidef::Types::Bool::Ternary'
                    );

    return $self->_wrap_operand($node);
}

# Appends a pending chain of comparisons to the expression
sub _flush_chain {
    my ($self, $struct_ref, $chain_ref) = @_;

    my ($ops, $operands) = @{${$chain_ref}}{qw(ops operands)};
    undef ${$chain_ref};

    if (@{$ops} == 1) {
        $self->append_method(
                             array   => \@{${$struct_ref}->{$self->{class}}[-1]{call}},
                             method  => $ops->[0],
                             arg     => $operands->[1],
                             op_type => 'op',
                            );
    }
    else {
        ${$struct_ref} = $self->_build_comparison_chain($operands, $ops);
    }

    return;
}

# Builds the AST of a chain of comparisons: `a < b <= c < d`
#
#   => (a < b) && (b <= c) && (c < d)
#
# The middle operands that are not simple (e.g.: function calls) are stored in temporary
# variables, with the help of an anonymous block, to be evaluated only once:
#
#   a < f(x) < c   =>   {|t| a < t && t < c}.call(f(x))
sub _build_comparison_chain {
    my ($self, $operands, $ops) = @_;

    my $class = $self->{class};
    my ($left, $right) = @{$operands}[0, 1];
    my $method = $ops->[0];

    my $call = sub {
        my ($lhs, $name, $rhs) = @_;
        scalar {$class => [{self => $lhs, call => [{method => $name, arg => [$rhs]}]}]};
    };

    @{$ops} == 1 and return $call->($left, $method, $right);

    my @rest_operands = @{$operands}[2 .. $#{$operands}];
    my @rest_ops      = @{$ops}[1 .. $#{$ops}];

    # Simple middle operand: it can be repeated
    if ($self->_is_simple_operand($right)) {
        return $call->($call->($left, $method, $right), '&&', $self->_build_comparison_chain([$right, @rest_operands], \@rest_ops));
    }

    # Complex middle operand: bind it to a temporary variable
    state $counter = 0;

    my $new_var = sub {
        my $var = bless({name => '__cmp' . ++$counter, type => 'var', class => $class}, 'Sidef::Variable::Variable');
        return ($var, scalar {$class => [{self => $var}]});
    };

    my (@vars, @args);

    if (not $self->_is_simple_operand($left)) {    # keep the left-to-right evaluation order
        my ($var, $ref) = $new_var->();
        push @vars, $var;
        push @args, $left;
        $left = $ref;
    }

    my ($var, $ref) = $new_var->();
    push @vars, $var;
    push @args, $right;

    my $inner = $call->($call->($left, $method, $ref), '&&', $self->_build_comparison_chain([$ref, @rest_operands], \@rest_ops));

    my $block = bless(
                      {
                       init_vars => bless({vars => \@vars}, 'Sidef::Variable::Init'),
                       code      => {$class => [{self => $inner}]},
                      },
                      'Sidef::Types::Block::BlockInit'
                     );

    return
      scalar {
              $class => [
                         {
                          self => $block,
                          call => [{method => 'call', arg => [{$class => [map { @{$_->{$class}} } @args]}]}],
                         }
                        ]
             };
}

# Returns true when the expression is a plain variable or literal, which is
# safe to be used more than once (e.g.: the middle operand of `a < b < c`).
sub _is_simple_operand {
    my ($self, $struct) = @_;

    ref($struct) eq 'HASH' or return 0;
    exists($struct->{call}) and return 0;
    exists($struct->{ind})  and return 0;

    if (exists $struct->{self}) {
        my $obj = $struct->{self};
        return $self->_is_simple_operand($obj) if ref($obj) eq 'HASH';
        return 1 if ref($obj)                                                 =~ /^Sidef::Types::(?:Number::Number|String::String|Bool::Bool)\z/;
        return 1 if ref($obj) eq 'Sidef::Variable::Variable' and $obj->{type} =~ /^(?:var|global)\z/;
        return 0;
    }

    my @statements = map { ref($_) eq 'ARRAY' ? @{$_} : () } values %{$struct};
    @statements == 1 or return 0;
    return $self->_is_simple_operand($statements[0]);
}

# ---------------------------------------------------------------------------
# Statements
# ---------------------------------------------------------------------------

sub parse_script {
    my ($self, %opt) = @_;

    my %struct;
    local *_ = $opt{code};
  MAIN: {
        $self->parse_whitespace(code => $opt{code});

        if (/\G\@:([^\W\d]\w*+)/gc) {
            push @{$struct{$self->{class}}}, {self => bless({name => $1}, 'Sidef::Variable::Label')};
            redo;
        }

        if (/\G(?:[;,]+|=>)/gc) {
            redo;
        }

        # A statement is a full expression: everything is allowed here, including
        # the pair constructors, the keyword operators (if, while, and, or) and the arrow calls (->).
        my $start_pos = pos($_) // 0;
        my $obj       = $self->parse_obj(code => $opt{code}, prec => PREC_ARROW);

        if (defined $obj) {

            # A statement that doesn't consume any input would be parsed forever
            if ((pos($_) // 0) == $start_pos) {
                $self->fatal_error(
                                   code  => $_,
                                   pos   => $start_pos,
                                   error => (substr($_, $start_pos, 1) eq '.' ? 'incomplete method name' : 'unexpected token'),
                                  );
            }

            push @{$struct{$self->{class}}}, {self => $obj};
            redo;
        }

        if (/\G(?:[;,]+|=>)/gc) {
            redo;
        }

        # We are at the end of the script.
        # We make some checks, and return the \%struct hash ref.
        if (/\G\z/) {
            $self->check_declarations($self->{ref_vars});
            return \%struct;
        }

        # The end of an array `]`, of a block or a lookup `}`, or of an argument expression `)`
        if (/\G([\]})])/gc) {

            my ($counter, $kind, $opening) = @{$CLOSING_DELIMITERS{$1}};

            if (--$self->{$counter} < 0) {
                $self->fatal_error(
                                   error  => "unbalanced $kind",
                                   reason => "unexpected `$1`: there is no matching `$opening` before it",
                                   code   => $_,
                                   pos    => pos($_) - 1,
                                  );
            }

            return \%struct;
        }

        my ($token) = /\G(\S{1,12})/;

        $self->fatal_error(
                           code  => $_,
                           pos   => (pos($_)),
                           error => (defined($token) ? "unexpected token `$token`" : "unexpected end of input"),
                          );
    }
}

sub Sidef::Parser::DirectoryGuard::DESTROY { $_[0]->() }

1
