
use 5.014;
use strict;
use warnings;

use lib '../../lib';    # devel only

package Sidef::Lexer;

use Sidef::Init;

our $DEBUG = 0;

sub new {
    my ($class) = @_;

    bless {
        line          => 1,
        has_object    => 0,
        expect_method => 0,
        parentheses   => 0,
        class         => 'main',
        variables     => {},
        re            => {
            double_quote  => Sidef::Utils::Regex::make_esc_delim(q{"}),
            single_quote  => Sidef::Utils::Regex::make_esc_delim(q{'}),
            file_quote    => Sidef::Utils::Regex::make_esc_delim(q{~}),
            var_in_string => Sidef::Utils::Regex::variable_in_string(),
            var_name      => qr/[a-zA-Z_]\w*/,
            operators     => do {
                local $" = q{|};

                my @operators = map { quotemeta } qw(

                  && || // ** << >> ==
                  / + - * % ^ & | :  =

                  );

                qr{(@operators)};
            },
        },
    }, $class;
}

sub fatal_error {
    my ($self, %opt) = @_;
    my $index = index($opt{'code'}, "\n", $opt{'pos'});
    $index += ($index == -1) ? (length($opt{'code'})) : -$opt{'pos'};

    die "\n** Syntax error at line $self->{line}, near:\n\t\"", substr($opt{'code'}, $opt{'pos'}, $index), "\"\n";
}

sub get_method_name {
    my ($self, %opt) = @_;

    given ($opt{'code'}) {

        if (/\G/gc
            && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
            pos($_) = $pos + pos($_);
        }

        # Alpha-numeric method name
        when (/\G([a-z]\w+)/gc) {
            return $1, pos;
        }

        # Operator-like method name
        when (m{\G$self->{re}{operators}}goc) {
            return $1, pos;
        }
        default {
            warn "Invalid method name!\n";
            $self->fatal_error(code => $_, pos => pos($_));
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
            if (/\G/gc
                && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                pos($_) = $pos + pos($_);
            }

            # End of the expression (or end of the file)
            when (/\G;/gc || /\G\z/) {
                $self->{has_object}    = 0;
                $self->{expect_method} = 0;
                return undef, pos;
            }

            $self->{has_object} = 1;

            # Double quoted string
            when (/\G$self->{re}{double_quote}/gc) {
                my $string = $1;

                while ($string =~ /$self->{re}{var_in_string}/go) {
                    if (exists $self->{variables}{$self->{class}}{$1}) {
                        $self->{variables}{$self->{class}}{$1}{count}++;
                    }
                    else {
                        warn "Attempt to use an uninitialized variable in double quoted string!\n";
                        $self->fatal_error(code => $_,
                                           pos  => pos($_) - length($string) + pos($string) - length($1) - 2);
                    }
                }

                return Sidef::Types::String::Double->new($string), pos;
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
                return Sidef::Types::Bool::Bool->new($1), pos;
            }

            # Floating point number
            when (/\G([+-]?\d+\.\d+)\b/gc) {
                return Sidef::Types::Number::Float->new($1), pos;
            }

            # Integer number
            when (/\G([+-]?\d+)\b/gc) {
                return Sidef::Types::Number::Integer->new($1), pos;
            }

            # Object as expression
            when (/\G(?=\()/) {
                my ($obj, $pos) =
                  $self->parse_arguments(code => substr($_, pos));
                pos($_) = $pos + pos;
                return $obj, pos;
            }

            # Declaration of variables. (with 'var')
            # Sorry about this. :)
            when (/\Gvar\h+($self->{re}{var_name})/goc) {    # /\G([a-zA-Z]\w+)(?=\s*=\s*\()/gc

                if (exists $self->{variables}{$self->{class}}{$1}) {
                    warn "Redeclaration of variable '$1' in same scope, at line $self->{line}\n";
                }

                my $variable = Sidef::Variable::Variable->new($1);
                $self->{variables}{$self->{class}}{$1} = {
                                                          obj   => $variable,
                                                          name  => $1,
                                                          count => 0,
                                                          line  => $self->{line},
                                                         };
                return $variable, pos;
            }

            # Variable call
            when (/\G($self->{re}{var_name})/goc) {

                if (exists $self->{variables}{$self->{class}}{$1}) {
                    $self->{variables}{$self->{class}}{$1}{count}++;
                    return $self->{variables}{$self->{class}}{$1}{obj}, pos;
                }

                warn "Attempt to use an uninitialized variable: <$1>\n";
                $self->fatal_error(code => $_,
                                   pos  => (pos($_) - length($1)));
            }
            default {
                warn $self->{expect_method}
                  ? "Invalid method caller!\n"
                  : "Invalid object type!\n";
                $self->fatal_error(code => $_, pos => pos($_));
            }
        }
    }
}

sub parse_arguments {
    my ($self, %opt) = @_;

    given ($opt{'code'}) {
        {
            if (/\G/gc
                && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                pos($_) = $pos + pos($_);
            }

            when (/\G\(/gc) {
                $self->{has_object}    = 0;
                $self->{expect_method} = 0;
                $self->{parentheses}++;
                redo;
            }
            default {
                my ($obj, $pos) =
                  $self->parse_script(code => substr($_, pos));
                pos($_) = $pos + pos;
                return $obj, pos;
            }

        }
    }

}

sub parse_script {
    my ($self, %opt) = @_;

    my %struct;
    given ($opt{code}) {
        {
            if (/\G/gc
                && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                pos($_) = $pos + pos;
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
            when (/\G\z/ || /\G__END__\b/gc) {

                while (my (undef, $class_var) = each %{$self->{variables}}) {
                    while (my (undef, $variable) = each %{$class_var}) {
                        if ($variable->{count} == 0) {
                            warn "Variable '$variable->{name}' has been initialized"
                              . " at line $variable->{line}, but not used again!\n";
                        }
                        elsif ($DEBUG) {
                            warn "Variable '$variable->{name} is used $variable->{count} times!\n";
                        }
                    }
                }

                return \%struct;
            }

            # Method separator '->', or operator-method, like '*'
            when ($self->{expect_method} == 1 && (/\G->/gc || /\G(?=\s*$self->{re}{operators})/)) {

                my ($method_name, $pos) = $self->get_method_name(code => substr($_, pos));
                pos($_) = $pos + pos;

                push @{$struct{$self->{class}}[-1]{call}}, {name => $method_name,};
                redo;
            }

            # Beginning of an argument expression
            when ($self->{has_object} == 1 && /\G(?=\()/) {

                my ($arg, $pos) = $self->parse_arguments(code => substr($_, pos));
                pos($_) = $pos + pos;

                push @{$struct{$self->{class}}[-1]{call}[-1]{arg}}, $arg;
                redo;
            }

            # The end of an argument expression
            when ($self->{has_object} == 1 && /\G\)/gc) {

                if (@{[caller(1)]}) {

                    if (--$self->{parentheses} < 0) {
                        warn "Unbalanced parentheses!\n";
                        $self->fatal_error(code => $_, pos => pos($_) - 1);
                    }

                    return (\%struct, pos);
                }

                redo;

            }

            # Comma separated arguments for methods
            when (/\G,/gc) {
                my ($obj, $pos) = $self->parse_expr(code => substr($_, pos));
                pos($_) = $pos + pos;

                push @{$struct{$self->{class}}}, {self => $obj};
                redo;
            }

            # Argument as object, without parentheses
            when ($self->{has_object} == 1 && $self->{expect_method} == 1) {

                my $expr = substr($_, pos);
                my ($obj, $pos) = $self->parse_expr(code => $expr);

                if (defined $obj) {
                    pos($_) = $pos + pos;
                    push @{$struct{$self->{class}}[-1]{call}[-1]{arg}}, $obj;
                    redo;
                }
                else {
                    continue;
                }

            }

            # Parse expression or object and use it as main object (self)
            default {

                my $expr = substr($_, pos);
                my ($obj, $pos) = $self->parse_expr(code => $expr);
                pos($_) = $pos + pos;

                if (defined $obj) {

                    $self->{has_object}    = 1;
                    $self->{expect_method} = 1;

                    push @{$struct{$self->{class}}}, {self => $obj};
                    redo;
                }
                else {
                    redo;
                }

            }
        }
    }

    die "Invalid code or something weird is happening! :)\n";

}

1;
