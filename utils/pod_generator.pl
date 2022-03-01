#!/usr/bin/perl

use utf8;
use 5.016;
use strict;
use autodie;
use warnings;

use feature 'fc';

use lib qw(.);
use open IO => ':encoding(UTF-8)';

use File::Find qw(find);
use List::Util qw(first);
use File::Basename qw(basename);
use File::Spec::Functions qw(curdir splitdir catfile);

my $dir = shift() // die "usage: $0 sidef/lib\n";

my %esc = (
           '>' => 'gt',
           '<' => 'lt',
          );

my %ignored_subs = map { $_ => 1 } qw<
  BEGIN
  ISA
  AUTOLOAD
  DESTROY
  >;

my %ignored_methods = (
                       'Sidef'                          => [qw(new)],
                       'Sidef::Sys::Sys'                => [qw(new)],
                       'Sidef::Math::Math'              => [qw(new)],
                       'Sidef::Time::Date'              => [qw(new)],
                       'Sidef::Types::Glob::DirHandle'  => [qw(new)],
                       'Sidef::Types::Glob::FileHandle' => [qw(new)],
                       'Sidef::Types::Glob::Backtick'   => [qw(new)],
                       'Sidef::Types::Glob::Stat'       => [qw(new)],
                       'Sidef::Types::Block::For'       => [qw(new)],
                       'Sidef::Types::Block::Try'       => [qw(new)],
                       'Sidef::Types::Regex::Match'     => [qw(new)],
                       'Sidef::Types::Regex::Regex'     => [qw(new)],
                      );

my %ignored_modules = map { $_ => 1 } qw (
  Sidef
  Sidef::Parser
  Sidef::Optimizer
  Sidef::Deparse::Perl
  Sidef::Deparse::Sidef
  );

my $name = basename($dir);
if ($name ne 'lib') {
    die "error: '$dir' is not a lib directory!";
}

chdir $dir;

find {
    no_chdir => 1,
    wanted   => sub {
        /\.pm\z/ && -f && process_file($_);
    },
} => curdir();

sub parse_pod_file {
    my ($file) = @_;

    my %data;
    open my $fh, '<', $file;

    my $meth = 0;
    while (defined(my $line = <$fh>)) {

        if ($meth) {
            my $sec = '';
            $sec .= $line;

            until ($line =~ /^=cut\b/ or eof($fh)) {
                $sec .= ($line = <$fh>);
            }

            if ($sec =~ /^=head2\h+(.*\S)/m) {
                $data{$1} = $sec;
            }
        }
        else {
            $data{__HEADER__} .= $line;
        }

        if ($meth == 0 && $line =~ /^=head1\h+METHODS/) {
            $meth = 1;
        }
    }
    close $fh;

    return \%data;
}

sub transform_method_names {
    map { [$_->[0], ($_->[1] =~ /[a-z]/) ? ('B_' . $_->[1]) : ('A_' . $_->[1])] } @_;
}

sub sort_methods_by_length {
#<<<
      map  { $_->[0] }
      sort {
             (length($a->[1] =~ tr/_//dr) <=> length($b->[1] =~ tr/_//dr))
          || (fc($a->[1]) cmp fc($b->[1]))
          || ($b->[1] cmp $a->[1])
      } transform_method_names(@_);
#>>>
}

sub sort_methods_by_name {
#<<<
      map  { $_->[0] }
      sort {
             (fc($a->[1] =~ tr/_//dr) cmp fc($b->[1] =~ tr/_//dr))
          || (fc($a->[1]) cmp fc($b->[1]))
          || ($a->[1] cmp $b->[1])
      } transform_method_names(@_);
#>>>
}

sub process_file {
    my ($file) = @_;

    my (undef, @parts) = splitdir($file);
    require join('/', @parts);

    $parts[-1] =~ s{\.pm\z}{};

    my $module = join('::', @parts);

    exists($ignored_modules{$module})
      && return;

    my $mod_methods = do {
        no strict 'refs';
        \%{$module . '::'};
    };

    my %subs;
    foreach my $sub (keys %{$mod_methods}) {

        next if $sub eq 'get_value';
        next if $sub =~ /^[(_]/;
        next if $sub =~ /^[[:upper:]]./;
        next if exists $ignored_subs{$sub};

        my $code;

        if (defined &{$module . '::' . $sub}) {
            $code = \&{$module . '::' . $sub};
        }
        else {
            next;
        }

        if (exists $ignored_methods{$module}) {
            if (first { $_ eq $sub } @{$ignored_methods{$module}}) {
                next;
            }
        }

        push @{$subs{$code}{aliases}}, $sub;
    }

    while (my ($key, $value) = each %subs) {

        my @sorted = sort_methods_by_length(map { [$_, $_] } @{$value->{aliases}});

        $value->{name} = shift @sorted;
        @{$value->{aliases}} = @sorted;

        my $sub       = $value->{name};
        my $orig_name = $sub;
        my $is_method = lc($sub) ne uc($sub);

        #$sub =~ s{([<>])}{E<$esc{$1}>}g;

        my $doc = $is_method ? <<"__POD__" : <<"__POD2__";

\=head2 $orig_name

    $parts[-1].$sub()

Returns the
__POD__

\=head2 $orig_name

    a $sub b

Returns the
__POD2__

        if (@{$value->{aliases}}) {
            $doc .= "\nAliases: " . join(
                ", ",
                map {
                    my $sub = $_;
                    $sub =~ s{([<>])}{E<$esc{$1}>}g;
                    "I<$sub>";
                } @{$value->{aliases}}
              )
              . "\n";
        }

        $doc .= "\n=cut\n";

        $subs{$key}{doc} //= $doc;
    }

    my @keys = keys %subs;
    if ($#keys == -1) {
        warn "[!] No method found for module: $module\n";
        return;
    }

    my $pod_file = catfile(@parts) . '.pod';

    say "** Writing: $pod_file";

    my $pod_data = {};

    (-e $pod_file) && do {
        $pod_data = parse_pod_file($pod_file);
    };

    while (my ($key, $value) = each %subs) {

        my $alias;
        if (exists $value->{aliases}) {
            $alias = first {
                exists($pod_data->{$_})
            }
            @{$value->{aliases}};
        }

        if ($alias // exists($pod_data->{$value->{name}})) {
            my $doc = $pod_data->{$alias // $value->{name}};
            if (not $doc =~ /^Returns? the$/m) {
                $subs{$key}{doc} = $doc;
            }
        }
    }

    open my $fh, '>', $pod_file;

    my $header = $pod_data->{__HEADER__};

    #if (not defined($header) or $header =~ /^This class implements \.\.\.$/m) {
    if (not defined($header)) {
        $header = <<"HEADER";

\=encoding utf8

\=head1 NAME

$module

\=head1 DESCRIPTION

This class implements ...

\=head1 SYNOPSIS

var obj = $parts[-1]\(...)

HEADER

        my @isa = @{exists($mod_methods->{ISA}) ? $mod_methods->{ISA} : []};

        if (@isa) {
            $header .= <<"HEADER";

\=head1 INHERITS

Inherits methods from:

HEADER

            $header .= join("\n", map { (" " x 7) . "* $_" } @isa);
            $header .= "\n\n";
        }

        $header .= <<"HEADER";
\=head1 METHODS
HEADER
    }

    # Print the header
    print {$fh} $header;

    # Print the methods
    foreach my $method (sort_methods_by_name(map { [$_, $_->{name}] } values %subs)) {
        print {$fh} $method->{doc};
    }
}
