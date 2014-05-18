package Sidef::Types::Array::MultiArray {

    use 5.014;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, @args) = @_;

        foreach my $arg (@args) {
            Sidef->_is_array($arg) || return;
        }

        my @array = map {
            [map { $_->get_value } @{$_}]
        } @args;
        bless \@array, __PACKAGE__;
    }

    sub get_value {
        my ($self) = @_;
        [
         map {
             [
              map {
                  ref($_) && defined(eval { $_->can('get_value') }) ? $_->get_value : $_
                } @{$_}
             ]
           } @{$self}
        ];
    }

    sub each {
        my ($self, $code) = @_;
        $self->_is_code($code) || return;

        foreach my $i (0 .. $#{$self->[0]}) {
            $code->call(map { $_->[$i] } @{$self});
        }

        $self;
    }

    *iter    = \&each;
    *iterate = \&each;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(
            'MultiArr.new(' . join(
                ",\n\t     ",
                map {
                    '[' . join(
                        ", ",
                        map {
                            ref($_) && defined(eval { $_->can('dump') }) ? $_->dump : $_
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
