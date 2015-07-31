#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 March 2015
# Website: http://github.com/trizen

#
## Test the Sidef deparser for consistency.
#

## Algorithm:
# - parse the code
# - deparse the code as D1
# - deparse the deparsed code as D2
# - if D1 != D2: throw an error

use utf8;
use 5.014;
use strict;
use autodie;
use warnings;

no warnings 'once';
use lib qw(../lib);

use Sidef;

use File::Find qw(find);
use File::Basename qw(basename);

sub parse_deparse {
    my ($code, $name) = @_;

    local @Sidef::Exec::NAMESPACES = ();

    my $parser = Sidef::Parser->new(
                                    file_name   => $name,
                                    script_name => $name,
                                    strict      => 1,
                                   );

    my $struct = $parser->parse_script(code => \$code);

    my $deparser   = Sidef::Deparse::Sidef->new(namespaces => [@Sidef::Exec::NAMESPACES]);
    my @statements = $deparser->deparse_script($struct);
    my $deparsed   = $deparser->{before} . join($deparser->{between}, @statements) . $deparser->{after};

    return ($deparsed, \@statements);
}

my %ignore = (

    #'include_class.sf'                  => 1,
    'module_definition.sf'              => 1,
    'module_loading.sf'                 => 1,
    'module_order_and_redeclaration.sf' => 1,
    'Matrix.sm'                         => 1,
);

my $dir = shift() // die "usage: $0 [scripts dir]\n";

find {
      wanted => sub { /\.s[fm]\z/ && (-f $_) && test_file($_) },
      no_chdir => 1,
     } => $dir;

sub test_file {
    my ($file) = @_;

    my $basename = basename($file);
    return if exists $ignore{$basename};

    delete @INC{
        qw(
          Math/BigInt.pm
          Math/BigFloat.pm
          Math/BigRat.pm
          Sidef/Types/Number/Number.pm
          Sidef/Types/Number/NumberInt.pm
          Sidef/Types/Number/NumberFast.pm
          Sidef/Types/Number/NumberRat.pm
          )
    };

    require Sidef::Types::Number::Number;

    {
        local $| = 1;
        printf("** Processing: %s\r", $file);
    }

    open my $fh, '<:utf8', $file;
    my $content = do { local $/; <$fh> };
    close $fh;

    my ($deparse_1, $statements_1) = parse_deparse($content,   $file);
    my ($deparse_2, $statements_2) = parse_deparse($deparse_1, $file);

    if ($deparse_1 ne $deparse_2) {

        require Algorithm::Diff;
        my $diff = Algorithm::Diff::diff($statements_1, $statements_2);

        require Data::Dump;
        Data::Dump::pp($diff);
        die "[!] Error detected on file: $file\n";
    }
}
