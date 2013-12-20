package Sidef::Variable::Init {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        my (undef, @vars) = @_;
        bless {vars => \@vars}, __PACKAGE__;
    }

    sub set_value {
        my ($self, @args) = @_;

        my @results;
        foreach my $var (@{$self->{vars}}) {
            push @results, $args[0];
            my $new_var = Sidef::Variable::Variable->new($var->{name}, $var->{type}, shift @args);
            push @{$var->{stack}}, $new_var;
        }

        $results[0];
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '='} = \&set_value;
    }

};

1;
