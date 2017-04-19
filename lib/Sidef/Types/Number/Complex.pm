package Sidef::Types::Number::Complex {

    # No reference is blessed on this class.

    use utf8;
    use 5.014;

    use parent qw(
      Sidef::Types::Number::Number
      );

    our ($PREC, $ROUND);

    BEGIN {
        *PREC  = \$Sidef::Types::Number::Number::PREC;
        *ROUND = \$Sidef::Types::Number::Number::ROUND;
    }

    sub new {
        my (undef, $real, $imag) = @_;

        if (ref($real) eq 'Sidef::Types::Number::Number') {
            $real = $$real;
        }
        else {
            $real =
              defined($real)
              ? Sidef::Types::Number::Number::_str2obj("$real")
              : Sidef::Types::Number::Number::ZERO;
        }

        if (defined($imag)) {

            if (ref($imag) eq 'Sidef::Types::Number::Number') {
                $imag = $$imag;
            }
            else {
                $imag = Sidef::Types::Number::Number::_str2obj("$imag");
            }

            my $c = Math::MPC::Rmpc_init2($PREC);
            my $sig = join(' ', ref($real), ref($imag));

            # GMPz
            if ($sig eq q(Math::GMPz Math::GMPz)) {
                Math::MPC::Rmpc_set_z_z($c, $real, $imag, $ROUND);
            }
            elsif ($sig eq q(Math::GMPz Math::GMPq)) {
                Math::MPC::Rmpc_set_z_q($c, $real, $imag, $ROUND);
            }
            elsif ($sig eq q(Math::GMPz Math::MPFR)) {
                Math::MPC::Rmpc_set_z_fr($c, $real, $imag, $ROUND);
            }

            # GMPq
            elsif ($sig eq q(Math::GMPq Math::GMPq)) {
                Math::MPC::Rmpc_set_q_q($c, $real, $imag, $ROUND);
            }
            elsif ($sig eq q(Math::GMPq Math::GMPz)) {
                Math::MPC::Rmpc_set_q_z($c, $real, $imag, $ROUND);
            }
            elsif ($sig eq q(Math::GMPq Math::MPFR)) {
                Math::MPC::Rmpc_set_q_fr($c, $real, $imag, $ROUND);
            }

            # MPFR
            elsif ($sig eq q(Math::MPFR Math::MPFR)) {
                Math::MPC::Rmpc_set_fr_fr($c, $real, $imag, $ROUND);
            }
            elsif ($sig eq q(Math::MPFR Math::GMPz)) {
                Math::MPC::Rmpc_set_fr_z($c, $real, $imag, $ROUND);
            }
            elsif ($sig eq q(Math::MPFR Math::GMPq)) {
                Math::MPC::Rmpc_set_fr_q($c, $real, $imag, $ROUND);
            }

            # Anything else
            else {
                $real = Sidef::Types::Number::Number::_any2mpc($real);
                $imag = Sidef::Types::Number::Number::_any2mpc($imag);
                Math::MPC::Rmpc_set($c, $imag, $ROUND);
                Math::MPC::Rmpc_mul_i($c, $c, 1, $ROUND);
                Math::MPC::Rmpc_add($c, $c, $real, $ROUND);
            }

            bless \$c, 'Sidef::Types::Number::Number';
        }
        else {
            my $c = Sidef::Types::Number::Number::_any2mpc($real);
            bless \$c, 'Sidef::Types::Number::Number';
        }
    }

    *call = \&new;
}

1;
