#!/usr/bin/perl

use 5.016;
use strict;
use warnings;

require OOPerl;

my $script = <<'CODE';
#!/usr/bin/ooperl

# Author: Trizen
# License: GPLv3
# Date: 26 March 2013
# http://trizen.googlecode.com

"val"->assign(item);    # item contains "val"
[item]->pop->print;     # prints "val"
25->sqrt->to_s->print;  # prints "5"

{
    "x"->print;
}->if(25->sqrt->is_true(["s"]));

{
    "hey"->print;           # should print "hey"

    {
        "nested block"->print;
    }

    -23->abs->to_s->print;  # should print "23"
}
->while(false);

class "Test";

{
    #\1->print;      # should print "v"
    "str"->print;
}
->if(item->match(m{^(\w)}i));


#24->/(6)->print;    # prints "4"

12/(63/(2)/(3))->to_s->print;   # fuck!


# -23->abs->to_s->print;  # should print "23"
CODE

$script = q{21->sqrt->func("item", 24->func2("option"));};

=cut
# 21->sqrt->func('item', 24->func2('option'));

{
 self => 21,
 call => [
          {
           name => 'sqrt',
           arg  => [],
          },
          {
           name => 'func',
           arg  => [
                   'item',
                   {
                    self => 24,
                    call => [
                             {
                              name => 'func2',
                              arg  => ['option'],
                             }
                            ],
                   },
                  ],
          }
         ],
}

=cut

{
    my $line        = 1;
    my $cbracket    = 0;
    my $parentheses = 0;

    sub parse_expr {
        my %opt = @_;

        my %struct;

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

                when (/\G([+-]?[0-9]+(?:\.[0-9]+)?)/gc) {

                    #                     push @{$struct{$class}}, {
                    #                            self => Number->new($1),
                    #                        };
                    #                    redo;
                    return (Number->new($1), pos);
                }
                when (/\G"(.*?)"/sgc) {

                    #  push @{$struct{$class}}, {
                    #          self => String->new($1),
                    #     };
                    return (String->new($1), pos);

                    # redo;
                }

                when (/\G[;,]+/gc || /\G\z/gc) {
                    return (undef, pos);
                }
                when (/\G((?>true|false))\b/gc) {
                    return (Bool->new($1), pos);
                }

                #  when(/\G\(/gc){
                #      ++$parentheses;

                #            }
                when (/\Gm\{(.*?)\}(\w*)/gc) {
                    return Regex->new($1, $2);
                }
                default {
                    warn "Can't parse expression! Error at line $line.\n";
                    die "Syntax error near: --->", substr($_, pos, index($_, "\n", pos) - pos), "<--- at line $line.\n";
                }
            }
        }

        return \%struct;

    }

    sub generate_struct {
        my %opt = @_;

        my %struct;
        my $class = 'main';
        my @expr;

        given ($opt{code}) {
            {
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
                when (/\G\{/gc) {
                    ++$cbracket;
                    my ($data, $pos) = __SUB__->(code => substr($_, pos));
                    push @{$struct{$class}}, {block => $data,};
                    pos($_) = $pos + pos;
                    redo;
                }
                when (/\G\}/gc) {
                    --$cbracket;
                    return +($struct{main}, pos) if $cbracket == 0;
                    redo;
                }
                when (/\G(?>\.|->)(\w+)/gsc) {

                    #push @expr, $1;

=cut
                     push @{$struct{$class}[-1]{call}}, $1;
                     when(/\G\h*\(/gc){
                        ++$parentheses;
                        my($data, $pos) = __SUB__->(code => substr($_, pos), expr => 1);
                        push @{$struct{'call'}[-1]{arg}}, $data;
                        pos($_) = $pos + pos;
                        redo;
                    }
=cut

                    redo;
                }
                when (/\G\[(.*?)\]/gc) {

                    #my @items = split(/\s*,\s*/, $1);
                    my ($items, $pos) = __SUB__->(code => $1, expr => 1);

                    #use Data::Dump qw(pp);
                    #pp $items;
                    #exit;
                    my @items;
                    push @{$struct{$class}}, {self => Array->new(\@items),};
                    redo;
                }
                when (/\G(\w+)/gc) {
                    push @{$struct{$class}}, {var => $1};
                    redo;
                }
          #      when (m{\G([/=*+\-%^~&])\h*\(}gc) {
           #         ++$parentheses;
           #         push @{$struct{$class}[-1]{call}}, $1;
           #         use Data::Dump qw(pp);

            #        my ($data, $pos) = __SUB__->(code => substr($_, pos), expr => 1);

            #        push @{$struct{$class}[-1]{arg}}, $data;
              #      pos($_) = $pos + pos;
             #       redo;

                    #pp $struct{$class}[-1];
                    #exit;
                    #pp __SUB__->(code => substr($_, pos), expr => 1);
                    #exit;
              #  }

                # when(/\G\(/gc){
                #         ++$parentheses;
                #         my($data, $pos) = __SUB__->(code => substr($_, pos), expr => 1);
                #         push @{$struct{$class}[0]{arg}}, $data;
                #         pos($_) = $pos + pos;
                #        redo;
                #}
               # when (/\G\)/gc) {
               #     --$parentheses;

                    #use Data::Dump qw(pp);
                    #pp $struct{main};
               #     return +(@{$struct{main}}, pos) if $parentheses == 0;
              #      die "Unbalanced parentheses, at line $line\n" if $parentheses < 0;
              #      redo;
              #  }
              when(/\G\(/gc){

              }
                #when (/\G;/gc) {
                #    return +(@{$struct{main}}, pos) if $opt{expr};
                #    redo;
                #}

                when (/\G\z/gc) {
                    break;
                }
                default {
                        my ($val, $pos) = parse_expr(code => substr($_, pos));
                        pos($_) = $pos + pos;

                        use Data::Dump qw(pp);
                        pp $val;

                        if (defined $val) {
                            push @expr, $val;
                            redo;
                        }

                    die "Syntax error near: --->", substr($_, pos, index($_, "\n", pos) - pos), "<--- at line $line.\n";
                }
            }
        }

        return (\%struct, length($script));
    }
}

my ($struct, $len) = generate_struct(code => $script);
use Data::Dump qw(pp);
pp $struct;

my $x    = {call => "print", val => String->new("xx")};
my $str  = $x->{val};
my $call = $x->{call};

$str->$call;

#($$x{val})->$$x{call};

=for comment

%struct content:

main  => { main    => [expr,expr],   # executed on run
           block1  => [expr,expr],   # executed when block is called
           block2  => [expr,expr],   # =//=
         },
class => { main   => [expr,expr],    # executed on run
           block1 => [expr,expr],    # executed when class+block is called
           block2 => [expr,expr],    # =//=
         },
...
=cut
