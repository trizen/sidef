#!/usr/bin/perl

# usage: perl test_all.pl [/regex/] [sidef argvs]

use strict;
use warnings;
use re 'eval';

my $sidef = '../bin/sidef';

my %ignored;
@ignored{
    qw(
      built_in_classes.sf
      http_tiny.sf
      lwp_module.sf
      quicksort_in_parallel.sf
      metaprogramming_method_definition.sf
      metaprogramming_2.sf
      file_find_module.sf
      multi_file_edit.sf
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

my $ignored;
if (@ARGV and $ARGV[0] eq 'ignored') {
    $ignored = 1;
    shift @ARGV;
}

my @scripts = grep {my $bool = exists $ignored{$_}; $ignored ? $bool : !$bool} glob('*.sf');
if (defined $regex_filter) {
    @scripts = grep {/$regex_filter/} @scripts;
}

system $^X, $sidef, @ARGV, '-t', @scripts;

if ($? != 0) {
    die "Non-zero exit code: $?";
}
