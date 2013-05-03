#!/usr/bin/perl

use strict;
use autodie;
use warnings;

use File::Basename qw(basename);
use File::Spec::Functions qw(catdir catfile updir);

my $struct_file = 'struct.pl';
my $dir = catdir(updir(), "lib", "Sidef", "Types");

my $pod = {};
if (-e $struct_file) {
    $pod = do $struct_file;
}

opendir(my $dir_h, $dir);

for my $d (readdir $dir_h) {

    next if chr ord $d eq '.';

    my $type_dir = catdir($dir, $d);
    -d $type_dir or next;

    opendir(my $d_h, $type_dir);

    my $basedir = basename($type_dir);
    my $ref = $pod->{$basedir} //= {};

    for my $f (readdir $d_h) {

        my $file_type = catfile($type_dir, $f);
        $f =~ /\.pm\z/ || next;

        open my $fh, '<', $file_type;

        my $indent_len = 0;
        my $last_line  = '';
        my $package    = "${basedir}::";

        while (<$fh>) {
            if (/^\h*package Sidef::Types::\w+::(\w+)/) {
                $package .= $1;
                $ref = $ref->{$1} //= {};
            }
            elsif (/^\h*use parent qw\((.*?)\);/s) {

                my @modules = split(' ', $1);

                foreach my $mod (@modules) {
                    my ($name) = $mod =~ /(\w+::\w+)\z/;
                    push @{$ref->{inherits}}, $name;
                }
            }
            elsif (   /^(\h*)sub (\w+)/
                   || /^(\h*)\*\{__PACKAGE__\h*.\h*'::'\h*.\h*'(.*?)'\}\h*=\h*sub\h*/) {
                next if $2 eq 'new';
                $indent_len = length($1);
                push @{$ref->{methods}}, {name => $2};
            }
            elsif (/^\h{$indent_len}\}/) {
                if ($last_line =~ /^\h*(?:return\h+|:\h+)?Sidef::Types::(\w+)::(\w+)/) {
                    $ref->{methods}[-1]{returns} = "$1::$2";
                }
                elsif ($last_line =~ /^\h*(?:return\h+)?(?:\b__PACKAGE__\b|\$self;)/) {
                    $ref->{methods}[-1]{returns} = $package;
                }
            }
            elsif (    ref $ref->{methods} eq 'ARRAY'
                   and @{$ref->{methods}}
                   and /\bmy\h*\(\$self(.*?)\)/s) {
                my $args = $1;
                my @args = grep { length > 0 } split(/\h*,?\h*\$/, $args);

                s{\@.*}{...} for @args;
                $ref->{methods}[-1]{args} = \@args;
            }
            else {
                $last_line = $_;
            }
        }

        $ref = $pod->{$basedir};
    }

}

print <<"POD";

=pod

POD

{
    local $\ = "\n\n";
    foreach my $type (sort keys %{$pod}) {

        print "=head1 $type";

        foreach my $m (sort keys %{$pod->{$type}}) {
            my $mod = $pod->{$type}{$m};

            print "=head2 $m";

            if (ref $mod->{inherits} eq 'ARRAY' and @{$mod->{inherits}}) {

                @{$mod->{inherits}} = do {
                    my %seen;
                    grep { !$seen{$_}++ } @{$mod->{inherits}};
                };

                print "=head3 Inherits from";
                print "=over 2";

                foreach my $in_mod (@{$mod->{inherits}}) {
                    print "=item * $in_mod";
                }

                print "=back";
            }

            if (ref $mod->{methods} eq 'ARRAY' and @{$mod->{methods}}) {

                my %method_group;
                foreach my $method (@{$mod->{methods}}) {
                    push @{$method_group{$method->{name}}}, $method;
                }

                foreach my $key (keys %method_group) {
                    if (@{$method_group{$key}} > 1) {
                        foreach my $met_key (keys %{$method_group{$key}[-1]}) {
                            if (not exists $method_group{$key}[0]{$met_key}) {
                                $method_group{$key}[0]{$met_key} = $method_group{$key}[-1]{$met_key};
                            }
                        }
                    }
                }

                @{$mod->{methods}} = do {
                    my %seen;
                    grep { !$seen{$_->{name}}++ } @{$mod->{methods}};
                };

                print "=head3 Methods";
                print "=over 2";

                foreach my $method (sort { $a->{name} cmp $b->{name} } @{$mod->{methods}}) {

                    printf "=item B<S<%-20s>> S<%25s> S<%25s>\n\n", $method->{name},
                      (ref $method->{args} eq 'ARRAY'
                        && @{$method->{args}} ? (" (" . join(', ', @{$method->{args}}) . ")") : "()"),
                      (exists $method->{returns} ? " B<$method->{returns}>" : "");

                    if (exists $method->{doc}) {
                        print "$method->{doc}";
                    }

                }
                print "=back";
            }
        }
    }
}

open my $struct_fh, '>', $struct_file;

use Data::Dump qw(pp);
print $struct_fh pp $pod;
close $struct_fh;
