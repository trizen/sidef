package Sidef::Parser {

    use utf8;
    use 5.014;
    use re 'eval';

    our $DEBUG = 0;

    sub new {
        my (undef, %opts) = @_;

        my %options = (
            line          => 1,
            strict        => 1,
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
            binpost_ops => {                   # binary + postfix operators
                             '...' => 1,
                           },
            obj_with_do => {
                            'Sidef::Types::Block::For'   => 1,
                            'Sidef::Types::Bool::While'  => 1,
                            'Sidef::Types::Bool::If'     => 1,
                            'Sidef::Types::Block::Given' => 1,
                           },
            obj_stat => [
                         {
                          sub => sub { Sidef::Types::Nil::Nil->new },
                          re  => qr/\Gnil\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Bool::Bool->true },
                          re  => qr/\Gtrue\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Bool::Bool->false },
                          re  => qr/\G(?:false|Bool)\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Block::Next->new },
                          re  => qr/\Gnext\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Block::Continue->new },
                          re  => qr/\Gcontinue\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Black::Hole->new },
                          re  => qr/\GBlackHole\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Block::Code->new },
                          re  => qr/\GBlock\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Glob::FileHandle->new(fh => \*ARGV) },
                          re  => qr/\GARGF\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Glob::FileHandle->stdin },
                          re  => qr/\GSTDIN\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Glob::FileHandle->stdout },
                          re  => qr/\GSTDOUT\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Glob::FileHandle->stderr },
                          re  => qr/\GSTDERR\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Glob::Dir->new },
                          re  => qr/\GDir\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Glob::File->new },
                          re  => qr/\GFile\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Glob::Fcntl->new },
                          re  => qr/\GFcntl\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Array::Array->new },
                          re  => qr/\GArr(?:ay)?\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Array::MultiArray->new },
                          re  => qr/\GMultiArr(?:ay)?\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Array::Pair->new },
                          re  => qr/\GPair\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Hash::Hash->new },
                          re  => qr/\GHash\b/,
                         },
                         {
                          sub => sub { Sidef::Types::String::String->new },
                          re  => qr/\GStr(?:ing)?\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Number::Number->new },
                          re  => qr/\GNum(?:ber)?\b/,
                         },
                         {
                          sub => sub { Sidef::Math::Math->new },
                          re  => qr/\GMath\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Glob::Pipe->new },
                          re  => qr/\GPipe\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Byte::Byte->new },
                          re  => qr/\GByte\b/,
                         },
                         {
                          sub => sub { Sidef::Variable::LazyMethod->new },
                          re  => qr/\GLazyMethod\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Byte::Bytes->new },
                          re  => qr/\GBytes\b/,
                         },
                         {
                          sub => sub { Sidef::Time::Time->new('__INIT__') },
                          re  => qr/\GTime\b/,
                         },
                         {
                          sub => sub { Sidef::Sys::SIG->new },
                          re  => qr/\G(?:Sig|SIG)\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Char::Char->new },
                          re  => qr/\GCha?r\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Char::Chars->new },
                          re  => qr/\GCha?rs\b/,
                         },
                         {
                          sub => sub { Sidef::Sys::Sys->new },
                          re  => qr/\GSys\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Regex::Regex->new('') },
                          re  => qr/\GRegex\b/,
                         },
                         {
                          sub => sub { Sidef->new },
                          re  => qr/\GSidef\b/,
                         },
                         {
                          sub => sub { Sidef::Perl::Perl->new },
                          re  => qr/\GPerl\b/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$., 1) },
                          re  => qr/\G\$\./,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$?, 1) },
                          re  => qr/\G\$\?/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$$, 1) },
                          re  => qr/\G\$\$/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$^T, 1) },
                          re  => qr/\G\$\^T\b/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$|, 1) },
                          re  => qr/\G\$\|/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$!, 0) },
                          re  => qr/\G\$!/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$", 0) },
                          re  => qr/\G\$"/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$\, 0) },
                          re  => qr/\G\$\\/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$/, 0) },
                          re  => qr{\G\$/},
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$;, 0) },
                          re  => qr/\G\$;/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$,, 0) },
                          re  => qr/\G\$,/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$^O, 0) },
                          re  => qr/\G\$\^O\b/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$^X, 0) },
                          re  => qr/\G\$\^PERL\b/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$0, 0) },
                          re  => qr/\G\$0\b/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$), 0) },
                          re  => qr/\G\$\)/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$(, 0) },
                          re  => qr/\G\$\(/,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$<, 1) },
                          re  => qr/\G\$</,
                         },
                         {
                          sub => sub { Sidef::Variable::Magic->new(\$>, 1) },
                          re  => qr/\G\$>/,
                         },
                        ],
            obj_keys => [    # this objects can take arguments
                {
                 sub     => sub { Sidef::Types::Bool::If->new },
                 re      => qr/\G(?=if\b)/,
                 dynamic => 1,
                },
                {
                 sub     => sub { Sidef::Types::Bool::While->new },
                 re      => qr/\G(?=while\b)/,
                 dynamic => 1,
                },
                {
                 sub     => sub { Sidef::Types::Block::For->new },
                 re      => qr/\G(?=for(?:each)?\b)/,
                 dynamic => 1,
                },
                {
                 sub     => sub { Sidef::Types::Block::Return->new },
                 re      => qr/\G(?=return\b)/,
                 dynamic => 1,
                },
                {
                 sub     => sub { Sidef::Types::Block::Break->new },
                 re      => qr/\G(?=break\b)/,
                 dynamic => 1,
                },
                {
                 sub     => sub { Sidef::Types::Block::Try->new },
                 re      => qr/\G(?=try\b)/,
                 dynamic => 1,
                },
                {
                 sub     => sub { Sidef::Types::Block::Given->new },
                 re      => qr/\G(?=(?:given|switch)\b)/,
                 dynamic => 1,
                },
                {
                 sub     => sub { Sidef::Module::Require->new },
                 re      => qr/\G(?=require\b)/,
                 dynamic => 1,
                },
                {
                 sub     => sub { Sidef::Sys::Sys->new },
                 re      => qr/\G(?=(?:print(?:ln|f)?+|say|exit|read)\b)/,
                 dynamic => 0,
                },
                {
                 sub => sub { Sidef::Sys::Sys->new(line => $_[0]->{line}, file_name => $_[0]->{file_name}) },
                 re      => qr/\G(?=(?:die|warn)\b)/,
                 dynamic => 1,
                },
                {
                 sub     => sub { Sidef::Types::Block::Code->new },
                 re      => qr/\G(?=loop\b)/,
                 dynamic => 0,
                },
                {
                 sub     => sub { Sidef::Variable::Ref->new() },
                 re      => qr/\G(?=[*\\&]|\+\+|--)/,
                 dynamic => 1,
                },
                {
                 sub     => sub { Sidef::Types::Number::Unary->new },
                 re      => qr/\G(?=[?√+~!-])/,
                 dynamic => 0,
                },
                {
                 sub     => sub { Sidef::Types::Hash::Hash->new },
                 re      => qr/\G(?=:)/,
                 dynamic => 0,
                },
            ],
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
                  require
                  true false
                  nil
                  import
                  include
                  print printf
                  println say

                  File
                  Fcntl
                  Dir
                  Arr Array Pair
                  MultiArray MultiArr
                  Hash
                  Str String
                  Num Number
                  Math
                  Pipe
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
                  eval
                  read
                  die
                  warn
                  exit

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

                  __NO_STRICT__
                  __RESET_LINE_COUNTER__

                  )
            },
            re => {
                match_flags => qr{[msixpogcdual]+},
                var_name    => qr/[[:alpha:]_]\w*(?>::[[:alpha:]_]\w*)*/,
                method_name => qr/[[:alpha:]_]\w*[!:?]?/,
                operators   => do {
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
                      <= ≤ >= ≥ < >
                      ++ --
                      += +
                      -= -
                      /= / ÷= ÷
                      **= **
                      %= %
                      ^= ^
                      *= *
                      ...
                      != ≠ ..
                      \\\\= \\\\
                      ?:
                      ?? ?
                      ! \\
                      : »
                      ~ √
                      );

                    qr{(@operators)};
                },
            },

            # Reference: http://en.wikipedia.org/wiki/International_variation_in_quotation_marks
            delim_pairs => {
                qw~
                  ( )
                  [ ]
                  { }
                  < >
                  « »
                  » «
                  ‹ ›
                  › ‹
                  「 」
                  『 』
                  „ ”
                  “ ”
                  ‘ ’
                  ‚ ’
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

        my $index = index($opt{code}, "\n", $opt{pos});
        $index += ($index == -1) ? (length($opt{code}) + 1) : -$opt{pos};

        my $rindex = rindex($opt{code}, "\n", $opt{pos});
        $rindex += 1;

        my $start = $rindex;
        my $point = $opt{pos} - $start;
        my $len   = $point + $index;

        if ($len > 78) {
            if ($point - $start > 60) {
                $start = ($point - 60);
                $point = $point - $start + $rindex;
                $len   = ($opt{pos} + $index - $start);
            }
            $len = 78 if $len > 78;
        }

        my @lines = (
                     "HAHA! That's really funny! You got me!",
                     "I thought that... Oh, you got me!",
                     "LOL! I expected... Oh, my! This is funny!",
                     "Oh, oh... Wait a second! Did you mean...? Damn!",
                     "You're emberesing me! That's not funny!",
                    );

        require File::Basename;
        my $basename = File::Basename::basename($0);

        my $error =
            "$basename: "
          . $lines[rand @lines] . "\n"
          . ($self->{file_name} // '-') . ':'
          . $self->{line}
          . ": syntax error, "
          . join(', ', grep { defined } $opt{error}, $opt{expected}) . "\n"
          . substr($opt{code}, $start, $len) . "\n";

        my $pointer = ' ' x ($point) . '^' . "\n";
        $self->{strict} ? (die $error, $pointer) : (warn $error, $pointer);
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

        return;
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

        my ($string, $pos) = $self->get_quoted_string(code => $opt{code}, no_count_line => 1);
        if ($string =~ /\G/gc
            && (my ($pos) = $self->parse_whitespace(code => $string))[0]) {
            pos($string) += $pos;
        }

        my @words;
        while ($string =~ /\G((?>[^\s\\]+|\\.)++)/gcs) {
            push @words, $1 =~ s{\\#}{#}gr;

            if ((my ($pos) = $self->parse_whitespace(code => substr($string, pos($string))))[0]) {
                pos($string) += $pos;
                next;
            }
        }

        return (\@words, $pos);
    }

    sub get_quoted_string {
        my ($self, %opt) = @_;

        for ($opt{code}) {

            if (   /\G/gc
                && /\G(?=\s)/
                && (my ($pos) = $self->parse_whitespace(code => substr($_, pos)))[0]) {
                pos($_) += $pos;
            }

            my $delim;
            if (/\G(?=(.))/) {
                $delim = $1;
                if ($delim eq '\\' && /\G\\(.*?)\\/gsc) {
                    return $1, pos;
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
            return $string, pos;
        }
    }

    sub get_method_name {
        my ($self, %opt) = @_;

        for ($opt{code}) {

            if (/\G/gc
                && (my ($pos, $end) = $self->parse_whitespace(code => substr($_, pos)))[0]) {
                pos($_) += $pos;
                $end && return (undef, pos);
            }

            # Alpha-numeric method name
            if (/\G($self->{re}{method_name})/gxoc) {
                return $1, 0, pos;
            }

            # Operator-like method name
            if (m{\G$self->{re}{operators}}goc) {
                return $1, (exists $self->{postfix_ops}{$1} ? 0 : 1), pos;
            }

            # Method name as expression
            my ($obj, $pos) = $self->parse_expr(code => substr($_, pos));
            $obj // return undef, 0, pos($_);
            return {self => $obj}, 0, pos($_) + $pos;
        }
    }

    sub get_init_vars {
        my ($self, %opt) = @_;

        for ($opt{code}) {

            my $end_delim;
            foreach my $key ('|', (keys %{$self->{delim_pairs}})) {
                next if exists $opt{ignore_delim} and exists $opt{ignore_delim}{$key};
                if (/\G\Q$key\E\h*(?(?=\R)\R\h*(?{++$self->{line}}))/gc) {
                    $end_delim = $self->{delim_pairs}{$key} // '|';
                    last;
                }
            }

            my @vars;
            while (/\G(\*?$self->{re}{var_name})/goc) {
                push @vars, $1;
                if ($opt{with_vals} && defined($end_delim) && /\G\h*(?:=|\bis\b)\h*/gc) {
                    my (undef, $pos) = $self->parse_obj(code => substr($_, pos));
                    $vars[-1] .= '=' . substr($_, pos($_), $pos);
                    pos($_) += $pos;
                }
                defined($end_delim)
                  && (/\G\h*,\h*(?(?=\R)\R\h*(?{++$self->{line}}))/gc
                      || last);
            }

            defined($end_delim) && /\G\h*(?(?=\R)\R\h*(?{++$self->{line}}))\h*\Q$end_delim\E/gc;
            return (\@vars, pos($_) // 0);
        }
    }

    sub parse_init_vars {
        my ($self, %opt) = @_;

        for ($opt{code}) {

            my $end_delim;
            foreach my $key ('|', (keys %{$self->{delim_pairs}})) {
                next if exists $opt{ignore_delim} and exists $opt{ignore_delim}{$key};
                if (/\G\Q$key\E\h*(?(?=\R)\R\h*(?{++$self->{line}}))/gc) {
                    $end_delim = $self->{delim_pairs}{$key} // '|';
                    last;
                }
            }

            my @var_objs;
            while (/\G(\*?)($self->{re}{var_name})/goc) {
                my ($attr, $name) = ($1, $2);

                if (exists $self->{keywords}{$name}) {
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => (pos($_) - length($name)),
                                       error => "'$name' is either a keyword or a predefined variable!",
                                      );
                }

                my ($var, $code) = $self->find_var($name, $self->{class});

                if (defined($var) && $code) {
                    warn "[WARN] Redeclaration of $opt{type} '$name' in same scope, at "
                      . "$self->{file_name}, line $self->{line}\n";
                }

                my $value;
                if (defined($end_delim) && /\G\h*(?:=|\bis\b)\h*/gc) {
                    my ($obj, $pos) = $self->parse_obj(code => substr($_, pos));
                    pos($_) += $pos;
                    $value =
                      ref($obj) eq 'HASH'
                      ? Sidef::Types::Block::Code->new($obj)->run
                      : $obj;
                }

                my $obj = Sidef::Variable::Variable->new(
                                                         name => $name,
                                                         type => $opt{type},
                                                         defined($value) ? (value => $value, def_value => 1) : (),
                                                         $attr eq '*' ? (multi => 1) : (),
                                                        );

                if (!$opt{private}) {
                    unshift @{$self->{vars}{$self->{class}}},
                      {
                        obj   => $obj,
                        name  => $name,
                        count => 0,
                        type  => $opt{type},
                        line  => $self->{line},
                      };
                }

                push @var_objs, $obj;
                defined($end_delim)
                  && (/\G\h*,\h*(?(?=\R)\R\h*(?{++$self->{line}}))/gc
                      || last);
            }

            defined($end_delim)
              && (
                  /\G\h*(?(?=\R)\R\h*(?{++$self->{line}}))\h*\Q$end_delim\E/gc
                  || $self->fatal_error(
                                        code  => $_,
                                        pos   => (pos($_) - 1),
                                        error => "unbalanced parentheses",
                                       )
                 );

            return \@var_objs, pos;
        }
    }

    sub parse_whitespace {
        my ($self, %opt) = @_;

        my $beg_line    = $self->{line};
        my $found_space = -1;
        for ($opt{code}) {
            {
                ++$found_space;

                # Whitespace
                if (/\G(?=\s)/) {

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
                                ? Sidef::Types::String::String->new($acc =~ s{\\\\}{\\}gr)
                                : Sidef::Types::String::String->new($acc)->apply_escapes($self)
                              };
                        }

                        redo;
                    }

                    # Horizontal space
                    if (/\G\h+/gc) {
                        redo;
                    }

                    # Vertical space
                    if (/\G\v+/gc) {
                        redo;
                    }
                }

                # Embedded comments (http://perlcabal.org/syn/S02.html#Embedded_Comments)
                if (/\G#`(?=[[:punct:]])/gc) {
                    my (undef, $pos) = $self->get_quoted_string(code => substr($_, pos));
                    pos($_) += $pos;
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
                        return pos, 1;
                    }

                    return pos;
                }

                return;
            }
        }
    }

    sub parse_expr {
        my ($self, %opt) = @_;

        for ($opt{code}) {
            {
                if (/\G/gc
                    && (my ($pos) = $self->parse_whitespace(code => substr($_, pos)))[0]) {
                    pos($_) += $pos;
                }

                # End of an expression, or end of the script
                if (/\G;/gc || /\G\z/) {
                    return undef, pos;
                }

                # Single quoted string
                if (/\G(?=['‘‚’])/ || /\G%q\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => substr($_, pos));
                    return Sidef::Types::String::String->new($string =~ s{\\\\}{\\}gr), pos($_) + $pos;
                }

                # Double quoted string
                if (/\G(?=["“„”])/ || /\G%Q\b/gc || /\G%(?![[:alpha:]])/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    return Sidef::Types::String::String->new($string)->apply_escapes($self), pos($_) + $pos;
                }

                # Single quoted filename
                if (/\G%f\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => substr($_, pos));
                    return Sidef::Types::Glob::File->new($string =~ s{\\\\}{\\}gr), pos($_) + $pos;
                }

                # Double quoted filename
                if (/\G%F\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    return Sidef::Types::Glob::File->new(${Sidef::Types::String::String->new($string)->apply_escapes($self)}),
                      pos($_) + $pos;
                }

                # Single quoted dirname
                if (/\G%d\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => substr($_, pos));
                    return Sidef::Types::Glob::Dir->new($string =~ s{\\\\}{\\}gr), pos($_) + $pos;
                }

                # Double quoted dirname
                if (/\G%D\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    return Sidef::Types::Glob::Dir->new(${Sidef::Types::String::String->new($string)->apply_escapes($self)}),
                      pos($_) + $pos;
                }

                # Single quoted pipe obj
                if (/\G%p\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    return Sidef::Types::Glob::Pipe->new($string =~ s{\\\\}{\\}gr), pos($_) + $pos;
                }

                # Double quoted pipe obj
                if (/\G%P\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    return Sidef::Types::Glob::Pipe->new(${Sidef::Types::String::String->new($string)->apply_escapes($self)}),
                      pos($_) + $pos;
                }

                # Backtick
                if (/\G%X\b/gc || /\G(?=`)/) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));

                    my $obj = Sidef::Types::String::String->new($string)->apply_escapes($self);
                    return {
                            $self->{class} => [
                                               {
                                                self =>
                                                  Sidef::Types::Glob::Backtick->new(
                                                           ref($obj) eq 'HASH' ? Sidef::Types::Block::Code->new($obj) : ${$obj}
                                                  ),
                                                call => [{method => '`'}]
                                               }
                                              ]
                           },
                      pos($_) + $pos;
                }

                if (/\G%x\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    return {$self->{class} =>
                            [{self => Sidef::Types::Glob::Backtick->new($string =~ s{\\\\}{\\}gr), call => [{method => '`'}]}]
                           },
                      pos($_) + $pos;
                }

                # Object as expression
                if (/\G(?=\()/) {
                    my ($obj, $pos) = $self->parse_arguments(code => substr($_, pos));
                    return $obj, pos($_) + $pos;
                }

                # Block as object
                if (/\G(?=\{)/) {
                    my ($obj, $pos) = $self->parse_block(code => substr($_, pos));
                    return $obj, pos($_) + $pos;
                }

                # Array as object
                if (/\G(?=\[)/) {

                    my $array = Sidef::Types::Array::HCArray->new();
                    my ($obj, $pos) = $self->parse_array(code => substr($_, pos));

                    if (ref $obj->{$self->{class}} eq 'ARRAY') {
                        push @{$array}, (@{$obj->{$self->{class}}});
                    }

                    return $array, pos($_) + $pos;
                }

                # Bareword followed by a fat comma or a colon character
                if (   /\G:([[:alpha:]_]\w*)/gc
                    || /\G([[:alpha:]_]\w*)(?=\h*=>|:(?![=:]))/gc) {
                    return Sidef::Types::String::String->new($1), pos;
                }

                # Declaration of variable types
                if (/\G(var|static|const)\b\h*/gc) {
                    my $type = $1;
                    my ($var_objs, $pos) =
                      $self->parse_init_vars(code => substr($_, pos),
                                             type => $type);

                    $pos // $self->fatal_error(
                                               code  => $_,
                                               pos   => pos,
                                               error => "expected a variable name after the keyword '$type'!",
                                              );

                    pos($_) += $pos;
                    return Sidef::Variable::Init->new(@{$var_objs}), pos;
                }

                # Declaration of compile-time evaluated constants
                if (/\Gdefine\h+($self->{re}{var_name})\h*/goc) {
                    my $name = $1;

                    if (exists $self->{keywords}{$name}) {
                        $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_) - length($name)),
                                           error => "'$name' is either a keyword or a predefined variable!",
                                          );
                    }

                    /\G=\h*/gc;    # an optional equal sign is allowed
                    my ($obj, $pos) = $self->parse_expr(code => substr($_, pos));

                    $obj // $self->fatal_error(
                                               code  => $_,
                                               pos   => pos,
                                               error => qq{expected an expression after variable "$name" (near <define>)},
                                              );

                    $obj =
                      ref($obj) eq 'HASH'
                      ? Sidef::Types::Block::Code->new($obj)->run
                      : $obj;

                    pos($_) += $pos;
                    unshift @{$self->{vars}{$self->{class}}},
                      {
                        obj   => $obj,
                        name  => $name,
                        count => 0,
                        type  => 'define',
                        line  => $self->{line},
                      };

                    return $obj, pos;
                }

                # Struct declaration
                if (/\Gstruct\b\h*/gc) {

                    my $name;
                    if (/\G($self->{re}{var_name})\h*/goc) {
                        $name = $1;
                    }

                    if (defined $name and exists $self->{keywords}{$name}) {
                        $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_) - length($name)),
                                           error => "'$name' is either a keyword or a predefined variable!",
                                          );
                    }

                    my ($vars, $pos) =
                      $self->parse_init_vars(
                                             code      => substr($_, pos),
                                             with_vals => 1,
                                             private   => 1,
                                             type      => 'var',
                                            );
                    pos($_) += $pos;

                    my $struct = Sidef::Variable::Struct->__new($vars);

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

                    return $struct, pos;
                }

                # Declaration of enums
                if (/\Genum\b\h*/gc) {
                    my ($vars, $pos) = $self->get_init_vars(code => substr($_, pos));
                    pos($_) += $pos;

                    @{$vars}
                      || $self->fatal_error(
                                            code  => $_,
                                            pos   => pos,
                                            error => q{expected one or more variable names after <enum>},
                                           );

                    foreach my $i (0 .. $#{$vars}) {
                        my $name = $vars->[$i];

                        if (exists $self->{keywords}{$name}) {
                            $self->fatal_error(
                                               code  => $_,
                                               pos   => (pos($_) - length($name)),
                                               error => "'$name' is either a keyword or a predefined variable!",
                                              );
                        }

                        unshift @{$self->{vars}{$self->{class}}},
                          {
                            obj   => Sidef::Types::Number::Number->new($i),
                            name  => $name,
                            count => 0,
                            type  => 'enum',
                            line  => $self->{line},
                          };
                    }

                    return (Sidef::Types::Number::Number->new($#{$vars}), pos);
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
                        my ($obj, $pos) = eval { $self->parse_expr(code => substr($_, pos($_))) };
                        if (not $@ and defined $obj) {
                            pos($_) += $pos;
                            $built_in_obj = ref($obj) eq 'HASH' ? Sidef::Types::Block::Code->new($obj)->run : $obj;
                        }
                    }

                    my $name = '';
                    if (not defined $built_in_obj) {
                        $name =
                            /\G($self->{re}{var_name})\h*/goc ? $1
                          : $type eq 'method' && /\G($self->{re}{operators})\h*/goc ? $1
                          : $type ne 'my' ? ''
                          : $self->fatal_error(
                                               error    => "invalid '$type' declaration",
                                               expected => "expected a name",
                                               code     => $_,
                                               pos      => pos($_)
                                              );
                    }

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
                      : $type eq 'func'   ? Sidef::Variable::Variable->new(name => $name, type => $type)
                      : $type eq 'method' ? Sidef::Variable::Variable->new(name => $name, type => $type)
                      : $type eq 'class'  ? Sidef::Variable::ClassInit->__new($name)
                      : $self->fatal_error(
                                           error    => "invalid type",
                                           expected => "a magic thing to happen",
                                           code     => $_,
                                           pos      => pos($_),
                                          );

                    unshift @{$self->{vars}{$self->{class}}},
                      {
                        obj   => $obj,
                        name  => $name,
                        count => 0,
                        type  => $type,
                        line  => $self->{line},
                      };

                    if ($type eq 'my') {
                        return Sidef::Variable::InitMy->new($name), pos($_);
                    }

                    if ($type eq 'class') {
                        my ($var_names, $pos1) =
                          $self->parse_init_vars(
                                                 code         => substr($_, pos),
                                                 with_vals    => 1,
                                                 private      => 1,
                                                 ignore_delim => {
                                                                  '{' => 1,
                                                                  '<' => 1,
                                                                 },
                                                );
                        pos($_) += $pos1 if defined $pos1;

                        # Class inheritance (class Name(...) << Name1, Name2)
                        if (/\G\h*<<?\h*/gc) {
                            while (/\G($self->{re}{var_name})\h*/gco) {
                                my ($name) = $1;
                                my ($class, $code) = $self->find_var($name, $self->{class});
                                if (ref $class) {
                                    if ($class->{type} eq 'class') {
                                        while (my ($name, $method) = each %{$class->{obj}{__METHODS__}}) {
                                            ($built_in_obj // $obj)->__add_method($name, $method);
                                        }
                                    }
                                    else {
                                        $self->fatal_error(
                                                           error    => "this is not a class",
                                                           expected => "expected a class name",
                                                           code     => $_,
                                                           pos      => pos($_) - length($name),
                                                          );
                                    }
                                }
                                else {
                                    $self->fatal_error(
                                                       error    => "can't find '$name' class",
                                                       expected => "expected an existent class name",
                                                       code     => $_,
                                                       pos      => pos($_) - length($name),
                                                      );
                                }

                                /\G,\h*/gc;
                            }
                        }

                        /\G\h*\{\h*/gc
                          || $self->fatal_error(
                                                error    => "invalid class declaration",
                                                expected => "expected: class $name(...){...}",
                                                code     => $_,
                                                pos      => pos($_)
                                               );

                        local $self->{class_name} = $name;
                        local $self->{current_class} = $built_in_obj // $obj;
                        my ($block, $pos) = $self->parse_block(code => '{' . substr($_, pos));
                        pos($_) += $pos - 1;

                        $obj->__set_value($block, $var_names);
                    }

                    if ($type eq 'func' or $type eq 'method') {

                        my ($var_names, $pos1) =
                          $self->get_init_vars(
                                               code         => substr($_, pos),
                                               with_vals    => 1,
                                               ignore_delim => {
                                                                '{' => 1,
                                                                '-' => 1,
                                                               }
                                              );
                        pos($_) += $pos1;

                        # Function return type (func name(...) -> Type {...})
                        # XXX: [KNOWN BUG] It doesn't check the returned type from method calls
                        if (/\G\h*(?:->|returns\b)\h*/gc) {
                            my ($r_obj, $pos) = $self->parse_expr(code => substr($_, pos));
                            pos($_) += $pos;

                            ref($r_obj) eq 'HASH'
                              and $self->fatal_error(
                                                     error    => "invalid return-type for function '$obj->{name}'",
                                                     expected => "expected a valid type, such as: Str, Num, Arr, etc...",
                                                     code     => $_,
                                                     pos      => pos($_) - $pos
                                                    );

                            $obj->{returns} = $r_obj;
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
                        my ($block, $pos) = $self->parse_block(code => '{' . $args . substr($_, pos));
                        pos($_) += $pos - (length($args) + 1);

                        $obj->set_value($block);
                        $self->{current_class}->__add_method($name, $block) if $type eq 'method';
                    }

                    return $obj, pos;
                }

                if (exists $self->{current_class} and /\Gdefine_method\b\h*/gc) {
                    my ($name, $pos) = $self->parse_expr(code => substr($_, pos($_)));
                    pos($_) += $pos;

                    my ($method, $pos2) = $self->parse_expr(code => 'method ' . substr($_, pos($_)));
                    pos($_) += $pos2 - 7;

                    return scalar {
                        $self->{class} => [
                                           {
                                            self => $self->{current_class},
                                            call => [
                                                     {
                                                      method => 'define_method',
                                                      arg    => [
                                                              {
                                                               $self->{class} => [{self => $name},
                                                                                  {
                                                                                   self => {
                                                                                            $self->{class} => [
                                                                                                 {
                                                                                                  call => [{method => 'copy'}],
                                                                                                  self => $method,
                                                                                                 },
                                                                                            ],
                                                                                           },
                                                                                  }
                                                                                 ],
                                                              }
                                                             ]
                                                     }
                                                    ]
                                           }
                                          ]

                                  },
                      pos($_);

                }

                # Binary, hexdecimal and octal numbers
                if (/\G0(b[10_]*|x[0-9A-Fa-f_]*|[0-9_]+\b)/gc) {
                    my $number = "0" . ($1 =~ tr/_//dr);
                    require Math::BigInt;
                    return
                      Sidef::Types::Number::Number->new(
                                                        $number =~ /^0[0-9]/
                                                        ? Math::BigInt->from_oct($number)
                                                        : Math::BigInt->new($number)
                                                       ),
                      pos;
                }

                # Integer or float number
                if (/\G([+-]?+(?=\.?[0-9])[0-9_]*+(?:\.[0-9_]++)?(?:[Ee](?:[+-]?+[0-9_]+))?)/gc) {
                    return Sidef::Types::Number::Number->new($1 =~ tr/_//dr), pos;
                }

                # Implicit method call on special variable: _
                if (/\G\./) {
                    my ($var) = $self->find_var('_', $self->{class});

                    if (defined $var) {
                        $var->{count}++;
                        ref($var->{obj}) eq 'Sidef::Variable::Variable' && do {
                            $var->{obj}{in_use} = 1;
                        };
                        return $var->{obj}, pos;
                    }

                    $self->fatal_error(
                                       code  => $_,
                                       pos   => pos($_) - 1,
                                       error => "attempt to use an implicit method call on the uninitialized variable: \"_\"",
                                      );
                }

                # Quoted words (%w/a b c/)
                if (/\G%([wW])\b/gc || /\G(?=(«|<(?!<)))/) {
                    my ($type) = $1;
                    my ($strings, $pos) = $self->get_quoted_words(code => substr($_, pos));

                    if ($type eq 'w' or $type eq '<') {
                        return (
                                Sidef::Types::Array::Array->new(
                                              map { Sidef::Types::String::String->new($_ =~ s{\\(?=[\\#\s])}{}gr) } @{$strings}
                                ),
                                pos($_) + $pos
                               );
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
                            : Sidef::Types::Array::Array->new(@objs),
                            pos($_) + $pos
                           );
                }

                foreach my $hash_ref (@{$self->{obj_keys}}) {
                    if (/$hash_ref->{re}/) {
                        return (
                                (
                                   $hash_ref->{dynamic}
                                 ? $hash_ref->{sub}->($self)
                                 : ($self->{static_objects}{$hash_ref} //= $hash_ref->{sub}->())
                                ),
                                pos, 1
                               );
                    }
                }

                # Eval keyword
                if (/\G(?=eval\b)/) {
                    return Sidef::Eval::Eval->new($self, {$self->{class} => [@{$self->{vars}{$self->{class}}}]}), pos, 1;
                }

                if (/\GParser\b/gc) {
                    return $self, pos;
                }

                # Regular expression
                if (m{\G(?=/)} || /\G%r\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    pos($_) += $pos;
                    return Sidef::Types::Regex::Regex->new($string, /\G($self->{re}{match_flags})/goc ? $1 : undef, $self),
                      pos;
                }

                foreach my $hash_ref (@{$self->{obj_stat}}) {
                    if (/$hash_ref->{re} (?!::)/gxc) {
                        return (($self->{static_objects}{$hash_ref} //= $hash_ref->{sub}->()), pos);
                    }
                }

                if (/\G__RESET_LINE_COUNTER__\b;*/gc) {
                    $self->{line} = 0;
                    redo;
                }

                if (/\G__MAIN__\b/gc) {
                    return Sidef::Types::String::String->new($self->{script_name}), pos;
                }

                if (/\G__FILE__\b/gc) {
                    return Sidef::Types::String::String->new($self->{file_name}), pos;
                }

                if (/\G__DATE__\b/gc) {
                    my (undef, undef, undef, $day, $mon, $year) = localtime;
                    return Sidef::Types::String::String->new(
                                                      join('-', $year + 1900, map { sprintf "%02d", $_ } $mon + 1, $day)), pos;
                }

                if (/\G__TIME__\b/gc) {
                    my ($sec, $min, $hour) = localtime;
                    return Sidef::Types::String::String->new(join(':', map { sprintf "%02d", $_ } $hour, $min, $sec)), pos;
                }

                if (/\G__LINE__\b/gc) {
                    return Sidef::Types::Number::Number->new($self->{line}), pos;
                }

                if (/\G__(?:END|DATA)__\b\h*+\R?/gc) {
                    if (exists $self->{'__DATA__'}) {
                        $self->{'__DATA__'} = substr($_, pos);
                    }

                    return undef, length($_);
                }

                if (/\GDATA\b/gc) {
                    return +(
                        $self->{static_objects}{'__DATA__'} //= do {
                            open my $str_fh, '<:utf8', \$self->{'__DATA__'};
                            Sidef::Types::Glob::FileHandle->new(fh   => $str_fh,
                                                                file => Sidef::Types::Nil::Nil->new);
                          }
                      ),
                      pos;
                }

                # Begining of here-document (<<"EOT", <<'EOT', <<EOT)
                if (/\G<<(?=\S)/gc) {
                    my ($name, $type) = (undef, 1);

                    if (/\G(?=(['"]))/) {
                        $type = 0 if $1 eq q{'};
                        my ($str, $pos) = $self->get_quoted_string(code => substr($_, pos));
                        pos($_) += $pos;
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

                    return $obj, pos($_);
                }

                if (/\G__USE_BIGNUM__\b;*/gc) {
                    delete $INC{'Sidef/Types/Number/Number.pm'};
                    require Sidef::Types::Number::Number;
                    redo;
                }

                if (/\G__USE_FASTNUM__\b;*/gc) {
                    delete $INC{'Sidef/Types/Number/NumberFast.pm'};
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
                    return $self->{current_block}, pos;
                }

                if (/\G__NAMESPACE__\b/gc) {
                    return Sidef::Types::String::String->new($self->{class}), pos;
                }

                if (exists($self->{current_function})) {
                    return ($self->{current_function},                                          pos) if /\G__FUNC__\b/gc;
                    return (Sidef::Types::String::String->new($self->{current_function}{name}), pos) if /\G__FUNC_NAME__\b/gc;
                }

                if (exists($self->{current_class})) {
                    return ($self->{current_class},                                 pos) if /\G__CLASS__\b/gc;
                    return (Sidef::Types::String::String->new($self->{class_name}), pos) if /\G__CLASS_NAME__\b/gc;
                }

                if (exists($self->{current_method})) {
                    return ($self->{current_method},                                          pos) if /\G__METHOD__\b/gc;
                    return (Sidef::Types::String::String->new($self->{current_method}{name}), pos) if /\G__METHOD_NAME__\b/gc;
                }

                if (
                    /\G(ENV|ARGV)\b/gc && do {
                        ref(($self->find_var($1, $self->{class}))[0])
                          ? do { pos($_) -= length($1); 0 }
                          : 1;
                    }
                  ) {
                    my $name = $1;
                    my $type = 'var';

                    my $variable = Sidef::Variable::Variable->new(name => $name, type => $type);

                    unshift @{$self->{vars}{$self->{class}}},
                      {
                        obj   => $variable,
                        name  => $name,
                        count => 1,
                        type  => $type,
                        line  => $self->{line},
                      };

                    if ($name eq 'ARGV') {
                        require Encode;
                        my $array =
                          Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new(Encode::decode_utf8($_)) }
                                                          @ARGV);
                        $variable->set_value($array);
                    }
                    elsif ($name eq 'ENV') {
                        require Encode;
                        my $hash =
                          Sidef::Types::Hash::Hash->new(map { Sidef::Types::String::String->new(Encode::decode_utf8($_)) }
                                                        %ENV);
                        $variable->set_value($hash);
                    }

                    return $variable, pos;
                }

                # Variable call
                if (/\G($self->{re}{var_name})/goc) {
                    my ($name, $class) = $self->get_name_and_class($1);
                    my ($var, $code) = $self->find_var($name, $class);

                    if (ref $var) {
                        $var->{count}++;
                        ref($var->{obj}) eq 'Sidef::Variable::Variable' && do {
                            $var->{obj}{in_use} = 1;
                        };
                        return $var->{obj}, pos;
                    }
                    elsif (/\G(?=\h*:?=(?![=~>]))/) {

                        #warn qq{[!] Implicit declaration of variable "$name", at line $self->{line}\n};
                        unshift @{$self->{vars}{$class}},
                          {
                            obj   => Sidef::Variable::My->new($name),
                            name  => $name,
                            count => 0,
                            type  => 'my',
                            line  => $self->{line},
                          };

                        return Sidef::Variable::InitMy->new($name), pos($_) - length($name);
                    }

                    $self->fatal_error(
                                       code  => $_,
                                       pos   => (pos($_) - length($name)),
                                       error => "attempt to use an uninitialized variable <$1>",
                                      );
                }

                # Regex variables ($1, $2, ...)
                if (/\G\$([0-9]+)\b/gc) {
                    return ($self->{regexp_vars}{$1} //= Sidef::Variable::Variable->new(name => $1, type => 'var'), pos);
                }

                /\G\$/gc && redo;

                #warn "$self->{script_name}:$self->{line}: unexpected char: " . substr($_, pos($_), 1) . "\n";
                #return undef, pos($_) + 1;

                return undef, pos($_);
            }
        }
    }

    sub parse_arguments {
        my ($self, %opt) = @_;

        for ($opt{code}) {
            if (/\G\(/gc) {

                $self->{parentheses}++;
                my ($obj, $pos) = $self->parse_script(code => substr($_, pos));

                $pos // $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_) - 1),
                                           error => "unbalanced parentheses",
                                          );

                return $obj, pos($_) + $pos;
            }
        }
    }

    sub parse_array {
        my ($self, %opt) = @_;

        for ($opt{code}) {
            if (/\G\[/gc) {

                $self->{right_brackets}++;
                my ($obj, $pos) = $self->parse_script(code => substr($_, pos));

                $pos // $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_) - 1),
                                           error => "unbalanced right brackets",
                                          );

                return $obj, pos($_) + $pos;
            }
        }
    }

    sub parse_block {
        my ($self, %opt) = @_;

        for ($opt{code}) {
            if (/\G\{/gc) {

                $self->{curly_brackets}++;

                my $ref = $self->{vars}{$self->{class}} //= [];
                my $count = scalar(@{$self->{vars}{$self->{class}}});

                unshift @{$self->{ref_vars_refs}{$self->{class}}}, @{$ref};
                unshift @{$self->{vars}{$self->{class}}}, [];

                $self->{vars}{$self->{class}} = $self->{vars}{$self->{class}}[0];

                my $block = Sidef::Types::Block::Code->new({});
                local $self->{current_block} = $block;

                if ((my ($pos) = $self->parse_whitespace(code => substr($_, pos)))[0]) {
                    pos($_) += $pos;
                }

                my $var_objs = [];
                if (/\G(?=\|)/) {
                    my ($vars, $pos) =
                      $self->parse_init_vars(code => substr($_, pos),
                                             type => 'var');
                    pos($_) += $pos;
                    $var_objs = $vars;
                }

                {    # special '_' variable
                    state $name = '_';
                    state $type = 'var';

                    my $var_obj = Sidef::Variable::Variable->new(name => $name, type => $type);
                    push @{$var_objs}, $var_obj;
                    unshift @{$self->{vars}{$self->{class}}},
                      {
                        obj   => $var_obj,
                        name  => $name,
                        count => 0,
                        type  => $type,
                        line  => $self->{line},
                      };
                }

                my ($obj, $pos) = $self->parse_script(code => substr($_, pos));
                $pos // $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_) - 1),
                                           error => "unbalanced curly brackets",
                                          );

                $block->{vars} = [map  { $_->{obj} }
                                  grep { ref($_) eq 'HASH' } @{$self->{vars}{$self->{class}}}
                                 ];

                $block->{init_vars} = [map { Sidef::Variable::Init->new($_) } @{$var_objs}];

                $block->{code} = $obj;
                splice @{$self->{ref_vars_refs}{$self->{class}}}, 0, $count;
                $self->{vars}{$self->{class}} = $ref;

                return $block, pos($_) + $pos;
            }
        }
    }

    sub parse_methods {
        my ($self, %opt) = @_;

        my @methods;
        for ($opt{code}) {

            pos($_) = 0;
            {
                if ((/\G(?![-=]>)/ && /\G(?=$self->{re}{operators})/o)
                    || /\G\./goc) {
                    my ($method, $req_arg, $pos) = $self->get_method_name(code => substr($_, pos));

                    if (defined($method)) {
                        pos($_) += $pos;

                        my $has_arg;
                        if (/\G\h*(?=[({])/gc || $req_arg || exists($self->{binpost_ops}{$method})) {
                            my ($arg, $pos) =
                                /\G(?=\()/ ? $self->parse_arguments(code => substr($_, pos))
                              : $req_arg || exists($self->{binpost_ops}{$method}) ? $self->parse_obj(code => substr($_, pos))
                              : /\G(?=\{)/ ? $self->parse_block(code => substr($_, pos))
                              :              die "[PARSING ERROR] Something wrong in the if condition!";

                            if (defined $arg) {
                                $has_arg = 1;
                                pos($_) += $pos;
                                push @methods, {method => $method, arg => [$arg]};
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
                            push @methods, {method => $method};
                        };
                        redo;
                    }
                }
            }

            return \@methods, pos;
        }
    }

    sub parse_obj {
        my ($self, %opt) = @_;

        my %struct;
        for ($opt{code}) {
            pos($_) = 0;

            my ($obj, $pos, $obj_key) = $self->parse_expr(code => substr($_, pos));
            pos($_) += $pos;

            # This object can't take any method!
            if (ref $obj eq 'Sidef::Variable::InitMy') {
                return $obj, pos;
            }

            if (
                #    (ref($obj) eq 'Sidef::Variable::Variable' and ($obj->{type} eq 'func' || $obj->{type} eq 'method'))
                # || (ref($obj) eq 'Sidef::Variable::ClassInit')
                # || (ref($obj) eq 'Sidef::Types::Block::Code')
                #  and
                /\G\h*(?=\()/gc
              ) {
                my ($arg, $pos) = $self->parse_arguments(code => substr($_, pos));
                pos($_) += $pos;
                $obj = {
                        $self->{class} => [
                                           {
                                            self => $obj,
                                            call => [
                                                     {
                                                      method => ref($obj) eq 'Sidef::Variable::ClassInit'
                                                      ? 'init'
                                                      : 'call',
                                                      arg => [$arg]
                                                     }
                                                    ]
                                           }
                                          ]
                       };
            }

            if (defined $obj) {
                push @{$struct{$self->{class}}}, {self => $obj};

                if ($obj_key) {
                    my ($method, $req_arg, $pos) = $self->get_method_name(code => substr($_, pos));
                    pos($_) += $pos;

                    if (defined $method) {

                        if (/\G\h*(?!;)/gc) {
                            my ($arg_obj, $pos) =
                              /\G(?=\()/
                              ? $self->parse_arguments(code => substr($_, pos))
                              : $self->parse_obj(code => substr($_, pos));
                            pos($_) += $pos;

                            if (defined $arg_obj) {
                                push @{$struct{$self->{class}}[-1]{call}}, {method => $method, arg => [$arg_obj]};
                            }
                        }
                    }
                    else {
                        die "[PARSER ERROR] The same object needs to be parsed again as a method for itself!";
                    }
                }

                while (/\G(?=\[)/) {
                    my ($ind, $pos) = $self->parse_expr(code => substr($_, pos));
                    pos($_) += $pos;
                    push @{$struct{$self->{class}}[-1]{ind}}, $ind;
                }

                my @methods;
                {

                    if (/\G(?=\.(?:$self->{re}{method_name}|\())/o) {
                        my ($methods, $pos) = $self->parse_methods(code => substr($_, pos));
                        pos($_) += $pos;
                        push @{$struct{$self->{class}}[-1]{call}}, @{$methods};
                    }

                    if (/\G(?=\[)/) {
                        $struct{$self->{class}}[-1]{self} = {
                            $self->{class} => [
                                {
                                 self => $struct{$self->{class}}[-1]{self},
                                 exists($struct{$self->{class}}[-1]{call}) ? (call => delete $struct{$self->{class}}[-1]{call})
                                 : (),
                                 exists($struct{$self->{class}}[-1]{ind})
                                 ? (ind => delete $struct{$self->{class}}[-1]{ind})
                                 : (),
                                }
                            ]
                        };

                        while (/\G(?=\[)/) {
                            my ($ind, $pos) = $self->parse_expr(code => substr($_, pos));
                            pos($_) += $pos;
                            push @{$struct{$self->{class}}[-1]{ind}}, $ind;
                        }
                    }

                    if (/\G(?!\h*[=-]>)/ && /\G(?=$self->{re}{operators})/o) {
                        my ($method, $req_arg, $pos) = $self->get_method_name(code => substr($_, pos));
                        pos($_) += $pos;

                        my $has_arg;
                        if ($req_arg or exists $self->{binpost_ops}{$method}) {
                            my ($arg, $pos) =
                              /\G\h*(?=\()/gc
                              ? $self->parse_arguments(code => substr($_, pos))
                              : $self->parse_obj(code => substr($_, pos));

                            if (defined $arg) {
                                pos($_) += $pos;
                                my ($methods, $pos) = $self->parse_methods(code => substr($_, pos));
                                pos($_) += $pos;

                                if (ref $arg ne 'HASH') {
                                    $arg = {$self->{class} => [{self => $arg}]};
                                }

                                if (@{$methods}) {
                                    push @{$arg->{$self->{class}}[-1]{call}}, @{$methods};
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

                                push @{$struct{$self->{class}}[-1]{call}}, {method => $method, arg => [$arg]};
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
                            push @{$struct{$self->{class}}[-1]{call}}, {method => $method};
                        };
                        redo;
                    }
                }
            }
            else {
                return undef, pos;
            }

            return \%struct, pos;

        }
    }

    sub parse_script {
        my ($self, %opt) = @_;

        if ($opt{code} =~ /\G/gc && (my ($pos) = $self->parse_whitespace(code => $opt{code}))[0]) {
            pos($opt{code}) += $pos;
        }

        # Locally deactivate some restrictions
        local $self->{strict} = 0 if $opt{code} =~ /\G__NO_STRICT__\b;*/gc;

        my $pos = pos($opt{code});

        my %struct;
        for ($opt{code}) {
            pos($_) = $pos;
          MAIN: {
                if ((my ($pos) = $self->parse_whitespace(code => substr($_, pos)))[0]) {
                    pos($_) += $pos;
                }

                # Module declaration
                if (/\Gmodule\b\h*/gc) {
                    my $name =
                      /\G($self->{re}{var_name})\h*/goc
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

                    my $parser = __PACKAGE__->new(
                                                  file_name   => $self->{file_name},
                                                  script_name => $self->{script_name},
                                                  strict      => $self->{strict},
                                                 );
                    local $parser->{line}  = $self->{line};
                    local $parser->{class} = $name;
                    local $parser->{ref_vars}{$name} = $self->{ref_vars}{$name} if exists($self->{ref_vars}{$name});

                    if ($name ne 'main' and not grep $_ eq $name, @Sidef::Exec::NAMESPACES) {
                        push @Sidef::Exec::NAMESPACES, $name;
                    }
                    my ($struct, $pos) = $parser->parse_block(code => '{' . substr($_, pos));
                    pos($_) += $pos - 1;
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

                    my ($var_names, $pos) =
                      $self->get_init_vars(code      => substr($_, pos),
                                           with_vals => 0);
                    pos($_) += $pos;

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
                    my ($expr, $pos) = eval { $self->parse_expr(code => substr($_, pos)) };

                    my @abs_filenames;
                    if ($@) {    # an error occured

                        # Try to get variable-like values (e.g.: include Some::Module::Name)
                        my ($var_names, $pos) =
                          $self->get_init_vars(code => substr($_, pos), with_vals => 0);
                        pos($_) += $pos;

                        @{$var_names}
                          || $self->fatal_error(
                                                code  => $_,
                                                pos   => (pos($_)),
                                                error => "expected a variable-like `Module::Name'!",
                                               );

                        foreach my $var_name (@{$var_names}) {
                            my @path = split(/::/, $var_name);

                            require File::Spec;
                            my $mod_path = File::Spec->catfile(@path[0 .. $#path - 1], $path[-1] . '.sm');

                            if (@{$self->{inc}} == 0) {
                                require File::Basename;
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
                                                   error => 'include-error: invalid value of type "'
                                                     . ref($value)
                                                     . '" (expected a plain-string)',
                                                  )
                              : [$value];
                        } @files;
                        pos($_) += $pos;
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
                                                      file_name   => $full_path,
                                                      script_name => $self->{script_name},
                                                      strict      => $self->{strict},
                                                     );

                        local $parser->{class} = $name if defined $name;
                        if (defined $name and $name ne 'main' and not grep $_ eq $name, @Sidef::Exec::NAMESPACES) {
                            push @Sidef::Exec::NAMESPACES, $name;
                        }
                        my $struct = $parser->parse_script(code => $content);

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

                my ($obj, $pos) = $self->parse_obj(code => substr($_, pos));
                pos($_) += $pos;

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
                        if ((my ($pos, $end) = $self->parse_whitespace(code => substr($_, pos)))[0]) {
                            pos($_) += $pos;
                            $end and redo MAIN;
                        }

                        if (/\G(?:=>|,)/gc) {
                            redo MAIN;
                        }

                        my $is_operator = /\G(?!->)/ && /\G(?=$self->{re}{operators})/o;
                        if (   $is_operator
                            || /\G(?:->|\.)\h*/gc
                            || /\G(?=$self->{re}{method_name})/o) {

                            if ((my ($pos, $end) = $self->parse_whitespace(code => substr($_, pos)))[0]) {
                                pos($_) += $pos;
                                $end && redo MAIN;
                            }

                            my ($methods, $pos) =
                              $self->parse_methods(
                                                   code => $is_operator
                                                   ? substr($_, pos)
                                                   : ("." . substr($_, pos))
                                                  );

                            pos($_) += $pos - ($is_operator ? 0 : 1);

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

                    my $check_vars;
                    $check_vars = sub {
                        my ($hash_ref) = @_;

                        foreach my $class (grep { $_ eq 'main' } keys %{$hash_ref}) {

                            my $array_ref = $hash_ref->{$class};

                            foreach my $variable (@{$array_ref}) {
                                if (ref $variable eq 'ARRAY') {
                                    $check_vars->({$class => $variable});
                                }
                                elsif (   $variable->{count} == 0
                                       && $variable->{type} ne 'class'
                                       && $variable->{type} ne 'func'
                                       && $variable->{type} ne 'method'
                                       && $variable->{name} ne 'self'
                                       && $variable->{name} ne ''
                                       && chr(ord $variable->{name}) ne '_') {
                                    warn '[WARN] '
                                      . (
                                         $variable->{type} eq 'const'
                                           || $variable->{type} eq 'define' || $variable->{type} eq 'enum'
                                         ? 'Constant'
                                         : 'Variable'
                                        )
                                      . " '$variable->{name}' has been initialized, but not used again, at "
                                      . "$self->{file_name}, line $variable->{line}\n";
                                }
                                elsif ($DEBUG) {
                                    warn "[WARN] Variable '$variable->{name}' is used $variable->{count} times!\n";
                                }
                            }
                        }

                    };

                    $check_vars->($self->{ref_vars});

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

                    return (\%struct, pos);
                }

                if (/\G\}/gc) {

                    if (--$self->{curly_brackets} < 0) {
                        $self->fatal_error(
                                           error => 'unbalanced curly brackets',
                                           code  => $_,
                                           pos   => pos($_) - 1,
                                          );
                    }

                    return (\%struct, pos);
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

                    return (\%struct, pos);
                }

                # If the object can take a block joined with a 'do' method
                if (exists $self->{obj_with_do}{$ref_obj}) {

                    {
                        my ($arg, $pos) = $self->parse_expr(code => substr($_, pos));

                        if (defined $arg) {
                            pos($_) += $pos;
                            push @{$struct{$self->{class}}[-1]{call}}, {method => 'do', arg => [$arg]};

                            if (/\G\h*(\R\h*)?(?=$self->{re}{method_name})/goc) {

                                if (defined $1) {
                                    $self->{line}++;
                                }

                                my ($methods, $pos) = $self->parse_methods(code => "." . substr($_, pos));

                                if (@{$methods}) {
                                    pos($_) += $pos - 1;
                                    push @{$struct{$self->{class}}[-1]{call}}, @{$methods};

                                    if ((my ($pos, $end) = $self->parse_whitespace(code => substr($_, pos)))[0]) {
                                        pos($_) += $pos;
                                        $end and redo MAIN;
                                    }

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
    }
};

1
