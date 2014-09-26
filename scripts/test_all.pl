#!/usr/bin/perl

# usage: perl test_all.pl [/regex/] [sidef argvs]

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
      http_tiny.sf
      langton_s_ant.sf
      langton_s_ant_2.sf
      levenshtein_recursive.sf
      lwp_module.sf
      fibonacci_validation.sf
      quicksort_in_parallel.sf
      metaprogramming_method_definition.sf
      metaprogramming_2.sf
      file_find_module.sf
      dice_game_solver.sf
      stdin.sf
      multi_file_edit.sf
      cosmic_calendar.sf
      rock_paper_scissors.sf
      tk_library.sf
      )
} = ();

if ($] < 5.018) {
    undef $ignored{'JASH.sf'};
}

my $regex_filter;
if (@ARGV and $ARGV[0] =~ m{^/(.+)/$}) {
    $regex_filter = qr/$1/i;
    shift @ARGV;
}

foreach my $sidef_script (glob '*.sf') {

    if (defined $regex_filter) {
        next unless $sidef_script =~ $regex_filter;
    }
    next if exists $ignored{$sidef_script};

    print "\n\n=>> Executing $sidef_script\n", "-" x 80, "\n";
    system $^X, $sidef, @ARGV, $sidef_script;

    if ($? != 0) {
        die "Non-zero exit code for script: $sidef_script\n";
    }
}
