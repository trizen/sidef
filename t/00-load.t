
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Sidef') || print "Bail out!\n";
}

diag("Testing Sidef $Sidef::VERSION, Perl $], $^X");
