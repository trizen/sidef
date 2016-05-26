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

# Execute arbitrary Sidef code
my $num = $sidef->execute_code(<<'SIDEF_CODE');

func fib(n) {
    n > 1 ? (__FUNC__(n-1) + __FUNC__(n-2)) : n;
}

fib(12);

SIDEF_CODE

# Output the result
say $num;

# Do something with the result computed in Sidef
say sqrt($num->get_value);
