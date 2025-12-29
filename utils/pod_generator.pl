#!/usr/bin/perl

use utf8;
use 5.016;
use strict;
use autodie;
use warnings;

use feature 'fc';

use lib qw(.);
use open IO => ':encoding(UTF-8)';

use File::Find            qw(find);
use List::Util            qw(first);
use File::Basename        qw(basename);
use File::Spec::Functions qw(curdir splitdir catfile);
use Pod::Simple::SimpleTree;

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

my %singletons = map { $_ => 1 } qw(
  Sidef::Sys::Sys
  Sidef::Sys::Sig
  Sidef::Math::Math
);

my %ignored_modules = map { $_ => 1 } qw(
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

    my %data = (
                __HEADER__ => '',
                __FOOTER__ => '',
               );

    my $parser = Pod::Simple::SimpleTree->new;
    $parser->preserve_whitespace(1);
    $parser->accept_targets('*');

    my $root = $parser->parse_file($file)->root;

    my $state          = 'header';    # header | methods | footer
    my $current_method = undef;

    for my $node (@$root) {
        next unless ref $node eq 'ARRAY';

        my ($tag, $attrs, @children) = @$node;

        # Detect METHODS section
        if ($tag eq 'head1') {
            my $title = _node_raw_text(\@children);

            if ($title =~ /^METHODS\b/i) {
                $state = 'methods';
                undef $current_method;
                next;
            }

            if ($state eq 'methods') {
                $state = 'footer';
            }
        }

        # HEADER
        if ($state eq 'header') {
            $data{__HEADER__} .= _serialize_node($node);
            next;
        }

        # METHODS
        if ($state eq 'methods') {

            if ($tag eq 'head2') {
                $current_method = _node_raw_text(\@children);
                $data{$current_method} = _serialize_node($node);
                next;
            }

            if (defined $current_method) {
                $data{$current_method} .= _serialize_node($node);
            }
            else {
                # Text immediately after "=head1 METHODS"
                $data{__FOOTER__} .= _serialize_node($node);
            }

            next;
        }

        # FOOTER
        if ($state eq 'footer') {
            $data{__FOOTER__} .= _serialize_node($node);
        }
    }

    return \%data;
}

sub _node_raw_text {
    my ($children) = @_;
    my $text = '';

    for my $c (@$children) {
        if (!ref $c) {
            $text .= $c;
        }
        elsif (ref $c eq 'ARRAY') {
            if (defined($c->[1]{'~orig_content'})) {
                $text .= $c->[1]{'~orig_content'};
            }
            else {
                $text .= $c->[0] . '<' . (_node_raw_text([@$c[2 .. $#$c]]) =~ s{([<>])}{$1 eq '<' ? 'E<lt>' : 'E<gt>'}ger) . '>';
            }
        }
    }

    return $text;
}

sub _serialize_node {
    my ($node) = @_;

    my ($tag, $attrs, @children) = @$node;
    my $out = '';

    # Reconstruct POD commands
    if ($tag =~ /^head(\d)$/) {
        $out .= "\n=head$1 " . _node_raw_text(\@children) . "\n\n";
        return $out;
    }

    if ($tag eq 'over-bullet') {
        $out .= "=over 4\n\n";
        foreach my $item (@children) {
            $out .= '=item ' . _node_raw_text([$item]) . "\n\n";
        }
        $out .= "=back\n";
        return $out;
    }

    if ($tag eq 'Para') {
        $out .= _node_raw_text(\@children) . "\n\n";
        return $out;
    }

    if ($tag eq 'Verbatim') {
        $out .= _node_raw_text(\@children) . "\n\n";
        return $out;
    }

    # Fallback: recurse
    for my $child (@children) {
        if (!ref $child) {
            $out .= $child;
        }
        else {
            $out .= _serialize_node($child);
        }
    }

    return $out;
}

sub parse_pod_file_old {
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

sub parse_pm_file {
    my ($file) = @_;

    my %data;
    open my $fh, '<', $file;

    while (defined(my $line = <$fh>)) {
        if ($line =~ /^\s*sub\s+(\w+)\s*\{/) {
            my $name = $1;
            next if ($name eq 'new');
            for (1 .. 2) {
                my $sig_line = scalar <$fh>;
                if ($sig_line =~ m{^\s*my\s*\((.*?)\)\s*=\s*\@_}) {
                    my $sig = $1;
                    $sig =~ s{\$}{}g;
                    $sig =~ s{\@}{*}g;
                    $sig =~ s{\%}{:}g;
                    my @params = split(/\s*,\s*/, $sig);
                    $data{$name} = \@params;
                }
            }
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

    my $signatures = parse_pm_file(join('/', @parts) . '.pm');

    while (my ($key, $value) = each %subs) {

        my @sorted  = sort_methods_by_length(map { [$_, $_] } @{$value->{aliases}});
        my $sig_key = first { exists($signatures->{$_}) } @sorted;

        $value->{name} = shift @sorted;
        @{$value->{aliases}} = @sorted;

        my $sub       = $value->{name};
        my $orig_name = $sub;
        my $is_method = lc($sub) ne uc($sub);

        #$sub =~ s{([<>])}{E<$esc{$1}>}g;

        #my $sig = "$parts[-1].$sub()";
        my $sig = "self.$sub";

        if (exists $singletons{$module}) {
            $sig = "$parts[-1].$sub";
        }

        if (defined($sig_key)) {
            my @params = @{$signatures->{$sig_key}};

            my $self = shift(@params);

            if (exists($singletons{$module}) or $self eq 'undef') {
                $self = $parts[-1];
            }

            $sig = $self . '.' . $orig_name;

            if (@params) {
                $sig .= '(' . join(', ', @params) . ')';
            }
        }

        my $doc = $is_method ? <<"__POD__" : <<"__POD2__";

\=head2 $orig_name

    $sig

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
            ) . "\n";
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

    #return if $pod_file ne 'Sidef/Object/Convert.pod';

    (-e $pod_file) && do {
        $pod_data = parse_pod_file($pod_file);
    };

    while (my ($key, $value) = each %subs) {

        my $alias;
        if (exists $value->{aliases}) {
            $alias = first { exists($pod_data->{$_}) } @{$value->{aliases}};
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
    my $footer = $pod_data->{__FOOTER__};

    #if (not defined($header) or $header =~ /^This class implements \.\.\.$/m) {
    if (not $header) {
        $header = <<"HEADER";
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
    }

    if (not $footer) {
        $footer = <<"FOOTER";

\=head1 AUTHOR

Daniel "Trizen" Șuteu

\=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Sidef itself.

\=cut
FOOTER
    }

    print {$fh} "=encoding utf8\n";

    # Print the header
    print {$fh} $header;

    print {$fh} "\n=head1 METHODS\n";

    # Print the methods
    foreach my $method (sort_methods_by_name(map { [$_, $_->{name}] } values %subs)) {
        print {$fh} $method->{doc};
    }

    print {$fh} $footer;
}
