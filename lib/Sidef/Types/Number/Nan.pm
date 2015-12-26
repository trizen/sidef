package Sidef::Types::Number::Nan {

    use 5.014;
    require Math::GMPq;

    #use parent qw(
    #  Sidef::Object::Object
    #  Sidef::Convert::Convert
    #  );

    sub new {
        state $nan = do {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_si($r, "-0", "-0");
            bless \$r, __PACKAGE__;
        };
    }

}

1
