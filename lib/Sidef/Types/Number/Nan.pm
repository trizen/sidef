package Sidef::Types::Number::Nan {

    use 5.014;
    require Math::GMPq;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => sub { 1 },
      q{0+}   => sub { 'NaN' },
      q{""}   => sub { 'NaN' };

    state $NAN = do {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_si($r, "-0", "-0");
        bless \$r, __PACKAGE__;
    };

    sub new { $NAN }

    sub get_value { 'NaN' }

    sub is_nan {
        state $x = Sidef::Types::Bool::Bool->true;
    }

    sub is_inf {
        state $x = Sidef::Types::Bool::Bool->false;
    }

    sub is_ninf {
        state $x = Sidef::Types::Bool::Bool->false;
    }
}

1
