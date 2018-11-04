#!/usr/bin/perl

#
## This file shows how to parse and execute
## arbitrary Sidef code from any Perl script.
#

use 5.014;
use strict;
use warnings;

# The directory where Sidef lives
use lib qw(../../lib);

# Load the Sidef main module
use Sidef;

my $sidef = Sidef->new(
                       name       => 'test',    # program name
                       opt        => {},        # command-line options
                       parser_opt => {},        # parser options
                      );

# Parse arbitrary Sidef code into an AST
my $ast = $sidef->parse_code(<<'SIDEF_CODE');

func fib(n) {
    n > 1 ? (__FUNC__(n-1) + __FUNC__(n-2)) : n;
}

fib(12);

SIDEF_CODE

# Compile the AST as Perl code
my $perl_code = $sidef->compile_ast($ast, 'Perl');

# Compile the AST as Sidef code
my $sidef_code = $sidef->compile_ast($ast, 'Sidef');

# Show deparsed code
say "=> Deparsed Sidef code:";
print '-' x 80, "\n", $sidef_code, '-' x 80, "\n";

# Evaluate the Perl code
my $num = eval($perl_code);

# Output the result
say $num;

# Do something with the result computed in Sidef
say sqrt($num->get_value);
