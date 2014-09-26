#!/usr/bin/perl

#
## This file shows how to parse and execute
## arbitrary Sidef code from any Perl script.
#

use 5.010;
use strict;
use warnings;

# The directory where Sidef lives
use lib qw(../lib);

# Initialize (almost) all the built-in objects
use Sidef::Init;

# Initialize a new parser
my $parser = Sidef::Parser->new();

# Parse some code and store the returned parse-tree
my $struct = $parser->parse_script(code => <<'SIDEF_CODE');

func fib(n) {
    n > 1 ? (__FUNC__(n-1) + __FUNC__(n-2)) : n;
}

fib(12);

SIDEF_CODE

# Execute the parse-tree and store the result
my $num = Sidef::Exec->new->execute($struct);

# Do something with the result computed in Sidef
say sqrt($num->get_value);
