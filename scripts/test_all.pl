#!/usr/bin/perl

use strict;
use warnings;

my $sidef = '../bin/sidef';

my %ignored;
@ignored{
    qw(
      100_doors_3.sf
      A+B.sf
      anagrams.sf
      anagrams_deranged_anagrams.sf
      arithmetic_integer_stdin.sf
      benford_s_law.sf
      bulls_and_cows.sf
      bulls_and_cows_player.sf
      levenshtein_recursive.sf
      fibonacci_validation.sf
      fibonacci_closed_solution.sf
      dice_game_solver.sf
      stdin.sf
      rock_paper_scissors.sf
      )
} = ();

foreach my $sidef_script (glob '*.sf') {

    next if exists $ignored{$sidef_script};

    print "\n\n=>> Executing $sidef_script\n", "-" x 80, "\n";
    system $^X, $sidef, @ARGV, $sidef_script;

    if ($? != 0) {
        die "Non-zero exit code for script: $sidef_script\n";
    }
}
