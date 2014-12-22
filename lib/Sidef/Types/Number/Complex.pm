package Sidef::Types::Number::Complex {

    use utf8;
    use 5.014;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $x, $y) = @_;

        my $self = bless {};
        defined($x) || return $self;

        require Math::Complex;

        #
        ## Check X
        #
        if (ref($x) eq __PACKAGE__ or ref($x) eq 'Sidef::Types::Number::Number') {
            $x = $$x;
        }

        if (ref($x) eq 'Math::Complex') {
            return bless \$x, __PACKAGE__;
        }

        if (my $rx = ref($x)) {
            if ($rx eq 'Math::BigFloat' or $rx eq 'Math::BigInt') {
                ## ok
            }
            else { $x = 0 }
        }

        #
        ## Check Y
        #
        if (ref($y) eq __PACKAGE__ or ref($y) eq 'Sidef::Types::Number::Number') {
            $y = $$y;
        }

        if (my $ry = ref($y)) {
            if ($ry eq 'Math::BigFloat' or $ry eq 'Math::BigInt') {
                ## ok
            }
            else { $y = 0 }
        }

        #if (not defined(&Math::BigFloat::_cartesian)) {
        #    *Math::BigFloat::_cartesian = sub {
        #        Math::Complex->make($_[0], 0)->_cartesian;
        #    };
        #}

        #
        ## Inherit methods from Number/NumberFast
        #
        state $inherited = 0;

        if (not $inherited) {
            my $ref = ref(${Sidef::Types::Number::Number->new(0)});

            my $type =
                $ref eq 'Math::BigInt'   ? 'int'
              : $ref eq 'Math::BigFloat' ? 'float'
              : $ref eq 'Math::BigRat'   ? 'rat'
              :                            'fast';

            if ($type ne 'fast') {
                delete $INC{'Sidef/Types/Number/Number.pm'};
                require Sidef::Types::Number::NumberFast;
            }

            {
                no strict 'refs';
                while (my ($key, $value) = each %{'Sidef::Types::Number::Number::'}) {
                    my $func = \&{'Sidef::Types::Number::Number' . '::' . $key};
                    if (defined &{$func}) {
                        next if ($key eq 'new' or $key eq 'call');
                        *{__PACKAGE__ . '::' . $key} = sub {
                            $func->(
                                $_[0],
                                map {
                                    ref($_) eq __PACKAGE__ ? $_ : do { bless \($_->get_value) }
                                  } @_[1 .. $#_]
                            );
                        };
                    }
                }
            }

            if ($type ne 'fast') {
                delete $INC{'Sidef/Types/Number/Number.pm'};
            }

            if ($type eq 'float') {
                require Sidef::Types::Number::Number;
            }
            elsif ($type eq 'int') {
                require Sidef::Types::Number::NumberInt;
            }
            elsif ($type eq 'rat') {
                require Sidef::Types::Number::NumberRat;
            }

            $inherited = 1;
        }

        bless \Math::Complex->make($x, $y), __PACKAGE__;
    }

    *call = \&new;

    sub cartesian {
        my ($self) = @_;
        ${$self}->display_format('cartesian');
        $self;
    }

    sub polar {
        my ($self) = @_;
        ${$self}->display_format('polar');
        $self;
    }

    sub real {
        my ($self) = @_;
        require Math::Complex;
        Sidef::Types::Number::Number->new(Math::Complex::Re($$self));
    }

    *re = \&real;
    *Re = \&real;

    sub imaginary {
        my ($self) = @_;
        require Math::Complex;
        Sidef::Types::Number::Number->new(Math::Complex::Im($$self));
    }

    *im = \&imaginary;
    *Im = \&imaginary;

    sub get_constant {
        my ($self, $name) = @_;

        require Math::Complex;

        state %cache;
        state $table = {i => sub { __PACKAGE__->new(Math::Complex->i) },};

        $cache{lc($name)} //= $table->{lc($name)}->();
    }
};

1
