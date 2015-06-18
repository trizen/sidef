package Sidef::Parser {

    use utf8;
    use 5.014;

    our $DEBUG = 0;

    sub new {
        my (undef, %opts) = @_;

        my %options = (
            line          => 1,
            inc           => [],
            class         => 'main',           # a.k.a. namespace
            vars          => {'main' => []},
            ref_vars_refs => {'main' => []},
            EOT           => [],
            postfix_ops   => {                 # postfix operators
                             '--'  => 1,
                             '++'  => 1,
                             '??'  => 1,
                             '...' => 1,
                             '!'   => 1,
                           },
            binpost_ops => {                   # infix + postfix operators
                             '...' => 1,
                           },
            obj_with_do => {
                            'Sidef::Types::Block::For'   => 1,
                            'Sidef::Types::Bool::While'  => 1,
                            'Sidef::Types::Bool::If'     => 1,
                            'Sidef::Types::Block::Given' => 1,
                           },
            obj_with_block => {
                               'Sidef::Types::Bool::While' => 1,
                              },
            static_obj_re => qr{\G
                (?>
                       nil\b                          (?{ state $x = Sidef::Types::Nil::Nil->new })
                     | true\b                         (?{ state $x = Sidef::Types::Bool::Bool->true })
                     | (?:false|Bool)\b               (?{ state $x = Sidef::Types::Bool::Bool->false })
                     | next\b                         (?{ state $x = Sidef::Types::Block::Next->new })
                     | continue\b                     (?{ state $x = Sidef::Types::Block::Continue->new })
                     | BlackHole\b                    (?{ state $x = Sidef::Types::Black::Hole->new })
                     | Block\b                        (?{ state $x = Sidef::Types::Block::Code->new })
                     | Backtick\b                     (?{ state $x = Sidef::Types::Glob::Backtick->new })
                     | ARGF\b                         (?{ state $x = Sidef::Types::Glob::FileHandle->new(fh => \*ARGV) })
                     | STDIN\b                        (?{ state $x = Sidef::Types::Glob::FileHandle->stdin })
                     | STDOUT\b                       (?{ state $x = Sidef::Types::Glob::FileHandle->stdout })
                     | STDERR\b                       (?{ state $x = Sidef::Types::Glob::FileHandle->stderr })
                     | Dir\b                          (?{ state $x = Sidef::Types::Glob::Dir->new })
                     | File\b                         (?{ state $x = Sidef::Types::Glob::File->new })
                     | Fcntl\b                        (?{ state $x = Sidef::Types::Glob::Fcntl->new })
                     | Arr(?:ay)?+\b                  (?{ state $x = Sidef::Types::Array::Array->new })
                     | MultiArr(?:ay)?+\b             (?{ state $x = Sidef::Types::Array::MultiArray->new })
                     | Pair\b                         (?{ state $x = Sidef::Types::Array::Pair->new })
                     | Hash\b                         (?{ state $x = Sidef::Types::Hash::Hash->new })
                     | Str(?:ing)?+\b                 (?{ state $x = Sidef::Types::String::String->new })
                     | Num(?:ber)?+\b                 (?{ state $x = Sidef::Types::Number::Number->new })
                     | Math\b                         (?{ state $x = Sidef::Math::Math->new })
                     | Socket\b                       (?{ state $x = Sidef::Types::Glob::Socket->new })
                     | Pipe\b                         (?{ state $x = Sidef::Types::Glob::Pipe->new })
                     | Byte\b                         (?{ state $x = Sidef::Types::Byte::Byte->new })
                     | Ref\b                          (?{ state $x = Sidef::Variable::Ref->new })
                     | LazyMethod\b                   (?{ state $x = Sidef::Variable::LazyMethod->new })
                     | Bytes\b                        (?{ state $x = Sidef::Types::Byte::Bytes->new })
                     | Time\b                         (?{ state $x = Sidef::Time::Time->new('__INIT__') })
                     | Complex\b                      (?{ state $x = Sidef::Types::Number::Complex->new })
                     | (?:Sig|SIG)\b                  (?{ state $x = Sidef::Sys::SIG->new })
                     | Cha?r\b                        (?{ state $x = Sidef::Types::Char::Char->new })
                     | Cha?rs\b                       (?{ state $x = Sidef::Types::Char::Chars->new })
                     | Sys\b                          (?{ state $x = Sidef::Sys::Sys->new })
                     | Regex\b                        (?{ state $x = Sidef::Types::Regex::Regex->new('') })
                     | Sidef\b                        (?{ state $x = Sidef->new })
                     | Perl\b                         (?{ state $x = Sidef::Perl::Perl->new })
                     | \$\.                           (?{ state $x = Sidef::Variable::Magic->new(\$., 1) })
                     | \$\?                           (?{ state $x = Sidef::Variable::Magic->new(\$?, 1) })
                     | \$\$                           (?{ state $x = Sidef::Variable::Magic->new(\$$, 1) })
                     | \$\^T\b                        (?{ state $x = Sidef::Variable::Magic->new(\$^T, 1) })
                     | \$\|                           (?{ state $x = Sidef::Variable::Magic->new(\$|, 1) })
                     | \$!                            (?{ state $x = Sidef::Variable::Magic->new(\$!, 0) })
                     | \$"                            (?{ state $x = Sidef::Variable::Magic->new(\$", 0) })
                     | \$\\                           (?{ state $x = Sidef::Variable::Magic->new(\$\, 0) })
                     | \$/                            (?{ state $x = Sidef::Variable::Magic->new(\$/, 0) })
                     | \$;                            (?{ state $x = Sidef::Variable::Magic->new(\$;, 0) })
                     | \$,                            (?{ state $x = Sidef::Variable::Magic->new(\$,, 0) })
                     | \$\^O\b                        (?{ state $x = Sidef::Variable::Magic->new(\$^O, 0) })
                     | \$\^PERL\b                     (?{ state $x = Sidef::Variable::Magic->new(\$^X, 0) })
                     | \$0\b                          (?{ state $x = Sidef::Variable::Magic->new(\$0, 0) })
                     | \$\)                           (?{ state $x = Sidef::Variable::Magic->new(\$), 0) })
                     | \$\(                           (?{ state $x = Sidef::Variable::Magic->new(\$(, 0) })
                     | \$<                            (?{ state $x = Sidef::Variable::Magic->new(\$<, 1) })
                     | \$>                            (?{ state $x = Sidef::Variable::Magic->new(\$>, 1) })
                     | ∞                              (?{ state $x = Sidef::Types::Number::Number->new->inf })
                ) (?!::)
            }x,
            prefix_obj_re => qr{\G
              (?:
                  if\b                                            (?{ Sidef::Types::Bool::If->new })
                | while\b                                         (?{ Sidef::Types::Bool::While->new })
                | for(?:each)?+\b                                 (?{ Sidef::Types::Block::For->new })
                | return\b                                        (?{ Sidef::Types::Block::Return->new })
                | break\b                                         (?{ Sidef::Types::Block::Break->new })
                | try\b                                           (?{ Sidef::Types::Block::Try->new })
                | (?:given|switch)\b                              (?{ Sidef::Types::Block::Given->new })
                | f?require\b                                     (?{ state $x = Sidef::Module::Require->new })
                | (?:(?:print(?:ln)?+|say|read)\b|>>?)            (?{ state $x = Sidef::Sys::Sys->new })
                | loop\b                                          (?{ state $x = Sidef::Types::Block::Code->new })
                | (?:[*\\&]|\+\+|--|lvalue\b)                     (?{ Sidef::Variable::Ref->new })
                | [?√+~!-]                                        (?{ state $x = Sidef::Object::Unary->new })
                | :                                               (?{ state $x = Sidef::Types::Hash::Hash->new })
              )
            }x,
            quote_operators_re => qr{\G
             (?:
                # String
                 (?: ['‘‚’] | %q\b. )                                      (?{ [qw(0 new Sidef::Types::String::String)] })
                |(?: ["“„”] | %(?:Q\b. | (?![[:alpha:]]). ))               (?{ [qw(1 new Sidef::Types::String::String)] })

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
                | %b\b.                                                    (?{ [qw(0 to_bytes Sidef::Types::Byte::Bytes)] })
                | %B\b.                                                    (?{ [qw(1 to_bytes Sidef::Types::Byte::Bytes)] })

                # Chars
                | %c\b.                                                    (?{ [qw(0 to_chars Sidef::Types::Char::Chars)] })
                | %C\b.                                                    (?{ [qw(1 to_chars Sidef::Types::Char::Chars)] })
             )
            }xs,
            keywords => {
                map { $_ => 1 }
                  qw(
                  next
                  break
                  return
                  for foreach
                  if while
                  try loop
                  given switch
                  continue
                  require frequire
                  true false
                  nil
                  import
                  include
                  print println say
                  eval
                  read
                  die
                  warn

                  File
                  Fcntl
                  Dir
                  Arr Array Pair
                  MultiArray MultiArr
                  Hash
                  Str String
                  Num Number
                  Complex
                  Math
                  Pipe
                  Ref
                  Socket
                  Byte Bytes
                  Chr Char
                  Chrs Chars
                  Bool
                  Sys
                  Sig SIG
                  Regex
                  Time
                  Sidef
                  Parser
                  Block
                  BlackHole
                  Backtick
                  LazyMethod

                  my
                  var
                  const
                  func
                  enum
                  class
                  static
                  define
                  struct
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

                  __USE_BIGNUM__
                  __USE_RATNUM__
                  __USE_INTNUM__
                  __USE_FASTNUM__

                  )
            },
            match_flags_re  => qr{[msixpogcdual]+},
            var_name_re     => qr/[[:alpha:]_]\w*(?>::[[:alpha:]_]\w*)*/,
            method_name_re  => qr/[[:alpha:]_]\w*[!:?]?/,
            var_init_sep_re => qr/\G\h*(?:=>|[=:]|\bis\b)\h*/,
            operators_re    => do {
                local $" = q{|};

                # The order matters! (in a way)
                my @operators = map { quotemeta } qw(

                  ===
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
                  ^^ $$
                  <= >= < >
                  ++ --
                  += +
                  -= -
                  /= / ÷= ÷
                  **= **
                  %= %
                  ^= ^
                  *= *
                  ...
                  != ..
                  \\\\= \\\\
                  ?? ?
                  ! \\
                  : « » ~
                  );

                qr{
                      »(?<uop>[[:alpha:]_]\w*|(?&op))«          # unroll method + op (e.g.: »add« or »+«)
                    | >(?<uop>[[:alpha:]_]\w*|(?&op))<          # unroll method + op (e.g.: >add< or >+<)
                    | \[(?<rop>(?&op))\]                        # reduce operator    (e.g.: [+])
                    | <(?<rop>[[:alpha:]_]\w*)>                 # reduce method      (e.g.: <add>)
                    | «(?<rop>[[:alpha:]_]\w*|(?&op))»          # reduce method + op (e.g.: «add» or «+»)
                    | \h*\^(?<mop>[[:alpha:]_]\w*[!:?]?)\^\h*   # method-like operator
                    | (?<op>@operators
                        | \p{Block: Mathematical_Operators}
                        | \p{Block: Supplemental_Mathematical_Operators}
                      )
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
                     "Sorry, I don’t know how to help in this situation.",
                     "I'm broken. Fix me, or show this to someone who can fix",
                     "Huh?",
                     "Out of order",
                     "You must be joking.",
                     "Ouch, That HURTS!",
                     "Who are you!?",
                     "Death before dishonour?",
                     "Good afternoon, gentelman, I’m a HAL 9000 Computer",
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

        my $error = sprintf("%s: %s\n%s:%s: syntax error, %s\n%s\n",
                            $basename,
                            $lines[rand @lines],
                            $self->{file_name} // '-',
                            $self->{line}, join(', ', grep { defined } $opt{error}, $opt{expected}), $error_line,);

        my $pointer = ' ' x ($point) . '^' . "\n";
        die $error, $pointer;
    }

    sub find_var {
        my ($self, $var_name, $class) = @_;

        foreach my $var (@{$self->{vars}{$class}}) {
            next if ref $var eq 'ARRAY';
            return ($var, 1) if $var->{name} eq $var_name;
        }

        foreach my $var (@{$self->{ref_vars_refs}{$class}}) {
            next if ref $var eq 'ARRAY';
            return ($var, 0) if $var->{name} eq $var_name;
        }

        ();
    }

    sub check_declarations {
        my ($self, $hash_ref) = @_;

        foreach my $class (grep { $_ eq 'main' } keys %{$hash_ref}) {

            my $array_ref = $hash_ref->{$class};

            foreach my $variable (@{$array_ref}) {
                if (ref $variable eq 'ARRAY') {
                    $self->check_declarations({$class => $variable});
                }
                elsif (   $variable->{count} == 0
                       && $variable->{type} ne 'class'
                       && $variable->{type} ne 'func'
                       && $variable->{type} ne 'method'
                       && $variable->{name} ne 'self'
                       && $variable->{name} ne ''
                       && chr(ord $variable->{name}) ne '_') {

                    # Minor exception for interactive mode
                    if ($self->{interactive}) {
                        ++$variable->{obj}{in_use};
                        next;
                    }

                    warn '[WARN] '
                      . (
                         $variable->{type} eq 'const' || $variable->{type} eq 'define' || $variable->{type} eq 'enum'
                         ? 'Constant'
                         : 'Variable'
                        )
                      . " '$variable->{name}' has been declared, but not used again, at "
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
    # 4th: the position after match
    sub get_method_name {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        # Implicit end of statement
        ($self->parse_whitespace(code => $opt{code}))[1] && return;

        # Alpha-numeric method name
        if (/\G($self->{method_name_re})/gxoc) {
            return ($1, 0, '');
        }

        # Operator-like method name
        if (m{\G$self->{operators_re}}goc) {
            my $uop = exists($+{uop});
            my $rop = exists($+{rop});
            return ($+, ($uop ? 1 : $rop ? 0 : not exists $self->{postfix_ops}{$+}), ($uop ? 'uop' : $rop ? 'rop' : ''));
        }

        # Method name as expression
        my ($obj) = $self->parse_expr(code => $opt{code});
        $obj // return;
        return ({self => $obj}, 0, '');
    }

    sub get_init_vars {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        my $end_delim;
        foreach my $key ('|', (keys %{$self->{delim_pairs}})) {
            next if exists $opt{ignore_delim} and exists $opt{ignore_delim}{$key};
            if (/\G\Q$key\E\h*/gc) {
                $end_delim = $self->{delim_pairs}{$key} // '|';
                $self->parse_whitespace(code => $opt{code});
                last;
            }
        }

        my @vars;
        while (/\G([*:]?$self->{var_name_re})/goc) {
            push @vars, $1;
            if ($opt{with_vals} && defined($end_delim) && /$self->{var_init_sep_re}/goc) {
                my $code = substr($_, pos);
                $self->parse_obj(code => \$code);
                $vars[-1] .= '=' . substr($_, pos($_), pos($code));
                pos($_) += pos($code);
            }

            defined($end_delim) && (/\G\h*,\h*/gc || last);
            $self->parse_whitespace(code => $opt{code});
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

        my $end_delim;
        foreach my $key ('|', (keys %{$self->{delim_pairs}})) {
            next if exists $opt{ignore_delim} and exists $opt{ignore_delim}{$key};
            if (/\G\Q$key\E\h*/gc) {
                $end_delim = $self->{delim_pairs}{$key} // '|';
                $self->parse_whitespace(code => $opt{code});
                last;
            }
        }

        my @var_objs;
        while (/\G([*:]?)($self->{var_name_re})/goc) {
            my ($attr, $name) = ($1, $2);

            my $class_name;
            ($name, $class_name) = $self->get_name_and_class($name);

            if (exists $self->{keywords}{$name}) {
                $self->fatal_error(
                                   code  => $_,
                                   pos   => $-[2],
                                   error => "'$name' is either a keyword or a predefined variable!",
                                  );
            }

            if (!$opt{private}) {
                my ($var, $code) = $self->find_var($name, $class_name);

                if (defined($var) && $code) {
                    warn "[WARN] Redeclaration of $opt{type} '$name' in same scope, at "
                      . "$self->{file_name}, line $self->{line}\n";
                }
            }

            my $value;
            if (defined($end_delim) && /$self->{var_init_sep_re}/goc) {
                my $obj = $self->parse_obj(code => $opt{code});
                $value =
                  ref($obj) eq 'HASH'
                  ? Sidef::Types::Block::Code->new($obj)->run
                  : $obj;
            }

            my $obj = Sidef::Variable::Variable->new(
                                                     name  => $name,
                                                     type  => $opt{type},
                                                     class => $class_name,
                                                     defined($value) ? (value => $value, has_value => 1) : (),
                                                     $attr eq '*' ? (array => 1) : $attr eq ':' ? (hash => 1) : (),
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
            defined($end_delim) && (/\G\h*,\h*/gc || last);
            $self->parse_whitespace(code => $opt{code});
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

                # End of a statement when two or more new lines has been found
                if ($self->{line} - $beg_line >= 2) {
                    return wantarray ? (1, 1) : (1);
                }

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
                if ($method ne 'new') {
                    @array_like = ($package, $method);
                    $package    = 'Sidef::Types::String::String';
                    $method     = 'new';
                }

                my $obj = $double_quoted
                  ? do {
                    state $str = Sidef::Types::String::String->new;    # load the string module
                    Sidef::Types::String::String::apply_escapes($package->$method($string), $self);
                  }
                  : $package->$method($string =~ s{\\\\}{\\}gr);

                # Special case for backticks (add method '`')
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
                        $obj = $array_like[0]->call($obj);
                    }
                }

                return $obj;
            }

            # Object as expression
            if (/\G(?=\()/) {
                my $obj = $self->parse_arguments(code => $opt{code});
                return $obj;
            }

            # Block as object
            if (/\G(?=\{)/) {
                my $obj = $self->parse_block(code => $opt{code});
                return $obj;
            }

            # Array as object
            if (/\G(?=\[)/) {

                my $array = Sidef::Types::Array::HCArray->new();
                my $obj = $self->parse_array(code => $opt{code});

                if (ref $obj->{$self->{class}} eq 'ARRAY') {
                    push @{$array}, (@{$obj->{$self->{class}}});
                }

                return $array;
            }

            # Bareword followed by a fat comma or a colon character
            if (   /\G:([[:alpha:]_]\w*)/gc
                || /\G([[:alpha:]_]\w*)(?=\h*=>|:(?![=:]))/gc) {
                return Sidef::Types::String::String->new($1);
            }

            # Declaration of variable types
            if (/\G(var|static|const)\b\h*/gc) {
                my $type = $1;
                my $vars = $self->parse_init_vars(code => $opt{code}, type => $type);

                $vars // $self->fatal_error(
                                            code  => $_,
                                            pos   => pos,
                                            error => "expected a variable name after the keyword '$type'!",
                                           );

                return Sidef::Variable::Init->new(@{$vars});
            }

            # Declaration of compile-time evaluated constants
            if (/\Gdefine\h+($self->{var_name_re})\h*/goc) {
                my $name = $1;

                if (exists $self->{keywords}{$name}) {
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => (pos($_) - length($name)),
                                       error => "'$name' is either a keyword or a predefined variable!",
                                      );
                }

                /\G=\h*/gc;    # an optional equal sign is allowed

                my $obj = $self->parse_obj(code => $opt{code});
                $obj // $self->fatal_error(
                                           code  => $_,
                                           pos   => pos,
                                           error => qq{expected an expression after variable "$name" (near <define>)},
                                          );

                $obj =
                  ref($obj) eq 'HASH'
                  ? Sidef::Types::Block::Code->new($obj)->run
                  : $obj;

                unshift @{$self->{vars}{$self->{class}}},
                  {
                    obj   => $obj,
                    name  => $name,
                    count => 0,
                    type  => 'define',
                    line  => $self->{line},
                  };

                return $obj;
            }

            # Struct declaration
            if (/\Gstruct\b\h*/gc) {

                my $name;
                if (/\G($self->{var_name_re})\h*/goc) {
                    $name = $1;
                }

                if (defined $name and exists $self->{keywords}{$name}) {
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => (pos($_) - length($name)),
                                       error => "'$name' is either a keyword or a predefined variable!",
                                      );
                }

                my $vars =
                  $self->parse_init_vars(
                                         code      => $opt{code},
                                         with_vals => 1,
                                         private   => 1,
                                         type      => 'var',
                                        );

                my $struct = Sidef::Variable::Struct->__new__($name, $vars);

                if (defined $name) {
                    unshift @{$self->{vars}{$self->{class}}},
                      {
                        obj   => $struct,
                        name  => $name,
                        count => 0,
                        type  => 'struct',
                        line  => $self->{line},
                      };
                }

                return $struct;
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

                    $value =
                        $var->{has_value}
                      ? $var->{value}
                      : $value->inc;

                    if (exists $self->{keywords}{$name}) {
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

                return Sidef::Types::Number::Number->new($#{$vars});
            }

            # Declaration of the 'my' special variable + class, method and function declarations
            if (
                   /\G(my|func|class)\b\h*/gc
                || /\G(->)\h*/gc
                || (exists($self->{current_class})
                    && /\G(method)\b\h*/gc)
              ) {
                my $type =
                    $1 eq '->'
                  ? exists($self->{current_class}) && !(exists($self->{current_method}))
                      ? 'method'
                      : 'func'
                  : $1;

                my $built_in_obj;
                if ($type eq 'class' and /\G(?!\{)/) {
                    my $obj = eval {
                        local $self->{_want_name} = 1;
                        my $code = substr($_, pos);
                        my ($obj) = $self->parse_expr(code => \$code);
                        pos($_) += pos($code);
                        $obj;
                    };
                    if (not $@ and defined $obj) {
                        $built_in_obj =
                          ref($obj) eq 'HASH'
                          ? Sidef::Types::Block::Code->new($obj)->run
                          : Sidef::Types::Block::Code->new({self => $obj})->_execute_expr;
                    }
                }

                my $name       = '';
                my $class_name = $self->{class};
                if (not defined $built_in_obj) {
                    $name =
                        /\G($self->{var_name_re})\h*/goc ? $1
                      : $type eq 'method' && /\G($self->{operators_re})\h*/goc ? $+
                      : $type ne 'my' ? ''
                      : $self->fatal_error(
                                           error    => "invalid '$type' declaration",
                                           expected => "expected a name",
                                           code     => $_,
                                           pos      => pos($_)
                                          );
                    ($name, $class_name) = $self->get_name_and_class($name);
                }

                local $self->{class} = $class_name;

                if ($type ne 'method'
                    && exists($self->{keywords}{$name})) {
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => $-[0],
                                       error => "'$name' is either a keyword or a predefined variable!",
                                      );
                }

                my $obj =
                    $type eq 'my' ? Sidef::Variable::My->new($name)
                  : $type eq 'func'   ? Sidef::Variable::Variable->new(name => $name, type => $type, class => $class_name)
                  : $type eq 'method' ? Sidef::Variable::Variable->new(name => $name, type => $type, class => $class_name)
                  : $type eq 'class'
                  ? Sidef::Variable::ClassInit->__new__(name => ($built_in_obj // $name), class => $class_name)
                  : $self->fatal_error(
                                       error    => "invalid type",
                                       expected => "expected a magic thing to happen",
                                       code     => $_,
                                       pos      => pos($_),
                                      );

                my $private = 0;
                if (($type eq 'method' or $type eq 'func') and $name ne '') {
                    my ($var) = $self->find_var($name, $class_name);

                    # Redeclaration of a function or a method in the same scope
                    if (ref $var) {
                        push @{$var->{obj}{value}{kids}}, $obj;
                        $private = 1;
                    }
                }

                if (not $private) {
                    unshift @{$self->{vars}{$class_name}},
                      {
                        obj   => $obj,
                        name  => $name,
                        count => 0,
                        type  => $type,
                        line  => $self->{line},
                      };
                }

                if ($type eq 'my') {
                    return Sidef::Variable::InitMy->new($name);
                }

                if ($type eq 'class') {
                    my $var_names =
                      $self->parse_init_vars(
                                             code         => $opt{code},
                                             with_vals    => 1,
                                             private      => 1,
                                             type         => 'var',
                                             ignore_delim => {
                                                              '{' => 1,
                                                              '<' => 1,
                                                             },
                                            );

                    $obj->__set_params__($var_names);

                    # Class inheritance (class Name(...) << Name1, Name2)
                    if (/\G\h*<<?\h*/gc) {
                        while (/\G($self->{var_name_re})\h*/gco) {
                            my ($name) = $1;
                            my ($class, $code) = $self->find_var($name, $class_name);
                            if (ref $class) {
                                if ($class->{type} eq 'class') {
                                    push @{$obj->{inherit}}, $name;
                                    while (my ($name, $method) = each %{$class->{obj}{__METHODS__}}) {
                                        ($built_in_obj // $obj)->__add_method__($name, $method);
                                    }
                                }
                                else {
                                    $self->fatal_error(
                                                       error    => "this is not a class",
                                                       expected => "expected a class name",
                                                       code     => $_,
                                                       pos      => pos($_) - length($name) - 1,
                                                      );
                                }
                            }
                            else {
                                $self->fatal_error(
                                                   error    => "can't find '$name' class",
                                                   expected => "expected an existent class name",
                                                   code     => $_,
                                                   pos      => pos($_) - length($name) - 1,
                                                  );
                            }

                            /\G,\h*/gc;
                        }
                    }

                    /\G\h*(?=\{)/gc
                      || $self->fatal_error(
                                            error    => "invalid class declaration",
                                            expected => "expected: class $name(...){...}",
                                            code     => $_,
                                            pos      => pos($_)
                                           );

                    local $self->{class_name} = $name;
                    local $self->{current_class} = $built_in_obj // $obj;
                    my $block = $self->parse_block(code => $opt{code});

                    $obj->__set_block__($block);
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

                    # Function return type (func name(...) -> Type {...})
                    # XXX: [KNOWN BUG] It doesn't check the returned type from method calls
                    if (/\G\h*(?:->|returns\b)\h*/gc) {
                        my $return_obj = eval {
                            local $self->{_want_name} = 1;
                            my $code = substr($_, pos);
                            my ($obj) = $self->parse_expr(code => \$code);
                            pos($_) += pos($code);
                            $obj;
                        };
                        if (not $@ and defined $return_obj) {
                            $obj->{returns} =
                              ref($return_obj) eq 'HASH'
                              ? Sidef::Types::Block::Code->new($return_obj)->run
                              : Sidef::Types::Block::Code->new({self => $return_obj})->_execute_expr;
                        }
                        else {
                            $self->fatal_error(
                                               error    => "invalid return-type for function '$name'",
                                               expected => "expected a valid type, such as: Str, Num, Arr, etc...",
                                               code     => $_,
                                               pos      => pos($_)
                                              );
                        }
                    }

                    /\G\h*\{\h*/gc
                      || $self->fatal_error(
                                            error    => "invalid '$type' declaration",
                                            expected => "expected: $type $name(...){...}",
                                            code     => $_,
                                            pos      => pos($_)
                                           );

                    local $self->{$type eq 'func' ? 'current_function' : 'current_method'} = $obj;
                    my $args = '|' . join(',', $type eq 'method' ? 'self' : (), @{$var_names}) . ' |';

                    my $code = '{' . $args . substr($_, pos);
                    my $block = $self->parse_block(code => \$code);
                    pos($_) += pos($code) - length($args) - 1;

                    $obj->set_value($block);
                    if (not $private) {
                        $self->{current_class}->__add_method__($name, $block) if $type eq 'method';
                    }
                }

                return $obj;
            }

            # Inside a class context
            if (exists $self->{current_class}) {

                # Method declaration
                if (/\Gdef_method\b\h*/gc) {
                    my ($name) = $self->parse_expr(code => $opt{code});

                    my $code = 'method ' . substr($_, pos($_));
                    my ($method) = $self->parse_expr(code => \$code);
                    pos($_) += pos($code) - 7;

                    return scalar {
                        $self->{class} => [
                            {
                             self => exists($self->{current_method})
                             ? do {
                                 my ($var) = $self->find_var('self', $self->{class});
                                 $var->{count}++;
                                 $var->{obj}{in_use} = 1;
                                 $var->{obj};
                               }
                             : $self->{current_class},
                             call => [
                                 {
                                  method => 'def_method',
                                  arg    => [
                                      $name,

                                      {
                                       $self->{class} => [
                                                          {
                                                           call => [{method => 'copy'}],
                                                           self => $method,
                                                          },
                                                         ]
                                      }

                                  ]
                                 }
                             ]
                            }
                          ]

                    };
                }

                # Declaration of class variables
                elsif (/\Gdef(?:_var)?\b\h*/gc) {

                    my $vars =
                      $self->parse_init_vars(
                                             code    => $opt{code},
                                             type    => 'def',
                                             private => 1,
                                            );

                    $vars // $self->fatal_error(
                                                code  => $_,
                                                pos   => pos,
                                                error => "expected a variable name after the keyword 'def'!",
                                               );

                    # Mark all variables as 'in_use'
                    foreach my $var (@{$vars}) {
                        $var->{in_use} = 1;
                    }

                    # Store them inside the class
                    $self->{current_class}->__add_vars__($vars);

                    # Return a 'Sidef::Variable::Init' object
                    return Sidef::Variable::Init->new(@{$vars});
                }
            }

            # Binary, hexdecimal and octal numbers
            if (/\G0(b[10_]*|x[0-9A-Fa-f_]*|[0-9_]+\b)/gc) {
                my $number = "0" . ($1 =~ tr/_//dr);
                state $x = require Math::BigInt;
                return
                  Sidef::Types::Number::Number->new(
                                                    $number =~ /^0[0-9]/
                                                    ? Math::BigInt->from_oct($number)
                                                    : Math::BigInt->new($number)
                                                   );
            }

            # Integer or float number
            if (/\G([+-]?+(?=\.?[0-9])[0-9_]*+(?:\.[0-9_]++)?(?:[Ee](?:[+-]?+[0-9_]+))?)([rifc]\b|)/gc) {
                my $num = $1 =~ tr/_//dr;
                return (
                          $2 eq 'f' ? Sidef::Types::Number::Number->new_float($num)
                        : $2 eq 'i' ? Sidef::Types::Number::Number->new_int($num)
                        : $2 eq 'r' ? Sidef::Types::Number::Number->new_rat($num)
                        : $2 eq 'c' ? Sidef::Types::Number::Complex->new($num)
                        :             Sidef::Types::Number::Number->new($num)
                       );
            }

            # Implicit method call on special variable: _
            if (/\G\./) {
                my ($var) = $self->find_var('_', $self->{class});

                if (defined $var) {
                    $var->{count}++;
                    ref($var->{obj}) eq 'Sidef::Variable::Variable' && do {
                        $var->{obj}{in_use} = 1;
                    };
                    return $var->{obj};
                }

                $self->fatal_error(
                                   code  => $_,
                                   pos   => pos($_) - 1,
                                   error => "attempt to use an implicit method call on the uninitialized variable: \"_\"",
                                  );
            }

            # Quoted words or numbers (%w/a b c/)
            if (/\G%([wWin])\b/gc || /\G(?=(«|<(?!<)))/) {
                my ($type) = $1;
                my $strings = $self->get_quoted_words(code => $opt{code});

                if ($type eq 'w' or $type eq '<') {
                    return Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new(s{\\(?=[\\#\s])}{}gr) }
                                                           @{$strings});
                }
                elsif ($type eq 'i') {
                    return Sidef::Types::Array::Array->new(map { Sidef::Types::Number::Number->new_int(s{\\(?=[\\#\s])}{}gr) }
                                                           @{$strings});
                }
                elsif ($type eq 'n') {
                    return Sidef::Types::Array::Array->new(map { Sidef::Types::Number::Number->new(s{\\(?=[\\#\s])}{}gr) }
                                                           @{$strings});
                }

                my ($inline_expression, @objs);
                foreach my $item (@{$strings}) {
                    my $str = Sidef::Types::String::String->new($item)->apply_escapes($self);
                    if (!$inline_expression and ref $str eq 'HASH') {
                        $inline_expression = 1;
                    }
                    push @objs, $str;
                }

                return (
                        $inline_expression
                        ? Sidef::Types::Array::HCArray->new(map { {self => $_} } @objs)
                        : Sidef::Types::Array::Array->new(@objs)
                       );
            }

            if (/$self->{prefix_obj_re}/goc) {
                pos($_) = $-[0];
                return ($^R, 1);
            }

            # Eval keyword
            if (/\Geval\b/gc) {
                pos($_) = $-[0];
                return (
                        Sidef::Eval::Eval->new(
                                               $self,
                                               {$self->{class} => [@{$self->{vars}{$self->{class}}}]},
                                               {$self->{class} => [@{$self->{ref_vars_refs}{$self->{class}}}]}
                                              ),
                        1
                       );
            }

            if (/\G(?:die|warn)\b/gc) {
                pos($_) = $-[0];
                return (Sidef::Sys::Sys->new(line => $self->{line}, file_name => $self->{file_name}), 1);
            }

            if (/\GParser\b/gc) {
                return $self;
            }

            # Regular expression
            if (m{\G(?=/)} || /\G%r\b/gc) {
                my $string = $self->get_quoted_string(code => $opt{code});
                return Sidef::Types::Regex::Regex->new($string, /\G($self->{match_flags_re})/goc ? $1 : undef, $self);
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
                        open my $str_fh, '<:utf8', \$self->{'__DATA__'};
                        Sidef::Types::Glob::FileHandle->new(fh   => $str_fh,
                                                            file => Sidef::Types::Nil::Nil->new);
                      }
                );
            }

            # Begining of here-document (<<"EOT", <<'EOT', <<EOT)
            if (/\G<<(?=\S)/gc) {
                my ($name, $type) = (undef, 1);

                if (/\G(?=(['"„]))/) {
                    $type = 0 if $1 eq q{'};
                    my $str = $self->get_quoted_string(code => $opt{code});
                    $name = $str;
                }
                elsif (/\G(-?\w+)/gc) {
                    $name = $1;
                }
                else {
                    $self->fatal_error(
                                       error    => "invalid 'here-doc' declaration",
                                       expected => "expected an alpha-numeric token after '<<'",
                                       code     => $_,
                                       pos      => pos($_)
                                      );
                }

                my $obj = {$self->{class} => []};
                push @{$self->{EOT}}, [$name, $type, $obj];

                return $obj;
            }

            if (/\G__USE_BIGNUM__\b;*/gc) {
                delete $INC{'Sidef/Types/Number/Number.pm'};
                require Sidef::Types::Number::Number;
                redo;
            }

            if (/\G__USE_FASTNUM__\b;*/gc) {
                delete $INC{'Sidef/Types/Number/NumberFast.pm'};
                require Sidef::Types::Number::Number;
                require Sidef::Types::Number::NumberFast;
                redo;
            }

            if (/\G__USE_INTNUM__\b;*/gc) {
                delete $INC{'Sidef/Types/Number/NumberInt.pm'};
                require Sidef::Types::Number::NumberInt;
                redo;
            }

            if (/\G__USE_RATNUM__\b;*/gc) {
                delete $INC{'Sidef/Types/Number/NumberRat.pm'};
                require Sidef::Types::Number::NumberRat;
                redo;
            }

            if (exists($self->{current_block}) && /\G__BLOCK__\b/gc) {
                return $self->{current_block};
            }

            if (/\G__NAMESPACE__\b/gc) {
                return Sidef::Types::String::String->new($self->{class});
            }

            if (exists($self->{current_function})) {
                return $self->{current_function} if /\G__FUNC__\b/gc;
                return Sidef::Types::String::String->new($self->{current_function}{name}) if /\G__FUNC_NAME__\b/gc;
            }

            if (exists($self->{current_class})) {
                return $self->{current_class} if /\G__CLASS__\b/gc;
                return Sidef::Types::String::String->new($self->{class_name}) if /\G__CLASS_NAME__\b/gc;
            }

            if (exists($self->{current_method})) {
                return $self->{current_method} if /\G__METHOD__\b/gc;
                return Sidef::Types::String::String->new($self->{current_method}{name}) if /\G__METHOD_NAME__\b/gc;
            }

            # Variable call
            if (/\G($self->{var_name_re})/goc) {
                my ($name, $class) = $self->get_name_and_class($1);
                my ($var, $code) = $self->find_var($name, $class);

                if (ref $var) {
                    $var->{count}++;
                    ref($var->{obj}) eq 'Sidef::Variable::Variable' && do {

                        #$var->{closure} = 1 if $code == 0;  # it might be a closure
                        $var->{obj}{in_use} = 1;
                    };
                    return $var->{obj};
                }

                if ($name eq 'ARGV' or $name eq 'ENV') {

                    my $type = 'var';
                    my $variable = Sidef::Variable::Variable->new(name => $name, type => $type, class => $class);

                    unshift @{$self->{vars}{$class}},
                      {
                        obj   => $variable,
                        name  => $name,
                        count => 1,
                        type  => $type,
                        line  => $self->{line},
                      };

                    if ($name eq 'ARGV') {
                        state $x = require Encode;
                        my $array =
                          Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new(Encode::decode_utf8($_)) }
                                                          @ARGV);
                        $variable->set_value($array);
                    }
                    elsif ($name eq 'ENV') {
                        state $x = require Encode;
                        my $hash =
                          Sidef::Types::Hash::Hash->new(map { Sidef::Types::String::String->new(Encode::decode_utf8($_)) }
                                                        %ENV);
                        $variable->set_value($hash);
                    }

                    return $variable;
                }

                # 'def' instance/class variables
                state $x = require List::Util;
                if (
                    ref($self->{current_class}) eq 'Sidef::Variable::ClassInit'
                    and defined(
                                my $var = List::Util::first(
                                                            sub { $_->{name} eq $name },
                                                            @{$self->{current_class}{__VARS__}},
                                                            @{$self->{current_class}{__DEF_VARS__}}
                                                           )
                               )
                  ) {
                    if (exists $self->{current_method}) {
                        my ($var, $code) = $self->find_var('self', $class);
                        if (ref $var) {
                            $var->{count}++;
                            $var->{obj}{in_use} = 1;
                            return
                              scalar {
                                      $self->{class} => [
                                                         {
                                                          self => $var->{obj},
                                                          call => [{method => $name}]
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

                    #warn qq{[!] Implicit declaration of variable "$name", at line $self->{line}\n};
                    unshift @{$self->{vars}{$class}},
                      {
                        obj   => Sidef::Variable::My->new($name),
                        name  => $name,
                        count => 0,
                        type  => 'my',
                        line  => $self->{line},
                      };

                    pos($_) -= length($name);
                    return Sidef::Variable::InitMy->new($name);
                }

                # Type constant
                my $obj;
                if (
                        not $self->{_want_name}
                    and $class ne $self->{class}
                    and index($class, '::') == -1
                    and defined(
                        eval {
                            local $self->{_want_name} = 1;
                            my $code = $class;
                            ($obj) = $self->parse_expr(code => \$code);
                            $obj;
                        }
                    )
                  ) {
                    return
                      scalar {
                              $self->{class} => [
                                                 {
                                                  self => $obj,
                                                  call => [
                                                           {
                                                            method => 'get_constant',
                                                            arg    => [Sidef::Types::String::String->new($name)]
                                                           }
                                                          ]
                                                 }
                                                ]
                             };
                }

                # Method call in functional style
                if (not $self->{_want_name} and ($class eq $self->{class} or $class eq 'CORE') and /\G(?=\()/) {
                    my $arg = $self->parse_arguments(code => $opt{code});

                    if (exists $arg->{$self->{class}}) {
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

                # Fatal error
                $self->fatal_error(
                                   code  => $_,
                                   pos   => (pos($_) - length($name)),
                                   error => "attempt to use an undeclared variable <$1>",
                                  );
            }

            # Regex variables ($1, $2, ...)
            if (/\G\$([0-9]+)\b/gc) {
                return $self->{regexp_vars}{$1} //= Sidef::Variable::Variable->new(name => $1, type => 'var');
            }

            /\G\$/gc && redo;

            #warn "$self->{script_name}:$self->{line}: unexpected char: " . substr($_, pos($_), 1) . "\n";
            #return undef, pos($_) + 1;

            return;
        }
    }

    sub parse_arguments {
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

            my $block = Sidef::Types::Block::Code->new({});
            local $self->{current_block} = $block;

            # Parse any whitespace (if any)
            $self->parse_whitespace(code => $opt{code});

            my $var_objs = [];
            if (/\G(?=\|)/) {
                $var_objs =
                  $self->parse_init_vars(code => $opt{code},
                                         type => 'var');
            }

            {    # special '_' variable
                my $var_obj = Sidef::Variable::Variable->new(name => '_', type => 'var', class => $self->{class});
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

            my $obj = $self->parse_script(code => $opt{code});

            $self->{curly_brackets}
              && $self->fatal_error(
                                    code  => $_,
                                    pos   => $p - 1,
                                    error => "unbalanced curly brackets",
                                   );

            $block->{vars} = [
                map { $_->{obj} }
                grep { ref($_) eq 'HASH' and ref($_->{obj}) eq 'Sidef::Variable::Variable' } @{$self->{vars}{$self->{class}}}
            ];

            $block->{init_vars} = [map { Sidef::Variable::Init->new($_) } @{$var_objs}];

            $block->{code} = $obj;
            splice @{$self->{ref_vars_refs}{$self->{class}}}, 0, $count;
            $self->{vars}{$self->{class}} = $ref;

            return $block;
        }
    }

    sub append_method {
        my ($self, %opt) = @_;

        if ($opt{op_type} eq '') {
            push @{$opt{array}}, {method => $opt{method}};
        }
        elsif ($opt{op_type} eq 'uop') {
            push @{$opt{array}}, {method => 'unroll_operator', arg => [Sidef::Types::String::String->new($opt{method})]};
        }
        elsif ($opt{op_type} eq 'rop') {
            push @{$opt{array}}, {method => 'reduce_operator', arg => [Sidef::Types::String::String->new($opt{method})]};
        }
        else {
            die "[PARSER ERROR] Invalid operator of type '$opt{op_type}'...";
        }

        if (exists($opt{arg}) and (%{$opt{arg}} || ($opt{method} =~ /^$self->{operators_re}\z/))) {
            push @{$opt{array}[-1]{arg}}, $opt{arg};
        }
    }

    sub parse_methods {
        my ($self, %opt) = @_;

        my @methods;
        local *_ = $opt{code};

        {
            if ((/\G(?![-=]>)/ && /\G(?=$self->{operators_re})/o) || /\G\./goc) {
                my ($method, $req_arg, $op_type) = $self->get_method_name(code => $opt{code});

                if (defined($method)) {

                    my $has_arg;
                    if (/\G\h*(?=[({])/gc || $req_arg || exists($self->{binpost_ops}{$method})) {

                        my $code = substr($_, pos);
                        my $arg = (
                                     /\G(?=\()/ ? $self->parse_arguments(code => \$code)
                                   : ($req_arg || exists($self->{binpost_ops}{$method})) ? $self->parse_obj(code => \$code)
                                   : /\G(?=\{)/ ? $self->parse_block(code => \$code)
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
                        elsif (exists($self->{binpost_ops}{$method})) {
                            ## it's a postfix operator
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

    sub parse_obj {
        my ($self, %opt) = @_;

        my %struct;
        local *_ = $opt{code};

        my ($obj, $obj_key) = $self->parse_expr(code => $opt{code});

        # This object can't take any method!
        if (ref($obj) eq 'Sidef::Variable::InitMy') {
            return $obj;
        }

        while (
            #    (ref($obj) eq 'Sidef::Variable::Variable' and ($obj->{type} eq 'func' || $obj->{type} eq 'method'))
            # || (ref($obj) eq 'Sidef::Variable::ClassInit')
            # || (ref($obj) eq 'Sidef::Types::Block::Code')
            #  and
            /\G\h*(?=\()/gc
          ) {
            my $arg = $self->parse_arguments(code => $opt{code});
            $obj = {
                    $self->{class} => [
                                       {
                                        self => $obj,
                                        call => [
                                                 {
                                                  method => ref($obj) eq 'Sidef::Variable::ClassInit'
                                                  ? 'init'
                                                  : 'call',
                                                  (%{$arg} ? (arg => [$arg]) : ())
                                                 }
                                                ]
                                       }
                                      ]
                   };
        }

        if (defined $obj) {
            push @{$struct{$self->{class}}}, {self => $obj};

            if ($obj_key) {
                my ($method) = $self->get_method_name(code => $opt{code});
                if (defined $method) {

                    if (/\G\h*(?!;)/gc) {

                        my $arg = (
                                   /\G(?=\()/ ? $self->parse_arguments(code => $opt{code})
                                   : exists($self->{obj_with_block}{ref $struct{$self->{class}}[-1]{self}})
                                     && /\G(?=\{)/ ? $self->parse_block(code => $opt{code})
                                   : $self->parse_obj(code => $opt{code})
                                  );

                        if (defined $arg) {
                            my @arg = ($arg);
                            if (exists $self->{obj_with_block}{ref $struct{$self->{class}}[-1]{self}}
                                and ref($arg) eq 'HASH') {
                                @arg = Sidef::Types::Block::Code->new($arg);
                            }
                            elsif (    ref($struct{$self->{class}}[-1]{self}) eq 'Sidef::Types::Block::For'
                                   and ref($arg) eq 'HASH'
                                   and $#{$arg->{$self->{class}}} == 2) {
                                @arg = map { Sidef::Types::Block::Code->new($_) } @{$arg->{$self->{class}}};
                            }

                            push @{$struct{$self->{class}}[-1]{call}}, {method => $method, arg => \@arg};
                        }
                    }
                }
                else {
                    die "[PARSER ERROR] The same object needs to be parsed again as a method for itself!";
                }
            }

            while (/\G(?=\[)/) {
                my ($ind) = $self->parse_expr(code => $opt{code});
                push @{$struct{$self->{class}}[-1]{ind}}, $ind;
            }

            my @methods;
            {
                if (/\G(?=\.(?:$self->{method_name_re}|[(\$]))/o) {
                    my $methods = $self->parse_methods(code => $opt{code});
                    push @{$struct{$self->{class}}[-1]{call}}, @{$methods};
                }

                if (/\G(?=\[)/) {
                    $struct{$self->{class}}[-1]{self} = {
                            $self->{class} => [
                                {
                                 self => $struct{$self->{class}}[-1]{self},
                                 exists($struct{$self->{class}}[-1]{call}) ? (call => delete $struct{$self->{class}}[-1]{call})
                                 : (),
                                 exists($struct{$self->{class}}[-1]{ind}) ? (ind => delete $struct{$self->{class}}[-1]{ind})
                                 : (),
                                }
                            ]
                    };

                    while (/\G(?=\[)/) {
                        my ($ind) = $self->parse_expr(code => $opt{code});
                        push @{$struct{$self->{class}}[-1]{ind}}, $ind;
                    }
                }

                if (/\G(?!\h*[=-]>)/ && /\G(?=$self->{operators_re})/o) {
                    my ($method, $req_arg, $op_type) = $self->get_method_name(code => $opt{code});

                    my $has_arg;
                    if ($req_arg or exists $self->{binpost_ops}{$method}) {

                        my $lonely_obj = /\G\h*(?=\()/gc;

                        my $code = substr($_, pos);
                        my $arg = (
                                     $lonely_obj
                                   ? $self->parse_arguments(code => \$code)
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
                            $struct{$self->{class}}[-1]{self} = {
                                                                 $self->{class} => [
                                                                          {
                                                                           self => $struct{$self->{class}}[-1]{self},
                                                                           exists($struct{$self->{class}}[-1]{call})
                                                                           ? (call => delete $struct{$self->{class}}[-1]{call})
                                                                           : (),
                                                                           exists($struct{$self->{class}}[-1]{ind})
                                                                           ? (ind => delete $struct{$self->{class}}[-1]{ind})
                                                                           : (),
                                                                          }
                                                                 ]
                                                                };

                            $self->append_method(
                                                 array   => \@{$struct{$self->{class}}[-1]{call}},
                                                 method  => $method,
                                                 arg     => $arg,
                                                 op_type => $op_type,
                                                );
                        }
                        elsif (exists $self->{binpost_ops}{$method}) {
                            ## it's a postfix operator
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
                                       error    => "invalid 'module' declaration",
                                       expected => "expected a name",
                                       code     => $_,
                                       pos      => pos($_)
                                      );

                /\G\h*\{\h*/gc
                  || $self->fatal_error(
                                        error    => "invalid module declaration",
                                        expected => "expected: module $name {...}",
                                        code     => $_,
                                        pos      => pos($_)
                                       );

                my $parser = __PACKAGE__->new(file_name   => $self->{file_name},
                                              script_name => $self->{script_name},);
                local $parser->{line}  = $self->{line};
                local $parser->{class} = $name;
                local $parser->{ref_vars}{$name} = $self->{ref_vars}{$name} if exists($self->{ref_vars}{$name});

                if ($name ne 'main' and not grep $_ eq $name, @Sidef::Exec::NAMESPACES) {
                    push @Sidef::Exec::NAMESPACES, $name;
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

                    my ($var, $code) = $self->find_var($name, $class);

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

            if (/\Ginclude\b\h*/gc) {
                my $expr = eval {
                    local $self->{_want_name} = 1;
                    my $code = substr($_, pos);
                    my ($obj) = $self->parse_expr(code => \$code);
                    pos($_) += pos($code);
                    $obj;
                };

                my @abs_filenames;
                if ($@) {    # an error occured

                    # Try to get variable-like values (e.g.: include Some::Module::Name)
                    my $var_names = $self->get_init_vars(code      => $opt{code},
                                                         with_vals => 0,);

                    @{$var_names}
                      || $self->fatal_error(
                                            code  => $_,
                                            pos   => pos($_),
                                            error => "expected a variable-like `Module::Name'!",
                                           );

                    foreach my $var_name (@{$var_names}) {
                        my @path = split(/::/, $var_name);

                        state $x = require File::Spec;
                        my $mod_path = File::Spec->catfile(@path[0 .. $#path - 1], $path[-1] . '.sm');

                        if (@{$self->{inc}} == 0) {
                            state $y = require File::Basename;
                            push @{$self->{inc}}, split(':', $ENV{SIDEF_INC}) if exists($ENV{SIDEF_INC});
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
                                                            error => "can't find the module '${mod_path}' anywhere in ['"
                                                              . join("', '", @{$self->{inc}}) . "']",
                                                           );

                        push @abs_filenames, [$full_path, $var_name];
                    }
                }
                else {

                    my @files = ref($expr) eq 'HASH' ? Sidef::Types::Block::Code->new($expr)->_execute : $expr;
                    push @abs_filenames, map {
                        my $value = $_;
                        do {
                            $value = $value->get_value;
                        } while (ref($value) and eval { $value->can('get_value') });

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

                    my $parser = __PACKAGE__->new(file_name   => $full_path,
                                                  script_name => $self->{script_name},);

                    local $parser->{class} = $name if defined $name;
                    if (defined $name and $name ne 'main' and not grep $_ eq $name, @Sidef::Exec::NAMESPACES) {
                        push @Sidef::Exec::NAMESPACES, $name;
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

            if (/\G;+/gc) {
                redo;
            }

            my $obj = $self->parse_obj(code => $opt{code});

            my $ref_obj =
                ref($obj) eq 'HASH'
              ? ref($obj->{$self->{class}}[-1]{self})
              : ref($obj);

            if (defined $obj) {
                push @{$struct{$self->{class}}}, {self => $obj};

                if (ref $obj eq 'Sidef::Variable::InitMy') {
                    /\G\h*;+/gc;
                    redo;
                }

                {
                    # Implicit end of statement -- redo
                    ($self->parse_whitespace(code => $opt{code}))[1] && redo MAIN;

                    if (/\G(?:=>|,)/gc) {
                        redo MAIN;
                    }

                    my $is_operator = /\G(?!->)/ && /\G(?=$self->{operators_re})/o;
                    if (   $is_operator
                        || /\G(?:->|\.)\h*/gc
                        || /\G(?=$self->{method_name_re})/o) {

                        # Implicit end of statement -- redo
                        ($self->parse_whitespace(code => $opt{code}))[1] && redo MAIN;

                        my $methods;
                        if ($is_operator) {
                            $methods = $self->parse_methods(code => $opt{code});
                        }
                        else {
                            my $code = '.' . substr($_, pos);
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

                        redo;
                    }
                }
            }

            if (/\G;+/gc) {
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

            #~ # If the object can take a block joined with a 'do' method
            if (exists $self->{obj_with_do}{$ref_obj}) {

                {
                    my ($arg) = $self->parse_expr(code => $opt{code});

                    if (defined $arg) {
                        push @{$struct{$self->{class}}[-1]{call}}, {method => 'do', arg => [$arg]};

                        if (/\G\h*(\R\h*)?(?=$self->{method_name_re}|$self->{operators_re})/goc) {

                            if (defined $1) {
                                $self->{line}++;
                            }

                            my $code = '. ' . substr($_, pos);
                            my $methods = $self->parse_methods(code => \$code);

                            if (@{$methods}) {
                                pos($_) += pos($code) - 2;
                                push @{$struct{$self->{class}}[-1]{call}}, @{$methods};
                                ($self->parse_whitespace(code => $opt{code}))[1] && redo MAIN;
                                redo;
                            }
                        }

                        if (/\G\h*;/gc) {
                            redo MAIN;
                        }
                    }
                }

                redo MAIN;
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
