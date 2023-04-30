package Sidef::Types::Array::Pair {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Array::Array
    );

    use overload q{""} => \&_dump;

    sub new {
        my (undef, $item1, $item2) = @_;
        bless [$item1, $item2], __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        my %addr;

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            exists($addr{$refaddr})
              && return $addr{$refaddr};

            my @array;
            $addr{$refaddr} = \@array;

            foreach my $i (0, 1) {
                my $item = $obj->[$i];

                if (index(ref($item), 'Sidef::') == 0) {
                    push @array, $item->get_value;
                }
                else {
                    push @array, $item;
                }
            }

            $addr{$refaddr};
        };

        no warnings 'redefine';
        local *Sidef::Types::Array::Pair::get_value = $sub;
        $sub->($_[0]);
    }

    sub first : lvalue {
        $_[0][0];
    }

    *key = \&first;

    sub second : lvalue {
        $_[0][1];
    }

    *value = \&second;

    sub swap {
        my ($self) = @_;
        ($self->[0], $self->[1]) = ($self->[1], $self->[0]);
        $self;
    }

    sub to_hash {
        my ($self) = @_;
        Sidef::Types::Hash::Hash->new(@$self);
    }

    *to_h = \&to_hash;

    sub to_array {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(ref($self) ? [@$self] : $self);
    }

    *to_a = \&to_array;

    sub _dump {

        my %addr;    # keeps track of dumped objects

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            exists($addr{$refaddr})
              and return $addr{$refaddr};

            $addr{$refaddr} = "Pair(#`($refaddr)...)";

            my $s;

            'Pair('
              . join(', ', map { (ref($_) && ($s = UNIVERSAL::can($_, 'dump'))) ? $s->($_) : ($_ // 'nil') } @$obj) . ')';
        };

        no warnings 'redefine';
        local *Sidef::Types::Array::Pair::dump = $sub;
        $sub->($_[0]);
    }

    sub dump {
        Sidef::Types::String::String->new($_[0]->_dump);
    }

    *to_s   = \&dump;
    *to_str = \&dump;
};

1
