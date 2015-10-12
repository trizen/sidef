#!/usr/bin/perl

use 5.020;
use strict;
use warnings;

use Regexp::Grammars;

my $code = 'func (a, b) { a + b * 42 }';

my $parser = qr{

        <[expression]>*

        <rule: class>     class <args>? <block>
        <rule: function>  func <args>? <block>

        <rule: block>   \{ <[expression]>* \}
        <rule: args>    \( <[identifier]>* % (,) \)

        <rule: expression>                  <function> | <block> | <class> | <equality_expression>
        <rule: eq_expr>                     (?: == | != ) <additive_expression>
        <rule: equality_expression>         <additive_expression> <[eq_expr]>*
        <rule: add_expr>                    [+\-] <multiplicative_expression>
        <rule: additive_expression>         <multiplicative_expression> <[add_expr]>*
        <rule: mult_expr>                   [*/] <primary>
        <rule: multiplicative_expression>   <primary> <[mult_expr]>*
        <rule: primary>                     \( <expression> \) | <number> | <identifier> | - <primary>

        <rule: number>                      \d+
        <rule: identifier>                  [\pL_][\pL\pN_]*

}xms;

$code =~ $parser;

use Data::Dump qw(pp);
pp \%/;
