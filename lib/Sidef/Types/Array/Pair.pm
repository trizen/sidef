package Sidef::Types::Array::Pair {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $item1, $item2) = @_;
        bless [$item1 // Sidef::Types::Nil::Nil->new, $item2 // Sidef::Types::Nil::Nil->new], __PACKAGE__;
    }

    sub get_value {
        my ($self) = @_;

        my @array;
        foreach my $i (0, 1) {
            my $item = $self->[$i];

            if (ref $item and defined eval { $item->can('get_value') }) {
                push @array, $item->get_value;
            }
            else {
                push @array, $item;
            }
        }

        \@array;
    }

    sub first {
        my ($self, $arg) = @_;
        if (@_ > 1) {
            return $self->[0] = $arg;
        }
        $self->[0];
    }

    sub second {
        my ($self, $arg) = @_;
        if (@_ > 1) {
            return $self->[1] = $arg;
        }
        $self->[1];
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

    sub dump {
        my ($self) = @_;

        my ($i, $s) = $self->_get_indent_level;
        my $string = Sidef::Types::String::String->new("Pair.new(\n" . $s x $i);

        for my $i (0, 1) {
            my $item = defined($self->[$i]) ? $self->[$i] : 'nil';

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
