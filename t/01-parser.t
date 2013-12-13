#!perl

use 5.010;
use strict;
use autodie;
use warnings FATAL => 'all';
use Test::More;

use List::Util qw(first);
use File::Spec::Functions qw(catfile);

use lib 'lib';
require Sidef::Init;

opendir(my $dir_h, 'scripts');

my @scripts =
  map { catfile('scripts', $_) }
  grep { /\.sf\z/ && $_ ne 'include_class.sf' && $_ ne 'lingua_ro.sf' } readdir($dir_h);

plan tests => scalar(@scripts);

foreach my $sidef_script (@scripts) {

    my $content = do {
        open my $fh, '<:encoding(UTF-8)', $sidef_script;
        local $/;
        <$fh>;
    };

    my $parser = Sidef::Parser->new(script_name => '-T');
    my $struct = $parser->parse_script(code => $content);

    is(ref($struct), 'HASH');
}
