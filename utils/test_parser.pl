#!/usr/bin/perl

use 5.010;
use strict;
use autodie;
use warnings FATAL => 'all';
use Test::More;

no warnings 'once';

use File::Find qw(find);
use List::Util qw(first);
use File::Temp qw(tempfile);
use File::Spec::Functions qw(catfile catdir updir);

my $libdir;

BEGIN {
    $libdir = catdir(updir(), 'lib');
}

use lib $libdir;
require Sidef;

my (undef, $tempfile) = tempfile();
my $scripts_dir = catdir(updir(), 'scripts');

my @scripts;
find {
    no_chdir => 1,
    wanted   => sub {
        if (/\.sf\z/) {
            push @scripts, $_;
        }
    },
} => $scripts_dir;

plan tests => (scalar(@scripts) * 3);

foreach my $sidef_script (@scripts) {

    my $content = do {
        open my $fh, '<:utf8', $sidef_script;
        local $/;
        <$fh>;
    };

    my $sidef = Sidef->new(name => $sidef_script);
    my $ast = $sidef->parse_code($content);

    is(ref($ast), 'HASH', $sidef_script);

    my $optimizer = Sidef::Optimizer->new();
    my $oast      = $optimizer->optimize($ast);

    my $code = $sidef->compile_ast($oast, 'Perl');

    ok($code ne '', $sidef_script);

    open my $fh, '>:utf8', $tempfile;
    print $fh $code;
    close $fh;

    ok(system($^X, '-Mlib=' . $libdir, '-MSidef', '-c', $tempfile) == 0, $sidef_script);

    $? && die "error for: $sidef_script";
}
