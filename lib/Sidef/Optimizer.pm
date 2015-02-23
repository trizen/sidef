use utf8;
use 5.014;
use strict;
use warnings;

# The directory where Sidef lives
use lib qw(..);

# Load the Sidef main module
use Sidef;

package Sidef::Optimizer {

    use Scalar::Util qw(refaddr);

    sub new {
        my (undef, %args) = @_;
        my %opts = (%args);
        bless \%opts, __PACKAGE__;
    }

    my %addr;

    sub optimize_expr {
        my ($self, $expr) = @_;

        my $obj = $expr->{self};

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $obj = $self->optimize($obj);
        }
        elsif ($ref eq "Sidef::Variable::Variable") {
            if ($obj->{type} eq 'var') {
                ## ok
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {
                if ($addr{refaddr($obj)}++) {
                    ## ok
                }
                else {
                    $obj->{value} = $self->optimize_expr({self => $obj->{value}});
                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::ClassInit') {
            if ($addr{refaddr($obj)}++) {
                ## ok
            }
            else {
                $obj->{__BLOCK__} = $self->optimize_expr({self => $obj->{__BLOCK__}});
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::Code') {
            my %code = $self->optimize($obj->{code});
            $obj->{code} = \%code;
        }

        # Indices
        if (exists $expr->{ind}) {
            $obj = {self => $obj, ind => []};
            foreach my $ind (@{$expr->{ind}}) {
                push @{$obj->{ind}}, map { $self->optimize_expr(ref($_) eq 'HASH' ? $_ : {self => $_->get_value}) } @{$ind};
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {
            if (ref($obj) eq 'HASH') {
                $obj->{call} = [];
            }
            else {
                $obj = {self => $obj, call => []};
            }
            foreach my $call (@{$expr->{call}}) {

                # Method call
                my $method = $call->{method};
                if (ref($method) eq 'HASH') {
                    $method = $self->optimize_expr($method);
                }
                push @{$obj->{call}}, {method => $method};

                # Method arguments
                if (exists $call->{arg}) {
                    foreach my $i (0 .. $#{$call->{arg}}) {
                        my $arg = $call->{arg}[$i];
                        if (ref $arg eq 'HASH') {
                            $arg = $self->optimize($arg);
                        }
                        push @{$obj->{call}[-1]{arg}}, $arg;
                    }
                }
            }
        }

        return $obj;
    }

    sub optimize {
        my ($self, $struct) = @_;

        my %opt_struct;
        my @classes = keys %{$struct};
        foreach my $class (@classes) {
            foreach my $i (0 .. $#{$struct->{$class}}) {
                my $expr = $struct->{$class}[$i];
                my $obj  = $self->optimize_expr($expr);
                push @{$opt_struct{$class}}, $obj;
            }
        }

        wantarray ? %opt_struct : $opt_struct{$classes[-1]}[-1];
    }

}

# Initialize a new parser
my $parser = Sidef::Parser->new();

# Parse some code and store the returned parse-tree
my $struct = $parser->parse_script(code => <<'SIDEF_CODE');

say((((("test")))));

SIDEF_CODE

use Data::Dump qw(pp);
my $opt        = Sidef::Optimizer->new;
my %opt_struct = $opt->optimize($struct);
pp \%opt_struct;

Sidef::Types::Block::Code->new(\%opt_struct)->run;
