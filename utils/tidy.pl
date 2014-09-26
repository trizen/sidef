#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Created on: 12 May 2014
# Latest edit on: 13 May 2014
# http://github.com/trizen/sidef

# Parses and beautifies Sidef source code

use 5.010;
use strict;
use autodie;
use warnings;

use open IO     => 'utf8';
use open ':std' => 'utf8';

use Sidef::Tidy qw(sf_beautify);
use Getopt::Std qw(getopts);

sub usage {
    print <<"HELP";
usage: $0 [options] [files]

options:
        -b  : backup the current file
        -h  : print this message and exit

example: $0 -b script.ext
HELP

    exit shift();
}

my %opt;
getopts('bh', \%opt);

$opt{h} && usage(0);
@ARGV || usage(2);

foreach my $file (@ARGV) {
    open my $fh, '<', $file;
    my $content = do { local $/; <$fh> };

    state $out_h = \*STDOUT;
    $opt{b} && do {
        rename $file, "$file.bak";
        open $out_h, '>', $file;
    };

    say {$out_h}
      sf_beautify(
                  $content => {
                               indent_size               => 4,
                               indent_character          => ' ',
                               preserve_newlines         => 1,
                               space_after_anon_function => 1,
                              }
                 );
}
