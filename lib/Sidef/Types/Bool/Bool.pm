package Sidef::Types::Bool::Bool {

    use overload
      q{bool} => \&get_value,
      q{0+}   => \&get_value,
      q{""}   => sub { ${$_[0]} ? 'true' : 'false' };

    use constant {
                  TRUE  => (bless \(my $t = 1), __PACKAGE__),
                  FALSE => (bless \(my $f = 0), __PACKAGE__),
                 };

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    sub new {
        $_[1] ? (TRUE) : (FALSE);
    }

    *call = \&new;

    sub true  { (TRUE) }
    sub false { (FALSE) }

    sub pick {
        CORE::rand(1) < 0.5 ? (TRUE) : (FALSE);
    }

    *rand = \&pick;

    sub get_value { ${$_[0]} }
    sub to_bool   { $_[0] }
    *to_b = \&to_bool;

    # Number
    sub to_num {
        ${$_[0]}
          ? Sidef::Types::Number::Number::ONE
          : Sidef::Types::Number::Number::ZERO;
    }

    *to_n = \&to_num;

    # Integer
    *to_i   = \&to_num;
    *to_int = \&to_num;

    # Rational
    *to_r   = \&to_num;
    *to_rat = \&to_num;

    # Float
    *to_f     = \&to_num;
    *to_float = \&to_num;

    # Complex
    sub to_complex {
        $_[0]->to_num->complex;
    }

    *to_c = \&to_complex;

    *{__PACKAGE__ . '::' . '|'} = sub {
        my ($self, $arg) = @_;
        $$self ? $self : $arg;
    };

    *{__PACKAGE__ . '::' . '&'} = sub {
        my ($self, $arg) = @_;
        $$self ? $arg : $self;
    };

    *{__PACKAGE__ . '::' . '^'} = sub {
        my ($self, $arg) = @_;
        ($$self xor $arg) ? (TRUE) : (FALSE);
    };

    sub is_true { $_[0] }

    sub not {
        ${$_[0]} ? (FALSE) : (TRUE);
    }

    *is_false = \&not;
    *flip     = \&not;
    *toggle   = \&not;
    *neg      = \&not;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self ? 'true' : 'false');
    }

};

1
