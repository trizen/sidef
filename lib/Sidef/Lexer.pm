
use 5.014;
use strict;
use warnings;

BEGIN {
    use File::Spec::Functions qw(rel2abs);
}

use lib rel2abs '../../lib';

package Sidef::Lexer;

use Sidef::Base;

sub make_esc_delim {
    if ($_[0] ne '\\') {
        my $delim = quotemeta shift;
        return qr{$delim([^$delim\\]*+(?>\\.|[^$delim\\]+)*+)$delim}s;
    }
    else {
        return qr{\\(.*?)\\}s;
    }
}

my $double_quote = make_esc_delim(q{"});
my $single_quote = make_esc_delim(q{'});

sub new {
    my ($class) = @_;
    bless {}, $class;
}

{

    my $line        = 1;
    my $cbracket    = 0;
    my $parentheses = 0;

    state $operators_re = do {
        local $" = q{|};

        my @operators = map { quotemeta } qw(

          && || // ** << >> ==
          / + - * % ^ & | :  =

          );

        qr{(@operators)};
    };

    sub syntax_error {
        my %opt = @_;
        die "Syntax error near: --->",
          substr($opt{'code'}, $opt{'pos'}, index($opt{'code'}, "\n", $opt{'pos'}) - $opt{'pos'}),
          "<--- at line $line.\n";
    }

    sub get_method_name {
        my %opt = @_;

        given ($opt{'code'}) {

            if (/\G/gc && defined(my $pos = parse_whitespace(code => substr($_, pos)))) {
                pos($_) = $pos + pos($_);
            }

            when (/\G(\w+)/gc) {
                return $1, pos;
            }
            when (m{\G$operators_re}gc) {
                return $1, pos;
            }
            default {
                die "Invalid method name, at line $line.\n";
            }
        }
    }

    sub parse_whitespace {
        my (%opt) = @_;

        given ($opt{code}) {
            {
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
                default {
                    return pos;
                }
            }
        }

        return;
    }

    sub parse_expr {
        my (%opt) = @_;

        given ($opt{code}) {
            {
                if (/\G/gc && defined(my $pos = parse_whitespace(code => substr($_, pos)))) {
                    pos($_) = $pos + pos($_);
                }

                when (/\G;/gc || /\G\z/gc) {
                    return undef, pos;
                }
                when (/\G$double_quote/gc) {
                    return Sidef::Types::String::Double->new($1), pos;
                }
                when (/\G$single_quote/gc) {
                    return Sidef::Types::String::Single->new($1), pos;
                }
                when (/\G((?>true|false))\b/gc) {
                    return Sidef::Types::Bool::Bool->new($1), pos;
                }
                when (/\G([+-]?\d+\.\d*)/gc) {
                    return Sidef::Types::Number::Float->new($1), pos;
                }
                when (/\G([+-]?\d+)\b/gc) {
                    return Sidef::Types::Number::Integer->new($1), pos;
                }
                default {
                    warn "Can't parse expression!\n";
                    syntax_error(code => $_, pos => pos($_));
                }
            }
        }
    }

    sub parse_arguments {
        my %opt = @_;

        my @arg;

        given ($opt{'code'}) {
            {

                if (/\G/gc && defined(my $pos = parse_whitespace(code => substr($_, pos)))) {
                    pos($_) = $pos + pos($_);
                }

                when (/\G\(/gc) {
                    $parentheses++;
                    redo;
                }
                when (/\G\)/gc) {
                    $parentheses--;

                    if ($parentheses == 0) {
                        return \@arg, pos;
                    }

                    if ($parentheses < 0) {
                        warn "Unbalanced parentheses!";
                        syntax_error(code => $_, pos => pos($_));
                    }

                    redo;
                }
                default {
                    my ($obj, $pos) = parse_script(code => substr($_, pos));
                    return $obj, $pos;
                }

            }
        }

    }

    sub parse_script {

        my %opt = @_;

        my %struct;
        my $class = 'main';

        given ($opt{code}) {
            {

                when (/\Gclass\h+/gc) {
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

                when (/\G\z/gc) {
                    return \%struct;
                }
                when (/\G->/gc || /\G(?=\s*$operators_re)/) {

                    my ($method_name, $pos) = get_method_name(code => substr($_, pos));
                    pos($_) = $pos + pos;

                    #die $method_name;

                    push @{$struct{$class}[-1]{call}}, {name => $method_name,};

                    redo;

                    #if (/\G(\w+)/gc) {
                    #     $method_name = $1;
                    #}
                    #elsif (m{\G([-+/*%])}gc) {
                    #    $method_name = $1;
                    #}

                    #++$#{$struct{$class}[-1]{call}};
                    #$struct{$class}[-1]{call} =

                    #my ( $expr, $pos ) = parse_expr(code => substr($_, pos));

                }

                when (/\G(?=\()/) {
                    my ($arg, $pos) = parse_arguments(code => substr($_, pos));
                    pos($_) = $pos + pos;

                    #push @{$struct{$class}[-1]{arg}}, $arg;
                    push @{$struct{$class}[-1]{call}[-1]{arg}}, $arg;

                    redo;
                }

                when (/\G\)/gc) {
                    --$parentheses;

                    if (@{[caller(1)]}) {
                        return (\%struct, pos);
                    }
                    else {
                        redo;
                    }

                    #say "->>>>", substr($_, pos);

                    #if($parentheses == 0){
                    #    return (\%struct, pos);
                    #}
                    #els
                    #else{
                    #    return \%struct, pos;
                    #}

                    # redo;
                    #--$parentheses;

                    #redo;
                }

                #while(/\G\h*,/gc){
                #        my($obj, $pos) = parse_expr( code => substr($_, pos) );
                #        pos($_) = $pos + pos;

                # push as argument
                # }

                when (/\G/gc) {
                    my $expr = substr($_, pos);
                    my ($obj, $pos) = parse_expr(code => $expr);
                    pos($_) = $pos + pos;

                    if (defined $obj) {

                        push @{$struct{$class}}, {self => $obj,};

                        redo;

                    }
                    else {
                        # die "Undefined object, at line $line.\n";
                        redo;
                    }

                }
            }
        }

        return \%struct;

    }

}

=cut

    {
    main => [
      {
            self => Number->new(81),
            call => [
                {
                name => 'sqrt',
                arg => [],
                }
            ],
    },

    {
        self => String->new('string'),
        call => [
            {
                name => 'lc',
                arg => [],
            },
            {
                name => 'uc',
                arg => [],
            },
            {
                name => 'print',
                arg => [],
            }
        ],

    },

    {
    self => Number->new(12);
    arg => [
        {
        self => Number->new(63),
        arg => [
            {
                self => Number->new(2),
            },
        ],
        call => ['/'],
    }
    ],
    call => ['/', 'to_s', 'print'],

    }
    ],
    class => [],
}

=cut

my $code = <<'CODE';

81->sqrt;

#12/(63/(2)/(3))->to_s->print;

24/(18*(3))->to_s(3)->print;   # should print 4

"string"->lc->uc->print;


44.2->int->log10;

CODE

my ($struct, $pos) = parse_script(code => $code);

use Data::Dump qw(pp);
pp $struct;

__END__

BINGO!!!


{
  main => [
    {
      call => [{ name => "sqrt" }],
      self => bless(do{\(my $o = 81)}, "Sidef::Types::Number::Integer"),
    },
    {
      call => [
                {
                  arg  => [
                            {
                              main => [
                                {
                                  call => [
                                            {
                                              arg  => [
                                                        {
                                                          main => [
                                                            {
                                                              self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                                            },
                                                          ],
                                                        },
                                                      ],
                                              name => "*",
                                            },
                                          ],
                                  self => bless(do{\(my $o = 18)}, "Sidef::Types::Number::Integer"),
                                },
                              ],
                            },
                          ],
                  name => "/",
                },
                {
                  arg  => [
                            {
                              main => [
                                {
                                  self => bless(do{\(my $o = 3)}, "Sidef::Types::Number::Integer"),
                                },
                              ],
                            },
                          ],
                  name => "to_s",
                },
                { name => "print" },
              ],
      self => bless(do{\(my $o = 24)}, "Sidef::Types::Number::Integer"),
    },
    {
      call => [{ name => "lc" }, { name => "uc" }, { name => "print" }],
      self => bless(do{\(my $o = "string")}, "Sidef::Types::String::Double"),
    },
    {
      call => [{ name => "int" }, { name => "log10" }],
      self => bless(do{\(my $o = 44.2)}, "Sidef::Types::Number::Float"),
    },
  ],
}
