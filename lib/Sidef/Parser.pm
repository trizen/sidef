package Sidef::Parser {

    use utf8;
    use 5.014;
    use strict;
    use warnings;

    require File::Spec;
    require Sidef::Init;

    our $DEBUG = 0;

    sub new {

        my (undef, %opts) = @_;

        my %options = (
            line          => 1,
            has_object    => 0,
            has_method    => 0,
            expect_method => 0,
            expect_index  => 0,
            expect_arg    => 0,
            parentheses   => 0,
            strict_var    => 0,
            inc           => [File::Spec->curdir()],
            class         => 'main',
            vars          => {'main' => []},
            ref_vars_refs => {'main' => []},
            lonely_ops    => {
                           '--'  => 1,
                           '++'  => 1,
                           '??'  => 1,
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
                          sub => sub { Sidef::Types::Glob::Dir->new },
                          re  => qr/\GDir\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Glob::File->new },
                          re  => qr/\GFile\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Array::Array->new },
                          re  => qr/\GArr(?:ay)?\b/,
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
                          sub => sub { Sidef::Types::Byte::Bytes->new },
                          re  => qr/\GBytes\b/,
                         },
                         {
                          sub => sub { Sidef::Time::Time->new },
                          re  => qr/\GTime\b/,
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
                          sub => sub { Sidef::Types::Bool::Bool->new },
                          re  => qr/\GBool\b/,
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
                          sub => sub { Sidef::Types::Nil::Nil->new },
                          re  => qr/\Gnil\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Bool::Bool->true },
                          re  => qr/\Gtrue\b/,
                         },
                         {
                          sub => sub { Sidef::Types::Bool::Bool->false },
                          re  => qr/\Gfalse\b/,
                         },
                        ],
            obj_keys => [
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
                          sub     => sub { Sidef::Types::Block::Continue->new },
                          re      => qr/\G(?=continue\b)/,
                          dynamic => 0,
                         },
                         {
                          sub     => sub { Sidef::Types::Block::Return->new },
                          re      => qr/\G(?=return\b)/,
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
                          sub     => sub { Sidef::Types::Block::Break->new },
                          re      => qr/\G(?=break\b)/,
                          dynamic => 0,
                         },
                         {
                          sub     => sub { Sidef::Types::Block::Next->new },
                          re      => qr/\G(?=next\b)/,
                          dynamic => 0,
                         },
                         {
                          sub     => sub { Sidef::Module::Require->new },
                          re      => qr/\G(?=require\b)/,
                          dynamic => 1,
                         },
                         {
                          sub     => sub { Sidef::Types::Bool::Bool->new },
                          re      => qr/\G(?=!)/,
                          dynamic => 0,
                         },
                         {
                          sub     => sub { Sidef::Types::Number::Negative->new },
                          re      => qr/\G(?=-)/,
                          dynamic => 0,
                         },
                         {
                          sub     => sub { Sidef::Types::Number::Positive->new },
                          re      => qr/\G(?=\+)/,
                          dynamic => 0,
                         },
                         {
                          sub     => sub { Sidef::Types::Block::Code->new({}) },
                          re      => qr/\G(?=:)/,
                          dynamic => 0,
                         },
                         {
                          sub     => sub { Sidef::Variable::Ref->new() },
                          re      => qr/\G(?=[*\\])/,
                          dynamic => 1,
                         },
                        ],
            keywords => {
                map { $_ => 1 }
                  qw(
                  q qq qw qqw qf qqf qd qqd qr
                  next
                  break
                  return
                  for foreach
                  if while
                  try
                  given switch
                  continue
                  require
                  true false
                  nil
                  import
                  include

                  Array
                  File
                  Dir
                  Arr Array
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
                  Regex
                  Time

                  my
                  var
                  const
                  byte
                  char
                  func
                  class

                  STDIN
                  STDOUT
                  STDERR

                  __FUNC__
                  __CLASS__
                  __BLOCK__
                  __FILE__
                  __RESET_LINE_COUNTER__
                  __STRICT__
                  __NO_STRICT__
                  __END__

                  )
            },
            re => {
                match_flags => qr{[msixpogcdual]+},
                var_name    => qr/[[:alpha:]_]\w*(?>::[[:alpha:]_]\w*)*+/,
                operators   => do {
                    local $" = q{|};

                    my @operators = map { quotemeta } qw(

                      ||= ||
                      &&= &&
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
                      /= / ÷ ÷=
                      **= **
                      %= %
                      ^= ^
                      *= *
                      ...
                      != ≠ ..
                      \\\\
                      ?:
                      ?? ?
                      ! \\
                      :
                      );

                    qr{(@operators)};
                },
            },
            %opts,
                      );

        $options{ref_vars} = $options{vars};
        $options{re}{vars} = qr{\(((?:$options{re}{var_name}(?:\h*,\h*$options{re}{var_name})*+)?+)\)}o;

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

        my $error =
            +($self->{script_name} // '-') . ':'
          . $self->{line}
          . ": syntax error, "
          . join(', ', grep { defined } $opt{error}, $opt{expected}) . "\n"
          . substr($opt{code}, $start, $len) . "\n";

        die $error, ' ' x ($point), '^', "\n";
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

    sub get_caller_num {
        my $i = 0;
        while (++$i) {
            if (not caller($i)) {
                return $i;
            }
        }
        return -1;
    }

    {
        my %pairs = qw'
          ( )
          [ ]
          { }
          < >
          « »
          „ ”
          “ ”
          ';

        sub get_quoted_words {
            my ($self, %opt) = @_;

            my ($string, $pos) = $self->get_quoted_string(code => $opt{code});
            if ($string =~ /\G/gc && defined(my $pos = $self->parse_whitespace(code => $string))) {
                pos($string) += $pos;
            }

            my @words;
            while ($string =~ /\G((?>[^\s\\]+|\\.)++)/gcs) {
                push @words, $1 =~ s{\\#}{#}gr;

                if (defined(my $pos = $self->parse_whitespace(code => substr($string, pos($string))))) {
                    pos($string) += $pos;
                    next;
                }
            }

            return (\@words, $pos);
        }

        sub get_quoted_string {
            my ($self, %opt) = @_;

            for ($opt{code}) {

                if (/\G/gc && /\G(?=\s)/ && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                    pos($_) += $pos;
                }

                my $delim;
                if (/\G(.)/gc) {
                    $delim = $1;
                    if ($delim eq '\\' && /\G(.*?)\\/gsc) {
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

                my $re_delim = quotemeta(exists($pairs{$delim}) ? ($delim . $pairs{$delim}) : $delim);

                my $string = '';
                while (/\G([^$re_delim\\]+)/gc || /\G\\([$re_delim])/gc || /\G(\\.)/gcs) {
                    $string .= $1;
                }

                if (exists $pairs{$delim}) {
                    while (/\G(?=\Q$delim\E)/) {

                        $string .= $delim;
                        my ($str, $pos) = $self->get_quoted_string(code => substr($_, pos));
                        pos($_) += $pos;
                        $string .= $str . $pairs{$delim};

                        while (/\G([^$re_delim\\]+)/gc || /\G\\([$re_delim])/gc || /\G(\\.)/gcs) {
                            $string .= $1;
                        }
                    }
                }

                my $end_delim = $pairs{$delim} // $delim;
                if (not /\G\Q$end_delim\E/gc) {
                    $self->fatal_error(
                                       error => sprintf(qq{can't find the quoted string terminator "%s"}, $end_delim),
                                       code  => $_,
                                       pos   => pos($_)
                                      );
                }

                return $string, pos;
            }
        }
    }

    sub get_method_name {
        my ($self, %opt) = @_;

        for ($opt{code}) {

            if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                pos($_) += $pos;
            }

            # Alpha-numeric method name
            if (/\G($self->{re}{var_name} [!:]?)/gxoc) {
                return {self => Sidef::Types::String::String->new($1)}, pos;
            }

            # Operator-like method name
            if (m{\G$self->{re}{operators}}goc) {
                $self->{expect_arg} = exists $self->{lonely_ops}{$1} ? 0 : 1;
                return {self => Sidef::Types::String::String->new($1)}, pos;
            }

            # Method name as variable
            if (m{\G\$(?=$self->{re}{var_name})}goc || 1) {
                my ($obj, $pos) = $self->parse_expr(code => substr($_, pos));
                return {self => $obj}, pos($_) + $pos;
            }
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
                        $self->{has_object}    = 0;
                        $self->{expect_method} = 0;
                        $self->{has_method}    = 0;
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
                if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                    pos($_) += $pos;
                }

                # End of an expression, or end of the script
                if (/\G;/gc || /\G\z/) {
                    $self->{has_object}    = 0;
                    $self->{expect_method} = 0;
                    $self->{has_method}    = 0;
                    return undef, pos;
                }

                $self->{has_object} = 1;
                $self->{has_method} = 0;
                $self->{expect_arg} = 0;

                # Single quoted string
                if (/\G(?=')/ || /\Gq\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => substr($_, pos));
                    return Sidef::Types::String::String->new($string =~ s{\\\\}{\\}gr), pos($_) + $pos;
                }

                # Double quoted string
                if (/\G(?=["\“„])/ || /\Gqq\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    return Sidef::Types::String::String->new($string)->apply_escapes->unescape(), pos($_) + $pos;
                }

                # Single quoted filename
                if (/\Gqf\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => substr($_, pos));
                    return Sidef::Types::Glob::File->new($string =~ s{\\\\}{\\}gr), pos($_) + $pos;
                }

                # Double quoted filename
                if (/\Gqqf\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));

                    return Sidef::Types::Glob::File->new(
                                   Sidef::Types::String::String->new($string)->apply_escapes->unescape), pos($_) + $pos;
                }

                # Single quoted dirname
                if (/\Gqd\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => substr($_, pos));
                    return Sidef::Types::Glob::Dir->new($string =~ s{\\\\}{\\}gr), pos($_) + $pos;
                }

                # Double quoted dirname
                if (/\Gqqd\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));

                    return Sidef::Types::Glob::Dir->new(
                                   Sidef::Types::String::String->new($string)->apply_escapes->unescape), pos($_) + $pos;
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
                    my $array = Sidef::Types::Array::Array->new();

                    my ($obj, $pos) = $self->parse_array(code => substr($_, pos));

                    if (ref $obj->{$self->{class}} eq 'ARRAY') {
                        push @{$array}, (@{$obj->{$self->{class}}});
                    }

                    return $array, pos($_) + $pos;
                }

                # Declaration of variable types
                if (/\G(var|char|byte|const)\b\h*/sgc) {
                    my $type = $1;

                    my $names =
                        /\G($self->{re}{var_name})/goc ? $1
                      : /\G$self->{re}{vars}/goc       ? $1
                      : $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_)),
                                           error => "invalid variable name!",
                                          );

                    my @var_objs;
                    foreach my $var_name (split(/\h*,\h*/, $names)) {

                        my ($name, $class) = $self->get_name_and_class($var_name);

                        if (exists $self->{keywords}{$name}) {
                            $self->fatal_error(
                                               code  => $_,
                                               pos   => (pos($_) - length($name)),
                                               error => "'$name' is a keyword!",
                                              );
                        }

                        my ($var, $code) = $self->find_var($name, $class);

                        if (defined $var and $code == 1) {
                            warn "Redeclaration of $type '$name' in same scope, at line $self->{line}\n";
                        }

                        my $obj = Sidef::Variable::Variable->new($name, $type);
                        push @var_objs, $obj;

                        unshift @{$self->{vars}{$self->{class}}},
                          {
                            obj   => $obj,
                            name  => $name,
                            count => 0,
                            type  => $type,
                            line  => $self->{line},
                          };
                    }

                    return Sidef::Variable::Init->new(@var_objs), pos;
                }

                # Declaration of the 'my' special variable and function declaration
                if (/\G(my)\h+($self->{re}{var_name})/goc || /\G(func)\h+((?:$self->{re}{var_name})?+)(?=\h*\()/goc) {
                    my $type = $1;
                    my $name = $2;

                    if (exists $self->{keywords}{$name}) {
                        $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_) - length($name)),
                                           error => "'$name' is a keyword!",
                                          );
                    }

                    my $variable =
                      $type eq 'my'
                      ? Sidef::Variable::My->new($name)
                      : Sidef::Variable::Variable->new($name, $type);

                    unshift @{$self->{vars}{$self->{class}}},
                      {
                        obj   => $variable,
                        name  => $name,
                        count => 0,
                        type  => $type,
                        line  => $self->{line},
                      };

                    if ($type eq 'my') {
                        return Sidef::Variable::InitMy->new($name), pos($_);
                    }

                    if ($type eq 'func') {

                        # Check the declared parameters
                        if (/\G\h*$self->{re}{vars}\h*\{/gocs) {

                            my $params = join('', map { "my $_;\\$_;" } split(/\h*,\h*/, $1));
                            local $self->{current_function} = $variable;
                            my ($obj, $pos) = $self->parse_block(code => '{' . $params . substr($_, pos));
                            pos($_) += $pos - (length($params) + 1);

                            $variable->set_value($obj);
                        }
                        else {
                            $self->fatal_error(
                                               error    => "invalid function declaration",
                                               expected => "expected: func $name(...){...}",
                                               code     => $_,
                                               pos      => pos($_)
                                              );
                        }
                    }

                    return $variable, pos;
                }

                # Binary, hexdecimal and octal numbers
                if (/\G0(b[10_]*|x[0-9A-Fa-f_]*|[0-9_]+\b)/gc) {
                    my $number = "0" . ($1 =~ tr/_//dr);
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

                # Quoted words (qw/a b c/)
                if (/\G(qq?w)\b/gc) {
                    my ($type) = $1;

                    my $array = Sidef::Types::Array::Array->new();
                    my ($strings, $pos) = $self->get_quoted_words(code => substr($_, pos));

                    $array->push(
                        map {
                            $type eq 'qw'
                              ? Sidef::Types::String::String->new($_)->unescape()
                              : Sidef::Types::String::String->new($_)->apply_escapes->unescape()
                          } @{$strings}
                    );
                    return $array, pos($_) + $pos;
                }

                foreach my $hash_ref (@{$self->{obj_keys}}) {
                    if (/$hash_ref->{re}/) {
                        $self->{expect_method} = 1;

                        if ($hash_ref->{dynamic}) {
                            return $hash_ref->{sub}->(), pos;
                        }

                        return (($self->{static_objects}{$hash_ref} //= $hash_ref->{sub}->()), pos);
                    }
                }

                # Regular expression
                if (m{\G(?=/)} || /\Gqr\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    pos($_) += $pos;

                    my $regex = Sidef::Types::String::String->new($string);
                    my $flags = $1 if /\G($self->{re}{match_flags})/goc;

                    return Sidef::Types::Regex::Regex->new($$regex, $flags), pos;
                }

                # Backtick
                if (/\G(?=`)/) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));

                    return Sidef::Types::Glob::Backtick->new(
                                   Sidef::Types::String::String->new($string)->apply_escapes->unescape), pos($_) + $pos;
                }

                foreach my $hash_ref (@{$self->{obj_stat}}) {
                    if (/$hash_ref->{re} (?!::)/gxc) {
                        return (($self->{static_objects}{$hash_ref} //= $hash_ref->{sub}->()), pos);
                    }
                }

                if (/\G__RESET_LINE_COUNTER__\b/gc) {
                    $self->{line} = 0;
                    redo;
                }

                if (/\G__CLASS__\b/gc) {
                    return Sidef::Types::String::String->new($self->{class}), pos;
                }

                if (/\G__FILE__\b/gc) {
                    return Sidef::Types::String::String->new($self->{script_name}), pos;
                }

                if (/\G__STRICT__\b/gc) {
                    $self->{strict_var} = 1;
                    redo;
                }

                if (/\G__NO_STRICT__\b/gc) {
                    $self->{strict_var} = 0;
                    redo;
                }

                if (/\G__END__\b/gc) {
                    return undef, length($_);
                }

                if (/\G__BLOCK__\b/gc) {
                    if (exists $self->{current_block}) {
                        return $self->{current_block}, pos;
                    }

                    $self->fatal_error(
                                       code  => $_,
                                       pos   => pos($_) - length('__BLOCK__'),
                                       error => "__BLOCK__ used outside a block!",
                                      );
                }

                if (/\G__FUNC__\b/gc) {
                    if (exists $self->{current_function}) {
                        return $self->{current_function}, pos;
                    }

                    $self->fatal_error(
                                       code  => $_,
                                       pos   => pos($_) - length('__FUNC__'),
                                       error => "__FUNC__ used outside a function!",
                                      );
                }

                if (
                    /\G((?>ENV|ARGV))\b/gc && do {
                        ref(($self->find_var($1, $self->{class}))[0]) ? do { pos($_) -= length($1); 0 } : 1;
                    }
                  ) {
                    my $name = $1;
                    my $type = 'var';

                    my $variable = Sidef::Variable::Variable->new($name, $type);

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
                        my $array = Sidef::Types::Array::Array->new(
                            map {
                                Sidef::Types::String::String->new(Encode::decode_utf8($_))
                              } @ARGV
                        );

                        $variable->set_value($array);
                    }
                    elsif ($name eq 'ENV') {
                        require Encode;
                        my $hash = Sidef::Types::Hash::Hash->new(
                            map {
                                Sidef::Types::String::String->new(Encode::decode_utf8($_))
                              } %ENV
                        );

                        $variable->set_value($hash);
                    }

                    return $variable, pos;
                }

                # Variable call
                if (/\G($self->{re}{var_name})/goc) {

                    my $var_name = $1;

                    if (/\G(?=\h*=>)/) {
                        return Sidef::Types::String::String->new($var_name), pos;
                    }

                    my ($name, $class) = $self->get_name_and_class($var_name);
                    my ($var, $code) = $self->find_var($name, $class);

                    if (ref $var) {
                        $var->{count}++;
                        return $var->{obj}, pos;
                    }
                    elsif (not $self->{strict_var} and /\G(?=\h*(?:\R\h*)?:?=(?![=~]))/) {
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

                if (/\G\$/gc) {
                    redo;
                }

                warn "$self->{script_name}:$self->{line}: unexpected char: " . substr($_, pos(), 1) . "\n";
                return undef, pos() + 1;
            }
        }
    }

    sub parse_arguments {
        my ($self, %opt) = @_;

        for ($opt{code}) {
            if (/\G\(/gc) {

                $self->{has_object}    = 0;
                $self->{expect_method} = 0;
                $self->{parentheses}++;

                my ($obj, $pos) = $self->parse_script(code => substr($_, pos));
                return $obj, pos($_) + $pos;
            }
        }
    }

    sub parse_array {
        my ($self, %opt) = @_;

        for ($opt{code}) {
            if (/\G\[/gc) {

                $self->{has_object}    = 0;
                $self->{expect_method} = 0;
                $self->{right_brackets}++;

                my ($obj, $pos) = $self->parse_script(code => substr($_, pos));
                return $obj, pos($_) + $pos;
            }
        }
    }

    sub parse_block {
        my ($self, %opt) = @_;

        for ($opt{code}) {
            if (/\G\{/gc) {

                $self->{has_object}    = 0;
                $self->{expect_method} = 0;
                $self->{curly_brackets}++;

                my $ref   = $self->{vars}{$self->{class}};
                my $count = scalar(@{$self->{vars}{$self->{class}}});

                unshift @{$self->{ref_vars_refs}{$self->{class}}}, @{$ref};
                unshift @{$self->{vars}{$self->{class}}}, [];

                $self->{vars}{$self->{class}} = $self->{vars}{$self->{class}}[0];

                my $block = Sidef::Types::Block::Code->new({});
                local $self->{current_block} = $block;
                my ($obj, $pos) = $self->parse_script(code => '\\var _;' . substr($_, pos));
                %{$block} = %{$obj};

                splice @{$self->{ref_vars_refs}{$self->{class}}}, 0, $count;
                $self->{vars}{$self->{class}} = $ref;

                return $block, pos($_) + $pos - 7;
            }
        }
    }

    sub parse_script {
        my ($self, %opt) = @_;

        my %struct;
        for ($opt{code}) {
            {
                if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                    pos($_) += $pos;
                }

                # Class declaration
                if (/\Gclass\h+($self->{re}{var_name})/goc) {
                    $self->{class} = $1;
                    redo;
                }

                if (/\Gimport\b\h*/gc) {

                    my $names =
                        /\G($self->{re}{var_name})/goc ? $1
                      : /\G$self->{re}{vars}/goc       ? $1
                      : $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_)),
                                           error => "invalid variable name!",
                                          );

                    foreach my $var_name (split(/\h*,\h*/, $names)) {
                        my ($name, $class) = $self->get_name_and_class($var_name);

                        if ($class eq $self->{class}) {
                            $self->fatal_error(
                                               code  => $_,
                                               pos   => pos($_) - length($names),
                                               error => "can't import '${class}::${name}' inside the same class",
                                              );
                        }

                        my ($var, $code) = $self->find_var($name, $class);

                        if (not defined $var) {
                            $self->fatal_error(
                                               code  => $_,
                                               pos   => pos($_) - length($names),
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

                    my $names =
                        /\G($self->{re}{var_name})/goc ? $1
                      : /\G$self->{re}{vars}/goc       ? $1
                      : $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_)),
                                           error => "invalid variable name!",
                                          );

                    foreach my $var_name (split(/\h*,\h*/, $names)) {
                        my @path = split(/::/, $var_name);
                        my $mod_path = File::Spec->catfile(@path[0 .. $#path - 1], $path[-1] . '.sm');

                        my ($full_path, $found_module);
                        foreach my $inc_dir (@{$self->{inc}}) {
                            if (-e ($full_path = File::Spec->catfile($inc_dir, $mod_path)) and -f _ and -r _) {
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

                        open(my $fh, '<:encoding(UTF-8)', $full_path)
                          || $self->fatal_error(
                                                code  => $_,
                                                pos   => pos($_),
                                                error => "can't open the file '$full_path': $!"
                                               );

                        my $content = do { local $/; <$fh> };
                        close $fh;

                        my $parser = __PACKAGE__->new(script_name => $full_path);
                        my $struct = $parser->parse_script(code => $content);

                        foreach my $class (keys %{$struct}) {
                            $struct{$class} = $struct->{$class};
                            $self->{ref_vars}{$class} = $parser->{ref_vars}{$class};
                        }
                    }

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
                                elsif ($variable->{count} == 0 && $variable->{name} ne '_' && $variable->{name} ne '') {
                                    warn "Variable '$variable->{name}' has been initialized"
                                      . " at line $variable->{line}, but not used again!\n";
                                }
                                elsif ($DEBUG) {
                                    warn "Variable '$variable->{name}' is used $variable->{count} times!\n";
                                }
                            }
                        }

                    };

                    $check_vars->($self->{ref_vars});

                    return \%struct;
                }

                # Comma separated expressions
                if (/\G(?>,|=>)/gc) {

                    $self->{expect_method} = 0;
                    $self->{has_object}    = 0;
                    $self->{has_method}    = 0;

                    redo;
                }

                # Method separator '->', or operator-method, like '*'
                if (   $self->{expect_method} == 1
                    && !$self->{expect_arg}
                    && (/\G(?=[a-z])/ || /\G->/gc || /\G(?=$self->{re}{operators})/o || /\G\./gc)) {

                    my ($method_name, $pos) = $self->get_method_name(code => substr($_, pos));
                    pos($_) += $pos;
                    push @{$struct{$self->{class}}[-1]{call}}, {name => $method_name};

                    $self->{has_method} = 1;

                    redo;
                }

                if (/\G\]/gc) {
                    --$self->{right_brackets};

                    if (@{[caller(1)]}) {

                        if ($self->{right_brackets} < 0) {
                            $self->fatal_error(
                                               error => 'unbalanced right brackets',
                                               code  => $_,
                                               pos   => pos($_) - 1,
                                              );
                        }

                        $self->{has_object}    = 1;
                        $self->{expect_method} = 1;
                        $self->{has_method}    = 0;
                        return (\%struct, pos);
                    }

                    redo;
                }

                if (/\G\}/gc) {
                    --$self->{curly_brackets};

                    $self->{expect_method} = 1;

                    if (@{[caller(1)]}) {

                        if ($self->{curly_brackets} < 0) {
                            $self->fatal_error(
                                               error => 'unbalanced curly brackets',
                                               code  => $_,
                                               pos   => pos($_) - 1,
                                              );
                        }

                        $self->{has_object}    = 1;
                        $self->{expect_method} = 1;
                        $self->{has_method}    = 0;
                        return (\%struct, pos);
                    }

                    redo;
                }

                # The end of an argument expression
                if (/\G\)/gc) {

                    $self->{expect_method} = 1;

                    if (@{[caller(1)]}) {

                        if (--$self->{parentheses} < 0) {
                            $self->fatal_error(
                                               error => 'unbalanced parentheses',
                                               code  => $_,
                                               pos   => pos($_) - 1,
                                              );
                        }

                        $self->{has_object}    = 1;
                        $self->{expect_method} = 1;
                        $self->{has_method}    = 0;
                        return (\%struct, pos);
                    }

                    redo;
                }

                # Array index
                if ($self->{expect_index} == 1) {

                    $self->{expect_index} = 0;

                    my ($array, $pos) = $self->parse_expr(code => substr($_, pos()));
                    pos($_) += $pos;

                    $self->{expect_index} = /\G(?=\h*\[)/;

                    push @{$self->{$self->get_caller_num}{last_object}{ind}}, $array;
                    redo;
                }

                # Beginning of an argument expression
                if ($self->{has_method} == 1) {

                    my $is_arg = /\G(?=\()/;
                    my ($obj, $pos) = $self->parse_expr(code => substr($_, pos));
                    pos($_) += $pos;

                    if (defined $obj) {
                        if ($is_arg) {
                            push @{$struct{$self->{class}}[-1]{call}[-1]{arg}}, $obj;
                        }
                        else {
                            push @{$struct{$self->{class}}[-1]{call}[-1]{arg}}, {$self->{class} => [{self => $obj}]};
                            if (/\G(?=\h*\[)/) {
                                $self->{$self->get_caller_num}{last_object} =
                                  $struct{$self->{class}}[-1]{call}[-1]{arg}[-1]{$self->{class}}[-1];
                                $self->{expect_index} = 1;
                            }
                        }
                    }

                    redo;
                }

                # Parse expression or object and use it as main object (self)
                my ($expect_method, $has_object) = ($self->{expect_method}, $self->{has_object});

                my ($obj, $pos) = $self->parse_expr(code => substr($_, pos));
                pos($_) += $pos;

                if (defined $obj) {

                    $self->{has_object}    = 1;
                    $self->{expect_method} = 1;

                    if (ref $obj eq 'Sidef::Variable::InitMy') {
                        $self->{expect_method} = 0;
                        $self->{has_object}    = 0;
                        $self->{has_method}    = 0;
                    }

                    if ($expect_method and $has_object) {

                        my $self_obj   = $struct{$self->{class}}[-1]{self};
                        my $method_obj = Sidef::Types::String::String->new('');

                        if (exists $self->{obj_with_do}{ref($self_obj)}) {
                            $$method_obj = 'do';
                        }
                        elsif (ref($self_obj) eq 'Sidef::Variable::Variable'
                               and $self_obj->{type} eq 'func') {
                            $$method_obj = 'call';
                        }
                        else {
                            $self->fatal_error(
                                               error => 'expected a method, not an object!',
                                               code  => $_,
                                               pos   => pos($_) - $pos,
                                              );
                        }

                        push @{$struct{$self->{class}}[-1]{call}}, {name => $method_obj};
                        push @{$struct{$self->{class}}[-1]{call}[-1]{arg}}, $obj;
                    }
                    else {
                        push @{$struct{$self->{class}}}, {self => $obj};
                    }

                    if (/\G(?=\h*\[)/) {
                        $self->{expect_index} = 1;
                        $self->{$self->get_caller_num}{last_object} = $struct{$self->{class}}[-1];
                    }
                }

                redo;
            }
        }

        die "Invalid code or something weird is happening! :)\n";
    }
}
