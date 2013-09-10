package Sidef::Variable::Init {

    use 5.014;
    use strict;
    use warnings;

    our $AUTOLOAD;

    sub new {
        my (undef, @vars) = @_;
        bless {vars => \@vars}, __PACKAGE__;
    }

    sub DESTROY {
        return;
    }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        my @results;
        if (@{$self->{vars}} && ($self->{vars}[0]->can($method) || $self->{vars}[0]->can('AUTOLOAD'))) {
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
