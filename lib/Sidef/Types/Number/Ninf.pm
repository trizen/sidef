package Sidef::Types::Number::Ninf {

    use 5.014;
    require Math::GMPq;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => sub { 1 },
      q{0+}   => sub { -'inf' },
      q{""}   => sub { '-Inf' };

    state $NINF = do {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_si($r, -1, 0);
        bless \$r, __PACKAGE__;
    };

    require Sidef::Types::Number::Number;

    state $ZERO = $Sidef::Types::Number::Number::ZERO;
    state $ONE  = $Sidef::Types::Number::Number::ONE;
    state $MONE = $Sidef::Types::Number::Number::MONE;
    state $NAN  = $Sidef::Types::Number::Number::NAN;

    if (not defined $ZERO or not defined $ONE or not defined $MONE or not defined $NAN) {
        die "Fatal error: can't load the Ninf class!";
    }

    sub new { $NINF }

    sub is_pos {
        state $x = Sidef::Types::Bool::Bool->false;
    }

    sub is_neg {
        state $x = Sidef::Types::Bool::Bool->true;
    }

    sub neg { state $x = Sidef::Types::Number::Inf->new }

    *abs = \&neg;
    *log = \&neg;

    sub min { $_[0] }
    sub max { $_[1] }

    sub inv { $ZERO }

    #
    ## sin(-inf) = [-1, 1]
    #
    sub sin { $NAN }

    #
    ## sinh(-inf) = -inf
    #
    sub sinh { $_[0] }

    #
    ## asin(-inf) = inf*i
    #
    sub asin { state $x = Sidef::Types::Number::Complex->new(0, '@inf@') }

    *sqrt = \&asin;

    #
    ## atan(-inf) = -pi/2
    #
    sub atan {
        state $x = Sidef::Types::Number::Number->pi->div(Sidef::Types::Number::Number->new(-2));
    }

    #
    ## tanh(-inf) = -1
    #
    sub tanh { $MONE }

    #
    ## exp(-inf) = 0
    #
    sub exp { $ZERO }

    #
    ## -inf.times {} does no-op
    #
    sub times { $_[1] }

    our $AUTOLOAD;
    sub AUTOLOAD { $_[0] }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '**'} = \&pow;
    }
}

1
