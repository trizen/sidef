
use 5.014;
use strict;
use warnings;

use lib '../../lib';    # devel only

package Sidef::Lexer;

use Sidef::Init;

our $DEBUG = 0;

sub new {
    my ($class) = @_;
    bless {}, $class;
}

{
    my %variables;

    my $line          = 1;
    my $has_object    = 0;
    my $expect_method = 0;
    my $cbracket      = 0;
    my $parentheses   = 0;
    my $class         = 'main';

    state $operators_re = do {
        local $" = q{|};

        my @operators = map { quotemeta } qw(

          && || // ** << >> ==
          / + - * % ^ & | :  =

          );

        qr{(@operators)};
    };

    state $var_re       = qr/[a-zA-Z_]\w*/;
    state $double_quote = Sidef::Utils::Regex::make_esc_delim(q{"});
    state $single_quote = Sidef::Utils::Regex::make_esc_delim(q{'});

    sub syntax_error {
        my ($self, %opt) = @_;
        die "\n** Syntax error at line $line, near:\n\t\"",
          substr($opt{'code'}, $opt{'pos'}, index($opt{'code'}, "\n", $opt{'pos'}) - $opt{'pos'}), "\"\n";
    }

    sub get_method_name {
        my ($self, %opt) = @_;

        given ($opt{'code'}) {

            if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                pos($_) = $pos + pos($_);
            }

            # Alpha-numeric method name
            when (/\G([a-z]\w+)/gc) {
                return $1, pos;
            }

            # Operator-like method name
            when (m{\G$operators_re}gc) {
                return $1, pos;
            }
            default {
                warn "Invalid method name!\n";
                $self->syntax_error(code => $_, pos => pos($_));
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
                        ++$line;
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

                # End of the expression (or end of the file)
                when (/\G;/gc || /\G\z/) {
                    $has_object    = 0;
                    $expect_method = 0;
                    return undef, pos;
                }

                $has_object = 1;

                # Double quoted string
                when (/\G$double_quote/gc) {
                    return Sidef::Types::String::Double->new($1), pos;
                }

                # Single quoted string
                when (/\G$single_quote/gc) {
                    return Sidef::Types::String::Single->new($1), pos;
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
                    my ($obj, $pos) = $self->parse_arguments(code => substr($_, pos));
                    pos($_) = $pos + pos;
                    return $obj, pos;
                }

                # Declaration of variables. (with 'var')
                # Sorry about this. :)
                when (/\Gvar\h+($var_re)/gc) {    # /\G([a-zA-Z]\w+)(?=\s*=\s*\()/gc

                    if (exists $variables{$class}{$1}) {
                        warn "Redeclaration of variable '$1' in same scope, at line $line\n";
                    }

                    my $variable = Sidef::Variable::Variable->new($1);
                    $variables{$class}{$1} = {
                                              obj   => $variable,
                                              name  => $1,
                                              count => 0,
                                              line  => $line,
                                             };
                    return $variable, pos;
                }

                # Variable call
                when (/\G($var_re)/gc) {

                    if (exists $variables{$class}{$1}) {
                        $variables{$class}{$1}{count}++;
                        return $variables{$class}{$1}{obj}, pos;
                    }

                    warn "Attempt to use an uninitialized variable: <$1>\n";
                    $self->syntax_error(code => $_, pos => (pos($_) - length($1)));
                }
                default {
                    warn $expect_method ? "Invalid method caller!\n" : "Invalid object type!\n";
                    $self->syntax_error(code => $_, pos => pos($_));
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
                    $has_object = 0;
                    $parentheses++;
                    redo;
                }
                default {
                    my ($obj, $pos) = $self->parse_script(code => substr($_, pos));
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
                if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                    pos($_) = $pos + pos;
                }

                # Class declaration
                when (/\Gclass\h*/gc) {

                    # Maybe, we should make some function: get_quoted_string()
                    # which supports q{}, qq{}, '', and ""
                    when (/\G($double_quote|$single_quote)/gc) {
                        $class = $1;
                        redo;
                    }

                    die "Expected class name, at line $line.\n";
                }

                # We are at the end of the script file.
                # We make some checks, and return the \%struct hash ref.
                when (/\G\z/) {

                    while (my (undef, $class_var) = each %variables) {
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
                when ($expect_method == 1 && (/\G->/gc || /\G(?=\s*$operators_re)/)) {

                    my ($method_name, $pos) = $self->get_method_name(code => substr($_, pos));
                    pos($_) = $pos + pos;

                    push @{$struct{$class}[-1]{call}}, {name => $method_name,};
                    redo;
                }

                # Beginning of an argument expression
                when ($has_object == 1 && /\G(?=\()/) {

                    my ($arg, $pos) = $self->parse_arguments(code => substr($_, pos));
                    pos($_) = $pos + pos;

                    push @{$struct{$class}[-1]{call}[-1]{arg}}, $arg;
                    redo;
                }

                # The end of an argument expression
                when ($has_object == 1 && /\G\)/gc) {

                    if (@{[caller(1)]}) {

                        if (--$parentheses < 0) {
                            warn "Unbalanced parentheses!\n";
                            $self->syntax_error(code => $_, pos => pos($_) - 1);
                        }

                        return (\%struct, pos);
                    }

                    redo;

                }

                # Argument as object, without parentheses
                when ($has_object == 1 && $expect_method == 1) {

                    my $expr = substr($_, pos);
                    my ($obj, $pos) = $self->parse_expr(code => $expr);

                    if (defined $obj) {
                        pos($_) = $pos + pos;
                        push @{$struct{$class}[-1]{call}[-1]{arg}}, $obj;
                        redo;
                    }
                    else {
                        continue;
                    }

                }

                ## This code will be used to support
                ## more than one argument for a method

                #while(/\G\h*,/gc){
                #        my($obj, $pos) = parse_expr( code => substr($_, pos) );
                #        pos($_) = $pos + pos;
                # }

                # Parse expression or object and use it as main object (self)
                default {

                    my $expr = substr($_, pos);
                    my ($obj, $pos) = $self->parse_expr(code => $expr);
                    pos($_) = $pos + pos;

                    if (defined $obj) {

                        $has_object    = 1;
                        $expect_method = 1;

                        push @{$struct{$class}}, {self => $obj};
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
}
