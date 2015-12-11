package Sidef::Types::Array::MultiArray {

    use 5.014;

    use parent qw(
      Sidef::Object::Object
      );

    use overload
      q{""}   => \&dump,
      q{bool} => sub { scalar @{$_[0]} };

    sub new {
        my (undef, @args) = @_;
        my @array = map { [@{$_}] } @args;
        bless \@array, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        my ($self) = @_;
        [
         map {
             [map { index(ref($_), 'Sidef::') == 0 ? $_->get_value : $_ } @{$_}]
           } @{$self}
        ];
    }

    sub _max {
        my ($self) = @_;
        state $x = require List::Util;
        List::Util::max(map { $#{$_} } @{$self});
    }

    sub map {
        my ($self, $code) = @_;

        my $max = $self->_max;

        my @arr;
        foreach my $i (0 .. $max) {
            push @arr, scalar $code->run(map { $_->[$i % @{$_}] } @{$self});
        }

        Sidef::Types::Array::Array->new(@arr);
    }

    sub each {
        my ($self, $code) = @_;

        my $max = $self->_max;

        foreach my $i (0 .. $max) {
            if (defined(my $res = $code->_run_code(map { $_->[$i % @{$_}] } @{$self}))) {
                return $res;
            }
        }

        $self;
    }

    *iter    = \&each;
    *iterate = \&each;

    sub append {
        my ($self, $array) = @_;
        push @{$self}, [@{$array}];
    }

    *push = \&append;

    sub to_array {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::Array::Array->new(@{$_}) } @{$self});
    }

    *to_a = \&to_array;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(
            'MultiArr(' . join(
                ",\n\t    ",
                map {
                    '[' . join(
                        ", ",
                        map {
                            ref($_)
                              && defined(eval { $_->can('dump') })
                              ? $_->dump
                              : $_
                          } @{$_}
                      )
                      . ']'
                  } @{$self}
              )
              . ")"
        );
    }
};

1
