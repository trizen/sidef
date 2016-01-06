package Sidef::Types::Number::Nan {

    use 5.014;
    use Math::GMPq qw();

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
        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub is_inf {
        (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_ninf {
        (Sidef::Types::Bool::Bool::FALSE);
    }
}

1
