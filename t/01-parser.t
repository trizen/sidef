#!perl

use 5.010;
use strict;
use autodie;
use warnings FATAL => 'all';
use Test::More;

use List::Util qw(first);
use File::Spec::Functions qw(catfile);

use lib '../lib';
require Sidef::Parser;

my %ignored = map { $_ => 1 } qw(
  100_doors_3.sf
  dice_game_solver.sf
  stdin.sf
  );

opendir(my $dir_h, 'scripts');
my @scripts = map { catfile('scripts', $_) } grep { not exists $ignored{$_} } grep { /\.sf\z/ } readdir($dir_h);

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
