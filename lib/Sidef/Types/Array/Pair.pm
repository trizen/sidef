package Sidef::Types::Array::Pair {

    use 5.014;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $item1, $item2) = @_;
        bless [map { Sidef::Variable::Variable->new(name => '', type => 'var', value => $_) } ($item1, $item2)], __PACKAGE__;
    }

    sub get_value {
        my ($self) = @_;

        my @array;
        foreach my $i (0, 1) {
            my $item = $self->[$i]->get_value;

            if (ref $item and defined eval { $item->can('get_value') }) {
                push @array, $item->get_value;
            }
            else {
                push @array, $item;
            }
        }

        \@array;
    }

    {
        no strict 'refs';
        foreach my $pair ([first => 0], [second => 1]) {
            *{__PACKAGE__ . '::' . $pair->[0]} = sub {
                my ($self, $arg) = @_;
                if (@_ > 1) {
                    $self->[$pair->[1]] = $arg;
                }
                $self->[$pair->[1]];
            };
        }
    }

    sub swap {
        my ($self) = @_;
        ($self->[0], $self->[1]) = ($self->[1], $self->[0]);
        $self;
    }

    sub to_hash {
        my ($self) = @_;
        Sidef::Types::Hash::Hash->new(map { $_->get_value } @{$self});
    }

    *to_h   = \&to_hash;
    *toHash = \&to_hash;

    sub to_array {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { $_->get_value } @{$self});
    }

    *to_a    = \&to_array;
    *toArray = \&to_array;

    sub dump {
        my ($self) = @_;

        my ($i, $s) = $self->_get_indent_level;
        my $string = Sidef::Types::String::String->new("Pair.new(\n" . $s x $i);

        for my $i (0, 1) {
            my $item = $self->[$i]->get_value // 'nil';

            $$string .=
              (ref $item and defined eval { $item->can('dump') })
              ? $item->dump()
              : $item;

            $$string .= ", " if $i != 1;
        }

        $$string .= "\n" . $s x $i . ")";
        $string;
    }
};

1
