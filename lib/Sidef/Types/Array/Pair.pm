package Sidef::Types::Array::Pair {

    use 5.014;

    use parent qw(
      Sidef::Types::Array::Array
      );

    use overload q{""} => \&dump;

    sub new {
        my (undef, $item1, $item2) = @_;
        bless [$item1, $item2], __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        my ($self) = @_;

        my @array;
        foreach my $i (0, 1) {
            my $item = $self->[$i];

            if (index(ref($item), 'Sidef::') == 0) {
                push @array, $item->get_value;
            }
            else {
                push @array, $item;
            }
        }

        \@array;
    }

    sub first : lvalue {
        $_[0][0];
    }

    sub second : lvalue {
        $_[0][1];
    }

    sub swap {
        my ($self) = @_;
        ($self->[0], $self->[1]) = ($self->[1], $self->[0]);
        $self;
    }

    sub to_hash {
        my ($self) = @_;
        Sidef::Types::Hash::Hash->new(@{$self});
    }

    *to_h = \&to_hash;

    sub to_array {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(@{$self});
    }

    *to_a = \&to_array;

    sub dump {
        my ($self) = @_;

        Sidef::Types::String::String->new(
            "Pair(" . "\n" . join(
                ",\n",

                (' ' x ($Sidef::SPACES += $Sidef::SPACES_INCR)) . join(
                    ", ",
                    map {
                        my $val = $_;
                        eval { $val->can('dump') } ? ${$val->dump} : defined($val) ? $val : 'nil'
                      } @{$self}
                )
              )
              . "\n"
              . (' ' x ($Sidef::SPACES -= $Sidef::SPACES_INCR)) . ")"
        );
    }
};

1
