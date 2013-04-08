
use 5.014;
use strict;
use warnings;

use lib '../../lib';    # devel only

package Sidef::Lexer;

use Sidef::Init;

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

            when (/\G([a-z]\w+)/gc) {
                return $1, pos;
            }
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
                when (/\G#.*/gc) {
                    redo;
                }
                when (/\G(?=[\h\v])/) {
                    when (/\G\R/gc) {
                        ++$line;
                        redo;
                    }
                    when (/\G\h+/gc) {
                        redo;
                    }
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

        state $double_quote = Sidef::Utils::Regex::make_esc_delim(q{"});
        state $single_quote = Sidef::Utils::Regex::make_esc_delim(q{'});

        given ($opt{code}) {
            {
                if (/\G/gc && defined(my $pos = $self->parse_whitespace(code => substr($_, pos)))) {
                    pos($_) = $pos + pos($_);
                }

                when (/\G;/gc || /\G\z/) {
                    $has_object    = 0;
                    $expect_method = 0;
                    return undef, pos;
                }

                $has_object = 1;
                when (/\G$double_quote/gc) {
                    return Sidef::Types::String::Double->new($1), pos;
                }
                when (/\G$single_quote/gc) {
                    return Sidef::Types::String::Single->new($1), pos;
                }
                when (/\G((?>true|false))\b/gc) {
                    return Sidef::Types::Bool::Bool->new($1), pos;
                }
                when (/\G([+-]?\d+\.\d+)\b/gc) {
                    return Sidef::Types::Number::Float->new($1), pos;
                }
                when (/\G([+-]?\d+)\b/gc) {
                    return Sidef::Types::Number::Integer->new($1), pos;
                }
                when (/\G(?=\()/) {
                    my ($obj, $pos) = $self->parse_arguments(code => substr($_, pos));
                    pos($_) = $pos + pos;
                    return $obj, pos;
                }
                when (/\G([a-zA-Z]\w+)(?=\s*=\s*\()/gc) {
                    my $variable = Sidef::Variable::Variable->new($1);
                    $variables{$class}{$1} = $variable;
                    return $variable, pos;
                }
                when (/\G([a-zA-Z]\w+)/gc) {

                    if (exists $variables{$class}{$1}) {
                        return $variables{$class}{$1}, pos;
                    }

                    warn "Attempt to use an uninitialized variable: <$1>\n";
                    $self->syntax_error(code => $_, pos => (pos($_) - length($1)));
                }
                default {
                    warn "Invalid object type!\n";
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

                when (/\Gclass\h*/gc) {
                    when (/\G"(.*?)"/gc) {
                        $class = $1;
                        redo;
                    }
                    when (/\G'(.*?)'/gc) {
                        $class = $1;
                        redo;
                    }

                    die "Expected class name, at line $line.\n";
                }

                when (/\G\z/) {
                    return \%struct;
                }
                when ($expect_method == 1 && (/\G->/gc || /\G(?=\s*$operators_re)/)) {

                    my ($method_name, $pos) = $self->get_method_name(code => substr($_, pos));
                    pos($_) = $pos + pos;

                    push @{$struct{$class}[-1]{call}}, {name => $method_name,};
                    redo;
                }
                when ($has_object == 1 && /\G(?=\()/) {

                    my ($arg, $pos) = $self->parse_arguments(code => substr($_, pos));
                    pos($_) = $pos + pos;

                    #push @{$struct{$class}[-1]{arg}}, $arg;
                    push @{$struct{$class}[-1]{call}[-1]{arg}}, $arg;

                    redo;
                }
                when ($has_object == 1 && /\G\)/gc) {

                    if (@{[caller(1)]}) {

                        if (--$parentheses < 0) {    # for some reason, it's not working...
                            warn "Unbalanced parentheses!\n";
                            $self->syntax_error(code => $_, pos => pos($_) - 1);
                        }

                        return (\%struct, pos);
                    }

                    redo;

                }

                ## Support for variables
                ## might be defined bellow.

                #when(/\G\w+/gc){
                #    warn "Variables not implemented, yet!\n";
                #      $self->syntax_error(code => $_, pos => pos($_));
                #}

                ## This code will be used to support
                ## more than one argument for a method

                #while(/\G\h*,/gc){
                #        my($obj, $pos) = parse_expr( code => substr($_, pos) );
                #        pos($_) = $pos + pos;
                # }

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

        return \%struct;

    }
}
