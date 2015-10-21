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

# Initialize a new parser and a new deparser
my $parser = Sidef::Parser->new();
my $deparser = Sidef::Deparse::Perl->new();

# Parse some code and store the returned parse-tree
my $struct = $parser->parse_script(code => \<<'SIDEF_CODE');

func fib(n) {
    n > 1 ? (__FUNC__(n-1) + __FUNC__(n-2)) : n;
}

fib(12);

SIDEF_CODE

# Generate Perl code and evaluate it
my $num = eval $deparser->deparse($struct);

# Output the result
say $num;

# Do something with the result computed in Sidef
say sqrt($num->get_value);
