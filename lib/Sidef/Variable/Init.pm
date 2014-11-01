package Sidef::Variable::Init {

    use 5.014;

    sub new {
        my (undef, @vars) = @_;
        bless {vars => \@vars}, __PACKAGE__;
    }

    sub set_value {
        my ($self, @args) = @_;

        while (my ($i, $var) = each @{$self->{vars}}) {

            exists($var->{in_use}) || next;

            my $type = $var->{type};
            if ($type eq 'var') {
                my $new_var =
                  Sidef::Variable::Variable->new(
                                                 name  => $var->{name},
                                                 type  => $var->{type},
                                                 value => exists($var->{multi})
                                                 ? Sidef::Types::Array::Array->new(@args[$i .. $#args])
                                                 : ($args[$i] // $var->{value})
                                                );
                push @{$var->{stack}}, $new_var;
            }
            elsif ($type eq 'static' or $type eq 'const') {
                if (not exists $var->{inited}) {
                    $var->set_value($args[$i] // $var->{value});
                    $var->{inited} = 1;
                }
            }
            else {    # actually, this will not happen
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
