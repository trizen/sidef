
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Init {

    our $AUTOLOAD;

    sub new {
        my (undef, @vars) = @_;
        bless {vars => \@vars}, __PACKAGE__;
    }

    sub DESTROY {

    }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.+)$/);

        my @results;
        if (@{$self->{vars}} && $self->{vars}[0]->can($method)) {
            foreach my $var (@{$self->{vars}}) {
                push @results, $var->$method(shift @args);
            }
        }
        else {
            warn sprintf(qq{Can't locate object method "%s" for object "%s"\n}, $method, ref($self->{vars}[0]));
        }

        $results[0];
    }

};

1;
