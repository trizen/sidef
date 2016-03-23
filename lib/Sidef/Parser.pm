package Sidef::Parser {

    use utf8;
    use 5.014;

    our $DEBUG = 0;
    use Sidef::Types::Bool::Bool;

    sub new {
        my (undef, %opts) = @_;

        my %options = (
            line          => 1,
            inc           => [],
            class         => 'main',           # a.k.a. namespace
            vars          => {'main' => []},
            ref_vars_refs => {'main' => []},
            EOT           => [],

            postfix_ops => {                   # postfix operators
                             '--'  => 1,
                             '++'  => 1,
                             '...' => 1,
                             '!'   => 1,
                           },

            hyper_ops => {

                # type => [takes args, method name]
                map    => [1, 'map_operator'],
                pam    => [1, 'pam_operator'],
                zip    => [1, 'zip_operator'],
                cross  => [1, 'cross_operator'],
                unroll => [1, 'unroll_operator'],
                reduce => [0, 'reduce_operator'],
            },

            static_obj_re => qr{\G
                (?:
                       nil\b                          (?{ state $x = bless({}, 'Sidef::Types::Nil::Nil') })
                     | null\b                         (?{ state $x = Sidef::Types::Null::Null->new })
                     | true\b                         (?{ Sidef::Types::Bool::Bool::TRUE })
                     | false\b                        (?{ Sidef::Types::Bool::Bool::FALSE })
                     | next\b                         (?{ state $x = bless({}, 'Sidef::Types::Block::Next') })
                     | break\b                        (?{ state $x = bless({}, 'Sidef::Types::Block::Break') })
                     | continue\b                     (?{ state $x = bless({}, 'Sidef::Types::Block::Continue') })
                     | Block\b                        (?{ state $x = bless({}, 'Sidef::DataTypes::Block::Block') })
                     | Backtick\b                     (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::Backtick') })
                     | ARGF\b                         (?{ state $x = bless({}, 'Sidef::Meta::Glob::ARGF') })
                     | STDIN\b                        (?{ state $x = bless({}, 'Sidef::Meta::Glob::STDIN') })
                     | STDOUT\b                       (?{ state $x = bless({}, 'Sidef::Meta::Glob::STDOUT') })
                     | STDERR\b                       (?{ state $x = bless({}, 'Sidef::Meta::Glob::STDERR') })
                     | Bool\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Bool::Bool') })
                     | FileHandle\b                   (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::FileHandle') })
                     | DirHandle\b                    (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::DirHandle') })
                     | Dir\b                          (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::Dir') })
                     | File\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::File') })
                     | Arr(?:ay)?+\b                  (?{ state $x = bless({}, 'Sidef::DataTypes::Array::Array') })
                     | MultiArr(?:ay)?+\b             (?{ state $x = bless({}, 'Sidef::DataTypes::Array::MultiArray') })
                     | Pair\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Array::Pair') })
                     | Hash\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Hash::Hash') })
                     | Str(?:ing)?+\b                 (?{ state $x = bless({}, 'Sidef::DataTypes::String::String') })
                     | Num(?:ber)?+\b                 (?{ state $x = bless({}, 'Sidef::DataTypes::Number::Number') })
                     | Inf\b                          (?{ state $x = Sidef::Types::Number::Inf->new })
                     | NaN\b                          (?{ state $x = Sidef::Types::Number::Nan->new })
                     | RangeNum(?:ber)?+\b            (?{ state $x = bless({}, 'Sidef::DataTypes::Range::RangeNumber') })
                     | RangeStr(?:ing)?+\b            (?{ state $x = bless({}, 'Sidef::DataTypes::Range::RangeString') })
                     | Socket\b                       (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::Socket') })
                     | Pipe\b                         (?{ state $x = bless({}, 'Sidef::DataTypes::Glob::Pipe') })
                     | Ref\b                          (?{ state $x = bless({}, 'Sidef::Variable::Ref') })
                     | LazyMethod\b                   (?{ state $x = bless({}, 'Sidef::DataTypes::Variable::LazyMethod') })
                     | Complex\b                      (?{ state $x = bless({}, 'Sidef::DataTypes::Number::Complex') })
                     | Regexp?\b                      (?{ state $x = bless({}, 'Sidef::DataTypes::Regex::Regex') })
                     | Object\b                       (?{ state $x = bless({}, 'Sidef::DataTypes::Object::Object') })
                     | Sidef\b                        (?{ state $x = bless({}, 'Sidef::DataTypes::Sidef::Sidef') })
                     | Sig\b                          (?{ state $x = Sidef::Sys::Sig->new })
                     | Sys\b                          (?{ state $x = Sidef::Sys::Sys->new })
                     | Perl\b                         (?{ state $x = Sidef::Perl::Perl->new })
                     | Math\b                         (?{ state $x = Sidef::Math::Math->new })
                     | Time\b                         (?{ state $x = Sidef::Time::Time->new })
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
                     | ∞                              (?{ state $x = Sidef::Types::Number::Inf->new })
                ) (?!::)
            }x,
            prefix_obj_re => qr{\G
              (?:
                  if\b                                       (?{ bless({}, 'Sidef::Types::Block::If') })
                | while\b                                    (?{ bless({}, 'Sidef::Types::Block::While') })
                | try\b                                      (?{ Sidef::Types::Block::Try->new })
                | foreach\b                                  (?{ bless({}, 'Sidef::Types::Block::ForEach') })
                | for\b                                      (?{ bless({}, 'Sidef::Types::Block::For') })
                | return\b                                   (?{ state $x = bless({}, 'Sidef::Types::Block::Return') })
                #| next\b                                     (?{ bless({}, 'Sidef::Types::Block::Next') })
                #| break\b                                    (?{ bless({}, 'Sidef::Types::Block::Break') })
                | read\b                                     (?{ state $x = Sidef::Sys::Sys->new })
                | goto\b                                     (?{ state $x = bless({}, 'Sidef::Perl::Builtin') })
                | (?:[*\\&]|\+\+|--)                         (?{ state $x = bless({}, 'Sidef::Variable::Ref') })
                | (?:>>?|[√+~!\-\^]|
                    (?:
                        say
                      | print
                      | defined
                    )\b)                                     (?{ state $x = bless({}, 'Sidef::Object::Unary') })
                | :                                          (?{ state $x = bless({}, 'Sidef::DataTypes::Hash::Hash') })
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
                | %p\b.                                                    (?{ [qw(0 new Sidef::Types::Glob::Pipe)] })
                | %P\b.                                                    (?{ [qw(1 new Sidef::Types::Glob::Pipe)] })

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
                | %s\b.                                                    (?{ [qw(0 __NEW__ Sidef::Module::OO)] })
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
                  MultiArray MultiArr
                  Hash
                  Str String
                  Num Number
                  RangeStr RangeString
                  RangeNum RangeNumber
                  Complex
                  Math
                  Pipe
                  Ref
                  Socket
                  Bool
                  Sys
                  Sig
                  Regex Regexp
                  Time
                  Perl
                  Sidef
                  Object
                  Parser
                  Block
                  Backtick
                  LazyMethod

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
                  if while
                  given
                  with
                  try
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

                  )
            },
            match_flags_re  => qr{[msixpogcaludn]+},
            var_name_re     => qr/[_\pL][_\pL\pN]*(?>::[_\pL][_\pL\pN]*)*/,
            method_name_re  => qr/[_\pL][_\pL\pN]*!?/,
            var_init_sep_re => qr/\G\h*(?:=>|[=:])\h*/,
            operators_re    => do {
                local $" = q{|};

                # The order matters! (in a way)
                my @operators = map { quotemeta } qw(

                  ||= ||
                  &&= &&

                  ^.. ..^

                  %%
                  ~~ !~
                  <=>
                  <<= >>=
                  << >>
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
                  ! \\
                  : « » ~
                  );

                qr{
                    (?(DEFINE)
                        (?<ops>
                              @operators
                            | \p{Block: Mathematical_Operators}
                            | \p{Block: Supplemental_Mathematical_Operators}
                        )
                    )

                      »(?<unroll>[_\pL][_\pL\pN]*|(?&ops))«          # unroll operator (e.g.: »add« or »+«)
                    | >>(?<unroll>[_\pL][_\pL\pN]*|(?&ops))<<        # unroll operator (e.g.: >>add<< or >>+<<)

                    | ~X(?<cross>(?&ops)|)                           # cross operator (e.g.: ~X or ~X+)
                    | ~Z(?<zip>(?&ops)|)                             # zip operator (e.g.: ~Z or ~Z+)

                    | »(?<map>[_\pL][_\pL\pN]*|(?&ops))»             # mapping operator (e.g.: »add» or »+»)
                    | >>(?<map>[_\pL][_\pL\pN]*|(?&ops))>>           # mapping operator (e.g.: >>add>> or >>+>>)

                    | «(?<pam>[_\pL][_\pL\pN]*|(?&ops))«             # reverse mapping operator (e.g.: «add« or «+«)
                    | <<(?<pam>[_\pL][_\pL\pN]*|(?&ops))<<           # reverse mapping operator (e.g.: <<add<< or <<+<<)

                    | <<(?<reduce>[_\pL][_\pL\pN]*|(?&ops))>>        # reduce operator (e.g.: <<add>> or <<+>>)
                    | «(?<reduce>[_\pL][_\pL\pN]*|(?&ops))»          # reduce operator (e.g.: «add» or «+»)

                    | \^(?<op>[_\pL][_\pL\pN]*[!:?]?)\^              # method-like operator (e.g.: ^add^)
                    | (?<op>(?&ops))                                 # primitive operator   (e.g.: +, -, *, /)
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

        my $start      = rindex($opt{code}, "\n", $opt{pos}) + 1;
        my $point      = $opt{pos} - $start;
        my $error_line = (split(/\R/, substr($opt{code}, $start, 80)))[0];

        my @lines = (
                     "HAHA! That's really funny! You got me!",
                     "I thought that... Oh, you got me!",
                     "LOL! I expected... Oh, my! This is funny!",
                     "Oh, oh... Wait a second! Did you mean...? Damn!",
                     "You're emberesing me! That's not funny!",
                     "My brain just exploded.",
                     "Sorry, I don't know how to help in this situation.",
                     "I'm broken. Fix me, or show this to someone who can fix",
                     "Huh?",
                     "Out of order",
                     "You must be joking.",
                     "Ouch, That HURTS!",
                     "Who are you!?",
                     "Death before dishonour?",
                     "Good afternoon, gentelman, I'm a HAL 9000 Computer",
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

        state $x = require File::Basename;
        my $basename = File::Basename::basename($0);

        my $error = sprintf("%s: %s\n\nFile : %s\nLine : %s\nError: %s\n\n" . ("~" x 80) . "\n%s\n",
                            $basename,
                            $lines[rand @lines],
                            $self->{file_name} // '-',
                            $self->{line}, join(', ', grep { defined } $opt{error}, $opt{reason}), $error_line,);

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

            if (my @candidates = Sidef::best_matches($name, \@names)) {
                $error .= ("[?] Did you mean: " . join("\n" . (' ' x 18), sort @candidates) . "\n");
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
                elsif ($self->{interactive}) {

                    # Minor exception for interactive mode
                    if (ref $variable->{obj} eq 'HASH') {
                        ++$variable->{obj}{in_use};
                    }

                }
                elsif (   $variable->{count} == 0
                       && $variable->{type} ne 'class'
                       && $variable->{type} ne 'func'
                       && $variable->{type} ne 'method'
                       && $variable->{type} ne 'global'
                       && $variable->{name} ne 'self'
                       && $variable->{name} ne ''
                       && chr(ord $variable->{name}) ne '_') {

                    warn '[WARN] '
                      . "$variable->{type} '$variable->{name}' has been declared, but not used again, at "
                      . "$self->{file_name}, line $variable->{line}\n";
                }
                elsif ($DEBUG) {
                    warn "[WARN] Variable '$variable->{name}' is used $variable->{count} times!\n";
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
                               error => qq{can't find the beginning of a string quote delimitator},
                               code  => $_,
                               pos   => pos($_),
                              );
        }

        my $beg_delim = quotemeta $delim;
        my $pair_delim = exists($self->{delim_pairs}{$delim}) ? $self->{delim_pairs}{$delim} : ();

        my $string = '';
        if (defined $pair_delim) {
            my $end_delim = quotemeta $pair_delim;
            my $re_delim  = $beg_delim . $end_delim;
            if (m{\G(?<main>$beg_delim((?>[^$re_delim\\]+|\\.|(?&main))*+)$end_delim)}sgc) {
                $string = $2 =~ s/\\([$re_delim])/$1/gr;
            }
        }
        elsif (m{\G$beg_delim([^\\$beg_delim]*+(?>\\.[^\\$beg_delim]*)*)}sgc) {
            $string = $1 =~ s/\\([$beg_delim])/$1/gr;
        }

        (defined($pair_delim) ? /\G(?<=\Q$pair_delim\E)/ : /\G$beg_delim/gc)
          || $self->fatal_error(
                                error => sprintf(qq{can't find the quoted string terminator <%s>}, $pair_delim // $delim),
                                code  => $_,
                                pos   => pos($_)
                               );

        $self->{line} += $string =~ s/\R\K//g if not $opt{no_count_line};
        return $string;
    }

    ## get_method_name() returns the following values:
    # 1st: method/operator (or undef)
    # 2nd: does operator require and argument (0 or 1)
    # 3rd: type of operator (e.g.: »+« is "uop", [+] is "rop")
    sub get_method_name {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        # Parse whitespace
        $self->parse_whitespace(code => $opt{code});

        # Alpha-numeric method name
        if (/\G($self->{method_name_re})/goc) {
            return ($1, 0, '');
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

        while (   /\G(?<type>$self->{var_name_re}(?:\h+|\h*>>?\h*)$self->{var_name_re})\h*/goc
               || /\G([*:]?$self->{var_name_re})\h*/goc
               || (defined($end_delim) && /\G(?=[({])/)) {
            push @vars, $1;

            if ($opt{with_vals} && defined($end_delim)) {

                # Add the variables into the symbol table
                my ($name, $class_name) = $self->get_name_and_class($vars[-1]);

                undef $classes{$class_name};
                unshift @{$self->{vars}{$class_name}},
                  {
                    obj   => '',
                    name  => $name,
                    count => 0,
                    type  => $opt{type},
                    line  => $self->{line},
                  };

                if (/\G<<?\h*/gc) {
                    my ($var) = /\G($self->{var_name_re})\h*/goc;
                    $var // $self->fatal_error(
                                               code  => $_,
                                               pos   => pos($_),
                                               error => 'expected a subset name',
                                              );
                    $vars[-1] .= " < $var ";
                }

                if (/\G(?=\{)/) {
                    my $code = substr($_, pos);
                    $self->parse_block(code => \$code, topic_var => 1);
                    $vars[-1] .= substr($_, pos($_), pos($code));
                    pos($_) += pos($code);
                }
                elsif (/\G(?=\()/) {
                    my $code = substr($_, pos);
                    $self->parse_arg(code => \$code);
                    $vars[-1] .= substr($_, pos($_), pos($code));
                    pos($_) += pos($code);
                }

                if (/$self->{var_init_sep_re}/goc) {
                    my $code = substr($_, pos);
                    $code =~ /^(?=\()/
                      ? $self->parse_arg(code => \$code)
                      : $self->parse_obj(code => \$code);
                    $vars[-1] .= '=' . substr($_, pos($_), pos($code));
                    pos($_) += pos($code);
                }
            }

            (defined($end_delim) && /\G\h*,\h*/gc) || last;
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
                                    pos   => pos,
                                    error => "can't find the closing delimiter: '$end_delim'",
                                   )
             );

        return \@vars;
    }

    sub parse_init_vars {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        my $end_delim = $self->parse_delim(%opt);

        my @var_objs;
        while (   /\G(?<type>$self->{var_name_re})(?:\h+|\h*>>?\h*)($self->{var_name_re})\h*/goc
               || /\G([*:]?)($self->{var_name_re})\h*/goc
               || (defined($end_delim) && /\G(?=[({])/)) {
            my ($attr, $name) = ($1, $2);

            my $ref_type;
            if (defined($+{type})) {
                my $type = $+{type};
                my $obj = $self->parse_expr(code => \$type);

                if (not defined($obj) or ref($obj) eq 'HASH') {
                    $self->fatal_error(
                                       code   => $_,
                                       pos    => pos,
                                       error  => "invalid type <<$type>> for variable '$name'",
                                       reason => "expected a type, such as: Str, Num, File, etc...",
                                      );
                }

                $ref_type = $obj;
            }

            my $class_name;
            ($name, $class_name) = $self->get_name_and_class($name);

            if (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name})) {
                $self->fatal_error(
                                   code  => $_,
                                   pos   => $-[2],
                                   error => "'$name' is either a keyword or a predefined variable!",
                                  );
            }

            my ($subset, $subset_blocks);
            if (defined($end_delim) and /\G<<?\h*/gc) {
                my ($name) = /\G($self->{var_name_re})/goc;

                $name // $self->fatal_error(
                                            code  => $_,
                                            pos   => pos($_),
                                            error => "expected the name of the subset",
                                           );

                my $code = $name;
                my $obj = $self->parse_expr(code => \$code);

                (defined($obj) and ref($obj) ne 'HASH')
                  || $self->fatal_error(
                                        code  => $_,
                                        pos   => pos($_),
                                        error => "expected a subset or a type",
                                       );

                $subset = $obj;

                if (ref($obj) eq 'Sidef::Variable::Subset' and exists($obj->{blocks})) {
                    $subset_blocks = $obj->{blocks};
                }
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
                    my $obj = (
                               /\G(?=\()/
                               ? $self->parse_arg(code => $opt{code})
                               : $self->parse_obj(code => $opt{code})
                              );
                    $value = (
                              ref($obj) eq 'HASH'
                              ? $obj
                              : {$self->{class} => [{self => $obj}]}
                             );
                }
            }

            my $obj = bless(
                            {
                             name => $name,
                             type => $opt{type},
                             (defined($ref_type) ? (ref_type => $ref_type) : ()),
                             (defined($subset)   ? (subset   => $subset)   : ()),
                             class => $class_name,
                             defined($value) ? (value => $value, has_value => 1) : (),
                             defined($attr)
                             ? ($attr eq '*' ? (array => 1, slurpy => 1) : $attr eq ':' ? (hash => 1, slurpy => 1) : ())
                             : (),
                             defined($where_block)   ? (where_block   => $where_block)   : (),
                             defined($where_expr)    ? (where_expr    => $where_expr)    : (),
                             defined($subset_blocks) ? (subset_blocks => $subset_blocks) : (),
                             $opt{in_use}            ? (in_use        => 1)              : (),
                            },
                            'Sidef::Variable::Variable'
                           );

            if (!$opt{private}) {
                unshift @{$self->{vars}{$class_name}},
                  {
                    obj   => $obj,
                    name  => $name,
                    count => 0,
                    type  => $opt{type},
                    line  => $self->{line},
                  };
            }

            push @var_objs, $obj;
            (defined($end_delim) && /\G\h*,\h*/gc) || last;

            #~ if ($obj->{slurpy}) {
            #~ $self->fatal_error(
            #~ error => "can't declare more parameters after a slurpy parameter",
            #~ code => $_,
            #~ pos => pos($_),
            #~ )
            #~ }

            $self->parse_whitespace(code => $opt{code});
        }

        $self->parse_whitespace(code => $opt{code}) if defined($end_delim);

        defined($end_delim)
          && (
              /\G\h*\Q$end_delim\E/gc
              || $self->fatal_error(
                                    code  => $_,
                                    pos   => pos,
                                    error => "can't find the closing delimiter: '$end_delim'",
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
                        my ($name, $type, $obj) = @{shift @{$self->{EOT}}};

                        my ($indent, $spaces);
                        if (chr ord $name eq '-') {
                            $name = substr($name, 1);
                            $indent = 1;
                        }

                        my $acc = '';
                        until (/\G$name(?:\R|\z)/gc) {

                            if (/\G(.*)/gc) {
                                $acc .= "$1\n";
                            }

                            # Indentation is true
                            if ($indent && /\G\R(\h+)$name(?:\R|\z)/gc) {
                                ++$self->{line};
                                $spaces = length($1);
                                last;
                            }

                            /\G\R/gc
                              ? ++$self->{line}
                              : die sprintf(qq{%s:%s: can't find string terminator "%s" anywhere before EOF.\n},
                                            $self->{file_name}, $beg_line, $name);
                        }

                        if ($indent) {
                            $acc =~ s/^\h{1,$spaces}//gm;
                        }

                        ++$self->{line};
                        push @{$obj->{$self->{class}}},
                          {
                              self => $type == 0
                            ? Sidef::Types::String::String->new($acc)
                            : Sidef::Types::String::String->new($acc)->apply_escapes($self)
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

                # Special case for backticks (add method 'exec')
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

                    push @{$struct->{$self->{class}}[-1]{call}}, {method => 'exec'};
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
            if (   /\G:([_\pL\pN]+)/gc
                || /\G([_\pL][_\pL\pN]*)(?=\h*=>)/gc) {

                # || /\G([_\pL][_\pL\pN]*)(?=\h*=>|:(?![=:]))/gc) {
                return Sidef::Types::String::String->new($1);
            }

            if (/\G([_\pL][_\pL\pN]*):(?![=:])/gc) {
                my $name = $1;
                my $obj = (
                           /\G\s*(?=\()/gc
                           ? $self->parse_arg(code => $opt{code})
                           : $self->parse_obj(code => $opt{code})
                          );
                return Sidef::Variable::NamedParam->new($name, $obj);
            }

            # Declaration of variables
            if (/\Gvar\b\h*/gc) {
                my $type     = 'var';
                my $vars     = $self->parse_init_vars(code => $opt{code}, type => $type);
                my $init_obj = bless({vars => $vars}, 'Sidef::Variable::Init');

                if (/\G\h*=\h*/gc) {
                    my $args = (
                                /\G\s*(?=\()/gc
                                ? $self->parse_arg(code => $opt{code})
                                : $self->parse_obj(code => $opt{code})
                      ) // $self->fatal_error(
                                              code  => $_,
                                              pos   => pos,
                                              error => "expected an expression after variable declaration",
                                             );

                    $init_obj->{args} = $args;
                }

                return $init_obj;
            }

            # "has" class attributes
            if (exists($self->{current_class}) and /\Ghas\b\h*/gc) {
                my $vars = $self->parse_init_vars(
                                                  code    => $opt{code},
                                                  type    => 'var',
                                                  private => 1,
                                                  in_use  => 1,
                                                 );

                foreach my $var (@{$vars}) {
                    my $name = $var->{name};
                    if (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name})) {
                        $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_) - length($name)),
                                           error => "'$name' is either a keyword or a predefined variable!",
                                          );
                    }
                }

                my $args;
                if (/\G\h*=\h*/gc) {
                    $args = $self->parse_obj(code => $opt{code});
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
                my $vars = $self->parse_init_vars(code => $opt{code}, type => $type, private => 1);

                foreach my $var (@{$vars}) {
                    my $name = $var->{name};
                    if (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name})) {
                        $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_) - length($name)),
                                           error => "'$name' is either a keyword or a predefined variable!",
                                          );
                    }
                }

                if (@{$vars} == 1 and /\G\h*=\h*/gc) {

                    my $v          = $vars->[0];
                    my $name       = $v->{name};
                    my $class_name = $v->{class};

                    my $obj = $self->parse_obj(code => $opt{code});
                    $obj // $self->fatal_error(
                                               code  => $_,
                                               pos   => pos($_) - 2,
                                               error => qq{expected an expression after $type "$name"},
                                              );

                    my $var =
                      $type eq 'define'
                      ? bless({init => 1, name => $name, class => $class_name, expr => $obj}, 'Sidef::Variable::Define')
                      : $type eq 'static'
                      ? bless({init => 1, name => $name, class => $class_name, expr => $obj}, 'Sidef::Variable::Static')
                      : $type eq 'const'
                      ? bless({init => 1, name => $name, class => $class_name, expr => $obj}, 'Sidef::Variable::Const')
                      : die "[PARSER ERROR] Invalid variable type: $type";

                    unshift @{$self->{vars}{$class_name}},
                      {
                        obj   => $var,
                        name  => $name,
                        count => 0,
                        type  => $type,
                        line  => $self->{line},
                      };

                    return $var;
                }

                my @var_objs;
                foreach my $v (@{$vars}) {

                    my $obj        = $v->{value};
                    my $name       = $v->{name};
                    my $class_name = $v->{class};

                    my $var = (
                               $type eq 'define'
                               ? bless({name => $name, class => $class_name, expr => $obj}, 'Sidef::Variable::Define')
                               : $type eq 'static'
                               ? bless({name => $name, class => $class_name, expr => $obj}, 'Sidef::Variable::Static')
                               : $type eq 'const'
                               ? bless({name => $name, class => $class_name, expr => $obj}, 'Sidef::Variable::Const')
                               : die "[PARSER ERROR] Invalid variable type: $type"
                              );

                    push @var_objs, $var;

                    unshift @{$self->{vars}{$class_name}},
                      {
                        obj   => $var,
                        name  => $name,
                        count => 0,
                        type  => $type,
                        line  => $self->{line},
                      };

                }

                return bless({vars => \@var_objs}, 'Sidef::Variable::ConstInit');
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
                                       error => "'$name' is either a keyword or a predefined variable!",
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
                                         code      => $opt{code},
                                         with_vals => 1,
                                         private   => 1,
                                         type      => 'var',
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
                                       error => "'$name' is either a keyword or a predefined variable!",
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

                        if (ref($type) eq 'Sidef::Variable::Subset') {
                            if (exists $type->{blocks}) {
                                push @{$subset->{blocks}}, @{$type->{blocks}};
                            }
                        }

                        push @{$subset->{inherits}}, $type;

                        /\G,\h*/gc && redo;
                    }
                }
                else {
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => pos($_),
                                       error => "expected a parent type (e.g.: subset $name < Number)",
                                      );
                }

                if (/\G(?=\{)/) {
                    my $block = $self->parse_block(code => $opt{code}, topic_var => 1);
                    push @{$subset->{blocks}}, $block;
                }

                return $subset;
            }

            # Declaration of enums
            if (/\Genum\b\h*/gc) {
                my $vars =
                  $self->parse_init_vars(
                                         code      => $opt{code},
                                         with_vals => 1,
                                         private   => 1,
                                         type      => 'var',
                                        );

                @{$vars}
                  || $self->fatal_error(
                                        code  => $_,
                                        pos   => pos,
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
                                           error => "'$name' is either a keyword or a predefined variable!",
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

            if (/\G\@(?!:)/gc) {
                my $pos = pos($_);
                my $obj = (
                           /\G(?=\()/
                           ? $self->parse_arg(code => $opt{code})
                           : $self->parse_obj(code => $opt{code})
                          );

                if (not defined $obj) {
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => $pos,
                                       error => "expected an expression after unary operator: '\@'",
                                      );
                }

                return {$self->{class} => [{self => $obj, call => [{method => '@*'}]}]};
            }

            # Local variables
            if (/\Glocal\b\h*/gc) {
                my $expr = $self->parse_obj(code => $opt{code});
                return bless({expr => $expr}, 'Sidef::Variable::Local');
            }

            # Declaration of local variables, classes, methods and functions
            if (
                   /\G(func|class|global)\b\h*/gc
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

                    ($name, $class_name) = $self->get_name_and_class($1);

                    if (exists($self->{built_in_classes}{$name})) {

                        my ($obj) = $self->parse_expr(code => \$name);

                        if (defined($obj)) {
                            $name         = '';
                            $built_in_obj = $obj;
                        }
                    }
                }

                if ($type ne 'class') {
                    $name = (
                               /\G($self->{var_name_re})\h*/goc ? $1
                             : $type eq 'method' && /\G($self->{operators_re})\h*/goc ? $+
                             :                                                          ''
                            );
                    ($name, $class_name) = $self->get_name_and_class($name);
                }

                local $self->{class} = $class_name;

                if (    $type ne 'method'
                    and $type ne 'class'
                    and (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name}))) {
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => $-[0],
                                       error => "'$name' is either a keyword or a predefined variable!",
                                      );
                }

                my $obj =
                  ($type eq 'func' or $type eq 'method')
                  ? bless({name => $name, type => $type, class => $class_name}, 'Sidef::Variable::Variable')
                  : $type eq 'class'
                  ? bless({name => ($built_in_obj // $name), class => $class_name}, 'Sidef::Variable::ClassInit')
                  : $type eq 'global' ? bless({name => $name, class => $class_name}, 'Sidef::Variable::Global')
                  : $self->fatal_error(
                                       error  => "invalid type",
                                       reason => "expected a magic thing to happen",
                                       code   => $_,
                                       pos    => pos($_),
                                      );

                {
                    my ($var) = $self->find_var($name, $class_name);

                    if (defined($var) and $var->{type} eq 'class') {
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

                        push @{$var->{obj}{value}{kids}}, $obj;
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

                if ($type eq 'global') {
                    return $obj;
                }

                if ($type eq 'class') {
                    my $var_names =
                      $self->parse_init_vars(
                                             code         => $opt{code},
                                             with_vals    => 1,
                                             private      => 1,
                                             in_use       => 1,
                                             type         => 'var',
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
                            my ($name) = $1;
                            if (defined(my $class = $self->find_var($name, $class_name))) {
                                if ($class->{type} eq 'class') {
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
                                                   error  => "Inheritance from built-in classes is not allowed",
                                                   reason => "`$name` is a built-in class",
                                                   code   => $_,
                                                   pos    => pos($_) - length($name) - 1,
                                                  );

                                #if ($name ne 'Sidef') {
                                #    my $ref = $self->parse_expr(code => \$name);
                                #    push @{$obj->{inherit}}, ref($ref);
                                #}
                            }
                            else {
                                $self->fatal_error(
                                                   error  => "can't find '$name' class",
                                                   reason => "expected an existent class name",
                                                   var    => $name,
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

                    local $self->{class_name} = (defined($built_in_obj) ? ref($built_in_obj) : $obj->{name});
                    local $self->{current_class} = $built_in_obj // $obj;
                    my $block = $self->parse_block(code => $opt{code});

                    # Set the block of the class
                    $obj->{block} = $block;
                }

                if ($type eq 'func' or $type eq 'method') {

                    my $var_names =
                      $self->get_init_vars(
                                           code         => $opt{code},
                                           with_vals    => 1,
                                           ignore_delim => {
                                                            '{' => 1,
                                                            '-' => 1,
                                                           }
                                          );

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
                                            error  => "invalid '$type' declaration",
                                            reason => "expected: $type $name(...){...}",
                                            code   => $_,
                                            pos    => pos($_)
                                           );

                    local $self->{$type eq 'func' ? 'current_function' : 'current_method'} = $has_kids ? $parent : $obj;
                    my $args = '|' . join(',', $type eq 'method' ? 'self' : (), @{$var_names}) . ' |';

                    my $code = '{' . $args . substr($_, pos);
                    my $block = $self->parse_block(code => \$code);
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
                             ? $self->parse_block(code => $opt{code})
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
                             ? $self->parse_block(code => $opt{code})
                             : $self->fatal_error(
                                                  error => "expected a block after `case(expr)`",
                                                  code  => $_,
                                                  pos   => pos($_),
                                                 )
                            );

                return bless({expr => $expr, block => $block}, 'Sidef::Types::Block::Case');
            }

            # "default {...}" construct
            if (exists($self->{current_given}) && /\Gdefault\h*(?=\{)/gc) {
                my $block = $self->parse_block(code => $opt{code});
                return bless({block => $block}, 'Sidef::Types::Block::Default');
            }

            # "with(expr) {...}" construct
            if (/\Gwith\b\h*/gc) {
                my $expr = (
                            /\G(?=\()/
                            ? $self->parse_arg(code => $opt{code})
                            : $self->parse_obj(code => $opt{code})
                           );

                $expr // $self->fatal_error(
                                            error  => "invalid declaration of the `with` construct",
                                            reason => "expected `with(expr) {...}`",
                                            code   => $_,
                                            pos    => pos($_),
                                           );

                my $block = (
                             /\G\h*(?=\{)/gc
                             ? $self->parse_block(code => $opt{code}, topic_var => 1)
                             : $self->fatal_error(
                                                  error => "expected a block after `with(expr)`",
                                                  code  => $_,
                                                  pos   => pos($_),
                                                 )
                            );

                return bless({expr => $expr, block => $block}, 'Sidef::Types::Block::With');
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

            # Binary, hexdecimal and octal numbers
            if (/\G0(b[10_]*|x[0-9A-Fa-f_]*|[0-9_]+\b)/gc) {
                return Sidef::Types::Number::Number->new("0" . ($1 =~ tr/_//dr), 0);
            }

            # Integer or float number
            if (/\G([+-]?+(?=\.?[0-9])[0-9_]*+(?:\.[0-9_]++)?(?:[Ee](?:[+-]?+[0-9_]+))?)/gc) {
                return Sidef::Types::Number::Number->new($1 =~ tr/_//dr);
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

            # Implicit method call on special variable: _
            if (/\G\./) {

                if (defined(my $var = $self->find_var('_', $self->{class}))) {
                    $var->{count}++;
                    ref($var->{obj}) eq 'Sidef::Variable::Variable' && do {
                        $var->{obj}{in_use} = 1;
                    };
                    return $var->{obj};
                }

                $self->fatal_error(
                                   code  => $_,
                                   pos   => pos($_),
                                   error => q{attempt to use an implicit method call on the uninitialized variable: "_"},
                                  );
            }

            # Quoted words or numbers (%w/a b c/)
            if (/\G%([wWin])\b/gc || /\G(?=(«|<(?!<)))/) {
                my ($type) = $1;
                my $strings = $self->get_quoted_words(code => $opt{code});

                if ($type eq 'w' or $type eq '<') {
                    return Sidef::Types::Array::Array->new(
                                                [map { Sidef::Types::String::String->new(s{\\(?=[\\#\s])}{}gr) } @{$strings}]);
                }
                elsif ($type eq 'i') {
                    return Sidef::Types::Array::Array->new(
                                           [map { Sidef::Types::Number::Number->new(s{\\(?=[\\#\s])}{}gr)->int } @{$strings}]);
                }
                elsif ($type eq 'n') {
                    return Sidef::Types::Array::Array->new(
                                                [map { Sidef::Types::Number::Number->new(s{\\(?=[\\#\s])}{}gr) } @{$strings}]);
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

                return
                  bless(
                        {
                         expr          => $obj,
                         vars          => {$self->{class} => [@{$self->{vars}{$self->{class}}}]},
                         ref_vars_refs => {$self->{class} => [@{$self->{ref_vars_refs}{$self->{class}}}]},
                        },
                        'Sidef::Eval::Eval'
                       );
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
                return Sidef::Types::String::String->new($self->{script_name});
            }

            if (/\G__FILE__\b/gc) {
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
            if (/\G<<(?=\S)/gc) {
                my ($name, $type) = (undef, 1);

                if (/\G(?=(['"„]))/) {
                    $type = 0 if $1 eq q{'};
                    my $str = $self->get_quoted_string(code => $opt{code});
                    $name = $str;
                }
                elsif (/\G(-?[_\pL\pN]+)/gc) {
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
                push @{$self->{EOT}}, [$name, $type, $obj];

                return $obj;
            }

            if (exists($self->{current_block}) && /\G__BLOCK__\b/gc) {
                return $self->{current_block};
            }

            if (/\G__NAMESPACE__\b/gc) {
                return Sidef::Types::String::String->new($self->{class});
            }

            if (exists($self->{current_function})) {
                /\G__FUNC__\b/gc && return $self->{current_function};
                /\G__FUNC_NAME__\b/gc && return Sidef::Types::String::String->new($self->{current_function}{name});
            }

            if (exists($self->{current_class})) {
                /\G__CLASS__\b/gc && return $self->{current_class};
                /\G__CLASS_NAME__\b/gc && return Sidef::Types::String::String->new($self->{class_name});
            }

            if (exists($self->{current_method})) {
                /\G__METHOD__\b/gc && return $self->{current_method};
                /\G__METHOD_NAME__\b/gc && return Sidef::Types::String::String->new($self->{current_method}{name});
            }

            # Variable call
            if (/\G($self->{var_name_re})/goc) {
                my ($name, $class) = $self->get_name_and_class($1);

                if (defined(my $var = $self->find_var($name, $class))) {
                    $var->{count}++;
                    ref($var->{obj}) eq 'Sidef::Variable::Variable' && do {
                        $var->{obj}{in_use} = 1;
                    };
                    return $var->{obj};
                }

                if ($name eq 'ARGV' or $name eq 'ENV') {

                    my $type = 'var';
                    my $variable =
                      bless({name => $name, type => $type, class => $class, in_use => 1}, 'Sidef::Variable::Variable');

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
                state $x = require List::Util;
                if (
                    ref($self->{current_class}) eq 'Sidef::Variable::ClassInit'
                    and defined(
                                my $var = List::Util::first(
                                                            sub { $_->{name} eq $name },
                                                            @{$self->{current_class}{vars}},
                                                            map { @{$_->{vars}} } @{$self->{current_class}{attributes}}
                                                           )
                               )
                  ) {
                    if (exists $self->{current_method}) {
                        if (defined(my $var = $self->find_var('self', $class))) {

                            if ($self->{opt}{k}) {
                                print STDERR
                                  "[INFO] `$name` is interpreted as `self.$name` at $self->{file_name} line $self->{line}\n";
                            }

                            $var->{count}++;
                            $var->{obj}{in_use} = 1;
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
                    else {
                        return $var;
                    }
                }

                if (/\G(?=\h*:?=(?![=~>]))/) {

                    my $var = bless({name => $name, class => $class}, 'Sidef::Variable::Global');

                    if (not $self->{interactive}) {
                        warn "[WARN] Implicit declaration of global variable '$name', at line $self->{line}\n";
                    }

                    unshift @{$self->{vars}{$class}},
                      {
                        obj   => $var,
                        name  => $name,
                        count => 0,
                        type  => 'global',
                        line  => $self->{line},
                      };

                    return $var;
                }

                # Method call in functional style
                if ($class eq $self->{class} or $class eq 'CORE') {

                    if ($self->{opt}{k}) {
                        print STDERR
                          "[INFO] `$name` is interpreted as a prefix method-call at $self->{file_name} line $self->{line}\n";
                    }

                    my $pos = pos($_);
                    /\G\h*/gc;    # remove any horizontal whitespace
                    my $arg = (
                                 /\G(?=\()/ ? $self->parse_arg(code => $opt{code})
                               : /\G(?=\{)/ ? $self->parse_block(code => $opt{code}, topic_var => 1)
                               : $self->fatal_error(
                                                    code  => $_,
                                                    pos   => ($pos - length($name)),
                                                    var   => $name,
                                                    error => "variable <$name> is not declared in the current scope",
                                                   )
                              );

                    if (ref($arg) and ref($arg) ne 'HASH') {
                        return
                          scalar {
                                  $self->{class} => [
                                                     {
                                                      self => $arg,
                                                      call => [{method => $name}]
                                                     }
                                                    ]
                                 };
                    }
                    elsif (ref($arg) eq 'HASH') {
                        if (not exists($arg->{$self->{class}})) {
                            $self->fatal_error(
                                               code  => $_,
                                               pos   => ($pos - length($name)),
                                               var   => $name,
                                               error => "attempt to call method <$name> on an undefined object",
                                              );
                        }

                        return scalar {
                            $self->{class} => [
                                {
                                 self => {
                                          $self->{class} => [{%{shift(@{$arg->{$self->{class}}})}}]
                                         },
                                 call => [
                                     {
                                      method => $name,
                                      (
                                       @{$arg->{$self->{class}}}
                                       ? (
                                          arg => [
                                              map {
                                                  { $self->{class} => [{%{$_}}] }
                                                } @{$arg->{$self->{class}}}
                                          ]
                                         )
                                       : ()
                                      ),
                                     }
                                 ],
                                }
                            ]
                        };
                    }
                }

                # Undeclared variable
                $self->fatal_error(
                                   code  => $_,
                                   var   => $name,
                                   pos   => (pos($_) - length($name)),
                                   error => "variable <$name> is not declared in the current scope",
                                  );
            }

            # Regex variables ($1, $2, ...)
            if (/\G\$([0-9]+)\b/gc) {
                $self->fatal_error(
                                   code  => $_,
                                   pos   => (pos($_) - length($1)),
                                   error => "attempt to use the deprecated regex variables",
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
                                    error => "unbalanced parentheses",
                                   );

            return $obj;
        }
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
                                    error => "unbalanced right brackets",
                                   );

            return $obj;
        }
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
                                    error => "unbalanced curly brackets",
                                   );

            return $obj;
        }
    }

    sub parse_block {
        my ($self, %opt) = @_;

        local *_ = $opt{code};
        if (/\G\{/gc) {

            my $p = pos($_);
            local $self->{curly_brackets} = 1;

            my $ref = $self->{vars}{$self->{class}} //= [];
            my $count = scalar(@{$self->{vars}{$self->{class}}});

            unshift @{$self->{ref_vars_refs}{$self->{class}}}, @{$ref};
            unshift @{$self->{vars}{$self->{class}}}, [];

            $self->{vars}{$self->{class}} = $self->{vars}{$self->{class}}[0];

            my $block = bless({}, 'Sidef::Types::Block::BlockInit');

            # Parse whitespace (if any)
            $self->parse_whitespace(code => $opt{code});

            my $has_vars;
            my $var_objs = [];
            if (/\G(?=\|)/) {
                $has_vars = 1;
                $var_objs = $self->parse_init_vars(code => $opt{code},
                                                   type => 'var',);
            }

            # Special '_' variable
            if ($opt{topic_var} and not $has_vars) {
                my $var_obj = bless({name => '_', type => 'var', class => $self->{class}}, 'Sidef::Variable::Variable');

                push @{$var_objs}, $var_obj;
                unshift @{$self->{vars}{$self->{class}}},
                  {
                    obj   => $var_obj,
                    name  => '_',
                    count => 0,
                    type  => 'var',
                    line  => $self->{line},
                  };
            }

            local $self->{current_block} = $block if ($opt{topic_var} || $has_vars);

            my $obj = $self->parse_script(code => $opt{code});

            $self->{curly_brackets}
              && $self->fatal_error(
                                    code  => $_,
                                    pos   => $p - 1,
                                    error => "unbalanced curly brackets",
                                   );

            #$block->{vars} = [
            #    map { $_->{obj} }
            #    grep { ref($_) eq 'HASH' and ref($_->{obj}) eq 'Sidef::Variable::Variable' } @{$self->{vars}{$self->{class}}}
            #];

            $block->{init_vars} = bless({vars => $var_objs}, 'Sidef::Variable::Init');

            $block->{code} = $obj;
            splice @{$self->{ref_vars_refs}{$self->{class}}}, 0, $count;
            $self->{vars}{$self->{class}} = $ref;

            return $block;
        }
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

        {
            if ((/\G(?![-=]>)/ && /\G(?=$self->{operators_re})/o) || /\G(\.|\s*(?!\.\.)\.)/gc) {
                my ($method, $req_arg, $op_type) = $self->get_method_name(code => $opt{code});

                if (defined($method)) {

                    my $has_arg;
                    if (/\G\h*(?=[({])/gc || $req_arg) {

                        my $code = substr($_, pos);
                        my $arg = (
                                     /\G(?=\()/ ? $self->parse_arg(code => \$code)
                                   : $req_arg ? $self->parse_obj(code => \$code)
                                   : /\G(?=\{)/ ? $self->parse_block(code => \$code, topic_var => 1)
                                   :              die "[PARSING ERROR] Something is wrong in the if condition"
                                  );

                        if (defined $arg) {
                            pos($_) += pos($code);
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
                                               pos   => pos($_) - 1,
                                               error => "operator '$method' requires a right-side argument",
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

            $struct->{$self->{class}}[-1]{self} = {
                        $self->{class} => [
                            {
                             self => $struct->{$self->{class}}[-1]{self},
                             exists($struct->{$self->{class}}[-1]{call}) ? (call => delete $struct->{$self->{class}}[-1]{call})
                             : (),
                             exists($struct->{$self->{class}}[-1]{ind}) ? (ind => delete $struct->{$self->{class}}[-1]{ind})
                             : (),
                            }
                        ]
            };
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

                $struct->{$self->{class}}[-1]{self} = {
                        $self->{class} => [
                            {
                             self => $struct->{$self->{class}}[-1]{self},
                             exists($struct->{$self->{class}}[-1]{call}) ? (call => delete $struct->{$self->{class}}[-1]{call})
                             : (),
                             exists($struct->{$self->{class}}[-1]{ind}) ? (ind => delete $struct->{$self->{class}}[-1]{ind})
                             : (),
                            }
                        ]
                };

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

    sub parse_obj {
        my ($self, %opt) = @_;

        my %struct;
        local *_ = $opt{code};

        my ($obj, $obj_key, $method) = $self->parse_expr(code => $opt{code});

        if (defined $obj) {
            push @{$struct{$self->{class}}}, {self => $obj};

            # for var in array { ... }
            if (ref($obj) eq 'Sidef::Types::Block::For' and /\G\h*(?=[*:]?$self->{var_name_re})/goc) {

                my $class_name = $self->{class};
                my $vars_end   = $#{$self->{vars}{$class_name}};

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

                /\G\h*in\h*/gc
                  || $self->fatal_error(
                                        error => "expected the token 'in' after variable declaration in for-loop",
                                        code  => $_,
                                        pos   => pos($_),
                                       );

                my $expr = (
                            /\G(?=\()/
                            ? $self->parse_arg(code => $opt{code})
                            : $self->parse_obj(code => $opt{code})
                           );

                my $block = (
                             /\G\h*(?=\{)/gc
                             ? $self->parse_block(code => $opt{code})
                             : $self->fatal_error(
                                                  error => "expected a block after the token 'in': for (...) in { ... }",
                                                  code  => $_,
                                                  pos   => pos($_),
                                                 )
                            );

                # Remove the for-loop variables from the current scope
                splice(@{$self->{vars}{$class_name}},
                       $#{$self->{vars}{$class_name}} - $vars_end - scalar(@vars),
                       scalar(@vars));

                # Store the info
                $obj->{vars}  = \@vars;
                $obj->{block} = $block;
                $obj->{expr}  = $expr;

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
                            my $block = $self->parse_block(code => $opt{code});
                            push @{$obj->{if}}, {expr => $arg, block => $block};

                          ELSIF: {
                                if (/\G(?=\s*elsif\h*\()/) {
                                    $self->parse_whitespace(code => $opt{code});
                                    while (/\G\h*elsif\h*(?=\()/gc) {
                                        my $arg = $self->parse_arg(code => $opt{code});
                                        $self->parse_whitespace(code => $opt{code});
                                        my $block = $self->parse_block(code => $opt{code});
                                        push @{$obj->{if}}, {expr => $arg, block => $block};
                                        redo ELSIF;
                                    }
                                }
                            }

                            if (/\G(?=\s*else\h*\{)/) {
                                $self->parse_whitespace(code => $opt{code});
                                /\Gelse\h*/gc;
                                my $block = $self->parse_block(code => $opt{code});
                                $obj->{else}{block} = $block;
                            }
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
                    elsif (ref($obj) eq 'Sidef::Types::Block::While') {
                        if (/\G\h*(?=\{)/gc) {
                            my $block = $self->parse_block(code => $opt{code});
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
                elsif (ref($obj) ne 'Sidef::Types::Block::Return') {
                    $self->fatal_error(
                                       code  => $_,
                                       error => "expected an argument. Did you mean '$method()' instead?",
                                       pos   => pos($_) - 1,
                                      );
                }
            }

            {
                if (/\G\h*(?=\.\h*(?:$self->{method_name_re}|[(\$]))/ogc) {
                    my $methods = $self->parse_methods(code => $opt{code});
                    push @{$struct{$self->{class}}[-1]{call}}, @{$methods};
                }

                if (/\G\h*\.?(\@)\h*(?=[\[\{])/gc) {
                    push @{$struct{$self->{class}}[-1]{call}}, {method => $1};
                    redo;
                }

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

                # Try-catch construct
                if (ref($obj) eq 'Sidef::Types::Block::Try') {
                    $self->parse_whitespace(code => $opt{code});
                    if (/\G\h*catch\b/gc) {
                        my $arg = $self->parse_obj(code => $opt{code});
                        push @{$struct{$self->{class}}[-1]{call}}, {method => 'catch', arg => [$arg]};
                    }
                }

                # Parse array and hash fetchers ([...] and {...})
                $self->parse_suffixes(code => $opt{code}, struct => \%struct) && redo;

                if (/\G(?!\h*[=-]>)/ && /\G(?=$self->{operators_re})/o) {
                    my ($method, $req_arg, $op_type) = $self->get_method_name(code => $opt{code});

                    my $has_arg;
                    if ($req_arg) {
                        my $lonely_obj = /\G\h*(?=\()/gc;

                        my $code = substr($_, pos);
                        my $arg = (
                                     $lonely_obj
                                   ? $self->parse_arg(code => \$code)
                                   : $self->parse_obj(code => \$code)
                                  );

                        if (defined $arg) {
                            pos($_) += pos($code);
                            if (ref $arg ne 'HASH') {
                                $arg = {$self->{class} => [{self => $arg}]};
                            }

                            if (not $lonely_obj) {
                                my $methods = $self->parse_methods(code => $opt{code});
                                if (@{$methods}) {
                                    push @{$arg->{$self->{class}}[-1]{call}}, @{$methods};
                                }
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
                                               pos   => pos($_) - 1,
                                               error => "operator '$method' requires a right-side argument",
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

            # Module declaration
            if (/\Gmodule\b\h*/gc) {
                my $name =
                  /\G($self->{var_name_re})\h*/goc
                  ? $1
                  : $self->fatal_error(
                                       error  => "invalid 'module' declaration",
                                       reason => "expected a name",
                                       code   => $_,
                                       pos    => pos($_)
                                      );

                /\G\h*\{\h*/gc
                  || $self->fatal_error(
                                        error  => "invalid module declaration",
                                        reason => "expected: module $name {...}",
                                        code   => $_,
                                        pos    => pos($_)
                                       );

                my $parser = __PACKAGE__->new(
                                              opt         => $self->{opt},
                                              file_name   => $self->{file_name},
                                              script_name => $self->{script_name},
                                             );
                local $parser->{line}  = $self->{line};
                local $parser->{class} = $name;
                local $parser->{ref_vars}{$name} = $self->{ref_vars}{$name} if exists($self->{ref_vars}{$name});

                if ($name ne 'main' and not grep $_ eq $name, @Sidef::NAMESPACES) {
                    unshift @Sidef::NAMESPACES, $name;
                }

                my $code = '{' . substr($_, pos);
                my ($struct, $pos) = $parser->parse_block(code => \$code);
                pos($_) += pos($code) - 1;
                $self->{line} = $parser->{line};

                foreach my $class (keys %{$struct->{code}}) {
                    push @{$struct{$class}}, @{$struct->{code}{$class}};
                    if (exists $self->{ref_vars}{$class}) {
                        unshift @{$self->{ref_vars}{$class}}, @{$parser->{ref_vars}{$class}[0]};
                    }
                    else {
                        push @{$self->{ref_vars}{$class}},
                          @{
                              $#{$parser->{ref_vars}{$class}} == 0 && ref($parser->{ref_vars}{$class}[0]) eq 'ARRAY'
                            ? $parser->{ref_vars}{$class}[0]
                            : $parser->{ref_vars}{$class}
                           };
                    }
                }

                redo;
            }

            if (/\Gimport\b\h*/gc) {

                my $var_names =
                  $self->get_init_vars(code      => $opt{code},
                                       with_vals => 0);

                @{$var_names}
                  || $self->fatal_error(
                                        code  => $_,
                                        pos   => (pos($_)),
                                        error => "expected a variable-like name for importing!",
                                       );

                foreach my $var_name (@{$var_names}) {
                    my ($name, $class) = $self->get_name_and_class($var_name);

                    if ($class eq $self->{class}) {
                        $self->fatal_error(
                                           code  => $_,
                                           pos   => pos($_),
                                           error => "can't import '${class}::${name}' inside the same class",
                                          );
                    }

                    my $var = $self->find_var($name, $class);

                    if (not defined $var) {
                        $self->fatal_error(
                                           code  => $_,
                                           pos   => pos($_),
                                           error => "variable '${class}::${name}' hasn't been declared",
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

                redo;
            }

            if (/\G\@:([\pL_][\pL\pN_]*)/gc) {
                push @{$struct{$self->{class}}}, {self => bless({name => $1}, 'Sidef::Variable::Label')};
                redo;
            }

            if (/\Ginclude\b\h*/gc) {

                my @abs_filenames;
                if (/\G($self->{var_name_re})/gc) {

                    my $var_name = $1;
                    next if exists $Sidef::INCLUDED{$var_name};

                    state $x = require File::Spec;
                    my @path = split(/::/, $var_name);
                    my $mod_path = File::Spec->catfile(@path[0 .. $#path - 1], $path[-1] . '.sm');

                    $Sidef::INCLUDED{$var_name} = $mod_path;

                    if (@{$self->{inc}} == 0) {
                        state $y = require File::Basename;
                        push @{$self->{inc}}, split(':', $ENV{SIDEF_INC}) if exists($ENV{SIDEF_INC});
                        push @{$self->{inc}},
                          File::Spec->catdir(File::Basename::dirname(File::Spec->rel2abs($0)),
                                             File::Spec->updir, 'share', 'sidef');
                        push @{$self->{inc}}, File::Basename::dirname(File::Spec->rel2abs($self->{script_name}));
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
                          pos   => pos($_),
                          error => "can't find the module '${mod_path}' anywhere in ['" . join("', '", @{$self->{inc}}) . "']",
                    );

                    push @abs_filenames, [$full_path, $var_name];
                }
                else {

                    my $expr = do {
                        my $code = substr($_, pos);
                        my ($obj) = $self->parse_expr(code => \$code);
                        pos($_) += pos($code);
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
                        my $value = $_;
                        do {
                            $value = $value->get_value;
                        } while (index(ref($value), 'Sidef::') == 0);

                        ref($value) ne ''
                          ? $self->fatal_error(
                               code  => $_,
                               pos   => pos($_),
                               error => 'include-error: invalid value of type "' . ref($value) . '" (expected a plain-string)',
                          )
                          : [$value];
                    } @files;
                }

                foreach my $pair (@abs_filenames) {

                    my ($full_path, $name) = @{$pair};

                    open(my $fh, '<:utf8', $full_path)
                      || $self->fatal_error(
                                            code  => $_,
                                            pos   => pos($_),
                                            error => "can't open file '$full_path': $!"
                                           );

                    my $content = do { local $/; <$fh> };
                    close $fh;

                    my $parser = __PACKAGE__->new(
                                                  opt         => $self->{opt},
                                                  file_name   => $full_path,
                                                  script_name => $self->{script_name},
                                                 );

                    local $parser->{class} = $name if defined $name;
                    if (defined $name and $name ne 'main' and not grep $_ eq $name, @Sidef::NAMESPACES) {
                        unshift @Sidef::NAMESPACES, $name;
                    }
                    my $struct = $parser->parse_script(code => \$content);

                    foreach my $class (keys %{$struct}) {
                        if (defined $name) {
                            $struct{$class} = $struct->{$class};
                            $self->{ref_vars}{$class} = $parser->{ref_vars}{$class};
                        }
                        else {
                            push @{$struct{$class}}, @{$struct->{$class}};
                            unshift @{$self->{ref_vars}{$class}}, @{$parser->{ref_vars}{$class}};
                        }
                    }
                }

                redo;
            }

            if (/\G(?:[;,]+|=>)/gc) {
                redo;
            }

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
                                        pos    => pos($_) - 1,
                                        error  => "invalid usage of the ternary operator",
                                        reason => "expected ':'",
                                       );

                $self->parse_whitespace(code => $opt{code});

                my $false = (
                             /\G(?=\()/
                             ? $self->parse_arg(code => $opt{code})
                             : $self->parse_obj(code => $opt{code})
                            );

                my $tern = bless(
                                 {
                                  cond  => scalar {$self->{class} => [pop @{$struct{$self->{class}}}]},
                                  true  => $true,
                                  false => $false
                                 },
                                 'Sidef::Types::Bool::Ternary'
                                );

                push @{$struct{$self->{class}}}, {self => $tern};
                redo MAIN;
            }

            my $obj = $self->parse_obj(code => $opt{code});

            if (defined $obj) {
                push @{$struct{$self->{class}}}, {self => $obj};

                {

                    my $pos_before = pos($_);
                    $self->parse_whitespace(code => $opt{code});
                    my $pos_after = pos($_);

                    my $has_newline = substr($_, $pos_before, $pos_after - $pos_before) =~ /\R/;

                    if (/\G(?:[;,]+|=>)/gc) {
                        redo MAIN;
                    }

                    state $bin_ops = {
                        map { $_ => 1 }
                          qw(
                          &&=
                          ||=
                          \\=
                          //=
                          :=

                          &&
                          ||
                          \\
                          //

                          += -= *= /=
                          |= &= ^= %=
                          =~
                          ==
                          ~~
                          !~
                          !=
                          )
                    };

                    my $is_operator = /\G(?!->)/ && /\G(?=($self->{operators_re}))/o;
                    my $op = $1;

                    if (
                           ($is_operator && defined($op) && exists $bin_ops->{$op})
                        || (!$has_newline && $is_operator)
                        || /\G(?:->|\.)\h*/gc

                        #|| /\G(?=$self->{method_name_re})/o
                      ) {

                        # Implicit end of statement -- redo
                        $self->parse_whitespace(code => $opt{code});

                        my $methods;
                        if ($is_operator) {
                            $methods = $self->parse_methods(code => $opt{code});
                        }
                        else {
                            my $code = substr($_, pos);
                            if   ($code =~ /^\./) { $code = ". $code" }
                            else                  { $code = ".$code" }
                            $methods = $self->parse_methods(code => \$code);
                            pos($_) += pos($code) - 1;
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
                    elsif (!$has_newline and /\G(if|while|and|or)\b\h*/gc) {
                        my $keyword = $1;
                        my $obj = (
                                   /\G(?=\()/
                                   ? $self->parse_arg(code => $opt{code})
                                   : $self->parse_obj(code => $opt{code})
                                  );
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
                                       error => 'unbalanced right brackets',
                                       code  => $_,
                                       pos   => pos($_) - 1,
                                      );
                }

                return \%struct;
            }

            if (/\G\}/gc) {

                if (--$self->{curly_brackets} < 0) {
                    $self->fatal_error(
                                       error => 'unbalanced curly brackets',
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
                                       error => 'unbalanced parentheses',
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
