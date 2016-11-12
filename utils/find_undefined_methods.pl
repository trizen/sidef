#!/usr/bin/perl

# Find undefined methods/symbols in a lib tree.

use utf8;
use 5.010;
use strict;
use autodie;
use warnings;

use lib qw(.);
use open IO => ':encoding(UTF-8)';

use File::Find qw(find);
use File::Basename qw(basename);
use File::Spec::Functions qw(curdir splitdir);

my %ignore;

#<<<
@ignore{
    'BEGIN',
    'import',
    '__ANON__',
    'AUTOLOAD',
    '(~~',
    'ISA',
    'a',
    'b',
    'PREC',
    'ROUND',
} = ();
#>>>

my $dir = shift() // die "usage: $0 sidef/lib\n";

my $name = basename($dir);
if ($name ne 'lib') {
    die "error: '$dir' is not a lib directory!";
}

chdir $dir;

find {
    no_chdir => 1,
    wanted   => sub {
        /\.pm\z/ && -f && check_file($_);
    },
} => curdir();

sub check_file {
    my ($file) = @_;

    my (undef, @parts) = splitdir($file);
    require join('/', @parts);

    $parts[-1] =~ s{\.pm\z}{};

    my $module = join('::', @parts);

    my $sym_table = do {
        no strict 'refs';
        \%{$module . '::'};
    };

    while (my ($key, $value) = each %{$sym_table}) {
        next if exists $ignore{$key};
        if (ref($value) eq '' and not defined(&$value)) {
            say "Undefined $module method: <<$key>>";
        }
    }
}
