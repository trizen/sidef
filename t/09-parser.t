#!perl

use 5.010;
use strict;
use autodie;
use warnings FATAL => 'all';
use Test::More;

no warnings 'once';

use File::Find qw(find);
use List::Util qw(first);
use File::Spec::Functions qw(catfile catdir);

use lib 'lib';
require Sidef;

my $scripts_dir = 'scripts';

my @scripts;
find {
    no_chdir => 1,
    wanted   => sub {
        if (/\.sf\z/) {
            push @scripts, $_;
        }
    },
} => $scripts_dir;

plan tests => (scalar(@scripts) * 2);

foreach my $sidef_script (@scripts) {

    my $content = do {
        open my $fh, '<:utf8', $sidef_script;
        local $/;
        <$fh>;
    };

    %Sidef::INCLUDED   = ();
    @Sidef::NAMESPACES = ();

    my $parser = Sidef::Parser->new(script_name => $sidef_script);
    my $struct = $parser->parse_script(code => \$content);

    is(ref($struct), 'HASH');

    my $deparser = Sidef::Deparse::Perl->new(namespaces => \@Sidef::NAMESPACES);
    my $code = $deparser->deparse($struct);

    ok($code ne '');
}
