package Sidef::Types::Array::MultiArray {

    use 5.014;
    use List::Util qw();

    use parent qw(
      Sidef::Object::Object
      );

    use overload
      q{""}   => \&_dump,
      q{bool} => sub { scalar @{$_[0]} };

    sub new {
        my (undef, @args) = @_;
        my @array = map { [@{$_}] } @args;
        bless \@array, __PACKAGE__;
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

            foreach my $arr (@$obj) {
                my @row;
                foreach my $item (@$arr) {
                    push @row, (index(ref($item), 'Sidef::') == 0 ? $item->get_value : $item);
                }
                push @array, \@row;
            }

            $addr{$refaddr};
        };

        local *Sidef::Types::Array::MultiArray::get_value = $sub;
        $sub->($_[0]);
    }

    sub _max {
        my ($self) = @_;
        List::Util::max(map { $#{$_} } @{$self});
    }

    sub map {
        my ($self, $code) = @_;

        my $max = $self->_max;

        my @arr;
        foreach my $i (0 .. $max) {
            push @arr, scalar $code->run(map { $_->[$i % @{$_}] } @{$self});
        }

        Sidef::Types::Array::Array->new(\@arr);
    }

    sub each {
        my ($self, $code) = @_;

        my $max = $self->_max;

        foreach my $i (0 .. $max) {
            $code->run(map { $_->[$i % @{$_}] } @{$self});
        }

        $self;
    }

    sub append {
        my ($self, $array) = @_;
        push @{$self}, [@{$array}];
    }

    *push = \&append;

    sub to_array {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { Sidef::Types::Array::Array->new(@{$_}) } @{$self}]);
    }

    *to_a = \&to_array;

    sub _dump {

        my %addr;    # keeps track of dumped objects

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            exists($addr{$refaddr})
              and return $addr{$refaddr};

            $addr{$refaddr} = "MultiArr(#`($refaddr)...)";

            my $s;

            'MultiArr(' . join(
                ",\n\t ",
                map {
                    '['
                      . join(", ",
                             map { (ref($_) && ($s = UNIVERSAL::can($_, 'dump'))) ? $s->($_) : defined($_) ? $_ : 'nil' } @$_)
                      . ']'
                  } @$obj
              )
              . ")";
        };

        local *Sidef::Types::Array::MultiArray::dump = $sub;
        $sub->($_[0]);
    }

    sub dump {
        Sidef::Types::String::String->new($_[0]->_dump);
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '<<'} = \&append;
    }
};

1
