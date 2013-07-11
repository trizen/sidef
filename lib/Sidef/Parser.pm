package Sidef::Parser {

    use utf8;
    use 5.014;
    use strict;
    use warnings;

    no if $] >= 5.018, warnings => "experimental::smartmatch";
    use autouse 'Encode' => qw(decode_utf8($;$));    # unicode support

    our $DEBUG = 0;
    require Sidef::Init;

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
            class         => 'main',
            vars          => [],
            ref_vars_refs => [],
            keywords      => {
                map { $_ => 1 }
                  qw(
                  q qq qw qqw
                  break
                  return
                  for foreach
                  if while
                  given
                  continue
                  require
                  true false
                  nil

                  Array
                  File
                  Dir
                  Arr Array
                  Hash
                  Str String
                  Num Number
                  Pipe
                  Byte Bytes
                  Chr Char
                  Chrs Chars
                  Bool
                  Sys
                  Regex

                  var
                  const
                  byte
                  char
                  func
                  my

                  STDIN
                  STDOUT
                  STDERR

                  __FUNC__
                  __BLOCK__
                  __RESET_LINE_COUNTER__
                  __STRICT__
                  __NO_STRICT__
                  __END__

                  )
            },
            re => {
                match_flags        => qr{[msixpogcdual]+},
                substitution_flags => qr{[msixpogcerdual]+},
                var_name           => qr/[[:alpha:]_]\w*/,
                operators          => do {
                    local $" = q{|};

                    my @operators = map { quotemeta } qw(

                      ||= ||
                      &&= &&
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
                      /= /
                      **= **
                      %= %
                      ^= ^
                      *= *
                      != ..
                      \\\\
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
        my ($self, $var_name) = @_;

        foreach my $var (@{$self->{vars}}) {
            next if ref $var eq 'ARRAY';
            return ($var, 1) if $var->{name} eq $var_name;
        }

        foreach my $var (@{$self->{ref_vars_refs}}) {
            next if ref $var eq 'ARRAY';
            return ($var, 0) if $var->{name} eq $var_name;
        }

        return;
    }

    sub get_caller_num {
        for (my $z = 1 ; $z < 1000 ; $z++) {    # should be enough
            if (not caller($z)) {
                return $z;
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
            when (/\G([a-z]\w*)/gc) {
                return {self => Sidef::Types::String::String->new($1)}, pos;
            }

            # Operator-like method name
            when (m{\G$self->{re}{operators}}goc) {
                $self->{expect_arg} = $1 ~~ ['--', '++', '??'] ? 0 : 1;
                return {self => Sidef::Types::String::String->new($1)}, pos;
            }

            # Method name as variable
            when (m{\G\$(?=$self->{re}{var_name})}goc || 1) {
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

                # One-line comment
                if (/\G#.*/gc) {
                    redo;
                }

                # Multi-line C comment
                if (m{\G/\*(.*?)\*/}gsc) {
                    $self->{line} += ($1 =~ tr/\n//);
                    redo;
                }

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
                when (/\G;/gc || /\G\z/) {
                    $self->{has_object}    = 0;
                    $self->{expect_method} = 0;
                    $self->{has_method}    = 0;
                    return undef, pos;
                }

                $self->{has_object} = 1;
                $self->{has_method} = 0;
                $self->{expect_arg} = 0;

                # Single quoted string
                when (/\G(?=')/ || /\Gq\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => substr($_, pos));
                    return Sidef::Types::String::String->new($string =~ s{\\\\}{\\}gr), pos($_) + $pos;
                }

                # Double quoted string
                when (/\G(?=["\“„])/ || /\Gqq\b/gc) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    return Sidef::Types::String::String->new($string)->apply_escapes->unescape(), pos($_) + $pos;
                }

                # Object as expression
                when (/\G(?=\()/) {
                    my ($obj, $pos) = $self->parse_arguments(code => substr($_, pos));
                    return $obj, pos($_) + $pos;
                }

                # Block as object
                when (/\G(?=\{)/) {
                    my ($obj, $pos) = $self->parse_block(code => substr($_, pos));
                    return $obj, pos($_) + $pos;
                }

                # Array as object
                when (/\G(?=\[)/) {
                    my $array = Sidef::Types::Array::Array->new();

                    my ($obj, $pos) = $self->parse_array(code => substr($_, pos));

                    if (ref $obj->{main} eq 'ARRAY') {
                        push @{$array}, (@{$obj->{main}});
                    }

                    return $array, pos($_) + $pos;
                }

                # Declaration of variable types
                when (/\G(var|char|byte|const)\b\h*/sgc) {
                    my $type = $1;

                    my $names =
                        /\G($self->{re}{var_name})/goc ? $1
                      : /\G$self->{re}{vars}/goc       ? $1
                      : $self->fatal_error(
                                           code  => $_,
                                           pos   => (pos($_)),
                                           error => "invalid variable name!",
                                          );

                    my @vars = split(/\h*,\h*/, $names);

                    my @var_objs;
                    foreach my $name (@vars) {

                        if (exists $self->{keywords}{$name}) {
                            $self->fatal_error(
                                               code  => $_,
                                               pos   => (pos($_) - length($name)),
                                               error => "'$name' is a keyword!",
                                              );
                        }

                        my ($var, $code) = $self->find_var($name);

                        if (defined $var and $code == 1) {
                            warn "Redeclaration of $type '$name' in same scope, at line $self->{line}\n";
                        }

                        my $obj = Sidef::Variable::Variable->new($name, $type);
                        push @var_objs, $obj;

                        unshift @{$self->{vars}},
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
                when (/\G(my)\h+($self->{re}{var_name})/goc || /\G(func)\h+((?:$self->{re}{var_name})?+)(?=\h*\()/goc) {
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

                    unshift @{$self->{vars}},
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

                # Boolean value
                when (/\G((?>true|false))\b/gc) {
                    return Sidef::Types::Bool::Bool->$1, pos;
                }

                # 'Not initialized' value
                when (/\Gnil\b/gc) {
                    return Sidef::Types::Nil::Nil->new(), pos;
                }

                # Special number
                when (/\G(?=0)/) {

                    # Binary, hexdecimal and octal numbers
                    when (/\G0(b[10]*|x[0-9A-Fa-f]*|[0-9]+\b)/gc) {
                        return Sidef::Types::Number::Number->new(oct($1)), pos;
                    }

                    continue;
                }

                # Integer or float number
                when (/\G([+-]?+(?=\.?[0-9])[0-9]*+(?:\.[0-9]++)?(?:[Ee](?:[+-]?+[0-9]+))?)/gc) {
                    return Sidef::Types::Number::Number->new($1), pos;
                }

                # Quoted words (qw/a b c/)
                when (/\G(qq?w)\b/gc) {
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

                when (/\G(?=if\b)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Types::Bool::If->new(), pos;
                }

                when (/\G(?=while\b)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Types::Bool::While->new(), pos;
                }

                when (/\G(?=for(?:each)?\b)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Types::Block::For->new(), pos;
                }

                when (/\G(?=continue\b)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Types::Block::Continue->new(), pos;
                }

                when (/\G(?=return\b)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Types::Block::Return->new(), pos;
                }

                when (/\G(?=given\b)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Types::Block::Given->new(), pos;
                }

                when (/\G(?=break\b)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Types::Block::Break->new(), pos;
                }

                when (/\G(?=require\b)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Module::Require->new(), pos;
                }

                # Regular expression
                when (m{\G(?=/)}) {

                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    pos($_) += $pos;

                    my $regex = Sidef::Types::String::String->new($string);
                    my $flags = $1 if /\G($self->{re}{match_flags})/goc;

                    return Sidef::Types::Regex::Regex->new($$regex, $flags), pos;
                }

                when (/\G(?=`)/) {
                    my ($string, $pos) = $self->get_quoted_string(code => (substr($_, pos)));
                    require Sidef::Types::Glob::Backtick;
                    return Sidef::Types::Glob::Backtick->new(
                                   Sidef::Types::String::String->new($string)->apply_escapes->unescape), pos($_) + $pos;
                }

                # Logical 'not'
                when (/\G(?=!)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Types::Bool::Bool->new(), pos;
                }

                # New hash-block (:{})
                when (/\G(?=:)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Types::Block::Code->new({}), pos;
                }

                when (/\G(?=\\)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Variable::Ref->new(), pos;
                }

                when (/\G(?=\*)/) {
                    $self->{expect_method} = 1;
                    return Sidef::Variable::Ref->new(), pos;
                }

                when (/\GDir\b/gc) {
                    return Sidef::Types::Glob::Dir->new(), pos;
                }

                when (/\GFile\b/gc) {
                    return Sidef::Types::Glob::File->new(), pos;
                }

                when (/\GArr(?:ay)?\b/gc) {
                    return Sidef::Types::Array::Array->new(), pos;
                }

                when (/\GHash\b/gc) {
                    return Sidef::Types::Hash::Hash->new(), pos;
                }

                when (/\GStr(?:ing)?\b/gc) {
                    return Sidef::Types::String::String->new(), pos;
                }

                when (/\GNum(?:ber)?\b/gc) {
                    return Sidef::Types::Number::Number->new(), pos;
                }

                when (/\GPipe\b/gc) {
                    return Sidef::Types::Glob::Pipe->new(), pos;
                }

                when (/\GByte\b/gc) {
                    return Sidef::Types::Byte::Byte->new(), pos;
                }

                when (/\GBytes\b/gc) {
                    return Sidef::Types::Byte::Bytes->new(), pos;
                }

                when (/\GCha?r\b/gc) {
                    return Sidef::Types::Char::Char->new(), pos;
                }

                when (/\GCha?rs\b/gc) {
                    return Sidef::Types::Char::Chars->new(), pos;
                }

                when (/\GBool\b/gc) {
                    return Sidef::Types::Bool::Bool->new(), pos;
                }

                when (/\GSys\b/gc) {
                    return Sidef::Sys::Sys->new(), pos;
                }

                when (/\GRegex\b/gc) {
                    return Sidef::Types::Regex::Regex->new(''), pos;
                }

                when (/\G__RESET_LINE_COUNTER__\b/gc) {
                    $self->{line} = 0;
                    redo;
                }

                when (/\G__STRICT__\b/gc) {
                    $self->{strict_var} = 1;
                    redo;
                }

                when (/\G__NO_STRICT__\b/gc) {
                    $self->{strict_var} = 0;
                    redo;
                }

                when (/\G__END__\b/gc) {
                    return undef, length($_);
                }

                when (/\G__BLOCK__\b/gc) {
                    if (exists $self->{current_block}) {
                        return $self->{current_block}, pos;
                    }

                    $self->fatal_error(
                                       code  => $_,
                                       pos   => pos($_) - length('__BLOCK__'),
                                       error => "__BLOCK__ used outside a block!",
                                      );
                }

                when (/\G__FUNC__\b/gc) {
                    if (exists $self->{current_function}) {
                        return $self->{current_function}, pos;
                    }

                    $self->fatal_error(
                                       code  => $_,
                                       pos   => pos($_) - length('__FUNC__'),
                                       error => "__FUNC__ used outside a function!",
                                      );
                }

                when (/\GSTDIN\b/gc) {
                    return Sidef::Types::Glob::FileHandle->stdin, pos;
                }

                when (/\GSTDOUT\b/gc) {
                    return Sidef::Types::Glob::FileHandle->stdout, pos;
                }

                when (/\GSTDERR\b/gc) {
                    return Sidef::Types::Glob::FileHandle->stderr, pos;
                }

                when (/\G((?>ENV|ARGV|SCRIPT))\b/gc) {
                    my $name = $1;
                    my $type = 'var';

                    my ($var, $code) = $self->find_var($name);

                    if (ref $var) {
                        pos($_) -= length($name);
                        continue;
                    }

                    my $variable = Sidef::Variable::Variable->new($name, $type);

                    unshift @{$self->{vars}},
                      {
                        obj   => $variable,
                        name  => $name,
                        count => 0,
                        type  => $type,
                        line  => $self->{line},
                      };

                    if ($name eq 'ARGV') {
                        my $array =
                          Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new(decode_utf8($_)) }
                                                          @ARGV);

                        $variable->set_value($array);
                    }
                    elsif ($name eq 'ENV') {
                        my $hash =
                          Sidef::Types::Hash::Hash->new(map { Sidef::Types::String::String->new(decode_utf8($_)) }
                                                        %ENV);

                        $variable->set_value($hash);
                    }
                    elsif ($name eq 'SCRIPT') {
                        my $string = Sidef::Types::String::String->new($self->{script_name});
                        $variable->set_value($string);
                    }

                    return $variable, pos;
                }

                # Variable call
                when (/\G($self->{re}{var_name})/goc) {

                    my $name = $1;
                    my ($var, $code) = $self->find_var($name);

                    if (ref $var) {
                        $var->{count}++;
                        return $var->{obj}, pos;
                    }
                    elsif (not $self->{strict_var}) {
                        unshift @{$self->{vars}},
                          {
                            obj   => Sidef::Variable::My->new($name),
                            name  => $name,
                            count => 0,
                            type  => 'my',
                            line  => $self->{line},
                          };

                        return Sidef::Variable::InitMy->new($name), pos($_) - length($name);
                    }

                    # Ignored, for now
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => (pos($_) - length($name)),
                                       error => "attempt to use an uninitialized variable <$1>",
                                      );
                }
                when (/\G\$/gc) {
                    redo;
                }
                default {
                    warn "$self->{script_name}:$self->{line}: unexpected char: " . substr($_, pos(), 1) . "\n";
                    return undef, pos() + 1;
                }
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

                my $ref   = $self->{vars};
                my $count = scalar(@{$self->{vars}});

                unshift @{$self->{ref_vars_refs}}, @{$ref};
                unshift @{$self->{vars}}, [];

                $self->{vars} = $self->{vars}[0];

                my $block = Sidef::Types::Block::Code->new({});
                local $self->{current_block} = $block;
                my ($obj, $pos) = $self->parse_script(code => '\\var _;' . substr($_, pos));
                %{$block} = %{$obj};

                splice @{$self->{ref_vars_refs}}, 0, $count;
                $self->{vars} = $ref;

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

=for comment

                # Class declaration -- needs to be redesigned (or removed completely)
                when (/\Gclass\b\h*/gc) {
                    my ($class, $pos) = $self->parse_expr(code => substr($_, pos));
                    pos($_) += $pos;

                    if (ref($class) eq 'Sidef::Types::String::String') {
                        $self->{class} = $$class;
                    }
                    else {
                        $self->fatal_error(
                                           error    => "invalid class name",
                                           expected => "expected: class 'name';",
                                           code     => $_,
                                           pos      => pos($_)
                                          );
                    }

                    redo;
                }

=cut

                # We are at the end of the script.
                # We make some checks, and return the \%struct hash ref.
                when (/\G\z/) {

                    my $check_vars;
                    $check_vars = sub {
                        my ($array_ref) = @_;

                        foreach my $variable (@{$array_ref}) {
                            if (ref $variable eq 'ARRAY') {
                                $check_vars->($variable);
                            }
                            elsif ($variable->{name} ne uc($variable->{name}) and $variable->{count} == 0) {
                                warn "Variable '$variable->{name}' has been initialized"
                                  . " at line $variable->{line}, but not used again!\n";
                            }
                            elsif ($DEBUG) {
                                warn "Variable '$variable->{name}' is used $variable->{count} times!\n";
                            }
                        }

                    };

                    $check_vars->($self->{ref_vars});

                    return \%struct;
                }

                # Comma separated expressions
                when (/\G(?>,|=>)/gc) {

                    $self->{expect_method} = 0;
                    $self->{has_object}    = 0;
                    $self->{has_method}    = 0;

                    redo;
                }

                # Method separator '->', or operator-method, like '*'
                when (   $self->{expect_method} == 1
                      && !$self->{expect_arg}
                      && (/\G(?=[a-z])/ || /\G->/gc || /\G(?=$self->{re}{operators})/o || /\G\./gc)) {

                    my ($method_name, $pos) = $self->get_method_name(code => substr($_, pos));
                    pos($_) += $pos;
                    push @{$struct{$self->{class}}[-1]{call}}, {name => $method_name};

                    $self->{has_method} = 1;

                    redo;
                }

                when (/\G\]/gc) {
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

                when (/\G\}/gc) {
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
                when (/\G\)/gc) {

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
                when ($self->{expect_index} == 1) {

                    $self->{expect_index} = 0;

                    my ($array, $pos) = $self->parse_expr(code => substr($_, pos()));
                    pos($_) += $pos;

                    $self->{expect_index} = /\G(?=\h*\[)/;

                    push @{$self->{$self->get_caller_num}{last_object}{ind}}, $array;
                    redo;
                }

                # Beginning of an argument expression
                when ($self->{has_method} == 1) {

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
                default {
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

                            if (
                                ref($self_obj) ~~ [
                                    qw(
                                      Sidef::Types::Block::For
                                      Sidef::Types::Bool::While
                                      Sidef::Types::Bool::If
                                      )
                                ]
                              ) {
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
        }

        die "Invalid code or something weird is happening! :)\n";
    }
}
