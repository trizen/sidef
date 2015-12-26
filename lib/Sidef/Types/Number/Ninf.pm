package Sidef::Types::Number::Ninf {

    use 5.014;
    require Math::GMPq;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => sub { 1 },
      q{0+}   => sub { '-inf' },
      q{""}   => sub { '-Inf' };

    require Sidef::Types::Number::Number;

    state $NINF = do {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_si($r, -1, 0);
        bless \$r, __PACKAGE__;
    };

    sub new { $NINF }

    sub is_pos {
        state $x = Sidef::Types::Bool::Bool->false;
    }

    sub is_neg {
        state $x = Sidef::Types::Bool::Bool->true;
    }

    sub neg { state $x = Sidef::Types::Number::Inf->new }

    sub min { $_[0] }
    sub max { $_[1] }

    #
    ## atan(-inf) = -pi/2
    #
    sub atan {
        state $neg_pi_2 = Sidef::Types::Number::Number->pi->div(Sidef::Types::Number::Number->new(-2));
    }

    #
    ## sqrt(-inf) = -inf
    #
    sub sqrt {
        $_[0];
    }

    #
    ## -inf.times {} does no-op
    #
    sub times { $_[1] }

    our $AUTOLOAD;
    sub AUTOLOAD { $NINF }
}

1
