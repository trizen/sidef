#!perl

use 5.010;
use strict;
use autodie;
use warnings FATAL => 'all';
use Test::More;

use File::Find qw(find);
use List::Util qw(first);
use File::Spec::Functions qw(catfile catdir);

use lib 'lib';
require Sidef::Init;

my $scripts_dir = 'scripts';
local $ENV{SIDEF_INC} = $scripts_dir;

my @scripts;
find {
    no_chdir => 1,
    wanted   => sub {
        if (/\.sf\z/) {
            push @scripts, $_;
        }
    },
} => $scripts_dir;

plan tests => scalar(@scripts);

foreach my $sidef_script (@scripts) {

    my $content = do {
        open my $fh, '<:utf8', $sidef_script;
        local $/;
        <$fh>;
    };

    my $parser = Sidef::Parser->new(script_name => '-T');
    my $struct = $parser->parse_script(code => $content);

    is(ref($struct), 'HASH');
}
