package Sidef::Variable::Init {

    use 5.014;

    sub new {
        my (undef, @vars) = @_;
        bless {vars => \@vars}, __PACKAGE__;
    }

    sub set_value {
        my ($self, @args) = @_;

        foreach my $i (0 .. $#{$self->{vars}}) {

            my $var = $self->{vars}[$i];
            exists($var->{in_use}) || next;

            my $type = $var->{type};
            if ($type eq 'var') {
                my $new_var =
                  Sidef::Variable::Variable->new(
                                                 name => $var->{name},
                                                 type => $var->{type},
                                                 (exists($var->{class}) ? (class => $var->{class}) : ()),
                                                 value => exists($var->{multi})
                                                 ? Sidef::Types::Array::Array->new(@args[$i .. $#args])
                                                 : (exists($args[$i]) ? $args[$i] : $var->{value})
                                                );
                push @{$var->{stack}}, $new_var;
            }
            elsif ($type eq 'static' or $type eq 'const') {
                if (not exists $var->{inited}) {
                    $var->set_value(exists($args[$i]) ? $args[$i] : $var->{value});
                    $var->{inited} = 1;
                }
            }
            else {    # other types of variables
                $var->set_value($args[$i]);
            }
        }

        $args[0];
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '='} = \&set_value;
    }

};

1;
