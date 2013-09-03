#!/usr/bin/perl

use strict;
use warnings;

my %ignored;
@ignored{
    qw(
      100_doors_3.sf
      A+B.sf
      anagrams.sf
      anagrams_deranged_anagrams.sf
      levenshtein_recursive.sf
      fibonacci_validation.sf
      dice_game_solver.sf
      stdin.sf
      rock_paper_scissors.sf
      )
} = ();

foreach my $sidef_script (glob '*.sf') {

    next if exists $ignored{$sidef_script};

    print "\n\n=>> Executing $sidef_script\n", "-" x 80, "\n";
    system $^X, '../bin/sidef', $sidef_script;

    if ($? != 0) {
        die "Non-zero exit code for script: $sidef_script\n";
    }
}
