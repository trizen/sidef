#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 April 2014
# Wesbite: https://github.com/trizen

# Experimental Sidef parser, using Damian Conway's Regexp::Grammars.

use 5.010;
use strict;
use warnings;
use Data::Dump qw(pp);

BEGIN {
    $SIG{__WARN__} = sub { };
};

use Regexp::Grammars;
local $SIG{__WARN__} = sub { print STDERR @_ };

my $parser = qr{
        <[main]>*

        <rule: main>
            <obj> ((?:\.|\s*)<[method]>)* ;*

        <rule: obj>
              "([^"\\]+|\\.)*"
            | \d+(?:\.\d+)?
            | \{ <[main]> \}

        <rule: args>
            \(<[obj]>(?:,<[obj]>)*\)

        <rule: name>
            (say|print|sort)

        <rule: method>
            <name> <args>?
    }xms;

my $text = <<'CODE';
"hello".sort("test", "here").print;
{
    "sidef" say;
}
CODE

if ($text =~ $parser) {
    #print Dumper(\%/);
    pp \%/;
}

__END__
