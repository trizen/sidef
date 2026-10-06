package Sidef::Parser;

use utf8;
use 5.016;

use Sidef::Types::Bool::Bool;
use List::Util   qw(first);
use Scalar::Util qw(refaddr);

# our $REGMARK;

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
                 [PREC_BITOR,      'L', '|',  '^',  '⊻'],
                 [PREC_RELATIONAL, 'L', '<',  '>',  '<=',  '>=', '≤',   '≥',   '∈', '∉', '∋', '∌', '⊂', '⊃', '⊄',  '⊅', '⊆', '⊇', '⊈', '⊉'],
                 [PREC_EQUALITY,   'L', '==', '!=', '<=>', '~~', '<~>', '=~=', '≅', '≠', '≡', '≢', '≈', '≉', '=~', '!~'],
                 [PREC_ANDAND,     'L', '&&', '∧'],
                 [PREC_OROR,       'L', '||', '\\\\', '∨'],
                 [PREC_PAIR,       'L', ':',  '：',    '⫶'],
                 [PREC_ASSIGN,     'R', '='],
                 [PREC_ASSIGN,     'L', ':=', '||=', '&&=', '//=', '\\\\=', '+=', '-=', '*=', '/=', '÷=', '%=', '**=', '^=', '|=', '&=', '<<=', '>>='],
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

# Precedence of the keyword operators
my %KEYWORD_PREC = (
                    'if'     => PREC_STMT,
                    'while'  => PREC_STMT,
                    'unless' => PREC_STMT,
                    'until'  => PREC_STMT,
                    'or'     => PREC_OR,
                    'and'    => PREC_AND,
                   );

sub new {
    my (undef, %opts) = @_;

    my %options = (
        line          => 1,
        inc           => [],
        class         => 'main',    # a.k.a. namespace
        vars          => {'main' => []},
        ref_vars_refs => {'main' => []},
        EOT           => [],

        postfix_ops => {            # postfix operators
           '--'  => 1,
           '++'  => 1,
           '...' => 1,
           '!'   => 1,
           '!!'  => 1,
                       },

        hyper_ops => {

            # type => [takes args, method name]
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
                     },

        static_obj_re => qr{\G
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
        }x,
        prefix_obj_re => qr{\G
          (?:
              if\b                                       (?{ bless({}, 'Sidef::Types::Block::If') })
            | with\b                                     (?{ bless({}, 'Sidef::Types::Block::With') })
            | while\b                                    (?{ bless({}, 'Sidef::Types::Block::While') })
            | unless\b                                   (?{ bless({}, 'Sidef::Types::Block::If') })
            | until\b                                    (?{ bless({}, 'Sidef::Types::Block::While') })
            | foreach\b                                  (?{ bless({}, 'Sidef::Types::Block::ForEach') })
            | for\b                                      (?{ bless({}, 'Sidef::Types::Block::For') })
            | return\b                                   (?{ state $x = bless({}, 'Sidef::Types::Block::Return') })
            #| next\b                                     (?{ bless({}, 'Sidef::Types::Block::Next') })
            #| break\b                                    (?{ bless({}, 'Sidef::Types::Block::Break') })
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
        }x,
        quote_operators_re => qr{\G
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
        }xs,
        built_in_classes => {
            map { $_ => 1 }
              qw(
              File
              FileHandle
              Dir
              DirHandle
              Arr Array
              Pair
              Vec Vector
              Matrix
              Enumerator
              Hash
              Set
              Bag
              Str String
              Num Number
              Poly Polynomial
              PolyMod PolynomialMod
              Frac Fraction
              Mod
              Gauss
              Quadratic
              Quaternion
              Range
              RangeStr RangeString
              RangeNum RangeNumber
              Complex
              Math
              Pipe
              Ref
              Socket
              SocketHandle
              Bool
              Sys
              Sig
              Regex Regexp
              Time
              Date
              Perl
              Sidef
              Object
              Parser
              Block
              Backtick
              Lazy
              LazyMethod
              NamedParam

              true false
              nil null
              )
        },
        keywords => {
            map { $_ => 1 }
              qw(
              next
              break
              return
              for foreach
              if elsif else unless until not
              with orwith
              while
              given
              with
              continue
              import
              include
              eval
              read
              die
              warn

              assert
              assert_eq
              assert_ne

              local
              global
              var
              del
              const
              func
              enum
              class
              static
              define
              struct
              subset
              module

              DATA
              ARGV
              ARGF
              ENV

              STDIN
              STDOUT
              STDERR

              __FILE__
              __LINE__
              __END__
              __DATA__
              __TIME__
              __DATE__
              __NAMESPACE__
              __COMPILED__
              __OPTIMIZED__
              )
        },
        match_flags_re  => qr{[msixpogcaludn]+},
        var_name_re     => qr/[^\W\d]\w*+(?>::[^\W\d]\w*)*/,
        method_name_re  => qr/[^\W\d]\w*+!?/,
        var_init_sep_re => qr/\G\h*(?:=>|[=:])\h*/,
        operators_re    => do {
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
        },

        # Reference: https://en.wikipedia.org/wiki/International_variation_in_quotation_marks
        delim_pairs => {
            qw~
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
              ~
        },
        %opts,
    );

    # Words that have a special meaning in parse_expr(). Any other plain identifier
    # is a variable, which allows skipping all the other checks (see `parse_expr`).
    $options{special_words} //= {
        map { $_ => 1 } (
            keys(%{$options{keywords}}),
            keys(%{$options{built_in_classes}}),
            qw(
              say print defined goto unless until not do loop try catch gather take
              when case default has method eval Parser Inf NaN Infi NaNi
              Arr Array Vec Vector Str String Num Number Poly Polynomial
              PolyMod PolynomialMod Frac Fraction Regex Regexp
              RangeNum RangeNumber RangeStr RangeString
              )
        )
    };

    $options{ref_vars} = $options{vars};
    $options{file_name}   //= '-';
    $options{script_name} //= '-';

    bless \%options, __PACKAGE__;
}

sub fatal_error {
    my ($self, %opt) = @_;

    my $start  = rindex($opt{code}, "\n", $opt{pos}) + 1;
    my $point  = $opt{pos} - $start;
    my $line   = $opt{line} // $self->{line};
    my $column = $point;

    my $error_line = (split(/\R/, substr($opt{code}, $start, $point + 80)))[0] // '';

    if (length($error_line) > 80 && $point > 60) {
        my $from = $point - 40;
        my $rem  = $point + 40 - length($error_line);

        $from -= $rem;
        $point = 40 + $rem;

        $error_line = substr($error_line, $from, 80);
    }

    my @lines = (

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

    my $error = sprintf("%s\n\nFile : %s\nLine : %s : %s\nError: %s\n\n" . ("~" x 80) . "\n%s\n",
                        $lines[rand @lines],
                        $self->{file_name} // '-',
                        $line, $column, join(', ', grep { defined } $opt{error}, $opt{reason}), $error_line);

    $error .= ' ' x ($point) . '^' . "\n" . ('~' x 80) . "\n";

    if (exists($opt{var})) {

        my ($name, $class) = $self->get_name_and_class($opt{var});

        my %seen;
        my @names;
        foreach my $var (@{$self->{vars}{$class}}) {
            next if ref $var eq 'ARRAY';
            if (!$seen{$var->{name}}++) {
                push @names, $var->{name};
            }
        }

        foreach my $var (@{$self->{ref_vars_refs}{$class}}) {
            next if ref $var eq 'ARRAY';
            if (!$seen{$var->{name}}++) {
                push @names, $var->{name};
            }
        }

        if ($class eq 'main') {
            $class = '';
        }
        else {
            $class .= '::';
        }

        if (my @candidates = Sidef::best_matches($name, [grep { $_ ne $name } @names])) {
            $error .= ("[?] Did you mean: " . join("\n" . (' ' x 18), map { $class . $_ } sort(@candidates)) . "\n");
        }
    }

    die $error;
}

sub find_var {
    my ($self, $var_name, $class) = @_;

    foreach my $var (@{$self->{vars}{$class}}) {
        next if ref $var eq 'ARRAY';
        if ($var->{name} eq $var_name) {
            return (wantarray ? ($var, 1) : $var);
        }
    }

    foreach my $var (@{$self->{ref_vars_refs}{$class}}) {
        next if ref $var eq 'ARRAY';
        if ($var->{name} eq $var_name) {
            return (wantarray ? ($var, 0) : $var);
        }
    }

    return;
}

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

sub get_name_and_class {
    my ($self, $var_name) = @_;

    $var_name // return ('', $self->{class});

    my $rindex = rindex($var_name, '::');
    $rindex != -1
      ? (substr($var_name, $rindex + 2), substr($var_name, 0, $rindex))
      : ($var_name, $self->{class});
}

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
        $self->fatal_error(
                           error => qq{can't find the beginning of a string quote delimiter},
                           code  => $_,
                           pos   => pos($_),
                          );
    }

    my $orig_pos   = pos($_);
    my $beg_delim  = quotemeta $delim;
    my $pair_delim = exists($self->{delim_pairs}{$delim}) ? $self->{delim_pairs}{$delim} : ();

    my $string = '';
    if (defined $pair_delim) {

        my $end_delim = quotemeta $pair_delim;
        my $re_delim  = $beg_delim . $end_delim;

        # if (m{\G(?<main>$beg_delim((?>[^$re_delim\\]+|\\.|(?&main))*+)$end_delim)}sgc) {
        # if (m{\G(?<main>$beg_delim((?>[^\\$re_delim]*+(?>\\.[^\\$re_delim]*|(?&main)){0,}){0,})(?:$end_delim(*ACCEPT:term))?)(*PRUNE)(*FAIL)}sgc) {

        if (m{\G(?<main>$beg_delim((?>[^\\$re_delim]*+(?>\\.[^\\$re_delim]*|(?&main)){0,}){0,})$end_delim)}sgc) {
            $string = $2 =~ s/\\([$re_delim])/$1/gr;
        }
    }

    # elsif (m{\G$beg_delim([^\\$beg_delim]*+(?>\\.[^\\$beg_delim]*)*)}sgc) {    # limited to 2^15-1 escapes
    # elsif (m{\G$beg_delim((?>(?>[^$beg_delim\\]++|\\.){0,}+){0,}+)}sgc) {
    # elsif (m{\G$beg_delim((?>[^\\$beg_delim]*+(?>\\.[^\\$beg_delim]*){0,}){0,})(?:$beg_delim(*ACCEPT:term))?(*PRUNE)(*FAIL)}sgc) {

    elsif (m{\G$beg_delim((?>[^\\$beg_delim]*+(?>\\.[^\\$beg_delim]*){0,}){0,})}sgc) {
        $string = $1 =~ s/\\([$beg_delim])/$1/gr;
    }

    # $REGMARK eq 'term'
    (defined($pair_delim) ? /\G(?<=\Q$pair_delim\E)/ : /\G$beg_delim/gc)
      || $self->fatal_error(
                            error => sprintf(qq{can't find the quoted string terminator <<%s>>}, $pair_delim // $delim),
                            code  => $_,
                            pos   => $orig_pos,
                           );

    $self->{line} += $string =~ s/\R\K//g if not $opt{no_count_line};
    return $string;
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

sub get_init_vars {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $end_delim = $self->parse_delim(%opt);

    my @vars;
    my %classes;

    while (   /\G(?<type>$self->{var_name_re}\h+$self->{var_name_re})\h*/goc
           || /\G([*:]?$self->{var_name_re})\h*/goc
           || (defined($end_delim) && /\G(?=[({])/)) {

        my $declaration = $1;

        if ($opt{with_vals} && defined($end_delim)) {

            # Add the variable into the symbol table
            if (defined $declaration) {

                my ($name, $class_name) = $self->get_name_and_class((split(' ', $declaration))[-1]);

                undef $classes{$class_name};
                unshift @{$self->{vars}{$class_name}},
                  {
                    obj   => '',
                    name  => $name,
                    count => 0,
                    type  => $opt{type},
                    line  => $self->{line},
                  };
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

    # Remove the newly added variables
    foreach my $class_name (keys %classes) {
        for (my $i = 0 ; $i <= $#{$self->{vars}{$class_name}} ; $i++) {
            if (ref($self->{vars}{$class_name}[$i]) eq 'HASH' and not ref($self->{vars}{$class_name}[$i]{obj})) {
                splice(@{$self->{vars}{$class_name}}, $i--, 1);
            }
        }
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

sub parse_init_vars {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    my $end_delim = $self->parse_delim(%opt);

    my @var_objs;
    while (   /\G(?<type>$self->{var_name_re})\h+($self->{var_name_re})\h*/goc
           || /\G([*:]?)($self->{var_name_re})\h*/goc
           || (defined($end_delim) && /\G(?=[({])/)) {
        my ($attr, $name) = ($1, $2);

        my $ref_type;
        if (defined($+{type})) {

            my $type = $+{type};
            my $obj  = $self->parse_expr(code => \$type);

            if (not defined($obj) or ref($obj) eq 'HASH') {
                $self->fatal_error(
                                   code   => $_,
                                   pos    => pos($_),
                                   error  => "invalid type <<$type>> for variable `$name`",
                                   reason => "expected a type, such as: Str, Num, File, etc...",
                                  );
            }

            $ref_type = $obj;
        }

        my ($subset);
        if (ref($ref_type) eq 'Sidef::Variable::Subset') {
            $subset = $ref_type;
            undef $ref_type;
        }

        my ($var_name, $class_name) = $self->get_name_and_class($name);

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

        if (exists($self->{keywords}{$var_name}) or exists($self->{built_in_classes}{$var_name})) {
            $self->fatal_error(
                               code  => $_,
                               pos   => $-[2],
                               error => "`$var_name` is either a keyword or a predefined variable!",
                              );
        }

        if (defined($end_delim) and m{\G<<?\h*}gc) {
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

            $subset = $obj;
        }

        my ($value, $where_expr, $where_block);

        if (defined($end_delim)) {

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
            unshift @{$self->{vars}{$class_name}},
              {
                obj   => $obj,
                name  => $var_name,
                count => 0,
                type  => $opt{type},
                line  => $self->{line},
              };
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

    return \@var_objs;
}

sub parse_whitespace {
    my ($self, %opt) = @_;

    my $beg_line    = $self->{line};
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

                # Here-document
                while ($#{$self->{EOT}} != -1) {

                    my $eot    = shift @{$self->{EOT}};
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
            redo;
        }

        if ($found_space > 0) {
            return 1;
        }

        return;
    }
}

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
        # which skip all the checks for keywords and special objects
        if (not $self->{no_fast_path}) {

            if (/\G(?=[0-9])/) {
                goto PARSE_NUMBER;
            }

            if (    /\G(?=[^\W\d])/
                and /\G([^\W\d]\w*+)(?!::|![^\W\d]|:(?![=:])|\h*=>)/
                and not exists($self->{special_words}{$1})
                and index($1, '__') != 0) {
                goto VARIABLE_ACCESS;
            }
        }

        if (/$self->{quote_operators_re}/goc) {
            my ($double_quoted, $method, $package) = @{$^R};

            pos($_) -= 1;
            my ($string, $pos) = $self->get_quoted_string(code => $opt{code});

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

        # Object as expression
        if (/\G(?=\()/) {
            my $obj = $self->parse_arg(code => $opt{code});
            return $obj;
        }

        # Block as object
        if (/\G(?=\{)/) {
            my $obj = $self->parse_block(code => $opt{code}, topic_var => 1);
            return $obj;
        }

        # Array as object
        if (/\G(?=\[)/) {

            my @array;
            my $obj = $self->parse_array(code => $opt{code});

            if (ref($obj->{$self->{class}}) eq 'ARRAY') {
                push @array, @{$obj->{$self->{class}}};
            }

            return bless(\@array, 'Sidef::Types::Array::HCArray');
        }

        # Bareword followed by a fat comma or preceded by a colon
        if (   /\G:(\w+)/gc
            || /\G([^\W\d]\w*+)(?=\h*=>)/gc) {

            # || /\G([^\W\d]\w*+)(?=\h*=>|:(?![=:]))/gc) {
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
            my $type     = $1;
            my $vars     = $self->parse_init_vars(code => $opt{code}, type => $type);
            my $init_obj = bless({vars => $vars}, 'Sidef::Variable::Init');

            if (/\G\h*=\h*/gc) {

                my $args = $self->parse_obj(code => $opt{code}, multiline => 1);

                $args // $self->fatal_error(
                                            code  => $_,
                                            pos   => pos($_),
                                            error => "expected an expression after variable declaration",
                                           );

                $init_obj->{args} = $args;
            }

            #if ($type eq 'del') {
            #    return bless {vars => []}, 'Sidef::Variable::Init';
            #}

            return $init_obj;
        }

        # "has" class attributes
        if (exists($self->{current_class}) and /\Ghas\b\h*/gc) {

            local $self->{allow_class_variable} = 0;

            my $vars = $self->parse_init_vars(
                                              code    => $opt{code},
                                              type    => 'has',
                                              private => 1,
                                             );

            foreach my $var (@{$vars}) {
                my $name = $var->{name};
                if (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name})) {
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => (pos($_) - length($name)),
                                       error => "`$name` is either a keyword or a predefined variable!",
                                      );
                }
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
        if (/\G(define|const|static)\b\h*/gc) {
            my $type = $1;
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

                unshift @{$self->{vars}{$class_name}},
                  {
                    obj   => $var,
                    name  => $name,
                    count => 0,
                    type  => $type,
                    line  => $line,
                  };
            };

            my $vars = $self->parse_init_vars(
                                              code     => $opt{code},
                                              type     => $type,
                                              private  => 1,
                                              callback => $callback,
                                             );

            foreach my $var (@var_objs) {
                my $name = $var->{name};
                if (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name})) {
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => (pos($_) - length($name)),
                                       error => "`$name` is either a keyword or a predefined variable!",
                                      );
                }
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
        if (/\Gstruct\b\h*/gc) {

            my ($name, $class_name);
            if (/\G($self->{var_name_re})\h*/goc) {
                ($name, $class_name) = $self->get_name_and_class($1);
            }

            if (defined($name) and (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name}))) {
                $self->fatal_error(
                                   code  => $_,
                                   pos   => (pos($_) - length($name)),
                                   error => "`$name` is either a keyword or a predefined variable!",
                                  );
            }

            my $struct = bless(
                               {
                                name  => $name,
                                class => $class_name,
                               },
                               'Sidef::Variable::Struct'
                              );

            if (defined $name) {
                unshift @{$self->{vars}{$class_name}},
                  {
                    obj   => $struct,
                    name  => $name,
                    count => 0,
                    type  => 'struct',
                    line  => $self->{line},
                  };
            }

            my $vars =
              $self->parse_init_vars(
                                     code    => $opt{code},
                                     type    => 'var',
                                     private => 1,
                                    );

            $struct->{vars} = $vars;

            return $struct;
        }

        # Subset declaration
        if (/\Gsubset\b\h*/gc) {

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

            if (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name})) {
                $self->fatal_error(
                                   code  => $_,
                                   pos   => (pos($_) - length($name)),
                                   error => "`$name` is either a keyword or a predefined variable!",
                                  );
            }

            my $subset = bless({name => $name, class => $class_name}, 'Sidef::Variable::Subset');

            unshift @{$self->{vars}{$class_name}},
              {
                obj   => $subset,
                name  => $name,
                count => 0,
                type  => 'subset',
                line  => $self->{line},
              };

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
        if (/\Genum\b\h*/gc) {
            my $vars =
              $self->parse_init_vars(
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

                if (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name})) {
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => (pos($_) - length($name)),
                                       error => "`$name` is either a keyword or a predefined variable!",
                                      );
                }

                unshift @{$self->{vars}{$self->{class}}},
                  {
                    obj   => $value,
                    name  => $name,
                    count => 0,
                    type  => 'enum',
                    line  => $self->{line},
                  };
            }

            return $value;
        }

        # Local variables
        if (/\Glocal\b\h*/gc) {
            my $expr = $self->parse_obj(code => $opt{code}, prec => PREC_OPERAND);
            return bless({expr => $expr}, 'Sidef::Variable::Local');
        }

        # Declaration of classes, methods and functions
        if (
               /\G(func|class)\b\h*/gc
            || /\G(->)\h*/gc
            || (exists($self->{current_class})
                && /\G(method)\b\h*/gc)
          ) {

            my $beg_pos = $-[0];
            my $type =
                $1 eq '->'
              ? exists($self->{current_class}) && !(exists($self->{current_method}))
                  ? 'method'
                  : 'func'
              : $1;

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

            if (    $type ne 'method'
                and $type ne 'class'
                and (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name}))) {
                $self->fatal_error(
                                   code  => $_,
                                   pos   => $-[0],
                                   error => "`$name` is either a keyword or a predefined variable!",
                                  );
            }

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

                    #~ push @{$var->{obj}{value}{kids}}, $obj;
                    $parent->{has_kids} = 1;
                    $obj->{parent}      = $parent;
                }
            }

            if (not $has_kids) {
                unshift @{$self->{vars}{$class_name}},
                  {
                    obj   => $obj,
                    name  => $name,
                    count => 0,
                    type  => $type,
                    line  => $self->{line},
                  };
            }

            if ($type eq 'class') {
                my $var_names =
                  $self->parse_init_vars(
                                         code         => $opt{code},
                                         params       => 1,
                                         private      => 1,
                                         type         => 'has',
                                         ignore_delim => {
                                                          '{' => 1,
                                                          '<' => 1,
                                                         },
                                        );

                # Set the class parameters
                $obj->{vars} = $var_names;

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

                /\G\h*(?=\{)/gc
                  || $self->fatal_error(
                                        error  => "invalid class declaration",
                                        reason => "expected: class $name(...){...}",
                                        code   => $_,
                                        pos    => pos($_)
                                       );

                #~ if (ref($built_in_obj) eq 'Sidef::Variable::ClassInit') {
                #~ $obj->{name} = $built_in_obj->{name};
                #~ }

                local $self->{class_name}    = (defined($built_in_obj) ? ref($built_in_obj) : $obj->{name});
                local $self->{current_class} = $built_in_obj // $obj;
                my $block = $self->parse_block(code => $opt{code});

                # Set the block of the class
                $obj->{block} = $block;
            }

            if ($type eq 'func' or $type eq 'method') {

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

                # Functions and method traits (example: "is cached")
                if (/\G\h*is\h+(?=\w)/gc) {
                    while (/\G(\w+)/gc) {
                        my $trait = $1;
                        if ($trait eq 'cached') {
                            $obj->{cached} = 1;
                        }

                        #elsif ($type eq 'method' and $trait eq 'exported') {
                        #    $obj->{exported} = 1;
                        #}
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

                # Function return type (func name(...) -> Type {...})
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

                /\G\h*\{\h*/gc
                  || $self->fatal_error(
                                        error  => "invalid `$type` declaration",
                                        reason => "expected: $type $name(...){...}",
                                        code   => $_,
                                        pos    => pos($_)
                                       );

                local $self->{$type eq 'func' ? 'current_function' : 'current_method'} = $has_kids ? $parent : $obj;
                my $args = '|' . join(',', $type eq 'method' ? 'self' : (), @{$var_names}) . ' |';

                my $code  = '{' . $args . substr($_, pos);
                my $block = $self->parse_block(code => \$code, with_vars => 1);
                pos($_) += pos($code) - length($args) - 1;

                # Set the block of the function/method
                $obj->{value} = $block;
            }

            return $obj;
        }

        # "given(expr) {...}" construct
        if (/\Ggiven\b\h*/gc) {
            my $expr = (
                        /\G(?=\()/
                        ? $self->parse_arg(code => $opt{code})
                        : $self->parse_obj(code => $opt{code})
                       );

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
        if (exists($self->{current_given}) && /\Gwhen\b\h*/gc) {
            my $expr = (
                        /\G(?=\()/
                        ? $self->parse_arg(code => $opt{code})
                        : $self->parse_obj(code => $opt{code})
                       );

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
        if (exists($self->{current_given}) && /\Gcase\b\h*/gc) {
            my $expr = (
                        /\G(?=\()/
                        ? $self->parse_arg(code => $opt{code})
                        : $self->parse_obj(code => $opt{code})
                       );

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

        # "do {...}" construct
        if (/\Gdo\h*(?=\{)/gc) {
            my $block = $self->parse_block(code => $opt{code});
            return bless({block => $block}, 'Sidef::Types::Block::Do');
        }

        # "loop {...}" construct
        if (/\Gloop\h*(?=\{)/gc) {
            my $block = $self->parse_block(code => $opt{code});
            return bless({block => $block}, 'Sidef::Types::Block::Loop');
        }

        # "try/catch" construct
        if (/\Gtry\h*(?=\{)/gc) {
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
        if (/\Ggather\h*(?=\{)/gc) {
            my $obj = bless({}, 'Sidef::Types::Block::Gather');

            local $self->{current_gather} = $obj;

            my $block = $self->parse_block(code => $opt{code});
            $obj->{block} = $block;

            return $obj;
        }

        if (exists($self->{current_gather}) and /\Gtake\b\h*/gc) {

            my $obj = (
                       /\G(?=\()/
                       ? $self->parse_arg(code => $opt{code})
                       : $self->parse_obj(code => $opt{code})
                      );

            return bless({expr => $obj, gather => $self->{current_gather}}, 'Sidef::Types::Block::Take');
        }

        # Declaration of a module
        if (/\Gmodule\b\h*/gc) {
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

        if (/\Gimport\b\h*/gc) {

            my $import_pos = pos($_);

            my $var_names =
              $self->get_init_vars(code      => $opt{code},
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

                unshift @{$self->{vars}{$self->{class}}},
                  {
                    obj   => $var->{obj},
                    name  => $name,
                    count => 0,
                    type  => $var->{type},
                    line  => $self->{line},
                  };
            }

            return 1;
        }

        if (/\Ginclude\b\h*/gc) {

            my $include_pos = pos($_);

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

            my @abs_filenames;
            if (/\G($self->{var_name_re})/gc) {
                my $var_name = $1;

                # The module is defined in the current file -- skip
                if (exists $self->{ref_vars}{$var_name}) {
                    redo;
                }

                # The module was already included -- skip
                if (exists $Sidef::INCLUDED{$var_name}) {
                    redo;
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

                push @abs_filenames, [$full_path, $var_name];
            }
            else {

                my $orig_dir  = Cwd::getcwd();
                my $orig_file = Cwd::abs_path($self->{file_name});
                my $file_dir  = File::Basename::dirname($orig_file);

                my $chdired = 0;
                if ($orig_dir ne $file_dir) {
                    if (chdir($file_dir)) {
                        $chdired = 1;
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

                push @abs_filenames, map {
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

                if ($chdired) { chdir($orig_dir) }
            }

            my @included;

            foreach my $pair (@abs_filenames) {

                my ($full_path, $name) = @{$pair};

                open(my $fh, '<:utf8', $full_path)
                  || $self->fatal_error(
                                        code  => ${$opt{code}},
                                        pos   => $include_pos,
                                        error => "can't open file `$full_path`: $!"
                                       );

                my $content = do { local $/; <$fh> };
                close $fh;

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

        # Super-script power
        if (/\G([⁰¹²³⁴⁵⁶⁷⁸⁹]+)/gc) {
            my $num = ($1 =~ tr/⁰¹²³⁴⁵⁶⁷⁸⁹/0-9/r);
            return Sidef::Types::Number::Number::_set_int($num);
        }

        # Binary, hexadecimal and octal numbers
      PARSE_NUMBER:
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
            my $num = $1 =~ tr/_//dr;

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

            if (defined(my $var = $self->find_var('_', $self->{class}))) {
                $var->{count}++;
                return $var->{obj};
            }

            $self->fatal_error(
                               code  => $_,
                               pos   => pos($_),
                               error => q{attempt of using an implicit method call on an inexistent "_" variable},
                              );
        }

        # Quoted words, numbers, vectors and matrices
        # %w(...), %i(...), %n(...), %v(...), %m(...), «...», <...>
        if (/\G%([wWinvm])\b/gc || /\G(?=(«|<(?!<)))/) {
            my ($type) = $1;
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

        # Prefix method call (`::name(...)` or `::name ...`)
        if (/\G::($self->{var_name_re})\h*/goc) {
            my $name = $1;

            my $pos = pos($_);
            my $arg = (
                       /\G(?=\()/
                       ? $self->parse_arg(code => $opt{code})
                       : $self->parse_obj(code => $opt{code})
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

        if (/($self->{prefix_obj_re})\h*/goc) {
            return ($^R, 1, $1);
        }

        # Assertions
        if (/\G(assert(?:_(?:eq|ne))?+)\b\h*/gc) {
            my $action = $1;

            my $arg = (
                       /\G(?=\()/
                       ? $self->parse_arg(code => $opt{code})
                       : $self->parse_obj(code => $opt{code})
                      );

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

        # Function-style `not(...)`: it is applied only on the parenthesized expression
        if (/\Gnot(?=\()/gc) {
            return $self->_negate($self->parse_arg(code => $opt{code}));
        }

        # Logical `not` (it has a lower precedence than comparisons: `not a == b` is `not (a == b)`)
        if (/\Gnot\b\h*/gc) {
            my $arg = $self->parse_obj(code => $opt{code}, prec => PREC_NOT);

            $arg // $self->fatal_error(
                                       code  => $_,
                                       pos   => pos($_),
                                       error => "expected an expression after `not`",
                                      );

            return $self->_negate($arg);
        }

        # die/warn
        if (/\G(die|warn)\b\h*/gc) {
            my $action = $1;

            my $arg = (
                       /\G(?=\()/
                       ? $self->parse_arg(code => $opt{code})
                       : $self->parse_obj(code => $opt{code})
                      );

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
        if (/\Geval\b\h*/gc) {

            my $obj = (
                       /\G(?=\()/
                       ? $self->parse_arg(code => $opt{code})
                       : $self->parse_obj(code => $opt{code})
                      );

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

        if (/\GParser\b/gc) {
            return $self;
        }

        # Regular expression
        if (m{\G(?=/)} || /\G%r\b/gc) {
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

        if (/\G__MAIN__\b/gc) {
            if (-e $self->{script_name}) {
                state $x = require Cwd;
                return Sidef::Types::String::String->new(Cwd::abs_path($self->{script_name}));
            }
            return Sidef::Types::String::String->new($self->{script_name});
        }

        if (/\G__FILE__\b/gc) {
            if (-e $self->{file_name}) {
                state $x = require Cwd;
                return Sidef::Types::String::String->new(Cwd::abs_path($self->{file_name}));
            }
            return Sidef::Types::String::String->new($self->{file_name});
        }

        if (/\G__DATE__\b/gc) {
            my (undef, undef, undef, $day, $mon, $year) = localtime;
            return Sidef::Types::String::String->new(join('-', $year + 1900, map { sprintf "%02d", $_ } $mon + 1, $day));
        }

        if (/\G__TIME__\b/gc) {
            my ($sec, $min, $hour) = localtime;
            return Sidef::Types::String::String->new(join(':', map { sprintf "%02d", $_ } $hour, $min, $sec));
        }

        if (/\G__LINE__\b/gc) {
            return Sidef::Types::Number::Number->new($self->{line});
        }

        if (/\G__COMPILED__\b/gc) {
            return Sidef::Types::Bool::Bool->new($self->{opt}{R} eq 'Perl' or $self->{opt}{c});
        }

        if (/\G__OPTIMIZED__\b/gc) {
            return Sidef::Types::Bool::Bool->new(($self->{opt}{O} || 0) > 0);
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
            my $indent = $1 ? 1 : 0;
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

        # Variable access
      VARIABLE_ACCESS:
        if (/\G($self->{var_name_re})/goc) {
            my $len_var = length($1);
            my ($name, $class) = $self->get_name_and_class($1);

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

            if ($name eq 'ARGV' or $name eq 'ENV') {

                my $type     = 'var';
                my $variable = bless({name => $name, type => $type, class => $class}, 'Sidef::Variable::Variable');

                unshift @{$self->{vars}{$class}},
                  {
                    obj   => $variable,
                    name  => $name,
                    count => 1,
                    type  => $type,
                    line  => $self->{line},
                  };

                return $variable;
            }

            # Class instance variables
            if (
                ref($self->{current_class}) eq 'Sidef::Variable::ClassInit'
                and defined(
                        my $var = (first { $_->{name} eq $name } (@{$self->{current_class}{vars}}, map { @{$_->{vars}} } @{$self->{current_class}{attributes}}))
                )
              ) {
                if (exists $self->{current_method}) {
                    if (defined(my $var = $self->find_var('self', $class))) {

                        if ($self->{opt}{k}) {
                            print STDERR "[INFO] `$name` is parsed as `self.$name` at $self->{file_name} line $self->{line}\n";
                        }

                        $var->{count}++;
                        return
                          scalar {
                                  $self->{class} => [
                                                     {
                                                      self => $var->{obj},
                                                      ind  => [{hash => [$name]}],
                                                     }
                                                    ]
                                 };
                    }
                }
                elsif (exists $self->{allow_class_variable}) {
                    return $var;
                }
                elsif ($var->{type} eq 'has') {
                    $self->fatal_error(
                                       error => "class variable <<$var->{name}>> can't be used outside a method",
                                       pos   => (pos($_) - length($name)),
                                       var   => $var,
                                       code  => $_,
                                      );
                }
                else {    # this should not happen
                    $self->fatal_error(
                                       error => "can't use undeclared variable <<$var->{name}>> in this context",
                                       pos   => (pos($_) - length($name)),
                                       var   => $var,
                                       code  => $_,
                                      );
                }
            }

            if (/\G(?=\h*:?=(?![=~>]))/) {

                if (not $self->{interactive}) {
                    warn "[WARNING] Implicit declaration of global variable `$name`" . " at $self->{file_name} line $self->{line}\n";
                }

                my $code = "global $name";
                return $self->parse_expr(code => \$code);
            }

            # Method call in functional style (deprecated -- use `::name()` instead)
            if ($len_var == length($name)) {

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

            # Undeclared variable
            $self->fatal_error(
                               code  => $_,
                               pos   => (pos($_) - length($name)),
                               var   => ($class . '::' . $name),
                               error => "variable <$class\::$name> is not declared in the current scope",
                              );
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

        #warn "$self->{script_name}:$self->{line}: unexpected char: " . substr($_, pos($_), 1) . "\n";
        #return undef, pos($_) + 1;

        return;
    }
}

sub parse_arg {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    if (/\G\(/gc) {
        my $p = pos($_);
        local $self->{parentheses} = 1;
        local $self->{no_pipe_op}  = 0;
        local $self->{no_pair_op}  = 0;
        my $obj = $self->parse_script(code => $opt{code});

        $self->{parentheses}
          && $self->fatal_error(
                                code  => $_,
                                pos   => $p - 1,
                                error => "unbalanced parenthesis",
                               );

        return $obj;
    }

    return;
}

sub parse_array {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    if (/\G\[/gc) {
        my $p = pos($_);
        local $self->{right_brackets} = 1;
        local $self->{no_pipe_op}     = 0;
        local $self->{no_pair_op}     = 0;
        my $obj = $self->parse_script(code => $opt{code});

        $self->{right_brackets}
          && $self->fatal_error(
                                code  => $_,
                                pos   => $p - 1,
                                error => "unbalanced right bracket",
                               );

        return $obj;
    }

    return;
}

sub parse_lookup {
    my ($self, %opt) = @_;

    local *_ = $opt{code};

    if (/\G\{/gc) {
        my $p = pos($_);
        local $self->{curly_brackets} = 1;
        local $self->{no_pipe_op}     = 0;
        local $self->{no_pair_op}     = 0;
        my $obj = $self->parse_script(code => $opt{code});

        $self->{curly_brackets}
          && $self->fatal_error(
                                code  => $_,
                                pos   => $p - 1,
                                error => "unbalanced curly bracket",
                               );

        return $obj;
    }

    return;
}

sub parse_block {
    my ($self, %opt) = @_;

    local *_ = $opt{code};
    if (/\G\{/gc) {

        my $p = pos($_);
        local $self->{curly_brackets} = 1;
        local $self->{no_pipe_op}     = 0;
        local $self->{no_pair_op}     = 0;

        my $class_name = $self->{class};

        if ($opt{is_module}) {
            $class_name = $opt{prev_class};
        }

        my $ref   = $self->{vars}{$class_name} //= [];
        my $count = scalar(@{$self->{vars}{$class_name}});

        unshift @{$self->{ref_vars_refs}{$class_name}}, @{$ref};
        unshift @{$self->{vars}{$class_name}},          [];

        $self->{vars}{$class_name} = $self->{vars}{$class_name}[0];

        my $block = bless({}, 'Sidef::Types::Block::BlockInit');

        # Parse whitespace (if any)
        $self->parse_whitespace(code => $opt{code});

        my $has_vars;
        my $var_objs = [];

        if (($opt{topic_var} || $opt{with_vars}) && /\G(?=\|)/) {
            $has_vars = 1;
            $var_objs = $self->parse_init_vars(
                                               params => 1,
                                               code   => $opt{code},
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
                                code  => $_,
                                pos   => $p - 1,
                                error => "unbalanced curly bracket",
                               );

        #$block->{vars} = [
        #    map { $_->{obj} }
        #    grep { ref($_) eq 'HASH' and ref($_->{obj}) eq 'Sidef::Variable::Variable' } @{$self->{vars}{$class_name}}
        #];

        if ($has_vars) {
            $block->{init_vars} = bless({vars => $var_objs}, 'Sidef::Variable::Init');
        }

        $block->{code} = $obj;
        splice @{$self->{ref_vars_refs}{$class_name}}, 0, $count;
        $self->{vars}{$class_name} = $ref;

        return $block;
    }

    return;
}

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

sub parse_methods {
    my ($self, %opt) = @_;

    my @methods;
    local *_ = $opt{code};
    my $orig_pos = pos($_);

    {
        # Method calls introduced by a dot (e.g.: `.name`, `.name(...)`, `.+(...)`).
        # The infix operators are handled by parse_infix().
        if (/\G\.(?!\.)/gc) {    # a single dot (`...` and `..` are operators)
            my ($method, $req_arg, $op_type) = $self->get_method_name(code => $opt{code});

            if (defined($method)) {

                my $has_arg;
                if (/\G\h*(?=[({])/gc || $req_arg) {
                    my $arg = (
                                 $req_arg   ? $self->parse_obj(code => $opt{code}, multiline => 1, prec => PREC_OPERAND)
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

    my ($method, $op_type) = @{$token}{qw(method op_type)};

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

            my $code   = substr($_, pos($_));
            my $dot_op = $code =~ /^\./;
            if   ($dot_op) { $code = ". $code" }
            else           { $code = ".$code" }

            my $methods = $self->parse_methods(code => \$code);
            pos($_) += pos($code) - ($dot_op ? 2 : 1);

            @{$methods}
              || $self->fatal_error(
                                    error => 'incomplete method name',
                                    code  => $_,
                                    pos   => pos($_) - 1,
                                   );

            if ($wrap) {
                $struct = {$self->{class} => [{self => $struct}]};
                $wrap   = 0;
            }

            push @{$struct->{$self->{class}}[-1]{call}}, @{$methods};

            # Calls and indices applied on the result: `x -> method(...)(...)`, `x -> method(...)[...]`
            $self->parse_suffixes(code => $opt{code}, struct => $struct);
            next;
        }

        # Ternary operator (the `?` is allowed to be on the next line)
        if ($min_prec <= PREC_TERNARY and /\G(?=\s*\?)/) {

            $self->_flush_chain(\$struct, \$chain) if defined $chain;

            $self->parse_whitespace(code => $opt{code});
            /\G\?/gc;
            my $q_pos = pos($_);
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
                              cond  => $struct,
                              true  => $true,
                              false => $false,
                             },
                             'Sidef::Types::Bool::Ternary'
                            );

            $struct = {$self->{class} => [{self => $node}]};
            $wrap   = 0;
            next;
        }

        my $token = $self->_peek_operator(code => $opt{code}) // last;

        # Keyword operators: if, while, and, or
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
                $struct = {$self->{class} => [{self => $struct}]};
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

        if (not $req_arg) {    # postfix operator, applied on the whole left-hand side

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
            $struct = {$self->{class} => [{self => $struct}]};
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
    }
    elsif ($ref eq 'Sidef::Variable::Ref' or $ref eq 'Sidef::Meta::PrefixColon') {
        $prec = PREC_OPERAND;
    }
    else {    # return, read, goto
        $prec = PREC_ASSIGN;
    }

    return $self->parse_obj(code => $opt{code}, prec => $prec);
}

# Parses an expression, using the operator precedence rules.
#
# The `prec` option sets the minimum precedence of the operators that are consumed.
# By default, a full expression is parsed (everything that binds tighter than
# a comma). The statement-level expressions (see parse_script) also consume the
# pair constructors and the keyword operators (if, while, and, or).
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

sub parse_operand {
    my ($self, %opt) = @_;

    my %struct;
    my $wrap;
    local *_ = $opt{code};

    if (not($opt{multiline}) and /\G\h*(?=\R)/gc) {
        $self->fatal_error(
                           code  => $_,
                           pos   => pos($_) - 1,
                           error => "unexpected end-of-statement",
                          );
    }

    my ($obj, $obj_key, $method) = $self->parse_expr(code => $opt{code});

    if (defined $obj) {
        push @{$struct{$self->{class}}}, {self => $obj};

        # for (var in array) { ... }
        my $for_paren = 0;
        if (ref($obj) eq 'Sidef::Types::Block::For'
            and /\G\h*\((?=\h*[*:]?$self->{var_name_re}(?:\h*,\h*[*:]?$self->{var_name_re})*\h+(?:in|∈)\b)/goc) {
            $for_paren = 1;
            /\G\h*/gc;
        }

        # for var in array { ... }
        if ($for_paren or (ref($obj) eq 'Sidef::Types::Block::For' and /\G\h*(?=[*:]?$self->{var_name_re})/goc)) {

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

                    unshift @{$self->{vars}{$class_name}},
                      {
                        obj   => $vars[-1],
                        name  => $name,
                        count => 1,
                        type  => 'var',
                        line  => $self->{line},
                      };

                    $type && last;
                    /\G\h*,\h*/gc || last;
                }

                /\G\h*(?:in|∈|=|)\h*/gc
                  || $self->fatal_error(
                                        error => "expected the token <<in>> after variable declaration in for-loop",
                                        code  => $_,
                                        pos   => pos($_),
                                       );

                my $expr = (
                            /\G(?=\()/
                            ? $self->parse_arg(code => $opt{code})
                            : $self->parse_obj(code => $opt{code})
                           );

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
                                              error => "expected a block",
                                              code  => $_,
                                              pos   => pos($_),
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
        }
        elsif ($obj_key) {
            my $arg = $self->_parse_prefix_arg(code => $opt{code}, obj => $obj, method => $method);

            if (defined $arg) {
                my @arg = ($arg);

                if (ref($obj) eq 'Sidef::Types::Block::For') {

                    if ($#{$arg->{$self->{class}}} == 2) {
                        @arg = (
                            map {
                                { $self->{class} => [$_] }
                            } @{$arg->{$self->{class}}}
                        );

                        if (/\G\h*(?=\{)/gc) {
                            my $block = $self->parse_block(code => $opt{code});

                            $obj->{expr}  = \@arg;
                            $obj->{block} = $block;

                            bless $obj, 'Sidef::Types::Block::CFor';

                        }
                        else {
                            $self->fatal_error(
                                               code   => $_,
                                               pos    => pos($_) - 1,
                                               error  => "invalid declaration of the `for` loop",
                                               reason => "expected a block after `for(;;)`",
                                              );
                        }
                    }
                    elsif ($#{$arg->{$self->{class}}} == 0) {

                        if (/\G\h*(?=\{)/gc) {
                            my $block = $self->parse_block(code => $opt{code}, topic_var => 1);

                            $obj->{expr}  = $arg;
                            $obj->{block} = $block;

                            bless $obj, 'Sidef::Types::Block::ForEach';
                        }
                        else {
                            $self->fatal_error(
                                               code   => $_,
                                               pos    => pos($_) - 1,
                                               error  => "invalid declaration of the `for` loop",
                                               reason => "expected a block after `for(...)`",
                                              );
                        }
                    }
                    else {
                        $self->fatal_error(
                                           code  => $_,
                                           pos   => pos($_) - 1,
                                           error => "invalid declaration of the `for` loop: incorrect number of arguments",
                                          );
                    }
                }
                elsif (ref($obj) eq 'Sidef::Types::Block::ForEach') {
                    if (/\G\h*(?=\{)/gc) {
                        my $block = $self->parse_block(code => $opt{code}, topic_var => 1);

                        $obj->{expr}  = $arg;
                        $obj->{block} = $block;

                    }
                    else {
                        $self->fatal_error(
                                           code   => $_,
                                           pos    => pos($_) - 1,
                                           error  => "invalid declaration of the `foreach` loop",
                                           reason => "expected a block after `foreach(...)`",
                                          );
                    }
                }
                elsif (ref($obj) eq 'Sidef::Types::Block::If') {

                    # `unless (cond) {...}` is the same as `if (!cond) {...}`
                    $arg = $self->_negate($arg) if $method eq 'unless';

                    if (/\G\h*(?=\{)/gc) {
                        my $block = $self->parse_block(code => $opt{code}, with_vars => 1);
                        push @{$obj->{if}}, {expr => $arg, block => $block};

                      ELSIF: {

                            $self->parse_whitespace(code => $opt{code});

                            if (/\G(?:elsif|else\h+if)\h*(?=\()/gc) {
                                my $arg = $self->parse_arg(code => $opt{code});
                                $self->parse_whitespace(code => $opt{code});

                                my $block = $self->parse_block(code => $opt{code}, with_vars => 1) // $self->fatal_error(
                                                                                                           code  => $_,
                                                                                                           pos   => pos($_) - 1,
                                                                                                           error => "invalid declaration of the `if` statement",
                                                                                                           reason => "expected a block after `elsif(...)`",
                                );

                                push @{$obj->{if}}, {expr => $arg, block => $block};
                                redo ELSIF;
                            }
                        }

                        if (/\Gelse\h*(?=\{)/gc) {
                            my $block = $self->parse_block(code => $opt{code});
                            $obj->{else}{block} = $block;
                        }

                        $self->backtrack_whitespace(code => $opt{code});
                    }
                    else {
                        $self->fatal_error(
                                           code   => $_,
                                           pos    => pos($_) - 1,
                                           error  => "invalid declaration of the `if` statement",
                                           reason => "expected a block after `if(...)`",
                                          );
                    }
                }
                elsif (ref($obj) eq 'Sidef::Types::Block::With') {

                    if (/\G\h*(?=\{)/gc) {
                        my $block = $self->parse_block(code => $opt{code}, topic_var => 1);
                        push @{$obj->{with}}, {expr => $arg, block => $block};

                      ORWITH: {

                            $self->parse_whitespace(code => $opt{code});

                            if (/\Gorwith\h*(?=\()/gc) {
                                my $arg = $self->parse_arg(code => $opt{code});
                                $self->parse_whitespace(code => $opt{code});

                                my $block = $self->parse_block(code => $opt{code}, topic_var => 1) // $self->fatal_error(
                                                                                                         code  => $_,
                                                                                                         pos   => pos($_) - 1,
                                                                                                         error => "invalid declaration of the `with` statement",
                                                                                                         reason => "expected a block after `orwith(...)`",
                                );

                                push @{$obj->{with}}, {expr => $arg, block => $block};
                                redo ORWITH;
                            }
                        }

                        if (/\Gelse\h*(?=\{)/gc) {
                            my $block = $self->parse_block(code => $opt{code});
                            $obj->{else}{block} = $block;
                        }

                        $self->backtrack_whitespace(code => $opt{code});
                    }
                    else {
                        $self->fatal_error(
                                           code   => $_,
                                           pos    => pos($_) - 1,
                                           error  => "invalid declaration of the `with` statement",
                                           reason => "expected a block after `with(...)`",
                                          );
                    }
                }
                elsif (ref($obj) eq 'Sidef::Types::Block::While') {

                    # `until (cond) {...}` is the same as `while (!cond) {...}`
                    $arg = $self->_negate($arg) if $method eq 'until';

                    if (/\G\h*(?=\{)/gc) {
                        my $block = $self->parse_block(code => $opt{code}, with_vars => 1);
                        $obj->{expr}  = $arg;
                        $obj->{block} = $block;
                    }
                    else {
                        $self->fatal_error(
                                           code   => $_,
                                           pos    => pos($_) - 1,
                                           error  => "invalid declaration of the `while` statement",
                                           reason => "expected a block after `while(...)`",
                                          );
                    }
                }
                else {
                    push @{$struct{$self->{class}}[-1]{call}}, {method => $method, arg => \@arg};
                    $wrap = 1;    # the result of a prefix operator is a new operand
                }
            }
            else {
                $self->fatal_error(
                                   code  => $_,
                                   error => "expected an argument. Did you mean '$method()' instead?",
                                   pos   => pos($_) - 1,
                                  );
            }
        }

        {
            # Method call
            if (/\G\h*(?=\.\s*(?:$self->{method_name_re}|[(\$]))/ogc) {
                my $methods = $self->parse_methods(code => $opt{code});
                push @{$struct{$self->{class}}[-1]{call}}, @{$methods};
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
            if (/\G(?=(?:[ \t]*(?:#[^\r\n]*)?\R)+\s*\.(?![.0-9]))/
                and not defined($self->find_var('_', $self->{class}))) {
                $self->parse_whitespace(code => $opt{code});
                redo;
            }

            # Operators used with the method-call syntax: `a .+ b`, or `a \.` followed by
            # the operator on the next line. The operator binds tighter than any other operator.
            if (/\G\h*(?:\\(?!\\)\s*)?(?=\.(?!\.)\s*(?:$self->{operators_re}))/ogc) {
                my $methods = $self->parse_methods(code => $opt{code});
                push @{$struct{$self->{class}}[-1]{call}}, @{$methods};
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

                push @{$struct{$self->{class}}[-1]{call}},
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
                push @{$struct{$self->{class}}[-1]{call}}, {keyword => 'while', arg => [$arg]};
            }

            # Parse array and hash fetchers ([...] and {...})
            if (/\G\.\h*(?=[\[\{])/gc or 1) {
                $self->parse_suffixes(code => $opt{code}, struct => \%struct) && redo;
            }

            # Postfix operators (e.g.: x++, x--, n!, n!!, x...)
            if (defined(my $token = $self->_peek_operator(code => $opt{code}, postfix_only => 1))) {
                $self->append_method(
                                     array   => \@{$struct{$self->{class}}[-1]{call}},
                                     method  => $token->{method},
                                     op_type => $token->{op_type},
                                    );
                redo;
            }
        }
    }
    else {
        return;
    }

    return (wantarray ? (\%struct, $wrap) : \%struct);
}

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

        if (/\G\]/gc) {

            if (--$self->{right_brackets} < 0) {
                $self->fatal_error(
                                   error => 'unbalanced right bracket',
                                   code  => $_,
                                   pos   => pos($_) - 1,
                                  );
            }

            return \%struct;
        }

        if (/\G\}/gc) {

            if (--$self->{curly_brackets} < 0) {
                $self->fatal_error(
                                   error => 'unbalanced curly bracket',
                                   code  => $_,
                                   pos   => pos($_) - 1,
                                  );
            }

            return \%struct;
        }

        # The end of an argument expression
        if (/\G\)/gc) {

            if (--$self->{parentheses} < 0) {
                $self->fatal_error(
                                   error => 'unbalanced parenthesis',
                                   code  => $_,
                                   pos   => pos($_) - 1,
                                  );
            }

            return \%struct;
        }

        $self->fatal_error(
                           code  => $_,
                           pos   => (pos($_)),
                           error => "expected a method",
                          );

        pos($_) += 1;
        redo;
    }
}

1
