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

    require Sidef::Types::Number::Number;

    state $INF = do {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($r, 1, 0);
        bless \$r, __PACKAGE__;
    };

    sub new { $INF }

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

    #
    ## atan(inf) = pi/2
    #
    sub atan {
        state $pi_2 = Sidef::Types::Number::Number->pi->div(Sidef::Types::Number::Number->new(2));
    }

    #
    ## sqrt(inf) = inf
    #
    sub sqrt { $_[0] }

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

    our $AUTOLOAD;
    sub AUTOLOAD { $INF }
}

1
