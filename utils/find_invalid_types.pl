#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 September 2014
# Website: https://github.com/trizen

use 5.014;
use strict;
use warnings;

use File::Find qw(find);
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile splitdir);

my $dir = shift() // die "usage: $0 [lib dir]\n";

if (basename($dir) ne 'lib') {
    die "error: '$dir' is not a lib directory!";
}

chdir $dir;

sub make_fuzzy_regex {
    my ($word) = @_;

    my @chars = split(//, $word);
    my @typos = map {
        join '',
          map { $_ . '+' }
          @chars[0 .. $_, $_ + 2 .. $#chars]
    } 0 .. $#chars;

    do { local $" = '|'; qr/@typos/ }
}

my $root_re = make_fuzzy_regex("Sidef");

sub process_file {
    my ($file) = @_;

    open my $fh, '<', $file or return;
    while (defined(my $line = <$fh>)) {
        if (   $line =~ /(?<quote>['"])(?<name>$root_re [:;].*?)\g{quote}/xo
            || $line =~ /(?<![*&@\$])\b(?<name>$root_re(?>::\w+)+)\b/o) {
            my $name   = $+{name};
            my $module = join('/', split(/::/, $name)) . '.pm';
            my $status = eval { require $module };
            if ($@) {
                if (defined &$name) {
                    warn "=> Plain usage of function `$name', in file `$file', at line $.\n";
                }
                else {
                    warn "=> Invalid type name `$name', in file `$file', at line $.\n";
                }
            }
            elsif ($status ne '1') {
                warn "=> Dubious return-value from: ", catfile($dir, $INC{$module}), "\n";
            }
        }
    }
    close $fh;
}

find {
    no_chdir => 1,
    wanted   => sub {
        my @parts = splitdir($_);

        # Ignore the `Sidef::Deparse:Perl` module
             @parts >= 3
          && $parts[-1] =~ /\.pm\z/
          && join("/", @parts[$#parts - 2 .. $#parts]) eq 'Sidef/Deparse/Perl.pm'
          && return;

        -f and process_file($_);
    },
} => $dir;
