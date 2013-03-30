
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

    sub get_method_name {
        my %opt = @_;

        state $operators_re = do {
            local $" = q{|};

            my @operators = map { quotemeta } qw(

              && || // ** << >> ==
              / + - * % ^ & | :  =

              );

            qr{(@operators)};
        };

        given ($opt{'code'}) {
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

    sub parse_expr {
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
                    continue;
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
                when (/\G(\d+)\b/gc) {
                    return Sidef::Types::Number::Integer->new($1), pos;
                }
                when (/\G(\d+\.\d*)/gc) {
                    return Sidef::Types::Number::Float->new($1), pos;
                }
                default {
                    die "Syntax error at line $line.\n";
                }
            }
        }
    }

    sub parse_script {

        my %opt = @_;

        my %struct;
        my $ref = $struct{main} //= [];
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
                when (/\G->/gc) {

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

                    # ++$ref;
                    # $ref->[-1]

                    #++$#{$struct{$class}};
                    #$struct{$class}[-1]{self} = $obj;

                    #redo;

                    #push @{$struct{$class}}
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

"string"->lc->uc->print;

#12/ ( 63/(2) /(3) )->to_s->print;

CODE

my $struct = parse_script(code => $code);

use Data::Dumper;
print Dumper $struct;
