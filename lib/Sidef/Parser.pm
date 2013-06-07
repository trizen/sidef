
use 5.014;
use strict;
use warnings;

package Sidef::Parser {

    require Sidef::Utils::Regex;
    require Sidef::Init;

    our $DEBUG = 0;

    sub new {
        my ($class) = @_;

        my %options = (
            line             => 1,
            has_object       => 0,
            has_method       => 0,
            expect_method    => 0,
            expect_index     => 0,
            expect_arg       => 0,
            expect_func_call => 0,
            parentheses      => 0,
            class            => 'main',
            vars             => [],
            ref_vars_refs    => [],
            re               => {
                double_quote       => Sidef::Utils::Regex::make_esc_delim(q{"}),
                single_quote       => Sidef::Utils::Regex::make_esc_delim(q{'}),
                file_quote         => Sidef::Utils::Regex::make_esc_delim(q{~}),
                regex              => Sidef::Utils::Regex::make_esc_delim(q{/}),
                m_regex            => Sidef::Utils::Regex::make_single_q_balanced(q{m}),
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
                      : ?
                      ! \\
                      );

                    qr{(@operators)};
                },
            },
        );

        $options{ref_vars} = $options{vars};

        bless \%options, $class;
    }

    sub fatal_error {
        my ($self, %opt) = @_;
        my $index = index($opt{'code'}, "\n", $opt{'pos'});
        $index += ($index == -1) ? (length($opt{'code'})) : -$opt{'pos'};

        die "\n** Syntax error at line $self->{line}, near:\n\t\"", substr($opt{'code'}, $opt{'pos'}, $index), "\"\n";
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

    sub get_method_name {
        my ($self, %opt) = @_;

        given ($opt{'code'}) {

            if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                pos($_) = $pos + pos($_);
            }

            # Alpha-numeric method name
            when (/\G([a-z]\w*)/gc) {
                return {self => Sidef::Types::String::String->new($1)}, pos;
            }

            # Operator-like method name
            when (m{\G$self->{re}{operators}}goc) {
                $self->{expect_arg} = $1 ~~ ['--', '++'] ? 0 : 1;
                return {self => Sidef::Types::String::String->new($1)}, pos;
            }

            # Method name as variable
            when (m{\G\$(?=$self->{re}{var_name})}goc || 1) {
                my ($obj, $pos) = $self->parse_expr(code => substr($_, pos));
                pos($_) = $pos + pos;
                return {self => $obj}, pos;
            }
        }
    }

    sub parse_whitespace {
        my ($self, %opt) = @_;

        my $found_space = -1;
        given ($opt{code}) {
            {
                ++$found_space;

                # Comments
                when (/\G#.*/gc) {
                    redo;
                }
                when (/\G(?=[\h\v])/) {

                    # Generic line
                    when (/\G\R/gc) {
                        ++$self->{line};
                        redo;
                    }

                    # Horizontal space
                    when (/\G\h+/gc) {
                        redo;
                    }

                    # Vertical space
                    when (/\G\v+/gc) {
                        redo;
                    }
                }
                when ($found_space > 0) {
                    return pos;
                }
                default {
                    return;
                }
            }
        }

        return;
    }

    sub parse_expr {
        my ($self, %opt) = @_;

        given ($opt{code}) {
            {
                if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                    pos($_) = $pos + pos($_);
                }

                when (/\G__RESET_LINE_COUNTER__\b/gc) {
                    $self->{line} = 0;
                    redo;
                }

                when (/\G__END__\b/gc) {
                    return undef, length($_);
                }

                # End of the expression (or end of the file)
                when (/\G;/gc || /\G\z/) {
                    $self->{has_object}    = 0;
                    $self->{expect_method} = 0;
                    $self->{has_method}    = 0;
                    return undef, pos;
                }

                $self->{has_object} = 1;
                $self->{has_method} = 0;
                $self->{expect_arg} = 0;

                when (/\GDir\b/gc) {
                    return Sidef::Types::Glob::Dir->new(), pos;
                }

                when (/\GFile\b/gc) {
                    return Sidef::Types::Glob::File->new(), pos;
                }

                when (/\GArray\b/gc) {
                    return Sidef::Types::Array::Array->new(), pos;
                }

                when (/\GHash\b/gc) {
                    return Sidef::Types::Hash::Hash->new(), pos;
                }

                when (/\GString\b/gc) {
                    return Sidef::Types::String::String->new(), pos;
                }

                when (/\GNumber\b/gc) {
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

                when (/\GChar\b/gc) {
                    return Sidef::Types::Char::Char->new(), pos;
                }

                when (/\GChar\b/gc) {
                    return Sidef::Types::Char::Chars->new(), pos;
                }

                when (/\GBool\b/gc) {
                    return Sidef::Types::Bool::Bool->new(), pos;
                }

                # Double quoted string
                when (/\G$self->{re}{double_quote}/gc) {
                    return Sidef::Types::String::String->new($1)->apply_escapes(), pos;
                }

                # Single quoted string
                when (/\G$self->{re}{single_quote}/goc) {
                    return Sidef::Types::String::String->new($1), pos;
                }

                # File quoted string
                when (/\G$self->{re}{file_quote}/goc) {
                    return Sidef::Types::Glob::File->new($1), pos;
                }

                # Boolean value
                when (/\G((?>true|false))\b/gc) {
                    return Sidef::Types::Bool::Bool->$1, pos;
                }

                # Undefined value
                when (/\Gnil\b/gc) {
                    return Sidef::Types::Nil::Nil->new(), pos;
                }

                # Floating point number
                when (/\G([+-]?\d+\.\d+)\b/gc) {
                    return Sidef::Types::Number::Number->new($1), pos;
                }

                # Integer number
                when (/\G([+-]?\d+)\b/gc) {
                    return Sidef::Types::Number::Number->new($1), pos;
                }

                when (/\G!/gc) {
                    $self->{expect_method} = 1;
                    return Sidef::Types::Bool::Bool->new(), pos() - 1;
                }

                when (/\G:/gc) {
                    $self->{expect_method} = 1;
                    return Sidef::Types::Block::Code->new({}), pos() - 1;
                }

                when (/\G\\/gc) {
                    $self->{expect_method} = 1;
                    return Sidef::Variable::Ref->new(), pos() - 1;
                }

                when (/\G\*/gc) {
                    $self->{expect_method} = 1;
                    return Sidef::Variable::Ref->new(), pos() - 1;
                }

                # Regular expression
                when (/\G$self->{re}{regex}/goc || ($] >= 5.017001 && /\G$self->{re}{m_regex}/goc)) {

                    my $regex = Sidef::Types::String::String->new($1)->apply_escapes();
                    my ($flags) = (/\G($self->{re}{match_flags})/gc);

                    return Sidef::Types::Regex::Regex->new($$regex, $flags), pos;
                }

                # Object as expression
                when (/\G(?=\()/) {
                    my ($obj, $pos) = $self->parse_arguments(code => substr($_, pos));
                    pos($_) = $pos + pos;
                    return $obj, pos;
                }

                # Array as object
                when (/\G(?=\[)/) {
                    my $array = Sidef::Types::Array::Array->new();

                    my ($obj, $pos) = $self->parse_array(code => substr($_, pos));
                    pos($_) = $pos + pos;

                    if (ref $obj->{main} eq 'ARRAY') {
                        push @{$array}, (@{$obj->{main}});
                    }

                    return $array, pos;
                }

                # Block as object
                when (/\G(?=\{)/) {

                    my ($obj, $pos) = $self->parse_block(code => substr($_, pos));
                    pos($_) = $pos + pos;

                    return $obj, pos;
                }

                # Declaration of variable types (var, const, char, etc...)
                when (/\G(var|const|char|byte|func)\h+($self->{re}{var_name})/goc) {
                    my $type = $1;
                    my $name = $2;

                    my ($var, $code) = $self->find_var($name);

                    if (defined $var and $code == 1) {
                        warn "Redeclaration of $type '$name' in same scope, at line $self->{line}\n";
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

                    if ($type eq 'func') {

                        # Check the declared parameters
                        if (/\G\s*\(((?:$self->{re}{var_name}(?:\s*,\s*$self->{re}{var_name})*)?)\)\s*\{/gcs) {

                            my $params = join('', map { "\\var $_;" } split(/\s*,\s*/, $1));
                            my ($obj, $pos) = $self->parse_block(code => '{' . $params . substr($_, pos));
                            pos($_) += $pos - (length($params) + 1);

                            $variable->set_value($obj);
                        }
                        else {
                            warn "Invalid declaration of function '$name'! Expected: func $name(...){...}\n";
                            $self->fatal_error(code => $_, pos => pos($_));
                        }
                    }

                    return $variable, pos;
                }

                # Variable call
                when (/\G($self->{re}{var_name})/goc) {

                    my ($var, $code) = $self->find_var($1);

                    if ($var) {
                        $var->{count}++;

                        if ($var->{type} eq 'func') {
                            if (/\G(?=\s*\()/) {
                                $self->{expect_func_call} = 1;
                            }
                        }

                        return $var->{obj}, pos;
                    }

                    warn "Attempt to use an uninitialized variable: <$1>\n";
                    $self->fatal_error(code => $_,
                                       pos  => (pos($_) - length($1)));
                }
                default {
                    warn "[LINE $self->{line}] Unexpected char: " . substr($_, pos(), 1) . "\n";
                    return undef, pos() + 1;
                }
            }
        }
    }

    sub parse_arguments {
        my ($self, %opt) = @_;

        given ($opt{'code'}) {
            {
                if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                    pos($_) = $pos + pos($_);
                }

                when (/\G\(/gc) {
                    $self->{has_object}    = 0;
                    $self->{expect_method} = 0;
                    $self->{parentheses}++;
                    my ($obj, $pos) = $self->parse_script(code => substr($_, pos));
                    pos($_) = $pos + pos;
                    return $obj, pos;
                }
            }
        }
    }

    sub parse_array {
        my ($self, %opt) = @_;

        given ($opt{'code'}) {
            {
                if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                    pos($_) = $pos + pos($_);
                }
                when (/\G\[/gc) {
                    $self->{has_object}    = 0;
                    $self->{expect_method} = 0;
                    $self->{right_brackets}++;
                    my ($obj, $pos) = $self->parse_script(code => substr($_, pos));
                    pos($_) = $pos + pos;
                    return $obj, pos;
                }
            }
        }
    }

    sub parse_block {
        my ($self, %opt) = @_;

        given ($opt{'code'}) {
            {
                if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                    pos($_) = $pos + pos($_);
                }
                when (/\G\{/gc) {

                    $self->{has_object}    = 0;
                    $self->{expect_method} = 0;
                    $self->{curly_brackets}++;

                    my $ref   = $self->{vars};
                    my $count = scalar(@{$self->{vars}});

                    unshift @{$self->{ref_vars_refs}}, @{$ref};
                    unshift @{$self->{vars}}, [];

                    $self->{vars} = $self->{vars}[0];

                    my ($obj, $pos) = $self->parse_script(code => '\\var _;' . substr($_, pos));
                    pos($_) += $pos - 7;

                    splice @{$self->{ref_vars_refs}}, 0, $count;
                    $self->{vars} = $ref;

                    return Sidef::Types::Block::Code->new($obj), pos;
                }
            }
        }
    }

    sub parse_script {
        my ($self, %opt) = @_;

        my %struct;
        given ($opt{code}) {
            {
                if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                    pos($_) = $pos + pos;
                }

                # Automatically add  the '.call' method when a function is called
                when ($self->{expect_func_call} == 1) {
                    my $pos = pos($_);
                    substr($_, $pos, 0, '.call');
                    pos($_) = $pos;
                    continue;
                }

                # Class declaration
                when (/\Gclass\h*/gc) {

                    # Maybe, we should make some function: get_quoted_string()
                    # which supports q{}, qq{}, '', and ""
                    when (/\G($self->{re}{double_quote}|$self->{re}{single_quote})/goc) {
                        $self->{class} = $1;
                        redo;
                    }

                    die "Expected class name, at line $self->{line}.\n";
                }

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
                                warn "Variable '$variable->{name} is used $variable->{count} times!\n";
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
                      && (/\G(?=[a-z])/ || /\G->/gc || /\G(?=\s*$self->{re}{operators})/ || /\G\./gc)) {

                    my ($method_name, $pos) = $self->get_method_name(code => substr($_, pos));
                    pos($_) = $pos + pos;
                    push @{$struct{$self->{class}}[-1]{call}}, {name => $method_name};

                    # Remove the automatically added '.call' method
                    if ($self->{expect_func_call} == 1) {
                        my $old_pos = pos();
                        substr($_, $old_pos - 5, 5, '');
                        pos($_) = $old_pos - 5;
                        $self->{expect_func_call} = 0;
                    }

                    $self->{has_method} = 1;

                    redo;
                }

                when (/\G\]/gc) {
                    --$self->{right_brackets};

                    if (@{[caller(1)]}) {

                        if ($self->{right_brackets} < 0) {
                            warn "Unbalanced right brackets!\n";
                            $self->fatal_error(code => $_, pos => pos($_) - 1);
                        }

                        $self->{has_object}    = 1;
                        $self->{expect_method} = 1;
                        return (\%struct, pos);
                    }

                    redo;
                }

                when (/\G\}/gc) {
                    --$self->{curly_brackets};

                    $self->{expect_method} = 1;

                    if (@{[caller(1)]}) {

                        if ($self->{curly_brackets} < 0) {
                            warn "Unbalanced right brackets!\n";
                            $self->fatal_error(code => $_, pos => pos($_) - 1);
                        }

                        $self->{has_object}    = 1;
                        $self->{expect_method} = 1;
                        return (\%struct, pos);
                    }

                    redo;
                }

                # The end of an argument expression
                when (/\G\)/gc) {

                    $self->{expect_method} = 1;

                    if (@{[caller(1)]}) {

                        if (--$self->{parentheses} < 0) {
                            warn "Unbalanced parentheses!\n";
                            $self->fatal_error(code => $_, pos => pos($_) - 1);
                        }

                        return (\%struct, pos);
                    }

                    redo;
                }

                # Array index
                when ($self->{expect_index} == 1) {

                    $self->{expect_index} = 0;

                    my ($array, $pos) = $self->parse_expr(code => substr($_, pos()));
                    pos($_) = $pos + pos();

                    $self->{expect_index} = /\G(?=\h*\[)/;

                    push @{$self->{last_object}{ind}}, $array;
                    redo;
                }

                # Beginning of an argument expression
                when ($self->{has_method} == 1) {

                    my $is_arg = /\G(?=\()/;
                    my ($obj, $pos) = $self->parse_expr(code => substr($_, pos));
                    pos($_) = $pos + pos;

                    if (defined $obj) {
                        if ($is_arg) {
                            push @{$struct{$self->{class}}[-1]{call}[-1]{arg}}, $obj;
                        }
                        else {
                            push @{$struct{$self->{class}}[-1]{call}[-1]{arg}}, {$self->{class} => [{self => $obj}]};
                            if (/\G(?=\h*\[)/) {
                                $self->{last_object} =
                                  $struct{$self->{class}}[-1]{call}[-1]{arg}[-1]{$self->{class}}[-1];
                                $self->{expect_index} = 1;
                            }
                        }
                    }

                    redo;
                }

                # Parse expression or object and use it as main object (self)
                default {

                    my ($obj, $pos) = $self->parse_expr(code => substr($_, pos));
                    pos($_) = $pos + pos;

                    if (defined $obj) {

                        $self->{has_object}    = 1;
                        $self->{expect_method} = 1;

                        push @{$struct{$self->{class}}}, {self => $obj};

                        if (/\G(?=\h*\[)/) {
                            $self->{expect_index} = 1;
                            $self->{last_object}  = $struct{$self->{class}}[-1];
                        }
                    }

                    redo;
                }
            }
        }

        die "Invalid code or something weird is happening! :)\n";

    }
};

1;
