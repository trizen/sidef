package Sidef::Types::Number::Inf {

    use 5.014;
    require Math::GMPq;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => sub { 1 },
      q{0+}   => sub { 'inf' },
      q{""}   => sub { 'Inf' };

    state $INF = do {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($r, 1, 0);
        bless \$r, __PACKAGE__;
    };

    require Sidef::Types::Number::Number;

    state $ZERO = $Sidef::Types::Number::Number::ZERO;
    state $ONE  = $Sidef::Types::Number::Number::ONE;
    state $MONE = $Sidef::Types::Number::Number::MONE;
    state $NAN  = $Sidef::Types::Number::Number::NAN;

    if (not defined $ZERO or not defined $ONE or not defined $MONE or not defined $NAN) {
        die "Fatal error: can't load the Inf class!";
    }

    sub new { $INF }

    sub add {
        my ($x, $y) = @_;
        ref($y) eq 'Sidef::Types::Number::Ninf' ? $NAN : $x;
    }

    sub sub {
        my ($x, $y) = @_;
        ref($y) eq __PACKAGE__ ? $NAN : $x;
    }

    sub is_pos {
        state $x = Sidef::Types::Bool::Bool->true;
    }

    sub is_neg {
        state $x = Sidef::Types::Bool::Bool->false;
    }

    sub neg {
        state $x = Sidef::Types::Number::Ninf->new;
    }

    sub min { $_[1] }
    sub max { $_[0] }

    sub inv { $Sidef::Types::Number::Number::ZERO }

    #
    ## sin(inf) = [-1, 1]
    #
    sub sin { $NAN }

    #
    ## sinh(inf) = inf
    #
    sub sinh { $_[0] }

    #
    ## asin(inf) = -inf*i
    #
    sub asin { state $x = Sidef::Types::Number::Complex->new(0, '-@inf@') }

    #
    ## atan(inf) = pi/2
    #
    sub atan {
        state $x = Sidef::Types::Number::Number->pi->div(Sidef::Types::Number::Number->new(2));
    }

    #
    ## tanh(inf) = 1
    #
    sub tanh { $ONE }

    #
    ## sqrt(inf) = inf
    #
    sub sqrt { $_[0] }

    #
    ## inf^(1/3) = inf
    #
    sub cbrt { $_[0] }

    sub times {
        my ($x, $block) = @_;

        my $i = 0;
        while (1) {
            if (defined(my $res = $block->_run_code(Sidef::Types::Number::Number::_new_uint(++$i)))) {
                return $res;
            }
        }

        $block;
    }

    sub pow {
        my ($x, $y) = @_;

        ref($y) eq __PACKAGE__ and return $x;
        ref($y) eq 'Sidef::Types::Number::Ninf' and return $ZERO;

        Sidef::Types::Number::Number::_valid($y);

        my $sign = Math::GMPq::Rmpq_sgn($$y);
        $sign < 0 ? $ZERO : $sign == 0 ? $NAN : $x;
    }

    our $AUTOLOAD;
    sub AUTOLOAD { $_[0] }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '**'} = \&pow;
        *{__PACKAGE__ . '::' . '+'}  = \&add;
        *{__PACKAGE__ . '::' . '-'}  = \&sub;
    }
}

1
