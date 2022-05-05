#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 24 June 2017
# http://github.com/trizen

use 5.014;
use strict;
use autodie;
use warnings;

use File::Find qw(find);
use File::Basename qw(basename);
use Text::Levenshtein::XS qw(distance);

my $dir = shift() // die "usage: $0 [lib dir]\n";

if (basename($dir) ne 'lib') {
    die "error: '$dir' is not a lib directory!";
}

my $typo_dist = 1;      # maximum typo distance

my %invokants;
my %declarations;

find {
    no_chdir => 1,
    wanted   => sub {

        /\.pm\z/ || return;

        my $content = do {
            local $/;
            open my $fh, '<:utf8', $_;
            <$fh>;
        };

        if ($content =~ /\bpackage\h+(Sidef(::\w+)*)/) {
            undef $declarations{$1};
        }
        else {
            warn "Unable to extract the package name from: $_\n";
        }

        while ($content =~ /\b(Sidef(::\w+)+)/g) {
            my $name = $1;
            push @{$invokants{$name}}, $_;

            if ($name =~ /^(.+)::/) {  # handle function calls
                push @{$invokants{$1}}, $_;
            }
        }
    },

} => $dir;

my @invokants    = keys(%invokants);
my @declarations = keys(%declarations);

foreach my $invo (@invokants) {

    next if exists($declarations{$invo});

    foreach my $decl (@declarations) {
        if (abs(length($invo) - length($decl)) <= $typo_dist
            and distance($invo, $decl) <= $typo_dist) {
            say "Possible typo: <<$invo>> instead of <<$decl>> in:";
            say "\t", join(
                "\n\t",
                do {
                    my %seen;
                    grep { !$seen{$_}++ } @{$invokants{$invo}};
                  }
              ),
              "\n";
        }
    }
}
