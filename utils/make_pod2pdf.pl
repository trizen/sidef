#!/usr/bin/perl

# Author: Trizen
# Date: 06 August 2026
# https://github.com/trizen

# POD to PDF converter for the Sidef programming language, with syntax highlighting, based on `pod2pdf.pl` script.

use 5.036;
use File::Find qw(find);
use File::Temp qw(tempfile);

use open IO => ':utf8', ':std';

my $ext = 'pod';
my @dirs = @ARGV ? @ARGV : ("bin/sidef", ".");

my $pod2pdf = 'pod2pdf.pl';
my $version = '26.07';

`which $pod2pdf` || die "pod2pdf.pl is not available";

@dirs || die "usage: $0 [files | dirs]\n";

my $ext_regex = join('|', map { quotemeta($_) } map { split(/\s*,\s*/, $_) } split(' ', $ext));
$ext_regex = qr/\.(?:$ext_regex)\z/o;

my $content = '';
my %seen;

find(
    {
     wanted => sub {
         if (-f $_ and $_ =~ /$ext_regex/) {
             return if $seen{$_}++;
             open my $fh, '<', $_ or return;
             while (defined(my $line = <$fh>)) {
                 $content .= $line;
             }
             close $fh;
             $content .= "\n";
         }
         elsif (-f $_ and $_ eq 'sidef') {
             return if $seen{$_}++;
             open my $fh, '<', $_ or return;
             while (defined(my $line = <$fh>)) {
                 chomp $line;
                 last if $line eq "__END__"
             }
            while (defined(my $line = <$fh>)) {
                $content .= $line;
            }
            close $fh;
            $content .= "\n";
         }
     },
    },
    @dirs
);

$content =~ s{=head1 NAME\s+}{=head1 }g;

my ($fh, $file) = tempfile();
binmode($fh, ':utf8');
print $fh $content;
close $fh;
system($pod2pdf, '--size', 'A3', '--mathjax', '--lang', 'ruby', '--title', "Sidef Programming Language - Documentation ($version)", $file, "sidef-documentation.pdf");
unlink($file);
