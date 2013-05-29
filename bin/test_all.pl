#!/usr/bin/perl

foreach my $sidef_script (glob '*.sf') {

    print "\n\n=>> Executing $sidef_script\n", "-" x 80, "\n";
    sleep 1;

    system $^X, '-X', 'sidef', $sidef_script;

    if ($? != 0) {
        die "Non-zero exit code for script: $sidef_script\n";
    }
}
