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

            my $arg = shift @args;
            push @results, $arg;

            my $type = $var->{type};

            if ($type eq 'var') {
                my $new_var = Sidef::Variable::Variable->new($var->{name}, $var->{type}, $arg);
                push @{$var->{stack}}, $new_var;
            }
            elsif ($type eq 'static' or $type eq 'const') {
                if (not exists $var->{inited}) {
                    $var->set_value($arg);
                    $var->{inited} = 1;
                }
            }
            else {    # actually, this will not happen
                $var->set_value($arg);
            }
        }

        $results[0];
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '='} = \&set_value;
    }

};

1;
