package Sidef::Types::Number::Number {

    use utf8;
    use 5.016;

    use Math::MPFR qw();
    use Math::GMPq qw();
    use Math::GMPz qw();
    use Math::MPC  qw();

    use List::Util             qw();
    use Math::Prime::Util::GMP qw();

    our ($ROUND, $PREC);

    BEGIN {
        $ROUND = Math::MPFR::MPFR_RNDN();
        $PREC  = 192;
    }

    state $MONE = Math::GMPz::Rmpz_init_set_si(-1);
    state $ZERO = Math::GMPz::Rmpz_init_set_ui(0);
    state $ONE  = Math::GMPz::Rmpz_init_set_ui(1);
    state $TWO  = Math::GMPz::Rmpz_init_set_ui(2);
    state $TEN  = Math::GMPz::Rmpz_init_set_ui(10);

#<<<
    use constant {

          ONE  => bless(\$ONE),
          TWO  => bless(\$TWO),
          ZERO => bless(\$ZERO),
          MONE => bless(\$MONE),

          ULONG_MAX => Math::GMPq::_ulong_max(),
          LONG_MIN  => Math::GMPq::_long_min(),

          HAS_PRIME_UTIL => eval { require Math::Prime::Util; 1 } // 0,

          # Check if we have a recent enough version of Math::Prime::Util
          HAS_NEW_PRIME_UTIL => eval { require Math::Prime::Util; defined(&Math::Prime::Util::is_perfect_power); } // 0,
    };
#>>>

    our $MPZ = bless \Math::GMPz::Rmpz_init();

    state $round_z = Math::MPFR::MPFR_RNDZ();

    my %DIGITS_36;
    @DIGITS_36{0 .. 9, 'a' .. 'z'} = (0 .. 35);

    my %DIGITS_62;
    @DIGITS_62{0 .. 9, 'A' .. 'Z', 'a' .. 'z'} = (0 .. 61);

    my %FROM_DIGITS_36;
    @FROM_DIGITS_36{0 .. 35} = (0 .. 9, 'a' .. 'z');

    my %FROM_DIGITS_62;
    @FROM_DIGITS_62{0 .. 61} = (0 .. 9, 'A' .. 'Z', 'a' .. 'z');

    state $LUCAS_PQ_LIMIT = CORE::int(CORE::sqrt(ULONG_MAX >> 2));

    use parent qw(Sidef::Object::Object);

    use overload
      q{bool} => sub { (@_) = (${$_[0]}); goto &__boolify__ },
      q{0+}   => sub { (@_) = (${$_[0]}); goto &__numify__ },
      q{""}   => sub { (@_) = (${$_[0]}); goto &__stringify__ };

    use Sidef::Types::Bool::Bool;

    my @cache = (ZERO, ONE);

    sub new {
        my (undef, $num, $base) = @_;

        if (ref($_[0]) eq __PACKAGE__) {
            return $_[0];
        }

        if (ref($base)) {
            if (ref($base) eq __PACKAGE__) {
                $base = _any2ui($$base) // 0;
            }
            else {
                $base = CORE::int($base);
            }
        }

        my $ref = ref($num);

        if (   $ref eq 'Sidef::Types::Number::Mod'
            or $ref eq 'Sidef::Types::Number::Gauss'
            or $ref eq 'Sidef::Types::Number::Quadratic'
            or $ref eq 'Sidef::Types::Number::Quaternion') {
            $num = $num->to_n;
        }
        elsif ($ref eq 'Sidef::Types::Bool::Bool') {
            $num = $num->get_value;
        }

        # Number with base
        if (defined($base)) {

            my $int_base = CORE::int($base);

            if ($int_base < 2 or $int_base > 62) {
                die "[ERROR] Number(): base must be between 2 and 62, got $base";
            }

            $num = defined($num) ? "$num" : '0';

            # Remove the leading plus sign (if any)
            $num =~ s/^\+// if substr($num, 0, 1) eq '+';

            if (index($num, '/') != -1) {
                my $r = Math::GMPq::Rmpq_init();
                eval { Math::GMPq::Rmpq_set_str($r, $num, $int_base); 1 } // goto &nan;
                if (Math::GMPq::Rmpq_get_str($r, 10) !~ m{^\s*[-+]?[0-9]+\s*(?:/\s*[-+]?[1-9]+[0-9]*\s*)?\z}) {
                    goto &nan;
                }
                Math::GMPq::Rmpq_canonicalize($r);
                return bless \$r;
            }
            elsif (substr($num, 0, 1) eq '(' and substr($num, -1) eq ')') {
                my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
                eval { Math::MPC::Rmpc_set_str($r, $num, $int_base, $ROUND); 1 } // goto &nan;
                return bless \$r;
            }
            elsif (index($num, '.') != -1) {
                my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
                if (Math::MPFR::Rmpfr_set_str($r, $num, $int_base, $ROUND) < 0) {
                    goto &nan;
                }
                return bless \$r;
            }
            else {
                return bless \(eval { Math::GMPz::Rmpz_init_set_str($num, $int_base) } // goto &nan);
            }
        }

        # Special string values
        if (!$ref) {
            return bless \_str2obj($num);
        }

        # Already a __PACKAGE__ object
        if ($ref eq __PACKAGE__) {
            return $num;
        }

        # GMPz
        if ($ref eq 'Math::GMPz') {
            return bless \Math::GMPz::Rmpz_init_set($num);
        }

        # MPFR
        if ($ref eq 'Math::MPFR') {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set($r, $num, $ROUND);
            return bless \$r;
        }

        # MPC
        if ($ref eq 'Math::MPC') {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set($r, $num, $ROUND);
            return bless \$r;
        }

        # GMPq
        if ($ref eq 'Math::GMPq') {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set($r, $num);
            return bless \$r;
        }

        bless \_str2obj("$num");
    }

    *call = \&new;

    sub run { $_[1] }

    sub _valid {
        (
         ref($$_) eq __PACKAGE__
           or do {
             my $sub = overload::Method($$_, '0+');

             my $tmp = (
                 defined($sub)
                 ? __PACKAGE__->new($sub->($$_))
                 : do {
                     my (undef, undef, undef, $caller) = caller(1);
                     die "[ERROR] Value <<$$_>> cannot be implicitly converted to a number, inside <<$caller>>!\n";
                 }
             );

             if (ref($tmp) ne __PACKAGE__) {    # this should not happen
                 my (undef, undef, undef, $caller) = caller(1);
                 die "[ERROR] Cannot convert <<$$_>> to a number, inside <<$caller>>! (is method \"to_n\" well-defined?)\n";
             }

             $$_ = $tmp;
         }
        ) for @_;
    }

    sub _set_int {
        if (ref($_[0]) eq 'Math::GMPz') {
            return bless \Math::GMPz::Rmpz_init_set($_[0]);
        }
        ($_[0] < ULONG_MAX and $_[0] > LONG_MIN)
          ? (
            ($_[0] >= 0)
            ? (
                 ($_[0] < 8192)
               ? ($cache[$_[0]] //= bless \Math::GMPz::Rmpz_init_set_ui($_[0]))
               : do {
                   if (Math::GMPz::get_refcnt($$MPZ) > 1) {
                       $MPZ = bless \Math::GMPz::Rmpz_init_set_ui($_[0]);
                   }
                   else {
                       Math::GMPz::Rmpz_set_ui($$MPZ, $_[0]);
                   }
                   $MPZ;
               }
              )
            : (
               ($_[0] == -1) ? MONE : do {

                   if (Math::GMPz::get_refcnt($$MPZ) > 1) {
                       $MPZ = bless \Math::GMPz::Rmpz_init_set_si($_[0]);
                   }
                   else {
                       Math::GMPz::Rmpz_set_si($$MPZ, $_[0]);
                   }

                   $MPZ;
               }
              )
            )
          : bless \Math::GMPz::Rmpz_init_set_str("$_[0]", 10);
    }

    sub _dump {
        my $x = ${$_[0]};

        my $ref = ref($x);

        if ($ref eq 'Math::GMPz') {
            ('int', Math::GMPz::Rmpz_get_str($x, 10));
        }
        elsif ($ref eq 'Math::GMPq') {
            ('rat', Math::GMPq::Rmpq_get_str($x, 10));
        }
        elsif ($ref eq 'Math::MPFR') {
            ('float', Math::MPFR::Rmpfr_get_str($x, 10, 0, $ROUND));
        }
        elsif ($ref eq 'Math::MPC') {
            ('complex', Math::MPC::Rmpc_get_str(10, 0, $x, $ROUND));
        }
        else {
            die "[ERROR] This shouldn't happen: <<$x>> as <<$ref>>";
        }
    }

    sub _set_str {
        my ($type, $str) = @_;

        if ($type eq 'int') {
            bless \Math::GMPz::Rmpz_init_set_str("$str", 10);
        }
        elsif ($type eq 'rat') {
            Math::GMPq::Rmpq_set_str((my $r = Math::GMPq::Rmpq_init()), "$str", 10);
            bless \$r;
        }
        elsif ($type eq 'float') {
            Math::MPFR::Rmpfr_set_str((my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC))), "$str", 10, $ROUND);
            bless \$r;
        }
        elsif ($type eq 'complex') {
            Math::MPC::Rmpc_set_str((my $r = Math::MPC::Rmpc_init2(CORE::int($PREC))), "$str", 10, $ROUND);
            bless \$r;
        }
        else {
            die "[ERROR] Number._set_str(): invalid type <<$type>> with content <<$str>>";
        }
    }

    sub _str2frac {
        my $str = lc($_[0]);

        my $sign = substr($str, 0, 1);
        if ($sign eq '-') {
            substr($str, 0, 1, '');
            $sign = '-';
        }
        else {
            substr($str, 0, 1, '') if ($sign eq '+');
            $sign = '';
        }

        if ((my $i = index($str, 'e')) != -1) {

            my $exp = substr($str, $i + 1);

            my ($before, $after) = split(/\./, substr($str, 0, $i));

            if (!defined($after)) {    # return faster for numbers like "13e2"
                if ($exp >= 0) {
                    return ("$sign$before" . ('0' x $exp));
                }
                else {
                    $after = '';
                }
            }

            my $numerator = "$sign$before$after";

            if ($exp < 0) {
                return ("$numerator/1" . ('0' x (CORE::abs($exp) + CORE::length($after))));
            }

            my $diff = ($exp - CORE::length($after));

            if ($diff >= 0) {
                return ($numerator . ('0' x $diff));
            }

            my $s = "$before$after";
            substr($s, $exp + CORE::length($before), 0, '.');
            return __SUB__->("$sign$s");
        }

        if ((my $i = index($str, '.')) != -1) {
            my ($before, $after) = (substr($str, 0, $i), substr($str, $i + 1));

            if ($after == 0) {
                return "$sign$before";
            }

            return ("$sign$before$after/1" . ('0' x CORE::length($after)));
        }

        return "$sign$str";
    }

    #
    ## Misc internal functions
    #

    # Convert a given pair (real, imag) into an MPC object
    sub _reals2mpc {
        my ($re, $im) = @_;

        my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));

        $re = _str2obj($re);
        $im = _str2obj($im);

        my $sig = join(' ', ref($re), ref($im));

        if ($sig eq q{Math::MPFR Math::MPFR}) {
            Math::MPC::Rmpc_set_fr_fr($r, $re, $im, $ROUND);
        }
        elsif ($sig eq q{Math::GMPz Math::GMPz}) {
            Math::MPC::Rmpc_set_z_z($r, $re, $im, $ROUND);
        }
        elsif ($sig eq q{Math::GMPz Math::MPFR}) {
            Math::MPC::Rmpc_set_z_fr($r, $re, $im, $ROUND);
        }
        elsif ($sig eq q{Math::MPFR Math::GMPz}) {
            Math::MPC::Rmpc_set_fr_z($r, $re, $im, $ROUND);
        }
        elsif ($sig eq q{Math::GMPz Math::GMPq}) {
            Math::MPC::Rmpc_set_z_q($r, $re, $im, $ROUND);
        }
        elsif ($sig eq q{Math::GMPq Math::GMPz}) {
            Math::MPC::Rmpc_set_q_z($r, $re, $im, $ROUND);
        }
        elsif ($sig eq q{Math::GMPq Math::GMPq}) {
            Math::MPC::Rmpc_set_q_q($r, $re, $im, $ROUND);
        }
        elsif ($sig eq q{Math::GMPq Math::MPFR}) {
            Math::MPC::Rmpc_set_q_fr($r, $re, $im, $ROUND);
        }
        elsif ($sig eq q{Math::MPFR Math::GMPq}) {
            Math::MPC::Rmpc_set_fr_q($r, $re, $im, $ROUND);
        }
        elsif (ref($re) eq 'Math::MPC') {
            Math::MPC::Rmpc_set($r, _any2mpc($im), $ROUND);
            Math::MPC::Rmpc_mul_i($r, $r, 1, $ROUND);
            Math::MPC::Rmpc_add($r, $r, $re, $ROUND);
        }
        elsif (ref($im) eq 'Math::MPC') {
            Math::MPC::Rmpc_set($r, $im, $ROUND);
            Math::MPC::Rmpc_mul_i($r, $r, 1, $ROUND);
            Math::MPC::Rmpc_add($r, $r, _any2mpc($re), $ROUND);
        }
        else {    # this should never happen
            $re = _any2mpfr($re);
            $im = _any2mpfr($im);
            Math::MPC::Rmpc_set_fr_fr($r, $re, $im, $ROUND);
        }

        return $r;
    }

    # Converts a string into an mpq object
    sub _str2obj {
        my ($s) = @_;

        $s || return $ZERO;

        $s = lc($s);

        if ($s eq 'inf' or $s eq '+inf') {
            goto &_inf;
        }
        elsif ($s eq '-inf') {
            goto &_ninf;
        }
        elsif ($s eq 'nan') {
            goto &_nan;
        }

        # Remove underscores
        $s =~ tr/_//d;

        # Performance improvement for Perl integers
        if (CORE::int($s) eq $s and $s > LONG_MIN and $s < ULONG_MAX) {
            return (
                    $s < 0
                    ? Math::GMPz::Rmpz_init_set_si($s)
                    : Math::GMPz::Rmpz_init_set_ui($s)
                   );
        }

        # Decimal expansion (parsed as a rational value)
        if ($s =~ tr/e.// and $s =~ /^([+-]?+(?=\.?[0-9])[0-9_]*+(?:\.[0-9_]++)?(?:[Ee](?:[+-]?+[0-9_]+))?)\z/) {
            my $frac = _str2frac($1);

            if (index($frac, '/') != -1) {
                my $q = Math::GMPq::Rmpq_init();
                Math::GMPq::Rmpq_set_str($q, $frac, 10);
                Math::GMPq::Rmpq_canonicalize($q);
                return $q;
            }
            else {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_set_str($z, $frac, 10);
                return $z;
            }
        }

        # Complex number of form: "(3 4)"
        if (substr($s, 0, 1) eq '(' and substr($s, -1) eq ')') {
            my ($re, $im) = split(' ', substr($s, 1, -1));

            if (defined($re) and defined($im)) {
                return _reals2mpc($re, $im);
            }
        }

        # Complex number of form: "3+4i"
        if (substr($s, -1) eq 'i') {

            if ($s eq 'i' or $s eq '+i') {
                my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
                Math::MPC::Rmpc_set_ui_ui($r, 0, 1, $ROUND);
                return $r;
            }
            elsif ($s eq '-i') {
                my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
                Math::MPC::Rmpc_set_si_si($r, 0, -1, $ROUND);
                return $r;
            }

            my ($re, $im);

            state $numeric_re  = qr/[+-]?+(?=\.?[0-9])[0-9]*+(?:\.[0-9]++)?(?:[Ee](?:[+-]?+[0-9]+))?/;
            state $unsigned_re = qr/(?=\.?[0-9])[0-9]*+(?:\.[0-9]++)?(?:[Ee](?:[+-]?+[0-9]+))?/;

            if ($s =~ /^($numeric_re)\s*([-+])\s*($unsigned_re)i\z/o) {
                ($re, $im) = ($1, $3);
                $im = "-$im" if $2 eq '-';
            }
            elsif ($s =~ /^($numeric_re)i\z/o) {
                ($re, $im) = (0, $1);
            }
            elsif ($s =~ /^($numeric_re)\s*([-+])\s*i\z/o) {
                ($re, $im) = ($1, 1);
                $im = -1 if $2 eq '-';
            }

            if (defined($re) and defined($im)) {
                return _reals2mpc($re, $im);
            }
        }

#<<<
        # Decimal expansion (parsed as a floating-point value)
        #~ if ($s =~ tr/e.//) {
            #~ my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            #~ if (Math::MPFR::Rmpfr_set_str($r, $s, 10, $ROUND)) {
                #~ Math::MPFR::Rmpfr_set_nan($r);
            #~ }
            #~ return $r;
        #~ }
#>>>

        # Remove a leading plus sign
        $s =~ s/^\+// if substr($s, 0, 1) eq '+';

        # Fractional value
        if (index($s, '/') != -1 and $s =~ m{^\s*[-+]?[0-9]+\s*/\s*[-+]?[1-9]+[0-9]*\s*\z}) {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_str($r, $s, 10);
            Math::GMPq::Rmpq_canonicalize($r);
            return $r;
        }

        eval { Math::GMPz::Rmpz_init_set_str("$s", 10) } // goto &_nan;
    }

    #
    ## MPZ
    #
    sub _mpz2mpq {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_z($r, $_[0]);
        $r;
    }

    sub _mpz2mpfr {
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_set_z($r, $_[0], $ROUND);
        $r;
    }

    sub _mpz2mpc {
        my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
        Math::MPC::Rmpc_set_z($r, $_[0], $ROUND);
        $r;
    }

    #
    ## MPQ
    #
    sub _mpq2mpz {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $_[0]);
        $z;
    }

    sub _mpq2mpfr {
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_set_q($r, $_[0], $ROUND);
        $r;
    }

    sub _mpq2mpc {
        my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
        Math::MPC::Rmpc_set_q($r, $_[0], $ROUND);
        $r;
    }

    #
    ## MPFR
    #
    sub _mpfr2mpc {
        my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
        Math::MPC::Rmpc_set_fr($r, $_[0], $ROUND);
        $r;
    }

    #
    ## Any to MPC (complex)
    #
    sub _any2mpc {
        my ($x) = @_;

        ref($x) eq 'Math::MPC'  && return $x;
        ref($x) eq 'Math::GMPz' && goto &_mpz2mpc;
        ref($x) eq 'Math::GMPq' && goto &_mpq2mpc;

        goto &_mpfr2mpc;
    }

    #
    ## Any to MPFR (floating-point)
    #
    sub _any2mpfr {
        my ($x) = @_;

        ref($x) eq 'Math::MPFR' && return $x;
        ref($x) eq 'Math::GMPz' && goto &_mpz2mpfr;
        ref($x) eq 'Math::GMPq' && goto &_mpq2mpfr;

        my $fr = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPC::RMPC_IM($fr, $x);

        if (Math::MPFR::Rmpfr_zero_p($fr)) {
            Math::MPC::RMPC_RE($fr, $x);
        }
        else {
            Math::MPFR::Rmpfr_set_nan($fr);
        }

        $fr;
    }

    #
    ## Any to MPFR or MPC, in this order
    #
    sub _any2mpfr_mpc {
        my ($x) = @_;

        if (   ref($x) eq 'Math::MPFR'
            or ref($x) eq 'Math::MPC') {
            return $x;
        }

        ref($x) eq 'Math::GMPz' && goto &_mpz2mpfr;
        ref($x) eq 'Math::GMPq' && goto &_mpq2mpfr;
        goto &_any2mpfr;    # this should not happen
    }

    #
    ## Any to GMPz (integer)
    #
    sub _any2mpz {
        my ($x) = @_;

        ref($x) eq 'Math::GMPz' && return $x;
        ref($x) eq 'Math::GMPq' && goto &_mpq2mpz;

        if (ref($x) eq 'Math::MPFR') {
            if (Math::MPFR::Rmpfr_number_p($x)) {
                my $z = Math::GMPz::Rmpz_init();
                Math::MPFR::Rmpfr_get_z($z, $x, $round_z);
                return $z;
            }
            return;
        }

        (@_) = _any2mpfr($x);
        goto &_any2mpz;
    }

    #
    ## Any to GMPq (rational)
    #
    sub _any2mpq {
        my ($x) = @_;

        ref($x) eq 'Math::GMPq' && return $x;
        ref($x) eq 'Math::GMPz' && goto &_mpz2mpq;

        if (ref($x) eq 'Math::MPFR') {
            if (Math::MPFR::Rmpfr_number_p($x)) {
                my $q = Math::GMPq::Rmpq_init();
                Math::MPFR::Rmpfr_get_q($q, $x);
                return $q;
            }
            return;
        }

        (@_) = _any2mpfr($x);
        goto &_any2mpq;
    }

    #
    ## Anything to an unsigned native integer
    #
    sub _any2ui {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_GMPz: {

            if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
                return Math::GMPz::Rmpz_get_ui($x);
            }

            state $t = Math::GMPz::Rmpz_init_set_str_nobless(join('', ~0), 10);

            if (Math::GMPz::Rmpz_sgn($x) >= 0 and Math::GMPz::Rmpz_cmp($x, $t) <= 0) {
                return Math::GMPz::Rmpz_get_str($x, 10);
            }

            return;
        }

      Math_GMPq: {

            if (Math::GMPq::Rmpq_integer_p($x)) {
                @_ = ($x = _mpq2mpz($x));
                goto Math_GMPz;
            }

            my $d = CORE::int(Math::GMPq::Rmpq_get_d($x));
            return (($d < 0 or $d > ULONG_MAX) ? undef : $d);
        }

      Math_MPFR: {

            if (Math::MPFR::Rmpfr_integer_p($x) and Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
                return Math::MPFR::Rmpfr_get_ui($x, $ROUND);
            }

            if (Math::MPFR::Rmpfr_number_p($x)) {
                my $d = CORE::int(Math::MPFR::Rmpfr_get_d($x, $ROUND));
                return (($d < 0 or $d > ULONG_MAX) ? undef : $d);
            }

            return;
        }

      Math_MPC: {
            @_ = ($x = _any2mpfr($x));
            goto Math_MPFR;
        }
    }

    #
    ## Anything to a signed native integer
    #
    sub _any2si {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_GMPz: {

            if (Math::GMPz::Rmpz_fits_slong_p($x)) {
                return Math::GMPz::Rmpz_get_si($x);
            }

            if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
                return Math::GMPz::Rmpz_get_ui($x);
            }

            return;
        }

      Math_GMPq: {

            if (Math::GMPq::Rmpq_integer_p($x)) {
                @_ = ($x = _mpq2mpz($x));
                goto Math_GMPz;
            }

            my $d = CORE::int(Math::GMPq::Rmpq_get_d($x));
            return (($d < LONG_MIN or $d > ULONG_MAX) ? undef : $d);
        }

      Math_MPFR: {

            if (Math::MPFR::Rmpfr_integer_p($x)) {
                if (Math::MPFR::Rmpfr_fits_slong_p($x, $ROUND)) {
                    return Math::MPFR::Rmpfr_get_si($x, $ROUND);
                }

                if (Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
                    return Math::MPFR::Rmpfr_get_ui($x, $ROUND);
                }
            }

            if (Math::MPFR::Rmpfr_number_p($x)) {
                my $d = CORE::int(Math::MPFR::Rmpfr_get_d($x, $ROUND));
                return (($d < LONG_MIN or $d > ULONG_MAX) ? undef : $d);
            }

            return;
        }

      Math_MPC: {
            @_ = ($x = _any2mpfr($x));
            goto Math_MPFR;
        }
    }

    # Big to (signed) integer-string
    sub _big2istr {
        my ($x) = @_;

        $x = $$x                            if index(ref($x), 'Sidef::') == 0;
        $x = (_any2mpz($x) // return undef) if ref($x) ne 'Math::GMPz';

        return Math::GMPz::Rmpz_get_si($x)
          if Math::GMPz::Rmpz_fits_slong_p($x);

        Math::GMPz::Rmpz_get_str($x, 10);
    }

    # Big to unsigned (non-negative) integer-string
    sub _big2uistr {
        my ($x) = @_;

        $x = $$x                            if index(ref($x), 'Sidef::') == 0;
        $x = (_any2mpz($x) // return undef) if ref($x) ne 'Math::GMPz';

        return Math::GMPz::Rmpz_get_ui($x)
          if Math::GMPz::Rmpz_fits_ulong_p($x);

        Math::GMPz::Rmpz_sgn($x) >= 0 or return undef;
        Math::GMPz::Rmpz_get_str($x, 10);
    }

    # Big to positive integer-string
    sub _big2pistr {
        my ($x) = @_;

        $x = $$x                            if index(ref($x), 'Sidef::') == 0;
        $x = (_any2mpz($x) // return undef) if ref($x) ne 'Math::GMPz';

        if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
            my $ui = Math::GMPz::Rmpz_get_ui($x);
            $ui > 0 or return undef;
            return $ui;
        }

        Math::GMPz::Rmpz_sgn($x) > 0 or return undef;
        Math::GMPz::Rmpz_get_str($x, 10);
    }

    sub _factor {
        my ($n) = @_;

        if (ref($n) eq 'Math::GMPz') {
            if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                $n = Math::GMPz::Rmpz_get_ui($n);
            }
            else {
                $n = Math::GMPz::Rmpz_get_str($n, 10);
            }
        }

        my @factors;

        if (length($n) > 500) {

            ($n, @factors) = _adaptive_trial_factor($n);

            if (Math::GMPz::Rmpz_fits_ulong_p($n)) {
                if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0) {
                    return @factors;
                }
                $n = Math::GMPz::Rmpz_get_ui($n);
            }
            else {
                $n = Math::GMPz::Rmpz_get_str($n, 10);
            }
        }

        (
         @factors,
         (
          (HAS_PRIME_UTIL and $n < ULONG_MAX)
          ? Math::Prime::Util::factor($n)
          : Math::Prime::Util::GMP::factor($n)
         )
        );
    }

    # Prime factorization in [p,k] form, where k is the multiplicity of p.
    sub _factor_exp {
        my ($n) = @_;

        if (ref($n) eq 'Math::GMPz') {
            if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                $n = Math::GMPz::Rmpz_get_ui($n);
            }
            else {
                $n = Math::GMPz::Rmpz_get_str($n, 10);
            }
        }

        if (HAS_PRIME_UTIL and $n < ULONG_MAX) {
            return Math::Prime::Util::factor_exp($n);
        }

        my @factors = _factor($n);

        my $prev_value = shift(@factors) // return;
        my @factor_exp = [$prev_value, 1];

        foreach my $curr_value (@factors) {
            if ($curr_value eq $prev_value) {
                ++$factor_exp[-1][1];
            }
            else {
                CORE::push(@factor_exp, [$curr_value, 1]);
            }
            $prev_value = $curr_value;
        }

        @factor_exp;
    }

    sub _divisors {
        my ($n) = @_;

        if (ref($n) eq 'Math::GMPz') {
            if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                $n = Math::GMPz::Rmpz_get_ui($n);
            }
            else {
                $n = Math::GMPz::Rmpz_get_str($n, 10);
            }
        }

        (HAS_PRIME_UTIL and $n < ULONG_MAX)
          ? Math::Prime::Util::divisors($n)
          : Math::Prime::Util::GMP::divisors($n);
    }

    sub _cached_pn_primorial {
        my ($k) = @_;
        state @pn_primorial;
        $pn_primorial[$k] //= Math::GMPz::Rmpz_init_set_str_nobless(Math::Prime::Util::GMP::pn_primorial($k), 10);
    }

    sub _cached_primorial {
        my ($k, $limit) = @_;

        state %cache;

        if (exists $cache{$k}) {
            return $cache{$k};
        }

        $limit //= 100;

        # Clear the cache when there are too many values cached
        if (scalar(keys(%cache)) > $limit) {
            Math::GMPz::Rmpz_clear($_) for values(%cache);
            undef %cache;
        }

        $cache{$k} //= do {
            my $t = Math::GMPz::Rmpz_init_nobless();
            Math::GMPz::Rmpz_primorial_ui($t, $k);
            $t;
        };
    }

    sub _is_prob_prime {
        my ($n) = @_;

        if (ref($n) eq 'Math::GMPz') {
            if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                $n = Math::GMPz::Rmpz_get_ui($n);
            }
            else {
                $n = Math::GMPz::Rmpz_get_str($n, 10);
            }
        }

        (HAS_PRIME_UTIL and $n < ULONG_MAX)
          ? Math::Prime::Util::is_prime($n)
          : Math::Prime::Util::GMP::is_prob_prime($n);
    }

    sub _is_squarefree {
        my ($n) = @_;

        if (ref($n) eq 'Math::GMPz') {
            if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                $n = Math::GMPz::Rmpz_get_ui($n);
            }
            else {
                $n = Math::GMPz::Rmpz_get_str($n, 10);
            }
        }

        (HAS_PRIME_UTIL and $n < ULONG_MAX)
          ? Math::Prime::Util::is_square_free($n)
          : (Math::Prime::Util::GMP::moebius($n) != 0);
    }

    sub _next_prime {
        my ($n) = @_;

        if (ref($n) eq 'Math::GMPz') {
            if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                $n = Math::GMPz::Rmpz_get_ui($n);
            }
            else {
                $n = Math::GMPz::Rmpz_get_str($n, 10);
            }
        }

        (HAS_PRIME_UTIL and $n < (ULONG_MAX - 2000))
          ? Math::Prime::Util::next_prime($n)
          : Math::Prime::Util::GMP::next_prime($n);
    }

    sub _prev_prime {
        my ($n) = @_;

        if (ref($n) eq 'Math::GMPz') {
            if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                $n = Math::GMPz::Rmpz_get_ui($n);
            }
            else {
                $n = Math::GMPz::Rmpz_get_str($n, 10);
            }
        }

        (HAS_PRIME_UTIL and $n < ULONG_MAX)
          ? Math::Prime::Util::prev_prime($n)
          : Math::Prime::Util::GMP::prev_prime($n);
    }

    sub _primorial_trial_factor {
        my ($n, $k) = @_;

        # n is a positive > 1 Math::GMPz object
        # k is an unsigned integer

        my $B = _cached_primorial($k);

        state $g = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_gcd($g, $n, $B);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {

            my $r = Math::GMPz::Rmpz_init_set($n);

            my @factors = _factor(Math::GMPz::Rmpz_get_str($g, 10));
            my @prime_factors;

            foreach my $f (@factors) {
                Math::GMPz::Rmpz_set_ui($g, $f);
                push @prime_factors, ($f) x Math::GMPz::Rmpz_remove($r, $r, $g);
            }

            return ($r, @prime_factors);
        }

        return ($n);
    }

    sub _adaptive_trial_factor {
        my ($n, $F, $L, $R) = @_;

        $F //= 2;
        $L //= 5e4;
        $R //= 1e6;

        if (ref($n) eq 'Math::GMPz') {
            $n = Math::GMPz::Rmpz_init_set($n);    # copy
        }
        else {
            $n = Math::GMPz::Rmpz_init_set_str($n, 10);
        }

        my @factors;

        my $P = _cached_primorial($L);

        state $g = Math::GMPz::Rmpz_init_nobless();
        state $t = Math::GMPz::Rmpz_init_nobless();

        while (1) {

            Math::GMPz::Rmpz_gcd($g, $P, $n);

            # Early stop when n seems to no longer have small factors
            if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
                last;
            }

            foreach my $p (
                           HAS_PRIME_UTIL
                           ? @{Math::Prime::Util::primes($F, $L)}
                           : Math::Prime::Util::GMP::sieve_primes($F, $L)
              ) {
                if (Math::GMPz::Rmpz_divisible_ui_p($g, $p)) {

                    Math::GMPz::Rmpz_set_ui($t, $p);
                    push @factors, ($p) x Math::GMPz::Rmpz_remove($n, $n, $t);

                    # Stop the loop early when no more primes divide `g` (optional)
                    Math::GMPz::Rmpz_divexact_ui($g, $g, $p);
                    last if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0);
                }
            }

            # Early stop when n has been fully factored or the trial range has been exhausted
            if ($L >= $R or Math::GMPz::Rmpz_cmp_ui($n, 1) == 0) {
                last;
            }

            $F = $L;
            $L <<= 1;
            $P = _cached_primorial($L);
        }

        return ($n, @factors);
    }

    #
    ## Binary splitting
    #

    sub _binsplit {
        my ($arr, $func) = @_;

        while ($#$arr > 0) {
            push(@$arr, $func->(shift(@$arr), shift(@$arr)));
        }

        $arr->[0];
    }

    #
    ## Generic each
    #

    sub _generic_each {
        my ($from, $to, $block, $step_function, $buffer_callback) = @_;

        # `from` and `to` are Math::GMPz objects
        # `block` is a Sidef callback block
        # `step_function` is a Perl subroutine to compute the step given the initial current value
        # `buffer_callback` is a Perl subroutine that returns an ARRAY ref with the values in the given range

        if (Math::GMPz::Rmpz_cmp($from, $to) > 0) {
            return ZERO;
        }

        my @buffer;
        my $done  = 0;
        my $count = 0;

        for (; ;) {

            if (!@buffer) {

                last if $done;

                my $step = $step_function->($from);

                if ($step <= 0) {
                    $step = 1e6;
                }

                my $upto = $from + $step;

                if ($upto >= $to) {
                    $done = 1;
                    $upto = $to;
                }

                #~ say ":: Sieving ($from, $upto) with step = $step";
                @buffer = @{$buffer_callback->($from, $upto)};
                $from   = $upto + 1;
                @buffer || next;
            }

            ++$count;
            $block->run(_set_int(shift(@buffer)));
        }

        _set_int($count);
    }

    #
    ## Internal conversion methods
    #

    sub __boolify__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            return !!Math::MPFR::Rmpfr_sgn($x);
        }

      Math_GMPq: {
            return !!Math::GMPq::Rmpq_sgn($x);
        }

      Math_GMPz: {
            return !!Math::GMPz::Rmpz_sgn($x);
        }

      Math_MPC: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_RE($r, $x);
            Math::MPFR::Rmpfr_sgn($r)   && return 1;
            Math::MPFR::Rmpfr_nan_p($r) && return 0;
            Math::MPC::RMPC_IM($r, $x);
            return !!Math::MPFR::Rmpfr_sgn($r);
        }
    }

    sub __numify__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_GMPz: {

            if (Math::GMPz::Rmpz_fits_slong_p($x)) {
                return Math::GMPz::Rmpz_get_si($x);
            }

            if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
                return Math::GMPz::Rmpz_get_ui($x);
            }

            return Math::GMPz::Rmpz_get_d($x);
        }

      Math_GMPq: {

            if (Math::GMPq::Rmpq_integer_p($x)) {
                $x = _mpq2mpz($x);
                goto Math_GMPz;
            }

            return Math::GMPq::Rmpq_get_d($x);
        }

      Math_MPFR: {
            if (Math::MPFR::Rmpfr_integer_p($x)) {
                if (Math::MPFR::Rmpfr_fits_slong_p($x, $ROUND)) {
                    return Math::MPFR::Rmpfr_get_si($x, $ROUND);
                }

                if (Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
                    return Math::MPFR::Rmpfr_get_ui($x, $ROUND);
                }
            }

            return Math::MPFR::Rmpfr_get_d($x, $ROUND);
        }

      Math_MPC: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_RE($r, $x);
            $x = $r;
            goto Math_MPFR;
        }
    }

    sub numify {
        (@_) = (${$_[0]});
        goto &__numify__;
    }

    sub __stringify__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_GMPz: {
            return Math::GMPz::Rmpz_get_str($x, 10);
        }

      Math_GMPq: {

            #~ return Math::GMPq::Rmpq_get_str($x, 10);

            Math::GMPq::Rmpq_integer_p($x)
              && return Math::GMPq::Rmpq_get_str($x, 10);

            $PREC = CORE::int($PREC) if ref($PREC);

            state $z = Math::GMPz::Rmpz_init_nobless();
            Math::GMPz::Rmpz_set_q($z, $x);

            my $size = Math::GMPz::Rmpz_sizeinbase($z, 10) - 1;

            my $f = Math::MPFR::Rmpfr_init2(CORE::int(($size + $PREC / 4) * CORE::log(10) / CORE::log(2)) + 10);
            Math::MPFR::Rmpfr_set_q($f, $x, $ROUND);

            local $PREC = 4 * $size + $PREC;
            return __SUB__->($f);
        }

      Math_MPFR: {
            Math::MPFR::Rmpfr_number_p($x)
              || return (
                           Math::MPFR::Rmpfr_nan_p($x)   ? 'NaN'
                         : Math::MPFR::Rmpfr_sgn($x) < 0 ? '-Inf'
                         :                                 'Inf'
                        );

            # log(10)/log(2) =~ 3.3219280948873623
            my $digits = CORE::int($PREC) >> 2;
            my ($mantissa, $exponent) = Math::MPFR::Rmpfr_deref2($x, 10, $digits, $ROUND);

            my $sgn = '';
            if (substr($mantissa, 0, 1) eq '-') {
                $sgn = substr($mantissa, 0, 1, '');
            }

            $mantissa == 0 and return '0';

            if (CORE::abs($exponent) < CORE::length($mantissa)) {

                if ($exponent > 0) {
                    substr($mantissa, $exponent, 0, '.');
                }
                else {
                    substr($mantissa, 0, 0, '0.' . ('0' x CORE::abs($exponent)));
                }

                $mantissa = CORE::reverse($mantissa);
                $mantissa =~ s/^0+//;
                $mantissa =~ s/^\.//;
                $mantissa = CORE::reverse($mantissa);

                return ($sgn . $mantissa);
            }

            if (CORE::length($mantissa) > 1) {
                substr($mantissa, 1, 0, '.');
            }

            return ($sgn . $mantissa . 'e' . ($exponent - 1));
        }

      Math_MPC: {
            my $fr = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($fr, $x);
            my $re = __SUB__->($fr);

            Math::MPC::RMPC_IM($fr, $x);
            my $im = __SUB__->($fr);

            if ($im eq '0' or $im eq '-0') {
                return $re;
            }

            my $sign = '+';

            if (substr($im, 0, 1) eq '-') {
                $sign = '-';
                substr($im, 0, 1, '');
            }

            #$im = '' if $im eq '1';
            return ($re eq '0' ? $sign eq '+' ? "${im}i" : "$sign${im}i" : "$re$sign${im}i");
        }
    }

    sub get_value {
        (@_) = (${$_[0]});
        goto &__stringify__;
    }

    #
    ## Public conversion methods
    #

    sub int {
        my ($x) = @_;
        ref($$x) eq 'Math::GMPz' ? $x : bless \(_any2mpz($$x) // (goto &nan));
    }

    *trunc  = \&int;
    *to_i   = \&int;
    *to_int = \&int;

    sub rat {
        my ($x) = @_;
        ref($$x) eq 'Math::GMPq' ? $x : bless \(_any2mpq($$x) // (goto &nan));
    }

    *to_r   = \&rat;
    *to_rat = \&rat;

    sub float {
        my ($x) = @_;
        (ref($$x) eq 'Math::MPFR' || ref($$x) eq 'Math::MPC') ? $x : bless \_any2mpfr_mpc($$x);
    }

    *to_f     = \&float;
    *to_float = \&float;

    sub to_poly {
        my ($x) = @_;
        Sidef::Types::Number::Polynomial->new(0 => $x);
    }

    sub eval {
        $_[0];
    }

    sub complex {
        my ($x, $y) = @_;

        if (defined $y) {
            return Sidef::Types::Number::Complex->new($x, $y);
        }

        ref($$x) eq 'Math::MPC' ? $x : bless \_any2mpc($$x);
    }

    sub rat_approx {
        my ($x) = @_;

        $x = _any2mpfr($$x);

        Math::MPFR::Rmpfr_number_p($x) || goto &nan;

        my $n1 = Math::GMPz::Rmpz_init_set_ui(0);
        my $n2 = Math::GMPz::Rmpz_init_set_ui(1);

        my $d1 = Math::GMPz::Rmpz_init_set_ui(1);
        my $d2 = Math::GMPz::Rmpz_init_set_ui(0);

        my $q = Math::GMPq::Rmpq_init();
        my $z = Math::GMPz::Rmpz_init();

        my $s = __stringify__($x);

        my $f1 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        my $f2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        my $f3 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPFR::Rmpfr_set($f1, $x, $ROUND);

        while (1) {
            Math::MPFR::Rmpfr_floor($f2, $f1);
            Math::MPFR::Rmpfr_get_z($z, $f2, $ROUND);

            Math::GMPz::Rmpz_addmul($n1, $n2, $z);    # n1 += n2 * z
            Math::GMPz::Rmpz_addmul($d1, $d2, $z);    # d1 += d2 * z

            ($n1, $n2) = ($n2, $n1);
            ($d1, $d2) = ($d2, $d1);

            # q = n2 / d2
            Math::GMPq::Rmpq_set_num($q, $n2);
            Math::GMPq::Rmpq_set_den($q, $d2);
            Math::GMPq::Rmpq_canonicalize($q);

            Math::MPFR::Rmpfr_set_q($f3, $q, $ROUND);
            CORE::index(__stringify__($f3), $s) == 0 and last;

            # f1 = 1 / (f1 - f2)
            Math::MPFR::Rmpfr_sub($f1, $f1, $f2, $ROUND);
            Math::MPFR::Rmpfr_zero_p($f1) && last;
            Math::MPFR::Rmpfr_ui_div($f1, 1, $f1, $ROUND);
        }

        bless \$q;
    }

    sub pair {
        my ($x, $y) = @_;
        Sidef::Types::Number::Complex->new($x, $y);
    }

    sub __norm__ {
        my ($x) = @_;

        goto(ref($x) =~ tr/:/_/rs);

      Math_MPC: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_norm($r, $x, $ROUND);
            return $r;
        }

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_sqr($r, $x, $ROUND);
            return $r;
        }

      Math_GMPz: {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_mul($r, $x, $x);
            return $r;
        }

      Math_GMPq: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_mul($r, $x, $x);
            return $r;
        }
    }

    sub norm {
        my ($x) = @_;
        bless \__norm__($$x);
    }

    sub conj {
        my ($x) = @_;
        ref($$x) eq 'Math::MPC' or return $x;
        my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
        Math::MPC::Rmpc_conj($r, $$x, $ROUND);
        bless \$r;
    }

    sub real {
        my ($x) = @_;

        if (ref($$x) eq 'Math::MPC') {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_RE($r, $$x);
            bless \$r;
        }
        else {
            $x;
        }
    }

    *re = \&real;

    sub imag {
        my ($x) = @_;

        if (ref($$x) eq 'Math::MPC') {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_IM($r, $$x);
            bless \$r;
        }
        else {
            ZERO;
        }
    }

    *im        = \&imag;
    *imaginary = \&imag;

    sub reals {
        ($_[0]->real, $_[0]->imag);
    }

    sub parts {
        Sidef::Types::Array::Array->new($_[0]->reals);
    }

    #
    ## CONSTANTS
    #

    sub pi {

        if (ref($_[0])) {
            return $_[0]->prime_count($_[1]);
        }

        my $pi = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_pi($pi, $ROUND);
        bless \$pi;
    }

    *π = \&pi;

    sub tau {

        if (ref($_[0])) {
            return $_[0]->sigma0;
        }

        my $tau = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_pi($tau, $ROUND);
        Math::MPFR::Rmpfr_mul_2ui($tau, $tau, 1, $ROUND);
        bless \$tau;
    }

    *τ = \&tau;

    sub ln2 {
        my $ln2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_log2($ln2, $ROUND);
        bless \$ln2;
    }

    sub EulerGamma {
        my $euler = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_euler($euler, $ROUND);
        bless \$euler;
    }

    *γ           = \&EulerGamma;
    *Y           = \&EulerGamma;
    *euler_gamma = \&EulerGamma;

    sub CatalanG {
        my $catalan = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_catalan($catalan, $ROUND);
        bless \$catalan;
    }

    *C = \&CatalanG;

    sub i {
        my ($x) = @_;

        state $i = do {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_ui_ui($c, 0, 1, $ROUND);
            $c;
        };

        if (ref($x)) {
            bless \__mul__($i, $$x);
        }
        else {
            state $obj = bless \$i;
        }
    }

    sub e {
        state $one_f = (Math::MPFR::Rmpfr_init_set_ui_nobless(1, $ROUND))[0];
        my $e = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_exp($e, $one_f, $ROUND);
        bless \$e;
    }

    sub phi {

        if (ref($_[0])) {
            return $_[0]->euler_phi;
        }

        state $five4_f = (Math::MPFR::Rmpfr_init_set_d_nobless(1.25, $ROUND))[0];

        my $phi = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_sqrt($phi, $five4_f, $ROUND);
        Math::MPFR::Rmpfr_add_d($phi, $phi, 0.5, $ROUND);

        bless \$phi;
    }

    *φ = \&phi;

    sub _nan {
        state $nan = do {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_nan($r);
            $r;
        };
    }

    sub nan {
        state $nan = do {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_nan($r);
            bless \$r;
        };
    }

    sub _inf {
        state $inf = do {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_inf($r, 1);
            $r;
        };
    }

    sub inf {
        state $inf = do {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_inf($r, 1);
            bless \$r;
        };
    }

    sub _ninf {
        state $ninf = do {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_inf($r, -1);
            $r;
        };
    }

    sub ninf {
        state $ninf = do {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_inf($r, -1);
            bless \$r;
        };
    }

    *zero = \&ZERO;
    *one  = \&ONE;
    *mone = \&MONE;

    sub __add__ {
        my ($x, $y) = @_;

        goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

        #
        ## GMPz
        #
      Math_GMPz__Math_GMPz: {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_add($r, $x, $y);
            return $r;
        }

      Math_GMPz__Math_GMPq: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_add_z($r, $y, $x);
            return $r;
        }

      Math_GMPz__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_add_z($r, $y, $x, $ROUND);
            return $r;
        }

      Math_GMPz__Math_MPC: {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($c, $x, $ROUND);
            Math::MPC::Rmpc_add($c, $c, $y, $ROUND);
            return $c;
        }

        #
        ## GMPq
        #
      Math_GMPq__Math_GMPq: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_add($r, $x, $y);
            return $r;
        }

      Math_GMPq__Math_GMPz: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_add_z($r, $x, $y);
            return $r;
        }

      Math_GMPq__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_add_q($r, $y, $x, $ROUND);
            return $r;
        }

      Math_GMPq__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($r, $x, $ROUND);
            Math::MPC::Rmpc_add($r, $r, $y, $ROUND);
            return $r;
        }

        #
        ## MPFR
        #
      Math_MPFR__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_add($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_GMPq: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_add_q($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_GMPz: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_add_z($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_add_fr($r, $y, $x, $ROUND);
            return $r;
        }

        #
        ## MPC
        #
      Math_MPC__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_add($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_MPFR: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_add_fr($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_GMPz: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($r, $y, $ROUND);
            Math::MPC::Rmpc_add($r, $r, $x, $ROUND);
            return $r;
        }

      Math_MPC__Math_GMPq: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($r, $y, $ROUND);
            Math::MPC::Rmpc_add($r, $r, $x, $ROUND);
            return $r;
        }
    }

    sub add {
        my ($x, $y) = @_;

        my $ref = ref($y);

        if (   $ref eq 'Sidef::Types::Number::Mod'
            or $ref eq 'Sidef::Types::Number::Gauss'
            or $ref eq 'Sidef::Types::Number::Fraction'
            or $ref eq 'Sidef::Types::Number::Quadratic'
            or $ref eq 'Sidef::Types::Number::Quaternion'
            or $ref eq 'Sidef::Types::Number::Polynomial') {
            return $y->add($x);
        }

        _valid(\$y);
        bless \__add__($$x, $$y);
    }

    sub __sub__ {
        my ($x, $y) = @_;

        goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

        #
        ## GMPq
        #
      Math_GMPq__Math_GMPq: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_sub($r, $x, $y);
            return $r;
        }

      Math_GMPq__Math_GMPz: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_sub_z($r, $x, $y);
            return $r;
        }

      Math_GMPq__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_sub_q($r, $y, $x, $ROUND);
            Math::MPFR::Rmpfr_neg($r, $r, $ROUND);
            return $r;
        }

      Math_GMPq__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($r, $x, $ROUND);
            Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
            return $r;
        }

        #
        ## GMPz
        #
      Math_GMPz__Math_GMPz: {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_sub($r, $x, $y);
            return $r;
        }

      Math_GMPz__Math_GMPq: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_z_sub($r, $x, $y);
            return $r;
        }

      Math_GMPz__Math_MPFR: {

#<<<
            state $has_z_sub = (Math::MPFR::MPFR_VERSION_MAJOR() >  3)
                            || (Math::MPFR::MPFR_VERSION_MAJOR() == 3
                            &&  Math::MPFR::MPFR_VERSION_MINOR() >= 1);
#>>>

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            $has_z_sub
              ? Math::MPFR::Rmpfr_z_sub($r, $x, $y, $ROUND)
              : do {
                Math::MPFR::Rmpfr_sub_z($r, $y, $x, $ROUND);
                Math::MPFR::Rmpfr_neg($r, $r, $ROUND);
              };

            return $r;
        }

      Math_GMPz__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($r, $x, $ROUND);
            Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
            return $r;
        }

        #
        ## MPFR
        #
      Math_MPFR__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_sub($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_GMPq: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_sub_q($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_GMPz: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_sub_z($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_fr($r, $x, $ROUND);
            Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
            return $r;
        }

        #
        ## MPC
        #
      Math_MPC__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_sub($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_MPFR: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_fr($r, $y, $ROUND);
            Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
            return $r;
        }

      Math_MPC__Math_GMPz: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($r, $y, $ROUND);
            Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
            return $r;
        }

      Math_MPC__Math_GMPq: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($r, $y, $ROUND);
            Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
            return $r;
        }
    }

    sub sub {
        my ($x, $y) = @_;

        my $ref = ref($y);

        if ($ref eq 'Sidef::Types::Number::Mod') {
            return $ref->new($x, $y->{m})->sub($y);
        }

        if (   $ref eq 'Sidef::Types::Number::Gauss'
            or $ref eq 'Sidef::Types::Number::Quaternion'
            or $ref eq 'Sidef::Types::Number::Fraction') {
            return $ref->new($x)->sub($y);
        }

        if ($ref eq 'Sidef::Types::Number::Quadratic') {
            return $ref->new($x, ZERO, $y->{w})->sub($y);
        }

        if ($ref eq 'Sidef::Types::Number::Polynomial') {
            return $ref->new(0 => $x)->sub($y);
        }

        _valid(\$y);
        bless \__sub__($$x, $$y);
    }

    sub __mul__ {
        my ($x, $y) = @_;

        goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

        #
        ## GMPq
        #
      Math_GMPq__Math_GMPq: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_mul($r, $x, $y);
            return $r;
        }

      Math_GMPq__Math_GMPz: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_mul_z($r, $x, $y);
            return $r;
        }

      Math_GMPq__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_mul_q($r, $y, $x, $ROUND);
            return $r;
        }

      Math_GMPq__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($r, $x, $ROUND);
            Math::MPC::Rmpc_mul($r, $r, $y, $ROUND);
            return $r;
        }

        #
        ## GMPz
        #
      Math_GMPz__Math_GMPz: {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_mul($r, $x, $y);
            return $r;
        }

      Math_GMPz__Math_GMPq: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_mul_z($r, $y, $x);
            return $r;
        }

      Math_GMPz__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_mul_z($r, $y, $x, $ROUND);
            return $r;
        }

      Math_GMPz__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($r, $x, $ROUND);
            Math::MPC::Rmpc_mul($r, $r, $y, $ROUND);
            return $r;
        }

        #
        ## MPFR
        #
      Math_MPFR__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_mul($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_GMPq: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_mul_q($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_GMPz: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_mul_z($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_mul_fr($r, $y, $x, $ROUND);
            return $r;
        }

        #
        ## MPC
        #
      Math_MPC__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_mul($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_MPFR: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_mul_fr($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_GMPz: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($r, $y, $ROUND);
            Math::MPC::Rmpc_mul($r, $r, $x, $ROUND);
            return $r;
        }

      Math_MPC__Math_GMPq: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($r, $y, $ROUND);
            Math::MPC::Rmpc_mul($r, $r, $x, $ROUND);
            return $r;
        }
    }

    sub mul {
        my ($x, $y) = @_;

        my $ref = ref($y);

        if (   $ref eq 'Sidef::Types::Number::Mod'
            or $ref eq 'Sidef::Types::Number::Gauss'
            or $ref eq 'Sidef::Types::Number::Fraction'
            or $ref eq 'Sidef::Types::Number::Quadratic'
            or $ref eq 'Sidef::Types::Number::Quaternion'
            or $ref eq 'Sidef::Types::Number::Polynomial'
            or $ref eq 'Sidef::Types::Array::Matrix') {
            return $y->mul($x);
        }

        _valid(\$y);
        bless \__mul__($$x, $$y);
    }

    sub __div__ {
        my ($x, $y) = @_;

        goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

        #
        ## GMPq
        #
      Math_GMPq__Math_GMPq: {

            # Check for division by zero
            Math::GMPq::Rmpq_sgn($y) || do {
                $x = _mpq2mpfr($x);
                goto Math_MPFR__Math_GMPq;
            };

            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_div($r, $x, $y);
            return $r;
        }

      Math_GMPq__Math_GMPz: {

            # Check for division by zero
            Math::GMPz::Rmpz_sgn($y) || do {
                $x = _mpq2mpfr($x);
                goto Math_MPFR__Math_GMPz;
            };

            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_div_z($r, $x, $y);
            return $r;
        }

      Math_GMPq__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_q_div($r, $x, $y, $ROUND);
            return $r;
        }

      Math_GMPq__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($r, $x, $ROUND);
            Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
            return $r;
        }

        #
        ## GMPz
        #
      Math_GMPz__Math_GMPz: {

            # Check for division by zero
            Math::GMPz::Rmpz_sgn($y) || do {
                $x = _mpz2mpfr($x);
                goto Math_MPFR__Math_GMPz;
            };

            # Check for exact divisibility
            if (Math::GMPz::Rmpz_divisible_p($x, $y)) {
                my $r = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_divexact($r, $x, $y);
                return $r;
            }

            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_num($r, $x);
            Math::GMPq::Rmpq_set_den($r, $y);
            Math::GMPq::Rmpq_canonicalize($r);
            return $r;
        }

      Math_GMPz__Math_GMPq: {

            # Check for division by zero
            Math::GMPq::Rmpq_sgn($y) || do {
                $x = _mpz2mpfr($x);
                goto Math_MPFR__Math_GMPq;
            };

            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_z_div($r, $x, $y);
            return $r;
        }

      Math_GMPz__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_z_div($r, $x, $y, $ROUND);
            return $r;
        }

      Math_GMPz__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($r, $x, $ROUND);
            Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
            return $r;
        }

        #
        ## MPFR
        #
      Math_MPFR__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_div($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_GMPq: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_div_q($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_GMPz: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_div_z($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_fr($r, $x, $ROUND);
            Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
            return $r;
        }

        #
        ## MPC
        #
      Math_MPC__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_div($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_MPFR: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_div_fr($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_GMPz: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($r, $y, $ROUND);
            Math::MPC::Rmpc_div($r, $x, $r, $ROUND);
            return $r;
        }

      Math_MPC__Math_GMPq: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($r, $y, $ROUND);
            Math::MPC::Rmpc_div($r, $x, $r, $ROUND);
            return $r;
        }
    }

    sub div {
        my ($x, $y) = @_;

        my $ref = ref($y);

        if ($ref eq 'Sidef::Types::Number::Mod') {
            return $ref->new($x, $y->{m})->div($y);
        }

        if ($ref eq 'Sidef::Types::Number::Quadratic') {
            return $ref->new($x, ZERO, $y->{w})->div($y);
        }

        if (   $ref eq 'Sidef::Types::Number::Gauss'
            or $ref eq 'Sidef::Types::Number::Fraction'
            or $ref eq 'Sidef::Types::Number::Quaternion') {
            return $ref->new($x)->div($y);
        }

        if ($ref eq 'Sidef::Types::Number::Polynomial') {
            return $ref->new(0 => $x)->div($y);
        }

        _valid(\$y);
        bless \__div__($$x, $$y);
    }

    # Modular operations

    sub addmod {
        my ($x, $y, $m) = @_;

        _valid(\$y, \$m);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;
        $m = _any2mpz($$m) // goto &nan;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add($r, $x, $y);
        Math::GMPz::Rmpz_mod($r, $r, $m);
        bless \$r;
    }

    sub submod {
        my ($x, $y, $m) = @_;

        _valid(\$y, \$m);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;
        $m = _any2mpz($$m) // goto &nan;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub($r, $x, $y);
        Math::GMPz::Rmpz_mod($r, $r, $m);
        bless \$r;
    }

    sub mulmod {
        my ($x, $y, $m) = @_;

        _valid(\$y, \$m);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;
        $m = _any2mpz($$m) // goto &nan;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul($r, $x, $y);
        Math::GMPz::Rmpz_mod($r, $r, $m);
        bless \$r;
    }

    #
    ## Integer operations
    #

    sub iadd {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add($r, $x, $y);
        bless \$r;
    }

    sub isub {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub($r, $x, $y);
        bless \$r;
    }

    sub imul {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul($r, $x, $y);
        bless \$r;
    }

    sub idiv {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        # Detect division by zero
        Math::GMPz::Rmpz_sgn($y) || do {
            my $sign = Math::GMPz::Rmpz_sgn($x);

            if ($sign == 0) {    # 0/0
                goto &nan;
            }
            elsif ($sign > 0) {    # x/0 where: x > 0
                goto &inf;
            }
            else {                 # x/0 where: x < 0
                goto &ninf;
            }
        };

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_div($r, $x, $y);
        bless \$r;
    }

    *idiv_floor = \&idiv;

    sub idiv_ceil {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        # Detect division by zero
        Math::GMPz::Rmpz_sgn($y) || do {
            my $sign = Math::GMPz::Rmpz_sgn($x);

            if ($sign == 0) {    # 0/0
                goto &nan;
            }
            elsif ($sign > 0) {    # x/0 where: x > 0
                goto &inf;
            }
            else {                 # x/0 where: x < 0
                goto &ninf;
            }
        };

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_cdiv_q($r, $x, $y);
        bless \$r;
    }

    sub idiv_trunc {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        # Detect division by zero
        Math::GMPz::Rmpz_sgn($y) || do {
            my $sign = Math::GMPz::Rmpz_sgn($x);

            if ($sign == 0) {    # 0/0
                goto &nan;
            }
            elsif ($sign > 0) {    # x/0 where: x > 0
                goto &inf;
            }
            else {                 # x/0 where: x < 0
                goto &ninf;
            }
        };

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_tdiv_q($r, $x, $y);
        bless \$r;
    }

    sub idiv_round {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        # Detect division by zero
        Math::GMPz::Rmpz_sgn($y) || do {
            my $sign = Math::GMPz::Rmpz_sgn($x);

            if ($sign == 0) {    # 0/0
                goto &nan;
            }
            elsif ($sign > 0) {    # x/0 where: x > 0
                goto &inf;
            }
            else {                 # x/0 where: x < 0
                goto &ninf;
            }
        };

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set($r, $y);
        Math::GMPz::Rmpz_addmul_ui($r, $x, 2);
        Math::GMPz::Rmpz_div($r, $r, $y);
        Math::GMPz::Rmpz_div_2exp($r, $r, 1);
        bless \$r;
    }

    sub __neg__ {
        my ($x) = @_;

        goto(ref($x) =~ tr/:/_/rs);

      Math_GMPz: {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_neg($r, $x);
            return $r;
        }

      Math_GMPq: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_neg($r, $x);
            return $r;
        }

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_neg($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_neg($r, $x, $ROUND);
            return $r;
        }
    }

    sub neg {
        my ($x) = @_;
        bless \__neg__($$x);
    }

    sub __abs__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_GMPz: {
            Math::GMPz::Rmpz_sgn($x) >= 0 and return $x;
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_abs($r, $x);
            return $r;
        }

      Math_GMPq: {
            Math::GMPq::Rmpq_sgn($x) >= 0 and return $x;
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_abs($r, $x);
            return $r;
        }

      Math_MPFR: {
            Math::MPFR::Rmpfr_sgn($x) >= 0 and return $x;
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_abs($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($r, $x, $ROUND);
            return $r;
        }
    }

    sub abs {
        my ($x) = @_;
        bless \__abs__($$x);
    }

    sub __inv__ {
        my ($x) = @_;

        goto(ref($x) =~ tr/:/_/rs);

      Math_GMPq: {

            # Check for division by zero
            Math::GMPq::Rmpq_sgn($x) || do {
                $x = _mpq2mpfr($x);
                goto Math_MPFR;
            };

            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_inv($r, $x);
            return $r;
        }

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
            return $r;
        }

      Math_GMPz: {

            # Check for division by zero
            Math::GMPz::Rmpz_sgn($x) || do {
                $x = _mpz2mpfr($x);
                goto Math_MPFR;
            };

            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_z($r, $x);
            Math::GMPq::Rmpq_inv($r, $r);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
            return $r;
        }
    }

    sub inv {
        my ($x) = @_;
        bless \__inv__($$x);
    }

    sub sqr {
        my ($x) = @_;
        bless \__mul__($$x, $$x);
    }

    *square = \&sqr;

    sub cube {
        my ($x) = @_;
        bless \__pow__($$x, 3);
    }

    sub __sqrt__ {
        my ($x) = @_;

        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {

            # Complex for x < 0
            if (Math::MPFR::Rmpfr_sgn($x) < 0) {
                my $r = _mpfr2mpc($x);
                Math::MPC::Rmpc_sqrt($r, $r, $ROUND);
                return $r;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_sqrt($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_sqrt($r, $x, $ROUND);
            return $r;
        }
    }

    sub sqrt {
        my ($x) = @_;
        bless \__sqrt__(_any2mpfr_mpc($$x));
    }

    sub sqrtQ {
        my ($x) = @_;
        Sidef::Types::Number::Quadratic->new(ZERO, ONE, $x);
    }

    sub __cbrt__ {
        my ($x) = @_;

        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {

            # Complex for x < 0
            if (Math::MPFR::Rmpfr_sgn($x) < 0) {
                $x = _mpfr2mpc($x);
                goto Math_MPC;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_cbrt($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $three_inv = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_ui($three_inv, 3, $ROUND);
            Math::MPFR::Rmpfr_ui_div($three_inv, 1, $three_inv, $ROUND);

            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_pow_fr($r, $x, $three_inv, $ROUND);
            return $r;
        }
    }

    sub cbrt {
        my ($x) = @_;
        bless \__cbrt__(_any2mpfr_mpc($$x));
    }

    sub __iroot__ {
        my ($x, $y) = @_;

        # $x is a Math::GMPz object
        # $y is a signed integer

        if ($y == 0) {
            Math::GMPz::Rmpz_sgn($x) || return $x;    # 0^Inf = 0

            # 1^Inf = 1 ; (-1)^Inf = 1
            if (Math::GMPz::Rmpz_cmpabs_ui($x, 1) == 0) {
                return $ONE;
            }

            goto &_inf;
        }
        elsif ($y < 0) {
            my $sign = Math::GMPz::Rmpz_sgn($x) || goto &_inf;    # 1 / 0^k = Inf
            Math::GMPz::Rmpz_cmp_ui($x, 1)      || return $x;     # 1 / 1^k = 1

            if ($sign < 0) {
                goto &_nan;
            }

            return $ZERO;
        }
        elsif ($y % 2 == 0 and Math::GMPz::Rmpz_sgn($x) < 0) {
            goto &_nan;
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_root($r, $x, $y);
        $r;
    }

    sub iroot {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__iroot__(_any2mpz($$x) // (goto &nan), _any2si($$y) // (goto &nan));
    }

    sub isqrt {
        my ($x) = @_;

        $x = _any2mpz($$x) // goto &nan;
        Math::GMPz::Rmpz_sgn($x) < 0 and goto &nan;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sqrt($r, $x);
        bless \$r;
    }

    sub icbrt {
        my ($x) = @_;
        bless \__iroot__(_any2mpz($$x) // (goto &nan), 3);
    }

    sub isqrtrem {
        my ($x) = @_;

        $x = _any2mpz($$x) // goto &nan;

        Math::GMPz::Rmpz_sgn($x) < 0
          and return ((nan()) x 2);

        my $r = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_sqrtrem($r, $s, $x);
        ((bless \$r), (bless \$s));
    }

    sub irootrem {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2si($$y)  // goto &nan;

        if ($y == 0) {
            Math::GMPz::Rmpz_sgn($x) || return (ZERO, MONE);    # 0^Inf = 0

            if (Math::GMPz::Rmpz_cmpabs_ui($x, 1) == 0) {       # 1^Inf = 1 ; (-1)^Inf = 1
                return (ONE, bless \__dec__($x));
            }

            return (inf(), bless \__dec__($x));
        }
        elsif ($y < 0) {
            my $sign = Math::GMPz::Rmpz_sgn($x) || return (inf(), ZERO);    # 1 / 0^k = Inf
            Math::GMPz::Rmpz_cmp_ui($x, 1) == 0 and return (ONE, ZERO);     # 1 / 1^k = 1
            return ($sign < 0 ? (nan(), nan()) : (ZERO, ninf()));
        }
        elsif ($y % 2 == 0 and Math::GMPz::Rmpz_sgn($x) < 0) {
            return (nan(), nan());
        }

        my $r = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_rootrem($r, $s, $x, $y);
        ((bless \$r), (bless \$s));
    }

    sub __pow__ {
        my ($x, $y) = @_;

        goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

        #
        ## GMPq
        #
      Math_GMPq__Scalar: {

            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_pow_ui($r, $x, CORE::abs($y));

            if ($y < 0) {
                Math::GMPq::Rmpq_sgn($r) || goto &_inf;
                Math::GMPq::Rmpq_inv($r, $r);
            }

            return $r;
        }

      Math_GMPq__Math_GMPq: {

            # Integer power
            if (Math::GMPq::Rmpq_integer_p($y)) {
                $y = Math::GMPq::Rmpq_get_d($y);
                goto Math_GMPq__Scalar;
            }

            # (-x)^(a/b) is a complex number
            elsif (Math::GMPq::Rmpq_sgn($x) < 0) {
                ($x, $y) = (_mpq2mpc($x), _mpq2mpc($y));
                goto Math_MPC__Math_MPC;
            }

            ($x, $y) = (_mpq2mpfr($x), _mpq2mpfr($y));
            goto Math_MPFR__Math_MPFR;
        }

      Math_GMPq__Math_GMPz: {
            $y = Math::GMPz::Rmpz_get_d($y);
            goto Math_GMPq__Scalar;
        }

      Math_GMPq__Math_MPFR: {
            $x = _mpq2mpfr($x);
            goto Math_MPFR__Math_MPFR;
        }

      Math_GMPq__Math_MPC: {
            $x = _mpq2mpc($x);
            goto Math_MPC__Math_MPC;
        }

        #
        ## GMPz
        #
      Math_GMPz__Scalar: {

            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_pow_ui($r, $x, CORE::abs($y));

            if ($y < 0) {
                Math::GMPz::Rmpz_sgn($r) || goto &_inf;

                my $q = Math::GMPq::Rmpq_init();
                Math::GMPq::Rmpq_set_z($q, $r);
                Math::GMPq::Rmpq_inv($q, $q);
                return $q;
            }

            return $r;
        }

      Math_GMPz__Math_GMPz: {
            $y = Math::GMPz::Rmpz_get_d($y);
            goto Math_GMPz__Scalar;
        }

      Math_GMPz__Math_GMPq: {
            if (Math::GMPq::Rmpq_integer_p($y)) {
                $y = Math::GMPq::Rmpq_get_d($y);
                goto Math_GMPz__Scalar;
            }

            ($x, $y) = (_mpz2mpfr($x), _mpq2mpfr($y));
            goto Math_MPFR__Math_MPFR;
        }

      Math_GMPz__Math_MPFR: {
            $x = _mpz2mpfr($x);
            goto Math_MPFR__Math_MPFR;
        }

      Math_GMPz__Math_MPC: {
            $x = _mpz2mpc($x);
            goto Math_MPC__Math_MPC;
        }

        #
        ## MPFR
        #
      Math_MPFR__Math_MPFR: {
            if (    Math::MPFR::Rmpfr_sgn($x) < 0
                and !Math::MPFR::Rmpfr_integer_p($y)
                and Math::MPFR::Rmpfr_number_p($y)) {
                $x = _mpfr2mpc($x);
                goto Math_MPC__Math_MPFR;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_pow($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Scalar: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            $y < 0
              ? Math::MPFR::Rmpfr_pow_si($r, $x, $y, $ROUND)
              : Math::MPFR::Rmpfr_pow_ui($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_GMPq: {
            $y = _mpq2mpfr($y);
            goto Math_MPFR__Math_MPFR;
        }

      Math_MPFR__Math_GMPz: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_pow_z($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_MPC: {
            $x = _mpfr2mpc($x);
            goto Math_MPC__Math_MPC;
        }

        #
        ## MPC
        #
      Math_MPC__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_pow($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Scalar: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            $y < 0
              ? Math::MPC::Rmpc_pow_si($r, $x, $y, $ROUND)
              : Math::MPC::Rmpc_pow_ui($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_MPFR: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_pow_fr($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_GMPz: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_pow_z($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_GMPq: {
            $y = _mpq2mpfr($y);
            goto Math_MPC__Math_MPFR;
        }
    }

    sub root {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__pow__($$x, __inv__($$y));
    }

    sub pow {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__pow__($$x, $$y);
    }

    sub ipow {
        my ($x, $y) = @_;
        _valid(\$y);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2si($$y)  // goto &nan;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_pow_ui($r, $x, CORE::abs($y));

        if ($y < 0) {
            Math::GMPz::Rmpz_sgn($r) || goto &inf;    # 0^(-y) = Inf
            Math::GMPz::Rmpz_div($r, $ONE, $r);
        }

        bless \$r;
    }

    sub ipow2 {
        my ($n) = @_;

        $n = _any2si($$n) // goto &nan;

        return ZERO if $n < 0;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_setbit($r, $n);
        bless \$r;
    }

    sub ipow10 {
        my ($n) = @_;

        $n = _any2si($$n) // goto &nan;

        return ZERO if $n < 0;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_ui_pow_ui($r, 10, $n);
        bless \$r;
    }

    sub __log2__ {
        my ($x) = @_;

        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {

            # Complex for x < 0
            if (Math::MPFR::Rmpfr_sgn($x) < 0) {
                $x = _mpfr2mpc($x);
                goto Math_MPC;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_log2($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $ln2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_const_log2($ln2, $ROUND);
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_log($r, $x, $ROUND);
            Math::MPC::Rmpc_div_fr($r, $r, $ln2, $ROUND);
            return $r;
        }
    }

    sub __log10__ {
        my ($x) = @_;

        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {

            # Complex for x < 0
            if (Math::MPFR::Rmpfr_sgn($x) < 0) {
                $x = _mpfr2mpc($x);
                goto Math_MPC;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_log10($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            state $MPC_VERSION = Math::MPC::MPC_VERSION();

            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));

            if ($MPC_VERSION >= 65536) {    # available only in mpc>=1.0.0
                Math::MPC::Rmpc_log10($r, $x, $ROUND);
            }
            else {
                my $ln10 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
                Math::MPFR::Rmpfr_set_ui($ln10, 10, $ROUND);
                Math::MPFR::Rmpfr_log($ln10, $ln10, $ROUND);
                Math::MPC::Rmpc_log($r, $x, $ROUND);
                Math::MPC::Rmpc_div_fr($r, $r, $ln10, $ROUND);
            }

            return $r;
        }
    }

    sub __log__ {
        my ($x) = @_;

        goto(ref($x) =~ tr/:/_/rs);

        #
        ## MPFR
        #
      Math_MPFR: {

            # Complex for x < 0
            if (Math::MPFR::Rmpfr_sgn($x) < 0) {
                my $r = _mpfr2mpc($x);
                Math::MPC::Rmpc_log($r, $r, $ROUND);
                return $r;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_log($r, $x, $ROUND);
            return $r;
        }

        #
        ## MPC
        #
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_log($r, $x, $ROUND);
            return $r;
        }
    }

    sub log {
        my ($x, $y) = @_;

        if (defined($y)) {
            _valid(\$y);
            bless \__div__(__log__(_any2mpfr_mpc($$x)), __log__(_any2mpfr_mpc($$y)));
        }
        else {
            bless \__log__(_any2mpfr_mpc($$x));
        }
    }

    sub ln {
        my ($x) = @_;
        bless \__log__(_any2mpfr_mpc($$x));
    }

    sub log2 {
        my ($x) = @_;
        bless \__log2__(_any2mpfr_mpc($$x));
    }

    sub log10 {
        my ($x) = @_;
        bless \__log10__(_any2mpfr_mpc($$x));
    }

    sub __ilog__ {
        my ($x, $y) = @_;

        # ilog(x, y <= 1) = NaN
        $y <= 1 and return;

        # ilog(x <= 0, y) = NaN
        Math::GMPz::Rmpz_sgn($x) <= 0 and return;

        # Return faster for y <= 62
        if ($y <= 62) {

            $y = Math::GMPz::Rmpz_get_ui($y) if ref($y);

            # NOTE: size is always exact for base = 2.
            my $e = (Math::GMPz::Rmpz_sizeinbase($x, $y) || return) - 1;

            if ($y != 2 and $e > 0) {
                state $t = Math::GMPz::Rmpz_init_nobless();
                Math::GMPz::Rmpz_ui_pow_ui($t, $y, $e);
                Math::GMPz::Rmpz_cmp($t, $x) > 0 and --$e;
            }

            return $e;
        }

        # Make sure `y` is a Math::GMPz object
        $y = Math::GMPz::Rmpz_init_set_ui($y) if !ref($y);

        my $e = 0;

        state $t    = Math::GMPz::Rmpz_init_nobless();
        state $logx = Math::MPFR::Rmpfr_init2_nobless(64);
        state $logy = Math::MPFR::Rmpfr_init2_nobless(64);

        Math::MPFR::Rmpfr_set_z($logx, $x, $round_z);
        Math::MPFR::Rmpfr_set_z($logy, $y, $round_z);
        Math::MPFR::Rmpfr_log($logx, $logx, $round_z);
        Math::MPFR::Rmpfr_log($logy, $logy, $round_z);
        Math::MPFR::Rmpfr_div($logx, $logx, $logy, $round_z);

        if (Math::MPFR::Rmpfr_fits_ulong_p($logx, $round_z)) {
            $e = Math::MPFR::Rmpfr_get_ui($logx, $round_z) - 1;
            Math::GMPz::Rmpz_pow_ui($t, $y, $e + 1);
        }
        else {
            Math::GMPz::Rmpz_set($t, $y);
        }

        for (; Math::GMPz::Rmpz_cmp($t, $x) <= 0 ; Math::GMPz::Rmpz_mul($t, $t, $y)) {
            ++$e;
        }

        return $e;
    }

    sub ilog {
        my ($x, $y) = @_;
        if (defined($y)) {
            _valid(\$y);
            _set_int(__ilog__((_any2mpz($$x) // goto &nan), (_any2mpz($$y) // goto &nan)) // goto &nan);
        }
        else {
            bless \(_any2mpz(__log__(_any2mpfr_mpc($$x))) // goto &nan);
        }
    }

    sub ilog2 {
        my ($x) = @_;
        _set_int(__ilog__((_any2mpz($$x) // goto &nan), 2) // goto &nan);
    }

    sub ilog10 {
        my ($x) = @_;
        _set_int(__ilog__((_any2mpz($$x) // goto &nan), 10) // goto &nan);
    }

    sub msb {
        my ($n) = @_;

        $n = _any2mpz($$n) // return undef;
        Math::GMPz::Rmpz_sgn($n) || return undef;

        _set_int(Math::GMPz::Rmpz_sizeinbase($n, 2) - 1);
    }

    sub lsb {
        my ($n) = @_;

        $n = _any2mpz($$n) // return undef;
        Math::GMPz::Rmpz_sgn($n) || return undef;

        _set_int(Math::GMPz::Rmpz_scan1($n, 0));
    }

    sub fusc {
        my ($n) = @_;

        $n = _any2mpz($$n) // goto &nan;
        Math::GMPz::Rmpz_sgn($n) >= 0 or goto &nan;

        if (Math::GMPz::Rmpz_even_p($n)) {
            $n = Math::GMPz::Rmpz_init_set($n);    # copy
            Math::GMPz::Rmpz_remove($n, $n, $TWO);
        }

        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {
            $n = Math::GMPz::Rmpz_get_ui($n);

            my ($x, $y) = (1, 0);

            for (; $n > 0 ; $n >>= 1) {
                ($n & 1)
                  ? ($y += $x)
                  : ($x += $y);
            }

            return _set_int($y);
        }

        state $x = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_set_ui($x, 1);

        my $y = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $i (0 .. Math::GMPz::Rmpz_sizeinbase($n, 2) - 1) {
            if (Math::GMPz::Rmpz_tstbit($n, $i)) {
                Math::GMPz::Rmpz_add($y, $y, $x);
            }
            else {
                Math::GMPz::Rmpz_add($x, $x, $y);
            }
        }

        bless \$y;
    }

    sub __lgrt__ {
        my ($c) = @_;

        $PREC = CORE::int($PREC) if ref($PREC);

        my $p = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_str($p, '1e-' . CORE::int($PREC >> 2), 10, $ROUND);

        goto(ref($c) =~ tr/:/_/rs);

      Math_MPFR: {

            # Return a complex number for x < e^(-1/e)
            if (Math::MPFR::Rmpfr_cmp_d($c, CORE::exp(-1 / CORE::exp(1))) < 0) {
                $c = _mpfr2mpc($c);
                goto Math_MPC;
            }

            my $r = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_log($r, $c, $ROUND);

            Math::MPFR::Rmpfr_set_ui((my $x = Math::MPFR::Rmpfr_init2($PREC)), 1, $ROUND);
            Math::MPFR::Rmpfr_set_ui((my $y = Math::MPFR::Rmpfr_init2($PREC)), 0, $ROUND);

            my $count = 0;
            my $tmp   = Math::MPFR::Rmpfr_init2($PREC);

            while (1) {
                Math::MPFR::Rmpfr_sub($tmp, $x, $y, $ROUND);
                Math::MPFR::Rmpfr_cmpabs($tmp, $p) <= 0 and last;

                Math::MPFR::Rmpfr_set($y, $x, $ROUND);

                Math::MPFR::Rmpfr_log($tmp, $x, $ROUND);
                Math::MPFR::Rmpfr_add_ui($tmp, $tmp, 1, $ROUND);

                Math::MPFR::Rmpfr_add($x, $x, $r, $ROUND);
                Math::MPFR::Rmpfr_div($x, $x, $tmp, $ROUND);
                last if ++$count > $PREC;
            }

            return $x;
        }

      Math_MPC: {
            my $d = Math::MPC::Rmpc_init2($PREC);
            Math::MPC::Rmpc_log($d, $c, $ROUND);

            my $x = Math::MPC::Rmpc_init2($PREC);
            Math::MPC::Rmpc_sqrt($x, $c, $ROUND);
            Math::MPC::Rmpc_add_ui($x, $x, 1, $ROUND);
            Math::MPC::Rmpc_log($x, $x, $ROUND);

            my $y = Math::MPC::Rmpc_init2($PREC);
            Math::MPC::Rmpc_set_ui($y, 0, $ROUND);

            my $tmp = Math::MPC::Rmpc_init2($PREC);
            my $abs = Math::MPFR::Rmpfr_init2($PREC);

            my $count = 0;
            while (1) {
                Math::MPC::Rmpc_sub($tmp, $x, $y, $ROUND);

                Math::MPC::Rmpc_abs($abs, $tmp, $ROUND);
                Math::MPFR::Rmpfr_cmp($abs, $p) <= 0 and last;

                Math::MPC::Rmpc_set($y, $x, $ROUND);

                Math::MPC::Rmpc_log($tmp, $x, $ROUND);
                Math::MPC::Rmpc_add_ui($tmp, $tmp, 1, $ROUND);

                Math::MPC::Rmpc_add($x, $x, $d, $ROUND);
                Math::MPC::Rmpc_div($x, $x, $tmp, $ROUND);
                last if ++$count > $PREC;
            }

            return $x;
        }
    }

    sub lgrt {
        my ($x) = @_;
        bless \__lgrt__(_any2mpfr_mpc($$x));
    }

    sub __LambertW__ {
        my ($x) = @_;

        $PREC = CORE::int($PREC) if ref($PREC);

        my $p = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_str($p, '1e-' . CORE::int($PREC >> 2), 10, $ROUND);

        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {

            # Return a complex number for x < -1/e
            if (Math::MPFR::Rmpfr_cmp_d($x, -1 / CORE::exp(1)) < 0) {
                $x = _mpfr2mpc($x);
                goto Math_MPC;
            }

            Math::MPFR::Rmpfr_set_ui((my $r = Math::MPFR::Rmpfr_init2($PREC)), 1, $ROUND);
            Math::MPFR::Rmpfr_set_ui((my $y = Math::MPFR::Rmpfr_init2($PREC)), 0, $ROUND);

            my $count = 0;
            my $tmp   = Math::MPFR::Rmpfr_init2($PREC);

            while (1) {
                Math::MPFR::Rmpfr_sub($tmp, $r, $y, $ROUND);
                Math::MPFR::Rmpfr_cmpabs($tmp, $p) <= 0 and last;

                Math::MPFR::Rmpfr_set($y, $r, $ROUND);

                Math::MPFR::Rmpfr_log($tmp, $r, $ROUND);
                Math::MPFR::Rmpfr_add_ui($tmp, $tmp, 1, $ROUND);

                Math::MPFR::Rmpfr_add($r, $r, $x, $ROUND);
                Math::MPFR::Rmpfr_div($r, $r, $tmp, $ROUND);
                last if ++$count > $PREC;
            }

            Math::MPFR::Rmpfr_log($r, $r, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2($PREC);
            Math::MPC::Rmpc_sqrt($r, $x, $ROUND);
            Math::MPC::Rmpc_add_ui($r, $r, 1, $ROUND);

            my $y = Math::MPC::Rmpc_init2($PREC);
            Math::MPC::Rmpc_set_ui($y, 0, $ROUND);

            my $tmp = Math::MPC::Rmpc_init2($PREC);
            my $abs = Math::MPFR::Rmpfr_init2($PREC);

            my $count = 0;
            while (1) {
                Math::MPC::Rmpc_sub($tmp, $r, $y, $ROUND);

                Math::MPC::Rmpc_abs($abs, $tmp, $ROUND);
                Math::MPFR::Rmpfr_cmp($abs, $p) <= 0 and last;

                Math::MPC::Rmpc_set($y, $r, $ROUND);

                Math::MPC::Rmpc_log($tmp, $r, $ROUND);
                Math::MPC::Rmpc_add_ui($tmp, $tmp, 1, $ROUND);

                Math::MPC::Rmpc_add($r, $r, $x, $ROUND);
                Math::MPC::Rmpc_div($r, $r, $tmp, $ROUND);
                last if ++$count > $PREC;
            }

            Math::MPC::Rmpc_log($r, $r, $ROUND);
            return $r;
        }
    }

    sub lambert_w {
        my ($x) = @_;
        bless \__LambertW__(_any2mpfr_mpc($$x));
    }

    *LambertW = \&lambert_w;

    sub __exp__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_exp($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_exp($r, $x, $ROUND);
            return $r;
        }
    }

    sub exp {
        my ($x, $y) = @_;

        if (defined($y)) {
            _valid(\$y);
            return bless \__pow__(_any2mpfr_mpc($$x), _any2mpfr_mpc($$y));
        }

        bless \__exp__(_any2mpfr_mpc($$x));
    }

    sub exp2 {
        my ($x) = @_;
        bless \__pow__($TWO, $$x);
    }

    sub exp10 {
        my ($x) = @_;
        bless \__pow__($TEN, $$x);
    }

    #
    ## sin / sinh / asin / asinh
    #

    sub __sin__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_sin($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_sin($r, $x, $ROUND);
            return $r;
        }
    }

    sub sin {
        my ($x) = @_;
        bless \__sin__(_any2mpfr_mpc($$x));
    }

    sub __sinh__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_sinh($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_sinh($r, $x, $ROUND);
            return $r;
        }
    }

    sub sinh {
        my ($x) = @_;
        bless \__sinh__(_any2mpfr_mpc($$x));
    }

    sub __asin__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {

            # Return a complex number for x < -1 or x > 1
            if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
                or Math::MPFR::Rmpfr_cmp_si($x, -1) < 0) {
                my $r = _mpfr2mpc($x);
                Math::MPC::Rmpc_asin($r, $r, $ROUND);
                return $r;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_asin($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_asin($r, $x, $ROUND);
            return $r;
        }
    }

    sub asin {
        my ($x) = @_;
        bless \__asin__(_any2mpfr_mpc($$x));
    }

    sub __asinh__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_asinh($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_asinh($r, $x, $ROUND);
            return $r;
        }
    }

    sub asinh {
        my ($x) = @_;
        bless \__asinh__(_any2mpfr_mpc($$x));
    }

    #
    ## cos / cosh / acos / acosh
    #

    sub __cos__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_cos($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_cos($r, $x, $ROUND);
            return $r;
        }
    }

    sub cos {
        my ($x) = @_;
        bless \__cos__(_any2mpfr_mpc($$x));
    }

    sub __cosh__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_cosh($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_cosh($r, $x, $ROUND);
            return $r;
        }
    }

    sub cosh {
        my ($x) = @_;
        bless \__cosh__(_any2mpfr_mpc($$x));
    }

    sub __acos__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {

            # Return a complex number for x < -1 or x > 1
            if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
                or Math::MPFR::Rmpfr_cmp_si($x, -1) < 0) {
                my $r = _mpfr2mpc($x);
                Math::MPC::Rmpc_acos($r, $r, $ROUND);
                return $r;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_acos($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_acos($r, $x, $ROUND);
            return $r;
        }
    }

    sub acos {
        my ($x) = @_;
        bless \__acos__(_any2mpfr_mpc($$x));
    }

    sub __acosh__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {

            # Return a complex number for x < 1
            if (Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0) {
                my $r = _mpfr2mpc($x);
                Math::MPC::Rmpc_acosh($r, $r, $ROUND);
                return $r;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_acosh($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_acosh($r, $x, $ROUND);
            return $r;
        }
    }

    sub acosh {
        my ($x) = @_;
        bless \__acosh__(_any2mpfr_mpc($$x));
    }

    #
    ## tan / tanh / atan / atanh
    #

    sub __tan__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_tan($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_tan($r, $x, $ROUND);
            return $r;
        }
    }

    sub tan {
        my ($x) = @_;
        bless \__tan__(_any2mpfr_mpc($$x));
    }

    sub __tanh__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_tanh($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_tanh($r, $x, $ROUND);
            return $r;
        }
    }

    sub tanh {
        my ($x) = @_;
        bless \__tanh__(_any2mpfr_mpc($$x));
    }

    sub __atan__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_atan($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_atan($r, $x, $ROUND);
            return $r;
        }
    }

    sub atan {
        my ($x) = @_;
        bless \__atan__(_any2mpfr_mpc($$x));
    }

    sub __atanh__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {

            # Return a complex number for x < -1 or x > 1
            if (   Math::MPFR::Rmpfr_cmp_ui($x, +1) > 0
                or Math::MPFR::Rmpfr_cmp_si($x, -1) < 0) {
                my $r = _mpfr2mpc($x);
                Math::MPC::Rmpc_atanh($r, $r, $ROUND);
                return $r;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_atanh($r, $x, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_atanh($r, $x, $ROUND);
            return $r;
        }
    }

    sub atanh {
        my ($x) = @_;
        bless \__atanh__(_any2mpfr_mpc($$x));
    }

    sub __atan2__ {
        my ($x, $y) = @_;
        goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

      Math_MPFR__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_atan2($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_MPC: {
            $x = _mpfr2mpc($x);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_MPFR: {
            $y = _mpfr2mpc($y);
            goto Math_MPC__Math_MPC;
        }

        #
        ## atan2(x, y) = -i * log((y + x*i) / sqrt(x^2 + y^2))
        #
      Math_MPC__Math_MPC: {
            my $r = Math::MPC::Rmpc_init2($PREC);

            Math::MPC::Rmpc_mul_i($r, $x, 1, $ROUND);
            Math::MPC::Rmpc_add($r, $r, $y, $ROUND);

            my $t1 = Math::MPC::Rmpc_init2($PREC);
            my $t2 = Math::MPC::Rmpc_init2($PREC);

            Math::MPC::Rmpc_sqr($t1, $x, $ROUND);
            Math::MPC::Rmpc_sqr($t2, $y, $ROUND);
            Math::MPC::Rmpc_add($t1, $t1, $t2, $ROUND);
            Math::MPC::Rmpc_sqrt($t1, $t1, $ROUND);

            Math::MPC::Rmpc_div($r, $r, $t1, $ROUND);
            Math::MPC::Rmpc_log($r, $r, $ROUND);
            Math::MPC::Rmpc_mul_i($r, $r, -1, $ROUND);

            return $r;
        }
    }

    sub atan2 {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__atan2__(_any2mpfr_mpc($$x), _any2mpfr_mpc($$y));
    }

    #
    ## sec / sech / asec / asech
    #

    sub __sec__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_sec($r, $x, $ROUND);
            return $r;
        }

        # sec(x) = 1/cos(x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_cos($r, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
            return $r;
        }
    }

    sub sec {
        my ($x) = @_;
        bless \__sec__(_any2mpfr_mpc($$x));
    }

    sub __sech__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_sech($r, $x, $ROUND);
            return $r;
        }

        # sech(x) = 1/cosh(x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_cosh($r, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
            return $r;
        }
    }

    sub sech {
        my ($x) = @_;
        bless \__sech__(_any2mpfr_mpc($$x));
    }

    sub __asec__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

        # asec(x) = acos(1/x)
      Math_MPFR: {

            # Return a complex number for x > -1 and x < 1
            if (    Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0
                and Math::MPFR::Rmpfr_cmp_si($x, -1) > 0) {
                $x = _mpfr2mpc($x);
                goto Math_MPC;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_acos($r, $r, $ROUND);
            return $r;
        }

        # asec(x) = acos(1/x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
            Math::MPC::Rmpc_acos($r, $r, $ROUND);
            return $r;
        }
    }

    sub asec {
        my ($x) = @_;
        bless \__asec__(_any2mpfr_mpc($$x));
    }

    sub __asech__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

        # asech(x) = acosh(1/x)
      Math_MPFR: {

            # Return a complex number for x < 0 or x > 1
            if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
                or Math::MPFR::Rmpfr_cmp_ui($x, 0) < 0) {
                $x = _mpfr2mpc($x);
                goto Math_MPC;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_acosh($r, $r, $ROUND);
            return $r;
        }

        # asech(x) = acosh(1/x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
            Math::MPC::Rmpc_acosh($r, $r, $ROUND);
            return $r;
        }
    }

    sub asech {
        my ($x) = @_;
        bless \__asech__(_any2mpfr_mpc($$x));
    }

    #
    ## csc / csch / acsc / acsch
    #

    sub __csc__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_csc($r, $x, $ROUND);
            return $r;
        }

        # csc(x) = 1/sin(x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_sin($r, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
            return $r;
        }
    }

    sub csc {
        my ($x) = @_;
        bless \__csc__(_any2mpfr_mpc($$x));
    }

    sub __csch__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_csch($r, $x, $ROUND);
            return $r;
        }

        # csch(x) = 1/sinh(x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_sinh($r, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
            return $r;
        }
    }

    sub csch {
        my ($x) = @_;
        bless \__csch__(_any2mpfr_mpc($$x));
    }

    sub __acsc__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

        # acsc(x) = asin(1/x)
      Math_MPFR: {

            # Return a complex number for x > -1 and x < 1
            if (    Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0
                and Math::MPFR::Rmpfr_cmp_si($x, -1) > 0) {
                $x = _mpfr2mpc($x);
                goto Math_MPC;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_asin($r, $r, $ROUND);
            return $r;
        }

        # acsc(x) = asin(1/x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
            Math::MPC::Rmpc_asin($r, $r, $ROUND);
            return $r;
        }
    }

    sub acsc {
        my ($x) = @_;
        bless \__acsc__(_any2mpfr_mpc($$x));
    }

    sub __acsch__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

        # acsch(x) = asinh(1/x)
      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_asinh($r, $r, $ROUND);
            return $r;
        }

        # acsch(x) = asinh(1/x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
            Math::MPC::Rmpc_asinh($r, $r, $ROUND);
            return $r;
        }
    }

    sub acsch {
        my ($x) = @_;
        bless \__acsch__(_any2mpfr_mpc($$x));
    }

    #
    ## cot / coth / acot / acoth
    #

    sub __cot__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_cot($r, $x, $ROUND);
            return $r;
        }

        # cot(x) = 1/tan(x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_tan($r, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
            return $r;
        }
    }

    sub cot {
        my ($x) = @_;
        bless \__cot__(_any2mpfr_mpc($$x));
    }

    sub __coth__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_coth($r, $x, $ROUND);
            return $r;
        }

        # coth(x) = 1/tanh(x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_tanh($r, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
            return $r;
        }
    }

    sub coth {
        my ($x) = @_;
        bless \__coth__(_any2mpfr_mpc($$x));
    }

    sub __acot__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

        # acot(x) = atan(1/x)
      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_atan($r, $r, $ROUND);
            return $r;
        }

        # acot(x) = atan(1/x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
            Math::MPC::Rmpc_atan($r, $r, $ROUND);
            return $r;
        }
    }

    sub acot {
        my ($x) = @_;
        bless \__acot__(_any2mpfr_mpc($$x));
    }

    sub __acoth__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

        # acoth(x) = atanh(1/x)
      Math_MPFR: {

            # Return a complex number for x > -1 and x < 1
            if (    Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0
                and Math::MPFR::Rmpfr_cmp_si($x, -1) > 0) {
                $x = _mpfr2mpc($x);
                goto Math_MPC;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_atanh($r, $r, $ROUND);
            return $r;
        }

        # acoth(x) = atanh(1/x)
      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
            Math::MPC::Rmpc_atanh($r, $r, $ROUND);
            return $r;
        }
    }

    sub acoth {
        my ($x) = @_;
        bless \__acoth__(_any2mpfr_mpc($$x));
    }

    sub __cis__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_ui_fr($r, 0, $x, $ROUND);
            Math::MPC::Rmpc_exp($r, $r, $ROUND);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_mul_i($r, $x, 1, $ROUND);
            Math::MPC::Rmpc_exp($r, $r, $ROUND);
            return $r;
        }
    }

    sub cis {
        my ($x) = @_;
        bless \__cis__(_any2mpfr_mpc($$x));
    }

    sub __sin_cos__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $cos = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $sin = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPFR::Rmpfr_sin_cos($sin, $cos, $x, $ROUND);

            return ($sin, $cos);
        }

      Math_MPC: {
            my $cos = Math::MPC::Rmpc_init2(CORE::int($PREC));
            my $sin = Math::MPC::Rmpc_init2(CORE::int($PREC));

            Math::MPC::Rmpc_sin_cos($sin, $cos, $x, $ROUND, $ROUND);

            return ($sin, $cos);
        }
    }

    sub sin_cos {
        my ($x) = @_;
        my ($sin, $cos) = __sin_cos__(_any2mpfr_mpc($$x));
        ((bless \$sin), (bless \$cos));
    }

    #
    ## Special functions
    #

    sub __agm__ {
        my ($x, $y) = @_;
        goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

      Math_MPFR__Math_MPFR: {
            if (   Math::MPFR::Rmpfr_sgn($x) < 0
                or Math::MPFR::Rmpfr_sgn($y) < 0) {
                ($x, $y) = (_mpfr2mpc($x), _mpfr2mpc($y));
                goto Math_MPC__Math_MPC;
            }

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_agm($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_MPC: {

            # agm(0,  x) = 0
            Math::MPC::Rmpc_cmp_si_si($x, 0, 0) || return $x;

            # agm(x, 0) = 0
            Math::MPC::Rmpc_cmp_si_si($y, 0, 0) || return $y;

            $PREC = CORE::int($PREC) if ref($PREC);

            my $a0 = Math::MPC::Rmpc_init2($PREC);
            my $g0 = Math::MPC::Rmpc_init2($PREC);

            my $a1 = Math::MPC::Rmpc_init2($PREC);
            my $g1 = Math::MPC::Rmpc_init2($PREC);

            my $t = Math::MPC::Rmpc_init2($PREC);

            Math::MPC::Rmpc_set($a0, $x, $ROUND);
            Math::MPC::Rmpc_set($g0, $y, $ROUND);

            my $count = 0;
            {
                Math::MPC::Rmpc_add($a1, $a0, $g0, $ROUND);
                Math::MPC::Rmpc_div_2ui($a1, $a1, 1, $ROUND);

                Math::MPC::Rmpc_mul($g1, $a0, $g0, $ROUND);
                Math::MPC::Rmpc_add($t, $a0, $g0, $ROUND);
                Math::MPC::Rmpc_sqr($t, $t, $ROUND);
                Math::MPC::Rmpc_cmp_si_si($t, 0, 0) || return $t;
                Math::MPC::Rmpc_div($g1, $g1, $t, $ROUND);
                Math::MPC::Rmpc_sqrt($g1, $g1, $ROUND);
                Math::MPC::Rmpc_add($t, $a0, $g0, $ROUND);
                Math::MPC::Rmpc_mul($g1, $g1, $t, $ROUND);

                if (Math::MPC::Rmpc_cmp($a0, $a1) and ++$count < $PREC) {
                    Math::MPC::Rmpc_set($a0, $a1, $ROUND);
                    Math::MPC::Rmpc_set($g0, $g1, $ROUND);
                    redo;
                }
            }

            return $g0;
        }

      Math_MPFR__Math_MPC: {
            $x = _mpfr2mpc($x);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_MPFR: {
            $y = _mpfr2mpc($y);
            goto Math_MPC__Math_MPC;
        }
    }

    sub agm {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__agm__(_any2mpfr_mpc($$x), _any2mpfr_mpc($$y));
    }

    sub __hypot__ {
        my ($x, $y) = @_;

        # hypot(x, y) = sqrt(x^2 + y^2)

        goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

      Math_MPFR__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_hypot($r, $x, $y, $ROUND);
            return $r;
        }

      Math_MPFR__Math_MPC: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($r, $y, $ROUND);
            Math::MPFR::Rmpfr_hypot($r, $r, $x, $ROUND);
            return $r;
        }

      Math_MPC__Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($r, $x, $ROUND);
            Math::MPFR::Rmpfr_hypot($r, $r, $y, $ROUND);
            return $r;
        }

      Math_MPC__Math_MPC: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($r, $x, $ROUND);
            my $t = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($t, $y, $ROUND);
            Math::MPFR::Rmpfr_hypot($r, $r, $t, $ROUND);
            return $r;
        }
    }

    sub hypot {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__hypot__(_any2mpfr_mpc($$x), _any2mpfr_mpc($$y));
    }

    sub gamma {
        my ($x) = @_;
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_gamma($r, _any2mpfr($$x), $ROUND);
        bless \$r;
    }

    *Γ = \&gamma;

    sub lngamma {
        my ($x) = @_;
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_lngamma($r, _any2mpfr($$x), $ROUND);
        bless \$r;
    }

    *gamma_log = \&lngamma;

    sub lgamma {
        my ($x) = @_;
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_lgamma($r, _any2mpfr($$x), $ROUND);
        bless \$r;
    }

    *gamma_abs_log = \&lgamma;

    sub digamma {
        my ($x) = @_;
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_digamma($r, _any2mpfr($$x), $ROUND);
        bless \$r;
    }

    *Ψ = \&digamma;

    #
    ## beta(x, y) = gamma(x)*gamma(y) / gamma(x+y)
    #
    sub beta {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpfr($$x);
        $y = _any2mpfr($$y);

        state $has_beta = Math::MPFR::MPFR_VERSION_MAJOR() >= 4;

        if ($has_beta) {    # available since mpfr-4.0.0
            my $r = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_beta($r, $x, $y, $ROUND);
            return bless \$r;
        }

        my $t1 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));    # gamma(x+y)
        my $t2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));    # gamma(y)

        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPFR::Rmpfr_add($t1, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_gamma($t1, $t1, $ROUND);
        Math::MPFR::Rmpfr_gamma($r,  $x,  $ROUND);
        Math::MPFR::Rmpfr_gamma($t2, $y,  $ROUND);
        Math::MPFR::Rmpfr_mul($r, $r, $t2, $ROUND);
        Math::MPFR::Rmpfr_div($r, $r, $t1, $ROUND);

        bless \$r;
    }

    #
    ## eta(s) = (1 - 2^(1-s)) * zeta(s)
    #
    sub eta {
        my ($x) = @_;

        $x = _any2mpfr($$x);

        my $x_is_int = Math::MPFR::Rmpfr_integer_p($x);
        my $r        = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        # Special case for eta(1) = log(2)
        if ($x_is_int and Math::MPFR::Rmpfr_cmp_ui($x, 1) == 0) {
            Math::MPFR::Rmpfr_const_log2($r, $ROUND);
            return bless \$r;
        }

        my $t = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPFR::Rmpfr_ui_sub($r, 1, $x, $ROUND);
        Math::MPFR::Rmpfr_ui_pow($r, 2, $r, $ROUND);
        Math::MPFR::Rmpfr_ui_sub($r, 1, $r, $ROUND);

        if ($x_is_int and Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
            Math::MPFR::Rmpfr_zeta_ui($t, Math::MPFR::Rmpfr_get_ui($x, $ROUND), $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_zeta($t, $x, $ROUND);
        }

        Math::MPFR::Rmpfr_mul($r, $r, $t, $ROUND);

        bless \$r;
    }

    *η = \&eta;

    sub zeta {
        my ($x) = @_;
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        my $f = _any2mpfr($$x);
        if (    Math::MPFR::Rmpfr_integer_p($f)
            and Math::MPFR::Rmpfr_fits_ulong_p($f, $ROUND)) {
            Math::MPFR::Rmpfr_zeta_ui($r, Math::MPFR::Rmpfr_get_ui($f, $ROUND), $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_zeta($r, $f, $ROUND);
        }
        bless \$r;
    }

    *ζ = \&zeta;

    sub _secant_numbers {
        my ($n) = @_;

        state @cache;

        if ($n <= $#cache) {
            return @cache;
        }

        $n <<= 1 if ($n <= 512);

        my @S = (Math::GMPz::Rmpz_init_set_ui(1));

        foreach my $k (1 .. $n) {
            Math::GMPz::Rmpz_mul_ui($S[$k] = Math::GMPz::Rmpz_init(), $S[$k - 1], $k);
        }

        foreach my $k (1 .. $n) {
            foreach my $j ($k + 1 .. $n) {
                Math::GMPz::Rmpz_addmul_ui($S[$j], $S[$j - 1], ($j - $k) * ($j - $k + 2));
            }
        }

        push @cache, @S[@cache .. (@S <= 1024 ? $#S : 1024)];

        return @S;
    }

    sub _tangent_numbers {
        my ($n) = @_;

        state @cache;

        if ($n <= $#cache) {
            return @cache;
        }

        $n <<= 1 if ($n <= 512);

        my @T = (Math::GMPz::Rmpz_init_set_ui(1));

        foreach my $k (1 .. $n) {
            Math::GMPz::Rmpz_mul_ui($T[$k] = Math::GMPz::Rmpz_init(), $T[$k - 1], $k);
        }

        foreach my $k (1 .. $n) {
            foreach my $j ($k .. $n) {
                Math::GMPz::Rmpz_mul_ui($T[$j], $T[$j], $j - $k + 2);
                Math::GMPz::Rmpz_addmul_ui($T[$j], $T[$j - 1], $j - $k);
            }
        }

        push @cache, @T[@cache .. (@T <= 1024 ? $#T : 1024)];

        return @T;
    }

    sub _bernoulli_numbers {
        my ($n) = @_;

        $n = ($n >> 1) + 1;

        state @cache;

        if ($n <= $#cache) {
            return @cache;
        }

        my @B;
        my @T = _tangent_numbers($n);

        my $t = Math::GMPz::Rmpz_init();

        foreach my $k (scalar(@cache) .. 2 * @T) {

            $k % 2 == 0 or $k == 1 or next;

            my $q = Math::GMPq::Rmpq_init();

            if ($k == 0) {
                Math::GMPq::Rmpq_set_ui($q, 1, 1);
                $B[$k] = $q;
                next;
            }

            if ($k == 1) {
                Math::GMPq::Rmpq_set_si($q, -1, 2);
                $B[$k] = $q;
                next;
            }

            # T_k
            Math::GMPz::Rmpz_mul_ui($t, $T[($k >> 1) - 1], $k);
            Math::GMPz::Rmpz_neg($t, $t) if ((($k >> 1) - 1) & 1);
            Math::GMPq::Rmpq_set_z($q, $t);

            # (2^k - 1) * 2^k
            Math::GMPz::Rmpz_set_ui($t, 0);
            Math::GMPz::Rmpz_setbit($t, $k);
            Math::GMPz::Rmpz_sub_ui($t, $t, 1);
            Math::GMPz::Rmpz_mul_2exp($t, $t, $k);

            # B_k = q
            Math::GMPq::Rmpq_div_z($q, $q, $t);

            $B[($k >> 1) + 1] = $q;
        }

        push @cache, @B[@cache .. (@B <= 1024 ? $#B : 1024)];

        return (@cache, (@B > @cache ? @B[@cache .. $#B] : ()));
    }

    sub bernoulli_polynomial {
        my ($n, $x) = @_;

        #
        ## B_n(x) = Sum_{k=0..n} binomial(n, k) * bernoulli(n-k) * x^k
        #

        my $polynomial = 0;

        if (defined($x) and ref($x) ne 'Sidef::Types::Number::Polynomial') {
            _valid(\$x);
            $x = $$x;
        }
        else {
            $polynomial = 1;
            $x //= Sidef::Types::Number::Polynomial->new(1 => ONE);
        }

        $n = _any2ui($$n) // goto &nan;

        my @B = _bernoulli_numbers($n);

        my $u = $n + 1;
        my $z = Math::GMPz::Rmpz_init();
        my $q = Math::GMPq::Rmpq_init();

        my @terms;

        foreach my $k (0 .. $n) {

            --$u & 1 and $u > 1 and next;    # B_n = 0 for odd n > 1

            Math::GMPz::Rmpz_bin_uiui($z, $n, $k);
            Math::GMPq::Rmpq_mul_z($q, $u <= 1 ? $B[$u] : $B[($u >> 1) + 1], $z);

            if ($polynomial) {
                push @terms, $x->pow(_set_int($k))->mul(bless \$q);
            }
            else {
                push @terms, __mul__(($k ? __pow__($x, $k) : $ONE), $q);
            }
        }

        $polynomial
          ? _binsplit([CORE::reverse @terms], \&Sidef::Types::Number::Polynomial::add)
          : (bless \_binsplit([CORE::reverse @terms], \&__add__));
    }

    sub bernfrac {
        my ($n, $x) = @_;

        defined($x) && goto &bernoulli_polynomial;

        $n = _any2ui($$n) // goto &nan;

        $n == 0 and return ONE;
        $n > 1 and $n % 2 and return ZERO;    # Bn=0 for odd n>1

        if ($n > 1 and $n < 512) {
            return bless \((_bernoulli_numbers($n))[($n >> 1) + 1]);
        }

        # Using bernfrac() from `Math::Prime::Util::GMP`
        my ($num, $den) = Math::Prime::Util::GMP::bernfrac($n);

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_str($q, "$num/$den", 10);
        bless \$q;
    }

    *bern             = \&bernfrac;
    *bernoulli        = \&bernfrac;
    *Bernoulli        = \&bernfrac;
    *bernoulli_number = \&bernfrac;

    sub faulhaber_polynomial {
        my ($n, $x) = @_;

        if (defined($x) and ref($x) ne 'Sidef::Types::Number::Polynomial') {
            _valid(\$x);
        }
        else {
            $x //= Sidef::Types::Number::Polynomial->new(1 => ONE);
        }

        $n = $n->inc;
        $x = $x->inc;

        $n->bernoulli_polynomial($x)->sub($n->bernfrac)->div($n);
    }

    sub euler_polynomial {
        my ($n, $x) = @_;

        #
        ## E_n(x) = Sum_{k=0..n} binomial(n, n-k) * euler_number(n-k) / 2^(n-k) * (x - 1/2)^k
        #

        my $polynomial = 0;

        if (defined($x) and ref($x) ne 'Sidef::Types::Number::Polynomial') {
            _valid(\$x);
            $x = $$x;
            $x = __dec__(__add__($x, $x));    # x = 2*x - 1
        }
        else {
            $polynomial = 1;
            $x //= Sidef::Types::Number::Polynomial->new(1 => ONE);
            $x = $x->add($x)->dec;
        }

        $n = _any2ui($$n) // goto &nan;

        my @S = _secant_numbers($n >> 1);

        my $u = $n + 1;
        my $z = Math::GMPz::Rmpz_init();

        my @terms;

        foreach my $k (0 .. $n) {
            --$u & 1 and next;    # E_n = 0 for all odd n

            Math::GMPz::Rmpz_bin_uiui($z, $n, $u);
            Math::GMPz::Rmpz_mul($z, $z, $S[$u >> 1]);
            Math::GMPz::Rmpz_neg($z, $z) if (($u >> 1) & 1);

            if ($polynomial) {
                push @terms, $x->pow(_set_int($k))->mul(bless \$z);
            }
            else {
                push @terms, ($k ? __mul__(__pow__($x, $k), $z) : Math::GMPz::Rmpz_init_set($z));
            }
        }

        if ($polynomial) {
            my $sum = _binsplit(\@terms, \&Sidef::Types::Number::Polynomial::add);
            Math::GMPz::Rmpz_set_ui($z, 0);
            Math::GMPz::Rmpz_setbit($z, $n);
            return $sum->div(bless \$z);
        }

        my $sum = _binsplit(\@terms, \&__add__);
        Math::GMPz::Rmpz_set_ui($z, 0);
        Math::GMPz::Rmpz_setbit($z, $n);
        bless \__div__($sum, $z);
    }

    sub euler {
        my ($n, $x) = @_;

        ref($n) || goto &EulerGamma;
        defined($x) && goto &euler_polynomial;

        $n = _any2ui($$n) // goto &nan;

        $n & 1 and return ZERO;    # E_n = 0 for all odd indices

        my $e = Math::GMPz::Rmpz_init_set((_secant_numbers($n >> 1))[$n >> 1]);
        Math::GMPz::Rmpz_neg($e, $e) if (($n >> 1) & 1);
        bless \$e;
    }

    *Euler        = \&euler;
    *euler_number = \&euler;

    sub secant_number {
        my ($n) = @_;

        $n = _any2ui($$n) // goto &nan;

        my @E = _secant_numbers($n);
        bless \Math::GMPz::Rmpz_init_set($E[$n]);
    }

    sub tangent_number {
        my ($n) = @_;

        #
        ## T_n = 2^(2*n) * (2^(2*n) - 1) * abs(bernoulli(2*n)) / (2*n)
        #

        $n = _any2ui($$n) // goto &nan;
        $n || return ZERO;
        $n <<= 1;

        my ($num, $den) = Math::Prime::Util::GMP::bernfrac($n);

        $num = Math::GMPz::Rmpz_init_set_str("$num", 10);
        $den = Math::GMPz::Rmpz_init_set_str("$den", 10);

        Math::GMPz::Rmpz_abs($num, $num) if !($n & 1);

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_setbit($r, $n);
        Math::GMPz::Rmpz_sub_ui($r, $r, 1);
        Math::GMPz::Rmpz_mul_2exp($r, $r, $n);
        Math::GMPz::Rmpz_mul($r, $r, $num);
        Math::GMPz::Rmpz_mul_ui($den, $den, $n);
        Math::GMPz::Rmpz_divexact($r, $r, $den);
        bless \$r;
    }

    # TODO: add support for an optional argument and return B_n(x)
    sub bernreal {
        my ($n) = @_;

        $n = _any2ui($$n) // goto &nan;

        # |B(n)| = zeta(n) * n! / 2^(n-1) / pi^n

        $n == 0 and return ONE;
        $n == 1 and return do { state $x = bless(\_str2obj('1/2')) };
        $n % 2  and return ZERO;                                        # Bn = 0 for odd n>1

        #local $PREC = CORE::int($n*CORE::log($n)+1);

        my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        my $p = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPFR::Rmpfr_zeta_ui($f, $n, $ROUND);                      # f = zeta(n)
        Math::MPFR::Rmpfr_set_ui($p, $n + 1, $ROUND);                   # p = n+1
        Math::MPFR::Rmpfr_gamma($p, $p, $ROUND);                        # p = gamma(p)

        Math::MPFR::Rmpfr_mul($f, $f, $p, $ROUND);                      # f = f * p

        Math::MPFR::Rmpfr_const_pi($p, $ROUND);                         # p = PI
        Math::MPFR::Rmpfr_pow_ui($p, $p, $n, $ROUND);                   # p = p^n

        Math::MPFR::Rmpfr_div_2ui($f, $f, $n - 1, $ROUND);              # f = f / 2^(n-1)

        Math::MPFR::Rmpfr_div($f, $f, $p, $ROUND);                      # f = f/p
        Math::MPFR::Rmpfr_neg($f, $f, $ROUND) if $n % 4 == 0;

        bless \$f;
    }

    # TODO: add support for an optional argument and return log(B_n(x))
    sub lnbernreal {
        my ($n) = @_;

        $n = _any2mpz($$n) // goto &nan;

        # log(|B(n)|) = (1 - n)*log(2) - n*log(π) + log(zeta(n)) + log(n!)

        (Math::GMPz::Rmpz_sgn($n) || return ZERO) < 0 and goto &nan;

        my $L = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_log2($L, $ROUND);

        if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0) {
            Math::MPFR::Rmpfr_neg($L, $L, $ROUND);
            return bless \$L;
        }

        Math::GMPz::Rmpz_odd_p($n) && goto &ninf;    # log(Bn) = -Inf for odd n>1

        my $pi = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_pi($pi, $ROUND);     # pi = π

        my $t = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_log($t, $pi, $ROUND);         # t = log(π)
        Math::MPFR::Rmpfr_mul_z($t, $t, $n, $ROUND);    # t = n*log(π)

        my $s = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_ui_sub($s, 1, $n);             # s = 1-n

        Math::MPFR::Rmpfr_mul_z($L, $L, $s, $ROUND);    # L = (1 - n)*log(2)
        Math::MPFR::Rmpfr_sub($L, $L, $t, $ROUND);      # L -= n*log(π)

        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {        # n is a native unsigned integer
            Math::MPFR::Rmpfr_zeta_ui($t, Math::GMPz::Rmpz_get_ui($n), $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_set_z($t, $n, $ROUND);    # t = n
            Math::MPFR::Rmpfr_zeta($t, $t, $ROUND);     # t = zeta(n)
        }

        Math::MPFR::Rmpfr_log($t, $t, $ROUND);          # t = log(zeta(n))
        Math::MPFR::Rmpfr_add($L, $L, $t, $ROUND);      # L += log(zeta(n))

        Math::GMPz::Rmpz_add_ui($s, $n, 1);             # s = n+1
        Math::MPFR::Rmpfr_set_z($t, $s, $ROUND);        # t = n+1
        Math::MPFR::Rmpfr_lngamma($t, $t, $ROUND);      # t = log(gamma(n+1)) = log(n!)

        Math::MPFR::Rmpfr_add($L, $L, $t, $ROUND);      # L += log(n!)

        # If 4|n, then B_n is negative; log(-Re(x)) = log(Re(x)) + π*i, for x>0
        if (Math::GMPz::Rmpz_divisible_2exp_p($n, 2)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_fr_fr($c, $L, $pi, $ROUND);
            return bless \$c;
        }

        bless \$L;
    }

    *lnbern        = \&lnbernreal;
    *bern_log      = \&lnbernreal;
    *bernoulli_log = \&lnbernreal;

    sub harmfrac {
        my ($n, $k) = @_;

        # Formula in terms of the Harmonic numbers, due to Conway and Guy (1996),
        # for computing the Harmonic numbers of the k-th order.
        if (defined($k)) {

            my $km1   = $k->dec;
            my $npkm1 = $n->add($km1);

            return $npkm1->binomial($km1)->mul($npkm1->harmfrac->sub($km1->harmfrac));
        }

        $n = _any2ui($$n) // goto &nan;
        $n || return ZERO();

        # Using harmfrac() from Math::Prime::Util::GMP
        my ($num, $den) = Math::Prime::Util::GMP::harmfrac($n);

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_str($q, "$num/$den", 10);
        bless \$q;
    }

    *harm            = \&harmfrac;
    *harmonic        = \&harmfrac;
    *harmonic_number = \&harmfrac;

    sub harmreal {
        my ($n, $k) = @_;

        # Formula in terms of the Harmonic numbers, due to Conway and Guy (1996),
        # for computing the Harmonic numbers of the k-th order.
        if (defined($k)) {

            my $km1   = $k->dec;
            my $npkm1 = $n->add($km1);

            return $npkm1->binomial($km1)->mul($npkm1->harmreal->sub($km1->harmreal));
        }

        $n = _any2mpfr($$n);

        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_add_ui($r, $n, 1, $ROUND);
        Math::MPFR::Rmpfr_digamma($r, $r, $ROUND);

        my $t = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_euler($t, $ROUND);
        Math::MPFR::Rmpfr_add($r, $r, $t, $ROUND);

        bless \$r;
    }

    sub erf {
        my ($x) = @_;
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_erf($r, _any2mpfr($$x), $ROUND);
        bless \$r;
    }

    sub erfc {
        my ($x) = @_;
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_erfc($r, _any2mpfr($$x), $ROUND);
        bless \$r;
    }

    sub bessel_j {
        my ($x, $n) = @_;

        $n = defined($n) ? do { _valid(\$n); __numify__($$n) } : 0;

        if ($n < LONG_MIN or $n > ULONG_MAX) {
            return ZERO;
        }

        $x = _any2mpfr($$x);
        $n = CORE::int($n);

        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        if ($n == 0) {
            Math::MPFR::Rmpfr_j0($r, $x, $ROUND);
        }
        elsif ($n == 1) {
            Math::MPFR::Rmpfr_j1($r, $x, $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_jn($r, $n, $x, $ROUND);
        }

        bless \$r;
    }

    *BesselJ = \&bessel_j;

    sub bessel_y {
        my ($x, $n) = @_;

        $n = defined($n) ? do { _valid(\$n); __numify__($$n) } : 0;

        if ($n < LONG_MIN or $n > ULONG_MAX) {
            if (__cmp__($$x, 0) < 0) {
                return nan();
            }
            return ($n < 0 ? inf() : ninf());
        }

        $x = _any2mpfr($$x);
        $n = CORE::int($n);

        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        if ($n == 0) {
            Math::MPFR::Rmpfr_y0($r, $x, $ROUND);
        }
        elsif ($n == 1) {
            Math::MPFR::Rmpfr_y1($r, $x, $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_yn($r, $n, $x, $ROUND);
        }

        bless \$r;
    }

    *BesselY = \&bessel_y;

    sub eint {
        my ($x) = @_;
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_eint($r, _any2mpfr($$x), $ROUND);
        bless \$r;
    }

    *ei = \&eint;
    *Ei = \&eint;

    sub ai {
        my ($x) = @_;
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_ai($r, _any2mpfr($$x), $ROUND);
        bless \$r;
    }

    *airy = \&ai;
    *Ai   = \&ai;

    sub li {
        my ($x) = @_;
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_log($r, _any2mpfr($$x), $ROUND);
        Math::MPFR::Rmpfr_eint($r, $r, $ROUND);
        bless \$r;
    }

    *Li = \&li;

    sub li2 {
        my ($x) = @_;
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_li2($r, _any2mpfr($$x), $ROUND);
        bless \$r;
    }

    *Li2 = \&li2;

    #
    ## Comparison and testing operations
    #

    sub __eq__ {
        my ($x, $y) = @_;

        goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

        #
        ## MPFR
        #
      Math_MPFR__Math_MPFR: {
            return Math::MPFR::Rmpfr_equal_p($x, $y);
        }

      Math_MPFR__Math_GMPz: {
            return (Math::MPFR::Rmpfr_integer_p($x) and Math::MPFR::Rmpfr_cmp_z($x, $y) == 0);
        }

      Math_MPFR__Math_GMPq: {
            return (Math::MPFR::Rmpfr_number_p($x) and Math::MPFR::Rmpfr_cmp_q($x, $y) == 0);
        }

      Math_MPFR__Math_MPC: {
            $x = _mpfr2mpc($x);
            goto Math_MPC__Math_MPC;
        }

      Math_MPFR__Scalar: {
            return (
                    Math::MPFR::Rmpfr_integer_p($x)
                      and (
                           ($y || return !Math::MPFR::Rmpfr_sgn($x)) < 0
                           ? Math::MPFR::Rmpfr_cmp_si($x, $y)
                           : Math::MPFR::Rmpfr_cmp_ui($x, $y)
                      ) == 0
                   );
        }

        #
        ## GMPq
        #
      Math_GMPq__Math_GMPq: {
            return Math::GMPq::Rmpq_equal($x, $y);
        }

      Math_GMPq__Math_GMPz: {
            return (Math::GMPq::Rmpq_integer_p($x) and Math::GMPq::Rmpq_cmp_z($x, $y) == 0);
        }

      Math_GMPq__Math_MPFR: {
            return (Math::MPFR::Rmpfr_number_p($y) and Math::MPFR::Rmpfr_cmp_q($y, $x) == 0);
        }

      Math_GMPq__Math_MPC: {
            $x = _mpq2mpc($x);
            goto Math_MPC__Math_MPC;
        }

      Math_GMPq__Scalar: {
            return (
                    Math::GMPq::Rmpq_integer_p($x)
                      and (
                           ($y || return !Math::GMPq::Rmpq_sgn($x)) < 0
                           ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
                           : Math::GMPq::Rmpq_cmp_ui($x, $y, 1)
                      ) == 0
                   );
        }

        #
        ## GMPz
        #
      Math_GMPz__Math_GMPz: {
            return (Math::GMPz::Rmpz_cmp($x, $y) == 0);
        }

      Math_GMPz__Math_GMPq: {
            return (Math::GMPq::Rmpq_integer_p($y) and Math::GMPq::Rmpq_cmp_z($y, $x) == 0);
        }

      Math_GMPz__Math_MPFR: {
            return (Math::MPFR::Rmpfr_integer_p($y) and Math::MPFR::Rmpfr_cmp_z($y, $x) == 0);
        }

      Math_GMPz__Math_MPC: {
            $x = _mpz2mpc($x);
            goto Math_MPC__Math_MPC;
        }

      Math_GMPz__Scalar: {
            return (
                    (
                     ($y || return !Math::GMPz::Rmpz_sgn($x)) < 0
                     ? Math::GMPz::Rmpz_cmp_si($x, $y)
                     : Math::GMPz::Rmpz_cmp_ui($x, $y)
                    ) == 0
                   );
        }

        #
        ## MPC
        #
      Math_MPC__Math_MPC: {
            my $f1 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $f2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($f1, $x);
            Math::MPC::RMPC_RE($f2, $y);

            Math::MPFR::Rmpfr_equal_p($f1, $f2) || return 0;

            Math::MPC::RMPC_IM($f1, $x);
            Math::MPC::RMPC_IM($f2, $y);

            return Math::MPFR::Rmpfr_equal_p($f1, $f2);
        }

      Math_MPC__Math_GMPz: {
            $y = _mpz2mpc($y);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_GMPq: {
            $y = _mpq2mpc($y);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_MPFR: {
            $y = _mpfr2mpc($y);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Scalar: {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_IM($f, $x);
            Math::MPFR::Rmpfr_zero_p($f) || return 0;
            Math::MPC::RMPC_RE($f, $x);
            $x = $f;
            goto Math_MPFR__Scalar;
        }
    }

    sub eq {
        my ($x, $y) = @_;

        ref($y) ne __PACKAGE__
          and return Sidef::Types::Bool::Bool::FALSE;

        __eq__($$x, $$y)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub __ne__ {
        my ($x, $y) = @_;

        goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

        #
        ## MPFR
        #
      Math_MPFR__Math_MPFR: {
            return !Math::MPFR::Rmpfr_equal_p($x, $y);
        }

      Math_MPFR__Math_GMPz: {
            return (!Math::MPFR::Rmpfr_integer_p($x) or Math::MPFR::Rmpfr_cmp_z($x, $y) != 0);
        }

      Math_MPFR__Math_GMPq: {
            return (!Math::MPFR::Rmpfr_number_p($x) or Math::MPFR::Rmpfr_cmp_q($x, $y) != 0);
        }

      Math_MPFR__Math_MPC: {
            $x = _mpfr2mpc($x);
            goto Math_MPC__Math_MPC;
        }

      Math_MPFR__Scalar: {
            return (
                    !Math::MPFR::Rmpfr_integer_p($x)
                      or (
                          ($y || return !!Math::MPFR::Rmpfr_sgn($x)) < 0
                          ? Math::MPFR::Rmpfr_cmp_si($x, $y)
                          : Math::MPFR::Rmpfr_cmp_ui($x, $y)
                      ) != 0
                   );
        }

        #
        ## GMPq
        #
      Math_GMPq__Math_GMPq: {
            return !Math::GMPq::Rmpq_equal($x, $y);
        }

      Math_GMPq__Math_GMPz: {
            return (!Math::GMPq::Rmpq_integer_p($x) or Math::GMPq::Rmpq_cmp_z($x, $y) != 0);
        }

      Math_GMPq__Math_MPFR: {
            return (!Math::MPFR::Rmpfr_number_p($y) or Math::MPFR::Rmpfr_cmp_q($y, $x) != 0);
        }

      Math_GMPq__Math_MPC: {
            $x = _mpq2mpc($x);
            goto Math_MPC__Math_MPC;
        }

      Math_GMPq__Scalar: {
            return (
                    !Math::GMPq::Rmpq_integer_p($x)
                      or (
                          ($y || return !!Math::GMPq::Rmpq_sgn($x)) < 0
                          ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
                          : Math::GMPq::Rmpq_cmp_ui($x, $y, 1)
                      ) != 0
                   );
        }

        #
        ## GMPz
        #
      Math_GMPz__Math_GMPz: {
            return (Math::GMPz::Rmpz_cmp($x, $y) != 0);
        }

      Math_GMPz__Math_GMPq: {
            return (!Math::GMPq::Rmpq_integer_p($y) or Math::GMPq::Rmpq_cmp_z($y, $x) != 0);
        }

      Math_GMPz__Math_MPFR: {
            return (!Math::MPFR::Rmpfr_integer_p($y) or Math::MPFR::Rmpfr_cmp_z($y, $x) != 0);
        }

      Math_GMPz__Math_MPC: {
            $x = _mpz2mpc($x);
            goto Math_MPC__Math_MPC;
        }

      Math_GMPz__Scalar: {
            return (
                    (
                     ($y || return !!Math::GMPz::Rmpz_sgn($x)) < 0
                     ? Math::GMPz::Rmpz_cmp_si($x, $y)
                     : Math::GMPz::Rmpz_cmp_ui($x, $y)
                    ) != 0
                   );
        }

        #
        ## MPC
        #
      Math_MPC__Math_MPC: {

            my $f1 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $f2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($f1, $x);
            Math::MPC::RMPC_RE($f2, $y);

            Math::MPFR::Rmpfr_equal_p($f1, $f2) || return 1;

            Math::MPC::RMPC_IM($f1, $x);
            Math::MPC::RMPC_IM($f2, $y);

            return !Math::MPFR::Rmpfr_equal_p($f1, $f2);
        }

      Math_MPC__Math_GMPz: {
            $y = _mpz2mpc($y);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_GMPq: {
            $y = _mpq2mpc($y);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_MPFR: {
            $y = _mpfr2mpc($y);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Scalar: {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_IM($f, $x);
            Math::MPFR::Rmpfr_zero_p($f) || return 1;
            Math::MPC::RMPC_RE($f, $x);
            $x = $f;
            goto Math_MPFR__Scalar;
        }
    }

    sub ne {
        my ($x, $y) = @_;

        ref($y) ne __PACKAGE__
          and return Sidef::Types::Bool::Bool::TRUE;

        __ne__($$x, $$y)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub __approx_cmp__ {
        my ($x, $y, $places, $equal) = @_;

        _valid(\$y);

        $x = $$x;
        $y = $$y;

        if (defined($places)) {
            _valid(\$places);
            $places = _any2si($$places) // return undef;
        }
        else {
            $places = -((CORE::int($PREC) >> 2) - 1);
        }

        if (   ref($x) eq 'Math::MPFR'
            or ref($y) eq 'Math::MPFR'
            or ref($x) eq 'Math::MPC'
            or ref($y) eq 'Math::MPC') {
            $x = _any2mpfr_mpc($x);
            $y = _any2mpfr_mpc($y);
        }

        $x = __round__($x, $places);
        $y = __round__($y, $places);

        $equal ? __eq__($x, $y) : __cmp__($x, $y);
    }

    sub approx_cmp {
        my ($x, $y, $places) = @_;
        ((__approx_cmp__($x, $y, $places) // return undef) || return ZERO) > 0 ? ONE : MONE;
    }

    sub approx_lt {
        my ($x, $y, $places) = @_;
        (__approx_cmp__($x, $y, $places) // return undef) < 0
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub approx_le {
        my ($x, $y, $places) = @_;
        (__approx_cmp__($x, $y, $places) // return undef) <= 0
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub approx_gt {
        my ($x, $y, $places) = @_;
        (__approx_cmp__($x, $y, $places) // return undef) > 0
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub approx_ge {
        my ($x, $y, $places) = @_;
        (__approx_cmp__($x, $y, $places) // return undef) >= 0
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub approx_eq {
        my ($x, $y, $places) = @_;
        (__approx_cmp__($x, $y, $places, 1) // return undef)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub approx_ne {
        my ($x, $y, $places) = @_;
        (__approx_cmp__($x, $y, $places, 1) // return undef)
          ? Sidef::Types::Bool::Bool::FALSE
          : Sidef::Types::Bool::Bool::TRUE;
    }

    sub __cmp__ {
        my ($x, $y) = @_;

        goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

        #
        ## MPFR
        #
      Math_MPFR__Math_MPFR: {
            if (   Math::MPFR::Rmpfr_nan_p($x)
                or Math::MPFR::Rmpfr_nan_p($y)) {
                return undef;
            }

            return Math::MPFR::Rmpfr_cmp($x, $y);
        }

      Math_MPFR__Math_GMPz: {
            Math::MPFR::Rmpfr_nan_p($x) && return undef;
            return Math::MPFR::Rmpfr_cmp_z($x, $y);
        }

      Math_MPFR__Math_GMPq: {
            Math::MPFR::Rmpfr_nan_p($x) && return undef;
            return Math::MPFR::Rmpfr_cmp_q($x, $y);
        }

      Math_MPFR__Math_MPC: {
            $x = _mpfr2mpc($x);
            goto Math_MPC__Math_MPC;
        }

      Math_MPFR__Scalar: {
            Math::MPFR::Rmpfr_nan_p($x) && return undef;
            return (
                    ($y || return Math::MPFR::Rmpfr_sgn($x)) < 0
                    ? Math::MPFR::Rmpfr_cmp_si($x, $y)
                    : Math::MPFR::Rmpfr_cmp_ui($x, $y)
                   );
        }

        #
        ## GMPq
        #
      Math_GMPq__Math_GMPq: {
            return Math::GMPq::Rmpq_cmp($x, $y);
        }

      Math_GMPq__Math_GMPz: {
            return Math::GMPq::Rmpq_cmp_z($x, $y);
        }

      Math_GMPq__Math_MPFR: {
            Math::MPFR::Rmpfr_nan_p($y) && return undef;
            return -(Math::MPFR::Rmpfr_cmp_q($y, $x));
        }

      Math_GMPq__Math_MPC: {
            $x = _mpq2mpc($x);
            goto Math_MPC__Math_MPC;
        }

      Math_GMPq__Scalar: {
            return (
                    ($y || return Math::GMPq::Rmpq_sgn($x)) < 0
                    ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
                    : Math::GMPq::Rmpq_cmp_ui($x, $y, 1)
                   );
        }

        #
        ## GMPz
        #
      Math_GMPz__Math_GMPz: {
            return Math::GMPz::Rmpz_cmp($x, $y);
        }

      Math_GMPz__Math_GMPq: {
            return -(Math::GMPq::Rmpq_cmp_z($y, $x));
        }

      Math_GMPz__Math_MPFR: {
            Math::MPFR::Rmpfr_nan_p($y) && return undef;
            return -(Math::MPFR::Rmpfr_cmp_z($y, $x));
        }

      Math_GMPz__Math_MPC: {
            $x = _mpz2mpc($x);
            goto Math_MPC__Math_MPC;
        }

      Math_GMPz__Scalar: {
            return (
                    ($y || return Math::GMPz::Rmpz_sgn($x)) < 0
                    ? Math::GMPz::Rmpz_cmp_si($x, $y)
                    : Math::GMPz::Rmpz_cmp_ui($x, $y)
                   );
        }

        #
        ## MPC
        #
      Math_MPC__Math_MPC: {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($f, $x);
            Math::MPFR::Rmpfr_nan_p($f) && return undef;

            Math::MPC::RMPC_RE($f, $y);
            Math::MPFR::Rmpfr_nan_p($f) && return undef;

            Math::MPC::RMPC_IM($f, $x);
            Math::MPFR::Rmpfr_nan_p($f) && return undef;

            Math::MPC::RMPC_IM($f, $y);
            Math::MPFR::Rmpfr_nan_p($f) && return undef;

            my $si     = Math::MPC::Rmpc_cmp($x, $y);
            my $re_cmp = Math::MPC::RMPC_INEX_RE($si);
            $re_cmp == 0 or return $re_cmp;
            return Math::MPC::RMPC_INEX_IM($si);
        }

      Math_MPC__Math_GMPz: {
            $y = _mpz2mpc($y);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_GMPq: {
            $y = _mpq2mpc($y);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_MPFR: {
            $y = _mpfr2mpc($y);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Scalar: {
            $y = _any2mpc(_str2obj($y));
            goto Math_MPC__Math_MPC;
        }
    }

    sub cmp {
        my ($x, $y) = @_;
        _valid(\$y);
        my $cmp = __cmp__($$x, $$y) // return undef;
        !$cmp ? ZERO : ($cmp > 0) ? ONE : MONE;
    }

    sub acmp {
        my ($x, $y) = @_;
        _valid(\$y);
        my $cmp = __cmp__(__abs__($$x), __abs__($$y)) // return undef;
        !$cmp ? ZERO : ($cmp > 0) ? ONE : MONE;
    }

    sub gt {
        my ($x, $y) = @_;
        _valid(\$y);
        ((__cmp__($$x, $$y) // return undef) > 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub ge {
        my ($x, $y) = @_;
        _valid(\$y);
        ((__cmp__($$x, $$y) // return undef) >= 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub lt {
        my ($x, $y) = @_;
        _valid(\$y);
        ((__cmp__($$x, $$y) // return undef) < 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub le {
        my ($x, $y) = @_;
        _valid(\$y);
        ((__cmp__($$x, $$y) // return undef) <= 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_zero {
        my ($x) = @_;
        __eq__($$x, 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_one {
        my ($x) = @_;
        __eq__($$x, $ONE)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_mone {
        my ($x) = @_;
        __eq__($$x, $MONE)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_positive {
        my ($x) = @_;
        ((__cmp__($$x, 0) // return undef) > 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_pos = \&is_positive;

    sub is_negative {
        my ($x) = @_;
        ((__cmp__($$x, 0) // return undef) < 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_neg = \&is_negative;

    sub __sgn__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            return Math::MPFR::Rmpfr_sgn($x);
        }

      Math_GMPq: {
            return Math::GMPq::Rmpq_sgn($x);
        }

      Math_GMPz: {
            return Math::GMPz::Rmpz_sgn($x);
        }

      Math_MPC: {
            my $abs = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($abs, $x, $ROUND);

            if (Math::MPFR::Rmpfr_zero_p($abs)) {    # it's zero
                return 0;
            }

            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_div_fr($r, $x, $abs, $ROUND);
            return $r;
        }
    }

    sub sign {
        my ($x) = @_;
        my $r = __sgn__($$x);
        if (ref($r)) {
            bless \$r;
        }
        else {
            ($r < 0) ? MONE : ($r > 0) ? ONE : ZERO;
        }
    }

    *sgn = \&sign;

    sub popcount {
        my ($x) = @_;
        my $z = _any2mpz($$x) // return undef;

        if (Math::GMPz::Rmpz_sgn($z) < 0) {
            my $t = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_neg($t, $z);
            $z = $t;
        }

        _set_int(Math::GMPz::Rmpz_popcount($z));
    }

    *hammingweight = \&popcount;

    # Hamming distance
    sub hamdist {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = _any2mpz($$n) // return undef;
        $k = _any2mpz($$k) // return undef;

        _set_int(Math::GMPz::Rmpz_hamdist($n, $k));
    }

    sub __is_int__ {
        my ($x) = @_;

        ref($x) eq 'Math::GMPz' && return 1;
        ref($x) eq 'Math::GMPq' && return Math::GMPq::Rmpq_integer_p($x);
        ref($x) eq 'Math::MPFR' && return Math::MPFR::Rmpfr_integer_p($x);

        (@_) = _any2mpfr($x);
        goto __SUB__;
    }

    sub is_int {
        my ($x) = @_;
        __is_int__($$x)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub __is_rat__ {
        my ($x) = @_;
        (ref($x) eq 'Math::GMPz' or ref($x) eq 'Math::GMPq');
    }

    sub is_rat {
        my ($x) = @_;
        __is_rat__($$x)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub __is_real__ {
        my ($x) = @_;

        ref($x) eq 'Math::GMPz' && return 1;
        ref($x) eq 'Math::GMPq' && return 1;
        ref($x) eq 'Math::MPFR' && return Math::MPFR::Rmpfr_number_p($x);

        (@_) = _any2mpfr($x);
        goto __SUB__;
    }

    sub is_real {
        my ($x) = @_;
        __is_real__($$x)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub __is_imag__ {
        my ($x) = @_;

        ref($x) eq 'Math::MPC' or return 0;

        my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPC::RMPC_RE($f, $x);
        Math::MPFR::Rmpfr_zero_p($f) || return 0;    # is complex
        Math::MPC::RMPC_IM($f, $x);
        !Math::MPFR::Rmpfr_zero_p($f);
    }

    sub is_imag {
        my ($x) = @_;
        __is_imag__($$x)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub __is_complex__ {
        my ($x) = @_;

        ref($x) eq 'Math::MPC' or return 0;

        my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPC::RMPC_IM($f, $x);
        Math::MPFR::Rmpfr_zero_p($f) && return 0;    # is real
        Math::MPC::RMPC_RE($f, $x);
        !Math::MPFR::Rmpfr_zero_p($f);
    }

    sub is_complex {
        my ($x) = @_;
        __is_complex__($$x)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_between {
        my ($x, $min, $max) = @_;
        _valid(\$min, \$max);
        (__cmp__($$x, $$min) >= 0 and __cmp__($$x, $$max) <= 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_even {
        my ($x) = @_;
        (__is_int__($$x) && Math::GMPz::Rmpz_even_p(_any2mpz($$x) // (return Sidef::Types::Bool::Bool::FALSE)))
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_odd {
        my ($x) = @_;
        (__is_int__($$x) && Math::GMPz::Rmpz_odd_p(_any2mpz($$x) // (return Sidef::Types::Bool::Bool::FALSE)))
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_congruent {
        my ($n, $k, $m) = @_;
        _valid(\$k, \$m);

        $n = $$n;
        $k = $$k;
        $m = $$m;

        if (ref($n) eq 'Math::GMPz' and ref($k) eq 'Math::GMPz' and ref($m) eq 'Math::GMPz') {
            Math::GMPz::Rmpz_sgn($m) || return Sidef::Types::Bool::Bool::FALSE;
            return (
                    Math::GMPz::Rmpz_congruent_p($n, $k, $m)
                    ? (Sidef::Types::Bool::Bool::TRUE)
                    : (Sidef::Types::Bool::Bool::FALSE)
                   );
        }

        __eq__(__mod__($n, $m), __mod__($k, $m))
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_div {
        my ($x, $y) = @_;
        _valid(\$y);

        $x = $$x;
        $y = $$y;

        if (ref($x) eq 'Math::GMPz' and ref($y) eq 'Math::GMPz') {
            return (
                      (Math::GMPz::Rmpz_divisible_p($x, $y) && Math::GMPz::Rmpz_sgn($y))
                    ? (Sidef::Types::Bool::Bool::TRUE)
                    : (Sidef::Types::Bool::Bool::FALSE)
                   );
        }

        __eq__(__mod__($x, $y), 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_divisible = \&is_div;

    sub divides {
        my ($x, $y) = @_;
        _valid(\$y);

        $x = $$x;
        $y = $$y;

        if (ref($x) eq 'Math::GMPz' and ref($y) eq 'Math::GMPz') {
            return (
                      (Math::GMPz::Rmpz_divisible_p($y, $x) && Math::GMPz::Rmpz_sgn($x))
                    ? (Sidef::Types::Bool::Bool::TRUE)
                    : (Sidef::Types::Bool::Bool::FALSE)
                   );
        }

        __eq__(__mod__($y, $x), 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub __is_inf__ {
        my ($x) = @_;

        ref($x) eq 'Math::GMPz' && return 0;
        ref($x) eq 'Math::GMPq' && return 0;
        ref($x) eq 'Math::MPFR' && return (Math::MPFR::Rmpfr_inf_p($x) and Math::MPFR::Rmpfr_sgn($x) > 0);

        (@_) = _any2mpfr($x);
        goto __SUB__;
    }

    sub is_inf {
        my ($x) = @_;
        __is_inf__($$x)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub __is_ninf__ {
        my ($x) = @_;

        ref($x) eq 'Math::GMPz' && return 0;
        ref($x) eq 'Math::GMPq' && return 0;
        ref($x) eq 'Math::MPFR' && return (Math::MPFR::Rmpfr_inf_p($x) and Math::MPFR::Rmpfr_sgn($x) < 0);

        (@_) = _any2mpfr($x);
        goto __SUB__;
    }

    sub is_ninf {
        my ($x) = @_;
        __is_ninf__($$x)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_nan {
        my ($x) = @_;

        $x = $$x;

        ref($x) eq 'Math::GMPz' && return Sidef::Types::Bool::Bool::FALSE;
        ref($x) eq 'Math::GMPq' && return Sidef::Types::Bool::Bool::FALSE;
        ref($x) eq 'Math::MPFR'
          && return (
                     Math::MPFR::Rmpfr_nan_p($x)
                     ? Sidef::Types::Bool::Bool::TRUE
                     : Sidef::Types::Bool::Bool::FALSE
                    );

        my $t = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPC::RMPC_RE($t, $x);
        Math::MPFR::Rmpfr_nan_p($t) && return Sidef::Types::Bool::Bool::TRUE;

        Math::MPC::RMPC_IM($t, $x);
        Math::MPFR::Rmpfr_nan_p($t) && return Sidef::Types::Bool::Bool::TRUE;

        Sidef::Types::Bool::Bool::FALSE;
    }

    sub sum {
        my (@vals) = @_;

        @vals || return ZERO;

        my @extra;
        my @numbers;

        foreach my $value (@vals) {
            if (ref($value) eq __PACKAGE__) {
                push @numbers, $$value;
            }
            else {
                if (UNIVERSAL::isa($value, 'Sidef::Types::Number::Number')) {
                    push @extra, $value;
                }
                else {
                    _valid(\$value);
                    push @numbers, $$value;
                }
            }
        }

        my @non_mpz;
        my $sum = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $n (@numbers) {
            if (ref($n) eq 'Math::GMPz') {
                Math::GMPz::Rmpz_add($sum, $sum, $n);
            }
            else {
                push @non_mpz, $n;
            }
        }

        if (@non_mpz) {
            $sum = __add__($sum, _binsplit(\@non_mpz, \&__add__));
        }

        my $r = bless \$sum;

        if (@extra) {
            $r = $r->add(_binsplit(\@extra, sub { $_[0]->add($_[1]) }));
        }

        $r;
    }

    *Σ = \&sum;

    sub prod {
        my (@vals) = @_;

        @vals || return ONE;

        my @numbers;
        my @unknown;

        foreach my $value (@vals) {
            if (ref($value) eq __PACKAGE__) {
                push @numbers, $$value;
            }
            else {
                if (UNIVERSAL::isa($value, 'Sidef::Types::Number::Number')) {
                    push @unknown, $value;
                }
                else {
                    _valid(\$value);
                    push @numbers, $$value;
                }
            }
        }

        my $r = (@numbers ? (bless \_binsplit(\@numbers, \&__mul__)) : ONE);

        if (@unknown) {
            $r = $r->mul(_binsplit(\@unknown, sub { $_[0]->mul($_[1]) }));
        }

        return $r;
    }

    *Π = \&prod;

    sub max {
        my (@vals) = @_;
        _valid(\(@vals));

        my $max = shift(@vals);

        foreach my $curr (@vals) {
            if ((__cmp__($$curr, $$max) // return undef) > 0) {
                $max = $curr;
            }
        }

        $max;
    }

    sub min {
        my (@vals) = @_;
        _valid(\(@vals));

        my $min = shift(@vals);

        foreach my $curr (@vals) {
            if ((__cmp__($$curr, $$min) // return undef) < 0) {
                $min = $curr;
            }
        }

        $min;
    }

    sub as_int {
        my ($x, $y) = @_;

        my $base = 10;
        if (defined($y)) {
            _valid(\$y);
            $base = _any2ui($$y) // 0;
            if ($base < 2 or $base > 62) {
                die "[ERROR] Number.as_int(): base must be between 2 and 62, got $y";
            }
        }

        Sidef::Types::String::String->new(Math::GMPz::Rmpz_get_str((_any2mpz($$x) // return undef), $base));
    }

    sub __base__ {
        my ($x, $base) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_GMPz: {
            return Math::GMPz::Rmpz_get_str($x, $base);
        }

      Math_GMPq: {
            return Math::GMPq::Rmpq_get_str($x, $base);
        }

      Math_MPFR: {
            return Math::MPFR::Rmpfr_get_str($x, $base, 0, $ROUND);
        }

      Math_MPC: {
            my $fr = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_RE($fr, $x);
            my $real = __base__($fr, $base);
            Math::MPC::RMPC_IM($fr, $x);
            return $real if Math::MPFR::Rmpfr_zero_p($fr);
            my $imag = __base__($fr, $base);
            return "($real $imag)";
        }
    }

    sub base {
        my ($x, $y) = @_;

        my $base = 10;

        if (defined($y)) {
            _valid(\$y);
            $base = _any2ui($$y) // 0;
            if ($base < 2 or $base > 62) {
                die "[ERROR] Number.base(): base must be between 2 and 62, got $y";
            }
        }

        $x = $$x;

        Sidef::Types::String::String->new(__base__($x, $base));
    }

    *in_base = \&base;

    sub as_rat {
        my ($x, $y) = @_;

        my $base = 10;
        if (defined($y)) {
            _valid(\$y);
            $base = _any2ui($$y) // 0;
            if ($base < 2 or $base > 62) {
                die "[ERROR] base must be between 2 and 62, got $y";
            }
        }

        my $str =
          ref($$x) eq 'Math::GMPz'
          ? Math::GMPz::Rmpz_get_str($$x, $base)
          : Math::GMPq::Rmpq_get_str((_any2mpq($$x) // return undef), $base);

        Sidef::Types::String::String->new($str);
    }

    sub as_frac {
        my ($x, $y) = @_;

        my $base = 10;
        if (defined($y)) {
            _valid(\$y);
            $base = _any2ui($$y) // 0;
            if ($base < 2 or $base > 62) {
                die "as_frac(): base must be between 2 and 62, got $y";
            }
        }

        my $str =
          ref($$x) eq 'Math::GMPz'
          ? Math::GMPz::Rmpz_get_str($$x, $base)
          : Math::GMPq::Rmpq_get_str((_any2mpq($$x) // return undef), $base);

        $str .= '/1' if (index($str, '/') == -1);

        Sidef::Types::String::String->new($str);
    }

    sub as_cfrac {
        my ($x, $n) = @_;

        my $p = CORE::int($PREC) >> 1;

        $x = $$x;
        $n = defined($n) ? do { _valid(\$n); _any2ui($$n) // 0 } : ($p >> 1);

        goto(ref($x) =~ tr/:/_/rs);

      Math_GMPq: {
            my @cfrac;
            my $q = Math::GMPq::Rmpq_init();

            Math::GMPq::Rmpq_set($q, $x);

            for (1 .. $n) {
                my $z = __floor__($q);
                push @cfrac, bless \$z;
                Math::GMPq::Rmpq_sub_z($q, $q, $z);
                Math::GMPq::Rmpq_sgn($q) || last;
                Math::GMPq::Rmpq_inv($q, $q);
            }

            return Sidef::Types::Array::Array->new(\@cfrac);
        }

      Math_MPFR: {
            my @cfrac;
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPFR::Rmpfr_set($f, $x, $ROUND);

            for (1 .. $n) {
                my $t = __floor__($f);
                push @cfrac, bless \(_any2mpz($t) // $t);

                Math::MPFR::Rmpfr_eq($f, $t, $p) && last;
                Math::MPFR::Rmpfr_sub($f, $f, $t, $ROUND);
                Math::MPFR::Rmpfr_ui_div($f, 1, $f, $ROUND);
            }

            return Sidef::Types::Array::Array->new(\@cfrac);
        }

      Math_MPC: {
            my @cfrac;
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));

            my $real_1 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $real_2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            my $imag_1 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $imag_2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::Rmpc_set($c, $x, $ROUND);

            for (1 .. $n) {
                my $t = __round__($c, 0);
                push @cfrac, bless \(_any2mpz($t) // $t);

                Math::MPC::Rmpc_real($real_1, $c, $ROUND);
                Math::MPC::Rmpc_imag($imag_1, $c, $ROUND);

                if (ref($t) eq 'Math::MPFR') {
                    Math::MPFR::Rmpfr_neg($t, $t, $ROUND);
                    Math::MPC::Rmpc_add_fr($c, $c, $t, $ROUND);
                    Math::MPFR::Rmpfr_neg($t, $t, $ROUND);

                    Math::MPFR::Rmpfr_set($real_2, $t, $ROUND);
                    Math::MPFR::Rmpfr_set_ui($imag_2, 0, $ROUND);
                }
                else {
                    Math::MPC::Rmpc_sub($c, $c, $t, $ROUND);

                    Math::MPC::Rmpc_real($real_2, $t, $ROUND);
                    Math::MPC::Rmpc_imag($imag_2, $t, $ROUND);
                }

#<<<
                   Math::MPFR::Rmpfr_eq($real_1, $real_2, $p)
                && Math::MPFR::Rmpfr_eq($imag_1, $imag_2, $p)
                && last;
#>>>

                Math::MPC::Rmpc_ui_div($c, 1, $c, $ROUND);
            }

            return Sidef::Types::Array::Array->new(\@cfrac);
        }

      Math_GMPz: {
            return Sidef::Types::Array::Array->new([bless \$x]);
        }
    }

    *cfrac = \&as_cfrac;

    sub as_float {
        my ($x, $prec) = @_;

        if (defined($prec)) {
            _valid(\$prec);
            $prec = (_any2ui($$prec) // 0) << 2;

            state $min_prec = Math::MPFR::RMPFR_PREC_MIN();
            state $max_prec = Math::MPFR::RMPFR_PREC_MAX();

            if ($prec < $min_prec or $prec > $max_prec) {
                die "as_float(): precision must be between $min_prec and $max_prec, got ", $prec >> 2;
            }
        }
        else {
            $prec = CORE::int($PREC);
        }

        local $PREC = $prec;
        Sidef::Types::String::String->new(__stringify__(_any2mpfr_mpc($$x)));
    }

    *as_dec = \&as_float;

    # Solution in integers to `x^2 - d*y^2 = n`
    # where `d` and `n` are provided (n=1 by default).

    sub solve_pell {
        my ($d, $n) = @_;

        $d = _any2mpz($$d) // return (undef, undef);

        if (defined($n)) {
            _valid(\$n);
            $n = _any2mpz($$n) // return (undef, undef);
        }
        else {
            $n = $ONE;
        }

        # No solutions for d <= 0 or n = 0
        if (   Math::GMPz::Rmpz_sgn($d) <= 0
            or Math::GMPz::Rmpz_sgn($n) == 0) {
            return (undef, undef);
        }

        # No solutions to `x^2 - d*y^2 = n` if `d` is a perfect square
        if (Math::GMPz::Rmpz_perfect_square_p($d)) {
            return (undef, undef);
        }

        my $x = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sqrt($x, $d);

        my $y = Math::GMPz::Rmpz_init_set($x);
        my $z = Math::GMPz::Rmpz_init_set_ui(1);

        my $t = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add($t, $x, $x);    # t = x+x

        my $t2 = Math::GMPz::Rmpz_init();
        my $t3 = Math::GMPz::Rmpz_init();

        my $f1 = Math::GMPz::Rmpz_init_set_ui(1);
        my $f2 = Math::GMPz::Rmpz_init_set($x);

        # The bound of the square root period is: O(sqrt(d)*log(d))
        # We set: max = 2*sqrt(d)*log(d) = 4*sqrt(d)*log(sqrt(d))
        my $max = Math::GMPz::Rmpz_get_d($x);
        $max = CORE::int(4 * $max * CORE::log($max) + 10);

        my $p = Math::GMPz::Rmpz_init();

        foreach (my $i = 0 ; $i <= $max ; ++$i) {

            # y = (r*z - y)
            Math::GMPz::Rmpz_submul($y, $t, $z);    # y = y - t*z
            Math::GMPz::Rmpz_neg($y, $y);           # y = -y

            Math::GMPz::Rmpz_sgn($z) || return (undef, undef);

            # z = floor((n - y*y) / z)
            Math::GMPz::Rmpz_mul($t, $y, $y);       # t = y*y
            Math::GMPz::Rmpz_sub($t, $d, $t);       # t = d-t
            Math::GMPz::Rmpz_div($z, $t, $z);       # z = floor(t/z)

            Math::GMPz::Rmpz_sgn($z) || return (undef, undef);

            # t = floor((x + y) / z)
            Math::GMPz::Rmpz_add($t, $x, $y);       # t = x+y
            Math::GMPz::Rmpz_div($t, $t, $z);       # t = floor(t/z)

            Math::GMPz::Rmpz_addmul($f1, $f2, $t);
            ($f1, $f2) = ($f2, $f1);

            Math::GMPz::Rmpz_mul($p, $f1, $f1);
            Math::GMPz::Rmpz_sub($p, $p, $n);
            Math::GMPz::Rmpz_mul($p, $p, $d);
            Math::GMPz::Rmpz_mul_2exp($p, $p, 2);

            if (Math::GMPz::Rmpz_perfect_square_p($p)) {

                Math::GMPz::Rmpz_sqrt($p, $p);
                Math::GMPz::Rmpz_div_2exp($p, $p, 1);
                Math::GMPz::Rmpz_divisible_p($p, $d) || next;
                Math::GMPz::Rmpz_divexact($p, $p, $d);
                Math::GMPz::Rmpz_sgn($p) || next;

                # Solution in positive integers
                return ((bless \$f1), (bless \$p));
            }
        }

        # No solution could be found
        return (undef, undef);
    }

    sub solve_lcg {
        my ($n, $r, $m) = @_;

        # Solve: n*x == r (mod m)

        _valid(\$r, \$m);

        $n = _any2mpz($$n) // goto &nan;
        $r = _any2mpz($$r) // goto &nan;
        $m = _any2mpz($$m) // goto &nan;

        Math::GMPz::Rmpz_sgn($m) || goto &nan;

        my $g = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_gcd($g, $n, $m);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) != 0) {

            # No solution exists if `r` is NOT divisible by `gcd(n,m)`
            Math::GMPz::Rmpz_divisible_p($r, $g) || goto &nan;

            $n = Math::GMPz::Rmpz_init_set($n);
            $r = Math::GMPz::Rmpz_init_set($r);
            $m = Math::GMPz::Rmpz_init_set($m);

            Math::GMPz::Rmpz_divexact($n, $n, $g);
            Math::GMPz::Rmpz_divexact($r, $r, $g);
            Math::GMPz::Rmpz_divexact($m, $m, $g);
        }

        Math::GMPz::Rmpz_invert($g, $n, $m);
        Math::GMPz::Rmpz_mul($g, $g, $r);
        Math::GMPz::Rmpz_mod($g, $g, $m);

        bless \$g;
    }

    *solve_linear_congruence = \&solve_lcg;

    sub sqrt_cfrac_period_each {
        my ($n, $block, $max) = @_;

        $n   = _any2mpz($$n) // return ZERO;
        $max = defined($max) ? CORE::int($max) : (0 + 'inf');

        Math::GMPz::Rmpz_sgn($n) < 0
          and return ZERO;

        my $x = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sqrt($x, $n);

        Math::GMPz::Rmpz_perfect_square_p($n)
          and return ZERO;

        # Optimization for native integers
        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {

            $n = Math::GMPz::Rmpz_get_ui($n);
            $x = Math::GMPz::Rmpz_get_ui($x);

            my $y = $x;
            my $z = 1;
            my $r = $x + $x;

            my $count = 0;

            for (; $count < $max ; ++$count) {

                $y = $r * $z - $y;
                $z = CORE::int(($n - $y * $y) / $z);
                $r = CORE::int(($x + $y) / $z);

                $block->run(_set_int($r));

                if ($z == 1) {
                    ++$count;
                    last;
                }
            }

            return _set_int($count);
        }

        my $y = Math::GMPz::Rmpz_init_set($x);
        my $z = Math::GMPz::Rmpz_init_set_ui(1);
        my $r = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_add($r, $x, $x);    # r = x+x

        my $count = 0;
        for (; $count < $max ; ++$count) {

            my $t = Math::GMPz::Rmpz_init();

            # y = (r*z - y)
            Math::GMPz::Rmpz_submul($y, $r, $z);    # y = y - t*z
            Math::GMPz::Rmpz_neg($y, $y);           # y = -y

            # z = ((n - y*y) / z)
            Math::GMPz::Rmpz_mul($t, $y, $y);         # t = y*y
            Math::GMPz::Rmpz_sub($t, $n, $t);         # t = n-t
            Math::GMPz::Rmpz_divexact($z, $t, $z);    # z = t/z

            # t = floor((x + y) / z)
            Math::GMPz::Rmpz_add($t, $x, $y);         # t = x+y
            Math::GMPz::Rmpz_div($t, $t, $z);         # t = floor(t/z)

            $r = $t;
            $block->run(bless \$t);

            if (Math::GMPz::Rmpz_cmp_ui($z, 1) == 0) {
                ++$count;
                last;
            }
        }

        return _set_int($count);
    }

    sub sqrt_cfrac {
        my ($n, $max) = @_;
        $n->sqrt_cfrac_period($max)->unshift($n->isqrt);
    }

    sub sqrt_cfrac_period {
        my ($n, $max) = @_;

        my @cfrac;

        $n->sqrt_cfrac_period_each(
            Sidef::Types::Block::Block->new(
                code => sub {
                    push @cfrac, $_[0];
                }
            ),
            $max
        );

        Sidef::Types::Array::Array->new(\@cfrac);
    }

    sub sqrt_cfrac_period_len {
        my ($n) = @_;

        $n = _any2mpz($$n) // goto &nan;

        return ZERO if Math::GMPz::Rmpz_perfect_square_p($n);

        goto &nan if Math::GMPz::Rmpz_sgn($n) < 0;

        my $t = Math::GMPz::Rmpz_init();
        my $x = Math::GMPz::Rmpz_init();
        my $z = Math::GMPz::Rmpz_init_set_ui(1);

        Math::GMPz::Rmpz_sqrt($x, $n);

        my $y = Math::GMPz::Rmpz_init_set($x);

        # Optimization for native integers
        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {

            $n = Math::GMPz::Rmpz_get_ui($n);
            $x = Math::GMPz::Rmpz_get_ui($x);

            my $y = $x;
            my $z = 1;
            my $r = $x + $x;

            my $period = 0;

            do {
                $y = $r * $z - $y;
                $z = CORE::int(($n - $y * $y) / $z);
                $r = CORE::int(($x + $y) / $z);
                ++$period;
            } until ($z == 1);

            return _set_int($period);
        }

        my $period = 0;

        do {

            # y = floor((x+y)/z)*z - y
            Math::GMPz::Rmpz_add($t, $x, $y);    # t = x+y
            Math::GMPz::Rmpz_div($t, $t, $z);    # t = floor(t/z)
            Math::GMPz::Rmpz_mul($t, $t, $z);    # t = t*z
            Math::GMPz::Rmpz_sub($y, $t, $y);    # y = t-y

            # z = (n - y*y)/z
            Math::GMPz::Rmpz_mul($t, $y, $y);         # t = y*y
            Math::GMPz::Rmpz_sub($t, $n, $t);         # t = n-t
            Math::GMPz::Rmpz_divexact($z, $t, $z);    # z = t/z

            ++$period;

        } until (Math::GMPz::Rmpz_cmp_ui($z, 1) == 0);

        _set_int($period);
    }

    sub convergents {
        my ($x, $n) = @_;

        my @cfrac = @{$x->as_cfrac($n)};

        my ($n1, $n2) = ($ZERO, $ONE);
        my ($d1, $d2) = ($ONE,  $ZERO);

        my @convergents;
        foreach my $z (map { $$_ } @cfrac) {

            ($n1, $n2) = ($n2, __add__(__mul__($n2, $z), $n1));
            ($d1, $d2) = ($d2, __add__(__mul__($d2, $z), $d1));

            push @convergents, bless \__div__($n2, $d2);
        }

        Sidef::Types::Array::Array->new(\@convergents);
    }

    sub dump {
        my ($x) = @_;

        $x = $$x;
        Sidef::Types::String::String->new(
                                            ref($x) eq 'Math::GMPq' ? Math::GMPq::Rmpq_get_str($x, 10)
                                          : ref($x) eq 'Math::GMPz' ? Math::GMPz::Rmpz_get_str($x, 10)
                                          :                           __stringify__($x)
                                         );
    }

    *stringify = \&dump;

    sub to_str {
        my ($x) = @_;
        Sidef::Types::String::String->new(__stringify__($$x));
    }

    *to_s = \&to_str;

    sub to_num {
        $_[0];
    }

    *to_n = \&to_num;

    sub as_bin {
        my ($x) = @_;
        Sidef::Types::String::String->new(Math::GMPz::Rmpz_get_str((_any2mpz($$x) // return undef), 2));
    }

    sub as_oct {
        my ($x) = @_;
        Sidef::Types::String::String->new(Math::GMPz::Rmpz_get_str((_any2mpz($$x) // return undef), 8));
    }

    sub as_hex {
        my ($x) = @_;
        Sidef::Types::String::String->new(Math::GMPz::Rmpz_get_str((_any2mpz($$x) // return undef), 16));
    }

    sub bits {
        my ($x) = @_;
        $x = _any2mpz($$x) // return Sidef::Types::Array::Array->new;
        my $bin = Math::GMPz::Rmpz_get_str($x, 2);
        $bin = substr($bin, 1) if substr($bin, 0, 1) eq '-';
        Sidef::Types::Array::Array->new([map { $_ ? ONE : ZERO } split(//, $bin)]);
    }

    sub digital_root {
        my ($n, $base) = @_;

        # Formula:
        #   digital_root(n,b) = n - (b-1)*floor((n-1)/(b-1))

        $n = _any2mpz($$n) // goto &nan;

        if (defined($base)) {
            _valid(\$base);
            $base = _any2mpz($$base) // goto &nan;
            Math::GMPz::Rmpz_cmp_ui($base, 1) > 0 or goto &nan;
        }
        else {
            $base = $TEN;
        }

        Math::GMPz::Rmpz_sgn($n) || return ZERO;

        my $r = Math::GMPz::Rmpz_init();
        my $t = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_sub_ui($r, $n,    1);
        Math::GMPz::Rmpz_sub_ui($t, $base, 1);
        Math::GMPz::Rmpz_mod($r, $r, $t);
        Math::GMPz::Rmpz_add_ui($r, $r, 1);

        bless \$r;
    }

    sub expnorm {
        my ($n, $base) = @_;

        $n = _any2mpfr_mpc($$n) // goto &nan;

        if (defined($base)) {
            _valid(\$base);
            $base = _any2ui($$base) // goto &nan;
            $base > 1 or goto &nan;
        }
        else {
            $base = 10;
        }

        my $log = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPFR::Rmpfr_set_ui($log, $base, $ROUND);
        Math::MPFR::Rmpfr_log($log, $log, $ROUND);

        if (ref($n) eq 'Math::MPFR') {

            my $exp = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPFR::Rmpfr_div($exp, $n, $log, $ROUND);
            Math::MPFR::Rmpfr_floor($exp, $exp);
            Math::MPFR::Rmpfr_add_ui($exp, $exp, 1, $ROUND);
            Math::MPFR::Rmpfr_mul($exp, $exp, $log, $ROUND);
            Math::MPFR::Rmpfr_sub($exp, $n, $exp, $ROUND);
            Math::MPFR::Rmpfr_exp($exp, $exp, $ROUND);

            return bless \$exp;
        }

        my $exp = Math::MPC::Rmpc_init2(CORE::int($PREC));

        Math::MPC::Rmpc_div_fr($exp, $n, $log, $ROUND);

        my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPC::RMPC_RE($real, $exp);
        Math::MPC::RMPC_IM($imag, $exp);

        Math::MPFR::Rmpfr_floor($real, $real);
        Math::MPFR::Rmpfr_floor($imag, $imag);

        Math::MPC::Rmpc_set_fr_fr($exp, $real, $imag, $ROUND);

        Math::MPC::Rmpc_add_ui($exp, $exp, 1, $ROUND);
        Math::MPC::Rmpc_mul_fr($exp, $exp, $log, $ROUND);
        Math::MPC::Rmpc_sub($exp, $n, $exp, $ROUND);
        Math::MPC::Rmpc_exp($exp, $exp, $ROUND);

        bless \$exp;
    }

    sub digits {
        my ($n, $k) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        my $sgn = Math::GMPz::Rmpz_sgn($n);

        if ($sgn == 0) {
            return Sidef::Types::Array::Array->new([ZERO]);
        }
        elsif ($sgn < 0) {
            $n = Math::GMPz::Rmpz_init_set($n);
            Math::GMPz::Rmpz_abs($n, $n);
        }

        if (defined($k)) {
            _valid(\$k);

            $k = _any2mpz($$k) // return Sidef::Types::Array::Array->new;

            # Not defined for k <= 1
            if (Math::GMPz::Rmpz_cmp_ui($k, 1) <= 0) {
                return Sidef::Types::Array::Array->new;
            }
        }

#<<<
        if (!defined($k) or Math::GMPz::Rmpz_cmp_ui($k, 62) <= 0) {
            $k = defined($k) ? Math::GMPz::Rmpz_get_ui($k) : 10;
            return Sidef::Types::Array::Array->new([
                map { _set_int($k <= 36 ? $DIGITS_36{$_} : $DIGITS_62{$_}) }
                    split(//, scalar CORE::reverse scalar Math::GMPz::Rmpz_get_str($n, $k))
            ]);
        }
#>>>

        # Subquadratic Algorithm 1.26 FastIntegerOutput from "Modern Computer Arithmetic v0.5.9"
        if (Math::GMPz::Rmpz_fits_ulong_p($k)) {

            my $A = $n;
            my $B = Math::GMPz::Rmpz_get_ui($k);

            # When B < 2^32, use Math::Prime::Util::GMP::todigits().
            if ($B <= 4294967295) {
                return
                  Sidef::Types::Array::Array->new(
                    [map { _set_int($_) } CORE::reverse(Math::Prime::Util::GMP::todigits(Math::GMPz::Rmpz_get_str($n, 10), $B))
                    ]
                  );
            }

            # Find r such that B^(2r - 2) <= A < B^(2r)
            my $r = (__ilog__($n, $k) >> 1) + 1;

            state $Q = Math::GMPz::Rmpz_init_nobless();
            state $R = Math::GMPz::Rmpz_init_nobless();

            my @digits = map { _set_int($_) } sub {
                my ($A, $r) = @_;

                # Cut the recursion early
                if (Math::GMPz::Rmpz_fits_ulong_p($A)) {
                    my $v = Math::GMPz::Rmpz_get_ui($A);
                    my ($m, @digits);
                    while ($v) {
                        ($v, $m) = (
                                    HAS_NEW_PRIME_UTIL
                                    ? Math::Prime::Util::divrem($v, $B)
                                    : Math::Prime::Util::GMP::divrem($v, $B)
                                   );
                        push @digits, $m;
                    }
                    return @digits;
                }

                #~ if (Math::GMPz::Rmpz_cmp_ui($A, $B) < 0) {
                #~ return Math::GMPz::Rmpz_get_ui($A);
                #~ }

                my $t = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_ui_pow_ui($t, $B, 2 * ($r - 1));    # can this be optimized away?

                if (Math::GMPz::Rmpz_cmp($t, $A) > 0) {
                    --$r;
                }

                Math::GMPz::Rmpz_ui_pow_ui($t, $B, $r);
                Math::GMPz::Rmpz_divmod($Q, $R, $A, $t);

                my $w = ($r + 1) >> 1;
                Math::GMPz::Rmpz_set($t, $Q);

                my @right = __SUB__->($R, $w);
                my @left  = __SUB__->($t, $w);

                (@right, (0) x ($r - scalar(@right)), @left);
              }
              ->($A, $r);

            return Sidef::Types::Array::Array->new(\@digits);
        }

        # This algorithm will be used only when base > ULONG_MAX
        my @digits;

        $n = Math::GMPz::Rmpz_init_set($n);    # copy

        while (Math::GMPz::Rmpz_sgn($n) > 0) {
            my $m = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_divmod($n, $m, $n, $k);
            push @digits, bless \$m;
        }

        Sidef::Types::Array::Array->new(\@digits);
    }

    sub __digits2num__ {
        my ($base, $digits) = @_;

        # $base is a native integer
        # $digits is a non-empty array of native integers < base (msd first)

        if ($base <= 10) {
            return Math::GMPz::Rmpz_init_set_str(join('', @$digits), $base);
        }

        if ($base <= 36) {
            return Math::GMPz::Rmpz_init_set_str(join('', map { $FROM_DIGITS_36{$_} } @$digits), $base);
        }

        if ($base <= 62) {
            return Math::GMPz::Rmpz_init_set_str(join('', map { $FROM_DIGITS_62{$_} } @$digits), $base);
        }

        my @D   = CORE::reverse(@$digits);
        my $len = scalar(@D);

        if (CORE::log($base) * $len < CORE::log(ULONG_MAX)) {
            my $r = 0;
            my $B = 1;

            foreach my $d (@D) {
                $r += $B * $d;
                $B *= $base;
            }

            return ${_set_int($r)};
        }

        my @d = map { Math::GMPz::Rmpz_init_set_ui($_) } @D;
        my $B = Math::GMPz::Rmpz_init_set_ui($base);
        my $L = \@d;

        for (my $k = $len ; $k > 1 ; $k = ($k >> 1) + ($k & 1)) {

            my @T;
            for (0 .. ($k >> 1) - 1) {
                my $t = $L->[2 * $_];
                Math::GMPz::Rmpz_addmul($t, $L->[2 * $_ + 1], $B);
                push(@T, $t);
            }

            push(@T, $L->[-1]) if ($k & 1);
            $L = \@T;
            Math::GMPz::Rmpz_mul($B, $B, $B);
        }

        $L->[0];
    }

    sub digits2num {
        my ($base, $D) = @_;

        my @digits = @$D;
        @digits || return ZERO;

        _valid(\$base);
        _valid(\(@digits));

        $base   = $$base;
        @digits = map { $$_ } @digits;

        my $all_mpz = ref($base) eq 'Math::GMPz';

        if ($all_mpz) {
            foreach my $digit (@digits) {
                if (ref($digit) ne 'Math::GMPz') {
                    $all_mpz = 0;
                    last;
                }
            }
        }

        my $L = \@digits;

        if ($all_mpz and Math::GMPz::Rmpz_cmp_ui($base, 2) >= 0) {

            if (Math::GMPz::Rmpz_cmp_ui($base, 62) <= 0) {    # return faster for base in 2..62

                my $str      = '';
                my $optimize = 1;
                my $B        = Math::GMPz::Rmpz_get_ui($base);

                foreach my $digit (CORE::reverse(@digits)) {
                    if (Math::GMPz::Rmpz_cmp_ui($digit, $B) < 0 and Math::GMPz::Rmpz_sgn($digit) >= 0) {
                        $str .= Math::GMPz::Rmpz_get_str($digit, $B);
                    }
                    else {
                        $optimize = 0;
                        last;
                    }
                }

                if ($optimize) {
                    return bless \Math::GMPz::Rmpz_init_set_str($str, $B);
                }
            }

            my $B = Math::GMPz::Rmpz_init_set($base);

            # Subquadratic Algorithm 1.25 FastIntegerInput from "Modern Computer Arithmetic v0.5.9"
            for (my $k = scalar(@digits) ; $k > 1 ; $k = ($k >> 1) + ($k & 1)) {

                my @T;
                for (0 .. ($k >> 1) - 1) {
                    my $t = Math::GMPz::Rmpz_init_set($L->[2 * $_]);
                    Math::GMPz::Rmpz_addmul($t, $L->[2 * $_ + 1], $B);
                    push(@T, $t);
                }

                push(@T, $L->[-1]) if ($k & 1);
                $L = \@T;
                Math::GMPz::Rmpz_mul($B, $B, $B);
            }

            return bless \($L->[0]);
        }

        my $B = $base;

        # Subquadratic Algorithm 1.25 FastIntegerInput from "Modern Computer Arithmetic v0.5.9"
        for (my $k = scalar(@digits) ; $k > 1 ; $k = ($k >> 1) + ($k & 1)) {

            my @T;
            for (0 .. ($k >> 1) - 1) {
                push(@T, __add__($L->[2 * $_], __mul__($B, $L->[2 * $_ + 1])));
            }

            push(@T, $L->[-1]) if ($k & 1);
            $L = \@T;
            $B = __mul__($B, $B);
        }

        bless \($L->[0]);
    }

    *from_digits = \&digits2num;

    sub digit {
        my ($n, $i, $k) = @_;

        _valid(\$i);

        $n = _any2mpz($$n) // return undef;
        $i = _any2si($$i)  // return undef;

        if (defined($k)) {
            _valid(\$k);

            $k = _any2mpz($$k) // return undef;

            # Not defined for k <= 1
            if (Math::GMPz::Rmpz_cmp_ui($k, 1) <= 0) {
                return undef;
            }
        }
        else {
            $k = $TEN;
        }

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init_set($n);

        my $sgn = Math::GMPz::Rmpz_sgn($u);

        if ($sgn == 0) {
            return ZERO;
        }
        elsif ($sgn < 0) {
            Math::GMPz::Rmpz_abs($u, $u);
        }

        if ($i < 0) {
            $i += __ilog__($u, $k) + 1;
            return undef if ($i < 0);
        }

        Math::GMPz::Rmpz_pow_ui($t, $k, $i);
        Math::GMPz::Rmpz_div($u, $u, $t);
        Math::GMPz::Rmpz_mod($u, $u, $k);

        bless \$u;
    }

    sub sumdigits {
        my ($n, $k) = @_;

        $n = _any2mpz($$n) // return undef;

        my $sgn = Math::GMPz::Rmpz_sgn($n);

        if ($sgn == 0) {
            return ZERO;
        }
        elsif ($sgn < 0) {
            $n = Math::GMPz::Rmpz_init_set($n);
            Math::GMPz::Rmpz_abs($n, $n);
        }

        if (defined($k)) {
            _valid(\$k);

            $k = _any2mpz($$k) // return undef;

            # Not defined for k <= 1
            if (Math::GMPz::Rmpz_cmp_ui($k, 1) <= 0) {
                return undef;
            }
        }

#<<<
        if (!defined($k) or Math::GMPz::Rmpz_cmp_ui($k, 62) <= 0) {
            $k = defined($k) ? Math::GMPz::Rmpz_get_ui($k) : 10;

            return _set_int(scalar Math::GMPz::Rmpz_popcount($n)) if ($k == 2);

            if (Math::GMPz::Rmpz_sizeinbase($n, $k) <= 1e6) {
                return _set_int(List::Util::sum(map { $k <= 36 ? $DIGITS_36{$_} : $DIGITS_62{$_} } split(//, Math::GMPz::Rmpz_get_str($n, $k))));
            }
            else {
                $k = Math::GMPz::Rmpz_init_set_ui($k);
            }
        }
#>>>

        # Subquadratic Algorithm 1.26 FastIntegerOutput from "Modern Computer Arithmetic v0.5.9"
        if (Math::GMPz::Rmpz_fits_ulong_p($k)) {

            my $A = $n;
            my $B = Math::GMPz::Rmpz_get_ui($k);

            # When B < 2^32, use Math::Prime::Util::GMP::todigits().
            if ($B <= 4294967295 and Math::GMPz::Rmpz_sizeinbase($n, 62) <= 1e6) {
                return _set_int(
                       Math::Prime::Util::GMP::vecsum(Math::Prime::Util::GMP::todigits(Math::GMPz::Rmpz_get_str($n, 10), $B)));
            }

            # Find r such that B^(2r - 2) <= A < B^(2r)
            my $r = (__ilog__($n, $k) >> 1) + 1;

            state $Q = Math::GMPz::Rmpz_init_nobless();
            state $R = Math::GMPz::Rmpz_init_nobless();

            my $total = sub {
                my ($A, $r) = @_;

                # Cut the recursion early
                if (Math::GMPz::Rmpz_fits_ulong_p($A)) {
                    my $v = Math::GMPz::Rmpz_get_ui($A);
                    my ($sum, $m) = (0);
                    while ($v) {
                        ($v, $m) = (
                                    HAS_NEW_PRIME_UTIL
                                    ? Math::Prime::Util::divrem($v, $B)
                                    : Math::Prime::Util::GMP::divrem($v, $B)
                                   );
                        $sum += $m;
                    }
                    return $sum;
                }

                #~ if (Math::GMPz::Rmpz_cmp_ui($A, $B) < 0) {
                #~ return Math::GMPz::Rmpz_get_ui($A);
                #~ }

                my $w = ($r + 1) >> 1;
                my $t = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_ui_pow_ui($t, $B, $r);
                Math::GMPz::Rmpz_divmod($Q, $R, $A, $t);
                Math::GMPz::Rmpz_set($t, $Q);

                __SUB__->($R, $w) + __SUB__->($t, $w);
              }
              ->($A, $r);

            ($total < ULONG_MAX)
              && return _set_int($total);
        }

        # This algorithm will be used only for very large bases,
        # base > ULONG_MAX, or when the sum of digits exceeds ULONG_MAX.
        my $m   = Math::GMPz::Rmpz_init();
        my $sum = Math::GMPz::Rmpz_init_set_ui(0);

        $n = Math::GMPz::Rmpz_init_set($n);    # copy

        while (Math::GMPz::Rmpz_sgn($n) > 0) {
            Math::GMPz::Rmpz_divmod($n, $m, $n, $k);
            Math::GMPz::Rmpz_add($sum, $sum, $m);
        }

        bless \$sum;
    }

    *digits_sum = \&sumdigits;
    *sum_digits = \&sumdigits;

    sub factorial_power {
        my ($n, $p) = @_;

        _valid(\$p);

        my $sum = $n->sumdigits($p) // return undef;

        $n = _any2mpz($$n) // return undef;
        $p = _any2mpz($$p) // return undef;

        my $r = Math::GMPz::Rmpz_init();
        my $t = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_sub_ui($t, $p, 1);       # t = p-1
        Math::GMPz::Rmpz_sub($r, $n, $$sum);      # r = n-sum
        Math::GMPz::Rmpz_divexact($r, $r, $t);    # r = r/t

        bless \$r;
    }

    *factorial_valuation = \&factorial_power;

    sub length {
        my ($x, $y) = @_;

        $x = _any2mpz($$x) // return undef;

        my $neg = ((Math::GMPz::Rmpz_sgn($x) || return ONE) < 0) ? 1 : 0;

        $y = defined($y) ? do { _valid(\$y); _any2mpz($$y) // return undef } : 10;

        if ($neg) {
            $x = Math::GMPz::Rmpz_init_set($x);
            Math::GMPz::Rmpz_abs($x, $x);
        }

        _set_int(1 + (__ilog__($x, $y) // return ZERO));
    }

    *len  = \&length;
    *size = \&length;

    sub __floor__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_floor($r, $x);
            return $r;
        }

      Math_GMPq: {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($r, $x);
            Math::GMPq::Rmpq_integer_p($x) && return $r;
            Math::GMPz::Rmpz_sub_ui($r, $r, 1) if Math::GMPq::Rmpq_sgn($x) < 0;
            return $r;
        }

      Math_MPC: {
            my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($real, $x);
            Math::MPC::RMPC_IM($imag, $x);

            Math::MPFR::Rmpfr_floor($real, $real);
            Math::MPFR::Rmpfr_floor($imag, $imag);

            if (Math::MPFR::Rmpfr_zero_p($imag)) {
                return $real;
            }

            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_fr_fr($r, $real, $imag, $ROUND);
            return $r;
        }
    }

    sub floor {
        my ($x) = @_;
        ref($$x) eq 'Math::GMPz' and return $x;    # already an integer
        bless \__floor__($$x);
    }

    sub __ceil__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_ceil($r, $x);
            return $r;
        }

      Math_GMPq: {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($r, $x);
            Math::GMPq::Rmpq_integer_p($x) && return $r;
            Math::GMPz::Rmpz_add_ui($r, $r, 1) if Math::GMPq::Rmpq_sgn($x) > 0;
            return $r;
        }

      Math_MPC: {
            my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($real, $x);
            Math::MPC::RMPC_IM($imag, $x);

            Math::MPFR::Rmpfr_ceil($real, $real);
            Math::MPFR::Rmpfr_ceil($imag, $imag);

            if (Math::MPFR::Rmpfr_zero_p($imag)) {
                return $real;
            }

            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_fr_fr($r, $real, $imag, $ROUND);
            return $r;
        }
    }

    sub ceil {
        my ($x) = @_;
        ref($$x) eq 'Math::GMPz' and return $x;    # already an integer
        bless \__ceil__($$x);
    }

    *ceiling = \&ceil;

    sub __inc__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_GMPz: {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_add_ui($r, $x, 1);
            return $r;
        }

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_add_ui($r, $x, 1, $ROUND);
            return $r;
        }

      Math_GMPq: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_add_z($r, $x, $ONE);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_add_ui($r, $x, 1, $ROUND);
            return $r;
        }
    }

    sub inc {
        my ($x) = @_;
        bless \__inc__($$x);
    }

    sub __dec__ {
        my ($x) = @_;
        goto(ref($x) =~ tr/:/_/rs);

      Math_GMPz: {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_sub_ui($r, $x, 1);
            return $r;
        }

      Math_MPFR: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_sub_ui($r, $x, 1, $ROUND);
            return $r;
        }

      Math_GMPq: {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_sub_z($r, $x, $ONE);
            return $r;
        }

      Math_MPC: {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_sub_ui($r, $x, 1, $ROUND);
            return $r;
        }
    }

    sub dec {
        my ($x) = @_;
        bless \__dec__($$x);
    }

    sub __mod__ {
        my ($x, $y) = @_;
        goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

        #
        ## GMPq
        #
      Math_GMPq__Math_GMPq: {

            if (Math::GMPq::Rmpq_integer_p($y)) {
                $y = _mpq2mpz($y);
                goto Math_GMPq__Math_GMPz;
            }

            Math::GMPq::Rmpq_sgn($y) || goto &_nan;

            my $quo = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_div($quo, $x, $y);

            # Floor
            Math::GMPq::Rmpq_integer_p($quo) || do {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_set_q($z, $quo);
                Math::GMPz::Rmpz_sub_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($quo) < 0;
                Math::GMPq::Rmpq_set_z($quo, $z);
            };

            Math::GMPq::Rmpq_mul($quo, $quo, $y);
            Math::GMPq::Rmpq_sub($quo, $x, $quo);

            return $quo;
        }

      Math_GMPq__Math_GMPz: {
            Math::GMPz::Rmpz_sgn($y) || goto &_nan;
            my $r = _modular_rational($x, $y) // do {

                my $quo = Math::GMPq::Rmpq_init();
                Math::GMPq::Rmpq_div_z($quo, $x, $y);

                # Floor
                Math::GMPq::Rmpq_integer_p($quo) || do {
                    my $z = Math::GMPz::Rmpz_init();
                    Math::GMPz::Rmpz_set_q($z, $quo);
                    Math::GMPz::Rmpz_sub_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($quo) < 0;
                    Math::GMPq::Rmpq_set_z($quo, $z);
                };

                Math::GMPq::Rmpq_mul_z($quo, $quo, $y);
                Math::GMPq::Rmpq_sub($quo, $x, $quo);

                return $quo;
            };
            Math::GMPz::Rmpz_mod($r, $r, $y);
            return $r;
        }

      Math_GMPq__Math_MPFR: {
            $x = _mpq2mpfr($x);
            goto Math_MPFR__Math_MPFR;
        }

      Math_GMPq__Math_MPC: {
            $x = _mpq2mpc($x);
            goto Math_MPC__Math_MPC;
        }

        #
        ## GMPz
        #
      Math_GMPz__Math_GMPz: {

            if (Math::GMPz::Rmpz_fits_ulong_p($y)) {
                my $r = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_mod_ui($r, $x, Math::GMPz::Rmpz_get_ui($y) || goto &_nan);
                return $r;
            }

            my $sgn_y = Math::GMPz::Rmpz_sgn($y) || goto &_nan;

            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_mod($r, $x, $y);

            if (!Math::GMPz::Rmpz_sgn($r)) {
                ## ok
            }
            elsif ($sgn_y < 0) {
                Math::GMPz::Rmpz_add($r, $r, $y);
            }

            return $r;
        }

      Math_GMPz__Scalar: {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_mod_ui($r, $x, $y);
            return $r;
        }

      Math_GMPz__Math_GMPq: {
            $x = _mpz2mpq($x);
            goto Math_GMPq__Math_GMPq;
        }

      Math_GMPz__Math_MPFR: {
            $x = _mpz2mpfr($x);
            goto Math_MPFR__Math_MPFR;
        }

      Math_GMPz__Math_MPC: {
            $x = _mpz2mpc($x);
            goto Math_MPC__Math_MPC;
        }

        #
        ## MPFR
        #
      Math_MPFR__Math_MPFR: {
            my $quo = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_div($quo, $x, $y, $ROUND);
            Math::MPFR::Rmpfr_floor($quo, $quo);
            Math::MPFR::Rmpfr_mul($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);
            return $quo;
        }

      Math_MPFR__Scalar: {
            my $quo = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_div_ui($quo, $x, $y, $ROUND);
            Math::MPFR::Rmpfr_floor($quo, $quo);
            Math::MPFR::Rmpfr_mul_ui($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);
            return $quo;
        }

      Math_MPFR__Math_GMPq: {
            my $quo = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_div_q($quo, $x, $y, $ROUND);
            Math::MPFR::Rmpfr_floor($quo, $quo);
            Math::MPFR::Rmpfr_mul_q($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);
            return $quo;
        }

      Math_MPFR__Math_GMPz: {
            my $quo = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_div_z($quo, $x, $y, $ROUND);
            Math::MPFR::Rmpfr_floor($quo, $quo);
            Math::MPFR::Rmpfr_mul_z($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);
            return $quo;
        }

      Math_MPFR__Math_MPC: {
            $x = _mpfr2mpc($x);
            goto Math_MPC__Math_MPC;
        }

        #
        ## MPC
        #
      Math_MPC__Math_MPC: {
            my $quo = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_div($quo, $x, $y, $ROUND);

            my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($real, $quo);
            Math::MPC::RMPC_IM($imag, $quo);

            Math::MPFR::Rmpfr_floor($real, $real);
            Math::MPFR::Rmpfr_floor($imag, $imag);

            Math::MPC::Rmpc_set_fr_fr($quo, $real, $imag, $ROUND);

            Math::MPC::Rmpc_mul($quo, $quo, $y, $ROUND);
            Math::MPC::Rmpc_sub($quo, $x, $quo, $ROUND);

            return $quo;
        }

      Math_MPC__Scalar: {
            my $quo = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_div_ui($quo, $x, $y, $ROUND);

            my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($real, $quo);
            Math::MPC::RMPC_IM($imag, $quo);

            Math::MPFR::Rmpfr_floor($real, $real);
            Math::MPFR::Rmpfr_floor($imag, $imag);

            Math::MPC::Rmpc_set_fr_fr($quo, $real, $imag, $ROUND);

            Math::MPC::Rmpc_mul_ui($quo, $quo, $y, $ROUND);
            Math::MPC::Rmpc_sub($quo, $x, $quo, $ROUND);

            return $quo;
        }

      Math_MPC__Math_MPFR: {
            $y = _mpfr2mpc($y);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_GMPz: {
            $y = _mpz2mpc($y);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_GMPq: {
            $y = _mpq2mpc($y);
            goto Math_MPC__Math_MPC;
        }
    }

    sub mod {
        my ($x, $y) = @_;

        my $ref = ref($y);

        if (   $ref eq 'Sidef::Types::Number::Gauss'
            or $ref eq 'Sidef::Types::Number::Quaternion'
            or $ref eq 'Sidef::Types::Number::Fraction') {
            return $ref->new($x)->mod($y);
        }

        if ($ref eq 'Sidef::Types::Number::Quadratic') {
            return $ref->new($x, ZERO, $y->{w})->mod($y);
        }

        if ($ref eq 'Sidef::Types::Number::Polynomial') {
            return $ref->new(0 => $x)->mod($y);
        }

        _valid(\$y);
        bless \__mod__($$x, $$y);
    }

    sub polymod {
        my ($x, @m) = @_;

        _valid(map { \$_ } @m);

        $x = $$x;
        @m = map { $$_ } @m;

        my @r;
        foreach my $m (@m) {
            my $mod = __mod__($x, $m);

            $x = __sub__($x, $mod);
            $x = __div__($x, $m);

            push @r, $mod;
        }

        push @r, $x;
        map { bless \$_ } @r;
    }

    sub imod {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        my $sign_y = Math::GMPz::Rmpz_sgn($y)
          || goto &nan;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mod($r, $x, $y);

        if (!Math::GMPz::Rmpz_sgn($r)) {
            ## OK
        }
        elsif ($sign_y < 0) {
            Math::GMPz::Rmpz_add($r, $r, $y);
        }

        bless \$r;
    }

    sub quadratic_nonresidue {
        my ($n) = @_;

        # Least quadratic non-residue of n. (OEIS: A020649)
        # Inspired by Dana Jacobsen's code from Math::Prime::Util::PP.

        $n = _any2mpz($$n) // goto &nan;

        if (Math::GMPz::Rmpz_cmp_ui($n, 2) <= 0) {
            return bless \$n;
        }

        if (Math::GMPz::Rmpz_ui_kronecker(2, $n) == -1) {
            return TWO;
        }

        if (_primality_pretest($n) && _is_prob_prime($n)) {
            for (my $k = 3 ; ; $k = _next_prime($k)) {
                if (Math::GMPz::Rmpz_ui_kronecker($k, $n) == -1) {
                    return _set_int($k);
                }
            }
        }

        if (Math::GMPz::Rmpz_even_p($n)) {
            return TWO if Math::GMPz::Rmpz_scan1($n, 0) >= 2;
        }

        foreach my $k (3, 5, 11, 13, 19) {
            if (Math::GMPz::Rmpz_divisible_ui_p($n, $k)) {
                return TWO;
            }
        }

        my @factors = _factor_exp($n);

#<<<
        @factors = map {
            ($_ < ULONG_MAX)
                ? Math::GMPz::Rmpz_init_set_ui($_)
                : Math::GMPz::Rmpz_init_set_str("$_", 10)
        } map { $_->[0] } @factors;
#>>>

        for (my $k = 2 ; ; $k = _next_prime($k)) {
            foreach my $p (@factors) {
                if (Math::GMPz::Rmpz_cmp_ui($p, $k) > 0 and Math::GMPz::Rmpz_ui_kronecker($k, $p) == -1) {
                    return _set_int($k);
                }
            }
        }
    }

    *qnr = \&quadratic_nonresidue;

    sub _sqrtmod {    # sqrt(n) modulo a prime power p^e
        my ($n_, $p_, $e) = @_;

        if ($e == 1) {
            return Math::Prime::Util::GMP::sqrtmod($n_, $p_);
        }

        # NOTE: Cannot change `my` to `state`, because of recursion

        my $p  = Math::GMPz::Rmpz_init();
        my $pp = Math::GMPz::Rmpz_init();
        my $n  = Math::GMPz::Rmpz_init();

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();

        if (ref($n_)) {
            Math::GMPz::Rmpz_set($n, $n_);
        }
        else {
            ($n_ < ULONG_MAX and $n_ > 0)
              ? Math::GMPz::Rmpz_set_ui($n, $n_)
              : Math::GMPz::Rmpz_set_str($n, "$n_", 10);
        }

        if (ref($p_)) {
            Math::GMPz::Rmpz_set($p, $p_);
        }
        else {
            ($p_ < ULONG_MAX and $p_ > 0)
              ? Math::GMPz::Rmpz_set_ui($p, $p_)
              : Math::GMPz::Rmpz_set_str($p, "$p_", 10);
        }

        # t = p^(k-1)
        Math::GMPz::Rmpz_pow_ui($t, $p, $e - 1);

        # pp = p^k
        Math::GMPz::Rmpz_mul($pp, $t, $p);

        # n %= p^k
        Math::GMPz::Rmpz_mod($n, $n, $pp);

        if (Math::GMPz::Rmpz_sgn($n) == 0) {
            return 0;
        }

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($pp)) {
            if (defined(my $r = Math::Prime::Util::sqrtmod(Math::GMPz::Rmpz_get_ui($n), Math::GMPz::Rmpz_get_ui($pp)))) {
                return $r;
            }
        }

        if (Math::GMPz::Rmpz_cmp_ui($p, 2) == 0) {

            if ($e == 1) {
                return (Math::GMPz::Rmpz_odd_p($n) ? 1 : 0);
            }

            if ($e == 2) {
                return (Math::GMPz::Rmpz_congruent_ui_p($n, 1, 4) ? 1 : 0);
            }

            Math::GMPz::Rmpz_congruent_ui_p($n, 1, 8) or return;

            my $r = __SUB__->(Math::GMPz::Rmpz_get_str($n, 10), $p_, $e - 1) // return;

            # u = (((r^2 - n) / 2^(e-1))%2) * 2^(e-2) + r
            Math::GMPz::Rmpz_set_str($t, $r, 10);
            Math::GMPz::Rmpz_mul($u, $t, $t);
            Math::GMPz::Rmpz_sub($u, $u, $n);
            Math::GMPz::Rmpz_div_2exp($u, $u, $e - 1);
            Math::GMPz::Rmpz_mod_ui($u, $u, 2);
            Math::GMPz::Rmpz_mul_2exp($u, $u, $e - 2);
            Math::GMPz::Rmpz_add($u, $u, $t);

            return Math::GMPz::Rmpz_get_str($u, 10);
        }

        my $s = Math::Prime::Util::GMP::sqrtmod($n_, $p_) // return;

        state $w = Math::GMPz::Rmpz_init_nobless();

        ($s < ULONG_MAX)
          ? Math::GMPz::Rmpz_set_ui($w, $s)
          : Math::GMPz::Rmpz_set_str($w, $s, 10);

        # u = (p^k - 2*(p^(k-1)) + 1) / 2
        Math::GMPz::Rmpz_mul_2exp($u, $t, 1);
        Math::GMPz::Rmpz_sub($u, $pp, $u);
        Math::GMPz::Rmpz_add_ui($u, $u, 1);
        Math::GMPz::Rmpz_div_2exp($u, $u, 1);

        # sqrtmod(a, p^k) = (powmod(sqrtmod(a, p), p^(k-1), p^k) * powmod(a, u, p^k)) % p^k
        Math::GMPz::Rmpz_powm($w, $w, $t, $pp);
        Math::GMPz::Rmpz_powm($u, $n, $u, $pp);
        Math::GMPz::Rmpz_mul($w, $w, $u);
        Math::GMPz::Rmpz_mod($w, $w, $pp);

        return Math::GMPz::Rmpz_get_str($w, 10);
    }

    sub sqrtmod {
        my ($x, $y) = @_;
        _valid(\$y);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;

        Math::GMPz::Rmpz_sgn($y) <= 0 and goto &nan;

        my $n = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mod($n, $x, $y);

        if (Math::GMPz::Rmpz_sgn($n) == 0) {
            return ZERO;
        }

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($y)) {
            if (defined(my $r = Math::Prime::Util::sqrtmod(Math::GMPz::Rmpz_get_ui($n), Math::GMPz::Rmpz_get_ui($y)))) {
                return _set_int($r);
            }
        }

        my $nstr = Math::GMPz::Rmpz_get_str($n, 10);
        my $ystr = Math::GMPz::Rmpz_get_str($y, 10);

        if (_is_prob_prime($ystr)) {
            return _set_int(Math::Prime::Util::GMP::sqrtmod($nstr, $ystr) // goto &nan);
        }

        # Workaround: find all the solutions and return the smallest one
        return (_set_int($n)->sqrtmod_all(_set_int($y))->first // goto &nan);

        # The code below fails to find a solution for: sqrtmod(17640, 48465)
        my $u = Math::GMPz::Rmpz_init();
        my $v = Math::GMPz::Rmpz_init();

        my @congruences;

        foreach my $pe (_factor_exp($ystr)) {
            my ($p, $e) = @$pe;
            my $root = _sqrtmod($nstr, $p, $e) // goto &nan;
            my $pk   = Math::Prime::Util::GMP::powint($p, $e);
            push @congruences, [$root, $pk];
        }

        my $r = Math::Prime::Util::GMP::chinese(@congruences) // goto &nan;

        ($r < ULONG_MAX)
          ? Math::GMPz::Rmpz_set_ui($v, $r)
          : Math::GMPz::Rmpz_set_str($v, $r, 10);

        # Check that v^2 = m (mod y)
        Math::GMPz::Rmpz_powm_ui($u, $v, 2, $y);
        Math::GMPz::Rmpz_cmp($u, $n) == 0 or goto &nan;

        bless \$v;
    }

    sub sqrtmod_all {
        my ($A, $N) = @_;

        # Based on algorithm by Hugo van der Sanden:
        #   https://github.com/danaj/Math-Prime-Util/pull/55

        _valid(\$N);

        $A = _any2mpz($$A) // return Sidef::Types::Array::Array->new;
        $N = _any2mpz($$N) // return Sidef::Types::Array::Array->new;

        # Copy objects for modification
        $A = Math::GMPz::Rmpz_init_set($A);
        $N = Math::GMPz::Rmpz_init_set($N);

        # Make n positive when < 0
        if (Math::GMPz::Rmpz_sgn($N) < 0) {
            Math::GMPz::Rmpz_abs($N, $N);
        }

        # return [] if (n <= 0)
        if (Math::GMPz::Rmpz_sgn($N) <= 0) {
            return Sidef::Types::Array::Array->new;
        }

        # return [0] if (n == 1)
        if (Math::GMPz::Rmpz_cmp_ui($N, 1) == 0) {
            return Sidef::Types::Array::Array->new([ZERO]);
        }

        Math::GMPz::Rmpz_mod($A, $A, $N);    # a %= n

        if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($N)) {
            my @arr = Math::Prime::Util::allsqrtmod(Math::GMPz::Rmpz_get_ui($A), Math::GMPz::Rmpz_get_ui($N));
            return Sidef::Types::Array::Array->new([map { _set_int($_) } @arr]);
        }

        my $sqrtmod_pk = sub {
            my ($A, $p, $k) = @_;

            my $pk = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_pow_ui($pk, $p, $k);

            if (Math::GMPz::Rmpz_divisible_p($A, $p)) {

                if (Math::GMPz::Rmpz_divisible_p($A, $pk)) {
                    my $low = Math::GMPz::Rmpz_init();
                    Math::GMPz::Rmpz_pow_ui($low, $p, $k >> 1);
                    my $high = ($k & 1) ? ($low * $p) : $low;
                    return map { $high * $_ } 0 .. $low - 1;
                }

                my $A2 = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_divexact($A2, $A, $p);
                Math::GMPz::Rmpz_divisible_p($A2, $p) || return;

                my $pj = Math::GMPz::Rmpz_init();
                my $Aj = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_divexact($pj, $pk, $p);
                Math::GMPz::Rmpz_divexact($Aj, $A2, $p);

                return map {
                    my $q = $_;
                    map { $q * $p + $_ * $pj } 0 .. $p - 1
                } __SUB__->($Aj, $p, $k - 2);
            }

            my $pk_root = _sqrtmod($A, $p, $k) // return;
            my $q       = Math::GMPz::Rmpz_init_set_str($pk_root, 10);

            #my $q = ${_set_int($A)->sqrtmod(_set_int($pk)) // return};

            ref($q) eq 'Math::GMPz' or return;

            return ($q, $pk - $q) if ($p != 2);
            return ($q)           if ($k == 1);
            return ($q, $pk - $q) if ($k == 2);

            my $pj = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_divexact($pj, $pk, $p);

            my $q2 = Math::GMPz::Rmpz_init();

            Math::GMPz::Rmpz_mul($q2, $q, $pj - 1);
            Math::GMPz::Rmpz_mod($q2, $q2, $pk);

            return ($q, $pk - $q, $q2, $pk - $q2);
        };

        my @congruences;

        foreach my $pe (_factor_exp($N)) {
            my ($p, $k) = @$pe;

            $p =
              ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_init_set_ui($p)
              : Math::GMPz::Rmpz_init_set_str("$p", 10);

            my $pk = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_pow_ui($pk, $p, $k);

            push @congruences, [map { [$_, $pk] } $sqrtmod_pk->($A, $p, $k)];
        }

        my @roots;

        if (HAS_PRIME_UTIL) {
            Math::Prime::Util::forsetproduct(
                sub {
                    push @roots, Math::Prime::Util::GMP::chinese(@_);
                },
                @congruences
            );
        }
        else {
            require Algorithm::Loops;
            my $iter = Algorithm::Loops::NestedLoops(\@congruences);

            while (my @arr = $iter->()) {
                push @roots, Math::Prime::Util::GMP::chinese(@arr);
            }
        }

        @roots = map  { Math::GMPz::Rmpz_init_set_str($_, 10) } @roots;
        @roots = grep { ($_ * $_) % $N == $A } @roots;
        @roots = sort { Math::GMPz::Rmpz_cmp($a, $b) } @roots;
        @roots = map  { bless \$_ } @roots;

        return Sidef::Types::Array::Array->new(\@roots);
    }

    sub difference_of_squares {
        my ($n) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        # No solutions when n == 2 (mod 4). See: A016825.
        if (Math::GMPz::Rmpz_congruent_ui_p($n, 2, 4)) {
            return Sidef::Types::Array::Array->new;
        }

        my $D = $_[0]->divisors($_[0]->isqrt);

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();

        my @solutions;

        foreach my $d (@$D) {

            Math::GMPz::Rmpz_divexact($t, $n, $$d);
            Math::GMPz::Rmpz_add($u, $$d, $t);
            Math::GMPz::Rmpz_even_p($u) || next;

            my $x = Math::GMPz::Rmpz_init();
            my $y = Math::GMPz::Rmpz_init();

            Math::GMPz::Rmpz_sub($y, $t, $$d);
            Math::GMPz::Rmpz_div_2exp($x, $u, 1);
            Math::GMPz::Rmpz_div_2exp($y, $y, 1);

            unshift @solutions, Sidef::Types::Array::Array->new([(bless \$x), (bless \$y)]);
        }

        Sidef::Types::Array::Array->new(\@solutions);
    }

    *diff_of_squares = \&difference_of_squares;

    sub sum_of_squares {
        my ($n) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        Math::GMPz::Rmpz_sgn($n) >= 0
          or return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_sgn($n) == 0) {
            return Sidef::Types::Array::Array->new(Sidef::Types::Array::Array->new([ZERO, ZERO]));
        }

        my %sqrtmod_cache;

        my $sum_of_two_squares_solutions = sub {
            my ($factor_exp) = @_;

            my $prod1 = Math::GMPz::Rmpz_init_set_ui(1);    # p == 1 (mod 4)
            my $prod2 = Math::GMPz::Rmpz_init_set_ui(1);    # p == 3 (mod 4)

            my @prod1_factor_exp;

            foreach my $pp (@$factor_exp) {
                my ($p, $e) = @$pp;

                if (Math::GMPz::Rmpz_congruent_ui_p($p, 3, 4)) {    # p = 3 (mod 4)
                    $e % 2 == 0 or return;                          # power must be even
                    Math::GMPz::Rmpz_mul($prod2, $prod2, $p**($e >> 1));
                }
                elsif (Math::GMPz::Rmpz_cmp_ui($p, 2) == 0) {       # p = 2
                    if ($e % 2 == 0) {                              # power is even
                        Math::GMPz::Rmpz_mul($prod2, $prod2, $p**($e >> 1));
                    }
                    else {                                          # power is odd
                        Math::GMPz::Rmpz_mul_2exp($prod1, $prod1, 1);
                        Math::GMPz::Rmpz_mul($prod2, $prod2, $p**(($e - 1) >> 1));
                        push @prod1_factor_exp, [$p, 1];
                    }
                }
                else {                                              # p = 1 (mod 4)
                    Math::GMPz::Rmpz_mul($prod1, $prod1, $p**$e);
                    push @prod1_factor_exp, [$p, $e];
                }
            }

            Math::GMPz::Rmpz_cmp_ui($prod1, 1) == 0
              and return [0, $prod2];

            Math::GMPz::Rmpz_cmp_ui($prod1, 2) == 0
              and return [$prod2, $prod2];

            # Using sqrtmod_all() -- not very efficient
            # my @square_roots = map { $$_ } @{MONE->sqrtmod_all(_set_int($prod1))};

            my @congruences;

            foreach my $pe (@prod1_factor_exp) {
                my ($p, $e) = @$pe;
                my $pp  = $p**$e;
                my $key = Math::GMPz::Rmpz_get_str($pp, 10);
                my $r   = ($sqrtmod_cache{$key} //= Math::GMPz::Rmpz_init_set_str(_sqrtmod($pp - 1, $p, $e), 10));
                push @congruences, [[$r, $pp], [$pp - $r, $pp]];
            }

            my @square_roots;

            if (HAS_PRIME_UTIL) {
                Math::Prime::Util::forsetproduct(
                    sub {
                        push @square_roots, Math::Prime::Util::GMP::chinese(@_);
                    },
                    @congruences
                );
            }
            else {
                require Algorithm::Loops;
                my $iter = Algorithm::Loops::NestedLoops(\@congruences);

                while (my @arr = $iter->()) {
                    push @square_roots, Math::Prime::Util::GMP::chinese(@arr);
                }
            }

            my @solutions;

            foreach my $r (@square_roots) {

                my $s = Math::GMPz::Rmpz_init_set_str($r, 10);
                my $q = Math::GMPz::Rmpz_init_set($prod1);

                my $t = Math::GMPz::Rmpz_init();

                while (1) {

                    # While s^2 > prod1
                    Math::GMPz::Rmpz_mul($t, $s, $s);
                    Math::GMPz::Rmpz_cmp($t, $prod1) > 0 or last;

                    Math::GMPz::Rmpz_set($t, $s);
                    Math::GMPz::Rmpz_mod($s, $q, $s);
                    Math::GMPz::Rmpz_set($q, $t);
                }

                Math::GMPz::Rmpz_mod($q, $q, $s);
                Math::GMPz::Rmpz_mul($s, $s, $prod2);
                Math::GMPz::Rmpz_mul($q, $q, $prod2);

                push @solutions, [$s, $q];
            }

            # TODO: use the identity:
            #   (a^2 + b^2)*(c^2 + d^2) = (a*c - b*d)^2 + (a*d + b*c)^2

            foreach my $pe (@prod1_factor_exp) {
                my ($p, $e) = @$pe;

                for (my $i = $e % 2 ; $i < $e ; $i += 2) {

                    my @factor_exp;
                    foreach my $pp (@prod1_factor_exp) {
                        if (Math::GMPz::Rmpz_cmp($pp->[0], $p) == 0) {
                            push(@factor_exp, [$p, $i]) if ($i > 0);
                        }
                        else {
                            push @factor_exp, $pp;
                        }
                    }

                    my $sq = Math::GMPz::Rmpz_init();
                    Math::GMPz::Rmpz_pow_ui($sq, $p, ($e - $i) >> 1);
                    Math::GMPz::Rmpz_mul($sq, $sq, $prod2);

                    push @solutions, map {
                        [map { $_ * $sq } @$_]
                    } __SUB__->(\@factor_exp);
                }
            }

            # Return only the unique solutions
            my %seen;
            grep { !$seen{ref($_->[0]) ? Math::GMPz::Rmpz_get_str($_->[0], 10) : $_->[0]}++ } @solutions;
        };

        my @factor_exp = map {
            my ($p, $e) = @$_;
            $p =
              ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_init_set_ui($p)
              : Math::GMPz::Rmpz_init_set_str("$p", 10);
            [$p, $e]
        } _factor_exp($n);
        my @solutions = $sum_of_two_squares_solutions->(\@factor_exp);

        @solutions = sort { $a->[0] <=> $b->[0] }
          map { ($_->[0] > $_->[1]) ? [$_->[1], $_->[0]] : $_ } @solutions;

        Sidef::Types::Array::Array->new(
            [
             map {
                 Sidef::Types::Array::Array->new([map { _set_int($_) } @$_])
               } @solutions
            ]
        );
    }

    sub _modular_rational {
        my ($n, $m) = @_;

        if (ref($n) ne 'Math::GMPq') {
            $n = _any2mpq($n) // return;
        }

        state $z = Math::GMPz::Rmpz_init_nobless();

        my $t = Math::GMPz::Rmpz_init();
        Math::GMPq::Rmpq_get_den($z, $n);
        Math::GMPz::Rmpz_invert($t, $z, $m) or return;
        Math::GMPq::Rmpq_get_num($z, $n);
        Math::GMPz::Rmpz_mul($t, $t, $z);

        return $t;
    }

    sub powmod {
        my ($n, $k, $m) = @_;

        _valid(\$k, \$m);

        $n = $$n;
        $k = _any2mpz($$k) // goto &nan;
        $m = _any2mpz($$m) // goto &nan;

        Math::GMPz::Rmpz_sgn($m) || goto &nan;

        if (ref($n) ne 'Math::GMPz') {
            if (__is_int__($n)) {
                $n = _any2mpz($n) // goto &nan;
            }
            else {
                $n = _modular_rational($n, $m) // goto &nan;
            }
        }

        my $r = Math::GMPz::Rmpz_init();

        if (Math::GMPz::Rmpz_sgn($k) < 0) {
            Math::GMPz::Rmpz_invert($r, $n, $m) or goto &nan;
        }

        Math::GMPz::Rmpz_fits_ulong_p($k)
          ? Math::GMPz::Rmpz_powm_ui($r, $n, Math::GMPz::Rmpz_get_ui($k), $m)
          : Math::GMPz::Rmpz_powm($r, $n, $k, $m);

        bless \$r;
    }

    *expmod = \&powmod;

    sub complex_cmp {
        my ($x_re, $x_im, $y_re, $y_im) = @_;

        $x_im //= ZERO;
        $y_re //= ZERO;
        $y_im //= ZERO;

        _valid(\$x_im, \$y_re, \$y_im);

#<<<
        my $cmp = (
               (__cmp__($$x_re, $$y_re) // return undef)
            || (__cmp__($$x_im, $$y_im) // return undef)
        );
#>>>

        ($cmp ? ($cmp == 1 ? ONE : MONE) : ZERO);
    }

    sub complex_mod {
        my ($x, $y, $m) = @_;
        _valid(\$y, \$m);
        ((bless \__mod__($$x, $$m)), (bless \__mod__($$y, $$m)));
    }

    *cmod = \&complex_mod;

    sub complex_add {
        my ($x_re, $x_im, $y_re, $y_im) = @_;

        $x_im //= ZERO;
        $y_re //= ZERO;
        $y_im //= ZERO;

        _valid(\$x_im, \$y_re, \$y_im);
        ((bless \__add__($$x_re, $$y_re)), (bless \__add__($$x_im, $$y_im)));
    }

    *cadd = \&complex_add;

    sub complex_sub {
        my ($x_re, $x_im, $y_re, $y_im) = @_;

        $x_im //= ZERO;
        $y_re //= ZERO;
        $y_im //= ZERO;

        _valid(\$x_im, \$y_re, \$y_im);
        ((bless \__sub__($$x_re, $$y_re)), (bless \__sub__($$x_im, $$y_im)));
    }

    *csub = \&complex_sub;

    sub complex_mul {
        my ($x_re, $x_im, $y_re, $y_im) = @_;

        # (a + b*i) * (x + y*i) = (a*x - b*y) + (a*y + b*x)*i

        $x_im //= ZERO;
        $y_re //= ZERO;
        $y_im //= ZERO;

        _valid(\$x_im, \$y_re, \$y_im);

#<<<
        (
            (bless \__sub__(__mul__($$x_re, $$y_re), __mul__($$x_im, $$y_im))),
            (bless \__add__(__mul__($$x_re, $$y_im), __mul__($$x_im, $$y_re))),
        );
#>>>
    }

    *cmul = \&complex_mul;

    sub complex_div {
        my ($x_re, $x_im, $y_re, $y_im) = @_;

        # (a + b*i) / (x + y*i) = (a*x + b*y)/(x^2 + y^2) + (b*x - a*y)/(x^2 + y^2)*i

        $x_im //= ZERO;
        $y_re //= ZERO;
        $y_im //= ZERO;

        _valid(\$x_im, \$y_re, \$y_im);

        my $den = __add__(__mul__($$y_re, $$y_re), __mul__($$y_im, $$y_im));

#<<<
        (
            (bless \__div__(__add__(__mul__($$x_re, $$y_re), __mul__($$x_im, $$y_im)), $den)),
            (bless \__div__(__sub__(__mul__($$x_im, $$y_re), __mul__($$x_re, $$y_im)), $den)),
        );
#>>>
    }

    *cdiv = \&complex_div;

    sub complex_inv {
        my ($re, $im) = @_;

        $im //= ZERO;
        _valid(\$im);

        my $den = __add__(__mul__($$re, $$re), __mul__($$im, $$im));

#<<<
        (
            (bless \__div__(        $$re,  $den)),
            (bless \__div__(__neg__($$im), $den)),
        );
#>>>
    }

    *cinv = \&complex_inv;

    sub complex_invmod {
        my ($x, $y, $m) = @_;

        _valid(\$y, \$m);

        $x = _any2mpz($$x) // return (nan(), nan());
        $y = _any2mpz($$y) // return (nan(), nan());
        $m = _any2mpz($$m) // return (nan(), nan());

        my $t = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_mul($t, $x, $x);
        Math::GMPz::Rmpz_addmul($t, $y, $y);

        if (Math::GMPz::Rmpz_invert($t, $t, $m)) {

            my $c0 = Math::GMPz::Rmpz_init();
            my $c1 = Math::GMPz::Rmpz_init();

            Math::GMPz::Rmpz_mul($c0, $x, $t);
            Math::GMPz::Rmpz_mul($c1, $y, $t);
            Math::GMPz::Rmpz_neg($c1, $c1);
            Math::GMPz::Rmpz_mod($c0, $c0, $m);
            Math::GMPz::Rmpz_mod($c1, $c1, $m);

            return ((bless \$c0), (bless \$c1));
        }

        return (nan(), nan());    # no inverse
    }

    *cinvmod = \&complex_invmod;

    sub complex_ipow {
        my ($x, $y, $n) = @_;

        _valid(\$y, \$n);

        $x = _any2mpz($$x) // return (nan(), nan());
        $y = _any2mpz($$y) // return (nan(), nan());
        $n = _any2mpz($$n) // return (nan(), nan());

        my $c0 = Math::GMPz::Rmpz_init_set_ui(1);
        my $c1 = Math::GMPz::Rmpz_init_set_ui(0);

        $x = Math::GMPz::Rmpz_init_set($x);
        $y = Math::GMPz::Rmpz_init_set($y);

        my $neg = 0;
        if (Math::GMPz::Rmpz_sgn($n) < 0) {
            $n = Math::GMPz::Rmpz_init_set($n);
            Math::GMPz::Rmpz_abs($n, $n);
            $neg = 1;
        }

        state $t = Math::GMPz::Rmpz_init_nobless();

        foreach my $k (0 .. Math::GMPz::Rmpz_sizeinbase($n, 2) - 1) {

            if (Math::GMPz::Rmpz_tstbit($n, $k)) {
                Math::GMPz::Rmpz_set($t, $c0);

                Math::GMPz::Rmpz_mul($c0, $c0, $x);
                Math::GMPz::Rmpz_submul($c0, $c1, $y);

                Math::GMPz::Rmpz_mul($c1, $c1, $x);
                Math::GMPz::Rmpz_addmul($c1, $t, $y);
            }

            Math::GMPz::Rmpz_mul($t, $x, $y);
            Math::GMPz::Rmpz_mul_2exp($t, $t, 1);

            Math::GMPz::Rmpz_mul($x, $x, $x);
            Math::GMPz::Rmpz_submul($x, $y, $y);
            Math::GMPz::Rmpz_set($y, $t);
        }

        my ($r1, $r2) = ((bless \$c0), (bless \$c1));
        ($r1, $r2) = complex_inv($r1, $r2) if $neg;
        ($r1, $r2);
    }

    sub complex_pow {
        my ($x, $y, $n) = @_;

        _valid(\$y, \$n);

        if (__is_int__($$x) and __is_int__($$y)) {
            return complex_ipow($x, $y, $n);
        }

        $x = $$x;
        $y = $$y;
        $n = _any2mpz($$n) // return (nan(), nan());

        my $neg = 0;
        if (Math::GMPz::Rmpz_sgn($n) < 0) {
            $n = Math::GMPz::Rmpz_init_set($n);
            Math::GMPz::Rmpz_abs($n, $n);
            $neg = 1;
        }

        my $c0 = $ONE;
        my $c1 = $ZERO;

#<<<
        foreach my $k (0 .. Math::GMPz::Rmpz_sizeinbase($n, 2) - 1) {

            if (Math::GMPz::Rmpz_tstbit($n, $k)) {
                ($c0, $c1) = (
                    __sub__(__mul__($c0, $x), __mul__($c1, $y)),
                    __add__(__mul__($c0, $y), __mul__($c1, $x)),
                );
            }

            ($x, $y) = (
                __sub__(__mul__($x, $x), __mul__($y, $y)),
                __mul__(__mul__($x, $y), $TWO),
            );
        }
#>>>

        my ($r1, $r2) = ((bless \$c0), (bless \$c1));
        ($r1, $r2) = complex_inv($r1, $r2) if $neg;
        ($r1, $r2);
    }

    *cpow = \&complex_pow;

    sub complex_powmod {
        my ($x, $y, $n, $m) = @_;

        _valid(\$y, \$n, \$m);

        $x = $$x;
        $y = $$y;

        $n = _any2mpz($$n) // return (nan(), nan());
        $m = _any2mpz($$m) // return (nan(), nan());

        Math::GMPz::Rmpz_sgn($m) || return (nan(), nan());

        # Identities for fractional x = a/b, y = c/d:
        #   ((a/b) + (c/d)*i)^n = ((a*d + b*c*i) / (b*d))^n
        #                       = (a*d + b*c*i)^n * (b*d)^(-n)

        # We use:
        #   ((a/b) + (c/d)*i)^n mod m = (a*invmod(b,m) + c*invmod(d, m)*i)^n mod m

        if (ref($x) ne 'Math::GMPz') {
            if (__is_int__($x)) {
                $x = _any2mpz($x) // return (nan(), nan());
            }
            else {
                $x = _modular_rational($x, $m) // return (nan(), nan());
            }
        }

        if (ref($y) ne 'Math::GMPz') {
            if (__is_int__($y)) {
                $y = _any2mpz($y) // return (nan(), nan());
            }
            else {
                $y = _modular_rational($y, $m) // return (nan(), nan());
            }
        }

        $x = _any2mpz($x) // return (nan(), nan());
        $y = _any2mpz($y) // return (nan(), nan());

        my $c0 = Math::GMPz::Rmpz_init_set_ui(1);
        my $c1 = Math::GMPz::Rmpz_init_set_ui(0);

        $x = Math::GMPz::Rmpz_init_set($x);
        $y = Math::GMPz::Rmpz_init_set($y);

        state $t = Math::GMPz::Rmpz_init_nobless();

        # Handle negative exponent
        if (Math::GMPz::Rmpz_sgn($n) < 0) {

            $n = Math::GMPz::Rmpz_init_set($n);
            Math::GMPz::Rmpz_abs($n, $n);

            my $t = Math::GMPz::Rmpz_init();

            Math::GMPz::Rmpz_mul($t, $x, $x);
            Math::GMPz::Rmpz_addmul($t, $y, $y);

            if (Math::GMPz::Rmpz_invert($t, $t, $m)) {

                Math::GMPz::Rmpz_mul($c0, $x, $t);
                Math::GMPz::Rmpz_mul($c1, $y, $t);
                Math::GMPz::Rmpz_neg($c1, $c1);
                Math::GMPz::Rmpz_mod($c0, $c0, $m);
                Math::GMPz::Rmpz_mod($c1, $c1, $m);

                Math::GMPz::Rmpz_set($x, $c0);
                Math::GMPz::Rmpz_set($y, $c1);

                Math::GMPz::Rmpz_set_ui($c0, 1);
                Math::GMPz::Rmpz_set_ui($c1, 0);
            }
            else {    # no inverse exists
                return (nan(), nan());
            }
        }

        foreach my $k (0 .. Math::GMPz::Rmpz_sizeinbase($n, 2) - 1) {

            if (Math::GMPz::Rmpz_tstbit($n, $k)) {
                Math::GMPz::Rmpz_set($t, $c0);

                Math::GMPz::Rmpz_mul($c0, $c0, $x);
                Math::GMPz::Rmpz_submul($c0, $c1, $y);

                Math::GMPz::Rmpz_mul($c1, $c1, $x);
                Math::GMPz::Rmpz_addmul($c1, $t, $y);

                Math::GMPz::Rmpz_mod($c0, $c0, $m);
                Math::GMPz::Rmpz_mod($c1, $c1, $m);
            }

            Math::GMPz::Rmpz_mul($t, $x, $y);
            Math::GMPz::Rmpz_mul_2exp($t, $t, 1);

            Math::GMPz::Rmpz_powm_ui($x, $x, 2, $m);
            Math::GMPz::Rmpz_powm_ui($y, $y, 2, $m);

            Math::GMPz::Rmpz_sub($x, $x, $y);
            Math::GMPz::Rmpz_mod($y, $t, $m);
        }

        ((bless \$c0), (bless \$c1));
    }

    *cpowmod = \&complex_powmod;

    sub invmod {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_invert($r, $x, $y) || (goto &nan);
        bless \$r;
    }

    sub divmod {
        my ($x, $y, $m) = @_;

        if (defined($m)) {    # modular division

            _valid(\$y, \$m);

            $x = _any2mpz($$x) // goto &nan;
            $y = _any2mpz($$y) // goto &nan;
            $m = _any2mpz($$m) // goto &nan;

            my $r = Math::GMPz::Rmpz_init();

            if (Math::GMPz::Rmpz_divisible_p($x, $y) and Math::GMPz::Rmpz_sgn($y)) {
                Math::GMPz::Rmpz_divexact($r, $x, $y);
                Math::GMPz::Rmpz_mod($r, $r, $m);
            }
            elsif (Math::GMPz::Rmpz_invert($r, $y, $m)) {
                Math::GMPz::Rmpz_mul($r, $r, $x);
                Math::GMPz::Rmpz_mod($r, $r, $m);
            }
            else {
                goto &nan;
            }

            return bless \$r;
        }

        _valid(\$y);

        $x = _any2mpz($$x) // return (nan(), nan());
        $y = _any2mpz($$y) // return (nan(), nan());

        Math::GMPz::Rmpz_sgn($y)
          || return (nan(), nan());

        my $r = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_divmod($r, $s, $x, $y);
        ((bless \$r), (bless \$s));
    }

    sub and {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_and($r, $x, $y);
        bless \$r;
    }

    sub or {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_ior($r, $x, $y);
        bless \$r;
    }

    sub xor {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_xor($r, $x, $y);
        bless \$r;
    }

    sub not {
        my ($x) = @_;

        $x = _any2mpz($$x) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_com($r, $x);
        bless \$r;
    }

    sub bit {
        my ($x, $k) = @_;

        _valid(\$k);

        $x = _any2mpz($$x) // return undef;
        $k = _any2ui($$k)  // return undef;

        Math::GMPz::Rmpz_tstbit($x, $k) ? ONE : ZERO;
    }

    *getbit  = \&bit;
    *testbit = \&bit;

    sub setbit {
        my ($x, $k) = @_;

        _valid(\$k);

        $x = _any2mpz($$x) // return undef;
        $k = _any2ui($$k)  // return undef;

        my $r = Math::GMPz::Rmpz_init_set($x);
        Math::GMPz::Rmpz_setbit($r, $k);
        bless \$r;
    }

    sub flipbit {
        my ($x, $k) = @_;

        _valid(\$k);

        $x = _any2mpz($$x) // return undef;
        $k = _any2ui($$k)  // return undef;

        my $r = Math::GMPz::Rmpz_init_set($x);

        Math::GMPz::Rmpz_tstbit($r, $k)
          ? Math::GMPz::Rmpz_clrbit($r, $k)
          : Math::GMPz::Rmpz_setbit($r, $k);

        bless \$r;
    }

    sub clearbit {
        my ($x, $k) = @_;

        _valid(\$k);

        $x = _any2mpz($$x) // return undef;
        $k = _any2ui($$k)  // return undef;

        my $r = Math::GMPz::Rmpz_init_set($x);
        Math::GMPz::Rmpz_clrbit($r, $k);
        bless \$r;
    }

    sub bit_scan0 {
        my ($n, $k) = @_;

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // return undef } : 0;
        $n = _any2mpz($$n) // return undef;

        _set_int(Math::GMPz::Rmpz_scan0($n, $k));
    }

    sub bit_scan1 {
        my ($n, $k) = @_;

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // return undef } : 0;
        $n = _any2mpz($$n) // return undef;

        _set_int(Math::GMPz::Rmpz_scan1($n, $k));
    }

    sub ramanujan_tau {
        _set_int(Math::Prime::Util::GMP::ramanujan_tau(&_big2uistr // (goto &nan)));
    }

    *RamanujanTau = \&ramanujan_tau;

    sub ramanujan_sum {
        my ($n, $k) = @_;

        #
        ## c_k(n) = μ(k/gcd(n, k)) * φ(k) / φ(k/gcd(n, k))
        #

        _valid(\$k);

        $n = _any2mpz($$n) // goto &nan;
        $k = _any2mpz($$k) // goto &nan;

        # Make `k` positive if it is negative
        if (Math::GMPz::Rmpz_sgn($k) < 0) {
            $k = Math::GMPz::Rmpz_init_set($k);
            Math::GMPz::Rmpz_neg($k, $k);
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_gcd($r, $n, $k);
        Math::GMPz::Rmpz_divexact($r, $k, $r) if Math::GMPz::Rmpz_sgn($r);

        my $r_str = Math::GMPz::Rmpz_get_str($r, 10);
        my $mu    = Math::Prime::Util::GMP::moebius($r_str) || return ZERO;

        if (Math::GMPz::Rmpz_cmp($r, $k) == 0) {
            return ($mu == 1 ? ONE : MONE);
        }

        my $k_str = Math::GMPz::Rmpz_get_str($k, 10);
        my $phi_k = Math::Prime::Util::GMP::totient($k_str);
        my $phi_r = Math::Prime::Util::GMP::totient($r_str);

        ($phi_k < ULONG_MAX)
          ? Math::GMPz::Rmpz_set_ui($r, $phi_k)
          : Math::GMPz::Rmpz_set_str($r, $phi_k, 10);

        if ($phi_r < ULONG_MAX) {
            Math::GMPz::Rmpz_divexact_ui($r, $r, $phi_r);
        }
        else {
            my $t = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_str($t, $phi_r, 10);
            Math::GMPz::Rmpz_divexact($r, $r, $t);
        }

        Math::GMPz::Rmpz_neg($r, $r) if ($mu == -1);
        bless \$r;
    }

    *RamanujanSum = \&ramanujan_sum;

    sub subfactorial {    # OEIS: A000166
        my ($x, $y) = @_;

        my $m = _any2ui($$x) // goto &nan;
        my $k = defined($y) ? do { _valid(\$y); _any2si($$y) // goto &nan } : 0;

        my $n = $m - $k;

        return ZERO if ($k < 0);
        return ONE  if ($n == 0);
        return ZERO if ($n < 0);

        my $z = Math::GMPz::Rmpz_init();

        if ($n >= 30000) {

            state $logtau = CORE::log(6.28318530717958647692528676655900576839433879875);

            my $logn = CORE::log($n);
            my $prec = 4 + CORE::int(($n * $logn + ($logn + $logtau) / 2 - $n) / CORE::log(2));

            Math::GMPz::Rmpz_fac_ui($z, $n);

            my $f = Math::MPFR::Rmpfr_init2($prec);
            Math::MPFR::Rmpfr_set_ui($f, 1, $round_z);
            Math::MPFR::Rmpfr_exp($f, $f, $round_z);
            Math::MPFR::Rmpfr_z_div($f, $z, $f, $round_z);
            Math::MPFR::Rmpfr_add_d($f, $f, 0.5, $round_z);
            Math::MPFR::Rmpfr_floor($f, $f);
            Math::MPFR::Rmpfr_get_z($z, $f, $round_z);
        }
        else {
            Math::GMPz::Rmpz_set_str($z, Math::Prime::Util::GMP::subfactorial($n), 10);
        }

        if ($k != 0) {
            my $t = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_bin_uiui($t, $m, $k);
            Math::GMPz::Rmpz_mul($z, $z, $t);
        }

        bless \$z;
    }

    sub factorial_sum {
        my ($n) = @_;
        $n = _any2ui($$n) // goto &nan;
        _set_int(Math::Prime::Util::GMP::factorial_sum($n));
    }

    *left_factorial = \&factorial_sum;

    sub superprimorial {    # A006939
        my ($n) = @_;

        $n = _any2ui($$n) // goto &nan;

        $n || return ONE;

        my @terms;
        my $k = 1;

        foreach my $p (Math::Prime::Util::GMP::sieve_primes(2, ${$_[0]->nth_prime})) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_ui_pow_ui($z, $p, $n - $k + 1);
            push @terms, $z;
            ++$k;
        }

        bless \_binsplit(\@terms, \&__mul__);
    }

    sub lnsuperprimorial {
        my ($n) = @_;

        $n = _any2ui($$n) // goto &nan;

        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        my $t = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPFR::Rmpfr_set_ui($r, 0, $ROUND);

        my $k = 1;
        foreach my $p (Math::Prime::Util::GMP::sieve_primes(2, ${$_[0]->nth_prime})) {
            Math::MPFR::Rmpfr_set_ui($t, $p, $ROUND);
            Math::MPFR::Rmpfr_log($t, $t, $ROUND);
            Math::MPFR::Rmpfr_mul_ui($t, $t, $n - $k + 1, $ROUND);
            Math::MPFR::Rmpfr_add($r, $r, $t, $ROUND);
            ++$k;
        }

        bless \$r;
    }

    *superprimorial_ln  = \&lnsuperprimorial;
    *superprimorial_log = \&lnsuperprimorial;

    sub superfactorial {    # A000178
        my ($n) = @_;

        $n = _any2ui($$n) // goto &nan;

        my @terms;
        foreach my $k (2 .. $n) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_ui_pow_ui($z, $k, $n - $k + 1);
            push @terms, $z;
        }

        @terms || return ONE;
        bless \_binsplit(\@terms, \&__mul__);
    }

    sub lnsuperfactorial {
        my ($n) = @_;

        $n = _any2ui($$n) // goto &nan;

        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        my $t = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPFR::Rmpfr_set_ui($r, 0, $ROUND);

        foreach my $k (2 .. $n) {
            Math::MPFR::Rmpfr_set_ui($t, $k, $ROUND);
            Math::MPFR::Rmpfr_log($t, $t, $ROUND);
            Math::MPFR::Rmpfr_mul_ui($t, $t, $n - $k + 1, $ROUND);
            Math::MPFR::Rmpfr_add($r, $r, $t, $ROUND);
        }

        bless \$r;
    }

    *superfactorial_ln  = \&lnsuperfactorial;
    *superfactorial_log = \&lnsuperfactorial;

    sub hyperfactorial {
        my ($n) = @_;

        $n = _any2ui($$n) // goto &nan;

        my @terms;
        foreach my $k (2 .. $n) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_ui_pow_ui($z, $k, $k);
            push @terms, $z;
        }

        @terms || return ONE;
        bless \_binsplit(\@terms, \&__mul__);
    }

    sub lnhyperfactorial {
        my ($n) = @_;

        $n = _any2ui($$n) // goto &nan;

        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        my $t = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPFR::Rmpfr_set_ui($r, 0, $ROUND);

        foreach my $k (2 .. $n) {
            Math::MPFR::Rmpfr_set_ui($t, $k, $ROUND);
            Math::MPFR::Rmpfr_log($t, $t, $ROUND);
            Math::MPFR::Rmpfr_mul_ui($t, $t, $k, $ROUND);
            Math::MPFR::Rmpfr_add($r, $r, $t, $ROUND);
        }

        bless \$r;
    }

    *hyperfactorial_ln  = \&lnhyperfactorial;
    *hyperfactorial_log = \&lnhyperfactorial;

    sub factorial {
        my ($n) = @_;
        $n = _any2ui($$n) // goto &nan;
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fac_ui($r, $n);
        bless \$r;
    }

    *fac = \&factorial;

    sub factorialmod {
        my ($n, $m) = @_;
        _valid(\$m);

        $n = _any2mpz($$n) // goto &nan;
        $m = _any2mpz($$m) // goto &nan;

        my $r;

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n) and Math::GMPz::Rmpz_fits_ulong_p($m)) {
            $r = Math::Prime::Util::factorialmod(Math::GMPz::Rmpz_get_ui($n), Math::GMPz::Rmpz_get_ui($m)) // goto &nan;
        }
        else {
            $r = Math::Prime::Util::GMP::factorialmod(_big2uistr($n) // (goto &nan), _big2uistr($m) // (goto &nan))
              // goto &nan;
        }

        _set_int($r);
    }

    sub double_factorial {
        my ($x) = @_;
        my $ui  = _any2ui($$x) // (goto &nan);
        my $z   = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_2fac_ui($z, $ui);
        bless \$z;
    }

    *dfac       = \&double_factorial;
    *dfactorial = \&double_factorial;

    sub multi_factorial {
        my ($x, $y) = @_;
        _valid(\$y);
        my $ui1 = _any2ui($$x) // (goto &nan);
        my $ui2 = _any2ui($$y) // (goto &nan);
        my $z   = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mfac_uiui($z, $ui1, $ui2);
        bless \$z;
    }

    *mfac       = \&multi_factorial;
    *mfactorial = \&multi_factorial;

    #
    ## falling_factorial(x, +y) = binomial(x, y) * y!
    ## falling_factorial(x, -y) = 1/falling_factorial(x + y, y)
    #

    sub falling_factorial {
        my ($x, $y) = @_;
        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2si($$y)  // (goto &nan);

        my $r = Math::GMPz::Rmpz_init_set($x);

        if ($y < 0) {
            Math::GMPz::Rmpz_add_ui($r, $r, CORE::abs($y));
        }

        Math::GMPz::Rmpz_bin_ui($r, $r, CORE::abs($y));

        Math::GMPz::Rmpz_sgn($r) || do {
            $y < 0
              ? (goto &nan)
              : (return ZERO);
        };

        state $t = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_fac_ui($t, CORE::abs($y));
        Math::GMPz::Rmpz_mul($r, $r, $t);

        if ($y < 0) {
            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_z($q, $r);
            Math::GMPq::Rmpq_inv($q, $q);
            return bless \$q;
        }

        bless \$r;
    }

    #
    ## rising_factorial(x, +y) = binomial(x + y - 1, y) * y!
    ## rising_factorial(x, -y) = 1/rising_factorial(x - y, y)
    #

    sub rising_factorial {
        my ($x, $y) = @_;
        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2si($$y)  // (goto &nan);

        my $r = Math::GMPz::Rmpz_init_set($x);
        Math::GMPz::Rmpz_add_ui($r, $r, CORE::abs($y));
        Math::GMPz::Rmpz_sub_ui($r, $r, 1);

        if ($y < 0) {
            Math::GMPz::Rmpz_sub_ui($r, $r, CORE::abs($y));
        }

        Math::GMPz::Rmpz_bin_ui($r, $r, CORE::abs($y));

        Math::GMPz::Rmpz_sgn($r) || do {
            $y < 0
              ? (goto &nan)
              : (return ZERO);
        };

        state $t = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_fac_ui($t, CORE::abs($y));
        Math::GMPz::Rmpz_mul($r, $r, $t);

        if ($y < 0) {
            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_z($q, $r);
            Math::GMPq::Rmpq_inv($q, $q);
            return bless \$q;
        }

        bless \$r;
    }

    sub primorial {
        my ($x) = @_;
        my $ui  = _any2ui($$x) // goto &nan;
        my $z   = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_primorial_ui($z, $ui);
        bless \$z;
    }

    sub primorial_inflation {    # A108951(n)
        my ($n) = @_;

        $n = $$n;

        if (ref($n) eq 'Math::GMPq') {    # handle rational inputs (not very efficient)

            my $num = Math::GMPz::Rmpz_init();
            my $den = Math::GMPz::Rmpz_init();

            Math::GMPq::Rmpq_get_num($num, $n);
            Math::GMPq::Rmpq_get_den($den, $n);

            my $t1 = (bless \$num)->primorial_inflation;
            my $t2 = (bless \$den)->primorial_inflation;

            return $t1->div($t2);
        }

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $prod = Math::GMPz::Rmpz_init_set_ui(1);
        my $tmp  = Math::GMPz::Rmpz_init();

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;
            ($p < ULONG_MAX) || goto &nan;

            my $primorial =
              ($p <= 1e5)
              ? _cached_primorial($p, 1e4)
              : do {
                Math::GMPz::Rmpz_primorial_ui($tmp, $p);
                $tmp;
              };

            if ($e > 1) {
                Math::GMPz::Rmpz_pow_ui($tmp, $primorial, $e);
                Math::GMPz::Rmpz_mul($prod, $prod, $tmp);
            }
            else {
                Math::GMPz::Rmpz_mul($prod, $prod, $primorial);
            }
        }

        bless \$prod;
    }

    sub primorial_deflation {    # A319626(n) / A319627(n)
        my ($n) = @_;

        my $prod = Math::GMPq::Rmpq_init();
        my $tmp  = Math::GMPq::Rmpq_init();

        Math::GMPq::Rmpq_set_ui($prod, 1, 1);

        $n = _big2uistr($n) // goto &nan;

        foreach my $pe (_factor_exp($n)) {
            my ($p, $e) = @$pe;

            my $q = ($p <= 2) ? 1 : _prev_prime($p);

            if ($p < ULONG_MAX) {
                Math::GMPq::Rmpq_set_ui($tmp, $p, $q);
            }
            else {
                Math::GMPq::Rmpq_set_str($tmp, "$p/$q", 10);
            }

            if ($e > 1) {
                Math::GMPq::Rmpq_pow_ui($tmp, $tmp, $e);
            }

            Math::GMPq::Rmpq_mul($prod, $prod, $tmp);
        }

        if (Math::GMPq::Rmpq_integer_p($prod)) {
            $prod = _mpq2mpz($prod);
        }

        bless \$prod;
    }

    sub pn_primorial {
        my ($x) = @_;
        _set_int(Math::Prime::Util::GMP::pn_primorial(_any2ui($$x) // goto &nan));
    }

    sub lucas {
        my ($x) = @_;
        my $ui  = _any2ui($$x) // (goto &nan);
        my $z   = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_lucnum_ui($z, $ui);
        bless \$z;
    }

    *Lucas = \&lucas;

    sub lucasu {
        my ($p, $q, $n) = @_;

        _valid(\$q, \$n);

        $p = _big2istr($p)  // goto &nan;
        $q = _big2istr($q)  // goto &nan;
        $n = _big2uistr($n) // goto &nan;

        _set_int(Math::Prime::Util::GMP::lucasu($p, $q, $n));
    }

    *lucasU = \&lucasu;
    *LucasU = \&lucasu;

    sub lucasv {
        my ($p, $q, $n) = @_;

        _valid(\$q, \$n);

        $p = _big2istr($p)  // goto &nan;
        $q = _big2istr($q)  // goto &nan;
        $n = _big2uistr($n) // goto &nan;

        _set_int(Math::Prime::Util::GMP::lucasv($p, $q, $n));
    }

    *lucasV = \&lucasv;
    *LucasV = \&lucasv;

    sub __lucasUVmod__ {
        my ($P, $Q, $n, $m) = @_;

        my $U1 = Math::GMPz::Rmpz_init_set_ui(1);

        my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set($P));
        my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

        Math::GMPz::Rmpz_sgn($n) == 0
          and return (Math::GMPz::Rmpz_init_set_ui(0), Math::GMPz::Rmpz_init_set_ui(2));

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_scan1($n, 0);

        Math::GMPz::Rmpz_div_2exp($t, $n, $s + 1);

        foreach my $bit (split(//, Math::GMPz::Rmpz_get_str($t, 2))) {

            Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
            Math::GMPz::Rmpz_mod($Q1, $Q1, $m);

            if ($bit) {
                Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
                Math::GMPz::Rmpz_mul($U1, $U1, $V2);
                Math::GMPz::Rmpz_mul($V1, $V1, $V2);

                Math::GMPz::Rmpz_powm_ui($V2, $V2, 2, $m);
                Math::GMPz::Rmpz_submul($V1, $Q1, $P);
                Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);

                Math::GMPz::Rmpz_mod($V1, $V1, $m);
                Math::GMPz::Rmpz_mod($U1, $U1, $m);
            }
            else {
                Math::GMPz::Rmpz_set($Q2, $Q1);
                Math::GMPz::Rmpz_mul($U1, $U1, $V1);
                Math::GMPz::Rmpz_mul($V2, $V2, $V1);
                Math::GMPz::Rmpz_sub($U1, $U1, $Q1);

                Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
                Math::GMPz::Rmpz_submul($V2, $Q1, $P);
                Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);

                Math::GMPz::Rmpz_mod($V2, $V2, $m);
                Math::GMPz::Rmpz_mod($U1, $U1, $m);
            }
        }

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
        Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
        Math::GMPz::Rmpz_mul($U1, $U1, $V1);
        Math::GMPz::Rmpz_mul($V1, $V1, $V2);
        Math::GMPz::Rmpz_sub($U1, $U1, $Q1);
        Math::GMPz::Rmpz_submul($V1, $Q1, $P);
        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);

        for (1 .. $s) {
            Math::GMPz::Rmpz_mul($U1, $U1, $V1);
            Math::GMPz::Rmpz_mod($U1, $U1, $m);
            Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
            Math::GMPz::Rmpz_submul_ui($V1, $Q1, 2);
            Math::GMPz::Rmpz_powm_ui($Q1, $Q1, 2, $m);
        }

        Math::GMPz::Rmpz_mod($U1, $U1, $m);
        Math::GMPz::Rmpz_mod($V1, $V1, $m);

        return ($U1, $V1);
    }

    sub __lucasVmod__ {
        my ($P, $Q, $n, $m) = @_;

        my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set($P));
        my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

        foreach my $bit (split(//, Math::GMPz::Rmpz_get_str($n, 2))) {

            Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
            Math::GMPz::Rmpz_mod($Q1, $Q1, $m);

            if ($bit) {
                Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
                Math::GMPz::Rmpz_mul($V1, $V1, $V2);
                Math::GMPz::Rmpz_powm_ui($V2, $V2, 2, $m);
                Math::GMPz::Rmpz_submul($V1, $P, $Q1);
                Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);
                Math::GMPz::Rmpz_mod($V1, $V1, $m);
            }
            else {
                Math::GMPz::Rmpz_set($Q2, $Q1);
                Math::GMPz::Rmpz_mul($V2, $V2, $V1);
                Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
                Math::GMPz::Rmpz_submul($V2, $P, $Q1);
                Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);
                Math::GMPz::Rmpz_mod($V2, $V2, $m);
            }
        }

        Math::GMPz::Rmpz_mod($V1, $V1, $m);

        return ($V1, $V2);
    }

    sub _modular_lucas_UV {
        my ($P, $Q, $n, $m) = @_;

        if (    Math::GMPz::Rmpz_cmpabs_ui($P, $LUCAS_PQ_LIMIT) < 0
            and Math::GMPz::Rmpz_cmpabs_ui($Q, $LUCAS_PQ_LIMIT) < 0) {
            my ($U, $V);
            if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($m) and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                eval {
                    ($U, $V) =
                      Math::Prime::Util::lucas_sequence(Math::GMPz::Rmpz_get_ui($m), Math::GMPz::Rmpz_get_si($P),
                                                        Math::GMPz::Rmpz_get_si($Q), Math::GMPz::Rmpz_get_ui($n));
                };
            }
            else {
                eval { ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($m, $P, $Q, $n) };
            }
            defined($U) && defined($V) && return (map { _str2obj($_) } ($U, $V));
        }

        state $D = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_mul($D, $P, $P);
        Math::GMPz::Rmpz_submul_ui($D, $Q, 4);

        # When `gcd(P*P - 4*Q, m) = 1`, we can use a faster algorithm
        if (Math::GMPz::Rmpz_invert($D, $D, $m)) {

            my ($V1, $V2) = __lucasVmod__($P, $Q, $n, $m);

            Math::GMPz::Rmpz_mul_2exp($V2, $V2, 1);
            Math::GMPz::Rmpz_submul($V2, $V1, $P);
            Math::GMPz::Rmpz_mul($V2, $V2, $D);
            Math::GMPz::Rmpz_mod($V2, $V2, $m);

            return ($V2, $V1);
        }

        __lucasUVmod__($P, $Q, $n, $m);
    }

    sub _modular_lucas_U {
        my ($P, $Q, $n, $m) = @_;

        if (    Math::GMPz::Rmpz_cmpabs_ui($P, $LUCAS_PQ_LIMIT) < 0
            and Math::GMPz::Rmpz_cmpabs_ui($Q, $LUCAS_PQ_LIMIT) < 0) {
            my ($U, $V);
            if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($m) and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                eval {
                    ($U, $V) =
                      Math::Prime::Util::lucas_sequence(Math::GMPz::Rmpz_get_ui($m), Math::GMPz::Rmpz_get_si($P),
                                                        Math::GMPz::Rmpz_get_si($Q), Math::GMPz::Rmpz_get_ui($n));
                };
            }
            else {
                eval { ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($m, $P, $Q, $n) };
            }
            defined($U) && return _str2obj($U);
        }

        state $D = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_mul($D, $P, $P);
        Math::GMPz::Rmpz_submul_ui($D, $Q, 4);

        # When `gcd(P*P - 4*Q, m) = 1`, we can use a faster algorithm
        if (Math::GMPz::Rmpz_invert($D, $D, $m)) {

            my ($V1, $V2) = __lucasVmod__($P, $Q, $n, $m);

            Math::GMPz::Rmpz_mul_2exp($V2, $V2, 1);
            Math::GMPz::Rmpz_submul($V2, $V1, $P);
            Math::GMPz::Rmpz_mul($V2, $V2, $D);
            Math::GMPz::Rmpz_mod($V2, $V2, $m);

            return $V2;
        }

        (__lucasUVmod__($P, $Q, $n, $m))[0];
    }

    sub _modular_lucas_V {
        my ($P, $Q, $n, $m) = @_;

        if (    Math::GMPz::Rmpz_cmpabs_ui($P, $LUCAS_PQ_LIMIT) < 0
            and Math::GMPz::Rmpz_cmpabs_ui($Q, $LUCAS_PQ_LIMIT) < 0) {
            my ($U, $V);
            if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($m) and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                eval {
                    ($U, $V) =
                      Math::Prime::Util::lucas_sequence(Math::GMPz::Rmpz_get_ui($m), Math::GMPz::Rmpz_get_si($P),
                                                        Math::GMPz::Rmpz_get_si($Q), Math::GMPz::Rmpz_get_ui($n));
                };
            }
            else {
                eval { ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($m, $P, $Q, $n) };
            }
            defined($V) && return _str2obj($V);
        }

        (__lucasVmod__($P, $Q, $n, $m))[0];
    }

    sub lucasumod {
        my ($P, $Q, $n, $m) = @_;

        _valid(\$Q, \$n, \$m);

        $P = _any2mpz($$P) // goto &nan;
        $Q = _any2mpz($$Q) // goto &nan;
        $n = _any2mpz($$n) // goto &nan;
        $m = _any2mpz($$m) // goto &nan;

        # undefined for m=0
        Math::GMPz::Rmpz_sgn($m) || goto &nan;

        # U_0(P, Q) = 0
        Math::GMPz::Rmpz_sgn($n) || return ZERO;

        # undefined for n < 0
        Math::GMPz::Rmpz_sgn($n) < 0 && goto &nan;

        bless \_modular_lucas_U($P, $Q, $n, $m);
    }

    *LucasUmod = \&lucasumod;
    *lucasUmod = \&lucasumod;

    sub lucasvmod {
        my ($P, $Q, $n, $m) = @_;

        _valid(\$Q, \$n, \$m);

        $P = _any2mpz($$P) // goto &nan;
        $Q = _any2mpz($$Q) // goto &nan;
        $n = _any2mpz($$n) // goto &nan;
        $m = _any2mpz($$m) // goto &nan;

        # undefined for m=0
        Math::GMPz::Rmpz_sgn($m) || goto &nan;

        # undefined for n < 0
        Math::GMPz::Rmpz_sgn($n) < 0 && goto &nan;

        bless \_modular_lucas_V($P, $Q, $n, $m);
    }

    *LucasVmod = \&lucasvmod;
    *lucasVmod = \&lucasvmod;

    sub lucasuvmod {
        my ($P, $Q, $n, $m) = @_;

        _valid(\$Q, \$n, \$m);

        $P = _any2mpz($$P) // goto &nan;
        $Q = _any2mpz($$Q) // goto &nan;
        $n = _any2mpz($$n) // goto &nan;
        $m = _any2mpz($$m) // goto &nan;

        # undefined for m=0
        Math::GMPz::Rmpz_sgn($m) || return (nan(), nan());

        # undefined for n < 0
        Math::GMPz::Rmpz_sgn($n) < 0 && return (nan(), nan());

        my ($U, $V) = _modular_lucas_UV($P, $Q, $n, $m);

        ((bless \$U), (bless \$V));
    }

    *LucasUVmod = \&lucasuvmod;
    *lucasUVmod = \&lucasuvmod;

    #
    ## Chebyshev polynomials: T_n(x)
    #

    sub chebyshevt {
        my ($n, $x) = @_;

        _valid(\$n);

        $n = _any2si($$n) // goto &nan;
        $n = -$n if $n < 0;
        $n == 0 and return ONE;

        if (defined($x) and ref($x) ne 'Sidef::Types::Number::Polynomial') {
            _valid(\$x);
        }
        else {
            $x //= Sidef::Types::Number::Polynomial->new(1 => ONE);
        }

        $n == 1 and return $x;

        if (ref($x) eq __PACKAGE__) {
            if (ref($$x) eq 'Math::GMPz' or (__is_rat__($$x) and __is_int__($$x))) {
                return _set_int(Math::Prime::Util::GMP::divint(Math::Prime::Util::GMP::lucasv(2 * $$x, 1, $n), 2));
            }
        }

        # T_n(x) = 1/2 * ((x - sqrt(x^2 - 1))^n + (x + sqrt(x^2 - 1))^n)

        my $e = _set_int($n);
        my $Q = Sidef::Types::Number::Quadratic->new(ZERO, ONE, $x->mul($x)->dec);
        my $r = $Q->neg->add($x)->pow($e);

        $r->a;
    }

    *chebyshevT = \&chebyshevt;
    *ChebyshevT = \&chebyshevt;

    #
    ## Chebyshev polynomials: U_n(x)
    #

    sub chebyshevu {
        my ($n, $x) = @_;

        _valid(\$n);

        $n = _any2si($$n) // goto &nan;
        $n == 0 and return ONE;

        my $negative = 0;

        if ($n < 0) {

            $n == -1 and return ZERO;
            $n == -2 and return MONE;

            $n        = -$n - 2;
            $negative = 1;
        }

        if (defined($x) and ref($x) ne 'Sidef::Types::Number::Polynomial') {
            _valid(\$x);
        }
        else {
            $x //= Sidef::Types::Number::Polynomial->new(1 => ONE);
        }

        if (ref($x) eq __PACKAGE__) {
            if (ref($$x) eq 'Math::GMPz' or (__is_rat__($$x) and __is_int__($$x))) {
                my $r = _set_int(Math::Prime::Util::GMP::lucasu(2 * $$x, 1, $n + 1));
                $r = $r->neg if $negative;
                return $r;
            }
        }

        # U_n(x) = ((x + sqrt(x^2 - 1))^(n+1) - (x - sqrt(x^2 - 1))^(n+1)) / (2 * sqrt(x^2 - 1))

        my $e = _set_int($n + 1);
        my $Q = Sidef::Types::Number::Quadratic->new(ZERO, ONE, $x->mul($x)->dec);

        my $r = $Q->add($x)->pow($e)->b;
        $r = $r->neg if $negative;
        $r;
    }

    *ChebyshevU = \&chebyshevu;
    *chebyshevU = \&chebyshevu;

    #
    ## Modular Chebyshev polynomials: T_n(x) mod m
    #

    sub chebyshevTmod {
        my ($n, $x, $m) = @_;

        _valid(\$n, \$x, \$m);

        $n = _any2mpz($$n) // goto &nan;
        $x = $$x;
        $m = _any2mpz($$m) // goto &nan;

        if (Math::GMPz::Rmpz_sgn($n) < 0) {
            $n = Math::GMPz::Rmpz_init_set($n);    # copy
            Math::GMPz::Rmpz_abs($n, $n);
        }

        if (Math::GMPz::Rmpz_odd_p($m) and (ref($x) eq 'Math::GMPz' or (__is_rat__($x) and __is_int__($x)))) {
            return _set_int(2 * $x)->lucasVmod(_set_int(1), (bless \$n), (bless \$m))->divmod(TWO, (bless \$m));
        }

        # T_n(x) = 1/2 * ((x - sqrt(x^2 - 1))^n + (x + sqrt(x^2 - 1))^n)

        my $Q = Sidef::Types::Number::Quadratic->new(ZERO, ONE, bless \__dec__(__mul__($x, $x)));
        my $r = ((bless \$x)->sub($Q))->powmod((bless \$n), (bless \$m));

        $r->a->mod(bless \$m);
    }

    #
    ## Modular Chebyshev polynomials: U_n(x) mod m
    #

    sub chebyshevUmod {
        my ($n, $x, $m) = @_;

        _valid(\$x, \$m);

        $n = _any2mpz($$n) // goto &nan;
        $x = $$x;
        $m = _any2mpz($$m) // goto &nan;

        my $negative = 0;

        if (Math::GMPz::Rmpz_sgn($n) < 0) {

            if (Math::GMPz::Rmpz_cmp_si($n, -1) == 0) {
                return ((ZERO)->mod(bless \$m));
            }

            if (Math::GMPz::Rmpz_cmp_si($n, -2) == 0) {
                return ((MONE)->mod(bless \$m));
            }

            $n        = -$n - 2;
            $negative = 1;
        }

        if (ref($x) eq 'Math::GMPz' or (__is_rat__($x) and __is_int__($x))) {
            my $r = _set_int(2 * $x)->lucasUmod(_set_int(1), (bless \$n)->inc, (bless \$m));
            $r = $r->neg->mod(bless \$m) if $negative;
            return $r;
        }

        # U_n(x) = ((x + sqrt(x^2 - 1))^(n+1) - (x - sqrt(x^2 - 1))^(n+1)) / (2 * sqrt(x^2 - 1))

        my $Q = Sidef::Types::Number::Quadratic->new(ZERO, ONE, bless \__dec__(__mul__($x, $x)));
        my $r = ((bless \$x)->add($Q))->powmod((bless \$n)->inc, (bless \$m))->b;

        $r = $r->neg if $negative;
        $r->mod(bless \$m);
    }

    #
    ## Legendre polynomials: P_n(x)
    #

    sub legendre_polynomial {
        my ($n, $x) = @_;

        my $polynomial = 0;

        if (defined($x) and ref($x) ne 'Sidef::Types::Number::Polynomial') {
            _valid(\$x);
        }
        else {
            $x //= Sidef::Types::Number::Polynomial->new(1 => ONE);
            $polynomial = 1;
        }

        $n = _any2ui($$n) // goto &nan;

        $n == 0 && return ONE;
        $n == 1 && return $x;

        my ($x1, $x2) = ($x->dec, $x->inc);

        if (!$polynomial) {
            $x1 = $$x1;
            $x2 = $$x2;
        }

        my $t = Math::GMPz::Rmpz_init();

        my @terms;
        foreach my $k (0 .. $n) {

            Math::GMPz::Rmpz_bin_uiui($t, $n, $k);
            Math::GMPz::Rmpz_mul($t, $t, $t);

            if ($polynomial) {
                push @terms, $x1->pow(_set_int($n - $k))->mul($x2->pow(_set_int($k)))->mul(bless \$t);
            }
            else {
                push @terms, __mul__(__mul__(__pow__($x1, $n - $k), __pow__($x2, $k)), $t);
            }
        }

        if ($polynomial) {
            my $sum = _binsplit(\@terms, \&Sidef::Types::Number::Polynomial::add);
            Math::GMPz::Rmpz_set_ui($t, 0);
            Math::GMPz::Rmpz_setbit($t, $n);
            return $sum->div(bless \$t);
        }

        my $sum = _binsplit(\@terms, \&__add__);
        Math::GMPz::Rmpz_set_ui($t, 0);
        Math::GMPz::Rmpz_setbit($t, $n);
        bless \__div__($sum, $t);
    }

    *LegendreP = \&legendre_polynomial;
    *legendrep = \&legendre_polynomial;
    *legendreP = \&legendre_polynomial;

    #
    ## The physicists' Hermite polynomials H_n(x)
    #

    sub hermiteH {
        my ($n, $x) = @_;

        my $polynomial = 0;

        if (defined($x) and ref($x) ne 'Sidef::Types::Number::Polynomial') {
            _valid(\$x);
        }
        else {
            $x //= Sidef::Types::Number::Polynomial->new(1 => ONE);
            $polynomial = 1;
        }

        $n = _any2ui($$n) // goto &nan;

        $n == 0 && return ONE;
        $x = $x->add($x);
        $n == 1 && return $x;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init_set_ui(1);

        my $v = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fac_ui($v, $n);

        my @terms;
        foreach my $m (0 .. $n >> 1) {

            Math::GMPz::Rmpz_mul($t, $v, $u);
            Math::GMPz::Rmpz_neg($t, $t) if ($m & 1);

            if ($polynomial) {
                push @terms, $x->pow(_set_int($n - ($m << 1)))->div(bless \$t);
            }
            else {
                push @terms, __div__(__pow__($$x, $n - ($m << 1)), $t);
            }

            my $d = ($n - ($m << 1)) * ($n - ($m << 1) - 1);
            Math::GMPz::Rmpz_divexact_ui($v, $v, $d) if $d;
            Math::GMPz::Rmpz_mul_ui($u, $u, $m + 1);
        }

        Math::GMPz::Rmpz_fac_ui($v, $n);

        if ($polynomial) {
            my $sum = _binsplit(\@terms, \&Sidef::Types::Number::Polynomial::add);
            return $sum->mul(bless \$v);
        }

        my $sum = _binsplit(\@terms, \&__add__);
        bless \__mul__($sum, $v);
    }

    *HermiteH            = \&hermiteH;
    *hermite_polynomialH = \&hermiteH;

    #
    ## The probabilists' Hermite polynomials He_n(x)
    #

    sub hermiteHe {
        my ($n, $x) = @_;

        my $polynomial = 0;

        if (defined($x) and ref($x) ne 'Sidef::Types::Number::Polynomial') {
            _valid(\$x);
        }
        else {
            $x //= Sidef::Types::Number::Polynomial->new(1 => ONE);
            $polynomial = 1;
        }

        $n = _any2ui($$n) // goto &nan;

        $n == 0 && return ONE;
        $n == 1 && return $x;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init_set_ui(1);

        my $v = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fac_ui($v, $n);

        my @terms;
        foreach my $m (0 .. $n >> 1) {

            Math::GMPz::Rmpz_mul($t, $v, $u);
            Math::GMPz::Rmpz_mul_2exp($t, $t, $m);
            Math::GMPz::Rmpz_neg($t, $t) if ($m & 1);

            if ($polynomial) {
                push @terms, $x->pow(_set_int($n - ($m << 1)))->div(bless \$t);
            }
            else {
                push @terms, __div__(__pow__($$x, $n - ($m << 1)), $t);
            }

            my $d = ($n - ($m << 1)) * ($n - ($m << 1) - 1);
            Math::GMPz::Rmpz_divexact_ui($v, $v, $d) if $d;
            Math::GMPz::Rmpz_mul_ui($u, $u, $m + 1);
        }

        Math::GMPz::Rmpz_fac_ui($v, $n);

        if ($polynomial) {
            my $sum = _binsplit(\@terms, \&Sidef::Types::Number::Polynomial::add);
            return $sum->mul(bless \$v);
        }

        my $sum = _binsplit(\@terms, \&__add__);
        bless \__mul__($sum, $v);
    }

    *HermiteHe            = \&hermiteHe;
    *hermite_polynomialHe = \&hermiteHe;

    #
    ## Laguerre polynomials: L_n(x)
    #

    sub laguerreL {
        my ($n, $x) = @_;

        my $polynomial = 0;

        if (defined($x) and ref($x) ne 'Sidef::Types::Number::Polynomial') {
            _valid(\$x);
        }
        else {
            $x //= Sidef::Types::Number::Polynomial->new(1 => ONE);
            $polynomial = 1;
        }

        $n = _any2ui($$n) // goto &nan;
        $n || return ONE;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init_set_ui(1);

        my @terms;
        foreach my $k (0 .. $n) {

            Math::GMPz::Rmpz_bin_uiui($t, $n, $k);
            Math::GMPz::Rmpz_neg($t, $t) if ($k & 1);

            if ($polynomial) {
                push @terms, $x->pow(_set_int($k))->mul(bless \$t)->div(bless \$u);
            }
            else {
                push @terms, __div__(__mul__(__pow__($$x, $k), $t), $u);
            }

            Math::GMPz::Rmpz_mul_ui($u, $u, $k + 1);
        }

        $polynomial
          ? _binsplit(\@terms, \&Sidef::Types::Number::Polynomial::add)
          : (bless \_binsplit(\@terms, \&__add__));
    }

    *laguerre            = \&laguerreL;
    *Laguerre            = \&laguerreL;
    *LaguerreL           = \&laguerreL;
    *laguerre_polynomial = \&laguerreL;

    sub fibonaccimod {
        my ($n, $m) = @_;
        _valid(\$m);

        $n = _big2uistr($n) // goto &nan;
        $m = _big2pistr($m) // goto &nan;

        return ZERO if $m eq '1';

        my ($r) = Math::Prime::Util::GMP::lucas_sequence($m, 1, -1, $n);
        _set_int($r);
    }

    *fibmod        = \&fibonaccimod;
    *fibonacci_mod = \&fibonaccimod;
    *FibonacciMod  = \&fibonaccimod;

    sub lucasmod {
        my ($n, $m) = @_;
        _valid(\$m);

        $n = _big2uistr($n) // goto &nan;
        $m = _big2pistr($m) // goto &nan;

        return ZERO if $m eq '1';

        my (undef, $r) = Math::Prime::Util::GMP::lucas_sequence($m, 1, -1, $n);
        _set_int($r);
    }

    *lucas_mod = \&lucasmod;
    *LucasMod  = \&lucasmod;

    sub fibonacci {
        my ($n, $k) = @_;

        $n = _any2ui($$n) // (goto &nan);

        if (defined($k)) {
            _valid(\$k);

            $k = _any2ui($$k) // (goto &nan);

            if ($k == 2) {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_fib_ui($z, $n);
                return bless \$z;
            }

            if ($n < $k - 1) {
                return ZERO;
            }

            # Algorithm after M. F. Hasler
            # See: https://oeis.org/A302990

            my @f = map {
                $_ < $k
                  ? do {
                    my $z = Math::GMPz::Rmpz_init();
                    Math::GMPz::Rmpz_setbit($z, $_);
                    $z;
                  }
                  : Math::GMPz::Rmpz_init_set_ui(1)
            } 1 .. ($k + 1);

            my $t = Math::GMPz::Rmpz_init();

            foreach my $i (2 * ++$k - 2 .. $n) {
                Math::GMPz::Rmpz_mul_2exp($t, $f[($i - 1) % $k], 1);
                Math::GMPz::Rmpz_sub($f[$i % $k], $t, $f[$i % $k]);
            }

            my $r = $f[$n % $k];
            return bless \$r;
        }

        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fib_ui($z, $n);
        bless \$z;
    }

    *fib       = \&fibonacci;
    *Fibonacci = \&fibonacci;

    sub motzkin {    # OEIS: A001006
        my ($n) = @_;

        $n = 1 + (_any2ui($$n) // (goto &nan));

        my $x = Math::GMPz::Rmpz_init_set_ui(0);
        my $y = Math::GMPz::Rmpz_init_set_ui(1);

        state $t = Math::GMPz::Rmpz_init_nobless();

        # Algorithm due to Peter Luschny, May 16 2016.
        foreach my $k (2 .. $n) {
            Math::GMPz::Rmpz_mul_ui($x, $x, 3 * $k * ($k - 1));
            Math::GMPz::Rmpz_mul_ui($t, $y, $k * (2 * $k - 1));
            Math::GMPz::Rmpz_add($x, $x, $t);
            Math::GMPz::Rmpz_divexact_ui($x, $x, ($k + 1) * ($k - 1));
            ($x, $y) = ($y, $x);
        }

        Math::GMPz::Rmpz_divexact_ui($y, $y, $n);
        bless \$y;
    }

    sub stirling {
        my ($x, $y) = @_;
        _valid(\$y);
        _set_int(Math::Prime::Util::GMP::stirling(_big2uistr($x) // (goto &nan), _big2uistr($y) // (goto &nan)));
    }

    *Stirling  = \&stirling;
    *stirling1 = \&stirling;
    *Stirling1 = \&stirling;

    sub stirling2 {
        my ($x, $y) = @_;
        _valid(\$y);
        _set_int(Math::Prime::Util::GMP::stirling(_big2uistr($x) // (goto &nan), _big2uistr($y) // (goto &nan), 2));
    }

    *Stirling2 = \&stirling2;

    sub stirling3 {
        my ($x, $y) = @_;
        _valid(\$y);
        _set_int(Math::Prime::Util::GMP::stirling(_big2uistr($x) // (goto &nan), _big2uistr($y) // (goto &nan), 3));
    }

    *Stirling3 = \&stirling3;

    sub bell {
        my ($x) = @_;
        my $n = _any2ui($$x) // goto &nan;

#<<<
        if ($n < 100) {
              return _set_int(
                    Math::Prime::Util::GMP::vecsum(map { Math::Prime::Util::GMP::stirling($n, $_, 2) } 0 .. $n));
        }
#>>>

        my @acc;

        my $t    = Math::GMPz::Rmpz_init();
        my $bell = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $k (1 .. $n) {

            Math::GMPz::Rmpz_set($t, $bell);

            foreach my $item (@acc) {
                Math::GMPz::Rmpz_add($t, $t, $item);
                Math::GMPz::Rmpz_set($item, $t);
            }

            unshift @acc, $bell;
            $bell = Math::GMPz::Rmpz_init_set($acc[-1]);
        }

        bless \$bell;
    }

    *bell_number = \&bell;
    *Bell        = \&bell;

    sub bellmod {
        my ($n, $m) = @_;

        # TODO: find a faster method.

        _valid(\$m);

        $n = _any2ui($$n)  // goto &nan;
        $m = _any2mpz($$m) // goto &nan;

        Math::GMPz::Rmpz_sgn($m) || goto &nan;

        # For small n, it's faster to just use bell(n) % m
        if ($n < 1000) {
            return $_[0]->bell->mod($_[1]);
        }

        my @acc;

        my $t    = Math::GMPz::Rmpz_init();
        my $bell = Math::GMPz::Rmpz_init_set_ui(1);

        my $native_m = 0;

        if (Math::GMPz::Rmpz_fits_ulong_p($m)) {
            $m        = Math::GMPz::Rmpz_get_ui($m);
            $native_m = 1;
        }

        foreach my $k (1 .. $n) {

            Math::GMPz::Rmpz_set($t, $bell);

            foreach my $item (@acc) {
                Math::GMPz::Rmpz_add($t, $t, $item);
                $native_m
                  ? Math::GMPz::Rmpz_mod_ui($t, $t, $m)
                  : Math::GMPz::Rmpz_mod($t, $t, $m);
                Math::GMPz::Rmpz_set($item, $t);
            }

            unshift @acc, Math::GMPz::Rmpz_init_set($bell);
            $bell = Math::GMPz::Rmpz_init_set($acc[-1]);
        }

        bless \$bell;
    }

    *Bellmod = \&bellmod;

    sub quadratic_formula {
        my ($A, $B, $C) = @_;

        $A //= ZERO;
        $B //= ZERO;
        $C //= ZERO;

        _valid(\$B, \$C);

        $A = $$A;
        $B = $$B;
        $C = $$C;

        state $FOUR = ${_set_int(4)};

        #
        ## (-b ± sqrt(b^2 - 4ac)) / (2a)
        #

        my $u = __mul__($B,              $B);                # b^2
        my $t = __mul__(__mul__($A, $C), $FOUR);             # 4ac
        my $s = __sqrt__(_any2mpfr_mpc(__sub__($u, $t)));    # sqrt(b^2 - 4ac)

        my $n1 = __sub__($s, $B);                            #   sqrt(b^2 - 4ac) - b
        my $n2 = __neg__(__add__($s, $B));                   # -(sqrt(b^2 - 4ac) + b)

        my $d = __add__($A, $A);                             # 2a

        my $x1 = __div__($n1, $d);                           # solution 1
        my $x2 = __div__($n2, $d);                           # solution 2

        ((bless \$x1), (bless \$x2));
    }

    sub quadratic_formulaQ {
        my ($A, $B, $C) = @_;

        $A //= ZERO;
        $B //= ZERO;
        $C //= ZERO;

        _valid(\$B, \$C);

        state $FOUR = _set_int(4);

        #
        ## (-b ± sqrt(b^2 - 4ac)) / (2a)
        #

        my $u = $B->mul($B);                                                     # b^2
        my $t = $A->mul($C)->mul($FOUR);                                         # 4ac
        my $s = Sidef::Types::Number::Quadratic->new(ZERO, ONE, $u->sub($t));    # sqrt(b^2 - 4ac)

        my $n1 = $s->sub($B);                                                    #   sqrt(b^2 - 4ac) - b
        my $n2 = $s->add($B)->neg;                                               # -(sqrt(b^2 - 4ac) + b)

        my $d = $A->add($A);                                                     # 2a

        my $x1 = $n1->div($d);                                                   # solution 1
        my $x2 = $n2->div($d);                                                   # solution 2

        ($x1, $x2);
    }

    sub cubic_formula {
        my ($A, $B, $C, $D) = @_;

        $A //= ZERO;
        $B //= ZERO;
        $C //= ZERO;
        $D //= ZERO;

        _valid(\$B, \$C, \$D);

        $A = $$A;
        $B = $$B;
        $C = $$C;
        $D = $$D;

        state $THREE   = ${_set_int(3)};
        state $FOUR    = ${_set_int(4)};
        state $NINE    = ${_set_int(9)};
        state $TWSEVEN = ${_set_int(27)};

        my $A3    = __mul__($A, $THREE);
        my $AC    = __mul__($A, $C);
        my $BB    = __mul__($B, $B);       # b^2
        my $D0    = __sub__($BB, __mul__($AC, $THREE));
        my $Bp3   = __mul__($BB, $B);      # b^3
        my $ABC9  = __mul__(__mul__($AC,             $B), $NINE);
        my $AAD27 = __mul__(__mul__(__mul__($A, $A), $D), $TWSEVEN);
        my $D1    = __add__(__sub__(__add__($Bp3, $Bp3), $ABC9), $AAD27);

        my $W = __sqrt__(_any2mpfr_mpc(__sub__(__mul__($D1, $D1), __mul__(__pow__($D0, 3), $FOUR))));
        my $M = __cbrt__(_any2mpfr_mpc(__div__(__sub__($D1, ((__sgn__($D0) || -1) == 1) ? $W : __neg__($W)), $TWO)));

        my @roots;

        my $R = $ONE;
        my $z = __div__(__sub__(__sqrt__(_mpz2mpc(-$THREE)), $ONE), $TWO);

        foreach my $k (0 .. 2) {
            my $t = __mul__($M, $R);
            my $x = __neg__(__div__(__add__(__add__($B, $t), __div__($D0, $t)), $A3));
            push @roots, $x;
            $R = __mul__($R, $z) if ($k < 2);
        }

        @roots = map { bless \$_ } @roots;
        return @roots;
    }

    sub iquadratic_formula {
        my ($A, $B, $C) = @_;

        $A //= ZERO;
        $B //= ZERO;
        $C //= ZERO;

        _valid(\$B, \$C);

        $A = _any2mpz($$A) // return (&nan, &nan);
        $B = _any2mpz($$B) // return (&nan, &nan);
        $C = _any2mpz($$C) // return (&nan, &nan);

        if (Math::GMPz::Rmpz_sgn($A) == 0) {    # detect division by zero
            return (&nan, &nan);
        }

        #
        ## floor((-b ± isqrt(b^2 - 4ac)) / (2a))
        #

        my $u = Math::GMPz::Rmpz_init();
        my $t = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_mul($t, $B, $B);        # b^2
        Math::GMPz::Rmpz_mul($u, $A, $C);        # ac
        Math::GMPz::Rmpz_mul_2exp($u, $u, 2);    # 4ac
        Math::GMPz::Rmpz_sub($t, $t, $u);        # b^2 - 4ac

        if (Math::GMPz::Rmpz_sgn($t) < 0) {      # t is negative: no real solution
            return (&nan, &nan);
        }

        Math::GMPz::Rmpz_sqrt($t, $t);           # isqrt(b^2 - 4ac)

        Math::GMPz::Rmpz_sub($u, $t, $B);        #   sqrt(b^2 - 4ac) - b
        Math::GMPz::Rmpz_add($t, $t, $B);        #   sqrt(b^2 - 4ac) + b
        Math::GMPz::Rmpz_neg($t, $t);            # -(sqrt(b^2 - 4ac) + b)

        Math::GMPz::Rmpz_div($u, $u, $A);
        Math::GMPz::Rmpz_div($t, $t, $A);

        Math::GMPz::Rmpz_div_2exp($u, $u, 1);
        Math::GMPz::Rmpz_div_2exp($t, $t, 1);

        ((bless \$u), (bless \$t));
    }

    *integer_quadratic_formula = \&iquadratic_formula;

    sub modular_quadratic_formula {
        my ($x, $y, $z, $m) = @_;

        $x //= ZERO;
        $y //= ZERO;
        $z //= ZERO;
        $m // return Sidef::Types::Array::Array->new;

        _valid(\$y, \$z, \$m);

        $x = _any2mpq($$x) // return Sidef::Types::Array::Array->new;
        $y = _any2mpq($$y) // return Sidef::Types::Array::Array->new;
        $z = _any2mpq($$z) // return Sidef::Types::Array::Array->new;
        $m = _any2mpz($$m) // return Sidef::Types::Array::Array->new;

        # x must not be zero
        Math::GMPq::Rmpq_sgn($x)
          || return Sidef::Types::Array::Array->new;

        my $four_m = 4 * $m;

        # D = b^2 - 4*a*c
        my $D = __mod__($y * $y - 4 * $x * $z, $four_m);

        # The discriminant must be an integer
        (ref($D) eq 'Math::GMPz' or Math::GMPq::Rmpq_integer_p($D))
          || return Sidef::Types::Array::Array->new;

        # Find all the solutions k to: k^2 == D (mod 4*m)
        my $S = _set_int($D)->sqrtmod_all(_set_int($four_m));

        @$S || return $S;

        my $two_a = 2 * $x;
        my $neg_b = __neg__($y);

        my @solutions;

        foreach my $k (@$S) {
            foreach my $u (__add__($neg_b, $$k), __sub__($neg_b, $$k)) {
                my $r = __mod__(__div__($u, $two_a), $m);
                if (__cmp__(__mod__($x * ($r * $r) + $y * $r + $z, $m), 0) == 0) {
                    push @solutions, (bless \$r);
                }
            }
        }

        Sidef::Types::Array::Array->new(\@solutions)->sort->uniq;
    }

    sub geometric_sum {
        my ($n, $r) = @_;
        _valid(\$r);

        $n = $$n;
        $r = $$r;

        bless \__div__(__sub__(__pow__($r, __add__($n, $ONE)), $ONE), __sub__($r, $ONE));
    }

    sub faulhaber_range {
        my ($from, $to, $k) = @_;
        _valid(\$to, \$k);
        return ZERO if $to->lt($from);
        return $to->faulhaber_sum($k)->sub($from->dec->faulhaber_sum($k));
    }

    sub faulhaber_sum {
        my ($n, $p) = @_;

        _valid(\$p);

        $n = _any2mpz($$n) // goto &nan;
        $p = _any2ui($$p)  // goto &nan;

        if ($p == 0) {
            return bless \$n;
        }

        if ($p == 1 or $p == 3) {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_add_ui($r, $n, 1);
            Math::GMPz::Rmpz_mul($r, $r, $n);
            Math::GMPz::Rmpz_div_2exp($r, $r, 1);
            Math::GMPz::Rmpz_mul($r, $r, $r) if ($p == 3);
            return bless \$r;
        }

        state $z = Math::GMPz::Rmpz_init_nobless();

        if ($p == 2) {    # n*(n+1)*(2*n+1)/6
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_add_ui($z, $n, 1);
            Math::GMPz::Rmpz_mul($r, $z, $n);
            Math::GMPz::Rmpz_mul_2exp($z, $z, 1);
            Math::GMPz::Rmpz_sub_ui($z, $z, 1);
            Math::GMPz::Rmpz_mul($r, $r, $z);
            Math::GMPz::Rmpz_divexact_ui($r, $r, 6);
            return bless \$r;
        }

        # When p >= n, sum the powers directly.
        if (Math::GMPz::Rmpz_cmp_ui($n, $p) <= 0) {
            my $r = Math::GMPz::Rmpz_init_set_ui(0);
            foreach my $k (1 .. Math::GMPz::Rmpz_get_ui($n)) {
                Math::GMPz::Rmpz_ui_pow_ui($z, $k, $p);
                Math::GMPz::Rmpz_add($r, $r, $z);
            }
            return bless \$r;
        }

        my @B = _bernoulli_numbers($p);

        my $q = Math::GMPq::Rmpq_init();
        my $u = Math::GMPz::Rmpz_init_set_ui(1);

        my $sum = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($sum, 0, 1);

        # Sum_{k=1..n} k^p = 1/(p+1) * Sum_{j=0..p} binomial(p+1, j) * n^(p-j+1) * bernoulli(j)
        #                  = 1/(p+1) * Sum_{j=0..p} binomial(p+1, p-j) * n^(j+1) * bernoulli(p-j)

        foreach my $j (0 .. $p - 2) {

            Math::GMPz::Rmpz_mul($u, $u, $n);

            # Skip when bernoulli(p-j) == 0
            ($p - $j) % 2 == 0 or next;

            Math::GMPz::Rmpz_bin_uiui($z, $p + 1, $p - $j);
            Math::GMPz::Rmpz_mul($z, $z, $u);
            Math::GMPq::Rmpq_mul_z($q, $B[(($p - $j) >> 1) + 1], $z);
            Math::GMPq::Rmpq_add($sum, $sum, $q);
        }

        # sum += (1/2) * n^p * (2*n + p + 1)
        Math::GMPz::Rmpz_mul($u, $u, $n);
        Math::GMPz::Rmpz_mul_2exp($z, $n, 1);
        Math::GMPz::Rmpz_add_ui($z, $z, $p + 1);
        Math::GMPz::Rmpz_mul($u, $u, $z);
        Math::GMPq::Rmpq_set_ui($q, 1, 2);
        Math::GMPq::Rmpq_mul_z($q, $q, $u);
        Math::GMPq::Rmpq_add($sum, $sum, $q);

        # z = sum/(p+1)
        Math::GMPq::Rmpq_get_num($u, $sum);
        Math::GMPz::Rmpz_divexact_ui($u, $u, $p + 1);
        bless \$u;
    }

    *faulhaber    = \&faulhaber_sum;
    *Faulhaber    = \&faulhaber_sum;
    *FaulhaberSum = \&faulhaber_sum;

    sub multinomial {
        my ($n, @mset) = @_;

        $n = _any2mpz($$n) // goto &nan;

        my $bin  = Math::GMPz::Rmpz_init();
        my $sum  = Math::GMPz::Rmpz_init_set($n);
        my $prod = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $k (@mset) {
            _valid(\$k);

            $k = _any2si($$k) // goto &nan;

            $k < 0
              ? Math::GMPz::Rmpz_sub_ui($sum, $sum, -$k)
              : Math::GMPz::Rmpz_add_ui($sum, $sum, $k);

            $k < 0
              ? Math::GMPz::Rmpz_bin_si($bin, $sum, $k)
              : Math::GMPz::Rmpz_bin_ui($bin, $sum, $k);

            Math::GMPz::Rmpz_mul($prod, $prod, $bin);
        }

        bless \$prod;
    }

    sub catalan {
        my ($n, $k) = @_;

        # Catalan triangle
        # catalan(n, k) = binomial(n+k, k) - binomial(n+k, k-1)
        if (defined($k)) {
            _valid(\$k);

            $n = _any2mpz($$n) // goto &nan;
            $k = _any2ui($$k)  // goto &nan;

            my $t = Math::GMPz::Rmpz_init();
            my $u = Math::GMPz::Rmpz_init();

            Math::GMPz::Rmpz_add_ui($t, $n, $k);
            Math::GMPz::Rmpz_bin_ui($u, $t, $k);
            ($k > 0)
              ? Math::GMPz::Rmpz_bin_ui($t, $t, $k - 1)
              : Math::GMPz::Rmpz_bin_si($t, $t, $k - 1);
            Math::GMPz::Rmpz_sub($u, $u, $t);

            return bless \$u;
        }

        $n = _any2ui($$n) // goto &nan;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_bin_uiui($r, $n << 1, $n);
        Math::GMPz::Rmpz_divexact_ui($r, $r, $n + 1);
        bless \$r;
    }

    *Catalan = \&catalan;

    sub binomial {
        my ($x, $y) = @_;
        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2si($$y)  // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();

        $y < 0
          ? Math::GMPz::Rmpz_bin_si($r, $x, $y)
          : Math::GMPz::Rmpz_bin_ui($r, $x, $y);

        bless \$r;
    }

    *nok = \&binomial;

    sub binomialmod {
        my ($n, $k, $m) = @_;

        _valid(\$k, \$m);

        $n = _any2mpz($$n) // (goto &nan);
        $k = _any2mpz($$k) // (goto &nan);
        $m = _any2mpz($$m) // (goto &nan);

        Math::GMPz::Rmpz_sgn($m) || goto &nan;

        my $factorial_without_prime = sub {
            my ($n, $p, $pk, $from, $count, $res) = @_;

            return 1 if ($n <= 1);

            if ($p > $n) {
                return (
                        (HAS_PRIME_UTIL and $pk < ULONG_MAX)
                        ? Math::Prime::Util::factorialmod($n, $pk)
                        : Math::Prime::Util::GMP::factorialmod($n, $pk)
                       );
            }

            if ($$from == $n) {
                return $$res;
            }

            if ($$from > $n) {
                $$from  = 0;
                $$count = 0;
                $$res   = 1;
            }

            my $r = $$res;
            my $t = $$count;

            foreach my $v ($$from + 1 .. $n) {
                if (++$t == $p) {
                    $t = 0;
                }
                else {
                    $r = (
                          HAS_PRIME_UTIL
                          ? Math::Prime::Util::mulmod($r, $v, $pk)
                          : Math::Prime::Util::GMP::mulmod($r, $v, $pk)
                         );
                }
            }

            $$res   = $r;
            $$count = $t;
            $$from  = $n;

            return $r;
        };

        my $factorial_valuation = sub {
            my ($n, $p) = @_;

            my $count = 0;
            my $ppow  = $p;

            while ($ppow <= $n) {
                $count += Math::Prime::Util::GMP::divint($n, $ppow);
                $ppow  *= $p;
            }

            return $count;
        };

        my $small_k_binomialmod = sub {
            my ($n, $k, $m) = @_;

            $n = Math::GMPz::Rmpz_init_set_str($n, 10) if !ref($n);
            $m = Math::GMPz::Rmpz_init_set_str($m, 10) if !ref($m);

            #~ say "Small k: ($n, $k, $m)";

            if ($k <= 1e6) {

                # This is fast only with recent versions of GMP
                my $bin = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_bin_ui($bin, $n, $k);
                Math::GMPz::Rmpz_mod($bin, $bin, $m);
                return $bin;
            }

            my $t   = Math::GMPz::Rmpz_init();
            my $u   = Math::GMPz::Rmpz_init();
            my $bin = Math::GMPz::Rmpz_init_set_ui(1);

            my %kp;

            for (my $i = $n - $k + 1 ; Math::GMPz::Rmpz_cmp($i, $n) <= 0 ; Math::GMPz::Rmpz_add_ui($i, $i, 1)) {

                Math::GMPz::Rmpz_set($t, $i);
                my (undef, @factors) = _primorial_trial_factor($i, $k);

                foreach my $p (List::Util::uniq(@factors)) {

                    next if ((my $e = ($kp{$p} //= $factorial_valuation->($k, $p))) == 0);

                    Math::GMPz::Rmpz_set_ui($u, $p);
                    my $v = Math::GMPz::Rmpz_remove($t, $t, $u);

                    if ($v >= $e) {

                        if ($v > $e) {
                            Math::GMPz::Rmpz_pow_ui($u, $u, $v - $e) if ($v - $e > 1);
                            Math::GMPz::Rmpz_mul($t, $t, $u);
                        }

                        $kp{$p} = 0;
                    }
                    else {
                        $kp{$p} -= $v;
                    }
                }

                Math::GMPz::Rmpz_mul($bin, $bin, $t);
                Math::GMPz::Rmpz_mod($bin, $bin, $m);
            }

            return $bin;
        };

        my $is_small_k = sub {
            my ($n, $k, $m) = @_;

            $n >= 1e6 or return;

            ## say "Small k check: binomial($n, $k, $m)";

            if ($m >= 1e7 and $n >= 1e7 and $k <= 1e6) {
                return 1;
            }

            my $new_k = Math::Prime::Util::GMP::subint($n, $k);

            if ($new_k > 0 and $new_k < $k) {
                $k = $new_k;
            }

            $k <= 1e7 or return;

            my $sqrt_m   = Math::Prime::Util::GMP::sqrtint($m);
            my $m_over_n = Math::Prime::Util::GMP::divint($m, $n);

            $k < $sqrt_m and $k < $m_over_n;
        };

        my $lucas_theorem = sub {    # p is prime
            my ($n, $k, $p) = @_;

            my $r = 1;
            my (@nd, @kd);

            while ($k) {
                my $np = Math::Prime::Util::GMP::modint($n, $p);
                my $kp = Math::Prime::Util::GMP::modint($k, $p);

                push @nd, $np;
                push @kd, $kp;

                if ($kp > $np) { return 0 }

                $n = Math::Prime::Util::GMP::divint($n, $p);
                $k = Math::Prime::Util::GMP::divint($k, $p);
            }

            foreach my $i (0 .. $#nd) {

                my $np = $nd[$i];
                my $kp = $kd[$i];
                my $rp = Math::Prime::Util::GMP::subint($np, $kp);

                #~ say "Lucas theorem: ($np, $kp, $p)";

                if ($is_small_k->($np, $kp, $p)) {
                    ## say "Optimization: ($np, $kp, $p)";
                    my $bin = $small_k_binomialmod->($np, $kp, $p);
                    $r = Math::Prime::Util::GMP::mulmod($r, $bin, $p);
                    next;
                }

                my $x = Math::Prime::Util::GMP::factorialmod($np, $p);
                my $y = Math::Prime::Util::GMP::factorialmod($kp, $p);
                my $z = Math::Prime::Util::GMP::factorialmod($rp, $p);

                $y = Math::Prime::Util::GMP::mulmod($y, $z, $p);
                $x = Math::Prime::Util::GMP::divmod($x, $y, $p) if ($y ne '1');
                $r = Math::Prime::Util::GMP::mulmod($r, $x, $p);
            }

            return $r;
        };

        my $modular_binomial = sub {
            my ($n, $k, $m) = @_;

            # Translation of binomod.gp v1.5 by Max Alekseyev, with some extra optimizations.

            # m == 1
            if (Math::GMPz::Rmpz_cmp_ui($m, 1) == 0) {
                return 0;
            }

            # k < 0
            if (Math::GMPz::Rmpz_sgn($k) < 0) {
                $k = $n - $k;
            }

            # k < n-k < 0
            if (Math::GMPz::Rmpz_sgn($k) < 0) {
                return 0;
            }

            # n < 0
            if (Math::GMPz::Rmpz_sgn($n) < 0) {
                my $x = Math::GMPz::Rmpz_even_p($k) ? 1 : -1;
                $x = Math::Prime::Util::GMP::mulint($x, __SUB__->(-$n + $k - 1, $k, $m));
                return Math::Prime::Util::GMP::modint($x, $m);
            }

            # k > n
            if (Math::GMPz::Rmpz_cmp($k, $n) > 0) {
                return 0;
            }

            # k == 0 or k == n
            if (Math::GMPz::Rmpz_sgn($k) == 0 or Math::GMPz::Rmpz_cmp($k, $n) == 0) {
                return Math::Prime::Util::GMP::modint(1, $m);
            }

            # k == 1 or k == n-1
            if (Math::GMPz::Rmpz_cmp_ui($k, 1) == 0 or $k == $n - 1) {
                return Math::Prime::Util::GMP::modint($n, $m);
            }

            # n-k > 0 and n-k < k
            if (Math::GMPz::Rmpz_cmp($n - $k, $k) < 0) {
                $k = $n - $k;
            }

            # k <= 10^4
            if (Math::GMPz::Rmpz_cmp_ui($k, 1e4) <= 0) {
                return Math::Prime::Util::GMP::modint($small_k_binomialmod->($n, $k, $m), $m);
            }

            my @F;

            foreach my $pp (_factor_exp(Math::Prime::Util::GMP::absint($m))) {
                my ($p, $q) = @$pp;

                if ($q == 1) {
                    if (HAS_NEW_PRIME_UTIL and $n < ULONG_MAX and $p < ULONG_MAX) {
                        push @F, [Math::Prime::Util::binomialmod($n, $k, $p), $p];
                    }
                    else {
                        push @F, [$lucas_theorem->($n, $k, $p), $p];
                    }
                    next;
                }

                my $d = __ilog__($n, $p) + 1;

                my (@np, @kp);

                do {
                    my $pi = 1;
                    foreach my $i (0 .. $d) {
                        push @np, Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::divint($n, $pi), $p);
                        push @kp, Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::divint($k, $pi), $p);
                        $pi = Math::Prime::Util::GMP::mulint($pi, $p);
                    }
                };

                my @e;

                foreach my $i (0 .. $d) {
                    $e[$i] = ($np[$i] < ($kp[$i] + (($i > 0) ? $e[$i - 1] : 0))) ? 1 : 0;
                }

                for (my $i = $d - 1 ; $i >= 0 ; --$i) {
                    $e[$i] += $e[$i + 1];
                }

                if ($e[0] >= $q) {
                    push @F, [0, Math::Prime::Util::GMP::powint($p, $q)];
                    next;
                }

                my $rq = $q - $e[0];

                my $pq  = Math::Prime::Util::GMP::powint($p, $q);
                my $prq = Math::Prime::Util::GMP::powint($p, $rq);

                if ($is_small_k->($n, $k, $pq)) {
                    ## say "Optimization prime power: ($n, $k, $p, $pq)";
                    my $bin = $small_k_binomialmod->($n, $k, $pq);
                    push @F, [$bin, $pq];
                    next;
                }

                if (HAS_NEW_PRIME_UTIL and $n < ULONG_MAX and $pq < ULONG_MAX) {
                    push @F, [Math::Prime::Util::binomialmod($n, $k, $pq), $pq];
                    next;
                }

                my (@N, @K, @R);

                do {
                    my $pi = 1;
                    my $r  = Math::Prime::Util::GMP::subint($n, $k);
                    foreach my $i (0 .. $d) {
                        push @N, Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::divint($n, $pi), $prq);
                        push @K, Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::divint($k, $pi), $prq);
                        push @R, Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::divint($r, $pi), $prq);
                        $pi = Math::Prime::Util::GMP::mulint($pi, $p);
                    }
                };

                my @NKR = (
                           sort { $a->[3] <=> $b->[3] }
                           map  { [$N[$_], $K[$_], $R[$_], $N[$_] + $K[$_] + $R[$_]] } 0 .. $#N
                          );

                @N = map { $_->[0] } @NKR;
                @K = map { $_->[1] } @NKR;
                @R = map { $_->[2] } @NKR;

                my @acc  = (1);
                my $nfac = 1;

                if ($prq < ULONG_MAX and $p < $n) {
                    my $count = 0;
                    foreach my $k (1 .. List::Util::min(List::Util::max(@N, @K, @R), 1e3)) {
                        if (++$count == $p) {
                            $count = 0;
                        }
                        else {
                            $nfac = (
                                     HAS_PRIME_UTIL
                                     ? Math::Prime::Util::mulmod($nfac, $k, $prq)
                                     : Math::Prime::Util::GMP::mulmod($nfac, $k, $prq)
                                    );
                        }
                        push @acc, $nfac;
                    }
                }

                my $v = Math::Prime::Util::GMP::powmod($p, $e[0], $pq);

                do {
                    my $from  = 0;
                    my $count = 0;
                    my $res   = 1;

                    foreach my $j (0 .. $d) {

                        my @pairs;
                        my ($x, $y, $z);

                        ($x = $acc[$N[$j]]) // push(@pairs, [\$x, $N[$j]]);
                        ($y = $acc[$K[$j]]) // push(@pairs, [\$y, $K[$j]]);
                        ($z = $acc[$R[$j]]) // push(@pairs, [\$z, $R[$j]]);

                        foreach my $pair (sort { $a->[1] <=> $b->[1] } @pairs) {
                            ## say "Factorial($pair->[1]) mod $prq with p = $p";
                            ${$pair->[0]} = $factorial_without_prime->($pair->[1], $p, $prq, \$from, \$count, \$res);
                        }

                        $y = Math::Prime::Util::GMP::mulmod($y, $z, $pq);
                        $x = Math::Prime::Util::GMP::divmod($x, $y, $pq) if ($y ne '1');
                        $v = Math::Prime::Util::GMP::mulmod($v, $x, $pq);
                    }
                };

                if (($p > 2 or $rq < 3) and $q <= scalar(@e)) {
                    $v = Math::Prime::Util::GMP::mulmod($v, (($e[$rq - 1] % 2 == 0) ? 1 : -1), $pq);
                }

                push @F, [$v, $pq];
            }

            Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::chinese(@F), $m);
        };

        _set_int($modular_binomial->($n, $k, $m));
    }

    sub moebius {
        my ($n, $k) = @_;

        if (defined($k)) {

            _valid(\$k);

            $n = _big2istr($n) // return Sidef::Types::Array::Array->new;
            $k = _big2istr($k) // return Sidef::Types::Array::Array->new;

            my @array = map { $_ ? ($_ == 1) ? ONE : MONE : ZERO } (
                                                                    HAS_PRIME_UTIL
                                                                    ? Math::Prime::Util::moebius($n, $k)
                                                                    : Math::Prime::Util::GMP::moebius($n, $k)
                                                                   );

            return Sidef::Types::Array::Array->new(\@array);
        }

        $n = _any2mpz($$n) // goto &nan;

        my $m;
        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            $m = Math::Prime::Util::moebius(Math::GMPz::Rmpz_get_ui($n));
        }
        else {
            $m = Math::Prime::Util::GMP::moebius(Math::GMPz::Rmpz_get_str($n, 10));
        }

        $m ? ($m == 1) ? ONE : MONE : ZERO;
    }

    *μ       = \&moebius;
    *mu      = \&moebius;
    *mobius  = \&moebius;
    *möbius  = \&moebius;
    *Möbius  = \&moebius;
    *Moebius = \&moebius;

    sub mertens {
        my ($x, $y) = @_;

        if (defined($y)) {
            _valid(\$y);
            $x = _big2istr($x) // return ZERO;
            $x = 1 if $x < 1;
            $y = _big2uistr($y) // return ZERO;
        }
        else {
            $y = _big2uistr($x) // return ZERO;
            $x = 1;
        }

        state $mertens_table = {

            # M(10^n), where M(x) is Mertens's function.
            # OEIS: https://oeis.org/A084237
            "1"                       => "1",
            "10"                      => "-1",
            "100"                     => "1",
            "1000"                    => "2",
            "10000"                   => "-23",
            "100000"                  => "-48",
            "1000000"                 => "212",
            "10000000"                => "1037",
            "100000000"               => "1928",
            "1000000000"              => "-222",
            "10000000000"             => "-33722",
            "100000000000"            => "-87856",
            "1000000000000"           => "62366",
            "10000000000000"          => "599582",
            "100000000000000"         => "-875575",
            "1000000000000000"        => "-3216373",
            "10000000000000000"       => "-3195437",
            "100000000000000000"      => "-21830254",
            "1000000000000000000"     => "-46758740",
            "10000000000000000000"    => "899990187",
            "100000000000000000000"   => "461113106",
            "1000000000000000000000"  => "3395895277",
            "10000000000000000000000" => "-2061910120",
                               };

        if ($x eq '1') {

            if (defined(my $value = $mertens_table->{$y})) {
                return _set_int($value);
            }

            if (HAS_NEW_PRIME_UTIL) {
                return _set_int($mertens_table->{$y} = Math::Prime::Util::mertens($y));
            }
        }

        # Support for large integers (slow for wide ranges)
        if ($y >= ~0) {

            $x = Math::GMPz::Rmpz_init_set_str("$x", 10);
            $y = Math::GMPz::Rmpz_init_set_str("$y", 10);

            my $sum = 0;

            for (; Math::GMPz::Rmpz_cmp($x, $y) <= 0 ; Math::GMPz::Rmpz_add_ui($x, $x, 1)) {
                $sum += Math::Prime::Util::GMP::moebius(Math::GMPz::Rmpz_get_str($x, 10));
            }

            return _set_int($sum);
        }

        return ZERO if ($y < $x);

        # Optimization for narrow ranges
        if (($x >= 10**4 and $y - $x <= 10**4) or "$x" / "$y" >= 0.999) {
            my $r =
              List::Util::sum(
                              HAS_PRIME_UTIL
                              ? Math::Prime::Util::moebius($x, $y)
                              : Math::Prime::Util::GMP::moebius($x, $y)
                             );
            return _set_int($r);
        }

        my $lookup_size = 2 * Math::Prime::Util::GMP::rootint($y, 3)**2;

        if ($y > 1e10) {
            $lookup_size >>= 1;
        }

        if ($y > 1e11) {
            $lookup_size >>= 1;
        }

        state @mertens_lookup;

        if (@mertens_lookup < $lookup_size) {
            $mertens_lookup[0] = 0;

            my @mu_range = (
                            HAS_PRIME_UTIL
                            ? Math::Prime::Util::moebius(scalar(@mertens_lookup), $lookup_size)
                            : Math::Prime::Util::GMP::moebius(scalar(@mertens_lookup), $lookup_size)
                           );

            foreach my $i (@mertens_lookup .. $lookup_size) {
                $mertens_lookup[$i] = $mertens_lookup[$i - 1] + shift(@mu_range);
            }
        }

        use integer;

        my $mertens = sub {
            my ($n) = @_;

            # Algorithm based on the recursive identity:
            #   M(n) = 1 - Sum_{k=2..n} M(floor(n/k))

            if ($n <= $lookup_size) {
                return $mertens_lookup[$n];
            }

            if (exists $mertens_table->{$n}) {
                return $mertens_table->{$n};
            }

            # Using Dana Jacobsen's (++) optimizations from Math::Prime::Util::PP.
            my $s  = Math::Prime::Util::GMP::sqrtint($n);
            my $ns = $n / ($s + 1);

            my ($nk, $nk1) = ($n, $n >> 1);
            my $M = 1 - ($nk - $nk1);

            foreach my $k (2 .. $ns) {
                ($nk, $nk1) = ($nk1, $n / ($k + 1));
                $M -= ($nk <= $lookup_size) ? $mertens_lookup[$nk] : __SUB__->($nk);
                $M -= $mertens_lookup[$k] * ($nk - $nk1);
            }

            if ($s > $ns) {
                $M -= $mertens_lookup[$s] * ($n / $s - $ns);
            }

            $mertens_table->{$n} = $M;
        };

        my $value =
          ($x == 1)
          ? $mertens->($y)
          : ($mertens->($y) - $mertens->($x) + Math::Prime::Util::GMP::moebius($x));

        _set_int($value);
    }

    sub liouville_sum {
        my ($from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $to->liouville_sum->sub($from->dec->liouville_sum);
        }

        my $n = _any2mpz($$from) // goto &nan;
        Math::GMPz::Rmpz_sgn($n) > 0 or return ZERO;

        state $liouville_table = {

            # L(10^n), where L(x) is Liouville's summatory function.
            # OIES: https://oeis.org/A090410
            '1'                    => '1',
            '10'                   => '0',
            '100'                  => '-2',
            '1000'                 => '-14',
            '10000'                => '-94',
            '100000'               => '-288',
            '1000000'              => '-530',
            '10000000'             => '-842',
            '100000000'            => '-3884',
            '1000000000'           => '-25216',
            '10000000000'          => '-116026',
            '100000000000'         => '-342224',
            '1000000000000'        => '-522626',
            '10000000000000'       => '-966578',
            '100000000000000'      => '-7424752',
            '1000000000000000'     => '-29445104',
            '10000000000000000'    => '-97617938',
            '100000000000000000'   => '-271676470',
            '1000000000000000000'  => '-618117940',
            '10000000000000000000' => '-810056106',
                                 };

        if (defined(my $value = $liouville_table->{$n})) {
            return _set_int($value);
        }

        state $t = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_sqrt($t, $n);
        Math::GMPz::Rmpz_fits_ulong_p($t) || goto &nan;    # too large

        my $L    = 0;
        my $sqrt = Math::GMPz::Rmpz_get_ui($t);

        foreach my $k (1 .. $sqrt) {
            if ($k * $k < ULONG_MAX) {
                Math::GMPz::Rmpz_div_ui($t, $n, $k * $k);
            }
            else {
                Math::GMPz::Rmpz_ui_pow_ui($t, $k, 2);
                Math::GMPz::Rmpz_div($t, $n, $t);
            }
            $L += Math::GMPz::Rmpz_get_si(${mertens($t)});    # most of the time is spent here
        }

        $liouville_table->{$n} = $L;
        _set_int($L);
    }

    sub cyclotomic_polynomial {
        my ($n, $x) = @_;

        _valid(\$n);

        $n = _any2ui($$n) // goto &nan;

        if (!defined($x)) {

            if ($n == 0) {
                return Sidef::Types::Number::Polynomial->new();
            }

            my %cache;

            my $r = sub {
                my ($k) = @_;

                # Based on algorithm from Math::Polynomial::Cyclotomic

                if (exists $cache{$k}) {
                    return $cache{$k};
                }

                my $t = Sidef::Types::Number::Polynomial->new($k => ONE)->dec;

                if ($k == 1) {
                    return $t;
                }

                my @d = _divisors($k);
                my $m = $d[-2];

                my $prod = Sidef::Types::Number::Polynomial->new($m => ONE)->dec;

                foreach my $i (1 .. $#d - 2) {
                    if ($m % $d[$i]) {
                        $prod = $prod->mul($cache{$d[$i]} // __SUB__->($d[$i]));
                    }
                }

                $cache{$k} = $t->div($prod);
              }
              ->($n);

            return $r;
        }

        _valid(\$x);
        $x = $$x;

        return ZERO if ($n == 0);

        return bless(\__dec__($x)) if ($n == 1);
        return bless(\__inc__($x)) if ($n == 2);

        my $x_is_mpz = ref($x) eq 'Math::GMPz';

        # Special case for x = 1: cyclotomic(n, 1) is A020500.
        if ($x_is_mpz ? (Math::GMPz::Rmpz_cmp_ui($x, 1) == 0) : __eq__($x, 1)) {
            my $k = Math::Prime::Util::GMP::is_prime_power($n) || return ONE;
            my $p = Math::Prime::Util::GMP::rootint($n, $k);
            return _set_int($p);
        }

        # Special case for x = -1: cyclotomic(n, -1) is A020513.
        if ($x_is_mpz ? (Math::GMPz::Rmpz_cmp_si($x, -1) == 0) : __eq__($x, -1)) {
            ($n % 2 == 0) || return ONE;
            my $k = Math::Prime::Util::GMP::is_prime_power($n >> 1) || return ONE;
            my $p = Math::Prime::Util::GMP::rootint($n >> 1, $k);
            return _set_int($p);
        }

        my @factor_exp = _factor_exp($n);

        # Generate the squarefree divisors of n, along
        # with the number of prime factors of each divisor
        my @sd;
        foreach my $pe (@factor_exp) {
            push @sd, map { [$_->[0] * $pe->[0], $_->[1] + 1] } @sd;
            push @sd, [$pe->[0], 1];
        }

        push @sd, [1, 0];

        my @terms;
        foreach my $pair (@sd) {
            my ($d, $c) = @$pair;

            my $t    = CORE::int($n / $d);
            my $base = $x_is_mpz
              ? do {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_pow_ui($z, $x, $t);
                Math::GMPz::Rmpz_sub_ui($z, $z, 1);
                $z;
              }
              : __dec__(__pow__($x, $t));

            unshift @terms, (($c % 2 == 0) ? $base : __inv__($base));
        }

        @terms || return ONE;
        bless \_binsplit(\@terms, \&__mul__);
    }

    *cyclotomic = \&cyclotomic_polynomial;

    sub cyclotomicmod {
        my ($n, $x, $m) = @_;

        _valid(\$n, \$x, \$m);

        my $M = $m;

        $n = _any2mpz($$n) // goto &nan;
        $x = $$x;
        $m = _any2mpz($$m) // goto &nan;

        Math::GMPz::Rmpz_sgn($m) || goto &nan;

        if (ref($x) ne 'Math::GMPz') {
            if (__is_int__($x)) {
                $x = _any2mpz($x) // goto &nan;
            }
            else {
                $x = _modular_rational($x, $m) // goto &nan;
            }
        }

        # n must be >= 0
        (Math::GMPz::Rmpz_sgn($n) || return ZERO) > 0
          or goto &nan;

        return ZERO if (Math::GMPz::Rmpz_cmp_ui($m, 1) == 0);

        return bless(\__dec__($x))->mod($M) if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0);
        return bless(\__inc__($x))->mod($M) if (Math::GMPz::Rmpz_cmp_ui($n, 2) == 0);

        # Special case for x = 1: cyclotomic(n, 1) is A020500.
        if (Math::GMPz::Rmpz_cmp_ui($x, 1) == 0) {
            my $k = Math::Prime::Util::GMP::is_prime_power($n) || return ONE;
            my $p = Math::Prime::Util::GMP::rootint($n, $k);
            return _set_int(Math::Prime::Util::GMP::modint($p, $m));
        }

        # Special case for x = -1: cyclotomic(n, -1) is A020513.
        if (Math::GMPz::Rmpz_cmp_si($x, -1) == 0) {
            Math::GMPz::Rmpz_even_p($n) || return ONE;
            my $o = $n >> 1;
            my $k = Math::Prime::Util::GMP::is_prime_power($o) || return ONE;
            my $p = Math::Prime::Util::GMP::rootint($o, $k);
            return _set_int(Math::Prime::Util::GMP::modint($p, $m));
        }

        my @factor_exp = _factor_exp($n);

        # Generate the squarefree divisors of n, along
        # with the number of prime factors of each divisor
        my @sd;
        foreach my $pe (@factor_exp) {
            my ($p) = @$pe;

            $p =
              ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_init_set_ui($p)
              : Math::GMPz::Rmpz_init_set_str("$p", 10);

            push @sd, map { [$_->[0] * $p, $_->[1] + 1] } @sd;
            push @sd, [$p, 1];
        }

        push @sd, [$ONE, 0];

        my $prod = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pair (@sd) {
            my ($d, $c) = @$pair;

            my $base = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_divexact($base, $n, $d);
            Math::GMPz::Rmpz_powm($base, $x, $base, $m);    # x^(n/d) mod m
            Math::GMPz::Rmpz_sub_ui($base, $base, 1);

            if ($c % 2 == 1) {
                Math::GMPz::Rmpz_invert($base, $base, $m) || goto &nan;
            }

            Math::GMPz::Rmpz_mul($prod, $prod, $base);
            Math::GMPz::Rmpz_mod($prod, $prod, $m);
        }

        bless \$prod;
    }

    sub cyclotomic_factor {
        my ($n, @bases) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0
          or return Sidef::Types::Array::Array->new;

        if (@bases) {
            _valid(\(@bases));
            @bases = grep { defined($_) } map { _any2mpz($$_) } @bases;
        }
        else {
            @bases = map { ${_set_int($_)} } (2 .. __ilog__($n, 2));
        }

        my $cyclotomicmod = sub {
            my ($n, $x, $m) = @_;

            my @factor_exp = _factor_exp($n);

            # Generate the squarefree divisors of n, along
            # with the number of prime factors of each divisor
            my @sd;
            foreach my $pe (@factor_exp) {
                my ($p) = @$pe;
                push @sd, map { [$_->[0] * $p, $_->[1] + 1] } @sd;
                push @sd, [$p, 1];
            }

            push @sd, [$ONE, 0];

            my $prod = Math::GMPz::Rmpz_init_set_ui(1);

            foreach my $pair (@sd) {
                my ($d, $c) = @$pair;

                my $base = Math::GMPz::Rmpz_init();
                my $exp  = CORE::int($n / $d);

                Math::GMPz::Rmpz_powm_ui($base, $x, $exp, $m);    # x^(n/d) mod m
                Math::GMPz::Rmpz_sub_ui($base, $base, 1);

                if ($c % 2 == 1) {
                    Math::GMPz::Rmpz_invert($base, $base, $m) || return $base;
                }

                Math::GMPz::Rmpz_mul($prod, $prod, $base);
                Math::GMPz::Rmpz_mod($prod, $prod, $m);
            }

            $prod;
        };

        $n = Math::GMPz::Rmpz_init_set($n);    # copy

        my @factors;
        state $g = Math::GMPz::Rmpz_init_nobless();

      OUTER: foreach my $x (@bases) {
            my $limit = 1 + __ilog__($n, $x);

            foreach my $k (3 .. $limit) {
                my $c = $cyclotomicmod->($k, $x, $n);

                Math::GMPz::Rmpz_gcd($g, $n, $c);
                if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0 and Math::GMPz::Rmpz_cmp($g, $n) < 0) {

                    my $valuation = Math::GMPz::Rmpz_remove($n, $n, $g);
                    push(@factors, (Math::GMPz::Rmpz_init_set($g)) x $valuation);

                    if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0 or _is_prob_prime($n)) {
                        last OUTER;
                    }
                }
            }
        }

        if (Math::GMPz::Rmpz_cmp_ui($n, 1) > 0) {
            push @factors, $n;
        }

        @factors = sort { Math::GMPz::Rmpz_cmp($a, $b) } @factors;
        @factors = map  { bless \$_ } @factors;
        Sidef::Types::Array::Array->new(\@factors);
    }

    sub powerfree_sum {
        my ($k, $from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $k->powerfree_sum($to)->sub($k->powerfree_sum($from->dec));
        }

        _valid(\$from);

        my $n = _any2mpz($$from) // return ZERO;
        $k = _any2ui($$k) // return ZERO;

        Math::GMPz::Rmpz_sgn($n) > 0
          or return ZERO;

        return ZERO if ($k == 0);
        return ONE  if ($k == 1);

        state $t = Math::GMPz::Rmpz_init_nobless();
        state $u = Math::GMPz::Rmpz_init_nobless();
        state $w = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_root($t, $n, $k);
        Math::GMPz::Rmpz_fits_ulong_p($t) || goto &nan;    # too large

        my $s   = Math::GMPz::Rmpz_get_ui($t);
        my $sum = Math::GMPz::Rmpz_init_set_ui(0);

        if (HAS_NEW_PRIME_UTIL) {
            Math::Prime::Util::forsquarefree(
                sub {

                    # u = faulhaber(floor(n/v^k), 1)
                    Math::GMPz::Rmpz_ui_pow_ui($w, $_, $k);
                    Math::GMPz::Rmpz_div($t, $n, $w);
                    Math::GMPz::Rmpz_mul($u, $t, $t);
                    Math::GMPz::Rmpz_add($u, $u, $t);
                    Math::GMPz::Rmpz_div_2exp($u, $u, 1);

                    # u *= v^k
                    Math::GMPz::Rmpz_mul($u, $u, $w);

                    (scalar(@_) & 1)
                      ? Math::GMPz::Rmpz_sub($sum, $sum, $u)
                      : Math::GMPz::Rmpz_add($sum, $sum, $u);
                },
                $s
            );
        }
        else {
            my $m;
            for (my $v = 1 ; $v <= $s ; ++$v) {
                if ($m = Math::Prime::Util::GMP::moebius($v)) {

                    # u = faulhaber(floor(n/v^k), 1)
                    Math::GMPz::Rmpz_ui_pow_ui($w, $v, $k);
                    Math::GMPz::Rmpz_div($t, $n, $w);
                    Math::GMPz::Rmpz_mul($u, $t, $t);
                    Math::GMPz::Rmpz_add($u, $u, $t);
                    Math::GMPz::Rmpz_div_2exp($u, $u, 1);

                    # u *= v^k
                    Math::GMPz::Rmpz_mul($u, $u, $w);

                    ($m == 1)
                      ? Math::GMPz::Rmpz_add($sum, $sum, $u)
                      : Math::GMPz::Rmpz_sub($sum, $sum, $u);
                }
            }
        }

        return bless \$sum;
    }

    sub squarefree_sum {
        my ($from, $to) = @_;
        (TWO)->powerfree_sum($from, $to);
    }

    sub _native_squarefree_count {
        my ($n) = @_;

        if (HAS_NEW_PRIME_UTIL) {
            return Math::Prime::Util::powerfree_count($n, 2);
        }

        my $s = CORE::int(CORE::sqrt($n));

        # Using moebius(1, sqrt(n)) for values of n <= 2^40
        if ($n <= (1 << 40)) {

            my ($count, $k) = (0, 0);

            foreach my $m (
                           HAS_PRIME_UTIL
                           ? Math::Prime::Util::moebius(1, $s)
                           : Math::Prime::Util::GMP::moebius(1, $s)
              ) {
                ++$k;
                $count += $m * CORE::int($n / ($k * $k)) if $m;
            }

            return $count;
        }

        # Linear counting up to sqrt(n)

        my $count = 0;

        if (HAS_NEW_PRIME_UTIL) {
            Math::Prime::Util::forsquarefree(
                sub {
                    $count += ((scalar(@_) & 1) ? -1 : 1) * CORE::int($n / ($_ * $_));
                },
                $s
            );
        }
        else {
            my $m;
            foreach my $k (1 .. $s) {
                if ($m = Math::Prime::Util::GMP::moebius($k)) {
                    $count += $m * CORE::int($n / ($k * $k));
                }
            }
        }

        return $count;
    }

    sub powerfree_count {
        my ($k, $from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $k->powerfree_count($to)->sub($k->powerfree_count($from->dec));
        }

        _valid(\$from);

        my $n = _any2mpz($$from) // return ZERO;
        $k = _any2ui($$k) // return ZERO;

        Math::GMPz::Rmpz_sgn($n) > 0
          or return ZERO;

        return ZERO if ($k == 0);
        return ONE  if ($k == 1);

        # Optimization for native integers
        if ($k == 2 and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            my $count = _native_squarefree_count(Math::GMPz::Rmpz_get_ui($n));
            return _set_int($count);
        }

        if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return _set_int(Math::Prime::Util::powerfree_count(Math::GMPz::Rmpz_get_ui($n), $k));
        }

        my $c = Math::GMPz::Rmpz_init_set_ui(0);
        state $t = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_root($t, $n, $k);
        Math::GMPz::Rmpz_fits_ulong_p($t) || goto &nan;    # too large

        my $s = Math::GMPz::Rmpz_get_ui($t);

        if (HAS_NEW_PRIME_UTIL) {
            Math::Prime::Util::forsquarefree(
                sub {
                    Math::GMPz::Rmpz_ui_pow_ui($t, $_, $k);
                    Math::GMPz::Rmpz_div($t, $n, $t);
                    (scalar(@_) & 1)
                      ? Math::GMPz::Rmpz_sub($c, $c, $t)
                      : Math::GMPz::Rmpz_add($c, $c, $t);
                },
                $s
            );
        }
        else {
            my $m;
            for (my $v = 1 ; $v <= $s ; ++$v) {
                if ($m = Math::Prime::Util::GMP::moebius($v)) {
                    Math::GMPz::Rmpz_ui_pow_ui($t, $v, $k);
                    Math::GMPz::Rmpz_div($t, $n, $t);
                    ($m == 1)
                      ? Math::GMPz::Rmpz_add($c, $c, $t)
                      : Math::GMPz::Rmpz_sub($c, $c, $t);
                }
            }
        }

        bless \$c;
    }

    sub squarefree_count {
        my ($from, $to) = @_;
        (TWO)->powerfree_count($from, $to);
    }

    *square_free_count = \&squarefree_count;

    sub _prime_count_checkpoint {
        my ($n, $i) = @_;

        $i //= 0;

#<<<
        state $checkpoints = [
            [999999999999989, 29844570422669], [ 99999999999973, 3204941750802 ], [  9999999999971, 346065536839  ], [  2760727302517, 100000000000  ],
            [  2474799787573, 90000000000   ], [  2190026988349, 80000000000   ], [  1906555030411, 70000000000   ], [  1624571841097, 60000000000   ],
            [  1344326694119, 50000000000   ], [  1066173339601, 40000000000   ], [   999999999989, 37607912018   ], [   928037044463, 35000000000   ],
            [   790645490053, 30000000000   ], [   654124187867, 25000000000   ], [   518649879439, 20000000000   ], [   384489816343, 15000000000   ],
            [   252097800623, 10000000000   ], [   225898512559, 9000000000    ], [   200000000507, 8007105083    ], [   173862636221, 7000000000    ],
            [   148059109201, 6000000000    ], [   122430513841, 5000000000    ], [    99999999977, 4118054813    ], [    97011687217, 4000000000    ],
            [    71856445751, 3000000000    ], [    49999999967, 2119654578    ], [    47055833459, 2000000000    ], [    44999999971, 1916268743    ],
            [    39999999979, 1711955433    ], [    34999999999, 1506589876    ], [    29999999993, 1300005926    ], [    24999999991, 1091987405    ],
            [    22801763489, 1000000000    ], [    21999999977, 966358351     ], [    20999999981, 924324489     ], [    20422213579, 900000000     ],
            [    19999999967, 882206716     ], [    18999999959, 840000027     ], [    18054236957, 800000000     ], [    17999999989, 797703398     ],
            [    16999999999, 755305935     ], [    15999999991, 712799821     ], [    15699342107, 700000000     ], [    14999999969, 670180516     ],
            [    13999999991, 627440336     ], [    13359555403, 600000000     ], [    12999999959, 584570200     ], [    11999999983, 541555851     ],
            [    11037271757, 500000000     ], [    10999999999, 498388617     ], [     9999999967, 455052511     ], [     9899999987, 450708777     ],
            [     9883692017, 450000000     ], [     9699999997, 442014876     ], [     9499999979, 433311792     ], [     9299999999, 424603409     ],
            [     8999999993, 411523195     ], [     8736028057, 400000000     ], [     8699999953, 398425675     ], [     8499999941, 389682427     ],
            [     8299999993, 380930729     ], [     7999999957, 367783654     ], [     7594955549, 350000000     ], [     7499999999, 345826612     ],
            [     7299999979, 337024801     ], [     6999999989, 323804352     ], [     6699999991, 310558733     ], [     6499999993, 301711468     ],
            [     6461335109, 300000000     ], [     6399999959, 297285198     ], [     6299999977, 292856421     ], [     5999999989, 279545368     ],
            [     5699999999, 266206294     ], [     5499999997, 257294520     ], [     5336500537, 250000000     ], [     5299999967, 248370960     ],
            [     5199999977, 243902342     ], [     4999999937, 234954223     ], [     4899999983, 230475545     ], [     4699999987, 221504167     ],
            [     4499999989, 212514323     ], [     4299999973, 203507248     ], [     4222234741, 200000000     ], [     4199999929, 198996103     ],
            [     4000000483, 189961831     ], [     3999999979, 189961812     ], [     3899999989, 185436625     ], [     3799999979, 180906194     ],
            [     3699999991, 176369517     ], [     3499999991, 167279333     ], [     3399999971, 162725196     ], [     3299999959, 158165829     ],
            [     3099999953, 149028641     ], [     2999999929, 144449537     ], [     2899999957, 139864011     ], [     2799999973, 135270258     ],
            [     2699999989, 130670192     ], [     2599999991, 126062167     ], [     2499999977, 121443371     ], [     2399999983, 116818447     ],
            [     2199999973, 107540122     ], [     2038074743, 100000000     ], [     1999999973, 98222287      ], [     1899999979, 93547928      ],
            [     1799999977, 88862422      ], [     1699999997, 84163019      ], [     1599999983, 79451833      ], [     1499999957, 74726528      ],
            [     1399999987, 69985473      ], [     1299999983, 65228333      ], [     1199999993, 60454705      ], [     1099999997, 55662470      ],
            [      999999937, 50847534      ], [      982451653, 50000000      ], [      949999993, 48431471      ], [      899999963, 46009215      ],
            [      849999977, 43581966      ], [      799999999, 41146179      ], [      749999989, 38703181      ], [      699999953, 36252931      ],
            [      649999993, 33793395      ], [      599999971, 31324703      ], [      549999959, 28845356      ], [      499999993, 26355867      ],
            [      449999993, 23853038      ], [      399999959, 21336326      ], [      373587883, 20000000      ], [      369999979, 19818405      ],
            [      359999989, 19311288      ], [      349999999, 18803526      ], [      329999987, 17785475      ], [      299999977, 16252325      ],
            [      289999999, 15739663      ], [      269999993, 14711384      ], [      249999991, 13679318      ], [      229999981, 12642573      ],
            [      199999991, 11078937      ], [      189999989, 10555473      ], [      179424673, 10000000      ], [      169999967, 9503083       ],
            [      159999997, 8974458       ], [      149999957, 8444396       ], [      139999991, 7912199       ], [      119999987, 6841648       ],
            [       99999989, 5761455       ], [       94999951, 5489749       ], [       89999999, 5216954       ], [       86028121, 5000000       ],
            [       84999979, 4943731       ], [       79999987, 4669382       ], [       74999959, 4394304       ], [       69999989, 4118064       ],
            [       64999981, 3840554       ], [       59999999, 3562115       ], [       54999943, 3282200       ], [       49999991, 3001134       ],
            [       44999971, 2718160       ], [       39999983, 2433654       ], [       34999969, 2146775       ], [       32452843, 2000000       ],
            [       29999999, 1857859       ], [       24999983, 1565927       ], [       19999999, 1270607       ], [       18999997, 1211050       ],
            [       17999987, 1151367       ], [       16999999, 1091314       ], [       15999989, 1031130       ], [       15485863, 1000000       ],
            [       14999981, 970704        ], [       13999981, 910077        ], [       12999997, 849252        ], [       11999989, 788060        ],
            [       10999997, 726517        ], [        9999991, 664579        ], [        8999993, 602489        ], [        7999993, 539777        ],
            [        7368787, 500000        ], [        6999997, 476648        ], [        5999993, 412849        ], [        4999999, 348513        ],
            [        3999971, 283146        ], [        3499999, 250150        ], [        2999999, 216816        ], [        2750159, 200000        ],
            [        2499997, 183072        ], [        1999993, 148933        ], [        1299709, 100000        ], [        1159523, 90000         ],
            [        1020379, 80000         ], [         999983, 78498         ], [         882377, 70000         ], [         746773, 60000         ],
            [         611953, 50000         ], [         499979, 41538         ], [         479909, 40000         ], [         350377, 30000         ],
            [         224737, 20000         ], [         104729, 10000         ], [          99991, 9592          ], [          93179, 9000          ],
            [          81799, 8000          ], [          70657, 7000          ], [          59359, 6000          ], [          49999, 5133          ],
            [          48611, 5000          ], [          37813, 4000          ], [          27449, 3000          ], [          17389, 2000          ],
            [           9973, 1229          ], [           7919, 1000          ], [           4999, 669           ], [            997, 168           ],
        ];
#>>>

        state $end = $#{$checkpoints};

        my $left  = 0;
        my $right = $end;

        my ($middle, $item, $cmp);

        while (1) {
            $middle = (
                       HAS_NEW_PRIME_UTIL
                       ? Math::Prime::Util::divint(Math::Prime::Util::addint($right, $left), 2)
                       : Math::Prime::Util::GMP::divint(Math::Prime::Util::GMP::addint($right, $left), 2)
                      );
            $item = $checkpoints->[$middle][$i];
            $cmp  = ($n <=> $item) || last;

            if ($cmp < 0) {
                $left = $middle + 1;
                if ($left > $right) {
                    ++$middle;
                    last;
                }
            }
            else {
                $right = $middle - 1;
                $left > $right && last;
            }
        }

        my $point = $checkpoints->[$middle] // return (undef, undef);
        return ($point->[0], $point->[1]);
    }

    sub _nth_prime_lower {
        my ($n) = @_;
        CORE::int($n * (CORE::log($n) + CORE::log(CORE::log($n)) - 1));
    }

    sub _nth_prime_upper {
        my ($n) = @_;
        CORE::int($n * (CORE::log($n) + CORE::log(CORE::log($n))));
    }

    sub _nth_almost_prime_lower {
        my ($n, $k) = @_;

        my $factorial_km1 = 1;

        for my $j (2 .. $k - 1) {
            $factorial_km1 *= $j;
        }

        CORE::int(($n * CORE::log($n)) / ((CORE::log(CORE::log($n))**($k - 1)) / $factorial_km1));
    }

    sub _prime_count_range {
        my ($x, $y) = @_;

        if ($y <= $x) {
            if ($x == $y and Math::Prime::Util::GMP::is_prime($x)) {
                return 1;
            }
            return 0;
        }

        my $count = 0;
        my $step  = _nth_prime_lower($y + CORE::log($y) * 2e3) - _nth_prime_lower($y);

        if ($step <= 0 or $step > 1e8) {
            $step = 1e6;
        }

        for (my $i = $x - 1 ; $i <= $y ; $i += $step) {

            my $from = $i + 1;
            my $to   = $i + $step;

            $to = $y if $to > $y;

            $count += () = Math::Prime::Util::GMP::sieve_primes($from, $to);
        }

        return $count;
    }

    sub _prime_count {
        my ($x, $y) = @_;

        state $primepi_lookup = {

            # Number of primes below 10^n
            # OEIS: https://oeis.org/A006880
            "1000000"                      => "78498",
            "10000000"                     => "664579",
            "100000000"                    => "5761455",
            "1000000000"                   => "50847534",
            "10000000000"                  => "455052511",
            "100000000000"                 => "4118054813",
            "1000000000000"                => "37607912018",
            "10000000000000"               => "346065536839",
            "100000000000000"              => "3204941750802",
            "1000000000000000"             => "29844570422669",
            "10000000000000000"            => "279238341033925",
            "100000000000000000"           => "2623557157654233",
            "1000000000000000000"          => "24739954287740860",
            "10000000000000000000"         => "234057667276344607",
            "100000000000000000000"        => "2220819602560918840",
            "1000000000000000000000"       => "21127269486018731928",
            "10000000000000000000000"      => "201467286689315906290",
            "100000000000000000000000"     => "1925320391606803968923",
            "1000000000000000000000000"    => "18435599767349200867866",
            "10000000000000000000000000"   => "176846309399143769411680",
            "100000000000000000000000000"  => "1699246750872437141327603",
            "1000000000000000000000000000" => "16352460426841680446427399",

            # Number of primes <= floor(sqrt(10^(2n+1)))
            # OEIS: https://oeis.org/A122121
            "3162277"                    => "227647",
            "31622776"                   => "1951957",
            "316227766"                  => "17082666",
            "3162277660"                 => "151876932",
            "31622776601"                => "1367199811",
            "316227766016"               => "12431880460",
            "3162277660168"              => "113983535775",
            "31622776601683"             => "1052370166553",
            "316227766016837"            => "9773865306521",
            "3162277660168379"           => "91238789797384",
            "31622776601683793"          => "855502559228365",
            "316227766016837933"         => "8052994747583677",
            "3162277660168379331"        => "76066570954337300",
            "31622776601683793319"       => "720722641159301040",
            "316227766016837933199"      => "6847673381013822597",
            "3162277660168379331998"     => "65223071241820793398",
            "31622776601683793319988"    => "622647095301172021671",
            "316227766016837933199889"   => "5956317545928249075039",
            "3162277660168379331998893"  => "57086403558149290301868",
            "31622776601683793319988935" => "548074549053620897173483",

            # Number of primes <= floor(10^n / k), for some small numbers k
            "10309278350515"   => "356392355629",
            "104166666666"     => "4282427463",
            "1041666666666"    => "39114743793",
            "10416666666666"   => "359975632063",
            "104166666666666"  => "3334113665385",
            "10638297872340"   => "367367036747",
            "106382978723404"  => "3402756647584",
            "1063829787234"    => "39915368200",
            "1111111111111111" => "33056584174789",
            "111111111111111"  => "3549047966156",
            "11111111111111"   => "383118399785",
            "1111111111111"    => "41621368073",
            "111111111111"     => "4555800188",
            "11235955056179"   => "387273732609",
            "116279069767441"  => "3708728266177",
            "1162790697674"    => "43483092670",
            "11627906976744"   => "400309533209",
            "12048192771084"   => "414271426137",
            "1219512195121"    => "45522996012",
            "12195121951219"   => "419148610121",
            "121951219512195"  => "3883734854095",
            "1234567901234"    => "46063874709",
            "12345679012345"   => "424144130506",
            "123456790123456"  => "3930144678942",
            "123456790123"     => "5040193472",
            "1250000000000000" => "37058666602970",
            "125000000000000"  => "3977696644164",
            "12500000000000"   => "429262473738",
            "1250000000000"    => "46618036665",
            "125000000000"     => "5100605440",
            "12658227848101"   => "434508183042",
            "133333333333333"  => "4234170485973",
            "13513513513513"   => "462826669200",
            "135135135135135"  => "4289558418919",
            "1351351351351"    => "50251513574",
            "13698630136986"   => "468947991808",
            "137174211248"     => "5576181164",
            "138888888888"     => "5643027425",
            "1388888888888"    => "51594745537",
            "13888888888888"   => "475236412836",
            "138888888888888"  => "4404877383892",
            "14084507042253"   => "481699024983",
            "14285714285"      => "639663667",
            "142857142857142"  => "4526682048776",
            "1428571428571428" => "42185591326481",
            "14285714285714"   => "488343188629",
            "1428571428571"    => "53013308951",
            "142857142857"     => "5797603975",
            "1428571428"       => "71341127",
            "14925373134328"   => "509445517621",
            "156250000000000"  => "4937023458275",
            "15625000000000"   => "532492027113",
            "1562500000000"    => "57790812036",
            "156250000000"     => "6318108621",
            "16129032258064"   => "549074258778",
            "161290322580645"  => "5091169161272",
            "1612903225806"    => "59584931448",
            "16393442622950"   => "557766346667",
            "1666666666666"    => "61496476037",
            "16666666666666"   => "566743254123",
            "166666666666666"  => "5255429125062",
            "1666666666666666" => "48993281778403",
            "166666666666"     => "6721737844",
            "16949152542372"   => "576019453837",
            "169491525423728"  => "5341670076170",
            "17241379310344"   => "585610147276",
            "172413793103448"  => "5430838640194",
            "1724137931034"    => "63537448178",
            "1851851851851"    => "68064427524",
            "185185185185185"  => "5820007824922",
            "18518518518518"   => "627463720453",
            "185185185185"     => "7436940214",
            "18867924528301"   => "638897445082",
            "188679245283018"  => "5926333832509",
            "195312500000"     => "7826876358",
            "2000000000000000" => "58478215681891",
            "200000000000000"  => "6270424651315",
            "20000000000000"   => "675895909271",
            "2000000000000"    => "73301896139",
            "200000000000"     => "8007105059",
            "20000000000"      => "882206716",
            "2000000000"       => "98222287",
            "208333333333333"  => "6523333943109",
            "20833333333333"   => "703087019180",
            "2083333333333"    => "76241905348",
            "208333333333"     => "8327097931",
            "21276595744680"   => "717535853858",
            "212765957446808"  => "6657734355710",
            "2127659574468"    => "77804020175",
            "217391304347826"  => "6797887995201",
            "21739130434782"   => "732602396419",
            "2173913043478"    => "79432841094",
            "222222222222222"  => "6944174236933",
            "22222222222222"   => "748327378590",
            "232558139534883"  => "7256837914986",
            "2325581395348"    => "84765434681",
            "23255813953488"   => "781934640950",
            "2439024390243"    => "88746041012",
            "243902439024390"  => "7599523082981",
            "24390243902439"   => "818764914659",
            "24414062500"      => "1067503007",
            "2500000000000000" => "72623478149504",
            "250000000000000"  => "7783516108362",
            "25000000000000"   => "838538039510",
            "2500000000000"    => "90882915772",
            "250000000000"     => "9920079604",
            "263157894736842"  => "8180096926854",
            "26315789473684"   => "881153649559",
            "2631578947368"    => "95487895305",
            "270270270270270"  => "8394214368915",
            "27027027027027"   => "904160213736",
            "2702702702702"    => "97973697682",
            "277777777777"     => "10976339421",
            "2777777777777"    => "100595137378",
            "277777777777777"  => "8620043221450",
            "27777777777777"   => "928423650342",
            "2941176470588"    => "106292129666",
            "294117647058823"  => "9110926447966",
            "29411764705882"   => "981160027955",
            "312500000000000"  => "9662193791231",
            "31250000000000"   => "1040375711845",
            "3125000000000"    => "112688110354",
            "312500000000"     => "12291069731",
            "3225806451612"    => "116189994198",
            "322580645161290"  => "9964085882898",
            "32258064516129"   => "1072800852668",
            "3333333333"       => "159687131",
            "33333333333"      => "1437873584",
            "333333333333"     => "13077229631",
            "3333333333333"    => "119921146470",
            "33333333333333"   => "1107351740716",
            "333333333333333"  => "10285792709504",
            "3333333333333333" => "96028033831165",
            "3448275862068"    => "123905016177",
            "34482758620689"   => "1144245941771",
            "344827586206896"  => "10629343624801",
            "370370370370"     => "14470326153",
            "3703703703703"    => "132741764431",
            "370370370370370"  => "11391582423328",
            "37037037037037"   => "1226093877740",
            "3846153846153"    => "137660753262",
            "38461538461538"   => "1271660515811",
            "384615384615384"  => "11815989555322",
            "390625000000"     => "15229927577",
            "400000000000000"  => "12273824155491",
            "40000000000000"   => "1320811971702",
            "4000000000000"    => "142966208126",
            "411522633744"     => "16012100612",
            "416666666666"     => "16204404651",
            "4166666666666"    => "148705830761",
            "41666666666666"   => "1373991431074",
            "416666666666666"  => "12769221416219",
            "434782608695"     => "16880968331",
            "4347826086956"    => "154935587256",
            "43478260869565"   => "1431718321829",
            "434782608695652"  => "13307030092080",
            "4545454545454"    => "161721584165",
            "45454545454545"   => "1494605849770",
            "454545454545454"  => "13892973435920",
            "48828125000"      => "2072060851",
            "5000000000000000" => "142377417196364",
            "500000000000000"  => "15237833654620",
            "50000000000000"   => "1638923764567",
            "5000000000000"    => "177291661649",
            "500000000000"     => "19308136142",
            "50000000000"      => "2119654578",
            "5000000000"       => "234954223",
            "5154639175257"    => "182577435554",
            "51546391752577"   => "1687924844082",
            "526315789473"     => "20284110437",
            "5263157894736"    => "186283514910",
            "52631578947368"   => "1722283675178",
            "526315789473684"  => "16014764115918",
            "555555555555"     => "21366409911",
            "5555555555555"    => "196256438549",
            "55555555555555"   => "1814751287143",
            "555555555555555"  => "16876678891443",
            "5617977528089"    => "198383139405",
            "56179775280898"   => "1834471308010",
            "588235294117"     => "22573541239",
            "5882352941176"    => "207381587155",
            "58823529411764"   => "1917915926717",
            "588235294117647"  => "17838418304439",
            "60240963855421"   => "1962605300107",
            "6024096385542"    => "212200329534",
            "625000000000000"  => "18918502148600",
            "62500000000000"   => "2033760752473",
            "6250000000000"    => "219872297126",
            "625000000000"     => "23928619968",
            "62500000000"      => "2624687920",
            "6329113924050"    => "222556880781",
            "63291139240506"   => "2058660902059",
            "66666666666"      => "2792083254",
            "666666666666"     => "25460842735",
            "6666666666666"    => "233998450404",
            "66666666666666"   => "2164793088936",
            "666666666666666"  => "20140348712061",
            "68493150684931"   => "2222149729012",
            "6849315068493"    => "240181159890",
            "7042253521126"    => "246706152157",
            "70422535211267"   => "2282685767114",
            "71428571428571"   => "2314230232867",
            "714285714285714"  => "21534014686327",
            "7142857142857"    => "250106086224",
            "74626865671641"   => "2414421726909",
            "7462686567164"    => "260904088230",
            "769230769230"     => "29217952804",
            "7692307692307"    => "268646892583",
            "76923076923076"   => "2486270966954",
            "769230769230769"  => "23138727712057",
            "76923076923"      => "3202406654",
            "7692307692"       => "354277612",
            "769230769"        => "39643338",
            "781250000000"     => "29656993786",
            "8196721311475"    => "285628623364",
            "81967213114754"   => "2643871089132",
            "833333333333"     => "31556671177",
            "8333333333333"    => "290221685283",
            "83333333333333"   => "2686501525128",
            "833333333333333"  => "25006683974403",
            "83333333333"      => "3457724375",
            "8474576271186"    => "294967792369",
            "84745762711864"   => "2730554048517",
            "9090909090"       => "415488843",
            "909090909090"     => "34312203318",
            "90909090909090"   => "2922521280710",
            "909090909090909"  => "27208902168103",
            "9090909090909"    => "315647597350",
            "90909090909"      => "3758465612",
            "909090909"        => "46450197",
            "9174311926605"    => "318442343729",
            "9345794392523"    => "324185856798",
            "9433962264150"    => "327137540745",
            "94339622641509"   => "3029193708578",
            "9708737864077"    => "336330446255",
            "97656250000"      => "4025476060",
            "9900990099009"    => "342757310840",

            # Number of primes <= 2^n.
            # OEIS: https://oeis.org/A007053
            "1048576"                      => "82025",
            "2097152"                      => "155611",
            "4194304"                      => "295947",
            "8388608"                      => "564163",
            "16777216"                     => "1077871",
            "33554432"                     => "2063689",
            "67108864"                     => "3957809",
            "134217728"                    => "7603553",
            "268435456"                    => "14630843",
            "536870912"                    => "28192750",
            "1073741824"                   => "54400028",
            "2147483648"                   => "105097565",
            "4294967296"                   => "203280221",
            "8589934592"                   => "393615806",
            "17179869184"                  => "762939111",
            "34359738368"                  => "1480206279",
            "68719476736"                  => "2874398515",
            "137438953472"                 => "5586502348",
            "274877906944"                 => "10866266172",
            "549755813888"                 => "21151907950",
            "1099511627776"                => "41203088796",
            "2199023255552"                => "80316571436",
            "4398046511104"                => "156661034233",
            "8796093022208"                => "305761713237",
            "17592186044416"               => "597116381732",
            "35184372088832"               => "1166746786182",
            "70368744177664"               => "2280998753949",
            "140737488355328"              => "4461632979717",
            "281474976710656"              => "8731188863470",
            "562949953421312"              => "17094432576778",
            "1125899906842624"             => "33483379603407",
            "2251799813685248"             => "65612899915304",
            "4503599627370496"             => "128625503610475",
            "9007199254740992"             => "252252704148404",
            "18014398509481984"            => "494890204904784",
            "36028797018963968"            => "971269945245201",
            "72057594037927936"            => "1906879381028850",
            "144115188075855872"           => "3745011184713964",
            "288230376151711744"           => "7357400267843990",
            "576460752303423488"           => "14458792895301660",
            "1152921504606846976"          => "28423094496953330",
            "2305843009213693952"          => "55890484045084135",
            "4611686018427387904"          => "109932807585469973",
            "9223372036854775808"          => "216289611853439384",
            "18446744073709551616"         => "425656284035217743",
            "36893488147419103232"         => "837903145466607212",
            "73786976294838206464"         => "1649819700464785589",
            "147573952589676412928"        => "3249254387052557215",
            "295147905179352825856"        => "6400771597544937806",
            "590295810358705651712"        => "12611864618760352880",
            "1180591620717411303424"       => "24855455363362685793",
            "2361183241434822606848"       => "48995571600129458363",
            "4722366482869645213696"       => "96601075195075186855",
            "9444732965739290427392"       => "190499823401327905601",
            "18889465931478580854784"      => "375744164937699609596",
            "37778931862957161709568"      => "741263521140740113483",
            "75557863725914323419136"      => "1462626667154509638735",
            "151115727451828646838272"     => "2886507381056867953916",
            "302231454903657293676544"     => "5697549648954257752872",
            "604462909807314587353088"     => "11248065615133675809379",
            "1208925819614629174706176"    => "22209558889635384205844",
            "2417851639229258349412352"    => "43860397052947409356492",
            "4835703278458516698824704"    => "86631124695994360074872",
            "9671406556917033397649408"    => "171136408646923240987028",
            "19342813113834066795298816"   => "338124238545210097236684",
            "38685626227668133590597632"   => "668150111666935905701562",
            "77371252455336267181195264"   => "1320486952377516565496055",
            "154742504910672534362390528"  => "2610087356951889016077639",
            "309485009821345068724781056"  => "5159830247726102115466054",
            "618970019642690137449562112"  => "10201730804263125133012340",
            "1237940039285380274899124224" => "20172933541156002700963336",
            "2475880078570760549798248448" => "39895115987049029184882256",
                                };

        if (defined($y)) {
            $x = 2 if ($x < 2);
        }
        else {
            $y = $x;
            $x = 2;
        }

        return 0 if ($y < $x);
        return 0 if ($y <= 0);

        my $table_len = 100003;

        state $pi_table = do {
            my @pi;

            my $k     = 0;
            my $count = 0;

            foreach my $p (Math::Prime::Util::GMP::sieve_primes(2, $table_len)) {
                splice(@pi, $k, $p - $k + 1, ($count) x ($p - $k + 1));
                $k = $p;
                ++$count;
            }

            \@pi;
        };

        if ($x eq '2') {
            if ($y < $table_len) {
                return $pi_table->[$y];
            }

            if (defined(my $value = $primepi_lookup->{$y})) {
                return $value;
            }
        }

        if (HAS_PRIME_UTIL) {
            my $prime_count = Math::Prime::Util::prime_count("$x", "$y");
            return "$prime_count";
        }
        elsif ($y >= ~0 or ($y >= 1e7 and Math::Prime::Util::GMP::subint($y, $x) <= 1e6) or "$x" / "$y" >= 0.999) {

            if ("$x" eq "$y") {    # workaround for danaj/Math-Prime-Util-GMP #33
                return (_is_prob_prime("$x") ? 1 : 0);
            }

            # Support for arbitrary large integers (slow for wide ranges)
            my $prime_count = Math::Prime::Util::GMP::prime_count("$x", "$y");
            return $prime_count;
        }

#<<<
        # Simple implementation of the prime-counting function (although it's pretty slow for large n)
        #~ if ($x > 2) {
            #~ return Math::Prime::Util::GMP::subint(__SUB__->($y), __SUB__->(Math::Prime::Util::GMP::subint($x, 1)));
        #~ }

        #~ my $n = $y;
        #~ my $r = Math::Prime::Util::GMP::sqrtint($n);
        #~ my @V = map { CORE::int($n / $_) } 1 .. $r;
        #~ push @V, CORE::reverse(1 .. $V[-1] - 1);

        #~ my %S;
        #~ @S{@V} = @V;

        #~ foreach my $p (2 .. $r) {
            #~ if ($S{$p} > $S{$p - 1}) {
                #~ my $cp = $S{$p - 1};
                #~ my $p2 = $p * $p;
                #~ foreach my $v (@V) {
                    #~ last if ($v < $p2);
                    #~ $S{$v} -= $S{CORE::int($v / $p)} - $cp;
                #~ }
            #~ }
        #~ }

        #~ return $S{$n} - 1;
#>>>

        my ($x_n, $x_pi);
        my ($y_n, $y_pi);

        if ($y >= 1e3) {

            ($y_n, $y_pi) = _prime_count_checkpoint($y);

            if ($x >= 1e3) {
                ($x_n, $x_pi) = _prime_count_checkpoint($x);
            }
            else {
                $x_n = $x;
                ($x == 2) ? ($x_pi = 1) : ($x_pi = () = Math::Prime::Util::GMP::sieve_primes(2, $x));
            }
        }

        if (defined($x_n) and defined($y_n)) {

            my $d_x = $x - $x_n;
            my $d_y = $y - $y_n;

            if (($d_x + $d_y) <= ($y - $x)) {

                # Sieve the ranges [x_n, x] and [y_n, y]
                my $x_count = _prime_count_range(_next_prime($x_n), _prev_prime($x + 1)) + $x_pi;
                my $y_count = _prime_count_range(_next_prime($y_n), _prev_prime($y + 1)) + $y_pi;

                my $prime_count = $y_count - $x_count;
                ++$prime_count if ($x == 2 or Math::Prime::Util::GMP::is_prime($x));
                return $prime_count;
            }
        }

        # Sieve the range [x, y]
        my $prime_count = _prime_count_range(_next_prime($x - 1), _prev_prime($y + 1));

        return $prime_count;
    }

    sub prime_count {
        my ($x, $y) = @_;

        if (defined($y)) {
            _valid(\$y);
            $x = _big2istr($x) // return ZERO;
            $x = 2 if $x < 2;
            $y = _big2uistr($y) // return ZERO;
        }
        else {
            $y = _big2uistr($x) // return ZERO;
            $x = 2;
        }

        return ZERO if ($y < $x);

        _set_int(_prime_count($x, $y));
    }

    *primepi      = \&prime_count;
    *count_primes = \&prime_count;

    sub prime_count_lower {
        my ($n) = @_;

        $n = _any2mpz($$n) // return ZERO;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO;
        }

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return _set_int(Math::Prime::Util::prime_count_lower(Math::GMPz::Rmpz_get_ui($n)));
        }

        _set_int(Math::Prime::Util::GMP::prime_count_lower(Math::GMPz::Rmpz_get_str($n, 10)));
    }

    *primepi_lower = \&prime_count_lower;

    sub prime_count_upper {
        my ($n) = @_;

        $n = _any2mpz($$n) // return ZERO;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO;
        }

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return _set_int(Math::Prime::Util::prime_count_upper(Math::GMPz::Rmpz_get_ui($n)));
        }

        _set_int(Math::Prime::Util::GMP::prime_count_upper(Math::GMPz::Rmpz_get_str($n, 10)));
    }

    *primepi_upper = \&prime_count_upper;

    sub prime_power_count_lower {
        my ($n) = @_;

        $n = _any2mpz($$n) // return ZERO;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO;
        }

        if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return _set_int(Math::Prime::Util::prime_power_count_lower(Math::GMPz::Rmpz_get_ui($n)));
        }

        my $t     = Math::GMPz::Rmpz_init();
        my $count = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $k (1 .. __ilog__($n, 2)) {
            Math::GMPz::Rmpz_root($t, $n, $k);
            Math::GMPz::Rmpz_add($count, $count, ${(bless \$t)->prime_count_lower});
        }

        bless \$count;
    }

    sub prime_power_count_upper {
        my ($n) = @_;

        $n = _any2mpz($$n) // return ZERO;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO;
        }

        if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return _set_int(Math::Prime::Util::prime_power_count_upper(Math::GMPz::Rmpz_get_ui($n)));
        }

        my $t     = Math::GMPz::Rmpz_init();
        my $count = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $k (1 .. __ilog__($n, 2)) {
            Math::GMPz::Rmpz_root($t, $n, $k);
            Math::GMPz::Rmpz_add($count, $count, ${(bless \$t)->prime_count_upper});
        }

        bless \$count;
    }

    sub composite_count_lower {
        my ($n) = @_;
        $n->sub($n->prime_count_upper)->dec;
    }

    sub composite_count_upper {
        my ($n) = @_;
        $n->sub($n->prime_count_lower)->dec;
    }

    sub _nth_composite_lower_bound {
        my ($n) = @_;

        # n + n/log(n) + n/(log(n)**2)
        my $log_n = $n->log;
        $n->add($n->div($log_n))->add($n->div($log_n->mul($log_n)));
    }

    sub _nth_composite_upper_bound {
        my ($n) = @_;

        # n + n/log(n) + (3*n)/(log(n)**2))
        my $log_n = $n->log;
        $n->add($n->div($log_n))->add($n->mul(_set_int(3))->div($log_n->mul($log_n)));
    }

    sub nth_composite_lower {
        my ($n) = @_;

        my $z = _any2mpz($$n) // goto &nan;

        if (Math::GMPz::Rmpz_sgn($z) <= 0) {
            return ZERO;
        }

        if (Math::GMPz::Rmpz_cmp_ui($z, 3) <= 0) {
            return _set_int(4);
        }

        bsearch_min(
            $n->_nth_composite_lower_bound,
            $n->_nth_composite_upper_bound,
            Sidef::Types::Block::Block->new(
                code => sub {
                    $_[0]->composite_count_upper->cmp($n);
                }
            )
        );
    }

    *composite_lower = \&nth_composite_lower;

    sub nth_composite_upper {
        my ($n) = @_;

        my $z = _any2mpz($$n) // goto &nan;

        if (Math::GMPz::Rmpz_sgn($z) < 0) {
            return ZERO;
        }

        if (Math::GMPz::Rmpz_cmp_ui($z, 3) <= 0) {
            return _set_int(8);
        }

        bsearch_max(
            $n->_nth_composite_lower_bound,
            $n->_nth_composite_upper_bound,
            Sidef::Types::Block::Block->new(
                code => sub {
                    $_[0]->composite_count_lower->cmp($n);
                }
            )
        );
    }

    *composite_upper = \&nth_composite_upper;

    sub _nth_prime_lower_bound {
        my ($n) = @_;
        my $log_n = $n->log;
        $n->mul($log_n->add($log_n->log)->dec);
    }

    sub _nth_prime_upper_bound {
        my ($n) = @_;
        my $log_n = $n->log;
        $n->mul($log_n->add($log_n->log));
    }

    sub nth_prime_lower {
        my ($n) = @_;

        my $z = _any2mpz($$n) // goto &nan;

        if (Math::GMPz::Rmpz_cmp_ui($z, 10) <= 0) {
            return $n->nth_prime;
        }

        bsearch_min(
            $n->_nth_prime_lower_bound,
            $n->_nth_prime_upper_bound,
            Sidef::Types::Block::Block->new(
                code => sub {
                    $_[0]->prime_count_upper->cmp($n);
                }
            )
        );
    }

    *prime_lower = \&nth_prime_lower;

    sub nth_prime_upper {
        my ($n) = @_;

        my $z = _any2mpz($$n) // goto &nan;

        if (Math::GMPz::Rmpz_cmp_ui($z, 10) <= 0) {
            return $n->nth_prime;
        }

        bsearch_max(
            $n->_nth_prime_lower_bound,
            $n->_nth_prime_upper_bound,
            Sidef::Types::Block::Block->new(
                code => sub {
                    $_[0]->prime_count_lower->cmp($n);
                }
            )
        );
    }

    *prime_upper = \&nth_prime_upper;

    sub nth_prime_power_lower {
        my ($n) = @_;

        my $z = _any2mpz($$n) // goto &nan;

        if (Math::GMPz::Rmpz_sgn($z) <= 0) {
            return ZERO;
        }

        bsearch_min(
            $n,
            $n->nth_prime_upper,
            Sidef::Types::Block::Block->new(
                code => sub {
                    $_[0]->prime_power_count_upper->cmp($n);
                }
            )
        );
    }

    *prime_power_lower = \&nth_prime_power_lower;

    sub nth_prime_power_upper {
        my ($n) = @_;

        my $z = _any2mpz($$n) // goto &nan;

        if (Math::GMPz::Rmpz_sgn($z) <= 0) {
            return ZERO;
        }

        bsearch_max(
            $n,
            $n->nth_prime_upper,
            Sidef::Types::Block::Block->new(
                code => sub {
                    $_[0]->prime_power_count_lower->cmp($n);
                }
            )
        );
    }

    *prime_power_upper = \&nth_prime_power_upper;

    sub almost_prime_count {
        my ($k, $from, $to) = @_;

        _valid(\$from);

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $k->almost_prime_count($to)->sub($k->almost_prime_count($from->dec));
        }

        $k = _any2ui($$k) // return ZERO;

        if ($k == 0) {
            return ONE;
        }
        elsif ($k == 1) {
            return $_[1]->prime_count;
        }
        elsif ($k == 2) {
            return $_[1]->semiprime_count;
        }

        state $pi_k_lookup = {
            3 => {
                  "10000000"             => "2444359",
                  "100000000"            => "23727305",
                  "1000000000"           => "229924367",
                  "10000000000"          => "2227121996",
                  "100000000000"         => "21578747909",
                  "1000000000000"        => "209214982913",
                  "10000000000000"       => "2030133769624",
                  "100000000000000"      => "19717814526785",
                  "1000000000000000"     => "191693417109381",
                  "10000000000000000"    => "1865380637252270",
                  "100000000000000000"   => "18168907486812690",
                  "1000000000000000000"  => "177123437184971927",
                  "10000000000000000000" => "1728190923820610000",
                 },

            4 => {
                  "10000000"           => "2050696",
                  "100000000"          => "20959322",
                  "1000000000"         => "212385942",
                  "10000000000"        => "2139236881",
                  "100000000000"       => "21454599814",
                  "1000000000000"      => "214499908019",
                  "10000000000000"     => "2139634739326",
                  "100000000000000"    => "21306682904040",
                  "1000000000000000"   => "211905511283590",
                  "10000000000000000"  => "2105504493045818",
                  "100000000000000000" => "20905484578206982",
                 },

            5 => {
                  "10000000"        => "1349779",
                  "100000000"       => "14371023",
                  "1000000000"      => "150982388",
                  "10000000000"     => "1570678136",
                  "100000000000"    => "16218372618",
                  "1000000000000"   => "166497674684",
                  "10000000000000"  => "1701439985694",
                  "100000000000000" => "17323079621014",
                 },

            6 => {
                  "10000000"        => "774078",
                  "100000000"       => "8493366",
                  "1000000000"      => "91683887",
                  "10000000000"     => "977694273",
                  "100000000000"    => "10327249593",
                  "1000000000000"   => "108264085934",
                  "10000000000000"  => "1128049914377",
                  "100000000000000" => "11694704489580",
                 },

            7 => {
                  "10000000"        => "409849",
                  "100000000"       => "4600247",
                  "1000000000"      => "50678212",
                  "10000000000"     => "550454756",
                  "100000000000"    => "5913771637",
                  "1000000000000"   => "62981797962",
                  "10000000000000"  => "665997804082",
                  "100000000000000" => "7001087934965",
                 },

            8 => {
                  "10000000"        => "207207",
                  "100000000"       => "2367507",
                  "1000000000"      => "26483012",
                  "10000000000"     => "291646797",
                  "100000000000"    => "3173159326",
                  "1000000000000"   => "34192782745",
                  "10000000000000"  => "365561221293",
                  "100000000000000" => "3882841742380",
                 },

            9 => {
                  "10000000"        => "101787",
                  "100000000"       => "1180751",
                  "1000000000"      => "13377156",
                  "10000000000"     => "148930536",
                  "100000000000"    => "1636170477",
                  "1000000000000"   => "17787688377",
                  "10000000000000"  => "191742524399",
                  "100000000000000" => "2052389350029",
                 },

            10 => {
                   "10000000"        => "49163",
                   "100000000"       => "578154",
                   "1000000000"      => "6618221",
                   "10000000000"     => "74342563",
                   "100000000000"    => "823164388",
                   "1000000000000"   => "9011965866",
                   "10000000000000"  => "97765974368",
                   "100000000000000" => "1052666075366",
                  },

            11 => {
                   "10000000"        => "23448",
                   "100000000"       => "279286",
                   "1000000000"      => "3230577",
                   "10000000000"     => "36585097",
                   "100000000000"    => "407818620",
                   "1000000000000"   => "4490844534",
                   "10000000000000"  => "48972151631",
                   "100000000000000" => "529781669333",
                  },

            12 => {
                   "10000000"        => "11068",
                   "100000000"       => "133862",
                   "1000000000"      => "1563465",
                   "10000000000"     => "17836903",
                   "100000000000"    => "200051717",
                   "1000000000000"   => "2214357712",
                   "10000000000000"  => "24255601105",
                   "100000000000000" => "263439785143",
                  },

            13 => {
                   "100000000"       => "63724",
                   "1000000000"      => "751610",
                   "10000000000"     => "8641282",
                   "100000000000"    => "97493048",
                   "1000000000000"   => "1084343921",
                   "10000000000000"  => "11926066887",
                   "100000000000000" => "129986121851",
                  },

            14 => {
                   "100000000"       => "30143",
                   "1000000000"      => "359812",
                   "10000000000"     => "4167745",
                   "100000000000"    => "47294032",
                   "1000000000000"   => "528497496",
                   "10000000000000"  => "5835244859",
                   "100000000000000" => "63809981451",
                  },

            15 => {
                   "100000000"       => "14221",
                   "1000000000"      => "171396",
                   "10000000000"     => "2002277",
                   "100000000000"    => "22864432",
                   "1000000000000"   => "256721609",
                   "10000000000000"  => "2845415088",
                   "100000000000000" => "31214953362",
                  },

            16 => {
                   "100000000"        => "6644",
                   "1000000000"       => "81378",
                   "10000000000"      => "959377",
                   "100000000000"     => "11023759",
                   "1000000000000"    => "124381518",
                   "10000000000000"   => "1384019728",
                   "100000000000000"  => "15231822577",
                   "1000000000000000" => "166147634770",
                  },

            17 => {
                   "1000000000"       => "38537",
                   "10000000000"      => "458176",
                   "100000000000"     => "5301868",
                   "1000000000000"    => "60136853",
                   "10000000000000"   => "671874910",
                   "100000000000000"  => "7418588349",
                   "1000000000000000" => "81141472649",
                  },

            18 => {
                   "10000000000"      => "218163",
                   "100000000000"     => "2544515",
                   "1000000000000"    => "29020610",
                   "10000000000000"   => "325615879",
                   "100000000000000"  => "3607646060",
                   "1000000000000000" => "39569497036",
                  },

            19 => {
                   "10000000000"      => "103657",
                   "100000000000"     => "1218224",
                   "1000000000000"    => "13978352",
                   "10000000000000"   => "157569342",
                   "100000000000000"  => "1752071168",
                   "1000000000000000" => "19273117219",
                  },

            20 => {
                   "10000000000"      => "49032",
                   "100000000000"     => "581979",
                   "1000000000000"    => "6722135",
                   "10000000000000"   => "76139019",
                   "100000000000000"  => "849839564",
                   "1000000000000000" => "9377172857",
                  },
        };

        my $v = _big2uistr($from) // return ZERO;

        if (exists($pi_k_lookup->{$k}) and defined(my $count = $pi_k_lookup->{$k}{$v})) {
            return _set_int($count);
        }

        my $n = _any2mpz($$from) // return ZERO;

        if (Math::GMPz::Rmpz_cmp_ui($n, $k) <= 0) {
            return ZERO;
        }

        state $t = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_set_ui($t, 0);
        Math::GMPz::Rmpz_setbit($t, $k);

        if (Math::GMPz::Rmpz_cmp($n, $t) < 0) {
            return ZERO;
        }

        if (    HAS_NEW_PRIME_UTIL
            and Math::GMPz::Rmpz_fits_ulong_p($n)
            and Math::Prime::Util::almost_prime_count(10, 1024) == 1) {
            return _set_int(Math::Prime::Util::almost_prime_count($k, Math::GMPz::Rmpz_get_ui($n)));
        }

        my $count = Math::GMPz::Rmpz_init_set_ui(0);

        sub {
            my ($m, $p, $k, $j) = @_;

            my $s = do {
                Math::GMPz::Rmpz_div($t, $n, $m);
                Math::GMPz::Rmpz_root($t, $t, $k);
                Math::GMPz::Rmpz_get_ui($t);
            };

            if ($k == 2) {

                foreach my $q (
                               HAS_PRIME_UTIL
                               ? @{Math::Prime::Util::primes($p, $s)}
                               : Math::Prime::Util::GMP::sieve_primes($p, $s)
                  ) {

                    Math::GMPz::Rmpz_mul_ui($t, $m, $q);
                    Math::GMPz::Rmpz_div($t, $n, $t);

                    my $pi = _prime_count(Math::GMPz::Rmpz_get_str($t, 10));

                    if ($pi < ULONG_MAX) {
                        Math::GMPz::Rmpz_add_ui($count, $count, $pi - $j);
                    }
                    else {
                        Math::GMPz::Rmpz_set_str($t, "$pi", 10);
                        Math::GMPz::Rmpz_sub_ui($t, $t, $j);
                        Math::GMPz::Rmpz_add($count, $count, $t);
                    }

                    ++$j;
                }

                return;
            }

            for (my $q = $p ; $q <= $s ; $q = _next_prime($q)) {
                __SUB__->($m * $q, $q, $k - 1, $j++);
            }
          }
          ->(Math::GMPz::Rmpz_init_set_ui(1), 2, $k, 0);

        bless \$count;
    }

    *pi_k           = \&almost_prime_count;
    *almost_primepi = \&almost_prime_count;

    sub squarefree_almost_prime_count {
        my ($k, $from, $to) = @_;

        _valid(\$from);

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $k->squarefree_almost_prime_count($to)->sub($k->squarefree_almost_prime_count($from->dec));
        }

        $k = _any2ui($$k) // return ZERO;

        if ($k == 0) {
            return ONE;
        }
        elsif ($k == 1) {
            return $_[1]->prime_count;
        }

        state $t = Math::GMPz::Rmpz_init_nobless();

        my $n = _any2mpz($$from) // return ZERO;

        Math::GMPz::Rmpz_sgn($n) > 0
          or return ZERO;

        my $count = Math::GMPz::Rmpz_init_set_ui(0);

        sub {
            my ($m, $p, $k, $j) = @_;

            my $s = do {
                Math::GMPz::Rmpz_div($t, $n, $m);
                Math::GMPz::Rmpz_root($t, $t, $k);
                Math::GMPz::Rmpz_get_ui($t);
            };

            if ($k == 2) {

                foreach my $q (
                               HAS_PRIME_UTIL
                               ? @{Math::Prime::Util::primes($p, $s)}
                               : Math::Prime::Util::GMP::sieve_primes($p, $s)
                  ) {

                    Math::GMPz::Rmpz_mul_ui($t, $m, $q);
                    Math::GMPz::Rmpz_div($t, $n, $t);

                    my $pi = _prime_count(Math::GMPz::Rmpz_get_str($t, 10));

                    if ($pi < ULONG_MAX) {
                        Math::GMPz::Rmpz_add_ui($count, $count, $pi - $j);
                    }
                    else {
                        Math::GMPz::Rmpz_set_str($t, "$pi", 10);
                        Math::GMPz::Rmpz_sub_ui($t, $t, $j);
                        Math::GMPz::Rmpz_add($count, $count, $t);
                    }

                    ++$j;
                }

                return;
            }

            for (; $p <= $s ; ++$j) {
                my $r = _next_prime($p);
                __SUB__->($m * $p, $r, $k - 1, $j + 1);
                $p = $r;
            }
          }
          ->(Math::GMPz::Rmpz_init_set_ui(1), 2, $k, 1);

        bless \$count;
    }

    *squarefree_pi_k           = \&squarefree_almost_prime_count;
    *squarefree_almost_primepi = \&squarefree_almost_prime_count;

    sub omega_prime_count {
        my ($k, $from, $to) = @_;

        _valid(\$from);

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $k->omega_prime_count($to)->sub($k->omega_prime_count($from->dec));
        }

        $k = _any2ui($$k) // return ZERO;

        if ($k == 0) {
            return ONE;
        }
        elsif ($k == 1) {
            return $_[1]->prime_power_count;
        }

        state $t = Math::GMPz::Rmpz_init_nobless();
        state $u = Math::GMPz::Rmpz_init_nobless();
        state $v = Math::GMPz::Rmpz_init_nobless();

        my $n = _any2mpz($$from) // return ZERO;

        # MPU is quite slow for large k. See also: danaj/Math-Prime-Util #72
        if (HAS_NEW_PRIME_UTIL and $k < 15 and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return _set_int(Math::Prime::Util::omega_prime_count($k, Math::GMPz::Rmpz_get_ui($n)));
        }

        Math::GMPz::Rmpz_sgn($n) > 0
          or return ZERO;

        my $count = Math::GMPz::Rmpz_init_set_ui(0);

        sub {
            my ($m, $p, $k, $j, $s) = @_;

            $s //= do {
                Math::GMPz::Rmpz_div($t, $n, $m);
                Math::GMPz::Rmpz_root($t, $t, $k);
                Math::GMPz::Rmpz_get_ui($t);
            };

            if ($k == 2) {

                for (; $p <= $s ; ++$j) {

                    my $r = _next_prime($p);

                    for (Math::GMPz::Rmpz_mul_ui($v, $m, $p) ;
                         Math::GMPz::Rmpz_cmp($v, $n) <= 0 ;
                         Math::GMPz::Rmpz_mul_ui($v, $v, $p)) {

                        Math::GMPz::Rmpz_div($t, $n, $v);

                        if (Math::GMPz::Rmpz_cmp_ui($t, $r) < 0) {
                            last;
                        }

                        my $w  = Math::GMPz::Rmpz_get_str($t, 10);
                        my $pi = _prime_count($w);

                        if ($pi < ULONG_MAX) {
                            Math::GMPz::Rmpz_add_ui($count, $count, $pi - $j);
                        }
                        else {
                            Math::GMPz::Rmpz_set_str($t, "$pi", 10);
                            Math::GMPz::Rmpz_sub_ui($t, $t, $j);
                            Math::GMPz::Rmpz_add($count, $count, $t);
                        }

                        for (my $r2 = $r ; $r2 <= $w ; $r2 = _next_prime($r2)) {

                            Math::GMPz::Rmpz_mul_ui($u, $v, $r2);
                            Math::GMPz::Rmpz_mul_ui($u, $u, $r2);

                            if (Math::GMPz::Rmpz_cmp($u, $n) > 0) {
                                last;
                            }

                            my $i = 0;
                            for (; Math::GMPz::Rmpz_cmp($u, $n) <= 0 ; Math::GMPz::Rmpz_mul_ui($u, $u, $r2)) {
                                ++$i;
                            }
                            Math::GMPz::Rmpz_add_ui($count, $count, $i);
                        }
                    }

                    $p = $r;
                }

                return;
            }

            for (; $p <= $s ; ++$j) {

                my $r = _next_prime($p);

                for (my $w = $m * $p ; Math::GMPz::Rmpz_cmp($w, $n) <= 0 ; Math::GMPz::Rmpz_mul_ui($w, $w, $p)) {

                    Math::GMPz::Rmpz_div($t, $n, $w);
                    Math::GMPz::Rmpz_root($t, $t, $k - 1);

                    my $s = Math::GMPz::Rmpz_get_ui($t);
                    last if ($r > $s);
                    __SUB__->($w, $r, $k - 1, $j + 1, $s);
                }

                $p = $r;
            }
          }
          ->(Math::GMPz::Rmpz_init_set_ui(1), 2, $k, 1);

        bless \$count;
    }

    *omega_primepi = \&omega_prime_count;

    sub nth_omega_prime {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
            $k >= 1 or goto &nan;
        }
        else {
            $k = 2;
        }

        if ($k == 1) {
            return $n->nth_prime_power;
        }

        my $k_obj = _set_int($k);
        my $n_obj = $n;

        $n = _any2mpz($$n) // goto &nan;

        Math::GMPz::Rmpz_sgn($n) > 0 or do {
            return ONE if (Math::GMPz::Rmpz_sgn($n) == 0);    # not k-omega prime, but...
            goto &nan;
        };

        my $min = Math::GMPz::Rmpz_init();
        my $max = Math::GMPz::Rmpz_init_set($n);

        Math::GMPz::Rmpz_set($min, _cached_pn_primorial($k));
        Math::GMPz::Rmpz_mul_2exp($max, $min, 1);

        while (Math::GMPz::Rmpz_cmp(${$k_obj->omega_prime_count(bless \$max)}, $n) < 0) {
            Math::GMPz::Rmpz_set($min, $max);
            Math::GMPz::Rmpz_mul_ui($max, $max, 2);
        }

        if (HAS_NEW_PRIME_UTIL and $k <= 12 and Math::GMPz::Rmpz_fits_ulong_p($max)) {    # too slow for large k
            my $r = Math::Prime::Util::nth_omega_prime($k, $n);
            if ($r) {
                return _set_int("$r");
            }
        }

        my $v     = Math::GMPz::Rmpz_init();
        my $count = Math::GMPz::Rmpz_init();

        while (1) {
            Math::GMPz::Rmpz_add($v, $min, $max);
            Math::GMPz::Rmpz_div_2exp($v, $v, 1);

            $count =
              (HAS_NEW_PRIME_UTIL and $k < 15 and Math::GMPz::Rmpz_fits_ulong_p($v))
              ? Math::GMPz::Rmpz_init_set_ui(Math::Prime::Util::omega_prime_count($k, Math::GMPz::Rmpz_get_ui($v)))
              : ${$k_obj->omega_prime_count(bless \$v)};

            my $cmp = Math::GMPz::Rmpz_cmp($count, $n);

            if ($cmp > 0) {
                Math::GMPz::Rmpz_sub_ui($max, $v, 1);
            }
            elsif ($cmp < 0) {
                Math::GMPz::Rmpz_add_ui($min, $v, 1);
            }
            else {
                last;
            }
        }

        $k_obj->omega_primes((bless \$min), (bless \$v))->last;
    }

    sub next_omega_prime {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) || goto &nan;
        }
        else {
            $k = 2;
        }

        if ($k == 1) {
            return $n->next_prime_power;
        }

        my $n_obj = $n;
        my $k_obj = _set_int($k);

        $n = _any2mpz($$n) // goto &nan;

        if (Math::GMPz::Rmpz_sgn($n) < 0) {
            goto &nan;
        }

        my $r = Math::GMPz::Rmpz_init_set(_cached_pn_primorial($k));

        # The smallest k-omega prime is primorial(p_k)
        if (Math::GMPz::Rmpz_cmp($n, $r) < 0) {
            return bless \$r;
        }

        # TODO: detect large n with moderately large k
        if ($k <= 7) {

            # Optimization for native integers
            if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_slong_p($n)) {
                $n = Math::GMPz::Rmpz_get_ui($n) + 1;
                until (Math::Prime::Util::is_omega_prime($k, $n)) {
                    ++$n;
                }
                return _set_int($n);
            }

            Math::GMPz::Rmpz_add_ui($r, $n, 1);

            my $r_obj = bless \$r;

            until ($r_obj->is_omega_prime($k_obj)) {
                Math::GMPz::Rmpz_add_ui($r, $r, 1);
            }

            return $r_obj;
        }

        $k_obj->omega_prime_count($n_obj)->inc->nth_omega_prime($k_obj);
    }

    sub nth_squarefree_almost_prime {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
            $k >= 1 or goto &nan;
        }
        else {
            $k = 2;
        }

        if ($k == 1) {
            return $n->nth_prime;
        }

        my $k_obj = _set_int($k);
        my $n_obj = $n;

        $n = _any2mpz($$n) // goto &nan;

        Math::GMPz::Rmpz_sgn($n) > 0 or do {
            return ONE if (Math::GMPz::Rmpz_sgn($n) == 0);    # not k-almost prime, but...
            goto &nan;
        };

        my $min = Math::GMPz::Rmpz_init();
        my $max = Math::GMPz::Rmpz_init_set($n);

        Math::GMPz::Rmpz_set($min, _cached_pn_primorial($k));
        Math::GMPz::Rmpz_mul_2exp($max, $min, 1);

        while (Math::GMPz::Rmpz_cmp(${$k_obj->squarefree_almost_prime_count(bless \$max)}, $n) < 0) {
            Math::GMPz::Rmpz_set($min, $max);
            Math::GMPz::Rmpz_mul_ui($max, $max, 2);
        }

        my $v     = Math::GMPz::Rmpz_init();
        my $count = Math::GMPz::Rmpz_init();

        while (1) {
            Math::GMPz::Rmpz_add($v, $min, $max);
            Math::GMPz::Rmpz_div_2exp($v, $v, 1);

            $count = ${$k_obj->squarefree_almost_prime_count(bless \$v)};

            my $cmp = Math::GMPz::Rmpz_cmp($count, $n);

            if ($cmp > 0) {
                Math::GMPz::Rmpz_sub_ui($max, $v, 1);
            }
            elsif ($cmp < 0) {
                Math::GMPz::Rmpz_add_ui($min, $v, 1);
            }
            else {
                last;
            }
        }

        $k_obj->squarefree_almost_primes((bless \$min), (bless \$v))->last;
    }

    sub next_squarefree_almost_prime {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) || goto &nan;
        }
        else {
            $k = 2;
        }

        if ($k == 1) {
            return $n->next_prime;
        }

        my $n_obj = $n;
        my $k_obj = _set_int($k);

        $n = _any2mpz($$n) // goto &nan;

        if (Math::GMPz::Rmpz_sgn($n) < 0) {
            goto &nan;
        }

        my $r = Math::GMPz::Rmpz_init_set(_cached_pn_primorial($k));

        # The smallest squarefree k-almost prime is primorial(p_k)
        if (Math::GMPz::Rmpz_cmp($n, $r) < 0) {
            return bless \$r;
        }

        # TODO: detect large n with moderately large k
        if ($k <= 7) {

            # Optimization for native integers
            if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_slong_p($n)) {
                $n = Math::GMPz::Rmpz_get_ui($n) + 1;
                until (Math::Prime::Util::is_almost_prime($k, $n) and Math::Prime::Util::is_square_free($n)) {
                    ++$n;
                }
                return _set_int($n);
            }

            Math::GMPz::Rmpz_add_ui($r, $n, 1);

            my $r_obj = bless \$r;

            until ($r_obj->is_almost_prime($k_obj) && $r_obj->is_squarefree) {
                Math::GMPz::Rmpz_add_ui($r, $r, 1);
            }

            return $r_obj;
        }

        $k_obj->squarefree_almost_prime_count($n_obj)->inc->nth_squarefree_almost_prime($k_obj);
    }

    sub prime_power_count {
        my ($x, $y) = @_;

        if (defined($y)) {
            _valid(\$y);
            $x = _big2istr($x) // return ZERO;
            $x = 2 if $x < 2;
            $y = _big2uistr($y) // return ZERO;
        }
        else {
            $y = _big2uistr($x) // return ZERO;
            $x = 2;
        }

        # Support for large integers
        if ($y >= ~0) {

            $x = Math::GMPz::Rmpz_init_set_str("$x", 10);
            $y = Math::GMPz::Rmpz_init_set_str("$y", 10);

            if ($y - $x > 1e6) {

                if ($x == 2) {

                    $y = __PACKAGE__->new($y);

                    my $pp_count = ZERO;
                    my $ilog2    = Math::GMPz::Rmpz_get_ui(${$y->ilog2});

                    for (my $k = 1 ; $k <= $ilog2 ; ++$k) {
                        my $root = $y->iroot(_set_int($k));
                        $pp_count = $pp_count->add($root->prime_count);
                    }

                    return $pp_count;
                }

                my $x_pp_count = __PACKAGE__->new($x)->prime_power_count;
                my $y_pp_count = __PACKAGE__->new($y)->prime_power_count;

                my $pp_count = $y_pp_count->sub($x_pp_count);

                if (Math::Prime::Util::GMP::is_prime_power($x)) {
                    $pp_count = $pp_count->inc;
                }

                return $pp_count;
            }

            my $count = 0;

            for (; Math::GMPz::Rmpz_cmp($x, $y) <= 0 ; Math::GMPz::Rmpz_add_ui($x, $x, 1)) {
                ++$count if Math::Prime::Util::GMP::is_prime_power(Math::GMPz::Rmpz_get_str($x, 10));
            }

            return _set_int($count);
        }

        return ZERO if ($y < $x);

#<<<
        state $pp_table = [ 0,  0,  1,  2,  3,  4,  4,  5,  6,  7,  7,  8,  8,  9,  9,  9, 10, 11, 11, 12, 12,
                           12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 18, 18, 18, 18, 18, 19, 19, 19, 19, 20,
                           20, 21, 21, 21, 21, 22, 22, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 25, 25, 26, 26,
                           26, 27, 27, 27, 28, 28, 28, 28, 29, 29, 30, 30, 30, 30, 30, 30, 31, 31, 32, 32, 33,
                           33, 33, 33, 33, 33, 34, 34, 34, 34, 34, 34, 34, 34, 35, 35, 35, 35];

        state $pi_table = [ 0,  0,  1,  2,  2,  3,  3,  4,  4,  4,  4,  5,  5,  6,  6,  6,  6,  7,  7,  8,  8,  8,
                            8,  9,  9,  9,  9,  9,  9, 10, 10, 11, 11, 11, 11, 11, 11, 12, 12, 12, 12, 13, 13, 14,
                           14, 14, 14, 15, 15, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 17, 17, 18, 18, 18, 18, 18,
                           18, 19, 19, 19, 19, 20, 20, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 23, 23, 23, 23, 23,
                           23, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25, 25];
#>>>

        # Optimization for narrow ranges
        if ($y - $x <= 100 or "$x" / "$y" >= 0.999) {

            if ($x <= 2 and $y <= 100) {
                return _set_int($pp_table->[$y]);
            }

            my $count = 0;

            for (; $x <= $y ; ++$x) {
                ++$count if Math::Prime::Util::GMP::is_prime_power($x);
            }

            return ZERO if ($count == 0);
            return ONE  if ($count == 1);

            return _set_int($count);
        }

        my $pp_count = sub {
            my ($n) = @_;

            return $pp_table->[$n] if $n <= 100;

            my $count = 0;

            foreach my $k (1 .. Math::Prime::Util::GMP::logint($n, 2)) {
                my $r = Math::Prime::Util::GMP::rootint($n, $k);

                if ($r <= 100) {
                    $count += $pi_table->[$r];
                }
                else {
                    $count += _prime_count($r);
                }
            }

            $count;
        };

        my $x_pp_count = ($x == 2 ? 1 : $pp_count->($x));
        my $y_pp_count = $pp_count->($y);

        my $count = $y_pp_count - $x_pp_count;

        if ($x == 2 or Math::Prime::Util::GMP::is_prime_power($x)) {
            ++$count;
        }

        _set_int($count);
    }

    sub nth_prime {
        my ($n) = @_;

        $n = _big2uistr($n) // goto &nan;

        if ($n == 0) {
            return ONE;    # not a prime, but may be convenient...
        }

        state $nth_prime_lookup = {

            # (10^n)-th prime.
            # OEIS: https://oeis.org/A006988
            "10000000"                  => "179424673",
            "100000000"                 => "2038074743",
            "1000000000"                => "22801763489",
            "10000000000"               => "252097800623",
            "100000000000"              => "2760727302517",
            "1000000000000"             => "29996224275833",
            "10000000000000"            => "323780508946331",
            "100000000000000"           => "3475385758524527",
            "1000000000000000"          => "37124508045065437",
            "10000000000000000"         => "394906913903735329",
            "100000000000000000"        => "4185296581467695669",
            "1000000000000000000"       => "44211790234832169331",
            "10000000000000000000"      => "465675465116607065549",
            "100000000000000000000"     => "4892055594575155744537",
            "1000000000000000000000"    => "51271091498016403471853",
            "10000000000000000000000"   => "536193870744162118627429",
            "100000000000000000000000"  => "5596564467986980643073683",
            "1000000000000000000000000" => "58310039994836584070534263",

            # (2^n)-th prime
            # OEIS: https://oeis.org/A033844
            "1073741824"               => "24563311309",
            "2147483648"               => "50685770167",
            "4294967296"               => "104484802057",
            "8589934592"               => "215187847711",
            "17179869184"              => "442795487221",
            "34359738368"              => "910399916939",
            "68719476736"              => "1870358526653",
            "137438953472"             => "3839726846311",
            "274877906944"             => "7877263558621",
            "549755813888"             => "16149760533341",
            "1099511627776"            => "33089240375501",
            "2199023255552"            => "67756520645329",
            "4398046511104"            => "138666449011757",
            "8796093022208"            => "283634652716357",
            "17592186044416"           => "579863159340527",
            "35184372088832"           => "1184895616861903",
            "70368744177664"           => "2420094683001859",
            "140737488355328"          => "4940729268330643",
            "281474976710656"          => "10082409897709157",
            "562949953421312"          => "20566476729238691",
            "1125899906842624"         => "41935796950796653",
            "2251799813685248"         => "85476377250109733",
            "4503599627370496"         => "174160587542317721",
            "9007199254740992"         => "354733509412061993",
            "18014398509481984"        => "722285281729443799",
            "36028797018963968"        => "1470194760556507397",
            "72057594037927936"        => "2991614170035124397",
            "144115188075855872"       => "6085631874569939777",
            "288230376151711744"       => "12375982557205846193",
            "576460752303423488"       => "25161232392544176197",
            "1152921504606846976"      => "51140670371058101123",
            "2305843009213693952"      => "103917116257220706127",
            "4611686018427387904"      => "211104554420210305087",
            "9223372036854775808"      => "428747374788279617303",
            "18446744073709551616"     => "870566678511500413493",
            "36893488147419103232"     => "1767268299972575740723",
            "73786976294838206464"     => "3586789210729460889317",
            "147573952589676412928"    => "7278050150447936843717",
            "295147905179352825856"    => "14764978793012287880219",
            "590295810358705651712"    => "29947588495888738082431",
            "1180591620717411303424"   => "60730194035557507211347",
            "2361183241434822606848"   => "123129946710886829498713",
            "4722366482869645213696"   => "249598086801961825095881",
            "9444732965739290427392"   => "505870764273226657981427",
            "18889465931478580854784"  => "1025087216809475771050003",
            "37778931862957161709568"  => "2076859014052740233944627",
            "75557863725914323419136"  => "4207073961494759547984247",
            "151115727451828646838272" => "8520834035044766488749161",
            "302231454903657293676544" => "17254990129969542495182251",
                                  };

        if (exists($nth_prime_lookup->{$n})) {
            my $p = $nth_prime_lookup->{$n};
            return _set_int($p);
        }

        if ($n > 1_000_000) {

            if (HAS_PRIME_UTIL) {
                my $p = Math::Prime::Util::nth_prime($n);
                return _set_int("$p");
            }

            my $min = ${_set_int($n)->nth_prime_lower};
            my $max = ${_set_int($n)->nth_prime_upper};

            if (!Math::GMPz::Rmpz_fits_ulong_p($max)) {
                goto &nan;
            }

            $min = Math::GMPz::Rmpz_get_ui($min);
            $max = Math::GMPz::Rmpz_get_ui($max);

            my $k = 0;
            my $count;

            while (1) {
                $k = (
                      HAS_NEW_PRIME_UTIL
                      ? Math::Prime::Util::divint(Math::Prime::Util::addint($min, $max), 2)
                      : Math::Prime::Util::GMP::divint(Math::Prime::Util::GMP::addint($min, $max), 2)
                     );

                # Make sure k does not overflow; otherwise return NaN
                goto &nan if ($k > ULONG_MAX or $k <= 0);

                $count = (
                          HAS_PRIME_UTIL
                          ? Math::Prime::Util::prime_count($k)
                          : _prime_count($k)
                         );

                if (CORE::abs($count - $n) <= $k**(2 / 3)) {
                    last;
                }

                my $cmp = $count <=> $n;

                if ($cmp > 0) {
                    $max = $k - 1;
                }
                elsif ($cmp < 0) {
                    $min = $k + 1;
                }
                else {
                    last;
                }
            }

            if (!_is_prob_prime($k)) {
                $k = _prev_prime($k);
            }

            while ($count != $n) {
                my $cmp = ($n <=> $count);
                $k = ($cmp < 0) ? _prev_prime($k) : _next_prime($k);
                $count += $cmp;
            }

            return _set_int($k);
        }

        state @table;

        my $limit = 1000 + CORE::int(2 * $n * CORE::log($n));
        $limit = 15_485_863 if $limit > 15_485_863;

        if (@table < $n) {
            $table[0] = 2;
            push @table, Math::Prime::Util::GMP::sieve_primes($table[-1] + 1, $limit);
        }

        _set_int($table[$n - 1]);
    }

    *prime = \&nth_prime;

    sub nth_prime_power {
        my ($n) = @_;
        $n = _any2ui($$n) // goto &nan;

        return ONE         if ($n == 0);    # not a prime power, but...
        return _set_int(2) if ($n == 1);
        return _set_int(3) if ($n == 2);

        # Lower and upper bounds
        my $min = $n;
        my $max = _nth_prime_upper($n);

        if ($n > 1e6) {

            # Better bounds for the n-th prime power
            $min = ${_set_int($n)->nth_prime_power_lower};
            $max = ${_set_int($n)->nth_prime_power_upper};

            Math::GMPz::Rmpz_fits_ulong_p($max) || goto &nan;

            $min = Math::GMPz::Rmpz_get_ui($min);
            $max = Math::GMPz::Rmpz_get_ui($max);
        }

        if (HAS_NEW_PRIME_UTIL) {
            return _set_int(Math::Prime::Util::nth_prime_power($n));
        }

        my $k = 0;
        my $count;

        while (1) {
            $k = (
                  HAS_NEW_PRIME_UTIL
                  ? Math::Prime::Util::divint(Math::Prime::Util::addint($min, $max), 2)
                  : Math::Prime::Util::GMP::divint(Math::Prime::Util::GMP::addint($min, $max), 2)
                 );

            # Make sure k does not overflow; otherwise return NaN
            goto &nan if ($k > ULONG_MAX or $k <= 0);

            $count = (
                      HAS_NEW_PRIME_UTIL
                      ? Math::Prime::Util::prime_power_count($k)
                      : Math::GMPz::Rmpz_get_ui(${_set_int($k)->prime_power_count})
                     );

            if (CORE::abs($count - $n) <= CORE::int(CORE::sqrt($k))) {
                last;
            }

            my $cmp = $count <=> $n;

            if ($cmp > 0) {
                $max = $k - 1;
            }
            elsif ($cmp < 0) {
                $min = $k + 1;
            }
            else {
                last;
            }
        }

        until (
               HAS_PRIME_UTIL
               ? Math::Prime::Util::is_prime_power($k)
               : Math::Prime::Util::GMP::is_prime_power($k)
          ) {
            --$k;
        }

        while ($count != $n) {
            my $cmp = ($n <=> $count);
            do {
                $k += $cmp;
              }
              until (
                     HAS_PRIME_UTIL
                     ? Math::Prime::Util::is_prime_power($k)
                     : Math::Prime::Util::GMP::is_prime_power($k)
                    );
            $count += $cmp;
        }

        _set_int($k);
    }

    sub composite_count {
        my ($from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $to->composite_count->sub($from->dec->composite_count);
        }

        my $n = _any2mpz($$from) // goto &nan;

        Math::GMPz::Rmpz_cmp_ui($n, 4) >= 0
          or return ZERO;

        my $pi = _set_int(_prime_count(Math::GMPz::Rmpz_get_str($n, 10)));
        bless \__dec__(__sub__($n, $$pi));    # n - pi(n) - 1
    }

    sub nth_composite {
        my ($n) = @_;
        $n = _any2ui($$n) // goto &nan;

        return ONE         if ($n == 0);      # not composite, but...
        return _set_int(4) if ($n == 1);

        # Lower and upper bounds from A002808 (for n >= 4).
        my $min = CORE::int($n + $n / CORE::log($n) + $n / (CORE::log($n)**2));
        my $max = CORE::int($n + $n / CORE::log($n) + (3 * $n) / (CORE::log($n)**2));

        if ($n > 1e6) {

            # Better bounds for the n-th composite number
            $min = ${_set_int($n)->nth_composite_lower};
            $max = ${_set_int($n)->nth_composite_upper};

            Math::GMPz::Rmpz_fits_ulong_p($max) || goto &nan;

            $min = Math::GMPz::Rmpz_get_ui($min);
            $max = Math::GMPz::Rmpz_get_ui($max);
        }

        if ($n < 4) {
            $min = 4;
            $max = 8;
        }

        my $k = 0;
        my $count;

        while (1) {
            $k = (
                  HAS_NEW_PRIME_UTIL
                  ? Math::Prime::Util::divint(Math::Prime::Util::addint($min, $max), 2)
                  : Math::Prime::Util::GMP::divint(Math::Prime::Util::GMP::addint($min, $max), 2)
                 );

            # Make sure k does not overflow; otherwise return NaN
            goto &nan if ($k > ULONG_MAX or $k <= 0);

            my $pi = (
                      HAS_PRIME_UTIL
                      ? Math::Prime::Util::prime_count($k)
                      : _prime_count($k)
                     );

            $count = ($k - $pi - 1);

            if (CORE::abs($count - $n) <= CORE::int(CORE::sqrt($k))) {
                last;
            }

            my $cmp = $count <=> $n;

            if ($cmp > 0) {
                $max = $k - 1;
            }
            elsif ($cmp < 0) {
                $min = $k + 1;
            }
            else {
                last;
            }
        }

        if (_is_prob_prime($k)) {
            --$k;
        }

        while ($count != $n) {
            my $cmp = ($n <=> $count);
            do {
                $k += $cmp;
            } while _is_prob_prime($k);
            $count += $cmp;
        }

        _set_int($k);
    }

    *composite = \&nth_composite;

    sub nth_squarefree {
        my ($n) = @_;

        $n = _any2mpz($$n) // goto &nan;

        Math::GMPz::Rmpz_fits_slong_p($n)
          or return _set_int($n)->nth_powerfree(_set_int(2));

        $n = _any2ui($n) // goto &nan;

        return ZERO if ($n == 0);    # not squarefree, but...
        return ONE  if ($n == 1);

        my $min = 1;
        my $max = 231;

        my $zeta2  = 1.64493406684823;
        my $sqrt_n = CORE::sqrt($n);

        # Bounds on squarefree numbers:
        #   https://mathoverflow.net/questions/66701/bounds-on-squarefree-numbers

        if ($n >= 268293) {
            $min = CORE::int($zeta2 * $n - 0.058377 * $sqrt_n);
            $max = CORE::int($zeta2 * $n + 0.058377 * $sqrt_n);
        }
        elsif ($n >= 144) {
            $min = CORE::int($zeta2 * $n - 5 * $sqrt_n);
            $max = CORE::int($zeta2 * $n + 5 * $sqrt_n);
        }

        my $k = 0;
        my $count;

        while (1) {
            $k = (
                  HAS_NEW_PRIME_UTIL
                  ? Math::Prime::Util::divint(Math::Prime::Util::addint($min, $max), 2)
                  : Math::Prime::Util::GMP::divint(Math::Prime::Util::GMP::addint($min, $max), 2)
                 );

            # Make sure k does not overflow; otherwise return NaN
            goto &nan if ($k > ULONG_MAX or $k <= 0);

            $count = (
                      HAS_NEW_PRIME_UTIL
                      ? Math::Prime::Util::powerfree_count($k, 2)
                      : _native_squarefree_count($k)
                     );

            if (CORE::abs($count - $n) <= CORE::int(CORE::sqrt($k))) {
                last;
            }

            my $cmp = $count <=> $n;

            if ($cmp > 0) {
                $max = $k - 1;
            }
            elsif ($cmp < 0) {
                $min = $k + 1;
            }
            else {
                last;
            }
        }

        until (_is_squarefree($k)) {
            --$k;
        }

        while ($count != $n) {
            my $cmp = ($n <=> $count);
            do {
                $k += $cmp;
            } until _is_squarefree($k);
            $count += $cmp;
        }

        _set_int($k);
    }

    sub nth_powerfree {
        my ($n, $k) = @_;

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 2;
        $n = _any2mpz($$n) // goto &nan;

        $k >= 2 or goto &nan;
        Math::GMPz::Rmpz_sgn($n) < 0 and goto &nan;

        return ZERO if (Math::GMPz::Rmpz_sgn($n) == 0);         # not k-powerfree, but...
        return ONE  if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0);

        if ($k == 2 and Math::GMPz::Rmpz_fits_slong_p($n)) {
            return ((bless \$n)->nth_squarefree);
        }

        my $min = Math::GMPz::Rmpz_init_set_ui(1);
        my $max = Math::GMPz::Rmpz_init_set_ui(231);

        # Bounds on squarefree numbers:
        #   https://mathoverflow.net/questions/66701/bounds-on-squarefree-numbers

        if ($n >= 144) {
            my $f = Math::MPFR::Rmpfr_init2(256);
            Math::MPFR::Rmpfr_zeta_ui($f, $k, $ROUND);
            Math::MPFR::Rmpfr_mul_z($f, $f, $n, $ROUND);

            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_root($r, $n, $k);
            Math::GMPz::Rmpz_mul_ui($r, $r, 5);

            my $t = Math::MPFR::Rmpfr_init2(256);
            Math::MPFR::Rmpfr_sub_z($t, $f, $r, $ROUND);
            $min = _any2mpz($t) // goto &nan;
            Math::MPFR::Rmpfr_add_z($t, $f, $r, $ROUND);
            $max = _any2mpz($t) // goto &nan;
        }

        my $k_obj     = _set_int($k);
        my $v         = Math::GMPz::Rmpz_init();
        my $count     = Math::GMPz::Rmpz_init();
        my $min_delta = Math::GMPz::Rmpz_init();

        while (1) {
            Math::GMPz::Rmpz_add($v, $min, $max);
            Math::GMPz::Rmpz_div_2exp($v, $v, 1);

            $count =
              (HAS_NEW_PRIME_UTIL && Math::GMPz::Rmpz_fits_ulong_p($v))
              ? Math::GMPz::Rmpz_init_set_ui(Math::Prime::Util::powerfree_count(Math::GMPz::Rmpz_get_ui($v), $k))
              : ${$k_obj->powerfree_count(bless \$v)};

            Math::GMPz::Rmpz_root($min_delta, $v, $k);

            if (Math::GMPz::Rmpz_cmp(CORE::abs($count - $n), $min_delta) <= 0) {
                last;
            }

            my $cmp = Math::GMPz::Rmpz_cmp($count, $n);

            if ($cmp > 0) {
                Math::GMPz::Rmpz_sub_ui($max, $v, 1);
            }
            elsif ($cmp < 0) {
                Math::GMPz::Rmpz_add_ui($min, $v, 1);
            }
            else {
                last;
            }
        }

        my $v_obj = bless \$v;

        until ($v_obj->is_powerfree($k_obj)) {
            Math::GMPz::Rmpz_sub_ui($v, $v, 1);
        }

        while (1) {
            my $cmp = Math::GMPz::Rmpz_cmp($n, $count) || last;
            do {
                ($cmp > 0)
                  ? Math::GMPz::Rmpz_add_ui($v, $v, 1)
                  : Math::GMPz::Rmpz_sub_ui($v, $v, 1);
              }
              until (
                     (HAS_NEW_PRIME_UTIL && Math::GMPz::Rmpz_fits_ulong_p($v))
                     ? Math::Prime::Util::is_powerfree(Math::GMPz::Rmpz_get_ui($v), $k)
                     : $v_obj->is_powerfree($k_obj)
                    );
            $count += $cmp;
        }

        $v_obj;
    }

    sub legendre {
        my ($x, $y) = @_;
        _valid(\$y);
        my $s = Math::GMPz::Rmpz_legendre(_any2mpz($$x) // (goto &nan), _any2mpz($$y) // (goto &nan));
        $s ? (($s == 1) ? ONE : MONE) : ZERO;
    }

    *Legendre = \&legendre;

    sub jacobi {
        my ($x, $y) = @_;
        _valid(\$y);
        my $s = Math::GMPz::Rmpz_jacobi(_any2mpz($$x) // (goto &nan), _any2mpz($$y) // (goto &nan));
        $s ? (($s == 1) ? ONE : MONE) : ZERO;
    }

    *Jacobi = \&jacobi;

    sub kronecker {
        my ($x, $y) = @_;
        _valid(\$y);
        my $s = Math::GMPz::Rmpz_kronecker(_any2mpz($$x) // (goto &nan), _any2mpz($$y) // (goto &nan));
        $s ? (($s == 1) ? ONE : MONE) : ZERO;
    }

    *Kronecker = \&kronecker;

    sub kronecker_delta {
        my ($x, $y) = @_;
        _valid(\$y);
        __eq__($$x, $$y) ? ONE : ZERO;
    }

    *δ              = \&kronecker_delta;
    *KroneckerDelta = \&kronecker_delta;

    sub hclassno {
        my ($n) = @_;

        # Algorithm from Math::Prime::Util::PP

        $n = _any2mpz($$n) // goto &nan;

        my $sgn = Math::GMPz::Rmpz_sgn($n);

        if ($sgn < 0) {
            $n = Math::GMPz::Rmpz_init_set($n);    # copy
            Math::GMPz::Rmpz_abs($n, $n);
        }
        elsif ($sgn == 0) {
            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_si($q, -1, 12);
            return bless \$q;
        }

        if (Math::GMPz::Rmpz_congruent_ui_p($n, 1, 4) or Math::GMPz::Rmpz_congruent_ui_p($n, 2, 4)) {
            return ZERO;
        }

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return _set_int(Math::Prime::Util::hclassno(Math::GMPz::Rmpz_get_ui($n)))->div(_set_int(12));
        }

        my $square = 0;

        state $t = Math::GMPz::Rmpz_init_nobless();

        my $h = Math::GMPz::Rmpz_init_set_ui(0);
        my $B = Math::GMPz::Rmpz_init_set_ui(Math::GMPz::Rmpz_odd_p($n) ? 1 : 0);

        my $B2 = Math::GMPz::Rmpz_init_set($n);
        Math::GMPz::Rmpz_add_ui($B2, $B2, 1);
        Math::GMPz::Rmpz_div_2exp($B2, $B2, 2);

        my $lim = Math::GMPz::Rmpz_init();

        if (Math::GMPz::Rmpz_sgn($B) == 0) {
            Math::GMPz::Rmpz_sqrt($lim, $B2);

            if (Math::GMPz::Rmpz_perfect_square_p($B2)) {
                $square = 1;
                Math::GMPz::Rmpz_sub_ui($lim, $lim, 1);
            }

            my $count = 0;
            foreach my $d (_divisors($B2)) {
                if ($d < ULONG_MAX) {
                    (Math::GMPz::Rmpz_cmp_ui($lim, $d) >= 0) ? ++$count : last;
                }
                else {
                    Math::GMPz::Rmpz_set_str($t, $d, 10);
                    (Math::GMPz::Rmpz_cmp($lim, $t) >= 0) ? ++$count : last;
                }
            }

            Math::GMPz::Rmpz_add_ui($h, $h, $count);

            Math::GMPz::Rmpz_set_ui($B, 2);
            Math::GMPz::Rmpz_set($B2, $n);
            Math::GMPz::Rmpz_add_ui($B2, $B2, 4);
            Math::GMPz::Rmpz_div_2exp($B2, $B2, 2);
        }

        while (1) {

            Math::GMPz::Rmpz_mul_ui($t, $B2, 3);
            Math::GMPz::Rmpz_cmp($t, $n) < 0 or last;

            if (Math::GMPz::Rmpz_divisible_p($B2, $B)) {
                Math::GMPz::Rmpz_add_ui($h, $h, 1);
            }

            Math::GMPz::Rmpz_sqrt($lim, $B2);

            if (Math::GMPz::Rmpz_perfect_square_p($B2)) {
                Math::GMPz::Rmpz_add_ui($h, $h, 1);
                Math::GMPz::Rmpz_sub_ui($lim, $lim, 1);
            }

            my $count = 0;
            foreach my $d (_divisors($B2)) {
                if ($d < ULONG_MAX) {
                    Math::GMPz::Rmpz_cmp_ui($lim, $d) >= 0 or last;
                    ++$count if (Math::GMPz::Rmpz_cmp_ui($B, $d) < 0);
                }
                else {
                    Math::GMPz::Rmpz_set_str($t, $d, 10);
                    Math::GMPz::Rmpz_cmp($lim, $t) >= 0 or last;
                    ++$count if (Math::GMPz::Rmpz_cmp($B, $t) < 0);
                }
            }

            Math::GMPz::Rmpz_add_ui($h, $h, 2 * $count) if ($count > 0);
            Math::GMPz::Rmpz_add_ui($B, $B, 2);

            Math::GMPz::Rmpz_mul($B2, $B, $B);
            Math::GMPz::Rmpz_add($B2, $B2, $n);
            Math::GMPz::Rmpz_div_2exp($B2, $B2, 2);
        }

        Math::GMPz::Rmpz_mul_ui($t, $B2, 3);

        my $m = ($square ? 2 : 3);

        if ($square or Math::GMPz::Rmpz_cmp($t, $n) == 0) {
            Math::GMPz::Rmpz_mul_ui($h, $h, $m);
            Math::GMPz::Rmpz_add_ui($h, $h, 1);
            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_ui($q, 1, $m);
            Math::GMPq::Rmpq_mul_z($q, $q, $h);
            return bless \$q;
        }

        return bless \$h;
    }

    sub sum_of_squares_count {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 2;
        }

        $n = _any2mpz($$n) // goto &nan;

        my $sgn = Math::GMPz::Rmpz_sgn($n);

        $sgn < 0  and return ZERO;
        $sgn == 0 and return ONE;

        if ($k <= 0) {
            return ZERO;
        }

        if ($k == 1) {
            return TWO if Math::GMPz::Rmpz_perfect_square_p($n);
            return ZERO;
        }

        state %cache;

        if (scalar(keys(%cache)) > 1e6) {
            undef %cache;
        }

        my $result = sub {
            my ($n, $k) = @_;

            my $sgn = Math::GMPz::Rmpz_sgn($n);

            $sgn < 0  and return 0;
            $sgn == 0 and return 1;

            return 0 if ($k <= 0);

            if ($k == 1) {
                return 2 if Math::GMPz::Rmpz_perfect_square_p($n);
                return 0;
            }

            # r_3(4*n) = r_3(n)
            if ($k == 3 and Math::GMPz::Rmpz_divisible_2exp_p($n, 2)) {
                $n = Math::GMPz::Rmpz_init_set($n);    # copy
                Math::GMPz::Rmpz_div_2exp($n, $n, 2);
            }

            my $t = Math::GMPz::Rmpz_init_set($n);
            my $v = Math::GMPz::Rmpz_remove($t, $t, $TWO);

            if ($k == 2) {    # OEIS: A004018
                Math::GMPz::Rmpz_congruent_ui_p($t, 3, 4) && return 0;

                my $count = Math::GMPz::Rmpz_init_set_ui(4);

                foreach my $pp (_factor_exp($t)) {
                    my ($p, $e) = @$pp;

                    my $r = ($p < ULONG_MAX) ? ($p % 4) : Math::Prime::Util::GMP::modint($p, 4);

                    if ($r == 3) {
                        $e % 2 == 0 or return 0;
                    }

                    if ($r == 1) {
                        Math::GMPz::Rmpz_mul_ui($count, $count, $e + 1);
                    }
                }

                return $count;
            }

            if ($k == 3) {    # OEIS: A005875

                ((($v & 1) == 1) || !Math::GMPz::Rmpz_congruent_ui_p($t, 7, 8)) || return 0;

                if (_is_squarefree($n)) {

                    if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                        my $count = 0;

                        if (Math::GMPz::Rmpz_congruent_ui_p($n, 3, 8)) {
                            $count = eval {
                                Math::Prime::Util::GMP::mulint(Math::Prime::Util::hclassno(Math::GMPz::Rmpz_get_ui($n)), 2);
                            };
                        }
                        else {
                            my $t = $n << 2;    # n is a Math::GMPz object
                            $count =
                              ($t < ULONG_MAX)
                              ? eval { Math::Prime::Util::hclassno(Math::GMPz::Rmpz_get_ui($t)) }
                              : undef;
                        }

                        if (defined($count)) {
                            return Math::GMPz::Rmpz_init_set_str("$count", 10);
                        }
                    }

                    my $h;
                    my $count = Math::GMPz::Rmpz_init();

                    if (Math::GMPz::Rmpz_congruent_ui_p($n, 3, 8)) {
                        $h = ${(bless \$n)->hclassno->mul(_set_int(24))};
                    }
                    else {
                        $h = ${(bless \$n)->mul(_set_int(4))->hclassno->mul(_set_int(12))};
                    }

                    (ref($h) eq 'Math::GMPq')
                      ? Math::GMPz::Rmpz_set_q($count, $h)
                      : Math::GMPz::Rmpz_set($count, $h);

                    return $count;
                }
            }

            if ($k == 4) {    # OEIS: A000118
                my $count =
                  Math::Prime::Util::GMP::mulint(Math::Prime::Util::GMP::sigma(($v >= 1) ? ($t << 1) : $t), 8);
                return Math::GMPz::Rmpz_init_set_str($count, 10);
            }

            if ($k == 6) {    # OEIS: A000141

                # A000141: a(n) = 4( Sum_{ d|n, d == 3 mod 4} d^2 - Sum_{ d|n, d == 1 mod 4} d^2 )
                #              + 16( Sum_{ d|n, n/d == 1 mod 4} d^2 - Sum_{ d|n, n/d == 3 mod 4} d^2 )

                # a(n) = 16*A050470(n) - 4*A002173(n).

                # Multiplicative formulas by Jianing Song, where Chi = A101455:
                #   A050470: Multiplicative with a(p^e) = ((p^2)^(e+1) - Chi(p)^(e+1))/(p^2 - Chi(p)).
                #   A002173: Multiplicative with a(p^e) = ((p^2*Chi(p))^(e+1) - 1)/(p^2*Chi(p) - 1).

                my $prod1 = Math::GMPz::Rmpz_init_set_ui(1);
                my $prod2 = Math::GMPz::Rmpz_init_set_ui(1);

                my $p1 = Math::GMPz::Rmpz_init();
                my $p2 = Math::GMPz::Rmpz_init();

                my $u1 = Math::GMPz::Rmpz_init();
                my $u2 = Math::GMPz::Rmpz_init();

                foreach my $pp (_factor_exp($t)) {
                    my ($p, $e) = @$pp;

                    ($p < ULONG_MAX)
                      ? Math::GMPz::Rmpz_set_ui($p1, $p)
                      : Math::GMPz::Rmpz_set_str($p1, $p, 10);

                    Math::GMPz::Rmpz_pow_ui($u1, $p1, 2 * ($e + 1));
                    Math::GMPz::Rmpz_set($u2, $u1);

                    my $congr1_4 = Math::GMPz::Rmpz_congruent_ui_p($p1, 1, 4);

                    if ($congr1_4 or $e % 2 == 1) {
                        Math::GMPz::Rmpz_sub_ui($u1, $u1, 1);
                        Math::GMPz::Rmpz_sub_ui($u2, $u2, 1);
                    }
                    else {
                        Math::GMPz::Rmpz_add_ui($u1, $u1, 1);
                        Math::GMPz::Rmpz_neg($u2, $u2);
                        Math::GMPz::Rmpz_sub_ui($u2, $u2, 1);
                    }

                    Math::GMPz::Rmpz_mul($p1, $p1, $p1);
                    Math::GMPz::Rmpz_set($p2, $p1);

                    if ($congr1_4) {
                        Math::GMPz::Rmpz_sub_ui($p1, $p1, 1);
                    }
                    else {
                        Math::GMPz::Rmpz_add_ui($p1, $p1, 1);
                        Math::GMPz::Rmpz_neg($p2, $p2);
                    }

                    Math::GMPz::Rmpz_sub_ui($p2, $p2, 1);

                    Math::GMPz::Rmpz_divexact($u1, $u1, $p1);
                    Math::GMPz::Rmpz_divexact($u2, $u2, $p2);

                    Math::GMPz::Rmpz_mul($prod1, $prod1, $u1);
                    Math::GMPz::Rmpz_mul($prod2, $prod2, $u2);
                }

                Math::GMPz::Rmpz_mul_2exp($prod1, $prod1, 4 + 2 * $v);
                Math::GMPz::Rmpz_mul_2exp($prod2, $prod2, 2);
                Math::GMPz::Rmpz_sub($prod1, $prod1, $prod2);

                return $prod1;
            }

            if ($k == 8) {    # OEIS: A000143

                # A138503: a(n) is multiplicative with a(2^e) = -(8^(e+1) - 15) / 7, a(p^e) = ((p^3)^(e+1) - 1) / (p^3 - 1).
                # A138503: Let n = 2^k * m, with m odd, then a(n) = -(8^(k+1) - 15)/7 * sigma_3(m).
                # r_8(n) = 16 * (-1)^n * -A138503(n)

                my $prod = Math::GMPz::Rmpz_init_set_ui(16);

                if ($v > 0) {
                    my $s = Math::GMPz::Rmpz_init();
                    Math::GMPz::Rmpz_ui_pow_ui($s, 8, $v + 1);
                    Math::GMPz::Rmpz_sub_ui($s, $s, 15);
                    Math::GMPz::Rmpz_divexact_ui($s, $s, 7);
                    Math::GMPz::Rmpz_mul($prod, $prod, $s);
                }

                my $count = Math::Prime::Util::GMP::mulint($prod, Math::Prime::Util::GMP::sigma($t, 3));
                return Math::GMPz::Rmpz_init_set_str($count, 10);
            }

            if ($k == 10) {    # OEIS: A000144

                # Efficient formula for k = 10, due to Michael Somos:
                # r_10(n) = 4/5 * (A050456(n) + 16*A050468(n) + 8*A030212(n))

                # A050456 is multiplicative with:
                #   a(2^e) = 1
                #   a(p^e) = ((p^4)^(e+1) - 1) / (p^4 - 1)  if p == 1 (mod 4)
                #   a(p^e) = (1 - (-p^4)^(e+1)) / (1 + p^4) if p == 3 (mod 4)

                # A050468 is multiplicative with:
                #   a(2^e) = 16^e
                #   a(p^e) = ((p^4)^(e+1) - 1) / (p^4 - 1)          if p == 1 (mod 4)
                #   a(p^e) = ((p^4)^(e+1) - (-1)^(e+1)) / (p^4 + 1) if p == 3 (mod 4)

                # A030212 is multiplicative with:
                #   a(2^e) = (-4)^e
                #   a(p^e) = p^(2*e) * (1 + (-1)^e)/2             if p == 3 (mod 4)
                #   a(p^e) = a(p) * a(p^(e-1)) - p^4 * a(p^(e-2)) if p == 1 (mod 4)
                # where a(p) = 2 * Re( (x + i*y)^4 ) and p = x^2 + y^2 with even x.

                my $sum_of_squares_solution = sub {
                    my ($p) = @_;    # p is congruent to 1 mod 4

                    # a(p) = 2 * Re( (x + i*y)^4 ) and p = x^2 + y^2.

                    # ref($p) eq 'Math::GMPz' or die "error";

                    my $u = $p;
                    my $s = Math::GMPz::Rmpz_init_set_str(Math::Prime::Util::GMP::sqrtmod(-1, $u), 10);
                    my $q = $u;

                    while ($s * $s > $u) {
                        ($s, $q) = ($q % $s, $s);
                    }

                    my ($x, $y) = ($s, $q % $s);

                    # ($x*$x + $y*$y == $p)
                    #    or die "Error: $x^2 + $y^2 != $p";

                    my ($re, $im) = _set_int($x)->complex_ipow(_set_int($y), _set_int(4));
                    ${$re->add($re)};
                };

                my $prod1 = Math::GMPz::Rmpz_init_set_ui(1);
                my $prod2 = Math::GMPz::Rmpz_init_set_ui(1);

                my $p1 = Math::GMPz::Rmpz_init();

                my $u1 = Math::GMPz::Rmpz_init();
                my $u2 = Math::GMPz::Rmpz_init();

                my @factors = _factor_exp($t);

                my $chi_4 = sub {
                    my (@f) = @_;

                    if (scalar(@f) == 0) {
                        return $ONE;
                    }

                    my $key = join('*', map { join('^', @$_) } @f);

                    if (exists $cache{$key}) {
                        return $cache{$key};
                    }

                    if (scalar(@f) == 1 and $f[0][1] == 1) {
                        Math::GMPz::Rmpz_set_str($p1, $f[0][0], 10);
                        Math::GMPz::Rmpz_congruent_ui_p($p1, 1, 4) || return $ZERO;
                        return $sum_of_squares_solution->($p1);
                    }

                    my $p2    = Math::GMPz::Rmpz_init();
                    my $prod3 = Math::GMPz::Rmpz_init_set_ui(1);

                    foreach my $pp (@f) {
                        my ($p, $e) = @$pp;

                        ($p < ULONG_MAX)
                          ? Math::GMPz::Rmpz_set_ui($p2, $p)
                          : Math::GMPz::Rmpz_set_str($p2, $p, 10);

                        my $congr3_4 = Math::GMPz::Rmpz_congruent_ui_p($p2, 3, 4);

                        if ($congr3_4) {

                            if ($e % 2 == 1) {
                                $cache{$key} = $ZERO;
                                return $ZERO;
                            }

                            Math::GMPz::Rmpz_pow_ui($p2, $p2, 2 * $e);
                            Math::GMPz::Rmpz_mul($prod3, $prod3, $p2);
                            next;
                        }

                        # Here, we have: p == 1 (mod 4)

                        my $s1 = (($e - 1 == 0) ? 1 : (($e - 1 < 0) ? 0 : __SUB__->([$p, $e - 1])));
                        my $s2 = (($e - 2 == 0) ? 1 : (($e - 2 < 0) ? 0 : __SUB__->([$p, $e - 2])));

                        my $x = $sum_of_squares_solution->($p2) * $s1;
                        my $y = 0;

                        if ($e - 2 >= 0) {
                            Math::GMPz::Rmpz_pow_ui($p2, $p2, 4);
                            $y = $p2 * $s2;
                        }

                        Math::GMPz::Rmpz_mul($prod3, $prod3, $x - $y);
                    }

                    $cache{$key} = $prod3;
                  }
                  ->(@factors);

                my $prod3 = Math::GMPz::Rmpz_init_set($chi_4);

                if ($v >= 1) {
                    Math::GMPz::Rmpz_mul_2exp($prod3, $prod3, 2 * $v);
                    Math::GMPz::Rmpz_neg($prod3, $prod3) if ($v % 2 == 1);
                }

                foreach my $pp (@factors) {
                    my ($p, $e) = @$pp;

                    ($p < ULONG_MAX)
                      ? Math::GMPz::Rmpz_set_ui($p1, $p)
                      : Math::GMPz::Rmpz_set_str($p1, $p, 10);

                    Math::GMPz::Rmpz_pow_ui($u1, $p1, 4 * ($e + 1));

                    my $congr1_4 = Math::GMPz::Rmpz_congruent_ui_p($p1, 1, 4);

                    Math::GMPz::Rmpz_pow_ui($p1, $p1, 4);

                    if ($congr1_4) {
                        Math::GMPz::Rmpz_sub_ui($p1, $p1, 1);
                        Math::GMPz::Rmpz_divexact($u1, $u1, $p1);
                        Math::GMPz::Rmpz_mul($prod1, $prod1, $u1);
                        Math::GMPz::Rmpz_mul($prod2, $prod2, $u1);
                        next;
                    }

                    # Here, we have: p == 3 (mod 4)

                    Math::GMPz::Rmpz_set($u2, $u1);
                    Math::GMPz::Rmpz_add_ui($p1, $p1, 1);

                    if ($e % 2 == 1) {
                        Math::GMPz::Rmpz_neg($u1, $u1);
                        Math::GMPz::Rmpz_sub_ui($u2, $u2, 1);
                    }
                    else {
                        Math::GMPz::Rmpz_add_ui($u2, $u2, 1);
                    }

                    Math::GMPz::Rmpz_add_ui($u1, $u1, 1);
                    Math::GMPz::Rmpz_divexact($u1, $u1, $p1);
                    Math::GMPz::Rmpz_divexact($u2, $u2, $p1);

                    Math::GMPz::Rmpz_mul($prod1, $prod1, $u1);
                    Math::GMPz::Rmpz_mul($prod2, $prod2, $u2);
                }

                Math::GMPz::Rmpz_mul_2exp($prod2, $prod2, 4 * $v) if ($v > 0);

                Math::GMPz::Rmpz_mul_2exp($prod2, $prod2, 4);
                Math::GMPz::Rmpz_mul_2exp($prod3, $prod3, 3);

                Math::GMPz::Rmpz_add($prod1, $prod1, $prod2);
                Math::GMPz::Rmpz_add($prod1, $prod1, $prod3);

                Math::GMPz::Rmpz_mul_2exp($prod1, $prod1, 2);
                Math::GMPz::Rmpz_divexact_ui($prod1, $prod1, 5);

                return $prod1;
            }

            my $key = "$n $k";

            if (exists $cache{$key}) {
                return $cache{$key};
            }

            my $count = Math::GMPz::Rmpz_init_set_ui(0);
            my $tmp   = Math::GMPz::Rmpz_init_set($n);

            foreach my $v (0 .. Math::Prime::Util::GMP::sqrtint($n)) {

                my $u = __SUB__->($tmp, $k - 1);

                ref($u)
                  ? Math::GMPz::Rmpz_addmul_ui($count, $u, (($v == 0) ? 1 : 2))
                  : Math::GMPz::Rmpz_add_ui($count, $count, $u * (($v == 0) ? 1 : 2));

                Math::GMPz::Rmpz_sub_ui($tmp, $tmp, 2 * $v + 1);
            }

            $cache{$key} = $count;
          }
          ->($n, $k);

        _set_int($result);
    }

    *squares_r = \&sum_of_squares_count;

    sub is_ntf {
        my ($x, $y) = @_;

        $x = $$x;

        if (ref($x) ne 'Math::GMPz') {
            __is_int__($x) || return Sidef::Types::Bool::Bool::FALSE;
            $x = _any2mpz($x) // return Sidef::Types::Bool::Bool::FALSE;
        }

        Math::GMPz::Rmpz_cmp_ui($x, 1) > 0
          or return Sidef::Types::Bool::Bool::FALSE;

        _valid(\$y);
        $y = $$y;

        if (ref($y) ne 'Math::GMPz') {
            __is_int__($y) || return Sidef::Types::Bool::Bool::FALSE;
            $y = _any2mpz($y) // return Sidef::Types::Bool::Bool::FALSE;
        }

        (Math::GMPz::Rmpz_cmp($x, $y) < 0 and Math::GMPz::Rmpz_divisible_p($y, $x))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_nontrivial_factor = \&is_ntf;

    sub is_coprime {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = $$x;
        $y = $$y;

        if (ref($x) ne 'Math::GMPz') {
            __is_int__($x) || return Sidef::Types::Bool::Bool::FALSE;
            $x = _any2mpz($x) // return Sidef::Types::Bool::Bool::FALSE;
        }

        if (ref($y) ne 'Math::GMPz') {
            __is_int__($y) || return Sidef::Types::Bool::Bool::FALSE;
            $y = _any2mpz($y) // return Sidef::Types::Bool::Bool::FALSE;
        }

        state $t = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_gcd($t, $x, $y);

        (Math::GMPz::Rmpz_cmp_ui($t, 1) == 0)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub gcd {
        my (@vals) = @_;
        _valid(\(@vals));

        @vals || return ZERO;    # By convention, gcd of an empty set is 0.
        @vals == 1 and return $vals[0];

        my $r = Math::GMPz::Rmpz_init();

        if (@vals > 2) {
            my @terms = map { _any2mpz($$_) // goto &nan } @vals;

            Math::GMPz::Rmpz_set($r, shift(@terms));

            foreach my $z (@terms) {
                Math::GMPz::Rmpz_gcd($r, $r, $z);
                last if (Math::GMPz::Rmpz_cmp_ui($r, 1) == 0);
            }

            return bless \$r;
        }

        my ($x, $y) = @vals;

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;

        Math::GMPz::Rmpz_gcd($r, $x, $y);
        bless \$r;
    }

    sub gcud {    # greatest common unitary divisor (OEIS: A165430)
        my (@vals) = @_;
        _valid(\(@vals));

        @vals || return ZERO;    # By convention, gcd of an empty set is 0.
        @vals == 1 and return $vals[0];

        my @terms = map { _any2mpz($$_) // goto &nan } @vals;
        my $g     = Math::GMPz::Rmpz_init_set($terms[0]);

        foreach my $i (1 .. $#terms) {
            Math::GMPz::Rmpz_gcd($g, $g, $terms[$i]);
            if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
                return bless \$g;
            }
        }

        state $t = Math::GMPz::Rmpz_init_nobless();

        foreach my $n (@terms) {
            next if (Math::GMPz::Rmpz_sgn($n) == 0);
            while (1) {
                Math::GMPz::Rmpz_divexact($t, $n, $g);
                Math::GMPz::Rmpz_gcd($t, $t, $g);
                last if (Math::GMPz::Rmpz_cmp_ui($t, 1) == 0);
                Math::GMPz::Rmpz_divexact($g, $g, $t);
            }
            last if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0);
        }

        bless \$g;
    }

    sub gcdext {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = _any2mpz($$n) // return (nan(), nan());
        $k = _any2mpz($$k) // return (nan(), nan());

        my $g = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $v = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_gcdext($g, $u, $v, $n, $k);

        ((bless \$u), (bless \$v), (bless \$g));
    }

    sub __lcm__ {
        my ($n, $k) = @_;
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_lcm($r, $n, $k);
        $r;
    }

    sub lcm {
        my (@vals) = @_;
        _valid(\(@vals));

        @vals or return ONE;    # By convention, lcm of an empty set is 1.
        @vals == 1 and return $vals[0];

        if (@vals > 2) {
            my @terms = map { _any2mpz($$_) // goto &nan } @vals;
            return bless \_binsplit(\@terms, \&__lcm__);
        }

        my ($x, $y) = @vals;

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_lcm($r, $x, $y);
        bless \$r;
    }

    sub consecutive_integer_lcm {
        _set_int(Math::Prime::Util::GMP::consecutive_integer_lcm(&_big2uistr // goto &nan));
    }

    *consecutive_lcm = \&consecutive_integer_lcm;

    sub num2perm {
        my ($n, $k) = @_;
        _valid(\$k);
        my @perm = map { _set_int($_) }
          Math::Prime::Util::GMP::numtoperm(_big2uistr($n) // (return undef), _big2uistr($k) // (return undef));
        Sidef::Types::Array::Array->new(\@perm);
    }

    sub valuation {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;

        Math::GMPz::Rmpz_sgn($y)          || return ZERO;
        Math::GMPz::Rmpz_cmpabs_ui($y, 1) || return ZERO;

        state $t = Math::GMPz::Rmpz_init_nobless();
        _set_int(scalar Math::GMPz::Rmpz_remove($t, $x, $y));
    }

    sub remove {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;

        Math::GMPz::Rmpz_sgn($y)          || return $_[0];
        Math::GMPz::Rmpz_cmpabs_ui($y, 1) || return $_[0];

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_remove($r, $x, $y);
        bless \$r;
    }

    *remdiv = \&remove;

    sub make_coprime {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = _any2mpz($$n) // goto &nan;
        $k = _any2mpz($$k) // goto &nan;

        if (Math::GMPz::Rmpz_sgn($n) == 0) {
            return bless \$n;
        }

        my $r = Math::GMPz::Rmpz_init_set($n);
        my $g = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_gcd($g, $r, $k);

        while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            Math::GMPz::Rmpz_remove($r, $r, $g);
            Math::GMPz::Rmpz_gcd($g, $r, $g);
        }

        bless \$r;
    }

    sub random_prime {
        my ($from, $to) = @_;

        my $prime;
        if (defined($to)) {
            _valid(\$to);
            $prime = Math::Prime::Util::GMP::random_prime(_big2uistr($from) // (goto &nan), _big2uistr($to) // (goto &nan));
        }
        else {
            $prime = Math::Prime::Util::GMP::random_prime(2, _big2uistr($from) // (goto &nan));
        }

        _set_int($prime // goto &nan);
    }

    sub random_safe_prime {
        my ($bits) = @_;
        my $prime  = Math::Prime::Util::GMP::random_safe_prime(_big2uistr($bits) // (goto &nan));
        _set_int($prime // goto &nan);
    }

    sub random_bytes {
        Sidef::Types::Array::Array->new(
                                        [map { _set_int(ord($_)) }
                                           split(//, Math::Prime::Util::GMP::random_bytes(&_big2uistr // (return undef)))
                                        ]
                                       );
    }

    sub random_string {
        Sidef::Types::String::String->new(Math::Prime::Util::GMP::random_bytes(&_big2uistr // (return undef)));
    }

    sub random_nbit_prime {
        my ($x) = @_;
        my $n = _any2ui($$x) // goto &nan;
        $n <= 1 && return _set_int(2);
        _set_int(Math::Prime::Util::GMP::random_nbit_prime($n));
    }

    sub random_nbit_strong_prime {
        my ($x) = @_;
        my $n = _any2ui($$x) // goto &nan;
        $n < 128 && goto &random_nbit_prime;
        _set_int(Math::Prime::Util::GMP::random_strong_prime($n));
    }

    *random_strong_nbit_prime = \&random_nbit_strong_prime;

    sub random_nbit_maurer_prime {
        my ($x) = @_;
        my $n = _any2ui($$x) // goto &nan;
        $n <= 1 && goto &nan;
        _set_int(Math::Prime::Util::GMP::random_maurer_prime($n));
    }

    *random_maurer_nbit_prime = \&random_nbit_maurer_prime;

    sub random_ndigit_prime {
        my ($x) = @_;
        my $n = _any2ui($$x) || goto &nan;
        _set_int(Math::Prime::Util::GMP::random_ndigit_prime($n));
    }

    sub is_semiprime {
        my ($x) = @_;

        __is_int__($$x) || return Sidef::Types::Bool::Bool::FALSE;
        $x = _any2mpz($$x) // return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_sgn($x) > 0
          or return Sidef::Types::Bool::Bool::FALSE;

        my $result;

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($x)) {
            $result = Math::Prime::Util::is_semiprime(Math::GMPz::Rmpz_get_ui($x));
        }
        else {
            $result = Math::Prime::Util::GMP::is_semiprime(Math::GMPz::Rmpz_get_str($x, 10));
        }

        $result
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub _semiprime_count {
        my ($n) = @_;

        state $pi2_table = {

            # Number of semiprimes <= 10^n
            # OEIS: https://oeis.org/A036352
            "10"                     => "4",
            "100"                    => "34",
            "1000"                   => "299",
            "10000"                  => "2625",
            "100000"                 => "23378",
            "1000000"                => "210035",
            "10000000"               => "1904324",
            "100000000"              => "17427258",
            "1000000000"             => "160788536",
            "10000000000"            => "1493776443",
            "100000000000"           => "13959990342",
            "1000000000000"          => "131126017178",
            "10000000000000"         => "1237088048653",
            "100000000000000"        => "11715902308080",
            "1000000000000000"       => "111329817298881",
            "10000000000000000"      => "1061057292827269",
            "100000000000000000"     => "10139482913717352",
            "1000000000000000000"    => "97123037685177087",
            "10000000000000000000"   => "932300026230174178",
            "100000000000000000000"  => "8966605849641219022",
            "1000000000000000000000" => "86389956293761485464",

            # Number of semiprimes <= 2^n
            # OEIS: https://oeis.org/A125527
            "4294967296"         => "658662065",
            "8589934592"         => "1289149627",
            "17179869184"        => "2524532330",
            "34359738368"        => "4946320619",
            "68719476736"        => "9696090315",
            "137438953472"       => "19015826478",
            "274877906944"       => "37310368709",
            "549755813888"       => "73237005168",
            "1099511627776"      => "143817246008",
            "2199023255552"      => "282528883551",
            "4398046511104"      => "555237939294",
            "8796093022208"      => "1091574618496",
            "17592186044416"     => "2146738817329",
            "35184372088832"     => "4223287872953",
            "70368744177664"     => "8311168557633",
            "140737488355328"    => "16360940729894",
            "281474976710656"    => "32216929163102",
            "562949953421312"    => "63457786440404",
            "1125899906842624"   => "125027663135664",
            "2251799813685248"   => "246401562625117",
            "4503599627370496"   => "485727708027940",
            "9007199254740992"   => "957746412122119",
            "18014398509481984"  => "1888916491053636",
            "36028797018963968"  => "3726284941841117",
            "72057594037927936"  => "7352535573376770",
            "144115188075855872" => "14510848832845041",
                           };

        if (defined(my $value = $pi2_table->{$n})) {
            return $value;
        }

        if (HAS_PRIME_UTIL) {
            return Math::Prime::Util::semiprime_count($n);
        }

        my $t = 0;
        my $s = Math::Prime::Util::GMP::sqrtint($n);

        my $count = 0;
        foreach my $p (Math::Prime::Util::GMP::sieve_primes(2, $s)) {
            $count += _prime_count(CORE::int($n / $p)) - ++$t + 1;
        }

        return $count;
    }

    sub semiprime_count {
        my ($from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $to->semiprime_count->sub($from->dec->semiprime_count);
        }

        my $n = _big2uistr($from) // return ZERO;
        _set_int(_semiprime_count($n));
    }

    sub nth_semiprime {
        my ($n) = @_;
        $n = _any2ui($$n) // goto &nan;

        return ONE         if ($n == 0);    # not semiprime, but...
        return _set_int(4) if ($n == 1);

        if (HAS_PRIME_UTIL) {
            my $k = Math::Prime::Util::nth_semiprime($n);
            return _set_int("$k");
        }

        # n-th semiprime is ~ n * log(n) / log(log(n))
        my $max = CORE::int($n * CORE::log($n) / CORE::log(CORE::log($n)));
        my $min = CORE::int(0.965 * $max);

        if ($n < 3e3) {
            $min = 4;
            $max = 11465;
        }

        require Memoize;
        Memoize::memoize('_prime_count');

        my $k     = 0;
        my $count = 0;

        while (1) {
            $k = (
                  HAS_NEW_PRIME_UTIL
                  ? Math::Prime::Util::divint(Math::Prime::Util::addint($min, $max), 2)
                  : Math::Prime::Util::GMP::divint(Math::Prime::Util::GMP::addint($min, $max), 2)
                 );

            goto &nan if ($k > ULONG_MAX or $k <= 0);

            $count = _semiprime_count($k);

            if (CORE::abs($count - $n) <= CORE::sqrt($k)) {
                last;
            }

            my $cmp = ($count <=> $n);

            if ($cmp > 0) {
                $max = $k - 1;
            }
            elsif ($cmp < 0) {
                $min = $k + 1;
            }
            else {
                last;
            }
        }

        Memoize::unmemoize('_prime_count');

        until (Math::Prime::Util::GMP::is_semiprime($k)) {
            --$k;
        }

        while ($count != $n) {
            my $cmp = ($n <=> $count);
            do {
                $k += $cmp;
              }
              until (
                     HAS_PRIME_UTIL
                     ? Math::Prime::Util::is_semiprime($k)
                     : Math::Prime::Util::GMP::is_semiprime($k)
                    );
            $count += $cmp;
        }

        _set_int($k);
    }

    *semiprime = \&nth_semiprime;

    sub next_semiprime {
        my ($n) = @_;

        $n = _any2mpz($$n) // goto &nan;

        Math::GMPz::Rmpz_sgn($n) < 0 and goto &nan;
        Math::GMPz::Rmpz_cmp_ui($n, 4) < 0 and return _set_int(4);

        # Optimization for native integers
        if (Math::GMPz::Rmpz_fits_slong_p($n)) {
            $n = Math::GMPz::Rmpz_get_ui($n) + 1;
            until (HAS_PRIME_UTIL ? Math::Prime::Util::is_semiprime($n) : Math::Prime::Util::GMP::is_semiprime($n)) {
                ++$n;
            }
            return _set_int($n);
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add_ui($r, $n, 1);

        until (Math::Prime::Util::GMP::is_semiprime(Math::GMPz::Rmpz_get_str($r, 10))) {
            Math::GMPz::Rmpz_add_ui($r, $r, 1);
        }

        bless \$r;
    }

    sub _primality_pretest {
        my ($n) = @_;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return;
            $n = _any2mpz($n) // return;
        }

        # Must be positive (first check -- don't change the order)
        (Math::GMPz::Rmpz_sgn($n) > 0) || return;

        # Check for divisibility by 2
        if (Math::GMPz::Rmpz_even_p($n)) {
            return (Math::GMPz::Rmpz_cmp_ui($n, 2) == 0);
        }

        # Return early if n is too small
        Math::GMPz::Rmpz_cmp_ui($n, 101) > 0 or return 1;

        # Check for very small factors
        if (ULONG_MAX >= 18446744073709551615) {
            Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $n, 16294579238595022365) == 1 or return 0;
            Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $n, 7145393598349078859) == 1  or return 0;
        }
        else {
            Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $n, 3234846615) == 1 or return 0;
        }

        # Native integer -- return early
        Math::GMPz::Rmpz_fits_ulong_p($n) && return 1;

        # Size of n in base-2
        my $size = Math::GMPz::Rmpz_sizeinbase($n, 2);

        # When n is large enough, try to find a small factor (up to 10^8)
        if ($size > 15_000) {

            state $g = Math::GMPz::Rmpz_init_nobless();

            my @checks = (1e4, 1e6);

            push(@checks, 1e7) if ($size > 20_000);
            push(@checks, 1e8) if ($size > 30_000);

            foreach my $k (@checks) {

                #~ say "Checking factors < $k";

                my $primorial = _cached_primorial($k);
                Math::GMPz::Rmpz_gcd($g, $primorial, $n);

                if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
                    ## say "Composite with a factor < $k";
                    return 0;
                }
            }
        }

        #~ say "No small factor...";
        return 1;
    }

    sub primality_pretest {
        my ($n) = @_;
        _primality_pretest($$n)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub all_prime {
        my (@vals) = @_;
        _valid(\(@vals));

        foreach my $n (@vals) {
            _primality_pretest($$n)
              || return Sidef::Types::Bool::Bool::FALSE;
        }

        my @strs;

        foreach my $n (@vals) {
            my $str = _big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE;
            Math::Prime::Util::GMP::is_euler_plumb_pseudoprime($str)
              || return Sidef::Types::Bool::Bool::FALSE;
            push @strs, $str;
        }

        foreach my $n (@strs) {
            _is_prob_prime($n)
              || return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub all_composite {
        my (@vals) = @_;
        _valid(\(@vals));

        foreach my $n (@vals) {
            (_primality_pretest($$n) // return Sidef::Types::Bool::Bool::FALSE) || next;
            _is_prob_prime(_big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE)
              && return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub is_prime {
        my ($n) = @_;

        $n = $$n;

        if (HAS_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                    Math::Prime::Util::is_prime(Math::GMPz::Rmpz_get_ui($n))
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        _primality_pretest($n)
          && Math::Prime::Util::GMP::is_prime(_big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_gaussian_prime {
        my ($x, $y) = @_;

        if (defined($y)) {
            _valid(\$y);
        }
        else {
            $y = ZERO;
        }

        $x = $$x;
        $y = $$y;

        if (ref($x) ne 'Math::GMPz') {
            __is_int__($x) || return Sidef::Types::Bool::Bool::FALSE;
            $x = _any2mpz($x) // return Sidef::Types::Bool::Bool::FALSE;
        }

        if (ref($y) ne 'Math::GMPz') {
            __is_int__($y) || return Sidef::Types::Bool::Bool::FALSE;
            $y = _any2mpz($y) // return Sidef::Types::Bool::Bool::FALSE;
        }

        Math::Prime::Util::GMP::is_gaussian_prime($x, $y)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_safe_prime {
        my ($n) = @_;

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        (Math::GMPz::Rmpz_odd_p($n) && _primality_pretest($n))
          || return Sidef::Types::Bool::Bool::FALSE;

        my $t = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub_ui($t, $n, 1);
        Math::GMPz::Rmpz_div_2exp($t, $t, 1);

        _primality_pretest($t)
          || return Sidef::Types::Bool::Bool::FALSE;

        (   Math::Prime::Util::GMP::is_strong_pseudoprime($t, 2)
         && Math::Prime::Util::GMP::is_strong_pseudoprime($n, 2)
         && Math::Prime::Util::GMP::is_extra_strong_lucas_pseudoprime($t))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_almost_prime {
        my ($n, $k) = @_;

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // return Sidef::Types::Bool::Bool::FALSE } : 2;

        if ($k == 0) {
            return $n->is_one;
        }
        elsif ($k == 1) {
            return $n->is_prime;
        }
        elsif ($k == 2) {
            return $n->is_semiprime;
        }

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        Math::GMPz::Rmpz_sgn($n) > 0
          or return Sidef::Types::Bool::Bool::FALSE;

        my $size = Math::GMPz::Rmpz_sizeinbase($n, 2);

        if ($k >= $size) {    # the smallest k-almost prime is 2^k
            return Sidef::Types::Bool::Bool::FALSE;
        }

        if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (          # XXX: available in MPU > 0.73
               Math::Prime::Util::is_almost_prime($k, Math::GMPz::Rmpz_get_ui($n))
               ? Sidef::Types::Bool::Bool::TRUE
               : Sidef::Types::Bool::Bool::FALSE
            );
        }

        my $bigomega  = 0;
        my $remainder = $n;

        if ($size > 100) {    # greater than 10^30
            foreach my $j (5 .. 9) {

                my ($r, @trial_factors) = _primorial_trial_factor($n, 10**$j);

                $bigomega  = scalar(@trial_factors);
                $remainder = $r;

                if (Math::GMPz::Rmpz_cmp_ui($r, 1) == 0) {
                    if ($bigomega == $k) {
                        return Sidef::Types::Bool::Bool::TRUE;
                    }
                    else {
                        return Sidef::Types::Bool::Bool::FALSE;
                    }
                }

                my $log = __ilog__($r, _next_prime(10**$j));

                $bigomega + $log + 1 >= $k
                  or return Sidef::Types::Bool::Bool::FALSE;

                my $r_is_prime = _is_prob_prime($r);

                if ($r_is_prime) {
                    if ($bigomega + 1 == $k) {
                        return Sidef::Types::Bool::Bool::TRUE;
                    }
                    else {
                        return Sidef::Types::Bool::Bool::FALSE;
                    }
                }

                if ($bigomega + ($r_is_prime ? 1 : 2) > $k) {
                    return Sidef::Types::Bool::Bool::FALSE;
                }

                my $r_size = Math::GMPz::Rmpz_sizeinbase($r, 2);

                last if (($j >= 5) && ($r_size <= 100));    # 30 digits
                last if (($j >= 6) && ($r_size <= 133));    # 40 digits
                last if (($j >= 7) && ($r_size <= 150));    # 45 digits
                last if (($j >= 8) && ($r_size <= 200));    # 60 digits

                # Try to find special factors
                if ($j >= 8) {

                    my @special_factors = @{(bless \$n)->special_factors};
                    my @gcd_factors     = @{
                        (bless \$n)->gcd_factors(
                                     Sidef::Types::Array::Array->new([@special_factors, (map { _set_int($_) } @trial_factors)])
                        )
                    };

                    if (scalar(@gcd_factors) > $k) {
                        return Sidef::Types::Bool::Bool::FALSE;
                    }

                    my @prime_factors;
                    my @composite_factors;

                    foreach my $f (@gcd_factors) {
                        if (_is_prob_prime($$f)) {
                            push @prime_factors, $f;
                        }
                        elsif (Math::GMPz::Rmpz_sizeinbase($$f, 2) <= 150) {
                            push @prime_factors, (map { _set_int($_) } _factor($$f));
                        }
                        else {
                            push @composite_factors, $f;
                        }
                    }

                    if (scalar(@prime_factors) + 2 * scalar(@composite_factors) > $k) {
                        return Sidef::Types::Bool::Bool::FALSE;
                    }

                    my $prod = Sidef::Types::Number::Number::prod(@prime_factors);
                    my $c    = (bless \$n)->idiv($prod);

                    $remainder = $$c;
                    $bigomega  = scalar(@prime_factors);

                    if (Math::GMPz::Rmpz_cmp_ui($remainder, 1) == 0) {
                        if ($bigomega == $k) {
                            return Sidef::Types::Bool::Bool::TRUE;
                        }
                        else {
                            return Sidef::Types::Bool::Bool::FALSE;
                        }
                    }

                    my $log = __ilog__($remainder, _next_prime(10**$j));

                    $bigomega + $log + 1 >= $k
                      or return Sidef::Types::Bool::Bool::FALSE;

                    if ($j == 8 and @composite_factors and Math::GMPz::Rmpz_sizeinbase(${$composite_factors[-1]}, 2) >= 200) {
                        next;
                    }

                    foreach my $f (@composite_factors) {
                        push @prime_factors, _factor($$f);
                    }

                    if (scalar(@prime_factors) == $k) {
                        return Sidef::Types::Bool::Bool::TRUE;
                    }
                    else {
                        return Sidef::Types::Bool::Bool::FALSE;
                    }
                }
            }
        }

        if ($bigomega > $k) {
            return Sidef::Types::Bool::Bool::FALSE;
        }

        my @factors = _factor($remainder);

        $bigomega += scalar(@factors);

        ($bigomega == $k)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_squarefree_almost_prime {
        my ($n, $k) = @_;

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // return Sidef::Types::Bool::Bool::FALSE } : 2;

        if ($k == 0) {
            return $n->is_one;
        }
        elsif ($k == 1) {
            return $n->is_prime;
        }
        elsif ($k == 2) {
            if ($n->is_square) {
                return Sidef::Types::Bool::Bool::FALSE;
            }
            return $n->is_semiprime;
        }

        my $n_obj = $n;
        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        Math::GMPz::Rmpz_sgn($n) > 0
          or return Sidef::Types::Bool::Bool::FALSE;

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            $n = Math::GMPz::Rmpz_get_ui($n);

            if (HAS_NEW_PRIME_UTIL) {
                if (Math::Prime::Util::is_almost_prime($k, $n) and Math::Prime::Util::is_square_free($n)) {
                    return Sidef::Types::Bool::Bool::TRUE;
                }
                return Sidef::Types::Bool::Bool::FALSE;
            }

            if (Math::Prime::Util::is_square_free($n) and scalar(Math::Prime::Util::factor($n)) == $k) {
                return Sidef::Types::Bool::Bool::TRUE;
            }
            return Sidef::Types::Bool::Bool::FALSE;
        }

        if (Math::GMPz::Rmpz_sizeinbase($n, 2) > 100) {
            $n_obj->is_prob_squarefree(_set_int(1e5)) || return Sidef::Types::Bool::Bool::FALSE;
        }

        if ($n_obj->is_almost_prime(_set_int($k)) and $n_obj->is_squarefree) {
            return Sidef::Types::Bool::Bool::TRUE;
        }

        return Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_omega_prime {
        my ($n, $k) = @_;

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // return Sidef::Types::Bool::Bool::FALSE } : 2;

        if ($k == 0) {
            return $n->is_one;
        }
        elsif ($k == 1) {
            return $n->is_prime_power;
        }

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        Math::GMPz::Rmpz_sgn($n) > 0
          or return Sidef::Types::Bool::Bool::FALSE;

        # The smallest k-omega prime is primorial(p_k)
        if (Math::GMPz::Rmpz_cmp($n, _cached_pn_primorial($k)) < 0) {
            return Sidef::Types::Bool::Bool::FALSE;
        }

        if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (    # XXX: available in MPU > 0.73
               Math::Prime::Util::is_omega_prime($k, Math::GMPz::Rmpz_get_ui($n))
               ? Sidef::Types::Bool::Bool::TRUE
               : Sidef::Types::Bool::Bool::FALSE
            );
        }

        my $omega     = 0;
        my $remainder = $n;
        my $size      = Math::GMPz::Rmpz_sizeinbase($n, 2);

        if ($size > 100) {    # greater than 10^30
            foreach my $j (5 .. 9) {

                my ($r, @trial_factors) = _primorial_trial_factor($n, 10**$j);

                $omega     = scalar(List::Util::uniq(@trial_factors));
                $remainder = $r;

                if (Math::GMPz::Rmpz_cmp_ui($r, 1) == 0) {
                    if ($omega == $k) {
                        return Sidef::Types::Bool::Bool::TRUE;
                    }
                    else {
                        return Sidef::Types::Bool::Bool::FALSE;
                    }
                }

                my $log = __ilog__($r, _next_prime(10**$j));

                $omega + $log + 1 >= $k
                  or return Sidef::Types::Bool::Bool::FALSE;

                my $r_is_prime_power = Math::Prime::Util::GMP::is_prime_power(Math::GMPz::Rmpz_get_str($r, 10));

                if ($r_is_prime_power) {
                    if ($omega + 1 == $k) {
                        return Sidef::Types::Bool::Bool::TRUE;
                    }
                    else {
                        return Sidef::Types::Bool::Bool::FALSE;
                    }
                }

                if ($omega + ($r_is_prime_power ? 1 : 2) > $k) {
                    return Sidef::Types::Bool::Bool::FALSE;
                }

                my $r_size = Math::GMPz::Rmpz_sizeinbase($r, 2);

                last if (($j >= 5) && ($r_size <= 100));    # 30 digits
                last if (($j >= 6) && ($r_size <= 133));    # 40 digits
                last if (($j >= 7) && ($r_size <= 150));    # 45 digits
                last if (($j >= 8) && ($r_size <= 200));    # 60 digits

                # Try to find special factors
                if ($j >= 8) {

                    my @special_factors = @{(bless \$n)->special_factors};
                    my @gcd_factors     = @{
                        (bless \$n)->gcd_factors(
                                     Sidef::Types::Array::Array->new([@special_factors, (map { _set_int($_) } @trial_factors)])
                        )
                    };

                    my @prime_factors;
                    my @composite_factors;

                    foreach my $f (@gcd_factors) {
                        if (_is_prob_prime($$f)) {
                            push @prime_factors, $f;
                        }
                        elsif (Math::GMPz::Rmpz_sizeinbase($$f, 2) <= 150) {
                            push @prime_factors, (map { _set_int($_) } _factor($$f));
                        }
                        else {
                            push @composite_factors, $f;
                        }
                    }

                    my $prod = Sidef::Types::Number::Number::prod(@prime_factors);
                    my $c    = (bless \$n)->idiv($prod);

                    $remainder = $$c;
                    $omega     = scalar(List::Util::uniq(map { Math::GMPz::Rmpz_get_str($$_, 10) } @prime_factors));

                    if (Math::GMPz::Rmpz_cmp_ui($remainder, 1) == 0) {
                        if ($omega == $k) {
                            return Sidef::Types::Bool::Bool::TRUE;
                        }
                        else {
                            return Sidef::Types::Bool::Bool::FALSE;
                        }
                    }

                    my $log = __ilog__($remainder, _next_prime(10**$j));

                    $omega + $log + 1 >= $k
                      or return Sidef::Types::Bool::Bool::FALSE;

                    if ($j == 8 and @composite_factors and Math::GMPz::Rmpz_sizeinbase(${$composite_factors[-1]}, 2) >= 200) {
                        next;
                    }

                    foreach my $f (@composite_factors) {
                        push @prime_factors, _factor($$f);
                    }

                    $omega = scalar(List::Util::uniq(map { ref($_) ? Math::GMPz::Rmpz_get_str($$_, 10) : $_ } @prime_factors));

                    if ($omega == $k) {
                        return Sidef::Types::Bool::Bool::TRUE;
                    }
                    else {
                        return Sidef::Types::Bool::Bool::FALSE;
                    }
                }
            }
        }

        if ($omega > $k) {
            return Sidef::Types::Bool::Bool::FALSE;
        }

        my @factors = _factor_exp($remainder);

        $omega += scalar(@factors);

        ($omega == $k)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_prob_prime {
        my ($n) = @_;

        $n = $$n;

        if (HAS_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                    Math::Prime::Util::is_prob_prime(Math::GMPz::Rmpz_get_ui($n))
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        _primality_pretest($n)
          && Math::Prime::Util::GMP::is_prob_prime(_big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_prov_prime {
        my ($n) = @_;

        $n = $$n;

        if (HAS_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                    Math::Prime::Util::is_prime(Math::GMPz::Rmpz_get_ui($n))
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        _primality_pretest($n)
          && Math::Prime::Util::GMP::is_provable_prime(_big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_provable_prime = \&is_prov_prime;

    sub is_bpsw_prime {
        my ($n) = @_;
        $n = $$n;
        _primality_pretest($n)
          && Math::Prime::Util::GMP::is_bpsw_prime(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_aks_prime {
        my ($n) = @_;
        $n = $$n;
        _primality_pretest($n)
          && Math::Prime::Util::GMP::is_aks_prime(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_composite {
        my ($n) = @_;

        (_primality_pretest($$n) // return Sidef::Types::Bool::Bool::FALSE)
          || return Sidef::Types::Bool::Bool::TRUE;

        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0 or return Sidef::Types::Bool::Bool::FALSE;

        _is_prob_prime(_big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::FALSE
          : Sidef::Types::Bool::Bool::TRUE;
    }

    sub is_odd_composite {
        my ($n) = @_;
        $n->is_odd && $n->is_composite;
    }

    sub miller_rabin_random {
        my ($n, $k) = @_;

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // 1 } : 1;

        __is_int__($$n)
          && Math::Prime::Util::GMP::miller_rabin_random(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE), $k)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_fermat_pseudoprime {
        my ($n, @bases) = @_;
        _valid(\(@bases));

        $n = $$n;

        if (HAS_NEW_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                Math::Prime::Util::is_pseudoprime(
                    Math::GMPz::Rmpz_get_ui($n),
                    do {
                        @bases = grep { defined($_) and $_ > 1 } map { _big2uistr($_) } @bases;
                        @bases ? (@bases) : (2);
                    }
                  )
                ? Sidef::Types::Bool::Bool::TRUE
                : Sidef::Types::Bool::Bool::FALSE
            );
        }

        __is_int__($n)
          && Math::Prime::Util::GMP::is_pseudoprime(
            _big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE),
            do {
                @bases = grep { defined($_) and $_ > 1 } map { _big2uistr($_) } @bases;
                @bases ? (@bases) : (2);
            }
          )
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_psp         = \&is_fermat_pseudoprime;
    *is_fermat_psp  = \&is_fermat_pseudoprime;
    *is_pseudoprime = \&is_fermat_pseudoprime;

    sub is_super_pseudoprime {
        my ($n, @bases) = @_;
        _valid(\(@bases));

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;

        my $z = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;
        $n = _big2uistr($z) // return Sidef::Types::Bool::Bool::FALSE;

        Math::Prime::Util::GMP::is_pseudoprime(
            $n,
            do {
                @bases = grep { defined($_) and $_ > 1 } map { _big2uistr($_) } @bases;
                @bases ? (@bases) : (2);
            }
        ) || return Sidef::Types::Bool::Bool::FALSE;

        @bases = (2) if !@bases;

        my $check_conditions = sub {

            # Using Thomas Ordowski's criterion from A050217.
#<<<
            my $gcd = Math::Prime::Util::GMP::gcd(
                map {
                    ($_ < ~0)
                        ? ($_ - 1)
                        : Math::Prime::Util::GMP::subint($_, 1)
                } @_
            );
#>>>

            foreach my $base (@bases) {
                Math::Prime::Util::GMP::powmod($base, $gcd, $n) eq '1'
                  or return;
            }

            return 1;
        };

        my @factors = map { ref($_) ? Math::GMPz::Rmpz_get_str($_, 10) : $_ } _miller_factor($z);

        if (scalar(@factors) > 1) {

            my @primes;
            my @composites;

            foreach my $f (@factors) {

                foreach my $base (@bases) {
                    Math::Prime::Util::GMP::powmod($base, $f, $n) eq $base
                      or return Sidef::Types::Bool::Bool::FALSE;
                }

                if (_is_prob_prime($f)) {
                    push @primes, $f;
                }
                else {
                    push @composites, $f;
                }
            }

            if (scalar(@primes) > 1) {
                $check_conditions->(@primes)
                  || return Sidef::Types::Bool::Bool::FALSE;
            }

            @composites
              || return Sidef::Types::Bool::Bool::TRUE;
        }

        @factors = map { _factor($_) } @factors;

        $check_conditions->(@factors)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_super_psp        = \&is_super_pseudoprime;
    *is_superpseudoprime = \&is_super_pseudoprime;

    # A141232 for b = 2;
    # A141350 for b = 3;
    # A140658 for b = 2,3;

    sub is_over_pseudoprime {
        my ($n, @bases) = @_;
        _valid(\(@bases));

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;

        my $z = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;
        $n = _big2uistr($z) // return Sidef::Types::Bool::Bool::FALSE;

        Math::Prime::Util::GMP::is_strong_pseudoprime(
            $n,
            do {
                @bases = grep { defined($_) and $_ > 1 } map { _big2uistr($_) } @bases;
                @bases ? (@bases) : (2);
            }
        ) || return Sidef::Types::Bool::Bool::FALSE;

        @bases = (2) if !@bases;

        my $check_conditions = sub {

#<<<
            my $gcd = Math::Prime::Util::GMP::gcd(
                map {
                    ($_ < ~0)
                        ? ($_ - 1)
                        : Math::Prime::Util::GMP::subint($_, 1)
                } @_
            );
#>>>

            foreach my $base (@bases) {
                Math::Prime::Util::GMP::powmod($base, $gcd, $n) eq '1'
                  or return;
            }

            my %znorder;

            foreach my $p (@_) {
                foreach my $base (@bases) {

                    if (exists $znorder{$base}) {
                        if (HAS_PRIME_UTIL and $p < ULONG_MAX and $base < ULONG_MAX) {
                            Math::Prime::Util::powmod($base, $znorder{$base}, $p) == 1 or return;
                        }
                        else {
                            Math::Prime::Util::GMP::powmod($base, $znorder{$base}, $p) eq '1' or return;
                        }
                    }

                    my $zn =
                      (HAS_PRIME_UTIL and $p < ULONG_MAX and $base < ULONG_MAX)
                      ? Math::Prime::Util::znorder($base, $p)
                      : Math::Prime::Util::GMP::znorder($base, $p);

                    if (exists $znorder{$base}) {
                        $znorder{$base} eq $zn or return;
                    }
                    else {
                        $znorder{$base} = $zn;
                    }
                }
            }

            return 1;
        };

        my @factors = map { ref($_) ? Math::GMPz::Rmpz_get_str($_, 10) : $_ } _miller_factor($z);

        if (scalar(@factors) > 1) {

            my @primes;
            my @composites;

            foreach my $f (@factors) {

                foreach my $base (@bases) {
                    Math::Prime::Util::GMP::powmod($base, $f, $n) eq $base
                      or return Sidef::Types::Bool::Bool::FALSE;
                }

                if (_is_prob_prime($f)) {
                    push @primes, $f;
                }
                else {
                    push @composites, $f;
                }
            }

            if (scalar(@primes) > 1) {
                $check_conditions->(@primes)
                  || return Sidef::Types::Bool::Bool::FALSE;
            }

            @composites
              || return Sidef::Types::Bool::Bool::TRUE;
        }

        @factors = map { _factor($_) } @factors;

        $check_conditions->(@factors)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_over_psp        = \&is_over_pseudoprime;
    *is_overpseudoprime = \&is_over_pseudoprime;

    sub is_euler_pseudoprime {
        my ($n, @bases) = @_;
        _valid(\(@bases));

        $n = $$n;

        if (HAS_NEW_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                Math::Prime::Util::is_euler_pseudoprime(
                    Math::GMPz::Rmpz_get_ui($n),
                    do {
                        @bases = grep { defined($_) and $_ > 1 } map { _big2uistr($_) } @bases;
                        @bases ? (@bases) : (2);
                    }
                  )
                ? Sidef::Types::Bool::Bool::TRUE
                : Sidef::Types::Bool::Bool::FALSE
            );
        }

        __is_int__($n)
          && Math::Prime::Util::GMP::is_euler_pseudoprime(
            _big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE),
            do {
                @bases = grep { defined($_) and $_ > 1 } map { _big2uistr($_) } @bases;
                @bases ? (@bases) : (2);
            }
          )
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_euler_psp = \&is_euler_pseudoprime;

    sub is_strong_fermat_pseudoprime {
        my ($n, @bases) = @_;
        _valid(\(@bases));

        $n = $$n;

        if (HAS_NEW_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                Math::Prime::Util::is_strong_pseudoprime(
                    Math::GMPz::Rmpz_get_ui($n),
                    do {
                        @bases = grep { defined($_) and $_ > 1 } map { _big2uistr($_) } @bases;
                        @bases ? (@bases) : (2);
                    }
                  )
                ? Sidef::Types::Bool::Bool::TRUE
                : Sidef::Types::Bool::Bool::FALSE
            );
        }

        __is_int__($n)
          && Math::Prime::Util::GMP::is_strong_pseudoprime(
            _big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE),
            do {
                @bases = grep { defined($_) and $_ > 1 } map { _big2uistr($_) } @bases;
                @bases ? (@bases) : (2);
            }
          )
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *miller_rabin          = \&is_strong_fermat_pseudoprime;
    *is_strong_psp         = \&is_strong_fermat_pseudoprime;
    *is_strong_fermat_psp  = \&is_strong_fermat_pseudoprime;
    *is_strong_pseudoprime = \&is_strong_fermat_pseudoprime;

    sub is_chebyshev_pseudoprime {    # OEIS: A175530
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_cmp_ui($n, 7056721) < 0 and return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_odd_p($n) or return Sidef::Types::Bool::Bool::FALSE;

        my $nstr = Math::GMPz::Rmpz_get_str($n, 10);

        # V_n(P,1) == P (mod n) for any integer P.
        foreach my $i (1 .. 10) {    # test with random values of P

            my $P = CORE::int(CORE::rand(1e6)) + 11;
            my ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($nstr, $P, 1, $nstr);

            if ($V ne $P) {
                return Sidef::Types::Bool::Bool::FALSE;
            }

            if ($i == 1 and _is_prob_prime($nstr)) {
                return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        # V_n(P,1) == P (mod n) for any integer P.
        foreach my $P (1, 3 .. 10) {    # test with small P
            my ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($nstr, $P, 1, $nstr);

            if ($V ne $P) {
                return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        # Odd composite integer n is a Chebyshev pseudoprime iff:
        #       n == {+1,-1} (mod p-1)
        #       n == {+1,-1} (mod p+1)
        # for each prime p|n.

        my @factors = _factor($nstr);

        state $t = Math::GMPz::Rmpz_init_nobless();
        state $u = Math::GMPz::Rmpz_init_nobless();
        state $v = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_sub_ui($t, $n, 1);
        Math::GMPz::Rmpz_add_ui($u, $n, 1);

        foreach my $p (@factors) {

            ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($v, $p)
              : Math::GMPz::Rmpz_set_str($v, $p, 10);

            Math::GMPz::Rmpz_sub_ui($v, $v, 1);
            Math::GMPz::Rmpz_divisible_p($t, $v)
              || Math::GMPz::Rmpz_divisible_p($u, $v)
              || return Sidef::Types::Bool::Bool::FALSE;

            Math::GMPz::Rmpz_add_ui($v, $v, 2);
            Math::GMPz::Rmpz_divisible_p($u, $v)
              || Math::GMPz::Rmpz_divisible_p($t, $v)
              || return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    *is_chebyshev     = \&is_chebyshev_pseudoprime;
    *is_chebyshev_psp = \&is_chebyshev_pseudoprime;

    sub is_lucasU_pseudoprime {    # true if U_n(P,Q) == 0 mod n
        my ($n, $P, $Q) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;

        $P = defined($P) ? do { _valid(\$P); _any2si($$P) // return Sidef::Types::Bool::Bool::FALSE } : +1;
        $Q = defined($Q) ? do { _valid(\$Q); _any2si($$Q) // return Sidef::Types::Bool::Bool::FALSE } : -1;

        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0
          or return Sidef::Types::Bool::Bool::FALSE;

        my $D = $P * $P - 4 * $Q;

        Math::Prime::Util::GMP::is_square($D)
          && return Sidef::Types::Bool::Bool::FALSE;

        my $k =
          ($D < 0)
          ? Math::GMPz::Rmpz_si_kronecker($D, $n)
          : Math::GMPz::Rmpz_ui_kronecker($D, $n);

        $k || return Sidef::Types::Bool::Bool::FALSE;

        my ($U, $V) = eval { Math::Prime::Util::GMP::lucas_sequence($n, $P, $Q, $n - $k) };

        defined($U) and ($U eq '0')
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_lucasu_psp            = \&is_lucasU_pseudoprime;
    *is_lucasU_psp            = \&is_lucasU_pseudoprime;
    *is_fib_psp               = \&is_lucasU_pseudoprime;
    *is_fibonacci_psp         = \&is_lucasU_pseudoprime;
    *is_fibonacci_pseudoprime = \&is_lucasU_pseudoprime;

    sub is_lucasV_pseudoprime {    # true if V_n(P,Q) == P mod n
        my ($n, $P, $Q) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;

        $P = defined($P) ? do { _valid(\$P); _any2si($$P) // return Sidef::Types::Bool::Bool::FALSE } : +1;
        $Q = defined($Q) ? do { _valid(\$Q); _any2si($$Q) // return Sidef::Types::Bool::Bool::FALSE } : -1;

        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0
          or return Sidef::Types::Bool::Bool::FALSE;

        my ($U, $V) = eval { Math::Prime::Util::GMP::lucas_sequence($n, $P, $Q, $n) };

        (defined($V) and $V eq join('', $P % $n))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_lucasv_psp                 = \&is_lucasV_pseudoprime;
    *is_lucasV_psp                 = \&is_lucasV_pseudoprime;
    *is_bruckman_lucas_psp         = \&is_lucasV_pseudoprime;
    *is_bruckman_lucas_pseudoprime = \&is_lucasV_pseudoprime;

    sub is_pell_lucas_pseudoprime {    # OEIS: A270342 (primes + composites), A270345 (composites)
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_cmp_ui($n, 2) > 0
          or return Sidef::Types::Bool::Bool::FALSE;

        my ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($n, 2, -1, $n);
        $V eq '2' ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_pell_lucas_psp = \&is_pell_lucas_pseudoprime;

    sub is_pell_pseudoprime {    # OEIS: A099011 (odd composites)
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_cmp_ui($n, 2) > 0 or return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_even_p($n) and return Sidef::Types::Bool::Bool::FALSE;

        my ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($n, 2, -1, $n);

        if (Math::GMPz::Rmpz_ui_kronecker(2, $n) == 1) {
            return ($U eq '1' ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE);
        }

        state $t = Math::GMPz::Rmpz_init_nobless();

        ($U < ULONG_MAX)
          ? Math::GMPz::Rmpz_set_ui($t, $U)
          : Math::GMPz::Rmpz_set_str($t, $U, 10);

        Math::GMPz::Rmpz_add_ui($t, $t, 1);
        Math::GMPz::Rmpz_cmp($t, $n) ? Sidef::Types::Bool::Bool::FALSE : Sidef::Types::Bool::Bool::TRUE;
    }

    *is_pell_psp = \&is_pell_pseudoprime;

    sub is_strong_fibonacci_pseudoprime {
        my ($n) = @_;

       # A strong Fibonacci pseudoprime is a composite number n which satisfies the following congruence with Q = -1 and all P:
       #   V_n(P,Q) = P (mod n)

        # The first several strong Fibonacci pseudoprimes, are:
        #   443372888629441, 39671149333495681, 842526563598720001,
        #   2380296518909971201, 3188618003602886401, 33711266676317630401

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        state $min = Math::GMPz::Rmpz_init_set_str_nobless("443372888629441", 10);

        Math::GMPz::Rmpz_cmp($n, $min) < 0 and return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_odd_p($n) or return Sidef::Types::Bool::Bool::FALSE;

        my $nstr = Math::GMPz::Rmpz_get_str($n, 10);

        # Check if n is a Fermat pseudoprime to base-2.
        Math::Prime::Util::GMP::is_pseudoprime($nstr, 2)
          || return Sidef::Types::Bool::Bool::FALSE;

        # V_n(P,-1) == P (mod n) for any integer P.
        foreach my $i (1 .. 10) {    # test with random values of P

            my $P = CORE::int(CORE::rand(1e6)) + 11;
            my ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($nstr, $P, -1, $nstr);

            if ($V ne $P) {
                return Sidef::Types::Bool::Bool::FALSE;
            }

            if ($i == 1 and _is_prob_prime($nstr)) {
                return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        # V_n(P,-1) == P (mod n) for any integer P.
        foreach my $P (1, 3 .. 10) {    # test with small P
            my ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($nstr, $P, -1, $nstr);

            if ($V ne $P) {
                return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        # Odd composite integer n is a strong Fibonacci pseudoprime iff:
        #     1) n is a Carmichael number: p-1 | n-1
        #     2) 2(p + 1) | (n − 1) or 2(p + 1) | (n − p)
        # for each prime p|n.

        my @factors = _factor($nstr);

        state $nm1 = Math::GMPz::Rmpz_init_nobless();
        state $u   = Math::GMPz::Rmpz_init_nobless();
        state $v   = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_sub_ui($nm1, $n, 1);

        my %seen;

        foreach my $p (@factors) {

            if ($seen{$p}++) {    # not squarefree
                return Sidef::Types::Bool::Bool::FALSE;
            }

            ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($v, $p)
              : Math::GMPz::Rmpz_set_str($v, $p, 10);

            # Check Korselt's criterion for Carmichael numbers:
            #   p-1 | n-1, for each p|n.

            Math::GMPz::Rmpz_sub_ui($u, $v, 1);
            Math::GMPz::Rmpz_divisible_p($nm1, $u) || return Sidef::Types::Bool::Bool::FALSE;

            # Check if any of the following condition is satisifed:
            #    2(p + 1) | (n − 1)
            #    2(p + 1) | (n − p)

            Math::GMPz::Rmpz_sub($u, $n, $v);
            Math::GMPz::Rmpz_add_ui($v, $v, 1);
            Math::GMPz::Rmpz_mul_2exp($v, $v, 1);

            Math::GMPz::Rmpz_divisible_p($nm1, $v)
              || Math::GMPz::Rmpz_divisible_p($u, $v)
              || return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    *is_strong_fib           = \&is_strong_fibonacci_pseudoprime;
    *is_strong_fibonacci     = \&is_strong_fibonacci_pseudoprime;
    *is_strong_fib_psp       = \&is_strong_fibonacci_pseudoprime;
    *is_strong_fibonacci_psp = \&is_strong_fibonacci_pseudoprime;

    sub is_lucas_pseudoprime {
        my ($n, $P, $Q) = @_;

        if (defined($P) or defined($Q)) {
            return $n->is_lucasU_pseudoprime($P, $Q);
        }

        $n = $$n;

        if (HAS_NEW_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                    Math::Prime::Util::is_lucas_pseudoprime(Math::GMPz::Rmpz_get_ui($n))
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        __is_int__($n)
          && Math::Prime::Util::GMP::is_lucas_pseudoprime(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_lucas_psp = \&is_lucas_pseudoprime;

    sub is_strong_lucas_pseudoprime {
        my ($n) = @_;

        $n = $$n;

        if (HAS_NEW_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                    Math::Prime::Util::is_strong_lucas_pseudoprime(Math::GMPz::Rmpz_get_ui($n))
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        __is_int__($n)
          && Math::Prime::Util::GMP::is_strong_lucas_pseudoprime(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_strong_lucas_psp = \&is_strong_lucas_pseudoprime;

    sub is_stronger_lucas_pseudoprime {
        my ($n) = @_;

        $n = $$n;

        if (HAS_NEW_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                    Math::Prime::Util::is_extra_strong_lucas_pseudoprime(Math::GMPz::Rmpz_get_ui($n))
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        __is_int__($n)
          && Math::Prime::Util::GMP::is_extra_strong_lucas_pseudoprime(_big2uistr($n)
                                                                       // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_stronger_lucas_psp             = \&is_stronger_lucas_pseudoprime;
    *is_extra_strong_lucas_psp         = \&is_stronger_lucas_pseudoprime;
    *is_extra_strong_lucas_pseudoprime = \&is_stronger_lucas_pseudoprime;

    sub is_strongish_lucas_pseudoprime {
        my ($n) = @_;

        $n = $$n;

        if (HAS_NEW_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                    Math::Prime::Util::is_almost_extra_strong_lucas_pseudoprime(Math::GMPz::Rmpz_get_ui($n))
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        __is_int__($n)
          && Math::Prime::Util::GMP::is_almost_extra_strong_lucas_pseudoprime(_big2uistr($n)
                                                                              // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_strongish_lucas_psp = \&is_strongish_lucas_pseudoprime;

    sub is_plumb_pseudoprime {
        my ($n) = @_;
        $n = $$n;
        __is_int__($n)
          && Math::Prime::Util::GMP::is_euler_plumb_pseudoprime(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_plumb_psp               = \&is_plumb_pseudoprime;
    *is_euler_plumb_psp         = \&is_plumb_pseudoprime;
    *is_euler_plumb_pseudoprime = \&is_plumb_pseudoprime;

    sub is_perrin_pseudoprime {
        my ($n) = @_;
        $n = $$n;
        __is_int__($n)
          && Math::Prime::Util::GMP::is_perrin_pseudoprime(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_perrin_psp = \&is_perrin_pseudoprime;

    sub is_frobenius_pseudoprime {
        my ($n, $k, $m) = @_;

        _valid(\$k, \$m) if defined($k);

        $n = $$n;

        __is_int__($n)
          && Math::Prime::Util::GMP::is_frobenius_pseudoprime(
                                                              _big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE),
                                                              (defined($k) ? _big2istr($k) // () : ()),
                                                              (defined($m) ? _big2istr($m) // () : ()),
                                                             )
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_frobenius_psp = \&is_frobenius_pseudoprime;

    sub is_frobenius_underwood_pseudoprime {
        my ($n) = @_;

        $n = $$n;

        __is_int__($n)
          && Math::Prime::Util::GMP::is_frobenius_underwood_pseudoprime(_big2uistr($n)
                                                                        // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_underwood_psp           = \&is_frobenius_underwood_pseudoprime;
    *is_underwood_pseudoprime   = \&is_frobenius_underwood_pseudoprime;
    *is_frobenius_underwood_psp = \&is_frobenius_underwood_pseudoprime;

    sub is_frobenius_khashin_pseudoprime {
        my ($n) = @_;
        $n = $$n;
        __is_int__($n)
          && Math::Prime::Util::GMP::is_frobenius_khashin_pseudoprime(_big2uistr($n)
                                                                      // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_khashin_psp           = \&is_frobenius_khashin_pseudoprime;
    *is_khashin_pseudoprime   = \&is_frobenius_khashin_pseudoprime;
    *is_frobenius_khashin_psp = \&is_frobenius_khashin_pseudoprime;

    sub is_nminus1_prime {
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE;

        _is_prob_prime($n)
          && Math::Prime::Util::GMP::is_nminus1_prime($n)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_nm1_prime = \&is_nminus1_prime;
    *is_pm1_prime = \&is_nminus1_prime;

    sub is_nplus1_prime {
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE;

        _is_prob_prime($n)
          && Math::Prime::Util::GMP::is_nplus1_prime($n)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_np1_prime = \&is_nplus1_prime;
    *is_pp1_prime = \&is_nplus1_prime;

    sub is_ecpp_prime {
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE;

        _is_prob_prime($n)
          && Math::Prime::Util::GMP::is_ecpp_prime($n)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_mersenne_prime {
        my ($n) = @_;

        $n = $$n;

        if (HAS_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                    Math::Prime::Util::is_mersenne_prime(Math::GMPz::Rmpz_get_ui($n))
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        __is_int__($n)
          && Math::Prime::Util::GMP::is_mersenne_prime(_big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub primes_each {
        my ($from, $to, $block) = @_;

        if (defined($block)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return undef;
            $to   = _any2mpz($$to)   // return undef;
        }
        else {
            $block = $to;
            $to    = _any2mpz($$from) // return undef;
            $from  = $TWO;
        }

        if (Math::GMPz::Rmpz_cmp_ui($from, 1) <= 0) {
            $from = $TWO;
        }

#<<<
        _generic_each(
            $from, $to, $block,
            sub {
                my ($from) = @_;

                my $t    = Math::GMPz::Rmpz_get_d($from);
                my $step = _nth_prime_lower($t + CORE::log($t) * 2e3) - _nth_prime_lower($t);

                if ($step <= 0 or $step > 1e6) {
                    $step = 1e6;
                }

                $step;
            },
            sub { [Math::Prime::Util::GMP::sieve_primes($_[0], $_[1])] }
        );
#>>>
    }

    *each_prime = \&primes_each;

    sub composites_each {
        my ($from, $to, $block) = @_;

        if (defined($block)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return undef;
            $to   = _any2mpz($$to)   // return undef;
        }
        else {
            $block = $to;
            $to    = _any2mpz($$from) // return undef;
            $from  = $TWO + $TWO;
        }

        if (Math::GMPz::Rmpz_cmp_ui($from, 3) <= 0) {
            $from = $TWO + $TWO;
        }

        _generic_each(
            $from, $to, $block,
            sub {
                1e5;
            },
            sub {
                my ($from, $to) = @_;

                if (ref($to) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_slong_p($to)) {
                    $to   = Math::GMPz::Rmpz_get_ui($to);
                    $from = Math::GMPz::Rmpz_get_ui($from) if (ref($from) eq 'Math::GMPz');
                }

                my @list;

                if (HAS_PRIME_UTIL and ref($to) eq '') {
                    Math::Prime::Util::forcomposites(sub { push @list, $_ }, $from, $to);
                    return \@list;
                }

                for (my $k = $from ; $k <= $to ; ++$k) {
                    if (!_is_prob_prime($k)) {
                        push @list, $k;
                    }
                }

                \@list;
            }
        );
    }

    *each_composite = \&composites_each;

    sub primes {
        my ($x, $y) = @_;

        _valid(\$y) if defined($y);

        Sidef::Types::Array::Array->new(
                                       [map { _set_int($_) }
                                          defined($y)
                                        ? Math::Prime::Util::GMP::sieve_primes((_big2uistr($x) // 0), (_big2uistr($y) // 0), 0)
                                        : Math::Prime::Util::GMP::sieve_primes(2, (_big2uistr($x) // 0), 0)
                                       ]
        );
    }

    sub composites {
        my ($from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $to   = _any2mpz($$to)   // return Sidef::Types::Array::Array->new;
        }
        else {
            $to   = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $from = 4;
        }

        if (ref($from) and Math::GMPz::Rmpz_cmp_ui($from, 3) <= 0) {
            $from = 4;
        }

        if (ref($to) and Math::GMPz::Rmpz_sgn($to) < 0) {
            $to = 0;
        }

        if ($from > $to) {
            return Sidef::Types::Array::Array->new;
        }

        if (ref($to) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_slong_p($to)) {
            $to   = Math::GMPz::Rmpz_get_ui($to);
            $from = Math::GMPz::Rmpz_get_ui($from) if (ref($from) eq 'Math::GMPz');
        }

        my @list;

        if (HAS_PRIME_UTIL and ref($to) eq '') {
            Math::Prime::Util::forcomposites(
                sub {
                    push @list, $_;
                },
                $from,
                $to
            );
        }
        else {
            for (my $k = $from ; $k <= $to ; ++$k) {
                if (!_is_prob_prime($k)) {
                    push @list, $k;
                }
            }
        }

        @list = map { ref($_) ? (bless \$_) : (bless \Math::GMPz::Rmpz_init_set_ui($_)) } @list;
        Sidef::Types::Array::Array->new(\@list);
    }

    sub smooth_numbers {
        my ($n, $primes, $block) = @_;

        my @primes = @$primes;
        @primes || return Sidef::Types::Array::Array->new();

        _valid(\(@primes));
        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new();

        Math::GMPz::Rmpz_sgn($n) > 0
          or return Sidef::Types::Array::Array->new();

        @primes = map { Math::GMPz::Rmpz_fits_ulong_p($_) ? Math::GMPz::Rmpz_get_ui($_) : $_ } map { _any2mpz($$_) } @primes;

        # Optimization when n is a native integer
        if (Math::GMPz::Rmpz_fits_ulong_p($n) and Math::GMPz::Rmpz_get_ui($n) < ULONG_MAX) {

            $n = Math::GMPz::Rmpz_get_ui($n);

            my @h = (1);
            foreach my $p (@primes) {
                my $p_obj = _set_int($p);
                foreach my $k (@h) {
                    my $t = $k * $p;
                    if (($t <= $n and $t < ULONG_MAX) and (defined($block) ? $block->(_set_int($t), $p_obj) : 1)) {
                        push @h, $t;
                    }
                }
            }

            @h = sort { $a <=> $b } @h;
            @h = map  { bless \Math::GMPz::Rmpz_init_set_ui($_) } @h;
            return Sidef::Types::Array::Array->new(\@h);
        }

        my @h = (1);

        foreach my $p (@primes) {
            my $p_obj = _set_int($p);

            foreach my $k (@h) {
                my $t = $p * $k;

                if (!ref($t) and !($t < ULONG_MAX)) {
                    $t = Math::GMPz::Rmpz_init_set_ui($k);

                    ref($p)
                      ? Math::GMPz::Rmpz_mul($t, $t, $p)
                      : Math::GMPz::Rmpz_mul_ui($t, $t, $p);
                }

                if (    (ref($t) ? (Math::GMPz::Rmpz_cmp($t, $n) <= 0) : (Math::GMPz::Rmpz_cmp_ui($n, $t) >= 0))
                    and (defined($block) ? $block->(_set_int($t), $p_obj) : 1)) {
                    push @h, $t;
                }
            }
        }

        @h = sort { $a <=> $b } @h;
        @h = map  { ref($_) ? $_ : Math::GMPz::Rmpz_init_set_ui($_) } @h;
        @h = map  { bless \$_ } @h;

        return Sidef::Types::Array::Array->new(\@h);
    }

    sub n_primes {
        my ($n, $start) = @_;

        $start = defined($start) ? do { _valid(\$start); _big2uistr($start) // 0 } : 2;
        $n     = _any2ui($$n) // return Sidef::Types::Array::Array->new;

        my @primes;

        if (HAS_PRIME_UTIL and $start < (ULONG_MAX >> 1)) {
            for (my $it = Math::Prime::Util::prime_iterator($start) ; $n > 0 ; --$n) {
                push @primes, _set_int($it->());
            }
            return Sidef::Types::Array::Array->new(\@primes);
        }

        if (_is_prob_prime($start)) {
            ## ok
        }
        else {
            $start = _next_prime($start);
        }

        for (my $p = $start ; $n > 0 ; --$n, ($p = _next_prime($p))) {
            push @primes, _set_int($p);
        }

        Sidef::Types::Array::Array->new(\@primes);
    }

    *nprimes     = \&n_primes;
    *next_primes = \&n_primes;

    sub n_composites {
        my ($n, $start) = @_;

        $n = _any2ui($$n) // return Sidef::Types::Array::Array->new;

        if (defined($start)) {
            _valid(\$start);
            $start = $start->dec->next_composite;
        }
        else {
            $start = _set_int(4);
        }

        my @composites;

        for (my $c = $start ; $n > 0 ; --$n, ($c = $c->next_composite)) {
            push @composites, $c;
        }

        Sidef::Types::Array::Array->new(\@composites);
    }

    *ncomposites     = \&n_composites;
    *next_composites = \&n_composites;

    sub pn_primes {
        my ($x, $y) = @_;

        if (defined($y)) {
            _valid(\$y);
            return $x->nth_prime->primes($y->nth_prime);
        }

        $x->nth_prime->primes;
    }

    sub sum_primes {
        my ($from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            $from = _big2istr($from) // return ZERO;
            $from = 2 if $from < 2;
            $to   = _big2uistr($to) // return ZERO;
        }
        else {
            $to   = _big2uistr($from) // return ZERO;
            $from = 2;
        }

        if (HAS_PRIME_UTIL) {
            my $r = Math::Prime::Util::sum_primes($from, $to);
            return _set_int("$r");
        }

        _set_int(Math::Prime::Util::GMP::vecsum(Math::Prime::Util::GMP::sieve_primes($from, $to)));
    }

    *prime_sum  = \&sum_primes;
    *primes_sum = \&sum_primes;

    sub prev_prime {
        my ($n) = @_;

        if (HAS_PRIME_UTIL and ref($$n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($$n)) {
            return _set_int(Math::Prime::Util::prev_prime(Math::GMPz::Rmpz_get_ui($$n)) || goto &nan);
        }

        _set_int(Math::Prime::Util::GMP::prev_prime(&_big2uistr // goto &nan) || goto &nan);
    }

    sub next_prime {
        my ($n) = @_;

        if (HAS_PRIME_UTIL and ref($$n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($$n)) {
            return _set_int(Math::Prime::Util::next_prime(Math::GMPz::Rmpz_get_ui($$n)) || goto &nan);
        }

        _set_int(Math::Prime::Util::GMP::next_prime(&_big2uistr // goto &nan) || goto &nan);
    }

    sub next_twin_prime {
        _set_int(Math::Prime::Util::GMP::next_twin_prime(&_big2uistr // goto &nan) || goto &nan);
    }

    sub next_composite {
        my ($n) = @_;

        $n = _any2mpz($$n) // goto &nan;

        Math::GMPz::Rmpz_sgn($n) < 0 and goto &nan;
        Math::GMPz::Rmpz_cmp_ui($n, 3) <= 0 and return _set_int(4);

        # Optimization for native integers
        if (Math::GMPz::Rmpz_fits_slong_p($n)) {
            $n = Math::GMPz::Rmpz_get_ui($n) + 1;
            return _set_int($n) if (($n & 1) == 0);
            ++$n                if _is_prob_prime($n);
            return _set_int($n);
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add_ui($r, $n, 1);

        if (Math::GMPz::Rmpz_even_p($r)) {
            return bless \$r;
        }

        if (_is_prob_prime($r)) {
            Math::GMPz::Rmpz_add_ui($r, $r, 1);
        }

        bless \$r;
    }

    sub next_prime_power {
        my ($n) = @_;

        $n = _any2mpz($$n) // goto &nan;

        Math::GMPz::Rmpz_sgn($n) < 0 and goto &nan;
        Math::GMPz::Rmpz_cmp_ui($n, 2) < 0 and return _set_int(2);

        # Optimization for native integers
        if (Math::GMPz::Rmpz_fits_slong_p($n)) {
            $n = Math::GMPz::Rmpz_get_ui($n) + 1;
            until (HAS_PRIME_UTIL ? Math::Prime::Util::is_prime_power($n) : Math::Prime::Util::GMP::is_prime_power($n)) {
                ++$n;
            }
            return _set_int($n);
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add_ui($r, $n, 1);

        until (Math::Prime::Util::GMP::is_prime_power(Math::GMPz::Rmpz_get_str($r, 10))) {
            Math::GMPz::Rmpz_add_ui($r, $r, 1);
        }

        bless \$r;
    }

    sub next_squarefree {
        my ($n) = @_;

        $n = _any2mpz($$n) // goto &nan;

        my $sgn = Math::GMPz::Rmpz_sgn($n);
        $sgn < 0  and goto &nan;
        $sgn == 0 and return ONE;

        # Optimization for native integers
        if (Math::GMPz::Rmpz_fits_slong_p($n)) {
            $n = Math::GMPz::Rmpz_get_ui($n) + 1;
            until (_is_squarefree($n)) {
                ++$n;
            }
            return _set_int($n);
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add_ui($r, $n, 1);

        my $r_obj = bless \$r;

        until ($r_obj->is_squarefree) {
            Math::GMPz::Rmpz_add_ui($r, $r, 1);
        }

        $r_obj;
    }

    sub next_powerfree {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
            $k >= 2 or goto &nan;
        }
        else {
            $k = 2;
        }

        if ($k == 2) {
            return $n->next_squarefree;
        }

        $n = _any2mpz($$n) // goto &nan;

        my $sgn = Math::GMPz::Rmpz_sgn($n);
        $sgn < 0  and goto &nan;
        $sgn == 0 and return ONE;

        # Optimization for native integers
        if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_slong_p($n)) {
            $n = Math::GMPz::Rmpz_get_ui($n) + 1;
            until (Math::Prime::Util::is_powerfree($n, $k)) {
                ++$n;
            }
            return _set_int($n);
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add_ui($r, $n, 1);

        my $k_obj = _set_int($k);
        my $r_obj = bless(\$r);

        until ($r_obj->is_powerfree($k_obj)) {
            Math::GMPz::Rmpz_add_ui($r, $r, 1);
        }

        $r_obj;
    }

    sub znorder {
        my ($x, $y) = @_;
        _valid(\$y);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;

        my $r;

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($x) and Math::GMPz::Rmpz_fits_ulong_p($y)) {
            $r = Math::Prime::Util::znorder(Math::GMPz::Rmpz_get_ui($x), Math::GMPz::Rmpz_get_ui($y)) // goto &nan;
        }
        else {
            $r = Math::Prime::Util::GMP::znorder(Math::GMPz::Rmpz_get_str($x, 10), Math::GMPz::Rmpz_get_str($y, 10))
              // goto &nan;
        }

        _set_int($r);
    }

    sub znprimroot {
        my $z = Math::Prime::Util::GMP::znprimroot(&_big2uistr // (goto &nan)) // goto &nan;
        _set_int($z);
    }

    sub rad {    # A007947
        my $n = &_big2uistr // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $r = Math::Prime::Util::GMP::vecprod(map { $_->[0] } @factor_exp);
        _set_int($r);
    }

    sub powerfree_part {
        my ($k, $n) = @_;

        # Multiplicative with:
        #   a(p^e, k) = p^(e mod k)

        _valid(\$n);

        $k = _any2ui($$k)   // goto &nan;
        $n = _big2uistr($n) // goto &nan;

        $k <= 0 and goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $r =
          Math::Prime::Util::GMP::vecprod(map { ($_->[1] == 1) ? $_->[0] : Math::Prime::Util::GMP::powint($_->[0], $_->[1]) }
                                          grep { $_->[1] } map { [$_->[0], $_->[1] % $k] } @factor_exp);
        _set_int($r);
    }

    sub core {    # A007913
        (TWO)->powerfree_part($_[0]);
    }

    *squarefree_part = \&core;

    sub powerfree_part_sum {
        my ($k, $from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $k->powerfree_part_sum($to)->sub($k->powerfree_part_sum($from->dec));
        }

        _valid(\$from);

        my $n = _any2mpz($$from) // return ZERO;
        $k = _any2ui($$k) // return ZERO;

        Math::GMPz::Rmpz_sgn($n) > 0
          or return ZERO;

        return ZERO        if ($k == 0);
        return (bless \$n) if ($k == 1);

        state $t = Math::GMPz::Rmpz_init_nobless();
        state $u = Math::GMPz::Rmpz_init_nobless();
        state $w = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_root($t, $n, $k);
        Math::GMPz::Rmpz_fits_ulong_p($t) || goto &nan;    # too large

        my $s   = Math::GMPz::Rmpz_get_ui($t);
        my $sum = Math::GMPz::Rmpz_init_set_ui(0);

        if (HAS_NEW_PRIME_UTIL) {
            Math::Prime::Util::forfactored(
                sub {

                    # u = faulhaber(floor(n/v^k), 1)
                    Math::GMPz::Rmpz_ui_pow_ui($w, $_, $k);
                    Math::GMPz::Rmpz_div($t, $n, $w);
                    Math::GMPz::Rmpz_mul($u, $t, $t);
                    Math::GMPz::Rmpz_add($u, $u, $t);
                    Math::GMPz::Rmpz_div_2exp($u, $u, 1);

                    Math::GMPz::Rmpz_set_ui($w, 1);

                    my $prev = 1;
                    foreach my $p (@_) {
                        next if ($p == $prev);
                        Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k);
                        Math::GMPz::Rmpz_ui_sub($t, 1, $t);
                        Math::GMPz::Rmpz_mul($w, $w, $t);
                        $prev = $p;
                    }

                    Math::GMPz::Rmpz_mul($u, $u, $w);
                    Math::GMPz::Rmpz_add($sum, $sum, $u);
                },
                $s
            );
        }
        else {
            my $m;
            for (my $v = 1 ; $v <= $s ; ++$v) {

                # u = faulhaber(floor(n/v^k), 1)
                Math::GMPz::Rmpz_ui_pow_ui($w, $v, $k);
                Math::GMPz::Rmpz_div($t, $n, $w);
                Math::GMPz::Rmpz_mul($u, $t, $t);
                Math::GMPz::Rmpz_add($u, $u, $t);
                Math::GMPz::Rmpz_div_2exp($u, $u, 1);

                Math::GMPz::Rmpz_set_ui($w, 1);

                my $prev = 1;
                foreach my $p (_factor($v)) {
                    next if ($p == $prev);
                    Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k);
                    Math::GMPz::Rmpz_ui_sub($t, 1, $t);
                    Math::GMPz::Rmpz_mul($w, $w, $t);
                    $prev = $p;
                }

                Math::GMPz::Rmpz_mul($u, $u, $w);
                Math::GMPz::Rmpz_add($sum, $sum, $u);
            }
        }

        return bless \$sum;
    }

    sub arithmetic_derivative {
        my ($x) = @_;

        my $deriv = sub {
            my ($n) = @_;

            # (-a)' = -(a')
            if (Math::GMPz::Rmpz_sgn($n) < 0) {
                my $t = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_neg($t, $n);
                $t = __SUB__->($t);
                Math::GMPz::Rmpz_neg($t, $t);
                return $t;
            }

            my $u = Math::GMPz::Rmpz_init();
            my $d = Math::GMPz::Rmpz_init_set_ui(0);
            my $s = Math::GMPz::Rmpz_get_str($n, 10);

            return $d if ($s eq '0' or $s eq '1');

            foreach my $pk (_factor_exp($s)) {
                my ($p, $k) = @$pk;

                # a(n) = Sum_{p^k|n} (n*k)/p

                if ($p < ULONG_MAX) {
                    Math::GMPz::Rmpz_divexact_ui($u, $n, $p);
                }
                else {
                    Math::GMPz::Rmpz_set_str($u, $p, 10);
                    Math::GMPz::Rmpz_divexact($u, $n, $u);
                }

                Math::GMPz::Rmpz_addmul_ui($d, $u, $k);
            }

            return $d;
        };

        my $n = $$x;

        # (a/b)' = (a'b - b'a) / b^2
        if (ref($n) eq 'Math::GMPq') {

            my $t1 = Math::GMPz::Rmpz_init();
            my $t2 = Math::GMPz::Rmpz_init();

            Math::GMPq::Rmpq_get_num($t1, $n);    # a
            Math::GMPq::Rmpq_get_den($t2, $n);    # b

            my $d1 = $deriv->($t1);               # a'
            my $d2 = $deriv->($t2);               # b'

            Math::GMPz::Rmpz_mul($d1, $d1, $t2);  # d1 = a' * b
            Math::GMPz::Rmpz_mul($d2, $d2, $t1);  # d2 = b' * a
            Math::GMPz::Rmpz_mul($t2, $t2, $t2);  # t2 = b^2
            Math::GMPz::Rmpz_sub($d1, $d1, $d2);  # d1 = (a'b - b'a)

            # q = d1 / t2
            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_num($q, $d1);
            Math::GMPq::Rmpq_set_den($q, $t2);
            Math::GMPq::Rmpq_canonicalize($q);
            return bless \$q;
        }

        bless \($deriv->(_any2mpz($n) // goto &nan));
    }

    *derivative = \&arithmetic_derivative;

    sub logarithmic_derivative {
        my ($n) = @_;
        $n->arithmetic_derivative->div($n);
    }

    sub lpf {
        my ($n) = @_;

        $n = _any2mpz($$n) // goto &nan;
        Math::GMPz::Rmpz_sgn($n) >= 0 or goto &nan;

        if (Math::GMPz::Rmpz_cmp_ui($n, 1) <= 0) {
            return bless \$n;
        }

        foreach my $p (2, 3, 5, 7) {
            if (Math::GMPz::Rmpz_divisible_ui_p($n, $p)) {
                return _set_int($p);
            }
        }

        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {
            my @f = _factor(Math::GMPz::Rmpz_get_ui($n));
            return _set_int($f[0]);
        }

        my $size = Math::GMPz::Rmpz_sizeinbase($n, 2);

        foreach my $j (2 .. 8) {

            my (undef, $f) = _primorial_trial_factor($n, 10**$j);

            if (defined($f)) {
                return _set_int($f);
            }

            last if (($j >= 5) && ($size <= 100));    # 30 digits
            last if (($j >= 6) && ($size <= 133));    # 40 digits
            last if (($j >= 7) && ($size <= 150));    # 45 digits
        }

        my @f = _factor($n);
        _set_int($f[0]);
    }

    sub gpf {
        my ($n) = @_;

        $n = _any2mpz($$n) // goto &nan;
        Math::GMPz::Rmpz_sgn($n) >= 0 or goto &nan;

        if (Math::GMPz::Rmpz_cmp_ui($n, 1) <= 0) {
            return bless \$n;
        }

        my @f = _factor($n);
        _set_int($f[-1]);
    }

    sub gcd_factors {
        my ($n, $arr) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        Math::GMPz::Rmpz_sgn($n) > 0
          or return Sidef::Types::Array::Array->new;

        my $z = Math::GMPz::Rmpz_init_set($n);    # copy
        state $t = Math::GMPz::Rmpz_init_nobless();

        my @gcds;
        my %seen_k;
        my %seen_gcd;

        foreach my $k (@$arr) {
            _valid(\$k);
            my $m = _any2mpz($$k) // next;
            next if $seen_k{Math::GMPz::Rmpz_get_str($m, 10)}++;
            Math::GMPz::Rmpz_gcd($t, $z, $m);
            Math::GMPz::Rmpz_cmp_ui($t, 1) > 0 or next;
            Math::GMPz::Rmpz_cmp($t, $z) < 0   or next;
            if (!$seen_gcd{Math::GMPz::Rmpz_get_str($t, 10)}++) {
                push @gcds, Math::GMPz::Rmpz_init_set($t);
            }
        }

        @gcds = sort { Math::GMPz::Rmpz_cmp($a, $b) } @gcds;

        my @factors;

        foreach my $g (@gcds) {

            Math::GMPz::Rmpz_gcd($t, $g, $z);
            Math::GMPz::Rmpz_cmp_ui($t, 1) > 0 or next;
            Math::GMPz::Rmpz_cmp($t, $z) < 0   or next;

            my $v = Math::GMPz::Rmpz_remove($z, $z, $t);
            push(@factors, (Math::GMPz::Rmpz_init_set($t)) x $v);
        }

        if (Math::GMPz::Rmpz_cmp_ui($z, 1) > 0) {
            push @factors, $z;
        }

        @factors = sort { Math::GMPz::Rmpz_cmp($a, $b) } @factors;
        @factors = map  { bless \$_ } @factors;

        Sidef::Types::Array::Array->new(\@factors);
    }

    *gcd_factor = \&gcd_factor;

    sub special_factors {
        my ($n, $m) = @_;

        if (defined($m)) {
            _valid(\$m);
        }
        else {
            $m //= ONE;
        }

        my $z = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        Math::GMPz::Rmpz_sgn($z) > 0
          or return Sidef::Types::Array::Array->new;

        # Factorize directly when n is a native integer
        if (Math::GMPz::Rmpz_fits_ulong_p($z)) {
            return Sidef::Types::Array::Array->new([map { _set_int($_) } _factor(Math::GMPz::Rmpz_get_ui($z))]);
        }

        # Factorize directly when n is small enough
        if (Math::GMPz::Rmpz_sizeinbase($z, 2) <= 110) {
            return Sidef::Types::Array::Array->new([map { _set_int($_) } _factor(Math::GMPz::Rmpz_get_str($z, 10))]);
        }

        my @factors;

        my $fermat_block = Sidef::Types::Block::Block->new(code => sub { $_[0]->fermat_factor($m->mul(_set_int(1e3))) });
        my $holf_block   = Sidef::Types::Block::Block->new(code => sub { $_[0]->holf_factor($m->mul(_set_int(1e3))) });
        my $pell_block   = Sidef::Types::Block::Block->new(code => sub { $_[0]->pell_factor($m->mul(_set_int(1e3))) });
        my $FLT_block    = Sidef::Types::Block::Block->new(code => sub { $_[0]->flt_factor($m->mul(_set_int(1e3))) });

        my $pm1_block       = Sidef::Types::Block::Block->new(code => sub { $_[0]->pm1_factor($m->mul(_set_int(1e5))) });
        my $pp1_block       = Sidef::Types::Block::Block->new(code => sub { $_[0]->pp1_factor($m->mul(_set_int(1e4))) });
        my $chebyshev_block = Sidef::Types::Block::Block->new(code => sub { $_[0]->chebyshev_factor($m->mul(_set_int(1e4))) });
        my $prho_block      = Sidef::Types::Block::Block->new(code => sub { $_[0]->pbrent_factor($m->mul(_set_int(1e5))) });

        push @factors, @{$n->trial_factor($m->mul(_set_int(1e6)))->first(-1)};

        # Special methods that depdend on the special form of n
        push @factors, @{$n->cop_factor($m->mul(_set_int(100)))->first(-1)};
        push @factors, @{$n->dop_factor($m->mul(_set_int(200)))->first(-1)};

        push @factors, @{$n->miller_factor($m->mul(_set_int(10)))->first(-1)};
        push @factors, @{$n->lucas_factor($m->mul(_set_int(5)))->first(-1)};

        push @factors, @{$n->fermat_factor($m->mul(_set_int(1e3)))->first(-1)};
        push @factors, @{$n->holf_factor($m->mul(_set_int(1e3)))->first(-1)};
        push @factors, @{$n->pell_factor($m->mul(_set_int(1e3)))->first(-1)};

        @factors = @{$n->gcd_factors(Sidef::Types::Array::Array->new([@factors]))};

        my @prime_factors;
        my @composite_factors;

        foreach my $f (@factors) {
            if (_is_prob_prime($$f)) {
                push @prime_factors, $f;
            }
            elsif (Math::GMPz::Rmpz_sizeinbase($$f, 2) <= 110) {
                push @prime_factors, (map { _set_int($_) } _factor($$f));
            }
            else {
                push @composite_factors, $f;
            }
        }

        # Special methods that can find extra special factors, recursively
        @composite_factors = map { @{$_->factor($fermat_block)} } @composite_factors;
        @composite_factors = map { @{$_->factor($holf_block)} } @composite_factors;
        @composite_factors = map { @{$_->factor($pell_block)} } @composite_factors;
        @composite_factors = map { @{$_->factor($FLT_block)} } @composite_factors;

        @composite_factors = map { @{$_->factor($pm1_block)} } @composite_factors;
        @composite_factors = map { @{$_->factor($pp1_block)} } @composite_factors;
        @composite_factors = map { @{$_->factor($prho_block)} } @composite_factors;
        @composite_factors = map { @{$_->factor($chebyshev_block)} } @composite_factors;

        @composite_factors = map {
            ($_->is_prime ? $_ : @{$_->cyclotomic_factor(map { _set_int($_) } 2 .. CORE::int($m->mul(_set_int(10))))})
        } @composite_factors;

        $n->gcd_factors(Sidef::Types::Array::Array->new([@prime_factors, @composite_factors]));
    }

    *special_factor = \&special_factors;

    sub factor {
        my ($n, $block) = @_;

        if (defined($block)) {
            my %cache;
            my $f = Sidef::Types::Array::Array->new([$n])->recmap(
                Sidef::Types::Block::Block->new(
                    code => sub {
                        my ($n) = @_;
                        _is_prob_prime($$n) ? Sidef::Types::Array::Array->new() : do {
                            my $factors = do { $cache{"$n"} //= $block->run($n) };
                            $factors->first(-1)->concat($factors->last(-1));
                        };
                    }
                )
            )->uniq;
            return $n->gcd_factors($f);
        }

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new();
        Sidef::Types::Array::Array->new([map { _set_int($_) } _factor($n)]);
    }

    *factors = \&factor;

    sub factor_exp {
        my ($n) = @_;

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new();

        my @pairs;
        foreach my $pk (_factor_exp($n)) {

            my ($p, $k) = @$pk;

            $p = _set_int($p);
            $k = _set_int($k);

            push @pairs, bless([$p, $k], 'Sidef::Types::Array::Array');
        }

        Sidef::Types::Array::Array->new(\@pairs);
    }

    *factors_exp = \&factor_exp;

    sub trial_factor {
        my ($n, $k) = @_;

        if (!defined($k)) {
            $n = _big2pistr($n) // (return Sidef::Types::Array::Array->new);
            my ($rem, @factors) = _adaptive_trial_factor($n);
            return Sidef::Types::Array::Array->new(
                                     [map { _set_int($_) } (@factors, ((Math::GMPz::Rmpz_cmp_ui($rem, 1) == 0) ? () : $rem))]);
        }

        _valid(\$k);
        __is_int__($$n) || return Sidef::Types::Array::Array->new();

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new();
        $k = _any2ui($$k)  // return Sidef::Types::Array::Array->new();

        return Sidef::Types::Array::Array->new()          if Math::GMPz::Rmpz_sgn($n) <= 0;
        return Sidef::Types::Array::Array->new(bless \$n) if $k <= 0;
        return Sidef::Types::Array::Array->new(ONE)       if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

        my ($r, @factors) = _primorial_trial_factor($n, $k);

        @factors
          || return Sidef::Types::Array::Array->new(bless \$n);

        my %count;
        my @uniq_factors;

        foreach my $f (@factors) {
            if (!$count{$f}++) {
                push @uniq_factors, $f;
            }
        }

        my @return =
          map { (_set_int($_)) x $count{$_} } @uniq_factors;

        if (Math::GMPz::Rmpz_cmp_ui($r, 1) > 0) {
            push @return, bless \$r;
        }

        return Sidef::Types::Array::Array->new(\@return);
    }

    sub prho_factor {
        my ($n, $k) = @_;
        _valid(\$k) if defined($k);
        Sidef::Types::Array::Array->new(
                                        [map { _set_int($_) }
                                           Math::Prime::Util::GMP::prho_factor(
                                                                  _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                                  (defined($k) ? _big2uistr($k) // () : ()),)
                                        ]
                                       );
    }

    sub pbrent_factor {
        my ($n, $k) = @_;
        _valid(\$k) if defined($k);
        Sidef::Types::Array::Array->new(
                                        [map { _set_int($_) }
                                           Math::Prime::Util::GMP::pbrent_factor(
                                                                  _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                                  (defined($k) ? _big2uistr($k) // () : ()),)
                                        ]
                                       );
    }

    sub pminus1_factor {
        my ($n, $B1, $B2) = @_;

        _valid(\$B1) if defined($B1);
        _valid(\$B2) if defined($B2);

        Sidef::Types::Array::Array->new(
                                        [map { _set_int($_) }
                                           Math::Prime::Util::GMP::pminus1_factor(
                                                                  _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                                  (defined($B1) ? _big2uistr($B1) // () : ()),
                                                                  (defined($B2) ? _big2uistr($B2) // () : ()),
                                           )
                                        ]
                                       );
    }

    *pm1_factor = \&pminus1_factor;

    sub pplus1_factor {
        my ($n, $B1) = @_;
        _valid(\$B1) if defined($B1);
        Sidef::Types::Array::Array->new(
                                        [map { _set_int($_) }
                                           Math::Prime::Util::GMP::pplus1_factor(
                                                                  _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                                  (defined($B1) ? _big2uistr($B1) // () : ()),)
                                        ]
                                       );
    }

    *pp1_factor = \&pplus1_factor;

    sub chebyshev_factor {
        my ($n, $B, $x) = @_;

        # The Chebyshev factorization method, taking
        # advantage of the smoothness of p-1 or p+1.

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0
          or return Sidef::Types::Array::Array->new;

        $B = defined($B) ? do { _valid(\$B); _any2ui($$B) || 1e5 } : 1e5;
        $x =
          defined($x)
          ? do { _valid(\$x); Math::GMPz::Rmpz_init_set(_any2mpz($$x) // $TWO) }
          : Math::GMPz::Rmpz_init_set_ui(CORE::int(CORE::rand(1e9)));

        my $i = Math::GMPz::Rmpz_init_set_ui(2);

        # Try to compute invmod(2, n)
        # If n is even, return faster
        Math::GMPz::Rmpz_invert($i, $i, $n)
          || return Sidef::Types::Array::Array->new([_set_int(2), (($n == 2) ? () : _set_int($n >> 1))]);

        state $V1 = Math::GMPz::Rmpz_init_nobless();
        state $V2 = Math::GMPz::Rmpz_init_nobless();
        state $Q1 = Math::GMPz::Rmpz_init_nobless();
        state $Q2 = Math::GMPz::Rmpz_init_nobless();

        my $chebyshevTmod = sub {
            my ($v, $x) = @_;

            Math::GMPz::Rmpz_mul_2exp($x, $x, 1);

            Math::GMPz::Rmpz_set_ui($V1, 2);
            Math::GMPz::Rmpz_set($V2, $x);
            Math::GMPz::Rmpz_set_ui($Q1, 1);
            Math::GMPz::Rmpz_set_ui($Q2, 1);

            my @bits;
            while ($v) {
                unshift @bits, $v & 1;
                $v >>= 1;
            }

            foreach my $bit (@bits) {

                Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
                Math::GMPz::Rmpz_mod($Q1, $Q1, $n);

                if ($bit) {
                    Math::GMPz::Rmpz_mul($V1, $V1, $V2);
                    Math::GMPz::Rmpz_powm_ui($V2, $V2, 2, $n);
                    Math::GMPz::Rmpz_submul($V1, $Q1, $x);
                    Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);
                    Math::GMPz::Rmpz_mod($V1, $V1, $n);
                }
                else {
                    Math::GMPz::Rmpz_set($Q2, $Q1);
                    Math::GMPz::Rmpz_mul($V2, $V2, $V1);
                    Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $n);
                    Math::GMPz::Rmpz_submul($V2, $Q1, $x);
                    Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);
                    Math::GMPz::Rmpz_mod($V2, $V2, $n);
                }
            }

            Math::GMPz::Rmpz_mul($x, $V1, $i);
            Math::GMPz::Rmpz_mod($x, $x, $n);
        };

        my $g     = Math::GMPz::Rmpz_init();
        my $lnB   = CORE::log($B);
        my $sqrtB = Math::Prime::Util::GMP::sqrtint($B);

        foreach my $p (
                       HAS_PRIME_UTIL
                       ? @{Math::Prime::Util::primes($sqrtB)}
                       : Math::Prime::Util::GMP::sieve_primes(2, $sqrtB)
          ) {
            $chebyshevTmod->($p**CORE::int($lnB / CORE::log($p)), $x);
        }

        for (my $p = _next_prime($sqrtB) ; $p <= $B ; $p = _next_prime($p)) {

            $chebyshevTmod->($p, $x);    # T_k(x) (mod n)

            Math::GMPz::Rmpz_sub_ui($g, $x, 1);
            Math::GMPz::Rmpz_gcd($g, $g, $n);

            if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {

                if (Math::GMPz::Rmpz_cmp($g, $n) == 0) {
                    return Sidef::Types::Array::Array->new([bless \$n]);
                }

                my $x = Math::GMPz::Rmpz_init();
                my $y = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_set($y, $g);
                Math::GMPz::Rmpz_divexact($x, $n, $g);

                my @f = map { bless \$_ } sort { Math::GMPz::Rmpz_cmp($a, $b) } ($x, $y);
                return Sidef::Types::Array::Array->new(\@f);
            }
        }

        Sidef::Types::Array::Array->new([bless(\$n)]);
    }

    sub holf_factor {
        my ($n, $k) = @_;
        _valid(\$k) if defined($k);
        Sidef::Types::Array::Array->new(
                                        [map { _set_int($_) }
                                           Math::Prime::Util::GMP::holf_factor(
                                                                  _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                                  (defined($k) ? _big2uistr($k) // 1e4 : 1e4))
                                        ]
                                       );
    }

    sub _miller_factor {
        my ($n, $tries) = @_;

        # $n is a Math::GMPz object holding a positive value
        # $tries is a positive native integer or `undef`

        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return _factor(Math::GMPz::Rmpz_get_ui($n));
        }

        my $D = Math::GMPz::Rmpz_init();    # n-1
        Math::GMPz::Rmpz_sub_ui($D, $n, 1);

        my $s = Math::GMPz::Rmpz_scan1($D, 0) || return ($n);
        my $r = $s - 1;

        my $d = Math::GMPz::Rmpz_init();    # D >> s
        Math::GMPz::Rmpz_div_2exp($d, $D, $s);

        $tries //= 1 + CORE::int(200 / $s);

        my $x = Math::GMPz::Rmpz_init();
        my $g = Math::GMPz::Rmpz_init();

        for (1 .. $tries) {

            my $p = (
                     HAS_PRIME_UTIL
                     ? Math::Prime::Util::random_prime(1e7)
                     : Math::Prime::Util::GMP::random_prime(1e7)
                    );

            Math::GMPz::Rmpz_set_ui($g, $p);
            Math::GMPz::Rmpz_powm($x, $g, $d, $n);

            foreach my $k (0 .. $r) {

                last if (Math::GMPz::Rmpz_cmp_ui($x, 1) == 0);
                last if (Math::GMPz::Rmpz_cmp($x, $D) == 0);

                foreach my $i (1, -1) {

                    ($i < 0)
                      ? Math::GMPz::Rmpz_sub_ui($g, $x, -$i)
                      : Math::GMPz::Rmpz_add_ui($g, $x, +$i);

                    Math::GMPz::Rmpz_gcd($g, $g, $n);

                    if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0 and Math::GMPz::Rmpz_cmp($g, $n) < 0) {

                        Math::GMPz::Rmpz_divexact($x, $n, $g);

                        my @g_factors = (_is_prob_prime($g) ? $g : __SUB__->($g));
                        my @x_factors = (_is_prob_prime($x) ? $x : __SUB__->($x));

                        return (@g_factors, @x_factors);
                    }
                }

                Math::GMPz::Rmpz_powm_ui($x, $x, 2, $n);
            }
        }

        my @holf_factors = Math::Prime::Util::GMP::holf_factor(Math::GMPz::Rmpz_get_str($n, 10), 10_000);

        if (scalar(@holf_factors) > 1) {
            return (
                    map { _is_prob_prime($_) ? $_ : __SUB__->($_) }
                    map { Math::GMPz::Rmpz_init_set_str($_, 10) } @holf_factors
                   );
        }

        return ($n);
    }

    sub miller_factor {
        my ($n, $tries) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new();
        Math::GMPz::Rmpz_sgn($n) > 0 or return Sidef::Types::Array::Array->new();

        if (defined($tries)) {
            _valid(\$tries);
            $tries = _any2ui($$tries) // undef;
        }

        my @factors = map { ref($_) ? $_ : Math::GMPz::Rmpz_init_set_ui($_) } _miller_factor($n, $tries);
        @factors = sort { Math::GMPz::Rmpz_cmp($a, $b) } @factors;
        @factors = map  { bless \$_ } @factors;

        Sidef::Types::Array::Array->new(\@factors);
    }

    *miller_rabin_factor = \&miller_factor;

    sub _lucas_factor {
        my ($n, $j, $tries) = @_;

        # $n is a Math::GMPz object holding a positive value
        # $j is a signed native integer or `undef`
        # $tries is an unsigned native integer or `undef`

        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return _factor(Math::GMPz::Rmpz_get_ui($n));
        }

        if (!defined($j)) {
            my @factors = __SUB__->($n, 1);
            @factors = map { _is_prob_prime($_) ? $_ : __SUB__->($_, -1) } @factors;
            return @factors;
        }

        my $D = Math::GMPz::Rmpz_init();    # n + j

        ($j < 0)
          ? Math::GMPz::Rmpz_sub_ui($D, $n, -$j)
          : Math::GMPz::Rmpz_add_ui($D, $n, +$j);

        my $s = Math::GMPz::Rmpz_scan1($D, 0) || return ($n);
        my $r = $s;

        my $d = Math::GMPz::Rmpz_init();    # D >> s
        Math::GMPz::Rmpz_div_2exp($d, $D, $s);
        $d = Math::GMPz::Rmpz_get_str($d, 10);

        $tries //= 1 + CORE::int(100 / $s);

        my $x = Math::GMPz::Rmpz_init();
        my $g = Math::GMPz::Rmpz_init();

        my $PQ_limit = $LUCAS_PQ_LIMIT;

        if (Math::GMPz::Rmpz_cmp_ui($n, 1e6) <= 0) {
            $PQ_limit = Math::GMPz::Rmpz_get_ui($n) - 1;
        }

        my $N = Math::GMPz::Rmpz_get_str($n, 10);

        foreach my $i (1 .. $tries) {

            my $P = 1 + CORE::int(CORE::rand($PQ_limit));
            my $Q = 1 + CORE::int(CORE::rand($PQ_limit));

            $Q *= -1 if (CORE::rand(1) < 0.5);

            my $delta = $P * $P - 4 * $Q;

            next
              if (
                  HAS_PRIME_UTIL
                  ? Math::Prime::Util::is_square($delta)
                  : Math::Prime::Util::GMP::is_square($delta)
                 );

            my ($U1, $V1, $Q1) =
              map { Math::GMPz::Rmpz_init_set_str($_, 10) } Math::Prime::Util::GMP::lucas_sequence($N, $P, $Q, $d);

            for my $k (1 .. $r) {

                foreach my $t ($U1, $V1, $P) {
                    if (ref($t)) {
                        Math::GMPz::Rmpz_gcd($g, $t, $n);
                    }
                    else {
                        Math::GMPz::Rmpz_sub_ui($g, $V1, $t);
                        Math::GMPz::Rmpz_gcd($g, $g, $n);
                    }
                    if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0 and Math::GMPz::Rmpz_cmp($g, $n) < 0) {
                        Math::GMPz::Rmpz_divexact($x, $n, $g);

                        my @g_factors = (_is_prob_prime($g) ? $g : __SUB__->($g, $j));
                        my @x_factors = (_is_prob_prime($x) ? $x : __SUB__->($x, $j));

                        return (@g_factors, @x_factors);
                    }
                }

                Math::GMPz::Rmpz_mul($U1, $U1, $V1);
                Math::GMPz::Rmpz_mod($U1, $U1, $n);
                Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $n);
                Math::GMPz::Rmpz_submul_ui($V1, $Q1, 2);
                Math::GMPz::Rmpz_powm_ui($Q1, $Q1, 2, $n);
            }
        }

        my @holf_factors = Math::Prime::Util::GMP::holf_factor($N, 10_000);

        if (scalar(@holf_factors) > 1) {
            return (
                    map { _is_prob_prime($_) ? $_ : __SUB__->($_, $j) }
                    map { Math::GMPz::Rmpz_init_set_str($_, 10) } @holf_factors
                   );
        }

        return ($n);
    }

    sub lucas_factor {
        my ($n, $j, $tries) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new();
        Math::GMPz::Rmpz_sgn($n) > 0 or return Sidef::Types::Array::Array->new();

        if (defined($j)) {
            _valid(\$j);
            $j = _any2si($$j) // undef;
        }

        if (defined($tries)) {
            _valid(\$tries);
            $tries = _any2ui($$tries) // undef;
        }

        my @factors = map { ref($_) ? $_ : Math::GMPz::Rmpz_init_set_ui($_) } _lucas_factor($n, $j, $tries);
        @factors = sort { Math::GMPz::Rmpz_cmp($a, $b) } @factors;
        @factors = map  { bless \$_ } @factors;

        Sidef::Types::Array::Array->new(\@factors);
    }

    *lucas_miller_factor = \&lucas_factor;

    sub fermat_factor {
        my ($n, $k) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new();
        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // 1e4 } : 1e4;

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0
          or return Sidef::Types::Array::Array->new();

        my $p = Math::GMPz::Rmpz_init();    # p = floor(sqrt(n))
        my $q = Math::GMPz::Rmpz_init();    # q = p^2 - n

        Math::GMPz::Rmpz_sqrtrem($p, $q, $n);
        Math::GMPz::Rmpz_neg($q, $q);

        for (my $j = 1 ; $j <= $k ; ++$j) {

            Math::GMPz::Rmpz_addmul_ui($q, $p, 2);

            Math::GMPz::Rmpz_add_ui($q, $q, 1);
            Math::GMPz::Rmpz_add_ui($p, $p, 1);

            if (Math::GMPz::Rmpz_perfect_square_p($q)) {
                Math::GMPz::Rmpz_sqrt($q, $q);

                my $r1 = Math::GMPz::Rmpz_init();
                my $r2 = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_sub($r1, $p, $q);
                Math::GMPz::Rmpz_add($r2, $p, $q);

                return Sidef::Types::Array::Array->new([bless(\$r1), bless(\$r2)]);
            }
        }

        Sidef::Types::Array::Array->new([bless(\$n)]);
    }

    # Congruence of powers factorization method
    sub cop_factor {
        my ($n, $upto) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        if (defined($upto)) {
            _valid(\$upto);
            $upto = _any2ui($$upto);
        }

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0
          or return Sidef::Types::Array::Array->new;

        my %seen_divisor;

        my $congr_powers = sub {
            my ($r1, $e1, $r2, $e2) = @_;

            my @d1 = _divisors($e1);
            my @d2 = _divisors($e2);

            @d1 = map {
                my $x = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_pow_ui($x, $r1, $_);
                $x;
            } @d1;

            @d2 = map {
                my $y = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_pow_ui($y, $r2, $_);
                $y;
            } @d2;

            state $g = Math::GMPz::Rmpz_init_nobless();

            my @factors;

            foreach my $x (@d1) {
                foreach my $y (@d2) {
                    foreach my $j (-1, 1) {

                        ($j == 1)
                          ? Math::GMPz::Rmpz_sub($g, $x, $y)
                          : Math::GMPz::Rmpz_add($g, $x, $y);

                        Math::GMPz::Rmpz_gcd($g, $g, $n);

                        if (    Math::GMPz::Rmpz_cmp_ui($g, 1) > 0
                            and Math::GMPz::Rmpz_cmp($g, $n) < 0
                            and !$seen_divisor{Math::GMPz::Rmpz_get_str($g, 10)}++) {
                            push @factors, Math::GMPz::Rmpz_init_set($g);
                        }
                    }
                }
            }

            @factors;
        };

        my @congr_powers_params;

        my $process = sub {
            my ($root, $e) = @_;

            for my $j (1, 0) {

                my $k = Math::GMPz::Rmpz_init();
                my $u = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_add_ui($k, $root, $j);
                Math::GMPz::Rmpz_powm_ui($u, $k, $e, $n);

                foreach my $z ($u, $n - $u) {

                    if (Math::GMPz::Rmpz_perfect_power_p($z)) {

                        my $t = Math::Prime::Util::GMP::is_power(Math::GMPz::Rmpz_get_str($z, 10)) || 1;

                        if ($t > 1) {
                            my $r = Math::GMPz::Rmpz_init();
                            Math::GMPz::Rmpz_root($r, $z, $t);
                            push @congr_powers_params, [$r, $t, $k, $e];
                        }
                    }
                }
            }
        };

        my $n_log2 = Math::GMPz::Rmpz_sizeinbase($n, 2);

        if (defined($upto) and $n_log2 > $upto) {
            $n_log2 = $upto;
        }

        my @range = reverse(2 .. $n_log2);

        for my $e (@range) {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_root($r, $n, $e);
            $process->($r, $e);
        }

        for my $r (@range) {
            my $e = __ilog__($n, $r);
            $process->(Math::GMPz::Rmpz_init_set_ui($r), $e);
        }

        my %seen_param;
        @congr_powers_params = grep { !$seen_param{join(' ', @$_)}++ } @congr_powers_params;

        my @divisors;

        foreach my $args (@congr_powers_params) {
            push @divisors, $congr_powers->(@$args);
        }

        (bless \$n)->gcd_factors(Sidef::Types::Array::Array->new([map { bless \$_ } @divisors]));
    }

    # Difference of powers factorization method
    sub dop_factor {
        my ($n, $upto) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        if (defined($upto)) {
            $upto = _any2ui($$upto);
        }

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0
          or return Sidef::Types::Array::Array->new;

        my %seen_divisor;
        my @diff_powers_params;

        #
        ## Difference of powers factorization method
        #

        my $diff_powers = sub {
            my ($r1, $e1, $r2, $e2) = @_;

            my @d1 = _divisors($e1);
            my @d2 = _divisors($e2);

            @d1 = map {
                my $x = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_pow_ui($x, $r1, $_);
                $x;
            } @d1;

            @d2 = map {
                my $y = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_pow_ui($y, $r2, $_);
                $y;
            } @d2;

            state $g = Math::GMPz::Rmpz_init_nobless();

            my @factors;

            foreach my $x (@d1) {
                foreach my $y (@d2) {
                    foreach my $j (1, -1) {

                        ($j == 1)
                          ? Math::GMPz::Rmpz_sub($g, $x, $y)
                          : Math::GMPz::Rmpz_add($g, $x, $y);

                        Math::GMPz::Rmpz_gcd($g, $g, $n);

                        if (    Math::GMPz::Rmpz_cmp_ui($g, 1) > 0
                            and Math::GMPz::Rmpz_cmp($g, $n) < 0
                            and !$seen_divisor{Math::GMPz::Rmpz_get_str($g, 10)}++) {
                            push @factors, Math::GMPz::Rmpz_init_set($g);
                        }
                    }
                }
            }

            @factors;
        };

        my $diff_power_check = sub {
            my ($r1, $e1) = @_;

            # u = r1^e1
            state $u = Math::GMPz::Rmpz_init_nobless();
            Math::GMPz::Rmpz_pow_ui($u, $r1, $e1);

            # dx = abs(u - n)
            state $dx = Math::GMPz::Rmpz_init_nobless();
            Math::GMPz::Rmpz_sub($dx, $u, $n);
            Math::GMPz::Rmpz_abs($dx, $dx);

            if (Math::GMPz::Rmpz_perfect_power_p($dx)) {

                my $e2 = Math::Prime::Util::GMP::is_power(Math::GMPz::Rmpz_get_str($dx, 10)) || 1;
                my $r2 = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_root($r2, $dx, $e2);
                push @diff_powers_params, [$r1, $e1, $r2, $e2];
            }
        };

        my $n_log2 = Math::GMPz::Rmpz_sizeinbase($n, 2);

        if (defined($upto) and $n_log2 > $upto) {
            $n_log2 = $upto;
        }

        my @range = CORE::reverse(2 .. $n_log2);

        # Sum and difference of powers of the form a^k ± b^k, where a and b are small.
        if (0) {
            foreach my $k (@range) {

                my $t  = __ilog__($n, $k);
                my $r1 = Math::GMPz::Rmpz_init_set_ui($k);

                $diff_power_check->($r1, $t);        # sum of powers
                $diff_power_check->($r1, $t + 1);    # difference of powers
            }
        }

        # Sum and difference of powers of the form a^k ± b^k, where a and b are large.
        foreach my $e1 (@range) {

            my $t = Math::GMPz::Rmpz_init();
            my $u = Math::GMPz::Rmpz_init();

            Math::GMPz::Rmpz_root($t, $n, $e1);
            Math::GMPz::Rmpz_add_ui($u, $t, 1);

            $diff_power_check->($t, $e1);    # sum of powers
            $diff_power_check->($u, $e1);    # difference of powers
        }

        my @divisors;

        foreach my $args (@diff_powers_params) {
            push @divisors, $diff_powers->(@$args);
        }

        (bless \$n)->gcd_factors(Sidef::Types::Array::Array->new([map { bless \$_ } @divisors]));
    }

    # "Fermat's Little Theorem" factorization method
    sub flt_factor {
        my ($n, $base, $reps) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new();

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0
          or return Sidef::Types::Array::Array->new;

        $base = defined($base) ? do { _valid(\$base); _any2ui($$base) // 2 }   : 2;
        $reps = defined($reps) ? do { _valid(\$reps); _any2ui($$reps) // 1e4 } : 1e4;

        state $z = Math::GMPz::Rmpz_init_nobless();
        state $t = Math::GMPz::Rmpz_init_nobless();
        state $g = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_set_ui($z, $base);
        Math::GMPz::Rmpz_set_ui($t, $base);

        Math::GMPz::Rmpz_powm($z, $z, $n, $n);

        # Cannot factor Fermat pseudoprimes
        if (Math::GMPz::Rmpz_cmp_ui($z, $base) == 0) {
            return Sidef::Types::Array::Array->new([bless \$n]);
        }

        my $multiplier = $base * $base;

        if ($multiplier > ULONG_MAX) {
            return Sidef::Types::Array::Array->new([bless \$n]);
        }

        for (my $j = 1 ; $j <= $reps ; $j += 1) {

            Math::GMPz::Rmpz_mul_ui($t, $t, $multiplier);
            Math::GMPz::Rmpz_mod($t, $t, $n) if ($j % 10 == 0);
            Math::GMPz::Rmpz_sub($g, $z, $t);
            Math::GMPz::Rmpz_gcd($g, $g, $n);

            if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {

                if (Math::GMPz::Rmpz_cmp($g, $n) == 0) {
                    return Sidef::Types::Array::Array->new([bless \$n]);
                }

                my $x = Math::GMPz::Rmpz_init();
                my $y = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_set($y, $g);
                Math::GMPz::Rmpz_divexact($x, $n, $g);

                my @f = map { bless \$_ } sort { Math::GMPz::Rmpz_cmp($a, $b) } ($x, $y);
                return Sidef::Types::Array::Array->new(\@f);
            }
        }

        Sidef::Types::Array::Array->new([bless(\$n)]);
    }

    sub pell_factor {
        my ($n, $reps) = @_;

        # Simple version of the continued-fraction factorization method.
        # Efficient for numbers that have factors relatively close to sqrt(n)

        $n    = _any2mpz($$n) // return Sidef::Types::Array::Array->new();
        $reps = defined($reps) ? do { _valid(\$reps); _any2ui($$reps) // 1e4 } : 1e4;

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0
          or return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_perfect_square_p($n)) {
            my $t = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_sqrt($t, $n);
            return Sidef::Types::Array::Array->new([(bless \$t), (bless \$t)]);
        }

        my $x = Math::GMPz::Rmpz_init();
        my $y = Math::GMPz::Rmpz_init();
        my $z = Math::GMPz::Rmpz_init_set_ui(1);

        my $t = Math::GMPz::Rmpz_init();
        my $w = Math::GMPz::Rmpz_init();
        my $r = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_sqrt($x, $n);
        Math::GMPz::Rmpz_set($y, $x);

        Math::GMPz::Rmpz_add($w, $x, $x);
        Math::GMPz::Rmpz_set($r, $w);

        my $f2 = Math::GMPz::Rmpz_init_set($x);
        my $f1 = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $k (1 .. $reps) {

            # y = r*z - y
            Math::GMPz::Rmpz_mul($t, $r, $z);
            Math::GMPz::Rmpz_sub($y, $t, $y);

            # z = (n - y*y) / z
            Math::GMPz::Rmpz_mul($t, $y, $y);
            Math::GMPz::Rmpz_sub($t, $n, $t);
            Math::GMPz::Rmpz_divexact($z, $t, $z);

            # r = (x + y) / z
            Math::GMPz::Rmpz_add($t, $x, $y);

            # Floor division: floor((x+y)/z)
            # Math::GMPz::Rmpz_div($r, $t, $z);

            # Round (x+y)/z to nearest integer
            Math::GMPz::Rmpz_set($r, $z);
            Math::GMPz::Rmpz_addmul_ui($r, $t, 2);
            Math::GMPz::Rmpz_div($r, $r, $z);
            Math::GMPz::Rmpz_div_2exp($r, $r, 1);

            # f1 = (f1 + r*f2) % n
            Math::GMPz::Rmpz_addmul($f1, $f2, $r);
            Math::GMPz::Rmpz_mod($f1, $f1, $n);

            # swap f1 with f2
            ($f1, $f2) = ($f2, $f1);

            if (Math::GMPz::Rmpz_perfect_square_p($z)) {

                my $g = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_sqrt($g, $z);
                Math::GMPz::Rmpz_sub($g, $f1, $g);
                Math::GMPz::Rmpz_gcd($g, $g, $n);

                if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {

                    if (Math::GMPz::Rmpz_cmp($g, $n) == 0) {
                        return Sidef::Types::Array::Array->new([bless \$n]);
                    }

                    my $x = Math::GMPz::Rmpz_init();
                    my $y = Math::GMPz::Rmpz_init();

                    Math::GMPz::Rmpz_set($y, $g);
                    Math::GMPz::Rmpz_divexact($x, $n, $g);

                    my @f = map { bless \$_ } sort { Math::GMPz::Rmpz_cmp($a, $b) } ($x, $y);
                    return Sidef::Types::Array::Array->new(\@f);
                }
            }

            last if (Math::GMPz::Rmpz_cmp_ui($z, 1) == 0);
        }

        Sidef::Types::Array::Array->new([bless(\$n)]);
    }

    sub mbe_factor {
        my ($n, $reps) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0
          or return Sidef::Types::Array::Array->new;

        $reps = defined($reps) ? do { _valid(\$reps); _any2ui($$reps) // 10 } : 10;

        state $state = Math::GMPz::zgmp_randinit_mt_nobless();
        Math::GMPz::zgmp_randseed_ui($state, CORE::int(CORE::rand(1e9)));

        state $t = Math::GMPz::Rmpz_init_nobless();
        state $g = Math::GMPz::Rmpz_init_nobless();

        state $A = Math::GMPz::Rmpz_init_nobless();
        state $B = Math::GMPz::Rmpz_init_nobless();
        state $C = Math::GMPz::Rmpz_init_nobless();

        foreach my $k (1 .. $reps) {

            # Deterministic version
            # Math::GMPz::Rmpz_div_ui($t, $n, $k+1);

            # Randomized version
            Math::GMPz::Rmpz_urandomm($t, $state, $n, 1);

            Math::GMPz::Rmpz_set($A, $t);
            Math::GMPz::Rmpz_set($B, $t);
            Math::GMPz::Rmpz_set_ui($C, 1);

            foreach my $i (0 .. Math::GMPz::Rmpz_sizeinbase($B, 2) - 1) {

                if (Math::GMPz::Rmpz_tstbit($B, $i)) {

                    Math::GMPz::Rmpz_powm($C, $A, $C, $n);
                    Math::GMPz::Rmpz_sub_ui($g, $C, 1);
                    Math::GMPz::Rmpz_gcd($g, $g, $n);

                    if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {

                        if (Math::GMPz::Rmpz_cmp($g, $n) == 0) {
                            return Sidef::Types::Array::Array->new([bless \$n]);
                        }

                        my $x = Math::GMPz::Rmpz_init();
                        my $y = Math::GMPz::Rmpz_init();

                        Math::GMPz::Rmpz_set($y, $g);
                        Math::GMPz::Rmpz_divexact($x, $n, $g);

                        my @f = map { bless \$_ } sort { Math::GMPz::Rmpz_cmp($a, $b) } ($x, $y);
                        return Sidef::Types::Array::Array->new(\@f);
                    }
                }

                Math::GMPz::Rmpz_powm($A, $A, $A, $n);
            }
        }

        Sidef::Types::Array::Array->new([bless(\$n)]);
    }

    sub squfof_factor {
        my ($n, $k) = @_;
        _valid(\$k) if defined($k);
        Sidef::Types::Array::Array->new(
                                        [map { _set_int($_) }
                                           Math::Prime::Util::GMP::squfof_factor(
                                                                  _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                                  (defined($k) ? _big2uistr($k) // 1e4 : 1e4))
                                        ]
                                       );
    }

    sub ecm_factor {
        my ($n, $B1, $curves) = @_;

        _valid(\$B1)     if defined($B1);
        _valid(\$curves) if defined($curves);

        Sidef::Types::Array::Array->new(
            [
             map { _set_int($_) } Math::Prime::Util::GMP::ecm_factor(
                                                     _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                     (defined($B1)     ? _big2uistr($B1)     // () : ()),    # B1
                                                     (defined($curves) ? _big2uistr($curves) // () : ()),    # number of curves
                                                                    )
            ]
        );
    }

    sub qs_factor {
        my ($n) = @_;
        Sidef::Types::Array::Array->new(
                             [map { _set_int($_) }
                                Math::Prime::Util::GMP::qs_factor(_big2pistr($n) // (return Sidef::Types::Array::Array->new()))
                             ]
        );
    }

    sub dirichlet_convolution {
        my ($n, $f, $g) = @_;

        $n = _any2mpz($$n) // goto &nan;
        Math::GMPz::Rmpz_sgn($n) > 0 or return ZERO;

        $f //= Sidef::Types::Block::Block->new(code => sub { ONE });
        $g //= Sidef::Types::Block::Block->new(code => sub { ONE });

        my @terms;
        my $result = ZERO;

        foreach my $d (_divisors($n)) {

            my $t =
              ($d < ULONG_MAX)
              ? Math::GMPz::Rmpz_init_set_ui($d)
              : Math::GMPz::Rmpz_init_set_str("$d", 10);

            my $u = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_divexact($u, $n, $t);

            $result = $result->add($f->run(bless \$t)->mul($g->run(bless \$u)));
        }

        return $result;
    }

    *dconv = \&dirichlet_convolution;

    sub dirichlet_hyperbola {
        my ($n, $f, $g, $F, $G) = @_;

        $n = _any2mpz($$n) // goto &nan;
        Math::GMPz::Rmpz_sgn($n) > 0 or return ZERO;

        $f //= Sidef::Types::Block::Block->new(code => sub { ONE });
        $g //= Sidef::Types::Block::Block->new(code => sub { ONE });

        $F //= Sidef::Types::Block::Block->new(code => sub { $_[0] });
        $G //= Sidef::Types::Block::Block->new(code => sub { $_[0] });

        my $s = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sqrt($s, $n);

        my $sum = Math::GMPz::Rmpz_init_set_ui(0);

        my $t = bless \Math::GMPz::Rmpz_init_set_ui(0);
        my $u = bless \Math::GMPz::Rmpz_init_set_ui(0);

        Math::GMPz::Rmpz_fits_slong_p($s) || goto &nan;

        foreach my $k (1 .. Math::GMPz::Rmpz_get_ui($s)) {

            Math::GMPz::Rmpz_set_ui($$t, $k);
            Math::GMPz::Rmpz_div_ui($$u, $n, $k);

            my $f_r = $f->run($t);
            my $g_r = $g->run($t);
            my $F_r = $F->run($u);
            my $G_r = $G->run($u);

            $f_r = $f_r->to_n if ref($f_r) ne __PACKAGE__;
            $g_r = $g_r->to_n if ref($g_r) ne __PACKAGE__;
            $F_r = $F_r->to_n if ref($F_r) ne __PACKAGE__;
            $G_r = $G_r->to_n if ref($G_r) ne __PACKAGE__;

            $f_r = $$f_r;
            $g_r = $$g_r;
            $F_r = $$F_r;
            $G_r = $$G_r;

            if (    ref($f_r) eq 'Math::GMPz'
                and ref($g_r) eq 'Math::GMPz'
                and ref($F_r) eq 'Math::GMPz'
                and ref($G_r) eq 'Math::GMPz'
                and ref($sum) eq 'Math::GMPz') {
                Math::GMPz::Rmpz_addmul($sum, $f_r, $G_r);
                Math::GMPz::Rmpz_addmul($sum, $g_r, $F_r);
            }
            else {
                $sum = __add__($sum, __add__(__mul__($f_r, $G_r), __mul__($g_r, $F_r)));
            }
        }

        $sum = __sub__($sum, __mul__(${$F->run(_set_int($s))->to_n}, ${$G->run(_set_int($s))->to_n}));
        bless \$sum;
    }

    *dirichlet_sum = \&dirichlet_hyperbola;

    sub sum_remainders {
        my ($n, $v) = @_;

        # a(n,v) = Sum_{k=1..n} v % k

        _valid(\$v);

        $n = _any2mpz($$n) // goto &nan;
        $v = _any2mpz($$v) // goto &nan;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO;
        }

        my $S = sub {    # Sum_{k=1..n} sigma(k) = Sum_{k=1..n} k*floor(n/k)
            my ($n) = @_;

            if (Math::GMPz::Rmpz_sgn($n) < 0) {

                # Support for negative n:
                #   S(-n) = n*(n+1)/2 + S(n-1)

                # Based on the formula:
                # Sum_{k=1..n} -k*floor(n/-k) = Sum_{k=1..n} k*ceiling(n/k)
                #                             = n*(n+1)/2 + Sum_{k=1..n-1} sigma(k).

                $n = Math::GMPz::Rmpz_init_set($n);
                Math::GMPz::Rmpz_abs($n, $n);

                my $t = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_add_ui($t, $n, 1);
                Math::GMPz::Rmpz_mul($t, $t, $n);
                Math::GMPz::Rmpz_div_2exp($t, $t, 1);
                Math::GMPz::Rmpz_sub_ui($n, $n, 1);

                my $r = __SUB__->($n);
                Math::GMPz::Rmpz_add($t, $t, $r);
                return $t;
            }

            my $t = Math::GMPz::Rmpz_init();
            my $u = Math::GMPz::Rmpz_init();
            my $T = Math::GMPz::Rmpz_init_set_ui(0);

            my $s = Math::Prime::Util::GMP::sqrtint($n);

            foreach my $k (1 .. $s) {

                # T += faulhaber(idiv(n,k), 1) + k*idiv(n,k)
                Math::GMPz::Rmpz_div_ui($t, $n, $k);
                Math::GMPz::Rmpz_add_ui($u, $t, 1);
                Math::GMPz::Rmpz_mul($u, $u, $t);
                Math::GMPz::Rmpz_div_2exp($u, $u, 1);
                Math::GMPz::Rmpz_mul_ui($t, $t, $k);
                Math::GMPz::Rmpz_add($u, $u, $t);
                Math::GMPz::Rmpz_add($T, $T, $u);
            }

            # T -= faulhaber(s, 1)*s
            Math::GMPz::Rmpz_set_str($u, $s, 10);
            Math::GMPz::Rmpz_add_ui($t, $u, 1);
            Math::GMPz::Rmpz_mul($t, $t, $u);
            Math::GMPz::Rmpz_div_2exp($t, $t, 1);
            Math::GMPz::Rmpz_mul($t, $t, $u);
            Math::GMPz::Rmpz_sub($T, $T, $t);

            return $T;
        };

        my $G = sub {    # Sum_{k=A..B} k*floor(B/k)
            my ($A, $B) = @_;

            if (Math::GMPz::Rmpz_sgn($B) < 0) {

                # Support for negative B:
                #   G(a,-b) = T(b) - T(a-1) + G(a, b-1)
                # where T(n) = n*(n+1)/2

                $B = Math::GMPz::Rmpz_init_set($B);
                Math::GMPz::Rmpz_abs($B, $B);

                my $t = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_add_ui($t, $B, 1);
                Math::GMPz::Rmpz_mul($t, $t, $B);
                Math::GMPz::Rmpz_div_2exp($t, $t, 1);

                my $t2 = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_sub_ui($t2, $A, 1);
                Math::GMPz::Rmpz_mul($t2, $t2, $A);
                Math::GMPz::Rmpz_div_2exp($t2, $t2, 1);

                Math::GMPz::Rmpz_sub($t, $t, $t2);
                Math::GMPz::Rmpz_sub_ui($B, $B, 1);

                my $r = __SUB__->($A, $B);
                Math::GMPz::Rmpz_add($t, $t, $r);
                return $t;
            }

            my $t = Math::GMPz::Rmpz_init();
            my $u = Math::GMPz::Rmpz_init();
            my $v = Math::GMPz::Rmpz_init();
            my $w = Math::GMPz::Rmpz_init();

            my $T = Math::GMPz::Rmpz_init_set_ui(0);

            while (Math::GMPz::Rmpz_cmp($A, $B) <= 0) {

                Math::GMPz::Rmpz_div($t, $B, $A);
                Math::GMPz::Rmpz_div($u, $B, $t);

                # v = u*(u+1)/2
                Math::GMPz::Rmpz_add_ui($v, $u, 1);
                Math::GMPz::Rmpz_mul($v, $v, $u);
                Math::GMPz::Rmpz_div_2exp($v, $v, 1);

                # w = (a-1)*a/2
                Math::GMPz::Rmpz_sub_ui($w, $A, 1);
                Math::GMPz::Rmpz_mul($w, $w, $A);
                Math::GMPz::Rmpz_div_2exp($w, $w, 1);

                # T += t*(v - w)
                Math::GMPz::Rmpz_sub($v, $v, $w);
                Math::GMPz::Rmpz_mul($v, $v, $t);
                Math::GMPz::Rmpz_add($T, $T, $v);

                Math::GMPz::Rmpz_add_ui($A, $u, 1);
            }

            return $T;
        };

        # Optimization when n < sqrt(v)
        if (Math::GMPz::Rmpz_cmpabs($n * $n, $v) <= 0 and Math::GMPz::Rmpz_fits_ulong_p($n)) {

            my $sum = Math::GMPz::Rmpz_init_set_ui(0);

            $n = Math::GMPz::Rmpz_get_ui($n);

            if (Math::GMPz::Rmpz_fits_ulong_p($v)) {
                $v = Math::GMPz::Rmpz_get_ui($v);
                foreach my $k (1 .. $n) {
                    Math::GMPz::Rmpz_add_ui($sum, $sum, $v % $k);
                }
            }
            else {
                my $t = Math::GMPz::Rmpz_init();
                foreach my $k (1 .. $n) {
                    Math::GMPz::Rmpz_add_ui($sum, $sum, Math::GMPz::Rmpz_mod_ui($t, $v, $k));
                }
            }

            return bless \$sum;
        }

        # a(n,v) = n*v - S(v) + G(n+1, v)

        my $x = $S->($v);
        my $y = $G->($n + 1, $v);

        my $negative = 0;

        if (Math::GMPz::Rmpz_sgn($v) < 0) {
            $v = Math::GMPz::Rmpz_init_set($v);
            Math::GMPz::Rmpz_abs($v, $v);
            $negative = 1;
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul($r, $n, $v);
        Math::GMPz::Rmpz_add($r, $r, $y);
        Math::GMPz::Rmpz_sub($r, $r, $x);

        if ($negative) {
            Math::GMPz::Rmpz_neg($r, $r);
        }

        bless \$r;
    }

    *sum_of_remainders = \&sum_remainders;

    # Divisors d of n, such that d <= k, with k = n when `k` is not specified
    sub divisors {
        my ($n, $k) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new();
        Math::GMPz::Rmpz_sgn($n) > 0 or return Sidef::Types::Array::Array->new();

        if (defined($k)) {
            _valid(\$k);

            $k = _any2mpz($$k) // return Sidef::Types::Array::Array->new();

            Math::GMPz::Rmpz_sgn($k) > 0
              or return Sidef::Types::Array::Array->new();

            my @factors;

            if (   !Math::GMPz::Rmpz_fits_ulong_p($n)
                and Math::GMPz::Rmpz_cmp_ui($n, $k) > 0
                and ($k <= 1e6 or $k == 1e7 or $k == 1e8)) {
                (undef, @factors) = _primorial_trial_factor($n, Math::GMPz::Rmpz_get_ui($k));
            }
            else {
                @factors = grep { Math::GMPz::Rmpz_init_set_str($_, 10) <= $k } _factor($n);
            }

            @factors || return Sidef::Types::Array::Array->new([ONE]);

            my %table;
            ++$table{$_} for @factors;

            my @d = (Math::GMPz::Rmpz_init_set_ui(1));
            state $t = Math::GMPz::Rmpz_init_nobless();

            foreach my $p (sort { Math::GMPz::Rmpz_cmp($a, $b) } map { Math::GMPz::Rmpz_init_set_str($_, 10) } keys %table) {

                my @t;
                my $r = Math::GMPz::Rmpz_init_set_ui(1);

                for my $i (1 .. $table{$p}) {
                    Math::GMPz::Rmpz_mul($r, $r, $p);
                    foreach my $u (@d) {
                        my $prod = $u * $r;
                        push(@t, $prod) if (Math::GMPz::Rmpz_cmp($prod, $k) <= 0);
                    }
                }

                push @d, @t;
            }

            return Sidef::Types::Array::Array->new([map { bless \$_ } sort { Math::GMPz::Rmpz_cmp($a, $b) } @d]);
        }

        if (HAS_PRIME_UTIL && Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return Sidef::Types::Array::Array->new(
                                              [map { _set_int($_) } Math::Prime::Util::divisors(Math::GMPz::Rmpz_get_ui($n))]);
        }

        Sidef::Types::Array::Array->new([map { _set_int($_) } _divisors($n)]);
    }

    sub udivisors {
        my ($n) = @_;

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new();

        my @d;
        foreach my $pe (_factor_exp($n)) {
            my ($p, $e) = @$pe;

            my $pp;

            if ($e <= 2) {    # p^e where e <= 2

                if ($p < ULONG_MAX) {
                    $pp = Math::GMPz::Rmpz_init_set_ui($p);
                }
                else {
                    $pp = Math::GMPz::Rmpz_init_set_str("$p", 10);
                }

                if ($e == 2) {
                    Math::GMPz::Rmpz_mul($pp, $pp, $pp);
                }
            }
            else {    # p^e where e >= 3

                $pp = Math::GMPz::Rmpz_init();

                if ($p < ULONG_MAX) {
                    Math::GMPz::Rmpz_ui_pow_ui($pp, $p, $e);
                }
                else {
                    Math::GMPz::Rmpz_set_str($pp, $p, 10);
                    Math::GMPz::Rmpz_pow_ui($pp, $pp, $e);
                }
            }

            my @t;

            foreach my $d (@d) {
                my $t = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_mul($t, $d, $pp);
                push @t, $t;
            }

            push @d, $pp;
            push @d, @t;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        unshift @d, ONE;

        Sidef::Types::Array::Array->new(\@d);
    }

    *unitary_divisors = \&udivisors;

    sub edivisors {    # OEIS: A322791
        my ($n) = @_;

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new();

        my @d = (Math::GMPz::Rmpz_init_set_ui(1));
        my $r = Math::GMPz::Rmpz_init();

        foreach my $pe (_factor_exp($n)) {
            my ($p, $e) = @$pe;

            my @t;
            foreach my $k (_divisors($e)) {

                if ($p < ULONG_MAX) {
                    Math::GMPz::Rmpz_ui_pow_ui($r, $p, $k);
                }
                else {
                    Math::GMPz::Rmpz_set_str($r, $p, 10);
                    Math::GMPz::Rmpz_pow_ui($r, $r, $k) if ($k > 1);
                }

                foreach my $u (@d) {
                    my $t = Math::GMPz::Rmpz_init();
                    Math::GMPz::Rmpz_mul($t, $u, $r);
                    push @t, $t;
                }
            }

            @d = @t;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        Sidef::Types::Array::Array->new(\@d);
    }

    *exponential_divisors = \&edivisors;

    sub idivisors {    # OEIS: A077609
        my ($n) = @_;

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new();

        my @d = ($ONE);
        my $r = Math::GMPz::Rmpz_init();

        foreach my $pe (_factor_exp($n)) {
            my ($p, $e) = @$pe;

            $p =
              ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_init_set_ui($p)
              : Math::GMPz::Rmpz_init_set_str("$p", 10);

            my @t;
            Math::GMPz::Rmpz_set($r, $p);

            foreach my $k (1 .. $e) {

                if (($e & $k) == $k) {
                    foreach my $u (@d) {
                        my $t = Math::GMPz::Rmpz_init();
                        Math::GMPz::Rmpz_mul($t, $u, $r);
                        push @t, $t;
                    }
                }

                Math::GMPz::Rmpz_mul($r, $r, $p) if ($k < $e);
            }

            push @d, @t;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        Sidef::Types::Array::Array->new(\@d);
    }

    *infinitary_divisors = \&idivisors;

    sub biudivisors {    # OEIS: A222266
        my ($n) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new();
        Math::GMPz::Rmpz_sgn($n) > 0 or return Sidef::Types::Array::Array->new();

        my @d = ($ONE);
        my $r = Math::GMPz::Rmpz_init();
        my $w = Math::GMPz::Rmpz_init();

        foreach my $pe (_factor_exp($n)) {
            my ($p, $e) = @$pe;

            $p =
              ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_init_set_ui($p)
              : Math::GMPz::Rmpz_init_set_str("$p", 10);

            my @t;
            Math::GMPz::Rmpz_set($r, $p);

            foreach my $k (1 .. $e) {

                Math::GMPz::Rmpz_divexact($w, $n, $r);

                if ((bless \$w)->gcud(bless \$r)->is_one) {
                    foreach my $u (@d) {
                        my $t = Math::GMPz::Rmpz_init();
                        Math::GMPz::Rmpz_mul($t, $u, $r);
                        push @t, $t;
                    }
                }

                Math::GMPz::Rmpz_mul($r, $r, $p) if ($k < $e);
            }

            push @d, @t;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        Sidef::Types::Array::Array->new(\@d);
    }

    *bdivisors           = \&biudivisors;
    *bi_unitary_divisors = \&biudivisors;

    sub prime_power_divisors {

        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();
        my $u = Math::GMPz::Rmpz_init();

        my @d;
        foreach my $pe (_factor_exp($n)) {
            my ($p, $e) = @$pe;

            $p =
              ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_init_set_ui($p)
              : Math::GMPz::Rmpz_init_set_str("$p", 10);

            push @d, $p;
            next if ($e == 1);

            Math::GMPz::Rmpz_set($u, $p);

            foreach my $i (2 .. $e) {
                Math::GMPz::Rmpz_mul($u, $u, $p);
                push @d, Math::GMPz::Rmpz_init_set($u);
            }
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        Sidef::Types::Array::Array->new(\@d);
    }

    sub prime_power_udivisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my @d;
        foreach my $pe (_factor_exp($n)) {
            my ($p, $e) = @$pe;

            my $pp;

            if ($e <= 2) {    # p^e where e <= 2

                if ($p < ULONG_MAX) {
                    $pp = Math::GMPz::Rmpz_init_set_ui($p);
                }
                else {
                    $pp = Math::GMPz::Rmpz_init_set_str("$p", 10);
                }

                if ($e == 2) {
                    Math::GMPz::Rmpz_mul($pp, $pp, $pp);
                }
            }
            else {    # p^e where e >= 3

                $pp = Math::GMPz::Rmpz_init();

                if ($p < ULONG_MAX) {
                    Math::GMPz::Rmpz_ui_pow_ui($pp, $p, $e);
                }
                else {
                    Math::GMPz::Rmpz_set_str($pp, $p, 10);
                    Math::GMPz::Rmpz_pow_ui($pp, $pp, $e);
                }
            }

            push @d, $pp;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        Sidef::Types::Array::Array->new(\@d);
    }

    *prime_power_unitary_divisors = \&prime_power_udivisors;
    *unitary_prime_power_divisors = \&prime_power_udivisors;

    sub powerfree_divisors {
        my ($k, $n) = @_;

        _valid(\$n);

        $n = _big2pistr($$n) // return Sidef::Types::Array::Array->new();
        $k = _any2ui($$k) || return Sidef::Types::Array::Array->new();

        if ($k == 1) {
            return Sidef::Types::Array::Array->new([ONE]);
        }

        my $r = Math::GMPz::Rmpz_init();

        my @d;
        foreach my $pe (_factor_exp($n)) {
            my ($p, $e) = @$pe;

            $p =
              ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_init_set_ui($p)
              : Math::GMPz::Rmpz_init_set_str("$p", 10);

            if ($k <= $e) {
                $e = $k - 1;
            }

            Math::GMPz::Rmpz_set($r, $p);

            my @t;
            foreach my $i (1 .. $e) {
                foreach my $d (@d) {
                    my $t = Math::GMPz::Rmpz_init();
                    Math::GMPz::Rmpz_mul($t, $r, $d);
                    push @t, $t;
                }
                push @t, Math::GMPz::Rmpz_init_set($r);
                Math::GMPz::Rmpz_mul($r, $r, $p) if ($i < $e);
            }

            push @d, @t;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        unshift @d, ONE;

        Sidef::Types::Array::Array->new(\@d);
    }

    sub squarefree_divisors {
        (TWO)->powerfree_divisors($_[0]);
    }

    my $power_divisors_func = sub {
        my ($k, $factor_exp) = @_;

        my @d = ($ONE);
        my $r = Math::GMPz::Rmpz_init();

        foreach my $pe (grep { $_->[1] >= $k } @$factor_exp) {

            my ($p, $e) = @$pe;

            $p =
              ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_init_set_ui($p)
              : Math::GMPz::Rmpz_init_set_str("$p", 10);

            my @t;
            for (my $i = $k ; $i <= $e ; $i += $k) {

                Math::GMPz::Rmpz_pow_ui($r, $p, $i);

                foreach my $d (@d) {
                    my $z = Math::GMPz::Rmpz_init();
                    Math::GMPz::Rmpz_mul($z, $r, $d);
                    push @t, $z;
                }
            }

            push @d, @t;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        Sidef::Types::Array::Array->new(\@d);
    };

    sub power_divisors {
        my ($k, $n) = @_;

        _valid(\$n);

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new();
        $k = _any2ui($$k) || return Sidef::Types::Array::Array->new();

        $power_divisors_func->($k, [_factor_exp($n)]);
    }

    sub perfect_power_divisors {
        my ($n) = @_;

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new();

        my @lists;
        my @factor_exp = _factor_exp($n);
        my $max_k      = List::Util::max(map { $_->[1] } @factor_exp);

        if (!defined($max_k) or $max_k == 1) {
            return Sidef::Types::Array::Array->new([ONE]);
        }

        foreach my $k (2 .. $max_k) {
            push @lists, $power_divisors_func->($k, \@factor_exp);
        }

        Sidef::Types::Array::Array->new([map { @$_ } @lists])->sort->uniq;
    }

    *pp_divisors = \&perfect_power_divisors;

    sub square_divisors {
        (TWO)->power_divisors($_[0]);
    }

    my $power_udivisors_func = sub {
        my ($k, $factor_exp) = @_;

        my @d = ($ONE);
        foreach my $pe (grep { $_->[1] % $k == 0 } @$factor_exp) {
            my ($p, $e) = @$pe;

            my $pp = (
                      ($p < ULONG_MAX)
                      ? Math::GMPz::Rmpz_init_set_ui($p)
                      : Math::GMPz::Rmpz_init_set_str("$p", 10)
                     );

            if ($e == 2) {
                Math::GMPz::Rmpz_mul($pp, $pp, $pp);
            }
            else {
                Math::GMPz::Rmpz_pow_ui($pp, $pp, $e);
            }

            my @t;
            foreach my $d (@d) {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_mul($z, $pp, $d);
                push @t, $z;
            }
            push @d, @t;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        Sidef::Types::Array::Array->new(\@d);
    };

    sub power_udivisors {
        my ($k, $n) = @_;

        _valid(\$n);

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new();
        $k = _any2ui($$k) || return Sidef::Types::Array::Array->new();

        return $power_udivisors_func->($k, [_factor_exp($n)]);
    }

    *unitary_power_divisors = \&power_udivisors;
    *power_unitary_divisors = \&power_udivisors;

    sub perfect_power_udivisors {
        my ($n) = @_;

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new();

        my @lists;
        my @factor_exp = _factor_exp($n);
        my $max_k      = List::Util::max(map { $_->[1] } @factor_exp);

        if (!defined($max_k) or $max_k == 1) {
            return Sidef::Types::Array::Array->new([ONE]);
        }

        foreach my $k (2 .. $max_k) {
            push @lists, $power_udivisors_func->($k, \@factor_exp);
        }

        Sidef::Types::Array::Array->new([map { @$_ } @lists])->sort->uniq;
    }

    *pp_udivisors                   = \&perfect_power_udivisors;
    *perfect_power_unitary_divisors = \&perfect_power_udivisors;

    sub square_udivisors {
        (TWO)->power_udivisors($_[0]);
    }

    *unitary_square_divisors = \&square_udivisors;
    *square_unitary_divisors = \&square_udivisors;

    sub powerfree_udivisors {
        my ($k, $n) = @_;

        _valid(\$n);

        $n = _big2pistr($$n) // return Sidef::Types::Array::Array->new();
        $k = _any2ui($$k) || return Sidef::Types::Array::Array->new();

        if ($k == 1) {
            return Sidef::Types::Array::Array->new([ONE]);
        }

        my @d;
        foreach my $pe (_factor_exp($n)) {
            my ($p, $e) = @$pe;

            $e < $k or next;

            my $r = Math::GMPz::Rmpz_init();

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($r, $p, $e);
            }
            else {
                Math::GMPz::Rmpz_set_str($r, "$p", 10);
                Math::GMPz::Rmpz_pow_ui($r, $r, $e);
            }

            my @tmp = ($r);

            foreach my $d (@d) {
                my $t = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_mul($t, $d, $r);
                push @tmp, $t;
            }

            push @d, @tmp;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        unshift @d, ONE;

        Sidef::Types::Array::Array->new(\@d);
    }

    *unitary_powerfree_divisors = \&powerfree_udivisors;
    *powerfree_unitary_divisors = \&powerfree_udivisors;

    sub squarefree_udivisors {
        (TWO)->powerfree_udivisors($_[0]);
    }

    *unitary_squarefree_divisors = \&squarefree_udivisors;
    *squarefree_unitary_divisors = \&squarefree_udivisors;

    sub prime_divisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my @d;
        foreach my $pk (_factor_exp($n)) {
            my $p = $pk->[0];
            push @d, _set_int($p);
        }

        Sidef::Types::Array::Array->new(\@d);
    }

    sub prime_udivisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my @d;
        foreach my $pk (_factor_exp($n)) {
            if ($pk->[1] == 1) {
                my $p = $pk->[0];
                push @d, _set_int($p);
            }
        }

        Sidef::Types::Array::Array->new(\@d);
    }

    *unitary_prime_divisors = \&prime_udivisors;
    *prime_unitary_divisors = \&prime_udivisors;

    sub exp_mangoldt {
        my $n = Math::Prime::Util::GMP::exp_mangoldt(&_big2uistr || return ONE);
        $n eq '1' and return ONE;
        _set_int($n);
    }

    sub mangoldt {
        $_[0]->exp_mangoldt->log;
    }

    sub primitive_part {
        my ($n, $f) = @_;
        $f // return $n->exp_mangoldt;
        my $z = _any2mpz($$n) // goto &nan;

        my (@u, @v);

        foreach my $d (@{$n->squarefree_divisors}) {
            my $t = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_divexact($t, $z, $$d);

            my $r = $f->run(bless \$t);
            my $m = Math::Prime::Util::GMP::moebius($$d);

            ($m == 1) ? push(@u, $$r) : push(@v, $$r);
        }

        my $u = @u ? _binsplit(\@u, \&__mul__) : $ONE;
        my $v = @v ? _binsplit(\@v, \&__mul__) : $ONE;

        bless \__div__($u, $v);
    }

    sub totient {
        my ($n) = @_;

        if (HAS_PRIME_UTIL and ref($$n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($$n)) {
            my $r = Math::Prime::Util::euler_phi(Math::GMPz::Rmpz_get_ui($$n));
            return _set_int($r);
        }

        my $r = Math::Prime::Util::GMP::totient(&_big2uistr // goto &nan);
        _set_int($r);
    }

    *EulerPhi      = \&totient;
    *eulerphi      = \&totient;
    *euler_phi     = \&totient;
    *euler_totient = \&totient;

    sub _n_over_d_divisors {
        my ($N, $d, $u, $D) = @_;

        # N = a positive integer
        # d = a divisor of N
        # u = temporary Math::GMPz object
        # D = array ref with divisors of N

        Math::GMPz::Rmpz_divexact($u, $N, $d);

        # When u = N/d is a native integer, call Math::Prime::Util::divisors().
        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($u)) {
            return Math::Prime::Util::divisors(Math::GMPz::Rmpz_get_ui($u));
        }

        # When N has too many divisors, it's faster
        # to simply compute the divisors of u = N/d
        if (scalar(@$D) > 1e4) {
            return _divisors($u);
        }

        # Otherwise, select the divisors of N/d from the divisors of N
        my @divisors;
        my $d_str = Math::GMPz::Rmpz_get_str($d, 10);

        foreach my $k (@$D) {

            if ($k < ULONG_MAX) {
                Math::GMPz::Rmpz_gcd_ui($u, $d, $k);
            }
            else {
                Math::GMPz::Rmpz_set_str($u, $k, 10);
                Math::GMPz::Rmpz_gcd($u, $u, $d);
            }

            if (Math::GMPz::Rmpz_cmp($u, $d) == 0) {
                push @divisors, Math::Prime::Util::GMP::divint($k, $d_str);
            }
        }

        return @divisors;
    }

    sub _dynamic_preimage {
        my ($N, $L, $D, %opt) = @_;

        # Based on invphi.gp ver. 2.1 by Max Alekseyev.

        my %R = (1 => [$ONE]);
        my $u = Math::GMPz::Rmpz_init();

        my $unitary = $opt{unitary};

        foreach my $l (@$L) {
            my %t;

            foreach my $pair (@$l) {
                my ($x, $y) = @$pair;

                foreach my $d (_n_over_d_divisors($N, $x, $u, $D)) {
                    if (exists $R{$d}) {

                        ($d < ULONG_MAX)
                          ? Math::GMPz::Rmpz_mul_ui($u, $x, $d)
                          : do {
                            Math::GMPz::Rmpz_set_str($u, $d, 10);
                            Math::GMPz::Rmpz_mul($u, $u, $x);
                          };

                        my $key  = Math::GMPz::Rmpz_get_str($u, 10);
                        my @list = @{$R{$d}};

                        if ($unitary) {
                            @list = grep {
                                Math::GMPz::Rmpz_gcd($u, $y, $_);
                                Math::GMPz::Rmpz_cmp_ui($u, 1) == 0;
                            } @list;
                        }

                        push @{$t{$key}}, map {
                            my $w = Math::GMPz::Rmpz_init();
                            Math::GMPz::Rmpz_mul($w, $y, $_);
                            $w;
                        } @list;
                    }
                }
            }

            while (my ($key, $value) = each %t) {
                push @{$R{$key}}, @$value;
            }
        }

        $R{$N} // [];
    }

    sub _dynamic_preimage_minmax {
        my ($N, $L, $D, %opt) = @_;

        # Based on invphi.gp ver. 2.1 by Max Alekseyev.

        my %R = (1 => $ONE);

        my $u = Math::GMPz::Rmpz_init();
        my $w = Math::GMPz::Rmpz_init();

        my $min = $opt{min};

        foreach my $l (@$L) {
            my %t;

            foreach my $pair (@$l) {
                my ($x, $y) = @$pair;

                foreach my $d (_n_over_d_divisors($N, $x, $u, $D)) {
                    if (exists $R{$d}) {

                        ($d < ULONG_MAX)
                          ? Math::GMPz::Rmpz_mul_ui($u, $x, $d)
                          : do {
                            Math::GMPz::Rmpz_set_str($u, $d, 10);
                            Math::GMPz::Rmpz_mul($u, $u, $x);
                          };

                        my $key = Math::GMPz::Rmpz_get_str($u, 10);

                        Math::GMPz::Rmpz_mul($w, $y, $R{$d});

                        if (
                            !exists($t{$key})
                            or (
                                $min
                                ? (Math::GMPz::Rmpz_cmp($w, $t{$key}) < 0)
                                : (Math::GMPz::Rmpz_cmp($w, $t{$key}) > 0)
                               )
                          ) {
                            $t{$key} = Math::GMPz::Rmpz_init_set($w);
                        }
                    }
                }
            }

            while (my ($key, $value) = each %t) {
                if (
                    !exists($R{$key})
                    or (
                        $min
                        ? (Math::GMPz::Rmpz_cmp($value, $R{$key}) < 0)
                        : (Math::GMPz::Rmpz_cmp($value, $R{$key}) > 0)
                       )
                  ) {
                    $R{$key} = $value;
                }
            }
        }

        $R{$N};
    }

    sub _dynamic_preimage_len_bigint {
        my ($N, $L, $D) = @_;

        # Based on invphi.gp ver. 2.1 by Max Alekseyev.

        my %R = (1 => Math::GMPz::Rmpz_init_set_ui(1));
        my $u = Math::GMPz::Rmpz_init();

        foreach my $l (@$L) {
            my %t;

            foreach my $pair (@$l) {

                my $x = $pair->[0];

                foreach my $d (_n_over_d_divisors($N, $x, $u, $D)) {
                    if (exists $R{$d}) {

                        ($d < ULONG_MAX)
                          ? Math::GMPz::Rmpz_mul_ui($u, $x, $d)
                          : do {
                            Math::GMPz::Rmpz_set_str($u, $d, 10);
                            Math::GMPz::Rmpz_mul($u, $u, $x);
                          };

                        my $key = Math::GMPz::Rmpz_get_str($u, 10);

                        if (!exists $t{$key}) {
                            $t{$key} = Math::GMPz::Rmpz_init_set_ui(0);
                        }

                        Math::GMPz::Rmpz_add($t{$key}, $t{$key}, $R{$d});
                    }
                }
            }

            while (my ($key, $value) = each %t) {
                if (!exists $R{$key}) {
                    $R{$key} = Math::GMPz::Rmpz_init_set_ui(0);
                }
                Math::GMPz::Rmpz_add($R{$key}, $R{$key}, $value);
            }
        }

        if (exists $R{$N}) {
            return Math::GMPz::Rmpz_get_str($R{$N}, 10);
        }

        return 0;
    }

    sub _dynamic_preimage_len {
        my ($N, $L, $D) = @_;

        # Based on invphi.gp ver. 2.1 by Max Alekseyev.

        my %R = (1 => 1);
        my $u = Math::GMPz::Rmpz_init();

        foreach my $l (@$L) {
            my %t;

            foreach my $pair (@$l) {

                my $x = $pair->[0];

                foreach my $d (_n_over_d_divisors($N, $x, $u, $D)) {
                    if (exists $R{$d}) {

                        ($d < ULONG_MAX)
                          ? Math::GMPz::Rmpz_mul_ui($u, $x, $d)
                          : do {
                            Math::GMPz::Rmpz_set_str($u, $d, 10);
                            Math::GMPz::Rmpz_mul($u, $u, $x);
                          };

                        $t{Math::GMPz::Rmpz_get_str($u, 10)} += $R{$d};
                    }
                }
            }

            while (my ($key, $value) = each %t) {
                $R{$key} += $value;
            }
        }

        my $r = $R{$N} // 0;
        ($r < ~0) || goto &_dynamic_preimage_len_bigint;
        return $r;
    }

    sub _cook_euler_phi {
        my ($N) = @_;

        my $p = Math::GMPz::Rmpz_init();
        my $v = Math::GMPz::Rmpz_init();

        my %L;
        my @D = _divisors($N);

        foreach my $d (@D) {

            Math::Prime::Util::GMP::is_prime(Math::Prime::Util::GMP::addint($d, 1)) || next;

            ($d < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($p, $d)
              : Math::GMPz::Rmpz_set_str($p, $d, 10);

            Math::GMPz::Rmpz_add_ui($p, $p, 1);

            my $t = Math::GMPz::Rmpz_remove($v, $N, $p);

            push @{$L{$p}}, map {

                # [(p-1)*p^(k-1), p^k]

                my $x = Math::GMPz::Rmpz_init();
                my $y = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_pow_ui($v, $p, $_ - 1);
                Math::GMPz::Rmpz_pow_ui($y, $p, $_);

                Math::GMPz::Rmpz_sub_ui($x, $p, 1);
                Math::GMPz::Rmpz_mul($x, $x, $v);

                [$x, $y]
            } 1 .. $t + 1;
        }

        ([values %L], \@D);
    }

    sub inverse_totient {
        my ($n) = @_;

        # Algorithm "invphi" from invphi.gp ver. 2.1 by Max Alekseyev.

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return Sidef::Types::Array::Array->new(ZERO) if !Math::GMPz::Rmpz_sgn($n);
            return Sidef::Types::Array::Array->new;
        }

#<<<
        if (HAS_NEW_PRIME_UTIL) {     # XXX: MPU 0.73 leaks memory
            return Sidef::Types::Array::Array->new([
                map {
                    ref($_) eq 'Math::GMPz'
                        ? (bless \$_)
                        : _set_int("$_")
                } Math::Prime::Util::inverse_totient($n)
            ]);
        }
#>>>

        my $result = _dynamic_preimage($n, _cook_euler_phi($n));
        Sidef::Types::Array::Array->new([map { bless \$_ } sort { Math::GMPz::Rmpz_cmp($a, $b) } @$result]);
    }

    *inverse_phi = \&inverse_totient;

    sub inverse_totient_len {
        my ($n) = @_;

        $n = _any2mpz($$n) // return ZERO;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ONE if !Math::GMPz::Rmpz_sgn($n);
            return ZERO;
        }

        my $r;

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            $r = scalar Math::Prime::Util::inverse_totient(Math::GMPz::Rmpz_get_ui($n));
        }
        else {
            $r = _dynamic_preimage_len($n, _cook_euler_phi($n));
        }

        _set_int($r);
    }

    *inverse_phi_len = \&inverse_totient_len;

    sub inverse_euler_phi_min {
        my ($n) = @_;

        $n = _any2mpz($$n) // return undef;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO if !Math::GMPz::Rmpz_sgn($n);
            return undef;
        }

        my $r = _dynamic_preimage_minmax($n, _cook_euler_phi($n), min => 1) // return undef;
        bless \$r;
    }

    *inverse_phi_min = \&inverse_euler_phi_min;

    sub inverse_euler_phi_max {
        my ($n) = @_;

        $n = _any2mpz($$n) // return undef;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO if !Math::GMPz::Rmpz_sgn($n);
            return undef;
        }

        my $r = _dynamic_preimage_minmax($n, _cook_euler_phi($n), min => 0) // return undef;
        bless \$r;
    }

    *inverse_phi_max = \&inverse_euler_phi_max;

    sub _cook_dedekind_psi {
        my ($N, $k) = @_;

        my $p = Math::GMPz::Rmpz_init();
        my $v = Math::GMPz::Rmpz_init();

        my %L;
        my @D = _divisors($N);

        foreach my $d (@D) {

            Math::Prime::Util::GMP::is_prime(Math::Prime::Util::GMP::subint($d, 1)) || next;

            ($d < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($p, $d)
              : Math::GMPz::Rmpz_set_str($p, $d, 10);

            Math::GMPz::Rmpz_sub_ui($p, $p, 1);

            my $t = Math::GMPz::Rmpz_remove($v, $N, $p);

            push @{$L{$p}}, map {

                # [(p+1)*p^(k-1), p^k]

                my $x = Math::GMPz::Rmpz_init();
                my $y = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_pow_ui($v, $p, $_ - 1);
                Math::GMPz::Rmpz_pow_ui($y, $p, $_);

                Math::GMPz::Rmpz_add_ui($x, $p, 1);
                Math::GMPz::Rmpz_mul($x, $x, $v);

                [$x, $y]
            } 1 .. $t + 1;
        }

        ([values %L], \@D);
    }

    sub inverse_dedekind_psi {
        my ($n) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return Sidef::Types::Array::Array->new(ZERO) if !Math::GMPz::Rmpz_sgn($n);
            return Sidef::Types::Array::Array->new;
        }

        my $result = _dynamic_preimage($n, _cook_dedekind_psi($n));
        Sidef::Types::Array::Array->new([map { bless \$_ } sort { Math::GMPz::Rmpz_cmp($a, $b) } @$result]);
    }

    *inverse_psi = \&inverse_dedekind_psi;

    sub inverse_dedekind_psi_len {
        my ($n) = @_;

        $n = _any2mpz($$n) // return ZERO;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ONE if !Math::GMPz::Rmpz_sgn($n);
            return ZERO;
        }

        my $r = _dynamic_preimage_len($n, _cook_dedekind_psi($n));
        _set_int($r);
    }

    *inverse_psi_len = \&inverse_dedekind_psi_len;

    sub inverse_dedekind_psi_min {
        my ($n) = @_;

        $n = _any2mpz($$n) // return undef;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO if !Math::GMPz::Rmpz_sgn($n);
            return undef;
        }

        my $r = _dynamic_preimage_minmax($n, _cook_dedekind_psi($n), min => 1) // return undef;
        bless \$r;
    }

    *inverse_psi_min = \&inverse_dedekind_psi_min;

    sub inverse_dedekind_psi_max {
        my ($n) = @_;

        $n = _any2mpz($$n) // return undef;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO if !Math::GMPz::Rmpz_sgn($n);
            return undef;
        }

        my $r = _dynamic_preimage_minmax($n, _cook_dedekind_psi($n), min => 0) // return undef;
        bless \$r;
    }

    *inverse_psi_max = \&inverse_dedekind_psi_max;

    sub _cook_usigma {
        my ($N) = @_;

        my %L;
        my @D = _divisors($N);

        foreach my $d (@D) {

            Math::Prime::Util::GMP::is_prime_power(Math::Prime::Util::GMP::subint($d, 1)) || next;

            my $u = Math::GMPz::Rmpz_init();
            my $v = Math::GMPz::Rmpz_init();

            ($d < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($u, $d)
              : Math::GMPz::Rmpz_set_str($u, $d, 10);

            Math::GMPz::Rmpz_sub_ui($v, $u, 1);

            push @{$L{$v}}, [$u, $v];
        }

        ([values %L], \@D);
    }

    sub inverse_usigma {
        my ($n) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return Sidef::Types::Array::Array->new(ZERO) if !Math::GMPz::Rmpz_sgn($n);
            return Sidef::Types::Array::Array->new;
        }

        my $result = _dynamic_preimage($n, _cook_usigma($n), unitary => 1);
        Sidef::Types::Array::Array->new([map { bless \$_ } sort { Math::GMPz::Rmpz_cmp($a, $b) } @$result]);
    }

    sub _cook_uphi {
        my ($N) = @_;

        my %L;
        my @D = _divisors($N);

        foreach my $d (@D) {

            Math::Prime::Util::GMP::is_prime_power(Math::Prime::Util::GMP::addint($d, 1)) || next;

            my $u = Math::GMPz::Rmpz_init();
            my $v = Math::GMPz::Rmpz_init();

            ($d < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($u, $d)
              : Math::GMPz::Rmpz_set_str($u, $d, 10);

            Math::GMPz::Rmpz_add_ui($v, $u, 1);

            push @{$L{$v}}, [$u, $v];
        }

        ([values %L], \@D);
    }

    sub inverse_uphi {
        my ($n) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return Sidef::Types::Array::Array->new(ZERO) if !Math::GMPz::Rmpz_sgn($n);
            return Sidef::Types::Array::Array->new;
        }

        my $result = _dynamic_preimage($n, _cook_uphi($n), unitary => 1);
        Sidef::Types::Array::Array->new([map { bless \$_ } sort { Math::GMPz::Rmpz_cmp($a, $b) } @$result]);
    }

    sub _cook_sigma {
        my ($N, $k) = @_;

        # Based on invphi.gp ver. 2.1 by Max Alekseyev.

        my $q = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $v = Math::GMPz::Rmpz_init();

        my %L;
        my @D = _divisors($N);

        foreach my $d (@D) {

            next if ($d == 1);

            ($d < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($u, $d)
              : Math::GMPz::Rmpz_set_str($u, $d, 10);

            foreach my $p (map { $_->[0] } _factor_exp(Math::Prime::Util::GMP::subint($d, 1))) {

                ($p < ULONG_MAX)
                  ? Math::GMPz::Rmpz_set_ui($s, $p)
                  : Math::GMPz::Rmpz_set_str($s, $p, 10);

                Math::GMPz::Rmpz_set($q, $s);
                Math::GMPz::Rmpz_pow_ui($q, $q, $k) if ($k > 1);

                # q = d*(p^k - 1) + 1
                Math::GMPz::Rmpz_sub_ui($q, $q, 1);
                Math::GMPz::Rmpz_mul($q, $q, $u);
                Math::GMPz::Rmpz_add_ui($q, $q, 1);

                my $t = Math::GMPz::Rmpz_remove($v, $q, $s);

                next if (($t <= $k) || ($t % $k));

                Math::GMPz::Rmpz_pow_ui($v, $s, $t);
                Math::GMPz::Rmpz_cmp($v, $q) == 0 or next;

                if ($k == 1) {
                    Math::GMPz::Rmpz_divexact($v, $v, $s);
                }
                else {
                    Math::GMPz::Rmpz_pow_ui($v, $s, Math::Prime::Util::GMP::divint($t, $k) - 1);
                }

                push @{$L{$p}}, [Math::GMPz::Rmpz_init_set($u), Math::GMPz::Rmpz_init_set($v)];
            }
        }

        ([values %L], \@D);
    }

    sub inverse_sigma {
        my ($n, $k) = @_;

        # Algorithm "invsigma" from invphi.gp ver. 2.1 by Max Alekseyev.

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;
        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // return Sidef::Types::Array::Array->new } : 1;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return Sidef::Types::Array::Array->new(ZERO) if !Math::GMPz::Rmpz_sgn($n);
            return Sidef::Types::Array::Array->new;
        }

        my $result = _dynamic_preimage($n, _cook_sigma($n, $k));
        Sidef::Types::Array::Array->new([map { bless \$_ } sort { Math::GMPz::Rmpz_cmp($a, $b) } @$result]);
    }

    sub inverse_sigma_len {
        my ($n, $k) = @_;

        $n = _any2mpz($$n) // return ZERO;
        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // return ZERO } : 1;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ONE if !Math::GMPz::Rmpz_sgn($n);
            return ZERO;
        }

        my $r = _dynamic_preimage_len($n, _cook_sigma($n, $k));
        _set_int($r);
    }

    sub inverse_sigma_min {
        my ($n, $k) = @_;

        $n = _any2mpz($$n) // return undef;
        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // return undef } : 1;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO if !Math::GMPz::Rmpz_sgn($n);
            return undef;
        }

        my $r = _dynamic_preimage_minmax($n, _cook_sigma($n, $k), min => 1) // return undef;
        bless \$r;
    }

    sub inverse_sigma_max {
        my ($n, $k) = @_;

        $n = _any2mpz($$n) // return undef;
        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // return undef } : 1;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO if !Math::GMPz::Rmpz_sgn($n);
            return undef;
        }

        my $r = _dynamic_preimage_minmax($n, _cook_sigma($n, $k), min => 0) // return undef;
        bless \$r;
    }

    sub jordan_totient {
        my ($n, $k) = @_;
        $k //= ONE;
        _valid(\$k);
        my $r = Math::Prime::Util::GMP::jordan_totient(_big2uistr($k) // (goto &nan), _big2uistr($n) // (goto &nan));
        _set_int($r);
    }

    *JordanTotient = \&jordan_totient;

    sub dedekind_psi {
        my ($n, $k) = @_;

        # Multiplicative with:
        #   a(p^e, k) = p^(k*e) + p^(k*e - k)

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;

        return $n->usigma0 if ($k == 0);

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        state $t = Math::GMPz::Rmpz_init_nobless();
        state $u = Math::GMPz::Rmpz_init_nobless();

        my $r = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            if ($e == 1) {
                if ($p < ULONG_MAX) {
                    Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k);
                }
                else {
                    Math::GMPz::Rmpz_set_str($t, $p, 10);
                    Math::GMPz::Rmpz_pow_ui($t, $t, $k) if ($k > 1);
                }

                Math::GMPz::Rmpz_add_ui($t, $t, 1);
                Math::GMPz::Rmpz_mul($r, $r, $t);
                next;
            }

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k * $e);
                Math::GMPz::Rmpz_ui_pow_ui($u, $p, $k * ($e - 1));
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_set($u, $t);
                Math::GMPz::Rmpz_pow_ui($t, $t, $k * $e);
                Math::GMPz::Rmpz_pow_ui($u, $u, $k * ($e - 1));
            }

            Math::GMPz::Rmpz_add($t, $t, $u);
            Math::GMPz::Rmpz_mul($r, $r, $t);
        }

        bless \$r;
    }

    *psi         = \&dedekind_psi;
    *DedekindPsi = \&dedekind_psi;

    sub carmichael_lambda {
        my ($n) = @_;

        if (HAS_PRIME_UTIL and ref($$n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($$n)) {
            my $r = Math::Prime::Util::carmichael_lambda(Math::GMPz::Rmpz_get_ui($$n));
            return _set_int($r);
        }

        my $r = Math::Prime::Util::GMP::carmichael_lambda(&_big2uistr // goto &nan);
        _set_int($r);
    }

    *lambda           = \&carmichael_lambda;
    *CarmichaelLambda = \&carmichael_lambda;

    sub liouville {
        my ($n) = @_;

        my $r;
        if (HAS_PRIME_UTIL and ref($$n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($$n)) {
            $r = Math::Prime::Util::liouville(Math::GMPz::Rmpz_get_ui($$n));
        }
        else {
            $r = Math::Prime::Util::GMP::liouville(&_big2uistr // goto &nan);
        }
        $r == 1 ? ONE : MONE;
    }

    *Liouville = \&liouville;

    sub bigomega {
        my ($n, $m) = @_;

        $m = defined($m) ? do { _valid(\$m); _any2ui($$m) // goto &nan } : 0;

        $n = _big2uistr($n) // goto &nan;
        $n eq '0' and return ZERO;

        my @factors = _factor($n);

        if ($m == 0) {
            return _set_int(scalar @factors);
        }

        # Ω_m(n) = Sum_{p^k|n} Sum_{j=1..k} n^m / p^(j*m)
        #        = Sum_{p^k|n} n^m * (p^(m*k) - 1) / (p^m - 1) / p^(m*k)

        my %factors;
        ++$factors{$_} for @factors;

        my $t  = Math::GMPz::Rmpz_init();
        my $u  = Math::GMPz::Rmpz_init();
        my $nm = Math::GMPz::Rmpz_init_set_str($n, 10);

        Math::GMPz::Rmpz_pow_ui($nm, $nm, $m) if $m > 1;

        my $sum = Math::GMPz::Rmpz_init_set_ui(0);

        while (my ($p, $k) = each %factors) {

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($u, $p, $m);    # u = p^m
            }
            else {
                Math::GMPz::Rmpz_set_str($u, $p, 10);
                Math::GMPz::Rmpz_pow_ui($u, $u, $m);       # u = p^m
            }

            Math::GMPz::Rmpz_pow_ui($t, $u, $k);      # t = (p^m)^k = p^(m*k)
            Math::GMPz::Rmpz_sub_ui($u, $u, 1);       # u = p^m - 1
            Math::GMPz::Rmpz_mul($u, $u, $t);         # u = (p^m - 1) * p^(m*k)
            Math::GMPz::Rmpz_sub_ui($t, $t, 1);       # t = p^(m*k) - 1
            Math::GMPz::Rmpz_mul($t, $t, $nm);        # t = n^m * (p^(m*k) - 1)
            Math::GMPz::Rmpz_divexact($t, $t, $u);    # t = (n^m * (p^(m*k) - 1)) / ((p^m - 1) * p^(m*k))

            Math::GMPz::Rmpz_add($sum, $sum, $t);
        }

        bless \$sum;
    }

    *Ω     = \&bigomega;
    *Omega = \&bigomega;

    sub prime_power_sigma0 {
        $_[0]->bigomega;
    }

    sub omega {
        my ($n, $m) = @_;

        $m = defined($m) ? do { _valid(\$m); _any2ui($$m) // goto &nan } : 0;
        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        if ($m == 0) {
            return _set_int(scalar @factor_exp);
        }

        # omega_m(n) = n^m * Sum_{p|n} 1/p^m

        my $t  = Math::GMPz::Rmpz_init();
        my $nm = Math::GMPz::Rmpz_init_set_str($n, 10);

        Math::GMPz::Rmpz_pow_ui($nm, $nm, $m) if $m > 1;

        my $sum = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $pe (@factor_exp) {

            my $p = $pe->[0];

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $m);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $m);
            }

            Math::GMPz::Rmpz_divexact($t, $nm, $t);
            Math::GMPz::Rmpz_add($sum, $sum, $t);
        }

        bless \$sum;
    }

    *ω = \&omega;

    sub prime_sigma0 {
        $_[0]->omega;
    }

    sub prime_power_usigma0 {
        $_[0]->omega;
    }

    sub usigma0 {

        # Identity:
        #   usigma0(n) = 2^omega(n)

        my $n = &_big2uistr // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_setbit($r, scalar @factor_exp);
        bless \$r;
    }

    sub usigma {
        my ($n, $k) = @_;

        # Interesting identity:
        #   usigma(n, k) = sigma(n^(2*k) / rad(n)) / sigma(n^k / rad(n))

        # Multiplicative with:
        #   usigma(p^e, k) = p^(k*e) + 1

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;

        if ($k == 0) {
            goto &usigma0;
        }

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k * $e);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $k * $e);
            }

            Math::GMPz::Rmpz_add_ui($t, $t, 1);
            Math::GMPz::Rmpz_mul($s, $s, $t);
        }

        bless \$s;
    }

    sub nisigma0 {    # A348341: count non-infinitary divisors of n
        my ($n) = @_;
        $n->sigma0->sub($n->isigma0);
    }

    sub nisigma {     # A348271: sum of non-infinitary divisors of n
        my ($n, $k) = @_;
        $n->sigma($k)->sub($n->isigma($k));
    }

    sub nusigma0 {    # A048105: count of non-unitary divisors of n
        my ($n) = @_;
        $n->sigma0->sub($n->usigma0);
    }

    sub nusigma {     # A048146: sum of non-unitary divisors of n
        my ($n, $k) = @_;
        $n->sigma($k)->sub($n->usigma($k));
    }

    sub bsigma0 {     # A286324: count of bi-unitary divisors of n.

        # Multiplicative with:
        #   a(p^e) = e + (e mod 2)

        my $n = &_big2uistr // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $r = Math::Prime::Util::GMP::vecprod(map { $_->[1] + ($_->[1] % 2) } @factor_exp);
        _set_int($r);
    }

    *biusigma0 = \&bsigma0;

    sub bsigma {    # A188999: Bi-unitary sigma: sum of the bi-unitary divisors of n
        my ($n, $k) = @_;

        # Multiplicative with:
        #   bsigma(p^e, k) = (p^(k*(e+1)) - 1)/(p^k - 1)                   if e is odd
        #   bsigma(p^e, k) = (p^(k*(e+1)) - 1)/(p^k - 1) - p^(k*(e/2))     if e is even

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;

        if ($k == 0) {
            goto &bsigma0;
        }

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($u, $p, $k);
                Math::GMPz::Rmpz_pow_ui($t, $u, $e + 1);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($u, $t, $k);
                Math::GMPz::Rmpz_pow_ui($t, $u, $e + 1);
            }

            Math::GMPz::Rmpz_sub_ui($t, $t, 1);
            Math::GMPz::Rmpz_sub_ui($u, $u, 1);
            Math::GMPz::Rmpz_divexact($t, $t, $u);

            if ($e % 2 == 0) {
                Math::GMPz::Rmpz_add_ui($u, $u, 1);
                Math::GMPz::Rmpz_pow_ui($u, $u, $e >> 1);
                Math::GMPz::Rmpz_sub($t, $t, $u);
            }

            Math::GMPz::Rmpz_mul($s, $s, $t);
        }

        bless \$s;
    }

    *biusigma = \&bsigma;

    sub nbsigma0 {    # Axxxxxx: count of non-bi-unitary divisors of n
        my ($n) = @_;
        $n->sigma0->sub($n->bsigma0);
    }

    sub nbsigma {     # A319072: sum of non-bi-unitary divisors of n.
        my ($n, $k) = @_;
        $n->sigma($k)->sub($n->bsigma($k));
    }

    sub isigma0 {     # A037445: count of infinitary divisors (or i-divisors) of n
        my ($n) = @_;

        # Multiplicative with:
        #   a(p^e) = 2^hammingweight(e)

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $r = Math::Prime::Util::GMP::vecprod(
            map {
                1 << (
                      HAS_PRIME_UTIL
                      ? Math::Prime::Util::hammingweight($_->[1])
                      : Math::Prime::Util::GMP::hammingweight($_->[1])
                     )
              } @factor_exp
        );

        _set_int($r);
    }

    sub isigma {    # A049417: sum of infinitary divisors of n
        my ($n, $k) = @_;

        # Multiplicative with:
        #   If e = Sum_{k >= 0} d_k 2^k (binary representation of e), then
        #   isigma(p^e, r) = Product_{k >= 0} (p^(r*2^k*{d_k+1}) - 1)/(p^(r*2^k) - 1)

        # Simplified formula, where d_k is odd in the binary representation of e (ignore even d_k):
        #   isigma(p^e, r) = Product_{k >= 0} (p^(r * 2^k) + 1)

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;

        if ($k == 0) {
            goto &isigma0;
        }

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            Math::GMPz::Rmpz_set_ui($t, 1);

            ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($t, $p)
              : Math::GMPz::Rmpz_set_str($t, $p, 10);

            my $r = 0;
            do {
                if ($e % 2 == 1) {
                    Math::GMPz::Rmpz_pow_ui($u, $t, (1 << $r) * $k);
                    Math::GMPz::Rmpz_add_ui($u, $u, 1);
                    Math::GMPz::Rmpz_mul($s, $s, $u);
                }
                ++$r;
            } while ($e >>= 1);
        }

        bless \$s;
    }

    sub esigma0 {    # A049419: count of exponential divisors (or e-divisors) of n.
        my ($n) = @_;

        # Multiplicative with:
        #   a(p^e) = tau(e)

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $r = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pp (@factor_exp) {
            if ($pp->[1] > 1) {
                my $t = (
                         HAS_PRIME_UTIL
                         ? Math::Prime::Util::divisor_sum($pp->[1], 0)
                         : Math::Prime::Util::GMP::sigma($pp->[1], 0)
                        );
                Math::GMPz::Rmpz_mul_ui($r, $r, $t);
            }
        }

        bless \$r;
    }

    sub esigma {    # A051377: sum of exponential divisors (or e-divisors) of n
        my ($n, $k) = @_;

        # Multiplicative with:
        #   a(p^e) = Sum_{d|e} p^d

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;

        if ($k == 0) {
            goto &esigma0;
        }

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $w = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            Math::GMPz::Rmpz_set_ui($t, 1);

            ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($t, $p)
              : Math::GMPz::Rmpz_set_str($t, $p, 10);

            my @e_divisors = ($e > 1) ? _divisors($e) : (1);

            Math::GMPz::Rmpz_set_ui($u, 0);

            foreach my $d (@e_divisors) {
                Math::GMPz::Rmpz_pow_ui($w, $t, $k * $d);
                Math::GMPz::Rmpz_add($u, $u, $w);
            }

            Math::GMPz::Rmpz_mul($s, $s, $u);
        }

        bless \$s;
    }

    sub nesigma0 {    # A160097: count of non-exponential divisors of n
        my ($n) = @_;
        $n->sigma0->sub($n->esigma0);
    }

    sub nesigma {     # A160135: sum of non-exponential divisors of n
        my ($n, $k) = @_;
        $n->sigma($k)->sub($n->esigma($k));
    }

    sub uphi {

        # Multiplicative with:
        #   uphi(p^e) = p^e - 1

        my $n = &_big2uistr // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $e);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $e);
            }

            Math::GMPz::Rmpz_sub_ui($t, $t, 1);
            Math::GMPz::Rmpz_mul($s, $s, $t);
        }

        bless \$s;
    }

    sub prime_power_sigma {
        my ($n, $k) = @_;

        # Additive with:
        #   a(p^e, k) = (p^(k*(e+1)) - p^k) / (p^k - 1)

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;

        if ($k == 0) {
            goto &prime_power_sigma0;
        }

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            if ($p < ULONG_MAX) {
                ($k == 1)
                  ? Math::GMPz::Rmpz_set_ui($u, $p)
                  : Math::GMPz::Rmpz_ui_pow_ui($u, $p, $k);
            }
            else {
                Math::GMPz::Rmpz_set_str($u, $p, 10);
                Math::GMPz::Rmpz_pow_ui($u, $u, $k) if ($k > 1);
            }

            Math::GMPz::Rmpz_pow_ui($t, $u, $e + 1);
            Math::GMPz::Rmpz_sub($t, $t, $u);
            Math::GMPz::Rmpz_sub_ui($u, $u, 1);
            Math::GMPz::Rmpz_divexact($t, $t, $u);
            Math::GMPz::Rmpz_add($s, $s, $t);
        }

        bless \$s;
    }

    sub prime_power_usigma {
        my ($n, $k) = @_;

        # Additive with:
        #   a(p^e, k) = p^(e*k)

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;

        if ($k == 0) {
            goto &prime_power_usigma0;
        }

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k * $e);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $k * $e);
            }

            Math::GMPz::Rmpz_add($s, $s, $t);
        }

        bless \$s;
    }

    sub squarefree_usigma0 {
        (TWO)->powerfree_usigma0($_[0]);
    }

    sub squarefree_usigma {
        (TWO)->powerfree_usigma($_[0], $_[1]);
    }

    *squarefree_sigma0 = \&usigma0;

    sub squarefree_sigma {
        (TWO)->powerfree_sigma($_[0], $_[1]);
    }

    sub power_sigma0 {
        my ($k, $n) = @_;

        # Multiplicative with:
        #   a(p^e) = floor(e/k) + 1

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k)   // goto &nan } : 1;
        $n = defined($n) ? do { _valid(\$n); _big2uistr($n) // goto &nan } : (goto &nan);

        $k > 0 or return ZERO;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        _set_int(
                 Math::Prime::Util::GMP::vecprod(map  { Math::Prime::Util::GMP::divint($_->[1], $k) + 1 }
                                                 grep { $_->[1] >= $k } @factor_exp)
                );
    }

    sub power_sigma {
        my ($k, $n, $j) = @_;

        # Multiplicative with:
        #   a(p^e) = (p^(j*k*(1+floor(e/k))) - 1) / (p^(j*k) - 1), where e >= k.

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;
        $j = defined($j) ? do { _valid(\$j); _any2ui($$j) // goto &nan } : 1;

        $k > 0 or return ZERO;

        if ($j == 0) {
            goto &power_sigma0;
        }

        $n = defined($n) ? do { _valid(\$n); _big2uistr($n) // goto &nan } : (goto &nan);

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            next if ($e < $k);

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k * $j);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $k * $j);
            }

            Math::GMPz::Rmpz_pow_ui($u, $t, 1 + Math::Prime::Util::GMP::divint($e, $k));
            Math::GMPz::Rmpz_sub_ui($t, $t, 1);
            Math::GMPz::Rmpz_sub_ui($u, $u, 1);
            Math::GMPz::Rmpz_divexact($u, $u, $t);

            Math::GMPz::Rmpz_mul($s, $s, $u);
        }

        bless \$s;
    }

    sub square_sigma0 {
        (TWO)->power_sigma0($_[0]);
    }

    sub square_sigma {
        (TWO)->power_sigma($_[0], $_[1]);
    }

    sub power_usigma0 {
        my ($k, $n) = @_;

        # Multiplicative with:
        #   a(p^e) = 2             if e == 0 (mod k)

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k)   // goto &nan } : 1;
        $n = defined($n) ? do { _valid(\$n); _big2uistr($n) // goto &nan } : (goto &nan);

        $k > 0 or return ZERO;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_setbit($r, scalar grep { $_->[1] % $k == 0 } @factor_exp);
        bless \$r;
    }

    sub power_usigma {
        my ($k, $n, $j) = @_;

        # Multiplicative with:
        #   a(p^e) = p^(e*j) + 1, where e == 0 (mod k).

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;
        $j = defined($j) ? do { _valid(\$j); _any2ui($$j) // goto &nan } : 1;

        $k > 0 or return ZERO;

        if ($j == 0) {
            goto &power_usigma0;
        }

        $n = defined($n) ? do { _valid(\$n); _big2uistr($n) // goto &nan } : (goto &nan);

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            $e % $k == 0 or next;

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $e * $j);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $e * $j);
            }

            Math::GMPz::Rmpz_add_ui($t, $t, 1);
            Math::GMPz::Rmpz_mul($s, $s, $t);
        }

        bless \$s;
    }

    sub square_usigma0 {
        (TWO)->power_usigma0($_[0]);
    }

    sub square_usigma {
        (TWO)->power_usigma($_[0], $_[1]);
    }

    sub powerfree_sigma0 {
        my ($k, $n) = @_;

        # Multiplicative with:
        #   a(p^e) = min(e, k-1) + 1

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k)   // goto &nan } : 1;
        $n = defined($n) ? do { _valid(\$n); _big2uistr($n) // goto &nan } : (goto &nan);

        $k > 0 or return ZERO;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        _set_int(Math::Prime::Util::GMP::vecprod(map { ($_->[1] < $k) ? ($_->[1] + 1) : $k } @factor_exp));
    }

    sub powerfree_sigma {
        my ($k, $n, $j) = @_;

        # Multiplicative with:
        #   a(p^e) = (p^(j*(e+1)) - 1)/(p^j - 1), where e = min(e, k-1)

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;
        $j = defined($j) ? do { _valid(\$j); _any2ui($$j) // goto &nan } : 1;

        $k > 0 or return ZERO;

        if ($j == 0) {
            goto &powerfree_sigma0;
        }

        $n = defined($n) ? do { _valid(\$n); _big2uistr($n) // goto &nan } : (goto &nan);

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            $e = $k - 1 if ($e >= $k);

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $j);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $j);
            }

            Math::GMPz::Rmpz_pow_ui($u, $t, $e + 1);
            Math::GMPz::Rmpz_sub_ui($t, $t, 1);
            Math::GMPz::Rmpz_sub_ui($u, $u, 1);
            Math::GMPz::Rmpz_divexact($u, $u, $t);

            Math::GMPz::Rmpz_mul($s, $s, $u);
        }

        bless \$s;
    }

    sub powerfree_usigma0 {
        my ($k, $n) = @_;

        # Multiplicative with:
        #   a(p^e) = 2          # for e < k
        #   a(p^e) = 1          # for e >= k

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k)   // goto &nan } : 1;
        $n = defined($n) ? do { _valid(\$n); _big2uistr($n) // goto &nan } : (goto &nan);

        $k > 0 or return ZERO;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_setbit($r, scalar grep { $_->[1] < $k } @factor_exp);
        bless \$r;
    }

    sub powerfree_usigma {
        my ($k, $n, $j) = @_;

        # Multiplicative with:
        #   a(p^e) = p^(e*j) + 1      # for e < k
        #   a(p^e) = 1                # for e >= k

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;
        $j = defined($j) ? do { _valid(\$j); _any2ui($$j) // goto &nan } : 1;

        $k > 0 or return ZERO;

        if ($j == 0) {
            goto &powerfree_usigma0;
        }

        $n = defined($n) ? do { _valid(\$n); _big2uistr($n) // goto &nan } : (goto &nan);

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $pe (@factor_exp) {

            my ($p, $e) = @$pe;

            $e < $k or next;

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $e * $j);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $e * $j);
            }

            Math::GMPz::Rmpz_add_ui($t, $t, 1);
            Math::GMPz::Rmpz_mul($s, $s, $t);
        }

        bless \$s;
    }

    sub prime_sigma {
        my ($n, $k) = @_;

        # Additive with:
        #   a(p^e, k) = p^k

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;

        if ($k == 0) {
            goto &prime_sigma0;
        }

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $pe (@factor_exp) {

            my $p = $pe->[0];

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $k);
            }

            Math::GMPz::Rmpz_add($s, $s, $t);
        }

        bless \$s;
    }

    sub prime_usigma0 {

        my $n = &_big2uistr // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        _set_int(scalar grep { $_->[1] == 1 } @factor_exp);
    }

    sub prime_usigma {
        my ($n, $k) = @_;

        # Additive with:
        #   a(p,   k) = p^k
        #   a(p^e, k) = 0 for e>1

        $k = defined($k) ? do { _valid(\$k); _any2ui($$k) // goto &nan } : 1;

        if ($k == 0) {
            goto &prime_usigma0;
        }

        $n = _big2uistr($n) // goto &nan;

        my @factor_exp = _factor_exp($n);
        @factor_exp and $factor_exp[0][0] eq '0' and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $pe (grep { $_->[1] == 1 } @factor_exp) {

            my $p = $pe->[0];

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $k);
            }

            Math::GMPz::Rmpz_add($s, $s, $t);
        }

        bless \$s;
    }

    sub sigma0 {
        my $n = &_big2uistr // goto &nan;
        $n eq '0' and return ZERO;
        my $s = Math::Prime::Util::GMP::sigma($n, 0);
        _set_int($s);
    }

    sub sigma {
        my ($n, $k) = @_;

        $k = defined($k) ? do { _valid(\$k); _any2si($$k) // goto &nan } : 1;

        $n = _big2uistr($n) // (goto &nan);
        $n eq '0' and return ZERO;

        my $s = Math::Prime::Util::GMP::sigma($n, CORE::abs($k));

        if ($k < 0) {    # Sum_{d|n} 1/d^k = sigma_k(n)/n^k
            return _set_int($s)->div(_set_int(Math::Prime::Util::GMP::powint($n, CORE::abs($k))));
        }

        _set_int($s);
    }

    *σ = \&sigma;

    sub is_abundant {
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_sgn($n) > 0 or return Sidef::Types::Bool::Bool::FALSE;

        my $nstr = (
                      Math::GMPz::Rmpz_fits_ulong_p($n)
                    ? Math::GMPz::Rmpz_get_ui($n)
                    : Math::GMPz::Rmpz_get_str($n, 10)
                   );

        my $sigma = Math::Prime::Util::GMP::sigma($nstr);

        if ($nstr < ULONG_MAX and $sigma < ULONG_MAX) {
            return (
                    (($sigma >> 1) > $nstr)
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        state $s = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_set_str($s, $sigma, 10);
        Math::GMPz::Rmpz_div_2exp($s, $s, 1);

        (Math::GMPz::Rmpz_cmp($s, $n) > 0)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub abundancy_index {
        my ($n) = @_;
        $n->sigma->div($n);
    }

    *abundancy = \&abundancy_index;

    sub sopf {    # OEIS: A008472
        my $n = &_big2uistr // goto &nan;
        my $s = Math::Prime::Util::GMP::vecsum(map { $_->[0] } _factor_exp($n));
        _set_int($s);
    }

    sub sopfr {    # OEIS: A001414
        my $n = &_big2uistr // goto &nan;
        my $s = Math::Prime::Util::GMP::vecsum(_factor($n));
        _set_int($s);
    }

    sub factor_map {
        my ($n, $block) = @_;

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new;

        my @array;
        foreach my $pk (_factor_exp($n)) {

            my ($p, $k) = @$pk;

            $p = _set_int($p);
            $k = _set_int($k);

            push @array, $block->run($p, $k);
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    sub divisor_map {
        my ($n, $block) = @_;

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new;

        my @array;
        foreach my $divisor (_divisors($n)) {
            push @array, $block->run(_set_int($divisor));
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    sub divisor_sum {
        my ($n, $block) = @_;
        $block // return $n->sigma;
        $n->divisor_map($block)->sum;
    }

    *divisors_sum = \&divisor_sum;

    sub divisor_prod {
        my ($n, $block) = @_;
        $block // return $n->divisors->prod;
        $n->divisor_map($block)->prod;
    }

    *divisors_prod = \&divisor_prod;

    sub factor_sum {
        my ($n, $block) = @_;
        $block // return $n->sopfr;
        $n->factor_map($block)->sum;
    }

    *factors_sum = \&factor_sum;

    sub factor_prod {
        my ($n, $block) = @_;
        $block // return $n;
        $n->factor_map($block)->prod;
    }

    *factors_prod = \&factor_prod;

    sub partitions {
        my $n = Math::Prime::Util::GMP::partitions(&_big2uistr // goto &nan);
        _set_int($n);
    }

    *partition_number = \&partitions;

    sub is_primitive_root {
        my ($x, $y) = @_;
        _valid(\$y);
        __is_int__($$x)
          && __is_int__($$y)
          && Math::Prime::Util::GMP::is_primitive_root(_big2uistr($x) // (return Sidef::Types::Bool::Bool::FALSE),
                                                       _big2uistr($y) // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub _sieve_powerful {
        my ($from, $to, $k) = @_;

        my @powerful;

        if (0 and HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($to)) {
            ## TODO
        }
        else {
            my $t = Math::GMPz::Rmpz_init();

            sub {
                my ($m, $r) = @_;

                if ($r < $k) {
                    push @powerful, (Math::GMPz::Rmpz_fits_ulong_p($m) ? Math::GMPz::Rmpz_get_ui($m) : $m);
                    return;
                }

                Math::GMPz::Rmpz_div($t, $to, $m);
                Math::GMPz::Rmpz_root($t, $t, $r);

                my $lo = 1;
                my $hi = Math::GMPz::Rmpz_get_ui($t);

                if ($r <= $k and Math::GMPz::Rmpz_cmp($from, $m) > 0) {
                    Math::GMPz::Rmpz_cdiv_q($t, $from, $m);
                    Math::GMPz::Rmpz_root($t, $t, $r);
                    $lo = Math::GMPz::Rmpz_get_ui($t);
                }

                foreach my $v ($lo .. $hi) {

                    if ($r > $k) {
                        (HAS_PRIME_UTIL ? Math::Prime::Util::is_square_free($v) : Math::Prime::Util::GMP::moebius($v)) or next;
                        Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $v) == 1                                        or next;
                    }

                    Math::GMPz::Rmpz_ui_pow_ui($t, $v, $r);
                    Math::GMPz::Rmpz_mul($t, $t, $m);

                    if ($r <= $k and Math::GMPz::Rmpz_cmp($t, $from) < 0) {
                        next;
                    }

                    __SUB__->(Math::GMPz::Rmpz_init_set($t), $r - 1);
                }
              }
              ->($ONE, 2 * $k - 1);

            @powerful = sort { $a <=> $b } @powerful;
        }

        return \@powerful;
    }

    # Array of k-powerful numbers in the range [from, to]
    sub powerful {
        my ($k, $from, $to) = @_;

        _valid(\$from);

        if (defined($to)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $to   = _any2mpz($$to)   // return Sidef::Types::Array::Array->new;
        }
        else {
            $to   = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $from = $ONE;
        }

        $k = _any2ui($$k) // return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_sgn($from) <= 0) {
            $from = $ONE;
        }

        if (Math::GMPz::Rmpz_sgn($to) < 0) {
            $to = $ZERO;
        }

#<<<
        my @powerful = map {
            ref($_) ? (bless \$_) : _set_int($_)
        } @{_sieve_powerful($from, $to, $k)};
#>>>

        Sidef::Types::Array::Array->new(\@powerful);
    }

    sub powerful_each {
        my ($k, $from, $to, $block) = @_;

        _valid(\$from);

        if (defined($block)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return ZERO;
            $to   = _any2mpz($$to)   // return ZERO;
        }
        else {
            $block = $to;
            $to    = _any2mpz($$from) // return ZERO;
            $from  = $ONE;
        }

        $k = _any2ui($$k) // return ZERO;

        if (Math::GMPz::Rmpz_sgn($from) <= 0) {
            $from = $ONE;
        }

        my $step_value = $TEN**(6 * $k);    # TODO: improve this value
        _generic_each($from, $to, $block, sub { $step_value }, sub { _sieve_powerful($_[0], $_[1], $k) });
    }

    *each_powerful = \&powerful_each;

    sub nth_powerful {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
            $k >= 2 or goto &nan;
        }
        else {
            $k = 2;
        }

        my $k_obj = _set_int($k);
        my $n_obj = $n;

        $n = _any2mpz($$n) // goto &nan;

        Math::GMPz::Rmpz_sgn($n) > 0 or do {
            return ZERO if (Math::GMPz::Rmpz_sgn($n) == 0);    # not k-powerful, but...
            goto &nan;
        };

        my $min = Math::GMPz::Rmpz_init_set_ui(1);
        my $max = Math::GMPz::Rmpz_init_set($n);

        Math::GMPz::Rmpz_mul($max, $max, $n);

        while (Math::GMPz::Rmpz_cmp(${$k_obj->powerful_count(bless \$max)}, $n) < 0) {
            Math::GMPz::Rmpz_set($min, $max);
            Math::GMPz::Rmpz_mul_ui($max, $max, $k);
        }

        my $v     = Math::GMPz::Rmpz_init();
        my $count = Math::GMPz::Rmpz_init();

        while (1) {
            Math::GMPz::Rmpz_add($v, $min, $max);
            Math::GMPz::Rmpz_div_2exp($v, $v, 1);

            $count =
              (HAS_NEW_PRIME_UTIL && Math::GMPz::Rmpz_fits_ulong_p($v))
              ? Math::GMPz::Rmpz_init_set_ui(Math::Prime::Util::powerful_count(Math::GMPz::Rmpz_get_ui($v), $k))
              : ${$k_obj->powerful_count(bless \$v)};

            my $cmp = Math::GMPz::Rmpz_cmp($count, $n);

            if ($cmp > 0) {
                Math::GMPz::Rmpz_sub_ui($max, $v, 1);
            }
            elsif ($cmp < 0) {
                Math::GMPz::Rmpz_add_ui($min, $v, 1);
            }
            else {
                last;
            }
        }

        $k_obj->powerful((bless \$min), (bless \$v))->last;
    }

    sub next_powerful {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
        }
        else {
            $k = TWO;
        }

        $k->powerful_count($n)->inc->nth_powerful($k);
    }

    sub _sieve_omega_primes {
        my ($from, $to, $k) = @_;

        return [1] if ($k == 0 and $to >= 1 and $from <= 1);
        return []  if ($k == 0);

        my @omega_primes;

        # TODO: optimization when A and B are close to each other.
        # Idea: if |A-B| < sqrt(B), then just iterate over the range A..B and grep the k-omega primes.

        if (0 and HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($to)) {

            # XXX: Out of memory for: omega_primes(12, 1e13)
            return Math::Prime::Util::omega_primes(    # XXX: available in MPU > 0.73
                                                    $k, Math::GMPz::Rmpz_get_ui($from), Math::GMPz::Rmpz_get_ui($to)
                                                  );
        }
        elsif (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($to)) {

            my $A = Math::GMPz::Rmpz_get_ui($from);
            my $B = Math::GMPz::Rmpz_get_ui($to);

            $A = Math::Prime::Util::vecmax($A, Math::Prime::Util::GMP::pn_primorial($k));

            sub {
                my ($m, $p, $k) = @_;

                my $s = Math::Prime::Util::rootint(Math::Prime::Util::GMP::divint($B, $m), $k);

                while ($p <= $s) {

                    my $r = _next_prime($p);

                    for (my $t = $m * $p ; $t - 1 < $B ; $t *= $p) {
                        if ($k == 1) {
                            push(@omega_primes, $t) if ($t >= $A);
                        }
                        else {
                            __SUB__->($t, $r, $k - 1) if ($t * $r - 1 < $B);
                        }
                    }

                    $p = $r;
                }
              }
              ->(1, 2, $k);

            @omega_primes = sort { $a <=> $b } @omega_primes;
        }
        else {

            my $A = Math::GMPz::Rmpz_init_set($from);
            my $B = Math::GMPz::Rmpz_init_set($to);

            my $t = Math::GMPz::Rmpz_init();
            my $x = Math::GMPz::Rmpz_init();

            Math::GMPz::Rmpz_set($t, _cached_pn_primorial($k));

            # A = max(A, t)
            if (Math::GMPz::Rmpz_cmp($t, $A) > 0) {
                Math::GMPz::Rmpz_set($A, $t);
            }

            sub {
                my ($m, $p, $k) = @_;

                my $s = Math::Prime::Util::GMP::rootint(Math::Prime::Util::GMP::divint($B, $m), $k);

                while ($p <= $s) {

                    my $r = _next_prime($p);

                    for (my $t = $m * $p ; Math::GMPz::Rmpz_cmp($t, $B) <= 0 ; $t *= $p) {
                        if ($k == 1) {
                            if (Math::GMPz::Rmpz_cmp($t, $A) >= 0) {
                                if (Math::GMPz::Rmpz_fits_ulong_p($t)) {
                                    push @omega_primes, Math::GMPz::Rmpz_get_ui($t);
                                }
                                else {
                                    push @omega_primes, $t;
                                }
                            }
                        }
                        else {
                            __SUB__->($t, $r, $k - 1) if (Math::GMPz::Rmpz_cmp($t * $r, $B) <= 0);
                        }
                    }

                    $p = $r;
                }
              }
              ->(Math::GMPz::Rmpz_init_set_ui(1), 2, $k);

            @omega_primes = sort { $a <=> $b } @omega_primes;
        }

        return \@omega_primes;
    }

    sub omega_prime_divisors {
        my ($n, $k) = @_;

        if (!defined($k)) {
            my @list;

            foreach my $k (0 .. $n->omega) {
                push @list, $n->omega_prime_divisors(_set_int($k));
            }

            return Sidef::Types::Array::Array->new(\@list);
        }

        _valid(\$k);

        $k = _any2ui($$k) // return Sidef::Types::Array::Array->new;
        my $z = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        if ($k == 0) {
            return Sidef::Types::Array::Array->new([ONE]);
        }

        if ($k == 1) {
            return $_[0]->prime_power_divisors;
        }

        my @factor_exp = _factor_exp($z);

        if ($k > scalar(@factor_exp)) {
            return Sidef::Types::Array::Array->new();
        }

        my %valuations  = map { @$_ } @factor_exp;
        my @factors     = map { ($_ < ULONG_MAX) ? $_ : Math::GMPz::Rmpz_init_set_str("$_", 10) } map { $_->[0] } @factor_exp;
        my $factors_end = $#factors;

        my $t = Math::GMPz::Rmpz_init();

        my @list;

        sub {
            my ($m, $k, $i) = @_;

            Math::GMPz::Rmpz_div($t, $z, $m);
            Math::GMPz::Rmpz_root($t, $t, $k);

            my $L =
                Math::GMPz::Rmpz_fits_ulong_p($t)
              ? Math::GMPz::Rmpz_get_ui($t)
              : Math::GMPz::Rmpz_init_set($t);

            foreach my $j ($i .. $factors_end) {

                my $q = $factors[$j];

                if (($k > 1 and $j == $factors_end) or ($q > $L)) {
                    last;
                }

                my $v = $m * $q;

                foreach (1 .. $valuations{$q}) {

                    if ($k == 1) {
                        push @list, $v;
                    }
                    else {
                        __SUB__->($v, $k - 1, $j + 1);
                    }

                    $v *= $q;
                }
            }
          }
          ->(Math::GMPz::Rmpz_init_set_ui(1), $k, 0);

        Sidef::Types::Array::Array->new([map { _set_int($_) } sort { $a <=> $b } @list]);
    }

    sub omega_primes {
        my ($k, $from, $to) = @_;

        _valid(\$from);

        if (defined($to)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $to   = _any2mpz($$to)   // return Sidef::Types::Array::Array->new;
        }
        else {
            $to   = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $from = $ONE;
        }

        $k = _any2ui($$k) // return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_sgn($from) <= 0) {
            $from = $ONE;
        }

        if (Math::GMPz::Rmpz_sgn($to) < 0) {
            $to = $ZERO;
        }

#<<<
        my @omega_primes = map {
            ref($_) ? (bless \$_) : _set_int($_)
        } @{_sieve_omega_primes($from, $to, $k)};
#>>>

        Sidef::Types::Array::Array->new(\@omega_primes);
    }

    sub prime_powers {
        (ONE)->omega_primes(@_);
    }

    sub omega_primes_each {
        my ($k, $from, $to, $block) = @_;

        _valid(\$from);

        if (defined($block)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return ZERO;
            $to   = _any2mpz($$to)   // return ZERO;
        }
        else {
            $block = $to;
            $to    = _any2mpz($$from) // return ZERO;
            $from  = $ONE;
        }

        $k = _any2ui($$k) // return ZERO;

        if (Math::GMPz::Rmpz_sgn($from) <= 0) {
            $from = $ONE;
        }

        my $step = ($k > 8) ? Math::Prime::Util::GMP::pn_primorial($k) : 1e7;

        if ($step > ULONG_MAX) {
            $step = Math::GMPz::Rmpz_init_set_str("$step", 10);
        }

        _generic_each($from, $to, $block, sub { $step }, sub { _sieve_omega_primes($_[0], $_[1], $k) });
    }

    *each_omega_prime = \&omega_primes_each;

    sub prime_powers_each {
        (ONE)->omega_primes_each(@_);
    }

    *each_prime_power = \&prime_powers_each;

    sub _sieve_almost_primes {
        my ($from, $to, $k, %opt) = @_;

        return [1] if ($k == 0 and $to >= 1 and $from <= 1);
        return []  if ($k == 0);

        if ($k == 1) {
            if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($to)) {
                return Math::Prime::Util::primes(Math::GMPz::Rmpz_get_ui($from), Math::GMPz::Rmpz_get_ui($to));
            }
            return [Math::Prime::Util::GMP::sieve_primes($from, $to)];
        }

        my $squarefree = $opt{squarefree};

        if ($k == 2) {
            if (HAS_PRIME_UTIL) {
                if (Math::GMPz::Rmpz_fits_ulong_p($to)) {
                    my $arr = Math::Prime::Util::semi_primes(Math::GMPz::Rmpz_get_ui($from), Math::GMPz::Rmpz_get_ui($to));
                    $arr = [grep { Math::Prime::Util::is_square_free($_) } @$arr] if $squarefree;
                    return $arr;
                }
                my $arr = Math::Prime::Util::semi_primes($from, $to);
                $arr = [grep { Math::Prime::Util::is_square_free($_) } @$arr] if $squarefree;
                return $arr;
            }
        }

        my @almost_primes;

        # TODO: optimization when A and B are close to each other.
        # Idea: if |A-B| < sqrt(B), then just iterate over the range A..B and grep the k-almost primes.

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($to)) {

            my $A = Math::GMPz::Rmpz_get_ui($from);
            my $B = Math::GMPz::Rmpz_get_ui($to);

            if ($squarefree) {
                $A = Math::Prime::Util::vecmax($A, Math::Prime::Util::GMP::pn_primorial($k));
            }
            else {
                $A = Math::Prime::Util::vecmax($A, Math::Prime::Util::GMP::powint(2, $k));
            }

            sub {
                my ($m, $p, $k, $u, $v) = @_;

#<<<
                if ($k == 1) {
                    Math::Prime::Util::forprimes(sub {
                        push(@almost_primes, $m * $_);
                    }, $u, $v);
                    return;
                }
#>>>

                my $s = Math::Prime::Util::rootint(Math::Prime::Util::GMP::divint($B, $m), $k);

                while ($p <= $s) {

                    my $r = _next_prime($p);
                    my $t = $m * $p;

                    my $u = (HAS_NEW_PRIME_UTIL ? Math::Prime::Util::divint($A, $t) : Math::Prime::Util::GMP::divint($A, $t));
                    my $v = (HAS_NEW_PRIME_UTIL ? Math::Prime::Util::divint($B, $t) : Math::Prime::Util::GMP::divint($B, $t));

                    ++$u if ($t * $u < $A);

                    if (!($u > $v)) {
                        $p = $r if $squarefree;
                        $u = $p if ($k == 2 and $p > $u);
                        __SUB__->($t, $p, $k - 1, ($k == 2) ? ($u, $v) : ());
                    }

                    $p = $r;
                }
              }
              ->(1, 2, $k);

            @almost_primes = sort { $a <=> $b } @almost_primes;
        }
        else {

            my $A = Math::GMPz::Rmpz_init_set($from);
            my $B = Math::GMPz::Rmpz_init_set($to);

            my $t = Math::GMPz::Rmpz_init_set_ui(0);
            my $x = Math::GMPz::Rmpz_init();

            if ($squarefree) {
                Math::GMPz::Rmpz_set_str($t, Math::Prime::Util::GMP::pn_primorial($k), 10);
            }
            else {
                Math::GMPz::Rmpz_setbit($t, $k);    # t = ipow(2, k)
            }

            # A = max(A, t)
            if (Math::GMPz::Rmpz_cmp($t, $A) > 0) {
                Math::GMPz::Rmpz_set($A, $t);
            }

            sub {
                my ($m, $p, $k, $u, $v) = @_;

                if ($k == 1) {

                    foreach my $q (
                                   HAS_PRIME_UTIL
                                   ? @{Math::Prime::Util::primes($u, $v)}
                                   : Math::Prime::Util::GMP::sieve_primes($u, $v)
                      ) {

                        if ($q < ULONG_MAX) {
                            Math::GMPz::Rmpz_mul_ui($x, $m, $q);
                        }
                        else {
                            Math::GMPz::Rmpz_set_str($x, "$q", 10);
                            Math::GMPz::Rmpz_mul($x, $x, $m);
                        }

                        push @almost_primes,
                          (
                              Math::GMPz::Rmpz_fits_ulong_p($x)
                            ? Math::GMPz::Rmpz_get_ui($x)
                            : Math::GMPz::Rmpz_init_set($x)
                          );
                    }

                    return;
                }

                my $s = Math::Prime::Util::GMP::rootint(Math::Prime::Util::GMP::divint($B, $m), $k);

                while ($p <= $s) {

                    my $r = _next_prime($p);
                    my $u = Math::GMPz::Rmpz_init();

                    Math::GMPz::Rmpz_mul_ui($u, $m, $p);
                    Math::GMPz::Rmpz_cdiv_q($t, $A, $u);
                    Math::GMPz::Rmpz_div($x, $B, $u);

                    if (!(Math::GMPz::Rmpz_cmp($t, $x) > 0)) {

                        $p = $r if $squarefree;

                        # t = max(t, p)
                        if ($k == 2 and Math::GMPz::Rmpz_cmp_ui($t, $p) < 0) {
                            Math::GMPz::Rmpz_set_ui($t, $p);
                        }

                        __SUB__->(
                                  $u, $p, $k - 1,
                                  ($k == 2)
                                  ? (Math::GMPz::Rmpz_get_str($t, 10), Math::GMPz::Rmpz_get_str($x, 10))
                                  : ()
                                 );
                    }

                    $p = $r;
                }
              }
              ->(Math::GMPz::Rmpz_init_set_ui(1), 2, $k);

            @almost_primes = sort { $a <=> $b } @almost_primes;
        }

        return \@almost_primes;
    }

    sub almost_prime_divisors {
        my ($n, $k) = @_;

        if (!defined($k)) {
            my @list;

            foreach my $k (0 .. $n->bigomega) {
                push @list, $n->almost_prime_divisors(_set_int($k));
            }

            return Sidef::Types::Array::Array->new(\@list);
        }

        _valid(\$k);

        $k = _any2ui($$k) // return Sidef::Types::Array::Array->new;
        my $z = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        if ($k == 0) {
            return Sidef::Types::Array::Array->new([ONE]);
        }

        my @factor_exp  = _factor_exp($z);
        my %valuations  = map { @$_ } @factor_exp;
        my @factors     = map { ($_ < ULONG_MAX) ? $_ : Math::GMPz::Rmpz_init_set_str("$_", 10) } map { $_->[0] } @factor_exp;
        my $factors_end = $#factors;

        if ($k == 1) {
            return Sidef::Types::Array::Array->new([map { _set_int($_) } @factors]);
        }

        my $bigomega = 0;

        foreach my $pp (@factor_exp) {
            $bigomega += $pp->[1];
        }

        if ($k > $bigomega) {
            return Sidef::Types::Array::Array->new();
        }

        my $t = Math::GMPz::Rmpz_init();

        my @list;

        sub {
            my ($m, $k, $i) = @_;

            Math::GMPz::Rmpz_div($t, $z, $m);

            if ($k == 1) {

                my $L =
                    Math::GMPz::Rmpz_fits_ulong_p($t)
                  ? Math::GMPz::Rmpz_get_ui($t)
                  : Math::GMPz::Rmpz_init_set($t);

                foreach my $j ($i .. $factors_end) {

                    my $q = $factors[$j];
                    $q > $L and last;

                    my $v = ref($q) ? Math::GMPz::Rmpz_remove($t, $m, $q) : do {
                        Math::GMPz::Rmpz_set_ui($t, $q);
                        Math::GMPz::Rmpz_remove($t, $m, $t);
                    };

                    if ($v < $valuations{$q}) {
                        push @list, $m * $q;
                    }
                }

                return;
            }

            Math::GMPz::Rmpz_root($t, $t, $k);

            my $L =
                Math::GMPz::Rmpz_fits_ulong_p($t)
              ? Math::GMPz::Rmpz_get_ui($t)
              : Math::GMPz::Rmpz_init_set($t);

            foreach my $j ($i .. $factors_end) {

                my $q = $factors[$j];
                $q > $L and last;

                my $v = ref($q) ? Math::GMPz::Rmpz_remove($t, $m, $q) : do {
                    Math::GMPz::Rmpz_set_ui($t, $q);
                    Math::GMPz::Rmpz_remove($t, $m, $t);
                };

                if ($v < $valuations{$q}) {
                    __SUB__->($m * $q, $k - 1, $j);
                }
            }
          }
          ->(Math::GMPz::Rmpz_init_set_ui(1), $k, 0);

        Sidef::Types::Array::Array->new([map { _set_int($_) } sort { $a <=> $b } @list]);
    }

    sub almost_primes {
        my ($k, $from, $to) = @_;

        _valid(\$from);

        if (defined($to)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $to   = _any2mpz($$to)   // return Sidef::Types::Array::Array->new;
        }
        else {
            $to   = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $from = $ONE;
        }

        $k = _any2ui($$k) // return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_sgn($from) <= 0) {
            $from = $ONE;
        }

        if (Math::GMPz::Rmpz_sgn($to) < 0) {
            $to = $ZERO;
        }

#<<<
        my @almost_primes = map {
            ref($_) ? (bless \$_) : _set_int($_)
        } @{_sieve_almost_primes($from, $to, $k)};
#>>>

        Sidef::Types::Array::Array->new(\@almost_primes);
    }

    sub almost_primes_each {
        my ($k, $from, $to, $block) = @_;

        _valid(\$from);

        if (defined($block)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return ZERO;
            $to   = _any2mpz($$to)   // return ZERO;
        }
        else {
            $block = $to;
            $to    = _any2mpz($$from) // return ZERO;
            $from  = $ONE;
        }

        $k = _any2ui($$k) // return ZERO;

        if (Math::GMPz::Rmpz_cmp_ui($from, $k) <= 0 and $k > 0) {
            $from = Math::GMPz::Rmpz_init_set_ui(0);
            Math::GMPz::Rmpz_setbit($from, $k);    # from = 2**k
        }

#<<<
        _generic_each($from, $to, $block, sub {
                my ($from) = @_;

                my $t    = Math::GMPz::Rmpz_get_d($from);
                my $step = ($k > 0) ? (_nth_almost_prime_lower($t + CORE::log($t) * 2e4, $k) - _nth_almost_prime_lower($t, $k)) : 0;

                if ($step <= 0 or $step > 1e9) {
                    $step = 100_000_000 * $k;
                }

                $step;
            }, sub { _sieve_almost_primes($_[0], $_[1], $k) });
#>>>
    }

    *each_almost_prime = \&almost_primes_each;

    sub nth_almost_prime {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
            $k >= 1 or goto &nan;
        }
        else {
            $k = 2;
        }

        if ($k == 1) {
            return $n->nth_prime;
        }
        elsif ($k == 2) {
            return $n->nth_semiprime;
        }

        my $k_obj = _set_int($k);
        my $n_obj = $n;

        $n = _any2mpz($$n) // goto &nan;

        Math::GMPz::Rmpz_sgn($n) > 0 or do {
            return ONE if (Math::GMPz::Rmpz_sgn($n) == 0);    # not k-almost prime, but...
            goto &nan;
        };

        if (HAS_NEW_PRIME_UTIL) {
            my $r = Math::Prime::Util::nth_almost_prime($k, $n);
            if ($r) {                                         # workaround for danaj/Math-Prime-Util #71
                return _set_int("$r");
            }
        }

        my $min = Math::GMPz::Rmpz_init();
        my $max = Math::GMPz::Rmpz_init_set($n);

        Math::GMPz::Rmpz_setbit($min, $k);
        Math::GMPz::Rmpz_mul_ui($max, $max, $k + 1);

        while (Math::GMPz::Rmpz_cmp(${$k_obj->almost_prime_count(bless \$max)}, $n) < 0) {
            Math::GMPz::Rmpz_set($min, $max);
            Math::GMPz::Rmpz_mul_ui($max, $max, $k);
        }

        my $v     = Math::GMPz::Rmpz_init();
        my $count = Math::GMPz::Rmpz_init();

        while (1) {
            Math::GMPz::Rmpz_add($v, $min, $max);
            Math::GMPz::Rmpz_div_2exp($v, $v, 1);

            $count =
              (HAS_NEW_PRIME_UTIL && Math::GMPz::Rmpz_fits_ulong_p($v))
              ? Math::GMPz::Rmpz_init_set_ui(Math::Prime::Util::almost_prime_count($k, Math::GMPz::Rmpz_get_ui($v)))
              : ${$k_obj->almost_prime_count(bless \$v)};

            my $cmp = Math::GMPz::Rmpz_cmp($count, $n);

            if ($cmp > 0) {
                Math::GMPz::Rmpz_sub_ui($max, $v, 1);
            }
            elsif ($cmp < 0) {
                Math::GMPz::Rmpz_add_ui($min, $v, 1);
            }
            else {
                last;
            }
        }

        $k_obj->almost_primes((bless \$min), (bless \$v))->last;
    }

    sub next_almost_prime {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) || goto &nan;
        }
        else {
            $k = 2;
        }

        if ($k == 1) {
            return $n->next_prime;
        }
        elsif ($k == 2) {
            return $n->next_semiprime;
        }

        my $n_obj = $n;
        my $k_obj = _set_int($k);

        $n = _any2mpz($$n) // goto &nan;

        if (Math::GMPz::Rmpz_sgn($n) < 0) {
            goto &nan;
        }

        my $r = Math::GMPz::Rmpz_init_set_ui(0);
        Math::GMPz::Rmpz_setbit($r, $k);

        # Smallest k-almost prime is 2^k
        if (Math::GMPz::Rmpz_cmp($n, $r) < 0) {
            return bless \$r;
        }

        if ($k <= 23) {

            # Approximate the cost it would take to count the k-almost primes <= n
            my $cost = sub {
                my ($m, $k) = @_;

                my $s = Math::Prime::Util::GMP::rootint(Math::Prime::Util::GMP::divint($n, $m), $k);

                if ($k == 2) {
                    return
                      Math::Prime::Util::GMP::mulint(Math::Prime::Util::GMP::rootint($s, (HAS_NEW_PRIME_UTIL ? 3 : 2)),
                                                     Math::Prime::Util::GMP::prime_count_upper($s));
                }

                Math::Prime::Util::GMP::mulint(Math::Prime::Util::GMP::prime_count_upper($s),
                                               __SUB__->(Math::Prime::Util::GMP::mulint($m, $s), $k - 1));
              }
              ->(1, $k);

            # When the cost is too large, do a linear search for the next k-almost prime
            if ($cost >= 1e7) {

                # Optimization for native integers
                if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_slong_p($n)) {
                    $n = Math::GMPz::Rmpz_get_ui($n) + 1;
                    until (Math::Prime::Util::is_almost_prime($k, $n)) {
                        ++$n;
                    }
                    return _set_int($n);
                }

                Math::GMPz::Rmpz_add_ui($r, $n, 1);

                my $r_obj = bless \$r;

                until ($r_obj->is_almost_prime($k_obj)) {
                    Math::GMPz::Rmpz_add_ui($r, $r, 1);
                }

                return $r_obj;
            }
        }

        $k_obj->almost_prime_count($n_obj)->inc->nth_almost_prime($k_obj);
    }

    sub squarefree_almost_primes {
        my ($k, $from, $to) = @_;

        _valid(\$from);

        if (defined($to)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $to   = _any2mpz($$to)   // return Sidef::Types::Array::Array->new;
        }
        else {
            $to   = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $from = $ONE;
        }

        $k = _any2ui($$k) // return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_sgn($from) <= 0) {
            $from = $ONE;
        }

        if (Math::GMPz::Rmpz_sgn($to) < 0) {
            $to = $ZERO;
        }

#<<<
        my @squarefree_almost_primes = map {
            ref($_) ? (bless \$_) : _set_int($_)
        } @{_sieve_almost_primes($from, $to, $k, squarefree => 1)};
#>>>

        Sidef::Types::Array::Array->new(\@squarefree_almost_primes);
    }

    sub squarefree_almost_primes_each {
        my ($k, $from, $to, $block) = @_;

        _valid(\$from);

        if (defined($block)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return ZERO;
            $to   = _any2mpz($$to)   // return ZERO;
        }
        else {
            $block = $to;
            $to    = _any2mpz($$from) // return ZERO;
            $from  = $ONE;
        }

        $k = _any2ui($$k) // return ZERO;

        if (Math::GMPz::Rmpz_sgn($from) <= 0) {
            $from = $ONE;
        }

        my $step = ($k > 8) ? Math::Prime::Util::GMP::pn_primorial($k) : 1e7;

        if ($step > ULONG_MAX) {
            $step = Math::GMPz::Rmpz_init_set_str("$step", 10);
        }

        _generic_each($from, $to, $block, sub { $step }, sub { _sieve_almost_primes($_[0], $_[1], $k, squarefree => 1) });
    }

    *each_squarefree_almost_prime = \&squarefree_almost_primes_each;

    sub semiprimes {
        my ($from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $to   = _any2mpz($$to)   // return Sidef::Types::Array::Array->new;
        }
        else {
            $to   = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $from = $ONE;
        }

        if (Math::GMPz::Rmpz_sgn($from) <= 0) {
            $from = $ONE;
        }

        if (Math::GMPz::Rmpz_sgn($to) < 0) {
            $to = $ZERO;
        }

#<<<
        my @semiprimes = map {
            ref($_) ? (bless \$_) : _set_int($_)
        } @{_sieve_almost_primes($from, $to, 2)};
#>>>

        Sidef::Types::Array::Array->new(\@semiprimes);
    }

    sub semiprimes_each {
        my ($from, $to, $block) = @_;

        if (defined($block)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return ZERO;
            $to   = _any2mpz($$to)   // return ZERO;
        }
        else {
            $block = $to;
            $to    = _any2mpz($$from) // return ZERO;
            $from  = $ONE;
        }

        if (Math::GMPz::Rmpz_sgn($from) <= 0) {
            $from = $ONE;
        }

        _generic_each($from, $to, $block, sub { 5e6 }, sub { _sieve_almost_primes($_[0], $_[1], 2) });
    }

    *each_semiprime = \&semiprimes_each;

    sub _sieve_squarefree {
        my ($from, $to) = @_;

        my @squarefree;

#<<<
        if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($to)) {
            Math::Prime::Util::forsquarefree(sub {   # XXX: leaks memory in MPU 0.73
                push @squarefree, $_;
            }, Math::GMPz::Rmpz_get_ui($from), Math::GMPz::Rmpz_get_ui($to));
        }
        elsif (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($to)) {

            $from = Math::GMPz::Rmpz_get_ui($from);
            $to   = Math::GMPz::Rmpz_get_ui($to);

            my @mu = Math::Prime::Util::moebius($from, $to);
            for (my $i = -1; $from < $to; ++$from) {
                push(@squarefree, $from) if $mu[++$i];
            }
            push(@squarefree, $to) if $mu[-1];
        }
        else {

            my $t  = Math::GMPz::Rmpz_init_set($from);
            my @mu = Math::Prime::Util::GMP::moebius($from, $to);

            for (my $i = -1; ; Math::GMPz::Rmpz_add_ui($t, $t, 1)) {
                push(@squarefree, Math::GMPz::Rmpz_get_str($t, 10)) if ($mu[++$i] // last);
            }
        }
#>>>

        return \@squarefree;
    }

    sub squarefree {
        my ($from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $to   = _any2mpz($$to)   // return Sidef::Types::Array::Array->new;
        }
        else {
            $to   = _any2mpz($$from) // return Sidef::Types::Array::Array->new;
            $from = $ONE;
        }

        if (Math::GMPz::Rmpz_sgn($from) <= 0) {
            $from = $ONE;
        }

        if (Math::GMPz::Rmpz_sgn($to) < 0) {
            $to = $ZERO;
        }

#<<<
        my @squarefree = map {
            _set_int($_)
        } @{_sieve_squarefree($from, $to)};
#>>>

        Sidef::Types::Array::Array->new(\@squarefree);
    }

    sub squarefree_each {
        my ($from, $to, $block) = @_;

        if (defined($block)) {
            _valid(\$to);
            $from = _any2mpz($$from) // return ZERO;
            $to   = _any2mpz($$to)   // return ZERO;
        }
        else {
            $block = $to;
            $to    = _any2mpz($$from) // return ZERO;
            $from  = $ONE;
        }

        if (Math::GMPz::Rmpz_sgn($from) <= 0) {
            $from = $ONE;
        }

        _generic_each($from, $to, $block, sub { 1e4 }, sub { _sieve_squarefree($_[0], $_[1]) });
    }

    *each_squarefree = \&squarefree_each;

    sub is_squarefree {
        my ($n) = @_;

        my $z = $$n;

        if (ref($z) ne 'Math::GMPz') {
            __is_int__($z) || return Sidef::Types::Bool::Bool::FALSE;
            $z = _any2mpz($z) // return Sidef::Types::Bool::Bool::FALSE;
        }

        if (Math::GMPz::Rmpz_sizeinbase($z, 2) > 100) {
            state $lim = _set_int(1e6);
            $n->is_prob_squarefree($lim) || return Sidef::Types::Bool::Bool::FALSE;
        }

        $z = _big2uistr($z) // return Sidef::Types::Bool::Bool::FALSE;

        _is_squarefree($z)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_square_free = \&is_squarefree;

    sub is_powerfree {
        my ($n, $k) = @_;

        if (!defined($k)) {    # default to k = 2
            return $n->is_squarefree;
        }

        _valid(\$k);

        $n = $$n;
        $k = _any2ui($$k) // return Sidef::Types::Bool::Bool::FALSE;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::FALSE if ($k == 0);

        if ($k == 1) {
            return Sidef::Types::Bool::Bool::TRUE if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0);
            return Sidef::Types::Bool::Bool::FALSE;
        }

        if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                    Math::Prime::Util::is_powerfree(Math::GMPz::Rmpz_get_ui($n), $k)
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        if ($k == 2) {
            return ((bless \$n)->is_squarefree);
        }

        # Optimization for large n
        if (Math::GMPz::Rmpz_sizeinbase($n, 2) > 100) {
            my ($rem, @f) = _adaptive_trial_factor($n);

            my %factors;
            ++$factors{$_} for @f;

            foreach my $e (values %factors) {
                $e < $k
                  or return Sidef::Types::Bool::Bool::FALSE;
            }

            if (Math::GMPz::Rmpz_cmp_ui($rem, 1) == 0) {
                return Sidef::Types::Bool::Bool::TRUE;
            }

            $n = $rem;
        }

        foreach my $pp (_factor_exp($n)) {
            $pp->[1] < $k
              or return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub is_totient {    # OEIS: A002202
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::is_totient(_big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_practical {    # OEIS: A005153
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::is_practical(_big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_fibonacci {    # OEIS: A010056
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        state $t = Math::GMPz::Rmpz_init_nobless();

        # 5*n^2 +/- 4 must be a perfect square

        Math::GMPz::Rmpz_mul($t, $n, $n);
        Math::GMPz::Rmpz_mul_ui($t, $t, 5);

        Math::GMPz::Rmpz_sub_ui($t, $t, 4);
        Math::GMPz::Rmpz_perfect_square_p($t)
          && return Sidef::Types::Bool::Bool::TRUE;

        Math::GMPz::Rmpz_add_ui($t, $t, 8);
        Math::GMPz::Rmpz_perfect_square_p($t)
          && return Sidef::Types::Bool::Bool::TRUE;

        Sidef::Types::Bool::Bool::FALSE;
    }

    *is_fib = \&is_fibonacci;

    sub is_lucas {    # OEIS: A102460
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_cmp_ui($n, 1) >= 0
          or return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_cmp_ui($n, 2) <= 0
          and return Sidef::Types::Bool::Bool::TRUE;

        state $log_phi = do {
            my $t = Math::MPFR::Rmpfr_init2_nobless(64);
            my $r = ${__PACKAGE__->phi};
            Math::MPFR::Rmpfr_log($t, $r, $ROUND);
            $t;
        };

        my $f = _any2mpfr($n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::MPFR::Rmpfr_log($f, $f, $ROUND);
        Math::MPFR::Rmpfr_div($f, $f, $log_phi, $ROUND);
        Math::MPFR::Rmpfr_round($f, $f);

        state $t = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_lucnum_ui($t, Math::MPFR::Rmpfr_get_ui($f, $ROUND));

        (Math::GMPz::Rmpz_cmp($t, $n) == 0)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_cyclic {    # OEIS: A003277
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE;

        (Math::Prime::Util::GMP::gcd(Math::Prime::Util::GMP::totient($n), $n) eq '1')
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_carmichael {    # OEIS: A002997
        my ($n) = @_;

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        # Small or even
        Math::GMPz::Rmpz_odd_p($n)            or return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_cmp_ui($n, 561) >= 0 or return Sidef::Types::Bool::Bool::FALSE;

        # If n is a native integer, Math::Prime::Util::is_carmichael() is slighly faster.
        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {
            my $nstr = Math::GMPz::Rmpz_get_ui($n);
            return (
                    (
                     HAS_PRIME_UTIL ? Math::Prime::Util::is_carmichael($nstr)
                     : Math::Prime::Util::GMP::is_carmichael($nstr)
                    ) ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        # If n is large enough, Math::Prime::Util::GMP::is_carmichael() uses a probable test.
        if (Math::GMPz::Rmpz_sizeinbase($n, 10) > 50) {
            my $nstr = Math::GMPz::Rmpz_get_str($n, 10);
            return (
                    Math::Prime::Util::GMP::is_carmichael($nstr)
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        state $nm1 = Math::GMPz::Rmpz_init_nobless();
        state $pm1 = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_sub_ui($nm1, $n, 1);

        # Divisible by a small square
        foreach my $p (3, 5, 7, 11, 13, 17, 19) {
            if (Math::GMPz::Rmpz_divisible_ui_p($n, $p)) {

                if (Math::GMPz::Rmpz_divisible_ui_p($n, $p * $p)) {
                    return Sidef::Types::Bool::Bool::FALSE;
                }

                Math::GMPz::Rmpz_divisible_ui_p($nm1, $p - 1)
                  || return Sidef::Types::Bool::Bool::FALSE;
            }
            else {
                Math::GMPz::Rmpz_set_ui($pm1, $p);
                Math::GMPz::Rmpz_powm($pm1, $pm1, $nm1, $n);
                Math::GMPz::Rmpz_cmp_ui($pm1, 1) == 0
                  or return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        # Must be a Fermat pseudoprime to base 2.
        Math::GMPz::Rmpz_powm($pm1, $TWO, $nm1, $n);
        Math::GMPz::Rmpz_cmp_ui($pm1, 1) == 0
          or return Sidef::Types::Bool::Bool::FALSE;

        my $check_conditions = sub {

            my %seen;
            foreach my $p (@_) {

                if ($seen{$p}++) {    # not squarefree
                    return;
                }

                # Check the Korselt criterion: p-1 | n-1, for each prime p|n.
                if ($p < ULONG_MAX) {
                    Math::GMPz::Rmpz_divisible_ui_p($nm1, $p - 1) || return;
                }
                else {
                    Math::GMPz::Rmpz_set_str($pm1, $p, 10);
                    Math::GMPz::Rmpz_sub_ui($pm1, $pm1, 1);
                    Math::GMPz::Rmpz_divisible_p($nm1, $pm1) || return;
                }
            }

            return 1;
        };

        my $omega     = 0;
        my $remainder = $n;

        if (!Math::GMPz::Rmpz_fits_ulong_p($n)) {

            my ($r, @factors) = _adaptive_trial_factor($n);

            if (@factors) {

                $check_conditions->(@factors)
                  || return Sidef::Types::Bool::Bool::FALSE;

                if (Math::GMPz::Rmpz_cmp_ui($r, 1) == 0) {
                    return Sidef::Types::Bool::Bool::TRUE;
                }

                $omega += scalar(@factors);
                $remainder = $r;
            }
        }

        my @factors = map { ref($_) ? Math::GMPz::Rmpz_get_str($_, 10) : $_ } _miller_factor($remainder);

        if (scalar(@factors) > 1) {

            my %seen;
            my @composites;

            foreach my $f (@factors) {

                if ($seen{$f}++) {    # not squarefree
                    return Sidef::Types::Bool::Bool::FALSE;
                }

                if (_is_prob_prime($f)) {
                    $check_conditions->($f)
                      || return Sidef::Types::Bool::Bool::FALSE;
                    ++$omega;
                }
                else {
                    push @composites, $f;
                }
            }

            @composites
              || return Sidef::Types::Bool::Bool::TRUE;

            @factors = @composites;
        }

        @factors = map { _factor($_) } @factors;

        $omega += scalar(@factors);

        ($omega >= 3 and $check_conditions->(@factors))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_imprimitive_carmichael {    # OEIS: A328935
        my ($n) = @_;

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        Math::GMPz::Rmpz_cmp_ui($n, 294409) >= 0 or return Sidef::Types::Bool::Bool::FALSE;

        if (HAS_PRIME_UTIL && Math::GMPz::Rmpz_fits_ulong_p($n)) {

            $n = Math::GMPz::Rmpz_get_ui($n);
            Math::Prime::Util::is_carmichael($n) || return Sidef::Types::Bool::Bool::FALSE;
            my @factors = map { $_ - 1 } Math::Prime::Util::factor($n);

            my $gcd = Math::Prime::Util::gcd(@factors);
            my $lcm = Math::Prime::Util::lcm(@factors);

            return (
                    (($gcd * $gcd) > $lcm)
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        (bless \$n)->is_carmichael() || return Sidef::Types::Bool::Bool::FALSE;

        my @factors =
          map { Math::Prime::Util::GMP::subint($_, 1) }
          map { _factor($_) } _miller_factor($n);

        my $gcd = Math::Prime::Util::GMP::gcd(@factors);
        my $lcm = Math::Prime::Util::GMP::lcm(@factors);

        state $x = Math::GMPz::Rmpz_init_nobless();
        state $y = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_set_str($x, $gcd, 10);
        Math::GMPz::Rmpz_set_str($y, $lcm, 10);

        Math::GMPz::Rmpz_mul($x, $x, $x);

        (Math::GMPz::Rmpz_cmp($x, $y) > 0)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_lucas_carmichael {    # OEIS: A006972
        my ($n) = @_;

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        # Small or even
        Math::GMPz::Rmpz_odd_p($n)            or return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_cmp_ui($n, 399) >= 0 or return Sidef::Types::Bool::Bool::FALSE;

        state $np1 = Math::GMPz::Rmpz_init_nobless();
        state $pp1 = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_add_ui($np1, $n, 1);

        # Divisible by a small square
        foreach my $p (3, 5, 7, 11, 13, 17, 19) {
            if (Math::GMPz::Rmpz_divisible_ui_p($n, $p)) {

                if (Math::GMPz::Rmpz_divisible_ui_p($n, $p * $p)) {
                    return Sidef::Types::Bool::Bool::FALSE;
                }

                Math::GMPz::Rmpz_divisible_ui_p($np1, $p + 1)
                  || return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        # my $nstr = Math::GMPz::Rmpz_get_str($n, 10);

        # No Lucas-Carmichael number is known that is also a Carmichael number or a Fermat base-2 pseudoprime.
        # However, it is conjectured that infinitely many such numbers exist.

        # If there exists a squarefree composite number N such that p-1 | N-1 and
        # p+1 | N+1 for every p|N, then N must have an odd number ≥ 5 of prime factors.
        # See: https://www.sciencedirect.com/science/article/pii/S0022314X14002108

        # if (Math::Prime::Util::GMP::is_pseudoprime($nstr, 2)) {
        #     return Sidef::Types::Bool::Bool::FALSE;     # no counter-example is known
        # }

        my $check_conditions = sub {

            my %seen;
            foreach my $p (@_) {

                if ($seen{$p}++) {    # not squarefree
                    return;
                }

                # Check the Lucas-Korselt criterion: p+1 | n+1, for each prime p|n.
                if ($p < ULONG_MAX) {
                    Math::GMPz::Rmpz_divisible_ui_p($np1, $p + 1) || return;
                }
                else {
                    Math::GMPz::Rmpz_set_str($pp1, $p, 10);
                    Math::GMPz::Rmpz_add_ui($pp1, $pp1, 1);
                    Math::GMPz::Rmpz_divisible_p($np1, $pp1) || return;
                }
            }

            return 1;
        };

        my $omega     = 0;
        my $remainder = $n;

        if (!Math::GMPz::Rmpz_fits_ulong_p($n)) {

            my ($r, @factors) = _adaptive_trial_factor($n);

            if (@factors) {

                $check_conditions->(@factors)
                  || return Sidef::Types::Bool::Bool::FALSE;

                if (Math::GMPz::Rmpz_cmp_ui($r, 1) == 0) {
                    return Sidef::Types::Bool::Bool::TRUE;
                }

                $omega += scalar(@factors);
                $remainder = $r;
            }
        }

        my @factors = map { ref($_) ? Math::GMPz::Rmpz_get_str($_, 10) : $_ } _lucas_factor($remainder);

        if (scalar(@factors) > 1) {

            my %seen;
            my @composites;

            foreach my $f (@factors) {

                if ($seen{$f}++) {    # not squarefree
                    return Sidef::Types::Bool::Bool::FALSE;
                }

                if (_is_prob_prime($f)) {
                    $check_conditions->($f)
                      || return Sidef::Types::Bool::Bool::FALSE;
                    ++$omega;
                }
                else {
                    push @composites, $f;
                }
            }

            @composites
              || return Sidef::Types::Bool::Bool::TRUE;

            @factors = @composites;
        }

        @factors = map { _factor($_) } @factors;

        $omega += scalar(@factors);

        ($omega >= 3 and $check_conditions->(@factors))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_absolute_euler_psp {    # OEIS: A033181
        my ($n) = @_;

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        # Small or even
        Math::GMPz::Rmpz_odd_p($n)             or return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_cmp_ui($n, 1729) >= 0 or return Sidef::Types::Bool::Bool::FALSE;

        state $nm1   = Math::GMPz::Rmpz_init_nobless();
        state $nm1d2 = Math::GMPz::Rmpz_init_nobless();
        state $pm1   = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_sub_ui($nm1, $n, 1);
        Math::GMPz::Rmpz_div_2exp($nm1d2, $nm1, 1);

        # Divisible by a small square
        foreach my $p (3, 5, 7, 11, 13, 17, 19) {
            if (Math::GMPz::Rmpz_divisible_ui_p($n, $p)) {

                if (Math::GMPz::Rmpz_divisible_ui_p($n, $p * $p)) {
                    return Sidef::Types::Bool::Bool::FALSE;
                }

                Math::GMPz::Rmpz_divisible_ui_p($nm1d2, $p - 1)
                  || return Sidef::Types::Bool::Bool::FALSE;
            }
            else {
                Math::GMPz::Rmpz_set_ui($pm1, $p);
                Math::GMPz::Rmpz_powm($pm1, $pm1, $nm1d2, $n);
                Math::GMPz::Rmpz_cmp_ui($pm1, 1) == 0
                  or Math::GMPz::Rmpz_cmp($pm1, $nm1) == 0
                  or return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        # If n is a native integer, check if it is a Carmichael number
        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {
            my $nstr = Math::GMPz::Rmpz_get_ui($n);
            (
             HAS_PRIME_UTIL
             ? Math::Prime::Util::is_carmichael($nstr)
             : Math::Prime::Util::GMP::is_carmichael($nstr)
            )
              || return Sidef::Types::Bool::Bool::FALSE;
        }
        else {
            my $nstr = Math::GMPz::Rmpz_get_str($n, 10);

            # Must be an Euler pseudoprime to base 2.
            Math::Prime::Util::GMP::is_euler_pseudoprime($nstr, 2)
              || return Sidef::Types::Bool::Bool::FALSE;

            # If n is large enough, Math::Prime::Util::GMP::is_carmichael() uses a probable test.
            if (Math::GMPz::Rmpz_sizeinbase($n, 10) > 50) {
                Math::Prime::Util::GMP::is_carmichael($nstr)
                  || return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        my $check_conditions = sub {

            my %seen;
            foreach my $p (@_) {

                if ($seen{$p}++) {    # not squarefree
                    return;
                }

                # Check the criterion for absolute Euler pseudoprimes: p-1 | (n-1)/2, for each prime p|n.
                if ($p < ULONG_MAX) {
                    Math::GMPz::Rmpz_divisible_ui_p($nm1d2, $p - 1) || return;
                }
                else {
                    Math::GMPz::Rmpz_set_str($pm1, $p, 10);
                    Math::GMPz::Rmpz_sub_ui($pm1, $pm1, 1);
                    Math::GMPz::Rmpz_divisible_p($nm1d2, $pm1) || return;
                }
            }

            return 1;
        };

        my $omega     = 0;
        my $remainder = $n;

        if (!Math::GMPz::Rmpz_fits_ulong_p($n)) {

            my ($r, @factors) = _adaptive_trial_factor($n);

            if (@factors) {

                $check_conditions->(@factors)
                  || return Sidef::Types::Bool::Bool::FALSE;

                if (Math::GMPz::Rmpz_cmp_ui($r, 1) == 0) {
                    return Sidef::Types::Bool::Bool::TRUE;
                }

                $omega += scalar(@factors);
                $remainder = $r;
            }
        }

        my @factors = map { ref($_) ? Math::GMPz::Rmpz_get_str($_, 10) : $_ } _miller_factor($remainder);

        if (scalar(@factors) > 1) {

            my %seen;
            my @composites;

            foreach my $f (@factors) {

                if ($seen{$f}++) {    # not squarefree
                    return Sidef::Types::Bool::Bool::FALSE;
                }

                if (_is_prob_prime($f)) {
                    $check_conditions->($f)
                      || return Sidef::Types::Bool::Bool::FALSE;
                    ++$omega;
                }
                else {
                    push @composites, $f;
                }
            }

            @composites
              || return Sidef::Types::Bool::Bool::TRUE;

            @factors = @composites;
        }

        @factors = map { _factor($_) } @factors;

        $omega += scalar(@factors);

        ($omega >= 3 and $check_conditions->(@factors))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_abs_euler_psp = \&is_absolute_euler_psp;

    sub is_fundamental {
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::is_fundamental(_big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_smooth_over_prod {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = $$n;
        $k = $$k;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        if (ref($k) ne 'Math::GMPz') {
            __is_int__($k) || return Sidef::Types::Bool::Bool::FALSE;
            $k = _any2mpz($k) // return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_sgn($n) <= 0;
        return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_sgn($k) <= 0;
        return Sidef::Types::Bool::Bool::TRUE  if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

        state $g = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_gcd($g, $n, $k);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
            return Sidef::Types::Bool::Bool::FALSE;
        }

        my $t = Math::GMPz::Rmpz_init_set($n);

        while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            Math::GMPz::Rmpz_remove($t, $t, $g);
            return Sidef::Types::Bool::Bool::TRUE if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
            Math::GMPz::Rmpz_gcd($g, $t, $g);
        }

        return Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_smooth {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = $$n;
        $k = $$k;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        $k = _any2ui($k);

        if (!defined($k) or $k > 1e8) {
            return $_[0]->gpf->le($_[1]);
        }

        return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_sgn($n) <= 0;
        return Sidef::Types::Bool::Bool::TRUE  if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;
        return Sidef::Types::Bool::Bool::FALSE if $k <= 1;

        my $B = _cached_primorial($k);

        state $g = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_gcd($g, $n, $B);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
            return Sidef::Types::Bool::Bool::FALSE;
        }

        my $t = Math::GMPz::Rmpz_init_set($n);

        while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            Math::GMPz::Rmpz_remove($t, $t, $g);
            return Sidef::Types::Bool::Bool::TRUE if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
            Math::GMPz::Rmpz_gcd($g, $t, $g);
        }

        return Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_rough {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = $$n;
        $k = $$k;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        $k = _any2ui($k);

        if (!defined($k) or $k > 1e8) {
            return $_[0]->lpf->ge($_[1]);
        }

        --$k;

        return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_sgn($n) <= 0;
        return Sidef::Types::Bool::Bool::TRUE  if $k <= 1;
        return Sidef::Types::Bool::Bool::TRUE  if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

        my $B = _cached_primorial($k);

        state $g = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_gcd($g, $n, $B);

        (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0)
          ? return Sidef::Types::Bool::Bool::FALSE
          : return Sidef::Types::Bool::Bool::TRUE;
    }

    sub smooth_count {
        my ($k, $from, $to) = @_;

        _valid(\$from);

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $k->smooth_count($to)->sub($k->smooth_count($from->dec));
        }

        my $n = _any2mpz($$from) // return ZERO;
        $k = _any2ui($$k) // return ZERO;

        if ($k < 2 or Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO;
        }

        if (Math::GMPz::Rmpz_cmp_ui($n, $k) <= 0) {
            return bless \$n;
        }

        my $count = sub {
            my ($n, $k) = @_;

            if (!ref($n) or Math::GMPz::Rmpz_fits_slong_p($n)) {

                if (ref($n)) {
                    $k == 2 and return Math::GMPz::Rmpz_sizeinbase($n, 2);
                    $n = Math::GMPz::Rmpz_get_ui($n);
                }

                if ($k == 2) {
                    return 1 + (HAS_PRIME_UTIL ? Math::Prime::Util::logint($n, 2) : Math::Prime::Util::GMP::logint($n, 2));
                }

                use integer;

                my $q   = _prev_prime($k);
                my $sum = 0;

                for (my $t = 1 ; ; $t *= $k) {
                    my $r = $n / $t;
                    if ($r <= $q) {
                        $sum += $r;
                        last;
                    }
                    $sum += __SUB__->($r, $q);
                }

                return $sum;
            }

            my $sum = Math::GMPz::Rmpz_sizeinbase($n, 2);

            if ($k == 2) {
                return $sum;
            }

            my $t = Math::GMPz::Rmpz_init();

            for (my $p = 3 ; $p <= $k ; $p = _next_prime($p)) {

                Math::GMPz::Rmpz_div_ui($t, $n, $p);

                if (Math::GMPz::Rmpz_cmp_ui($t, $p) <= 0) {
                    $sum += Math::GMPz::Rmpz_get_ui($t);
                }
                else {
                    $sum += __SUB__->($t, $p);
                }
            }

            $sum;
          }
          ->($n, _prev_prime($k + 1));

        _set_int($count);
    }

    sub rough_count {
        my ($k, $from, $to) = @_;

        _valid(\$from);

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $k->rough_count($to)->sub($k->rough_count($from->dec));
        }

        my $n = _any2mpz($$from) // return ZERO;
        $k = _any2ui($$k) // return ZERO;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return ZERO;
        }

        if ($k <= 2) {
            return bless \$n;
        }

        if (Math::GMPz::Rmpz_cmp_ui($n, $k) < 0) {
            return TWO if (Math::GMPz::Rmpz_cmp_ui($n, $k) == 0);
            return ONE;
        }

        if (HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            my $r = Math::Prime::Util::legendre_phi(Math::GMPz::Rmpz_get_ui($n), Math::Prime::Util::prime_count($k - 1));
            return _set_int($r);
        }

        my $count = sub {
            my ($n, $p) = @_;

            if (!ref($n) or Math::GMPz::Rmpz_fits_slong_p($n)) {

                $n = Math::GMPz::Rmpz_get_ui($n) if ref($n);

                use integer;

                if ($p * $p > $n) {
                    return 1;
                }

                $p == 2 and return ($n >> 1);
                $p == 3 and return do { my $t = $n / 3; $t - ($t >> 1) };

                my $u = 0;
                my $t = $n / $p;

                for (my $q = 2 ; $q < $p ; $q = _next_prime($q)) {

                    my $v = __SUB__->($t, $q);

                    if ($v == 1) {
                        $u += (HAS_PRIME_UTIL ? Math::Prime::Util::prime_count($q, $p - 1) : _prime_count($q, $p - 1));
                        last;
                    }

                    $u += $v;
                }

                return ($t - $u);
            }

            if (Math::GMPz::Rmpz_cmp_ui($n, $p * $p) < 0) {
                return 1;
            }

            if ($p == 2) {
                return ($n >> 1);
            }

            if ($p == 3) {
                my $t = $n / 3;
                return ($t - ($t >> 1));
            }

            my $u = Math::GMPz::Rmpz_init_set_ui(0);
            my $t = Math::GMPz::Rmpz_init();

            Math::GMPz::Rmpz_div_ui($t, $n, $p);

            for (my $q = 2 ; $q < $p ; $q = _next_prime($q)) {

                my $v = __SUB__->($t, $q);

                if ($v == 1) {
                    Math::GMPz::Rmpz_add_ui(
                                            $u, $u,
                                            (
                                             HAS_PRIME_UTIL
                                             ? Math::Prime::Util::prime_count($q, $p - 1)
                                             : _prime_count($q, $p - 1)
                                            )
                                           );
                    last;
                }

                if (ref($v)) {
                    Math::GMPz::Rmpz_add($u, $u, $v);
                }
                else {
                    Math::GMPz::Rmpz_add_ui($u, $u, $v);
                }
            }

            $t - $u;
          }
          ->($n * $k, $k);

        if (ref($count)) {
            return bless \$count;
        }

        _set_int($count);
    }

    sub legendre_phi {
        my ($n, $k) = @_;
        _valid(\$k);
        $k->inc->nth_prime->rough_count($n);
    }

    sub smooth_part {
        my ($k, $n) = @_;

        _valid(\$n);

        $n = $$n;
        $k = $$k;

        if (ref($n) ne 'Math::GMPz') {
            $n = _any2mpz($n) // goto &nan;
        }

        $k = _any2ui($k) // goto &nan;

        return ZERO if Math::GMPz::Rmpz_sgn($n) <= 0;
        return ONE  if $k <= 1;
        return ONE  if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

        my $B = _cached_primorial($k);

        state $g = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_gcd($g, $n, $B);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
            return ONE;
        }

        my $t = Math::GMPz::Rmpz_init_set($n);

        while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            Math::GMPz::Rmpz_remove($t, $t, $g);
            return (bless \$n) if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
            Math::GMPz::Rmpz_gcd($g, $t, $g);
        }

        Math::GMPz::Rmpz_divexact($t, $n, $t);
        bless \$t;
    }

    sub smooth_divisors {
        my ($k, $n) = @_;
        $k->smooth_part($n)->divisors;
    }

    sub rough_part {
        my ($k, $n) = @_;

        _valid(\$n);

        $n = $$n;
        $k = $$k;

        if (ref($n) ne 'Math::GMPz') {
            $n = _any2mpz($n) // goto &nan;
        }

        $k = _any2ui($k) // goto &nan;

        --$k;

        return ZERO        if Math::GMPz::Rmpz_sgn($n) <= 0;
        return (bless \$n) if $k <= 1;
        return ONE         if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

        my $B = _cached_primorial($k);

        state $g = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_gcd($g, $n, $B);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
            return bless \$n;
        }

        my $t = Math::GMPz::Rmpz_init_set($n);

        while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            Math::GMPz::Rmpz_remove($t, $t, $g);
            return ONE if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
            Math::GMPz::Rmpz_gcd($g, $t, $g);
        }

        bless \$t;
    }

    sub rough_divisors {
        my ($k, $n) = @_;
        $k->rough_part($n)->divisors;
    }

    sub is_prob_squarefree {
        my ($n, $k) = @_;

        if (!defined($k)) {
            state %cache;
            foreach my $k (2 .. 7) {

                $n->is_prob_squarefree(_set_int(10**$k))
                  || return Sidef::Types::Bool::Bool::FALSE;

                my $t = (
                    $cache{$k} //= do {
                        my $z = Math::GMPz::Rmpz_init();
                        Math::GMPz::Rmpz_ui_pow_ui($z, 10, 3 * $k);
                        $z;
                    }
                );

                __cmp__($$n, $t) < 0 and return Sidef::Types::Bool::Bool::TRUE;
            }

            return Sidef::Types::Bool::Bool::TRUE;
        }

        _valid(\$k);
        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;

        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;
        $k = _any2ui($$k)  // return Sidef::Types::Bool::Bool::FALSE;

        return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_sgn($n) <= 0;
        return Sidef::Types::Bool::Bool::FALSE if $k <= 0;
        return Sidef::Types::Bool::Bool::TRUE  if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;
        return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_perfect_power_p($n);

        my $B = _cached_primorial($k);

        state $t = Math::GMPz::Rmpz_init_nobless();
        state $g = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_gcd($g, $n, $B);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {

            return Sidef::Types::Bool::Bool::TRUE if Math::GMPz::Rmpz_cmp($g, $n) == 0;

            Math::GMPz::Rmpz_divexact($t, $n, $g);
            Math::GMPz::Rmpz_gcd($g, $t, $g);

            # Divisible by a small square
            return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_cmp_ui($g, 1) > 0;

            # k-rough part is a perfect power
            return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_perfect_power_p($t);
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub __is_power__ {
        my ($n, $k) = @_;

        # $n is a Math::GMPz object
        # $k is a native signed integer

        # Everything is a first power
        $k == 1 and return 1;

        if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0) {
            return 1;
        }

        # Return true when `n` is -1 and `k` is odd
        if ($k % 2 and Math::GMPz::Rmpz_cmp_si($n, -1) == 0) {
            return 1;
        }

        # Don't accept a non-positive power
        # Also, when `n` is negative and `k` is even, return faster
        if ($k <= 0 or ($k % 2 == 0 and Math::GMPz::Rmpz_sgn($n) < 0)) {
            return 0;
        }

        # Optimization for perfect squares (thanks to Dana Jacobsen)
        $k == 2 and return Math::GMPz::Rmpz_perfect_square_p($n);

        # Return faster if not a perfect power
        Math::GMPz::Rmpz_perfect_power_p($n) || return 0;

        # Check if n = a^k, for some integer `a`, by taking the k-th root of `n`
        state $t = Math::GMPz::Rmpz_init_nobless();
        !!Math::GMPz::Rmpz_root($t, $n, $k);
    }

    sub is_square {
        my ($n) = @_;

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        Math::GMPz::Rmpz_perfect_square_p($n)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_sqr            = \&is_square;
    *is_perfect_square = \&is_square;

    sub is_cube {
        my ($n) = @_;

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        __is_power__($n, 3)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_power {
        my ($n, $k) = @_;

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        if (defined $k) {
            _valid(\$k);

            $k = _any2si($$k) // return undef;

            return (
                    __is_power__($n, $k)
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        Math::GMPz::Rmpz_perfect_power_p($n)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_pp            = \&is_power;
    *is_pow           = \&is_power;
    *is_perfect_power = \&is_power;

    sub power_count {    # OEIS: A069623
        my ($n, $k) = @_;

        if (defined($k)) {
            return $n->iroot($k);
        }

        $n = _any2mpz($$n) // return ZERO;
        Math::GMPz::Rmpz_sgn($n) > 0 or return ZERO;

        # a(n) = n - Sum_{k=1..floor(log_2(n))} μ(k) * (floor(n^(1/k)) - 1).

        my $r = Math::GMPz::Rmpz_init_set_ui(0);
        state $t = Math::GMPz::Rmpz_init_nobless();

        foreach my $k (1 .. __ilog__($n, 2)) {
            my $mu = (HAS_PRIME_UTIL ? Math::Prime::Util::moebius($k) : Math::Prime::Util::GMP::moebius($k)) || next;
            Math::GMPz::Rmpz_root($t, $n, $k);
            Math::GMPz::Rmpz_sub_ui($t, $t, 1);
            ($mu == 1)
              ? Math::GMPz::Rmpz_add($r, $r, $t)
              : Math::GMPz::Rmpz_sub($r, $r, $t);
        }

        Math::GMPz::Rmpz_sub($r, $n, $r);
        bless \$r;
    }

    *perfect_power_count = \&power_count;

    sub is_power_of {
        my ($n, $k) = @_;

        $n = $$n;
        $k = $$k;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        if (ref($k) ne 'Math::GMPz') {
            $k = _any2mpz($k) // return Sidef::Types::Bool::Bool::FALSE;
        }

        if (Math::GMPz::Rmpz_cmp_ui($k, 2) == 0) {
            return (
                    (Math::GMPz::Rmpz_popcount($n) == 1)
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        my $e = __ilog__($n, $k) // return Sidef::Types::Bool::Bool::FALSE;

        state $t = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_pow_ui($t, $k, $e);

        (Math::GMPz::Rmpz_cmp($t, $n) == 0)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub powerful_count {    # count of k-powerful numbers
        my ($k, $from, $to) = @_;

        _valid(\$from);

        if (defined($to)) {
            _valid(\$to);
            return ZERO if $to->lt($from);
            return $k->powerful_count($to)->sub($k->powerful_count($from->dec));
        }

        my $n = _any2mpz($$from) // return ZERO;
        Math::GMPz::Rmpz_sgn($n) > 0 or return ZERO;

        $k = _any2ui($$k) // return ZERO;

        my $t     = Math::GMPz::Rmpz_init();
        my $count = Math::GMPz::Rmpz_init_set_ui(0);

        sub {
            my ($m, $r) = @_;

            Math::GMPz::Rmpz_div($t, $n, $m);
            Math::GMPz::Rmpz_root($t, $t, $r);

            if ($r <= $k) {
                Math::GMPz::Rmpz_add($count, $count, $t);
                return;
            }

            foreach my $v (1 .. $t) {

                if ($r > $k) {
                    (HAS_PRIME_UTIL ? Math::Prime::Util::is_square_free($v) : Math::Prime::Util::GMP::moebius($v)) or next;
                    Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $v) == 1                                        or next;
                }

                Math::GMPz::Rmpz_ui_pow_ui($t, $v, $r);
                __SUB__->($m * $t, $r - 1);
            }
          }
          ->($ONE, 2 * $k - 1);

        bless \$count;
    }

    sub is_powerful {
        my ($n, $k) = @_;

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        Math::GMPz::Rmpz_sgn($n) > 0
          or return Sidef::Types::Bool::Bool::FALSE;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // return Sidef::Types::Bool::Bool::FALSE;
            $k <= 1 and return Sidef::Types::Bool::Bool::TRUE;
        }
        else {
            $k = 2;
        }

        Math::GMPz::Rmpz_divisible_2exp_p($n, 1)
          and !Math::GMPz::Rmpz_divisible_2exp_p($n, 2)
          and return Sidef::Types::Bool::Bool::FALSE;

        foreach my $p (3, 5, 7, 11, 13) {
            Math::GMPz::Rmpz_divisible_ui_p($n, $p)
              and !Math::GMPz::Rmpz_divisible_ui_p($n, $p * $p)
              and return Sidef::Types::Bool::Bool::FALSE;
        }

        state $t = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_root($t, $n, 2 * $k + 1);

        my $trial_limit = 1e6;
        if (Math::GMPz::Rmpz_fits_ulong_p($t)) {
            $trial_limit = Math::GMPz::Rmpz_get_ui($t);
            $trial_limit = 10**(1 + CORE::int(CORE::log($trial_limit) / CORE::log(10)));
            $trial_limit = 1e2 if ($trial_limit < 1e2);
            $trial_limit = 1e6 if ($trial_limit > 1e6);
        }

        my ($rem, @f) = _primorial_trial_factor($n, $trial_limit);

        my %factors;
        ++$factors{$_} for @f;

        foreach my $e (values %factors) {
            $e < $k and return Sidef::Types::Bool::Bool::FALSE;
        }

        if (Math::GMPz::Rmpz_cmp_ui($rem, 1) == 0) {
            return Sidef::Types::Bool::Bool::TRUE;
        }

        if (Math::Prime::Util::GMP::is_power($rem) >= $k) {
            return Sidef::Types::Bool::Bool::TRUE;
        }

        if (Math::GMPz::Rmpz_cmp_ui($t, $trial_limit) < 0) {
            return Sidef::Types::Bool::Bool::FALSE;
        }

        foreach my $pe (_factor_exp($rem)) {
            $pe->[1] < $k and return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub is_perfect {
        my ($n) = @_;

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        Math::GMPz::Rmpz_sgn($n) > 0
          or return Sidef::Types::Bool::Bool::FALSE;

        if (Math::GMPz::Rmpz_odd_p($n)) {    # odd case

            # Reference:
            #   https://en.wikipedia.org/wiki/Perfect_number#Odd_perfect_numbers

            Math::GMPz::Rmpz_sizeinbase($n, 10) > 1500
              or return Sidef::Types::Bool::Bool::FALSE;

            Math::GMPz::Rmpz_divisible_ui_p($n, 105)
              and return Sidef::Types::Bool::Bool::FALSE;

                 Math::GMPz::Rmpz_congruent_ui_p($n, 1, 12)
              or Math::GMPz::Rmpz_congruent_ui_p($n, 117, 468)
              or Math::GMPz::Rmpz_congruent_ui_p($n, 81,  324)
              or return Sidef::Types::Bool::Bool::FALSE;

            my $t = Math::GMPz::Rmpz_init_set_str(Math::Prime::Util::GMP::sigma("$n"), 10);

            return (
                    (Math::GMPz::Rmpz_cmp($t, 2 * $n) == 0)
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        # Here n is even
        state $m = Math::GMPz::Rmpz_init_nobless();

        my $v     = Math::GMPz::Rmpz_remove($m, $n, $TWO);
        my $scan0 = Math::GMPz::Rmpz_scan0($m, 0);

        $scan0 == $v + 1
          or return Sidef::Types::Bool::Bool::FALSE;

        # n must have the form: 2^(k-1)*(2^k - 1)
        $scan0 == Math::GMPz::Rmpz_popcount($m)
          or return Sidef::Types::Bool::Bool::FALSE;

        (
         HAS_PRIME_UTIL ? Math::Prime::Util::is_mersenne_prime($v + 1)
         : Math::Prime::Util::GMP::is_mersenne_prime($v + 1)
          ) ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_prime_power {
        my ($n) = @_;

        $n = $$n;

        if (HAS_PRIME_UTIL and ref($n) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($n)) {
            return (
                    Math::Prime::Util::is_prime_power(Math::GMPz::Rmpz_get_ui($n))
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        __is_int__($n)
          && Math::Prime::Util::GMP::is_prime_power(_big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub prime_root {
        my ($n) = @_;

        my $str = _big2uistr($n) // return $n;
        my $pow = Math::Prime::Util::GMP::is_prime_power($str) || return $n;

        $pow == 1 and return $n;

        my $t = _any2mpz($$n) // return $n;
        my $r = Math::GMPz::Rmpz_init();

        $pow == 2
          ? Math::GMPz::Rmpz_sqrt($r, $t)
          : Math::GMPz::Rmpz_root($r, $t, $pow);

        bless \$r;
    }

    sub prime_power {
        my $pow = Math::Prime::Util::GMP::is_prime_power(&_big2uistr // return ONE) || return ONE;
        $pow == 1 ? ONE : _set_int($pow);
    }

    sub perfect_root {
        my ($n) = @_;

        my $t = _any2mpz($$n) // return $n;
        Math::GMPz::Rmpz_perfect_power_p($t) || return $n;

        my $pow = Math::Prime::Util::GMP::is_power(Math::GMPz::Rmpz_get_str($t, 10)) || return $n;
        my $r   = Math::GMPz::Rmpz_init();

        $pow == 2
          ? Math::GMPz::Rmpz_sqrt($r, $t)
          : Math::GMPz::Rmpz_root($r, $t, $pow);

        bless \$r;
    }

    sub perfect_power {
        _set_int(Math::Prime::Util::GMP::is_power(&_big2istr // return ONE) || return ONE);
    }

    sub next_pow {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;

        Math::GMPz::Rmpz_sgn($x) <= 0 and return ONE;

        my $log = 1 + (__ilog__($x, $y) // goto &nan);

        my $r = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_fits_ulong_p($y)
          ? Math::GMPz::Rmpz_ui_pow_ui($r, Math::GMPz::Rmpz_get_ui($y), $log)
          : Math::GMPz::Rmpz_pow_ui($r, $y, $log);

        bless \$r;
    }

    *next_power = \&next_pow;

    sub prev_pow {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;

        Math::GMPz::Rmpz_sgn($x) <= 0 and goto &nan;

        my $log = (__ilog__($x, $y) // goto &nan);

        my $r = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_fits_ulong_p($y)
          ? Math::GMPz::Rmpz_ui_pow_ui($r, Math::GMPz::Rmpz_get_ui($y), $log)
          : Math::GMPz::Rmpz_pow_ui($r, $y, $log);

        if (Math::GMPz::Rmpz_cmp($r, $x) == 0) {

            if ($log == 0) {
                goto &nan;
            }

            Math::GMPz::Rmpz_divexact($r, $r, $y);
        }

        bless \$r;
    }

    *prev_power = \&prev_pow;

    #
    ## Is a polygonal number?
    #

    sub __is_polygonal__ {
        my ($n, $k, $second) = @_;

        # $n is a Math::GMPz object
        # $k is a Math::GMPz object
        # $second is a boolean

        Math::GMPz::Rmpz_sgn($n) || return 1;

        # polygonal_root(n, k)
        #   = ((k - 4) ± sqrt(8 * (k - 2) * n + (k - 4)^2)) / (2 * (k - 2))

        state $t = Math::GMPz::Rmpz_init_nobless();
        state $u = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_sub_ui($u, $k, 2);      # u = k-2
        Math::GMPz::Rmpz_mul($t, $n, $u);        # t = n*u
        Math::GMPz::Rmpz_mul_2exp($t, $t, 3);    # t = t*8

        Math::GMPz::Rmpz_sub_ui($u, $u, 2);      # u = u-2
        Math::GMPz::Rmpz_mul($u, $u, $u);        # u = u^2

        Math::GMPz::Rmpz_add($t, $t, $u);        # t = t+u
        Math::GMPz::Rmpz_perfect_square_p($t) || return 0;
        Math::GMPz::Rmpz_sqrt($t, $t);           # t = sqrt(t)

        Math::GMPz::Rmpz_sub_ui($u, $k, 4);      # u = k-4

        $second
          ? Math::GMPz::Rmpz_sub($t, $u, $t)     # t = t-u
          : Math::GMPz::Rmpz_add($t, $t, $u);    # t = t+u

        Math::GMPz::Rmpz_add_ui($u, $u, 2);      # u = u+2
        Math::GMPz::Rmpz_mul_2exp($u, $u, 1);    # u = u*2

        Math::GMPz::Rmpz_divisible_p($t, $u);    # true iff u|t
    }

    sub is_polygonal {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = $$n;
        $k = $$k;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        if (ref($k) ne 'Math::GMPz') {
            $k = _any2mpz($k) // return Sidef::Types::Bool::Bool::FALSE;
        }

        __is_polygonal__($n, $k)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_polygonal2 {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = $$n;
        $k = $$k;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        if (ref($k) ne 'Math::GMPz') {
            $k = _any2mpz($k) // return Sidef::Types::Bool::Bool::FALSE;
        }

        __is_polygonal__($n, $k, 1)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    #
    ## Integer polygonal root
    #

    sub __ipolygonal_root__ {
        my ($n, $k, $second) = @_;

        # $n is a Math::GMPz object
        # $k is a Math::GMPz object
        # $second is a boolean

        # polygonal_root(n, k)
        #   = ((k - 4) ± sqrt(8 * (k - 2) * n + (k - 4)^2)) / (2 * (k - 2))

        state $t = Math::GMPz::Rmpz_init_nobless();
        state $u = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_sub_ui($u, $k, 2);      # u = k-2
        Math::GMPz::Rmpz_mul($t, $n, $u);        # t = n*u
        Math::GMPz::Rmpz_mul_2exp($t, $t, 3);    # t = t*8

        Math::GMPz::Rmpz_sub_ui($u, $u, 2);      # u = u-2
        Math::GMPz::Rmpz_mul($u, $u, $u);        # u = u^2
        Math::GMPz::Rmpz_add($t, $t, $u);        # t = t+u

        Math::GMPz::Rmpz_sgn($t) < 0 && goto &_nan;    # `t` is negative

        Math::GMPz::Rmpz_sqrt($t, $t);                 # t = sqrt(t)
        Math::GMPz::Rmpz_sub_ui($u, $k, 4);            # u = k-4

        $second
          ? Math::GMPz::Rmpz_sub($t, $u, $t)           # t = u-t
          : Math::GMPz::Rmpz_add($t, $t, $u);          # t = t+u

        Math::GMPz::Rmpz_add_ui($u, $u, 2);            # u = u+2
        Math::GMPz::Rmpz_mul_2exp($u, $u, 1);          # u = u*2

        Math::GMPz::Rmpz_sgn($u) || return $n;         # `u` is zero

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_div($r, $t, $u);              # r = floor(t/u)
        return $r;
    }

    #
    ## Integer k-gonal root of `n`
    #

    sub ipolygonal_root {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = _any2mpz($$n) // goto &nan;
        $k = _any2mpz($$k) // goto &nan;

        bless \__ipolygonal_root__($n, $k);
    }

    #
    ## Second integer k-gonal root of `n`
    #

    sub ipolygonal_root2 {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = _any2mpz($$n) // goto &nan;
        $k = _any2mpz($$k) // goto &nan;

        bless \__ipolygonal_root__($n, $k, 1);
    }

    #
    ## n-th k-gonal number
    #

    sub polygonal {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = _any2mpz($$n) // goto &nan;
        $k = _any2mpz($$k) // goto &nan;

        # polygonal(n, k) = n * (k*n - k - 2*n + 4) / 2

        my $r = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_mul($r, $n, $k);         # r = n*k
        Math::GMPz::Rmpz_sub($r, $r, $k);         # r = r-k
        Math::GMPz::Rmpz_submul_ui($r, $n, 2);    # r = r-2*n
        Math::GMPz::Rmpz_add_ui($r, $r, 4);       # r = r+4
        Math::GMPz::Rmpz_mul($r, $r, $n);         # r = r*n
        Math::GMPz::Rmpz_div_2exp($r, $r, 1);     # r = r/2

        bless \$r;
    }

    #
    ## Polygonal inverses for a given number
    #

    sub polygonal_inverse {
        my ($n) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;
        Math::GMPz::Rmpz_sgn($n) > 0 or return Sidef::Types::Array::Array->new;

        state $t = Math::GMPz::Rmpz_init_nobless();
        state $u = Math::GMPz::Rmpz_init_nobless();
        state $v = Math::GMPz::Rmpz_init_nobless();

        Math::GMPz::Rmpz_mul_2exp($t, $n, 1);

        my @divisors = _divisors(Math::GMPz::Rmpz_get_str($t, 10));

        shift @divisors;
        pop @divisors;

        my @inverses;

        foreach my $divisor (@divisors) {

            ($divisor < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($u, $divisor)
              : Math::GMPz::Rmpz_set_str($u, $divisor, 10);

            Math::GMPz::Rmpz_divexact($v, $t, $u);
            Math::GMPz::Rmpz_addmul_ui($v, $u, 2);
            Math::GMPz::Rmpz_sub_ui($v, $v, 4);
            Math::GMPz::Rmpz_sub_ui($u, $u, 1);

            if (Math::GMPz::Rmpz_divisible_p($v, $u)) {

                my $r = Math::GMPz::Rmpz_init();
                my $i = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_add_ui($r, $u, 1);
                Math::GMPz::Rmpz_divexact($i, $v, $u);

                push @inverses, Sidef::Types::Array::Array->new([(bless \$r), (bless \$i)]);
            }
        }

        Sidef::Types::Array::Array->new(\@inverses);
    }

    *inverse_polygonal = \&polygonal_inverse;

    #
    ## k-gonal root of `n`
    #

    sub __polygonal_root__ {
        my ($n, $k, $second) = @_;
        goto(join('__', ref($n), ref($k)) =~ tr/:/_/rs);

        # polygonal_root(n, k)
        #   = ((k - 4) ± sqrt(8 * (k - 2) * n + (k - 4)^2)) / (2 * (k - 2))

      Math_MPFR__Math_MPFR: {
            my $t = Math::MPFR::Rmpfr_init2($PREC);
            my $u = Math::MPFR::Rmpfr_init2($PREC);

            Math::MPFR::Rmpfr_sub_ui($u, $k, 2, $ROUND);     # u = k-2
            Math::MPFR::Rmpfr_mul($t, $n, $u, $ROUND);       # t = n*u
            Math::MPFR::Rmpfr_mul_2ui($t, $t, 3, $ROUND);    # t = t*8

            Math::MPFR::Rmpfr_sub_ui($u, $u, 2, $ROUND);     # u = u-2
            Math::MPFR::Rmpfr_sqr($u, $u, $ROUND);           # u = u^2
            Math::MPFR::Rmpfr_add($t, $t, $u, $ROUND);       # t = t+u

            # Return a complex number for `t < 0`
            if (Math::MPFR::Rmpfr_sgn($t) < 0) {
                $n = _mpfr2mpc($n);
                $k = _mpfr2mpc($k);
                goto Math_MPC__Math_MPC;
            }

            Math::MPFR::Rmpfr_sqrt($t, $t, $ROUND);          # t = sqrt(t)
            Math::MPFR::Rmpfr_sub_ui($u, $k, 4, $ROUND);     # u = k-4

            $second
              ? Math::MPFR::Rmpfr_sub($t, $u, $t, $ROUND)     # t = u-t
              : Math::MPFR::Rmpfr_add($t, $t, $u, $ROUND);    # t = t+u

            Math::MPFR::Rmpfr_add_ui($u, $u, 2, $ROUND);      # u = u+2
            Math::MPFR::Rmpfr_mul_2ui($u, $u, 1, $ROUND);     # u = u*2

            Math::MPFR::Rmpfr_zero_p($u) && return $n;        # `u` is zero
            Math::MPFR::Rmpfr_div($t, $t, $u, $ROUND);        # t = t/u
            return $t;
        }

      Math_MPFR__Math_MPC: {
            $n = _mpfr2mpc($n);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_MPFR: {
            $k = _mpfr2mpc($k);
            goto Math_MPC__Math_MPC;
        }

      Math_MPC__Math_MPC: {
            my $t = Math::MPC::Rmpc_init2($PREC);
            my $u = Math::MPC::Rmpc_init2($PREC);

            Math::MPC::Rmpc_sub_ui($u, $k, 2, $ROUND);     # u = k-2
            Math::MPC::Rmpc_mul($t, $n, $u, $ROUND);       # t = n*u
            Math::MPC::Rmpc_mul_2ui($t, $t, 3, $ROUND);    # t = t*8

            Math::MPC::Rmpc_sub_ui($u, $u, 2, $ROUND);     # u = u-2
            Math::MPC::Rmpc_sqr($u, $u, $ROUND);           # u = u^2
            Math::MPC::Rmpc_add($t, $t, $u, $ROUND);       # t = t+u

            Math::MPC::Rmpc_sqrt($t, $t, $ROUND);          # t = sqrt(t)
            Math::MPC::Rmpc_sub_ui($u, $k, 4, $ROUND);     # u = k-4

            $second
              ? Math::MPC::Rmpc_sub($t, $u, $t, $ROUND)     # t = u-t
              : Math::MPC::Rmpc_add($t, $t, $u, $ROUND);    # t = t+u

            Math::MPC::Rmpc_add_ui($u, $u, 2, $ROUND);      # u = u+2
            Math::MPC::Rmpc_mul_2ui($u, $u, 1, $ROUND);     # u = u*2

            if (Math::MPC::Rmpc_cmp_si($t, 0) == 0) {       # `u` is zero
                return $n;
            }

            Math::MPC::Rmpc_div($t, $t, $u, $ROUND);        # t = t/u
            return $t;
        }
    }

    #
    ## k-gonal root of `n`
    #

    sub polygonal_root {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__polygonal_root__(_any2mpfr_mpc($$x), _any2mpfr_mpc($$y));
    }

    #
    ## Second k-gonal root of `n`
    #

    sub polygonal_root2 {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__polygonal_root__(_any2mpfr_mpc($$x), _any2mpfr_mpc($$y), 1);
    }

    sub is_palindrome {
        my ($n, $k) = @_;

        $n = $$n;

        if (ref($n) ne 'Math::GMPz') {
            __is_int__($n) || return Sidef::Types::Bool::Bool::FALSE;
            $n = _any2mpz($n) // return Sidef::Types::Bool::Bool::FALSE;
        }

        if (defined($k)) {
            _valid(\$k);
            $k = _any2mpz($$k) // return Sidef::Types::Bool::Bool::FALSE;
        }

        Math::GMPz::Rmpz_sgn($n) >= 0
          or return Sidef::Types::Bool::Bool::FALSE;

        # Optimization for bases <= 62
        if (!defined($k) or Math::GMPz::Rmpz_cmp_ui($k, 62) <= 0) {

            $k = defined($k) ? Math::GMPz::Rmpz_get_ui($k) : 10;
            $k <= 1 and return Sidef::Types::Bool::Bool::FALSE;

            my $str = Math::GMPz::Rmpz_get_str($n, $k);

            return (
                    ($str eq CORE::reverse($str))
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        my @digits = @{$_[0]->digits($_[1])};
        my $len    = scalar(@digits) - 1;

        foreach my $i (0 .. ($len >> 1)) {
            Math::GMPz::Rmpz_cmp(${$digits[$i]}, ${$digits[$len - $i]})
              && return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    *is_palindromic = \&is_palindrome;

    sub next_palindrome {
        my ($n, $base) = @_;

        $base = defined($base) ? do { _valid(\$base); _any2ui($$base) // goto &nan } : 10;
        $base <= 1 and goto &nan;

        $n = _any2mpz($$n) // goto &nan;

        Math::GMPz::Rmpz_sgn($n) >= 0
          or goto &nan;

        my @d;

        if ($base <= 10) {
            @d = split(//, scalar CORE::reverse Math::GMPz::Rmpz_get_str($n, $base));
        }
        elsif ($base <= 36) {
            @d = map { $DIGITS_36{$_} } split(//, scalar CORE::reverse Math::GMPz::Rmpz_get_str($n, $base));
        }
        elsif ($base <= 62) {
            @d = map { $DIGITS_62{$_} } split(//, scalar CORE::reverse Math::GMPz::Rmpz_get_str($n, $base));
        }
        else {
            @d = map { Math::GMPz::Rmpz_get_ui($$_) } @{$_[0]->digits($_[1])};
        }

        my $l = $#d;
        my $i = ((scalar(@d) + 1) >> 1) - 1;

        my $is_palindrome = 1;

        foreach my $j (0 .. $i) {
            if ($d[$j] != $d[$l - $j]) {
                $is_palindrome = 0;
                last;
            }
        }

        if (!$is_palindrome) {
            my @copy = @d;

            foreach my $i (0 .. $i) {
                $d[$i] = $d[$l - $i];
            }

            my $is_greater = 1;

            foreach my $j (0 .. $i) {
                my $cmp = $d[$i - $j] <=> $copy[$i - $j];

                if ($cmp > 0) {
                    last;
                }
                if ($cmp < 0) {
                    $is_greater = 0;
                    last;
                }
            }

            if ($is_greater) {
                return bless \__digits2num__($base, \@d);
            }
        }

        while ($i >= 0 and $d[$i] == $base - 1) {
            $d[$i] = 0;
            $d[$l - $i] = 0;
            $i--;
        }

        if ($i >= 0) {
            $d[$i]++;
            $d[$l - $i] = $d[$i];
        }
        else {
            @d     = (0) x (scalar(@d) + 1);
            $d[0]  = 1;
            $d[-1] = 1;
        }

        bless \__digits2num__($base, \@d);
    }

    sub reverse {
        my ($n, $k) = @_;

        $n = _any2mpz($$n) // goto &nan;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2mpz($$k) // goto &nan;
        }

        # Optimization for bases <= 62
        if (!defined($k) or Math::GMPz::Rmpz_cmp_ui($k, 62) <= 0) {

            $k = defined($k) ? Math::GMPz::Rmpz_get_ui($k) : 10;
            $k <= 1 and goto &nan;

            my $str = scalar(CORE::reverse(Math::GMPz::Rmpz_get_str($n, $k))) =~ s/^0+//r;

            $str || return ZERO;

            if (substr($str, -1) eq '-') {    # support for negative numbers
                chop($str);
                $str = "-$str";
            }

            if ($k == 10) {
                return _set_int($str);
            }

            return bless \Math::GMPz::Rmpz_init_set_str("$str", $k);
        }

        $_[0]->digits($_[1])->flip->digits2num($_[1])->mul($_[0]->sgn);
    }

    *flip = \&reverse;

    sub rotate {
        my ($n, $k, $base) = @_;

        _valid(\$k);
        _valid(\$base) if defined($base);

        $n->digits($base)->rotate($k->neg)->digits2num($base);
    }

    sub shift_left {
        my ($x, $y) = @_;

        _valid(\$y);

        $y = _any2si($$y)  // (goto &nan);
        $x = _any2mpz($$x) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();

        $y < 0
          ? Math::GMPz::Rmpz_div_2exp($r, $x, -$y)
          : Math::GMPz::Rmpz_mul_2exp($r, $x, $y);

        bless \$r;
    }

    *lsft = \&shift_left;

    sub shift_right {
        my ($x, $y) = @_;

        _valid(\$y);

        $y = _any2si($$y)  // (goto &nan);
        $x = _any2mpz($$x) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();

        $y < 0
          ? Math::GMPz::Rmpz_mul_2exp($r, $x, -$y)
          : Math::GMPz::Rmpz_div_2exp($r, $x, $y);

        bless \$r;
    }

    *rsft = \&shift_right;

    #
    ## Rational specific
    #

    sub numerator {
        my ($x) = @_;

        my $r = $$x;
        while (1) {

            if (ref($r) eq 'Math::GMPq') {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPq::Rmpq_get_num($z, $r);
                return bless \$z;
            }

            ref($r) eq 'Math::GMPz' and return $x;    # is an integer

            $r = _any2mpq($r) // (goto &nan);
        }
    }

    *nu = \&numerator;

    sub denominator {
        my ($x) = @_;

        my $r = $$x;
        while (1) {

            if (ref($r) eq 'Math::GMPq') {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPq::Rmpq_get_den($z, $r);
                return bless \$z;
            }

            ref($r) eq 'Math::GMPz' and return ONE;    # is an integer

            $r = _any2mpq($r) // (goto &nan);
        }
    }

    *de = \&denominator;

    sub nude {
        ($_[0]->numerator, $_[0]->denominator);
    }

    #
    ## Conversion/Miscellaneous
    #

    sub chr {
        my ($x) = @_;
        Sidef::Types::String::String->new(CORE::chr(__numify__($$x)));
    }

    sub __round__ {
        my ($x, $prec) = @_;

        goto(ref($x) =~ tr/:/_/rs);

      Math_MPFR: {
            my $nth = -CORE::int($prec);

            my $p = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_str($p, '1e' . CORE::abs($nth), 10, $ROUND);

            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            if ($nth < 0) {
                Math::MPFR::Rmpfr_div($r, $x, $p, $ROUND);
            }
            else {
                Math::MPFR::Rmpfr_mul($r, $x, $p, $ROUND);
            }

            Math::MPFR::Rmpfr_round($r, $r);

            if ($nth < 0) {
                Math::MPFR::Rmpfr_mul($r, $r, $p, $ROUND);
            }
            else {
                Math::MPFR::Rmpfr_div($r, $r, $p, $ROUND);
            }

            return $r;
        }

      Math_MPC: {
            my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($real, $x);
            Math::MPC::RMPC_IM($imag, $x);

            $real = __SUB__->($real, $prec);
            $imag = __SUB__->($imag, $prec);

            if (Math::MPFR::Rmpfr_zero_p($imag)) {
                return $real;
            }

            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_fr_fr($r, $real, $imag, $ROUND);
            return $r;
        }

      Math_GMPq: {
            my $nth = -CORE::int($prec);

            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set($r, $x);

            my $sgn = Math::GMPq::Rmpq_sgn($r);

            if ($sgn < 0) {
                Math::GMPq::Rmpq_neg($r, $r);
            }

            my $p = Math::GMPz::Rmpz_init_set_str('1' . ('0' x CORE::abs($nth)), 10);

            if ($nth < 0) {
                Math::GMPq::Rmpq_div_z($r, $r, $p);
            }
            else {
                Math::GMPq::Rmpq_mul_z($r, $r, $p);
            }

            state $half = do {
                my $q = Math::GMPq::Rmpq_init_nobless();
                Math::GMPq::Rmpq_set_ui($q, 1, 2);
                $q;
            };

            Math::GMPq::Rmpq_add($r, $r, $half);

            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $r);

            if (Math::GMPz::Rmpz_odd_p($z) and Math::GMPq::Rmpq_integer_p($r)) {
                Math::GMPz::Rmpz_sub_ui($z, $z, 1);
            }

            Math::GMPq::Rmpq_set_z($r, $z);

            if ($nth < 0) {
                Math::GMPq::Rmpq_mul_z($r, $r, $p);
            }
            else {
                Math::GMPq::Rmpq_div_z($r, $r, $p);
            }

            if ($sgn < 0) {
                Math::GMPq::Rmpq_neg($r, $r);
            }

            if (Math::GMPq::Rmpq_integer_p($r)) {
                Math::GMPz::Rmpz_set_q($z, $r);
                return $z;
            }

            return $r;
        }

      Math_GMPz: {
            return $x if ($prec == 0);
            $x = _mpz2mpq($x);
            goto Math_GMPq;
        }
    }

    sub round {
        my ($x, $prec) = @_;

        my $nth = (
            defined($prec)
            ? do {
                _valid(\$prec);
                _any2si($$prec) // (goto &nan);
              }
            : 0
        );

        bless \__round__($$x, $nth);
    }

    *roundf = \&round;

    sub to {
        my ($from, $to, $step) = @_;
        Sidef::Types::Range::RangeNumber->new($from, $to, $step // ONE);
    }

    *upto = \&to;

    sub downto {
        my ($from, $to, $step) = @_;
        Sidef::Types::Range::RangeNumber->new($from, $to, defined($step) ? $step->neg : MONE);
    }

    sub xto {
        my ($from, $to, $step) = @_;

        $to =
          defined($step)
          ? $to->sub($step)
          : $to->dec;

        Sidef::Types::Range::RangeNumber->new($from, $to, $step // ONE);
    }

    *xupto = \&xto;

    sub xdownto {
        my ($from, $to, $step) = @_;

        $from =
          defined($step)
          ? $from->sub($step)
          : $from->dec;

        Sidef::Types::Range::RangeNumber->new($from, $to, defined($step) ? $step->neg : MONE);
    }

    sub range {
        my ($from, $to, $step) = @_;

        defined($to)
          ? $from->to($to, $step)
          : (ZERO)->to($from->dec);
    }

    {
        my $srand = srand();

        {
            state $state = Math::MPFR::Rmpfr_randinit_mt_nobless();
            Math::MPFR::Rmpfr_randseed_ui($state, $srand);

            sub rand {
                my ($x, $y) = @_;

                my $rand = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

                if (defined($y)) {
                    _valid(\$y);
                    Math::MPFR::Rmpfr_urandom($rand, $state, $ROUND);
                    $rand = __mul__($rand, __sub__($$y, $$x));
                    $rand = __add__($rand, $$x);
                }
                else {
                    Math::MPFR::Rmpfr_urandom($rand, $state, $ROUND);
                    $rand = __mul__($rand, $$x);
                }
                bless \$rand;
            }

            sub seed {
                my ($x) = @_;
                my $z = _any2mpz($$x) // die "[ERROR] Number.seed(): invalid seed value <<$x>> (expected an integer)";
                Math::MPFR::Rmpfr_randseed($state, $z);
                bless \$z;
            }
        }

        {
            state $state = Math::GMPz::zgmp_randinit_mt_nobless();
            Math::GMPz::zgmp_randseed_ui($state, $srand);

            sub irand {
                my ($x, $y) = @_;

                if (defined($y)) {
                    _valid(\$y);

                    $x = _any2mpz($$x) // goto &nan;
                    $y = _any2mpz($$y) // goto &nan;

                    my $cmp = Math::GMPz::Rmpz_cmp($y, $x);

                    if ($cmp == 0) {
                        return $_[0];
                    }
                    elsif ($cmp < 0) {
                        ($x, $y) = ($y, $x);
                    }

                    my $r = Math::GMPz::Rmpz_init();
                    Math::GMPz::Rmpz_sub($r, $y, $x);
                    Math::GMPz::Rmpz_add_ui($r, $r, 1);
                    Math::GMPz::Rmpz_urandomm($r, $state, $r, 1);
                    Math::GMPz::Rmpz_add($r, $r, $x);
                    return bless \$r;
                }

                $x = Math::GMPz::Rmpz_init_set(_any2mpz($$x) // goto &nan);

                my $sgn = Math::GMPz::Rmpz_sgn($x)
                  || return ZERO;

                if ($sgn < 0) {
                    Math::GMPz::Rmpz_sub_ui($x, $x, 1);
                }
                else {
                    Math::GMPz::Rmpz_add_ui($x, $x, 1);
                }

                Math::GMPz::Rmpz_urandomm($x, $state, $x, 1);
                Math::GMPz::Rmpz_neg($x, $x) if $sgn < 0;
                bless \$x;
            }

            sub iseed {
                my ($x) = @_;
                my $z = _any2mpz($$x) // die "[ERROR] Number.iseed(): invalid seed value <<$x>> (expected an integer)";
                Math::GMPz::zgmp_randseed($state, $z);
                bless \$z;
            }
        }
    }

    sub of {
        my ($x, $obj, $range) = @_;

        if (defined($range) and ref($obj) eq 'Sidef::Types::Block::Block') {
            return $range->lazy->map($obj)->first($x);
        }

        $x = CORE::int(__numify__($$x));

        if (ref($obj) eq 'Sidef::Types::Block::Block') {
            my @array;
            for (my $i = 0 ; $i < $x ; ++$i) {
                push @array, $obj->run(_set_int($i));
            }
            return Sidef::Types::Array::Array->new(\@array);
        }

        Sidef::Types::Array::Array->new([($obj) x $x]);
    }

    sub by {
        my ($x, $block, $range) = @_;

        if (defined($range) and ref($block) eq 'Sidef::Types::Block::Block') {
            return $block->first($x, $range);
        }

        $x = CORE::int(__numify__($$x));

        my @items;
        for (my ($i, $j) = (0, 0) ; $j < $x ; ++$i) {
            my $k = _set_int($i);
            if ($block->run($k)) {
                push @items, $k;
                ++$j;
            }
        }

        Sidef::Types::Array::Array->new(\@items);
    }

    *first = \&by;

    sub defs {
        my ($x, $block, $range) = @_;

        if (defined($range) and ref($block) eq 'Sidef::Types::Block::Block') {
            state $defined = Sidef::Types::Block::Block->new(code => sub { defined($_[0]) });
            return $range->lazy->map($block)->grep($defined)->first($x);
        }

        $x = CORE::int(__numify__($$x));

        my @items;
        for (my ($i, $j) = (0, 0) ; $j < $x ; ++$i) {
            push @items, $block->run(_set_int($i)) // next;
            ++$j;
        }

        Sidef::Types::Array::Array->new(\@items);
    }

    sub times {
        my ($x, $block) = @_;

        $x = CORE::int(__numify__($$x));

        for (my $i = 0 ; $i < $x ; ++$i) {
            $block->run(_set_int($i));
        }

        return $_[0];
    }

    sub th {
        my ($n, $block, $range) = @_;

        if (ref($block) ne 'Sidef::Types::Block::Block') {
            return undef;
        }

        $block->nth($n, $range);
    }

    *st = \&th;
    *nd = \&th;
    *rd = \&th;

    foreach my $name (
                      qw(
                      permutations
                      circular_permutations
                      derangements
                      )
      ) {
        no strict 'refs';
        *{__PACKAGE__ . '::' . $name} = sub {
#<<<
            my ($n, $block) = @_;
            Sidef::Types::Array::Array->new([map { _set_int($_) } 0 .. __numify__($$n) - 1])->$name($block);
#>>>
        };
    }

    *complete_permutations = \&derangements;

    foreach my $name (
                      qw(
                      subsets
                      variations
                      variations_with_repetition
                      combinations
                      combinations_with_repetition
                      )
      ) {
        no strict 'refs';
        *{__PACKAGE__ . '::' . $name} = sub {
#<<<
            my ($n, $k, $block) = @_;
            Sidef::Types::Array::Array->new([map { _set_int($_) } 0 .. __numify__($$n) - 1])->$name($k, $block);
#>>>
        };
    }

    *tuples                 = \&variations;
    *tuples_with_repetition = \&variations_with_repetition;

    sub bsearch_inverse {
        my ($min, $max, $block) = @_;

        my $prec = CORE::int($PREC);

        my $left   = Math::MPFR::Rmpfr_init2($prec);
        my $right  = Math::MPFR::Rmpfr_init2($prec);
        my $middle = Math::MPFR::Rmpfr_init2($prec);

        if (defined($block)) {
            _valid(\$max);
            Math::MPFR::Rmpfr_set($left,  (_any2mpfr($$min) // return undef), $ROUND);
            Math::MPFR::Rmpfr_set($right, (_any2mpfr($$max) // return undef), $ROUND);
        }
        else {
            $block = $max;
            Math::MPFR::Rmpfr_set($right, (_any2mpfr($$min) // return undef), $ROUND);
            Math::MPFR::Rmpfr_set_ui($left, 0, $ROUND);
        }

        my $prev;

        while (1) {

            Math::MPFR::Rmpfr_add($middle, $left, $right, $ROUND);
            Math::MPFR::Rmpfr_div_2ui($middle, $middle, 1, $ROUND);

            my $item = Math::MPFR::Rmpfr_init2($prec);
            Math::MPFR::Rmpfr_set($item, $middle, $ROUND);

            my $value = bless(\$item, __PACKAGE__);
            my $cmp   = CORE::int($block->run($value)) || return $value;

            if ($cmp > 0) {
                Math::MPFR::Rmpfr_set($right, $middle, $ROUND);
            }
            elsif ($cmp < 0) {
                Math::MPFR::Rmpfr_set($left, $middle, $ROUND);
            }

            if (Math::MPFR::Rmpfr_cmp($left, $right) >= 0) {
                last;
            }

            # Prevent infinite looping
            if (defined($prev) and Math::MPFR::Rmpfr_cmp($prev, $item) == 0) {
                return $value;
            }

            $prev = $item;
        }

        return undef;
    }

    *bsearch_solve = \&bsearch_inverse;

    sub bsearch {
        my ($left, $right, $block) = @_;

        if (defined($block)) {
            _valid(\$right);
            $left  = Math::GMPz::Rmpz_init_set(_any2mpz($$left)  // return undef);
            $right = Math::GMPz::Rmpz_init_set(_any2mpz($$right) // return undef);
        }
        else {
            $block = $right;
            $right = Math::GMPz::Rmpz_init_set(_any2mpz($$left) // return undef);
            $left  = Math::GMPz::Rmpz_init_set_ui(0);
        }

        my $middle = Math::GMPz::Rmpz_init();

        while (Math::GMPz::Rmpz_cmp($left, $right) <= 0) {

            Math::GMPz::Rmpz_add($middle, $left, $right);
            Math::GMPz::Rmpz_div_2exp($middle, $middle, 1);

            my $item = bless \Math::GMPz::Rmpz_init_set($middle);
            my $cmp  = CORE::int($block->run($item)) || return $item;

            if ($cmp > 0) {
                Math::GMPz::Rmpz_sub_ui($right, $middle, 1);
            }
            else {
                Math::GMPz::Rmpz_add_ui($left, $middle, 1);
            }
        }

        return undef;
    }

    sub bsearch_ge {
        my ($left, $right, $block) = @_;

        if (defined($block)) {
            _valid(\$right);
            $left  = Math::GMPz::Rmpz_init_set(_any2mpz($$left)  // return undef);
            $right = Math::GMPz::Rmpz_init_set(_any2mpz($$right) // return undef);
        }
        else {
            $block = $right;
            $right = Math::GMPz::Rmpz_init_set(_any2mpz($$left) // return undef);
            $left  = Math::GMPz::Rmpz_init_set_ui(0);
        }

        my $middle = Math::GMPz::Rmpz_init();

        while (1) {

            Math::GMPz::Rmpz_add($middle, $left, $right);
            Math::GMPz::Rmpz_div_2exp($middle, $middle, 1);

            my $item = bless \Math::GMPz::Rmpz_init_set($middle);
            my $cmp  = CORE::int($block->run($item)) || return $item;

            if ($cmp < 0) {
                Math::GMPz::Rmpz_add_ui($left, $middle, 1);

                if (Math::GMPz::Rmpz_cmp($left, $right) > 0) {
                    Math::GMPz::Rmpz_add_ui($middle, $middle, 1);
                    last;
                }
            }
            else {
                Math::GMPz::Rmpz_sub_ui($right, $middle, 1);
                Math::GMPz::Rmpz_cmp($left, $right) > 0 and last;
            }
        }

        bless \$middle;
    }

    sub bsearch_le {
        my ($left, $right, $block) = @_;

        if (defined($block)) {
            _valid(\$right);
            $left  = Math::GMPz::Rmpz_init_set(_any2mpz($$left)  // return undef);
            $right = Math::GMPz::Rmpz_init_set(_any2mpz($$right) // return undef);
        }
        else {
            $block = $right;
            $right = Math::GMPz::Rmpz_init_set(_any2mpz($$left) // return undef);
            $left  = Math::GMPz::Rmpz_init_set_ui(0);
        }

        my $middle = Math::GMPz::Rmpz_init();

        while (1) {

            Math::GMPz::Rmpz_add($middle, $left, $right);
            Math::GMPz::Rmpz_div_2exp($middle, $middle, 1);

            my $item = bless \Math::GMPz::Rmpz_init_set($middle);
            my $cmp  = CORE::int($block->run($item)) || return $item;

            if ($cmp < 0) {
                Math::GMPz::Rmpz_add_ui($left, $middle, 1);
                Math::GMPz::Rmpz_cmp($left, $right) > 0 and last;
            }
            else {
                Math::GMPz::Rmpz_sub_ui($right, $middle, 1);
                if (Math::GMPz::Rmpz_cmp($left, $right) > 0) {
                    Math::GMPz::Rmpz_sub_ui($middle, $middle, 1);
                    last;
                }
            }
        }

        bless \$middle;
    }

    sub bsearch_min {
        my ($left, $right, $block) = @_;

        if (defined($block)) {
            _valid(\$right);
            $left  = Math::GMPz::Rmpz_init_set(_any2mpz($$left)  // return undef);
            $right = Math::GMPz::Rmpz_init_set(_any2mpz($$right) // return undef);
        }
        else {
            $block = $right;
            $right = Math::GMPz::Rmpz_init_set(_any2mpz($$left) // return undef);
            $left  = Math::GMPz::Rmpz_init_set_ui(0);
        }

        my $middle = Math::GMPz::Rmpz_init();

        while (Math::GMPz::Rmpz_cmp($left, $right) < 0) {

            Math::GMPz::Rmpz_add($middle, $left, $right);
            Math::GMPz::Rmpz_div_2exp($middle, $middle, 1);

            my $item = bless \Math::GMPz::Rmpz_init_set($middle);
            my $cmp  = CORE::int($block->run($item));

            if ($cmp < 0) {
                Math::GMPz::Rmpz_add_ui($left, $middle, 1);
            }
            else {
                Math::GMPz::Rmpz_set($right, $middle);
            }
        }

        bless \$left;
    }

    sub bsearch_max {
        my ($left, $right, $block) = @_;

        if (defined($block)) {
            _valid(\$right);
            $left  = Math::GMPz::Rmpz_init_set(_any2mpz($$left)  // return undef);
            $right = Math::GMPz::Rmpz_init_set(_any2mpz($$right) // return undef);
        }
        else {
            $block = $right;
            $right = Math::GMPz::Rmpz_init_set(_any2mpz($$left) // return undef);
            $left  = Math::GMPz::Rmpz_init_set_ui(0);
        }

        my $middle = Math::GMPz::Rmpz_init();

        while (Math::GMPz::Rmpz_cmp($left, $right) < 0) {

            Math::GMPz::Rmpz_add($middle, $left, $right);
            Math::GMPz::Rmpz_div_2exp($middle, $middle, 1);
            Math::GMPz::Rmpz_add_ui($middle, $middle, 1);

            my $item = bless \Math::GMPz::Rmpz_init_set($middle);
            my $cmp  = CORE::int($block->run($item));

            if ($cmp > 0) {
                Math::GMPz::Rmpz_sub_ui($right, $middle, 1);
            }
            else {
                Math::GMPz::Rmpz_set($left, $middle);
            }
        }

        bless \$right;
    }

    sub commify {
        my ($self) = @_;

        my $n = "$self";

        my $x   = $n;
        my $neg = $n =~ s{^-}{};
        $n =~ /\.|$/;

        if ($-[0] > 3) {

            my $l = $-[0] - 3;
            my $i = ($l - 1) % 3 + 1;

            $x = substr($n, 0, $i) . ',';

            while ($i < $l) {
                $x .= substr($n, $i, 3) . ',';
                $i += 3;
            }

            $x .= substr($n, $i);
        }

        Sidef::Types::String::String->new(($neg ? '-' : '') . $x);
    }

    #
    ## Conversions
    #

    sub rad2deg {
        my ($x) = @_;
        my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_pi($f, $ROUND);
        Math::MPFR::Rmpfr_ui_div($f, 180, $f, $ROUND);
        bless \__mul__($f, $$x);
    }

    sub deg2rad {
        my ($x) = @_;
        my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_pi($f, $ROUND);
        Math::MPFR::Rmpfr_div_ui($f, $f, 180, $ROUND);
        bless \__mul__($f, $$x);
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}   = \&div;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '%'}   = \&mod;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'}   = \&le;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'}   = \&ge;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'}   = \&ne;
        *{__PACKAGE__ . '::' . '..'}  = \&to;
        *{__PACKAGE__ . '::' . '..^'} = \&xto;
        *{__PACKAGE__ . '::' . '^..'} = \&xdownto;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
        *{__PACKAGE__ . '::' . '!!'}  = \&double_factorial;
        *{__PACKAGE__ . '::' . '%%'}  = \&is_div;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
        *{__PACKAGE__ . '::' . ':'}   = \&pair;
        *{__PACKAGE__ . '::' . '//'}  = \&idiv;
        *{__PACKAGE__ . '::' . '=~='} = \&approx_eq;
        *{__PACKAGE__ . '::' . '≅'}   = \&approx_eq;
        *{__PACKAGE__ . '::' . '<~>'} = \&approx_cmp;
    }
}

1
