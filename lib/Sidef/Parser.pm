package Sidef::Parser {

    use utf8;
    use 5.016;

    use Sidef::Types::Bool::Bool;
    use List::Util qw(first);
    use Scalar::Util qw(refaddr);

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
                     | Perl\b                         (?{ state $x = bless({}, 'Sidef::Perl::Perl') })
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
                     | \$\^PERL\b                     (?{ state $x = bless({name => '$^X'}, 'Sidef::Variable::Magic') })
                     | (?:\$0|\$\^SIDEF)\b            (?{ state $x = bless({name => '$0'}, 'Sidef::Variable::Magic') })
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
                  Mod
                  Gauss
                  Quadratic
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
                  if elsif else
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

            # Reference: http://en.wikipedia.org/wiki/International_variation_in_quotation_marks
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

        my $error_line = (split(/\R/, substr($opt{code}, $start, $point + 80)))[0];

        if (length($error_line) >= 80) {

            if ($point > 60) {

                my $from = $point - 40;
                my $rem  = $point + 40 - length($error_line);

                $from -= $rem;
                $point = 40 + $rem;

                $error_line = substr($error_line, $from, 80);
            }
            else {
                $error_line = substr($error_line, 0, 80);
            }
        }

        my @lines = (
                     "HAHA! That's really funny! You got me!",
                     "I thought that... Oh, you got me!",
                     "LOL! I expected... Oh, my! This is funny!",
                     "Oh, oh... Wait a second! Did you mean...? Damn!",
                     "You're embarrassing me! That's not funny!",
                     "My brain just exploded.",
                     "Sorry, I don't know how to help in this situation.",
                     "I'm broken. Fix me, or show this to someone who can fix",
                     "Huh?",
                     "Out of order",
                     "You must be joking.",
                     "Ouch, That HURTS!",
                     "Who are you!?",
                     "Death before dishonour?",
                     "Good afternoon, gentleman, I'm a HAL 9000 Computer",
                     "Okie dokie, I'm dead",
                     "Help is not available for you.",
                     "Your expression has defeated me",
                     "Your code has defeated me",
                     "Your logic has defeated me",
                     "Weird magic happens here",
                     "I give up... dumping core now!",
                     "Okie dokie, core dumped.bash",
                     "You made me die. Shame on you!",
                     "Invalid code. Feel ashamed for yourself and try again.",
                    );

        my $error = sprintf("%s: %s\n\nFile : %s\nLine : %s : %s\nError: %s\n\n" . ("~" x 80) . "\n%s\n",
                            'sidef',
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

            if (m{\G(?<main>$beg_delim((?>[^\\$re_delim]*+(?>\\.[^\\$re_delim]*|(?&main)){0,}){0,})$end_delim)}sgc) {
                $string = $2 =~ s/\\([$re_delim])/$1/gr;
            }
        }

        # elsif (m{\G$beg_delim([^\\$beg_delim]*+(?>\\.[^\\$beg_delim]*)*)}sgc) {    # limited to 2^15-1 escapes
        # elsif (m{\G$beg_delim((?>(?>[^$beg_delim\\]++|\\.){0,}+){0,}+)}sgc) {

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

        my @delims = ('|', keys(%{$self->{delim_pairs}}));
        if (exists $opt{ignore_delim}) {
            @delims = grep { not exists $opt{ignore_delim}{$_} } @delims;
        }

        my $regex = do {
            local $" = "";
            qr/\G([@delims])\h*/;
        };

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

            my ($subset);
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
                        until (/\G$name(?:\R|\z)/gc) {

                            if (/\G(.*)/gc) {
                                $acc .= "$1\n";
                            }

                            # Indentation is true
                            if ($indent && /\G\R(\h*)$name(?:\R|\z)/gc) {
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

            # Embedded comments (http://perlcabal.org/syn/S02.html#Embedded_Comments)
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
                while (1) {
                    m{\G.*?\*/}gc && last;
                    /\G.+/gc || (/\G\R/gc ? $self->{line}++ : last);
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

                my $obj = (
                    $double_quoted
                    ? do {
                        state $str = Sidef::Types::String::String->new;    # load the string module
                        Sidef::Types::String::String::apply_escapes($package->$method($string), $self);
                      }
                    : $package->$method($string =~ s{\\\\}{\\}gr)
                );

                # Special case for backticks (add method 'run')
                if ($package eq 'Sidef::Types::Glob::Backtick') {
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

                if (ref $obj->{$self->{class}} eq 'ARRAY') {
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

                my $value = Sidef::Types::Number::Number->new(-1);

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
                my $expr = $self->parse_obj(code => $opt{code});
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
                  ($type eq 'func' or $type eq 'method')
                  ? bless({name => $name, type => $type, class => $class_name}, 'Sidef::Variable::Variable')
                  : $type eq 'class'
                  ? bless({name => ($built_in_obj // $name), class => $class_name}, 'Sidef::Variable::ClassInit')
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
                    require File::Spec;
                    require Cwd;
                };

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

                    if (@{$self->{inc}} == 0) {
                        state $y = require File::Basename;
                        push @{$self->{inc}}, split(':', $ENV{SIDEF_INC}) if exists($ENV{SIDEF_INC});

                        push @{$self->{inc}},
                          File::Spec->catdir(File::Basename::dirname(Cwd::abs_path($0)), File::Spec->updir, 'share', 'sidef');

                        if (-f $self->{script_name}) {
                            push @{$self->{inc}}, File::Basename::dirname(Cwd::abs_path($self->{script_name}));
                        }

                        push @{$self->{inc}}, File::Spec->curdir;
                    }

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
                            map   { $_->{self} }
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
                                  code  => $_,
                                  pos   => $include_pos,
                                  error => 'include-error: invalid value of type "' . ref($filename) . '" (expected a string)',
                          );

                        my @files;
                        foreach my $file (glob($filename)) {
                            my $abs = Cwd::abs_path($file);

                            if (!defined($abs) or $abs eq '') {
                                $self->fatal_error(
                                          code  => $_,
                                          pos   => $include_pos,
                                          error => 'include-error: cannot resolve the absolute path to file <<' . $file . '>>',
                                );
                            }

                            push @files, $abs;
                        }

                        foreach my $file (@files) {
                            if (exists $Sidef::INCLUDED{$file}) {
                                $self->fatal_error(
                                                   code  => $_,
                                                   pos   => $include_pos,
                                                   error => "include-error: circular inclusion of file: $file",
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
                                            code  => $_,
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
                return Sidef::Types::Number::Number->new($num);
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
            if (/\G([+-]?+(?=\.?[0-9])[0-9_]*+(?:\.[0-9_]++)?(?:[Ee](?:[+-]?+[0-9_]+))?)/gc) {
                my $num = $1 =~ tr/_//dr;

                if (/\Gi\b/gc) {    # imaginary
                    return Sidef::Types::Number::Complex->new(0, $num);
                }

                return Sidef::Types::Number::Number->new($num);
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
                my $string = $self->get_quoted_string(code => $opt{code});
                return Sidef::Types::Regex::Regex->new($string, /\G($self->{match_flags_re})/goc ? $1 : undef);
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
                        my $var = (
                                 first { $_->{name} eq $name }
                                 (@{$self->{current_class}{vars}}, map { @{$_->{vars}} } @{$self->{current_class}{attributes}})
                                  )
                               )
                  ) {
                    if (exists $self->{current_method}) {
                        if (defined(my $var = $self->find_var('self', $class))) {

                            if ($self->{opt}{k}) {
                                print STDERR
                                  "[INFO] `$name` is parsed as `self.$name` at $self->{file_name} line $self->{line}\n";
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
                        warn "[WARNING] Implicit declaration of global variable `$name`"
                          . " at $self->{file_name} line $self->{line}\n";
                    }

                    my $code = "global $name";
                    return $self->parse_expr(code => \$code);
                }

                # Method call in functional style (deprecated -- use `::name()` instead)
                if ($len_var == length($name)) {

                    if ($self->{opt}{k}) {
                        print STDERR
                          "[INFO] `$name` is parsed as a prefix method-call at $self->{file_name} line $self->{line}\n";
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
            if ((/\G(?![-=]>)/ && /\G(?=$self->{operators_re})/o) || /\G\./gc) {
                my ($method, $req_arg, $op_type) = $self->get_method_name(code => $opt{code});

                if (defined($method)) {

                    my $has_arg;
                    if (/\G\h*(?=[({])/gc || $req_arg) {
                        my $arg = (
                                     $req_arg   ? $self->parse_obj(code => $opt{code}, multiline => 1)
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

    sub parse_obj {
        my ($self, %opt) = @_;

        my %struct;
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

            # for var in array { ... }
            if (ref($obj) eq 'Sidef::Types::Block::For' and /\G\h*(?=[*:]?$self->{var_name_re})/goc) {

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
                my $arg = (
                           /\G(?=\()/
                           ? $self->parse_arg(code => $opt{code})
                           : $self->parse_obj(code => $opt{code})
                          );

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

                        if (/\G\h*(?=\{)/gc) {
                            my $block = $self->parse_block(code => $opt{code}, with_vars => 1);
                            push @{$obj->{if}}, {expr => $arg, block => $block};

                          ELSIF: {

                                $self->parse_whitespace(code => $opt{code});

                                if (/\Gelsif\h*(?=\()/gc) {
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
                if (/\G\h*(?=\.\h*(?:$self->{method_name_re}|[(\$]))/ogc) {
                    my $methods = $self->parse_methods(code => $opt{code});
                    push @{$struct{$self->{class}}[-1]{call}}, @{$methods};
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
                if (ref($obj) eq 'Sidef::Types::Block::Do' and /\G\h*while\b/gc) {
                    my $arg = $self->parse_obj(code => $opt{code});
                    push @{$struct{$self->{class}}[-1]{call}}, {keyword => 'while', arg => [$arg]};
                }

                # Parse array and hash fetchers ([...] and {...})
                if (/\G\.\h*(?=[\[\{])/gc or 1) {
                    $self->parse_suffixes(code => $opt{code}, struct => \%struct) && redo;
                }

                # Tightly-binded operator
                if (
                    /\G(?![=-]>)/    # not '=>' or '->'
                    && (
                        /\G(?=$self->{operators_re})/o                         # operator
                        || /\G\h*\.\h*(?!\.\.)(?=$self->{operators_re})/gco    # dot followed by operator
                        || /\G(?=[⁰¹²³⁴⁵⁶⁷⁸⁹])/                                # unicode superscript
                       )
                  ) {

                    my $orig_pos = pos($_);
                    my ($method, $req_arg, $op_type) = $self->get_method_name(code => $opt{code});

                    if (defined($method)) {

                        my $has_arg;
                        if ($req_arg) {
                            my $arg = $self->parse_obj(code => $opt{code}, multiline => 1);

                            if (defined $arg) {
                                if (ref $arg ne 'HASH') {
                                    $arg = {$self->{class} => [{self => $arg}]};
                                }

                                my $methods = $self->parse_methods(code => $opt{code});
                                if (@{$methods}) {
                                    push @{$arg->{$self->{class}}[-1]{call}}, @{$methods};
                                }

                                $has_arg = 1;
                                $self->append_method(
                                                     array   => \@{$struct{$self->{class}}[-1]{call}},
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
                                                 array   => \@{$struct{$self->{class}}[-1]{call}},
                                                 method  => $method,
                                                 op_type => $op_type,
                                                );
                        };
                        redo;
                    }
                }
            }
        }
        else {
            return;
        }

        return \%struct;
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

            my $obj;

            # Ternary operator
            if (%struct && /\G\?/gc) {
                $self->parse_whitespace(code => $opt{code});

                my $true = (
                            /\G(?=\()/
                            ? $self->parse_arg(code => $opt{code})
                            : $self->parse_obj(code => $opt{code})
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

                my $false = (
                             /\G(?=\()/
                             ? $self->parse_arg(code => $opt{code})
                             : $self->parse_obj(code => $opt{code})
                            );

                $obj = bless(
                             {
                              cond  => scalar {$self->{class} => [pop @{$struct{$self->{class}}}]},
                              true  => $true,
                              false => $false
                             },
                             'Sidef::Types::Bool::Ternary'
                            );
            }
            else {
                $obj = $self->parse_obj(code => $opt{code});
            }

            if (defined $obj) {
                push @{$struct{$self->{class}}}, {self => $obj};

                {
                    my $pos_before = pos($_);
                    $self->parse_whitespace(code => $opt{code});

                    # End of expression
                    if (/\G(?:[;,]+|=>)/gc or substr($_, $pos_before, pos($_) - $pos_before) =~ /\R/) {
                        redo MAIN;
                    }

                    # Code extended on a newline
                    if (/\G\\(?!\\)/gc) {
                        $self->parse_whitespace(code => $opt{code});
                    }

                    my $is_operator = /\G(?!->)/ && /\G(?=($self->{operators_re}))/o;

                    if ($is_operator or /\G(?:->|\.)\h*/gc) {

                        # Implicit end of statement -- redo
                        $self->parse_whitespace(code => $opt{code});

                        my $methods;
                        if ($is_operator) {
                            $methods = $self->parse_methods(code => $opt{code});
                        }
                        else {
                            my $code   = substr($_, pos);
                            my $dot_op = $code =~ /^\./;
                            if   ($dot_op) { $code = ". $code" }
                            else           { $code = ".$code" }
                            $methods = $self->parse_methods(code => \$code);
                            pos($_) += pos($code) - ($dot_op ? 2 : 1);
                        }

                        if (@{$methods}) {
                            push @{$struct{$self->{class}}[-1]{call}}, @{$methods};
                        }
                        else {
                            $self->fatal_error(
                                               error => 'incomplete method name',
                                               code  => $_,
                                               pos   => pos($_) - 1,
                                              );
                        }

                        $self->parse_suffixes(code => $opt{code}, struct => \%struct);
                        redo;
                    }
                    elsif (/\G(if|while|and|or)\b\h*/gc) {
                        my $keyword = $1;
                        my $obj     = $self->parse_obj(code => $opt{code});
                        push @{$struct{$self->{class}}[-1]{call}}, {keyword => $keyword, arg => [$obj]};
                        redo;
                    }
                    else {
                        redo MAIN;
                    }
                }
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
};

1
