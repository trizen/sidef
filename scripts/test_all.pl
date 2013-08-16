#!/usr/bin/perl

use strict;
use warnings;
use List::Util qw(first);

my @ignored = qw(
  100_doors_3.sf
  dice_game_solver.sf
  stdin.sf
  rock_paper_scissors.sf
  );

foreach my $sidef_script (glob '*.sf') {

    next if first { $_ eq $sidef_script } @ignored;

    print "\n\n=>> Executing $sidef_script\n", "-" x 80, "\n";
    sleep 1;

    system $^X, '../bin/sidef', $sidef_script;

    if ($? != 0) {
        die "Non-zero exit code for script: $sidef_script\n";
    }
}
