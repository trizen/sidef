package Sidef::Types::Number::Number {

    use utf8;
    use 5.016;

    use Math::MPFR qw();
    use Math::GMPq qw();
    use Math::GMPz qw();
    use Math::MPC qw();

    use List::Util qw();
    use Math::Prime::Util::GMP qw();

    use constant {
                  ULONG_MAX => Math::GMPq::_ulong_max(),
                  LONG_MIN  => Math::GMPq::_long_min(),
                 };

    our ($ROUND, $PREC);

    BEGIN {
        $ROUND = Math::MPFR::MPFR_RNDN();
        $PREC  = 192;
    }

    my $MPZ = bless \Math::GMPz::Rmpz_init();

    state $round_z = Math::MPFR::MPFR_RNDZ();

    state $MONE = Math::GMPz::Rmpz_init_set_si(-1);
    state $ZERO = Math::GMPz::Rmpz_init_set_ui(0);
    state $ONE  = Math::GMPz::Rmpz_init_set_ui(1);
    state $TWO  = Math::GMPz::Rmpz_init_set_ui(2);
    state $FOUR = Math::GMPz::Rmpz_init_set_ui(4);
    state $TEN  = Math::GMPz::Rmpz_init_set_ui(10);

    state $HAS_PRIME_UTIL = eval { require Math::Prime::Util; 1 };

#<<<
    use constant {
          ONE  => bless(\$ONE),
          TWO  => bless(\$TWO),
          ZERO => bless(\$ZERO),
          MONE => bless(\$MONE),
    };
#>>>

    use parent qw(Sidef::Object::Object);

    use overload
      q{bool} => sub { (@_) = (${$_[0]}); goto &__boolify__ },
      q{0+}   => sub { (@_) = (${$_[0]}); goto &__numify__ },
      q{""}   => sub { (@_) = (${$_[0]}); goto &__stringify__ };

    use Sidef::Types::Bool::Bool;

    my @cache = (ZERO, ONE);

    sub new {
        my (undef, $num, $base) = @_;

        if (ref($base)) {
            if (ref($base) eq __PACKAGE__) {
                $base = _any2ui($$base) // 0;
            }
            else {
                $base = CORE::int($base);
            }
        }

        my $ref = ref($num);

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

        # Special objects
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

    require Devel::Peek;

    sub _set_uint {
        ($_[1] <= 8192)
          ? ($cache[$_[1]] //= bless \Math::GMPz::Rmpz_init_set_ui($_[1]))
          : do {
            if (Devel::Peek::SvREFCNT($MPZ) > 0) {
                $MPZ = bless \Math::GMPz::Rmpz_init_set_ui($_[1]);
            }
            else {
                Math::GMPz::Rmpz_set_ui($$MPZ, $_[1]);
            }
            $MPZ;
        }
    }

    sub _set_int {
        $_[1] == -1 && return MONE;
        $_[1] >= 0  && goto &_set_uint;

        if (Devel::Peek::SvREFCNT($MPZ) > 0) {
            $MPZ = bless \Math::GMPz::Rmpz_init_set_si($_[1]);
        }
        else {
            Math::GMPz::Rmpz_set_si($$MPZ, $_[1]);
        }

        $MPZ;
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
        my (undef, $type, $str) = @_;

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

        # Complex number
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
                else {    # this should never happen
                    $re = _any2mpfr($re);
                    $im = _any2mpfr($im);
                    Math::MPC::Rmpc_set_fr_fr($r, $re, $im, $ROUND);
                }

                return $r;
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
                goto &Math::GMPz::Rmpz_get_ui;
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
                push @_, $ROUND;
                goto &Math::MPFR::Rmpfr_get_ui;
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
                goto &Math::GMPz::Rmpz_get_si;
            }

            if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
                goto &Math::GMPz::Rmpz_get_ui;
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
                    push @_, $ROUND;
                    goto &Math::MPFR::Rmpfr_get_si;
                }

                if (Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
                    push @_, $ROUND;
                    goto &Math::MPFR::Rmpfr_get_ui;
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

        $x = $$x                            if ref($x) eq __PACKAGE__;
        $x = (_any2mpz($x) // return undef) if ref($x) ne 'Math::GMPz';

        return Math::GMPz::Rmpz_get_si($x)
          if Math::GMPz::Rmpz_fits_slong_p($x);

        Math::GMPz::Rmpz_get_str($x, 10);
    }

    # Big to unsigned (non-negative) integer-string
    sub _big2uistr {
        my ($x) = @_;

        $x = $$x                            if ref($x) eq __PACKAGE__;
        $x = (_any2mpz($x) // return undef) if ref($x) ne 'Math::GMPz';

        return Math::GMPz::Rmpz_get_ui($x)
          if Math::GMPz::Rmpz_fits_ulong_p($x);

        Math::GMPz::Rmpz_sgn($x) >= 0 or return undef;
        Math::GMPz::Rmpz_get_str($x, 10);
    }

    # Big to positive integer-string
    sub _big2pistr {
        my ($x) = @_;

        $x = $$x                            if ref($x) eq __PACKAGE__;
        $x = (_any2mpz($x) // return undef) if ref($x) ne 'Math::GMPz';

        if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
            my $ui = Math::GMPz::Rmpz_get_ui($x);
            $ui > 0 or return undef;
            return $ui;
        }

        Math::GMPz::Rmpz_sgn($x) > 0 or return undef;
        Math::GMPz::Rmpz_get_str($x, 10);
    }

    #
    ## Binary splitting
    #

    sub _binsplit {
        my ($arr, $func) = @_;

        my $sub = sub {
            my ($s, $n, $m) = @_;

            $n == $m
              ? $s->[$n]
              : $func->(__SUB__->($s, $n, ($n + $m) >> 1), __SUB__->($s, (($n + $m) >> 1) + 1, $m));
        };

        my $end = $#$arr;

        if ($end <= 1e5) {
            return $sub->($arr, 0, $end);
        }

        my @partial;

        while (@$arr) {
            my @head = splice(@$arr, 0, 1e5);
            push @partial, $sub->(\@head, 0, $#head);
        }

        __SUB__->(\@partial, $func);
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

                ## say ":: Sieving ($from, $upto) with step = $step";
                @buffer = @{$buffer_callback->($from, $upto)};
                $from   = $upto + 1;
                @buffer || next;
            }

            my $number = shift(@buffer);

            if ($number < ULONG_MAX) {
                $number = __PACKAGE__->_set_uint($number);
            }
            else {
                $number = bless \Math::GMPz::Rmpz_init_set_str("$number", 10);
            }

            ++$count;
            $block->run($number);
        }

        __PACKAGE__->_set_uint($count);
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
                goto &Math::GMPz::Rmpz_get_si;
            }

            if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
                goto &Math::GMPz::Rmpz_get_ui;
            }

            goto &Math::GMPz::Rmpz_get_d;
        }

      Math_GMPq: {

            if (Math::GMPq::Rmpq_integer_p($x)) {
                @_ = ($x = _mpq2mpz($x));
                goto Math_GMPz;
            }

            goto &Math::GMPq::Rmpq_get_d;
        }

      Math_MPFR: {
            push @_, $ROUND;

            if (Math::MPFR::Rmpfr_integer_p($x)) {
                if (Math::MPFR::Rmpfr_fits_slong_p($x, $ROUND)) {
                    goto &Math::MPFR::Rmpfr_get_si;
                }

                if (Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
                    goto &Math::MPFR::Rmpfr_get_ui;
                }
            }

            goto &Math::MPFR::Rmpfr_get_d;
        }

      Math_MPC: {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_RE($r, $x);
            @_ = ($x = $r);
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
            push @_, 10;
            goto &Math::GMPz::Rmpz_get_str;
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

            $im = '' if $im eq '1';
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

    *conjug    = \&conj;
    *conjugate = \&conj;

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

    #
    ## CONSTANTS
    #

    sub pi {
        my $pi = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_pi($pi, $ROUND);
        bless \$pi;
    }

    sub tau {
        my $tau = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_pi($tau, $ROUND);
        Math::MPFR::Rmpfr_mul_2ui($tau, $tau, 1, $ROUND);
        bless \$tau;
    }

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

    *Y           = \&EulerGamma;
    *euler_gamma = \&EulerGamma;

    sub CatalanG {
        my $catalan = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_catalan($catalan, $ROUND);
        bless \$catalan;
    }

    *C         = \&CatalanG;
    *catalan_G = \&CatalanG;

    sub i {
        my ($x) = @_;

        state $i = do {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_ui_ui($c, 0, 1, $ROUND);
            $c;
        };

        if (ref($x) eq __PACKAGE__) {
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

        if (ref($_[0]) eq __PACKAGE__) {
            return $_[0]->euler_phi;
        }

        state $five4_f = (Math::MPFR::Rmpfr_init_set_d_nobless(1.25, $ROUND))[0];

        my $phi = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_sqrt($phi, $five4_f, $ROUND);
        Math::MPFR::Rmpfr_add_d($phi, $phi, 0.5, $ROUND);

        bless \$phi;
    }

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
        _valid(\$y);
        bless \__div__($$x, $$y);
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
        Math::GMPz::Rmpz_tdiv_q($r, $x, $y);
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
            state $three_inv = do {
                my $r = Math::MPC::Rmpc_init2_nobless(CORE::int($PREC));
                Math::MPC::Rmpc_set_ui($r, 3, $ROUND);
                Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
                $r;
            };

            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_pow($r, $x, $three_inv, $ROUND);
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
            $y = _mpq2mpc($y);
            goto Math_MPC__Math_MPC;
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
            Math::GMPz::Rmpz_tdiv_q($r, $ONE, $r);
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

            my $e = (Math::GMPz::Rmpz_sizeinbase($x, $y) || return) - 1;

            if ($e > 0) {
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
            __PACKAGE__->_set_uint(__ilog__((_any2mpz($$x) // goto &nan), (_any2mpz($$y) // goto &nan)) // goto &nan);
        }
        else {
            bless \(_any2mpz(__log__(_any2mpfr_mpc($$x))) // goto &nan);
        }
    }

    sub ilog2 {
        my ($x) = @_;
        __PACKAGE__->_set_uint(__ilog__((_any2mpz($$x) // goto &nan), 2) // goto &nan);
    }

    sub ilog10 {
        my ($x) = @_;
        __PACKAGE__->_set_uint(__ilog__((_any2mpz($$x) // goto &nan), 10) // goto &nan);
    }

    sub msb {
        my ($n) = @_;

        $n = _any2mpz($$n) // return undef;
        Math::GMPz::Rmpz_sgn($n) || return undef;

        __PACKAGE__->_set_uint(Math::GMPz::Rmpz_sizeinbase($n, 2) - 1);
    }

    sub lsb {
        my ($n) = @_;

        $n = _any2mpz($$n) // return undef;
        Math::GMPz::Rmpz_sgn($n) || return undef;

        __PACKAGE__->_set_uint(Math::GMPz::Rmpz_scan1($n, 0));
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
        my ($x) = @_;
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

        _valid(\$x);

        $n = _any2ui($$n) // goto &nan;
        $x = $$x;

        my @B = _bernoulli_numbers($n);

        my $u = $n + 1;
        my $z = Math::GMPz::Rmpz_init();
        my $q = Math::GMPq::Rmpq_init();

        my @terms;

        foreach my $k (0 .. $n) {

            --$u & 1 and $u > 1 and next;    # B_n = 0 for odd n > 1

            Math::GMPz::Rmpz_bin_uiui($z, $n, $k);
            Math::GMPq::Rmpq_mul_z($q, $u <= 1 ? $B[$u] : $B[($u >> 1) + 1], $z);

            push @terms, __mul__($k ? __pow__($x, $k) : $ONE, $q);
        }

        bless \_binsplit([CORE::reverse(@terms)], \&__add__);
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

        _valid(\$x);

        $n = $n->inc;
        $x = $x->inc;

        $n->bernoulli_polynomial($x)->sub($n->bernfrac)->div($n);
    }

    sub euler_polynomial {
        my ($n, $x) = @_;

        #
        ## E_n(x) = Sum_{k=0..n} binomial(n, n-k) * euler_number(n-k) / 2^(n-k) * (x - 1/2)^k
        #

        $n = _any2ui($$n) // goto &nan;
        $x = $$x;

        my @S = _secant_numbers($n >> 1);

        my $u = $n + 1;
        my $z = Math::GMPz::Rmpz_init();

        $x = __dec__(__add__($x, $x));    # x = 2*x - 1

        my @terms;

        foreach my $k (0 .. $n) {
            --$u & 1 and next;            # E_n = 0 for all odd n

            Math::GMPz::Rmpz_bin_uiui($z, $n, $u);
            Math::GMPz::Rmpz_mul($z, $z, $S[$u >> 1]);
            Math::GMPz::Rmpz_neg($z, $z) if (($u >> 1) & 1);

            push @terms, ($k ? __mul__(__pow__($x, $k), $z) : Math::GMPz::Rmpz_init_set($z));
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
        my ($n) = @_;

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
        my ($x) = @_;

        $x = _any2mpfr($$x);

        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_add_ui($r, $x, 1, $ROUND);
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
            goto &Math::MPFR::Rmpfr_sgn;
        }

      Math_GMPq: {
            goto &Math::GMPq::Rmpq_sgn;
        }

      Math_GMPz: {
            goto &Math::GMPz::Rmpz_sgn;
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

        __PACKAGE__->_set_uint(Math::GMPz::Rmpz_popcount($z));
    }

    *hammingweight = \&popcount;

    # Hamming distance
    sub hamdist {
        my ($n, $k) = @_;

        _valid(\$k);

        $n = _any2mpz($$n) // return undef;
        $k = _any2mpz($$k) // return undef;

        __PACKAGE__->_set_uint(Math::GMPz::Rmpz_hamdist($n, $k));
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
        _valid(\(@vals));

        my @left;
        my $sum = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $n (@vals) {
            if (ref($$n) eq 'Math::GMPz') {
                Math::GMPz::Rmpz_add($sum, $sum, $$n);
            }
            else {
                push @left, $$n;
            }
        }

        if (@left) {
            $sum = __add__($sum, _binsplit(\@left, \&__add__));
        }

        bless \$sum;
    }

    sub prod {
        my (@vals) = @_;
        @vals || return ONE;
        _valid(\(@vals));
        bless \_binsplit([map { $$_ } @vals], \&__mul__);
    }

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
            Math::GMPz::Rmpz_tdiv_q($z, $t, $z);    # z = floor(t/z)

            Math::GMPz::Rmpz_sgn($z) || return (undef, undef);

            # t = floor((x + y) / z)
            Math::GMPz::Rmpz_add($t, $x, $y);       # t = x+y
            Math::GMPz::Rmpz_tdiv_q($t, $t, $z);    # t = floor(t/z)

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

    sub sqrt_cfrac {
        my ($n, $max) = @_;

        $n   = _any2mpz($$n) // return Sidef::Types::Array::Array->new();
        $max = defined($max) ? CORE::int($max) : (0 + 'inf');

        Math::GMPz::Rmpz_sgn($n) < 0
          and return Sidef::Types::Array::Array->new();

        my $x = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sqrt($x, $n);

        my @cfrac = (bless \$x);

        Math::GMPz::Rmpz_perfect_square_p($n)
          and return Sidef::Types::Array::Array->new(\@cfrac);

        # Optimization for native integers
        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {

            $n = Math::GMPz::Rmpz_get_ui($n);
            $x = Math::GMPz::Rmpz_get_ui($x);

            my @cfrac = __PACKAGE__->_set_uint($x);

            my $y = $x;
            my $z = 1;
            my $r = $x + $x;

            for (my $count = 0 ; $count < $max ; ++$count) {

                $y = $r * $z - $y;
                $z = CORE::int(($n - $y * $y) / $z);
                $r = CORE::int(($x + $y) / $z);

                push @cfrac, __PACKAGE__->_set_uint($r);

                last if $z == 1;
            }

            return Sidef::Types::Array::Array->new(\@cfrac);
        }

        my $y = Math::GMPz::Rmpz_init_set($x);
        my $z = Math::GMPz::Rmpz_init_set_ui(1);
        my $r = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_add($r, $x, $x);    # r = x+x

        for (my $count = 0 ; $count < $max ; ++$count) {

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
            Math::GMPz::Rmpz_tdiv_q($t, $t, $z);      # t = floor(t/z)

            $r = $t;
            push @cfrac, bless \$t;

            last if Math::GMPz::Rmpz_cmp_ui($z, 1) == 0;
        }

        Sidef::Types::Array::Array->new(\@cfrac);
    }

    sub sqrt_cfrac_period {
        my ($n) = @_;
        my @arr = @{$n->sqrt_cfrac};
        CORE::shift(@arr);
        Sidef::Types::Array::Array->new(\@arr);
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

            return __PACKAGE__->_set_uint($period);
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

        __PACKAGE__->_set_uint($period);
    }

    sub convergents {
        my ($x, $n) = @_;

        my @cfrac = @{$x->as_cfrac($n)};

        if (defined($n)) {
            $n = _any2ui($$n) // 0;
            $n = @cfrac if $n > @cfrac;
        }
        else {
            $n = @cfrac;
        }

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

    my %DIGITS_36;
    @DIGITS_36{0 .. 9, 'a' .. 'z'} = (0 .. 35);

    my %DIGITS_62;
    @DIGITS_62{0 .. 9, 'A' .. 'Z', 'a' .. 'z'} = (0 .. 61);

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
                map { __PACKAGE__->_set_uint($k <= 36 ? $DIGITS_36{$_} : $DIGITS_62{$_}) }
                    split(//, scalar CORE::reverse scalar Math::GMPz::Rmpz_get_str($n, $k))
            ]);
        }
#>>>

        # Subquadratic algorithm from "Modern Computer Arithmetic" by Richard P. Brent and Paul Zimmermann
        if (Math::GMPz::Rmpz_fits_ulong_p($k)) {

            # Find r such that B^(2r - 2) <= A < B^(2r)
            my $r = (__ilog__($n, $k) >> 1) + 1;

            my $A = $n;
            my $B = Math::GMPz::Rmpz_get_ui($k);

            state $Q = Math::GMPz::Rmpz_init_nobless();
            state $R = Math::GMPz::Rmpz_init_nobless();

            my @digits = map { __PACKAGE__->_set_uint($_) } sub {
                my ($A, $r) = @_;

                if (Math::GMPz::Rmpz_cmp_ui($A, $B) < 0) {
                    return Math::GMPz::Rmpz_get_ui($A);
                }

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
        Math::GMPz::Rmpz_tdiv_q($u, $u, $t);
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
            return __PACKAGE__->_set_uint(scalar Math::GMPz::Rmpz_popcount($n)) if ($k == 2);
            return __PACKAGE__->_set_uint(List::Util::sum(map { $k <= 36 ? $DIGITS_36{$_} : $DIGITS_62{$_} } split(//, Math::GMPz::Rmpz_get_str($n, $k))));
        }
#>>>

        # Subquadratic algorithm from "Modern Computer Arithmetic" by Richard P. Brent and Paul Zimmermann
        if (Math::GMPz::Rmpz_fits_ulong_p($k)) {

            # Find r such that B^(2r - 2) <= A < B^(2r)
            my $r = (__ilog__($n, $k) >> 1) + 1;

            my $A = $n;
            my $B = Math::GMPz::Rmpz_get_ui($k);

            state $Q = Math::GMPz::Rmpz_init_nobless();
            state $R = Math::GMPz::Rmpz_init_nobless();

            my $total = sub {
                my ($A, $r) = @_;

                if (Math::GMPz::Rmpz_cmp_ui($A, $B) < 0) {
                    return Math::GMPz::Rmpz_get_ui($A);
                }

                my $w = ($r + 1) >> 1;
                my $t = Math::GMPz::Rmpz_init();

                Math::GMPz::Rmpz_ui_pow_ui($t, $B, $r);
                Math::GMPz::Rmpz_divmod($Q, $R, $A, $t);
                Math::GMPz::Rmpz_set($t, $Q);

                __SUB__->($R, $w) + __SUB__->($t, $w);
              }
              ->($A, $r);

            ($total < ULONG_MAX)
              && return __PACKAGE__->_set_uint($total);
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

    sub length {
        my ($x, $y) = @_;

        $x = _any2mpz($$x) // return undef;

        my $neg = ((Math::GMPz::Rmpz_sgn($x) || return ONE) < 0) ? 1 : 0;

        if (defined($y)) {
            _valid(\$y);
            $y = _any2mpz($$y) // return undef;
        }
        else {
            $y = 10;
        }

        if ($neg) {
            $x = Math::GMPz::Rmpz_init_set($x);
            Math::GMPz::Rmpz_abs($x, $x);
        }

        __PACKAGE__->_set_uint(1 + (__ilog__($x, $y) // return ZERO));
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

            Math::GMPq::Rmpq_sgn($y)
              || goto &_nan;

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

            Math::GMPz::Rmpz_sgn($y)
              || goto &_nan;

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

    sub sqrtmod {
        my ($x, $y) = @_;
        _valid(\$y);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;

        Math::GMPz::Rmpz_sgn($y) <= 0 and goto &nan;

        my $xstr = Math::GMPz::Rmpz_get_str($x, 10);
        my $ystr = Math::GMPz::Rmpz_get_str($y, 10);

        if (Math::Prime::Util::GMP::is_prob_prime($ystr)) {
            my $n = Math::Prime::Util::GMP::sqrtmod($xstr, $ystr) // goto &nan;
            return (($n < ULONG_MAX) ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n));
        }

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor($ystr);

        my @congruences;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $v = Math::GMPz::Rmpz_init();
        my $w = Math::GMPz::Rmpz_init();
        my $m = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_mod($m, $x, $y);

        foreach my $p (keys %factors) {

            if ($p eq '2') {
                my $e = $factors{$p};

                if ($e == 1) {
                    push @congruences, [(Math::GMPz::Rmpz_odd_p($m) ? 1 : 0), 2];
                    next;
                }

                if ($e == 2) {
                    push @congruences, [(Math::GMPz::Rmpz_congruent_ui_p($m, 1, 4) ? 1 : 0), 4];
                    next;
                }

                Math::GMPz::Rmpz_congruent_ui_p($m, 1, 8) or goto &nan;
                Math::GMPz::Rmpz_ui_pow_ui($v, 2, $e - 1);

                my $r = ${(bless \$m)->sqrtmod(bless \$v)};

                Math::GMPz::Rmpz_mul($t, $r, $r);
                Math::GMPz::Rmpz_sub($t, $t, $m);
                Math::GMPz::Rmpz_div_2exp($t, $t, $e - 1);
                Math::GMPz::Rmpz_mod_ui($t, $t, 2);

                Math::GMPz::Rmpz_mul_2exp($t, $t, $e - 2);
                Math::GMPz::Rmpz_add($t, $t, $r);

                push @congruences, [Math::GMPz::Rmpz_get_str($t, 10), Math::GMPz::Rmpz_get_str($v, 10)];
                next;
            }

            my $s = Math::Prime::Util::GMP::sqrtmod($xstr, $p) // goto &nan;

            ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($t, $p)
              : Math::GMPz::Rmpz_set_str($t, $p, 10);

            ($s < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($w, $s)
              : Math::GMPz::Rmpz_set_str($w, $s, 10);

            # v = p^k
            Math::GMPz::Rmpz_pow_ui($v, $t, $factors{"$p"});

            # t = p^(k-1)
            Math::GMPz::Rmpz_divexact($t, $v, $t);

            # u = (p^k - 2*(p^(k-1)) + 1) / 2
            Math::GMPz::Rmpz_mul_2exp($u, $t, 1);
            Math::GMPz::Rmpz_sub($u, $v, $u);
            Math::GMPz::Rmpz_add_ui($u, $u, 1);
            Math::GMPz::Rmpz_div_2exp($u, $u, 1);

            # sqrtmod(a, p^k) = (powmod(sqrtmod(a, p), p^(k-1), p^k) * powmod(a, u, p^k)) % p^k
            Math::GMPz::Rmpz_powm($w, $w, $t, $v);
            Math::GMPz::Rmpz_powm($u, $m, $u, $v);
            Math::GMPz::Rmpz_mul($w, $w, $u);
            Math::GMPz::Rmpz_mod($w, $w, $v);

            push @congruences, [Math::GMPz::Rmpz_get_str($w, 10), Math::GMPz::Rmpz_get_str($v, 10)];
        }

        my $n = Math::Prime::Util::GMP::chinese(@congruences) // goto &nan;

        ($n < ULONG_MAX)
          ? Math::GMPz::Rmpz_set_ui($t, $n)
          : Math::GMPz::Rmpz_set_str($t, $n, 10);

        # Check that t^2 = m (mod y)
        Math::GMPz::Rmpz_powm_ui($u, $t, 2, $y);
        Math::GMPz::Rmpz_cmp($u, $m) == 0 or goto &nan;

        bless \$t;
    }

    sub modpow {
        my ($x, $y, $z) = @_;

        _valid(\$y, \$z);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);
        $z = _any2mpz($$z) // (goto &nan);

        Math::GMPz::Rmpz_sgn($z) || goto &nan;

        if (Math::GMPz::Rmpz_sgn($y) < 0) {
            my $t = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_gcd($t, $x, $z);
            Math::GMPz::Rmpz_cmp_ui($t, 1) == 0 or goto &nan;
        }

        my $r = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_fits_ulong_p($y)
          ? Math::GMPz::Rmpz_powm_ui($r, $x, Math::GMPz::Rmpz_get_ui($y), $z)
          : Math::GMPz::Rmpz_powm($r, $x, $y, $z);

        bless \$r;
    }

    *expmod = \&modpow;
    *powmod = \&modpow;

    sub modinv {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_invert($r, $x, $y) || (goto &nan);
        bless \$r;
    }

    *invmod = \&modinv;

    sub divmod {
        my ($x, $y) = @_;

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

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // return undef;
        }
        else {
            $k = 0;
        }

        $n = _any2mpz($$n) // return undef;

        __PACKAGE__->_set_uint(Math::GMPz::Rmpz_scan0($n, $k));
    }

    sub bit_scan1 {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // return undef;
        }
        else {
            $k = 0;
        }

        $n = _any2mpz($$n) // return undef;

        __PACKAGE__->_set_uint(Math::GMPz::Rmpz_scan1($n, $k));
    }

    sub ramanujan_tau {
        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::ramanujan_tau(&_big2uistr // (goto &nan)));
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

    sub subfactorial {
        my ($x, $y) = @_;

        my $m = _any2ui($$x) // goto &nan;
        my $k = defined($y) ? do { _valid(\$y); _any2si($$y) // goto &nan } : 0;

        my $n = $m - $k;

        return ZERO if ($k < 0);
        return ONE  if ($n == 0);
        goto &nan   if ($n < 0);

        my $z = Math::GMPz::Rmpz_init();

        if ($n >= 40000) {

            my $tau  = 6.28318530717958647692528676655900576839433879875;
            my $prec = 4 + CORE::int(($n * CORE::log($n) + CORE::log($tau * $n) / 2 - $n) / CORE::log(2));

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
        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::factorial_sum($n));
    }

    *left_factorial = \&factorial_sum;

    sub superfactorial {
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

        my $r = Math::Prime::Util::GMP::factorialmod(_big2uistr($n) // (goto &nan), _big2uistr($m) // (goto &nan))
          // goto &nan;

        ($r < ULONG_MAX) ? __PACKAGE__->_set_uint($r) : __PACKAGE__->_set_str('int', $r);
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

        Math::GMPz::Rmpz_fits_ulong_p($r)
          ? Math::GMPz::Rmpz_bin_uiui($r, Math::GMPz::Rmpz_get_ui($r), CORE::abs($y))
          : Math::GMPz::Rmpz_bin_ui($r, $r, CORE::abs($y));

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

        Math::GMPz::Rmpz_fits_ulong_p($r)
          ? Math::GMPz::Rmpz_bin_uiui($r, Math::GMPz::Rmpz_get_ui($r), CORE::abs($y))
          : Math::GMPz::Rmpz_bin_ui($r, $r, CORE::abs($y));

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

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan);
        return ZERO if exists($factors{'0'});

        state %cache;

        my $prod = Math::GMPz::Rmpz_init_set_ui(1);
        my $tmp  = Math::GMPz::Rmpz_init();

        while (my ($p, $e) = each %factors) {

            ($p < ULONG_MAX) || goto &nan;

            my $primorial = ($p <= 1e5)
              ? (
                $cache{$p} //= do {
                    my $z = Math::GMPz::Rmpz_init_nobless();
                    Math::GMPz::Rmpz_primorial_ui($z, $p);
                    $z;
                }
              )
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

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan);

        while (my ($p, $e) = each %factors) {

            my $q = ($p <= 2) ? 1 : Math::Prime::Util::GMP::prev_prime($p);

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
        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::pn_primorial(_any2ui($$x) // goto &nan));
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

        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::lucasu($p, $q, $n));
    }

    *lucasU  = \&lucasu;
    *LucasU  = \&lucasu;
    *lucas_U = \&lucasu;

    sub lucasv {
        my ($p, $q, $n) = @_;

        _valid(\$q, \$n);

        $p = _big2istr($p)  // goto &nan;
        $q = _big2istr($q)  // goto &nan;
        $n = _big2uistr($n) // goto &nan;

        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::lucasv($p, $q, $n));
    }

    *lucasV  = \&lucasv;
    *LucasV  = \&lucasv;
    *lucas_V = \&lucasv;

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

    state $LUCAS_PQ_LIMIT = int(sqrt(ULONG_MAX >> 2));

    sub _modular_lucas_UV {
        my ($P, $Q, $n, $m) = @_;

        if (    Math::GMPz::Rmpz_cmpabs_ui($P, $LUCAS_PQ_LIMIT) < 0
            and Math::GMPz::Rmpz_cmpabs_ui($Q, $LUCAS_PQ_LIMIT) < 0) {
            my ($U, $V);
            eval { ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($m, $P, $Q, $n) };
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
            eval { ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($m, $P, $Q, $n) };
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
            eval { ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($m, $P, $Q, $n) };
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

        _valid(\$x);

        $n = _any2si($$n) // goto &nan;

        $n = -$n if $n < 0;
        $n == 0 and return ONE;
        $n == 1 and return $x;

        $x = $$x;

        my $t = __add__($x, $x);
        my ($u, $v) = ($ONE, $x);

        foreach my $i (2 .. $n) {
            ($u, $v) = ($v, __sub__(__mul__($t, $v), $u));
        }

        bless \$v;
    }

    *chebyshevT  = \&chebyshevt;
    *ChebyshevT  = \&chebyshevt;
    *chebyshev_T = \&chebyshevt;

    #
    ## Chebyshev polynomials: U_n(x)
    #

    sub chebyshevu {
        my ($n, $x) = @_;

        _valid(\$x);

        $n = _any2si($$n) // goto &nan;
        $n == 0 and return ONE;

        my $negative = 0;

        if ($n < 0) {

            $n == -1 and return ZERO;
            $n == -2 and return MONE;

            $n        = -$n - 2;
            $negative = 1;
        }

        $x = $$x;

        my $t = __add__($x, $x);
        my ($u, $v) = ($ONE, $t);

        foreach my $i (2 .. $n) {
            ($u, $v) = ($v, __sub__(__mul__($t, $v), $u));
        }

        $v = __neg__($v) if $negative;
        bless \$v;
    }

    *ChebyshevU  = \&chebyshevu;
    *chebyshevU  = \&chebyshevu;
    *chebyshev_U = \&chebyshevu;

    #
    ## Legendre polynomials: P_n(x)
    #

    sub legendre_polynomial {
        my ($n, $x) = @_;

        _valid(\$x);

        $n = _any2ui($$n) // goto &nan;

        $n == 0 && return ONE;
        $n == 1 && return $x;

        my $x1 = __dec__($$x);
        my $x2 = __inc__($$x);

        my $t = Math::GMPz::Rmpz_init();

        my @terms;
        foreach my $k (0 .. $n) {
            Math::GMPz::Rmpz_bin_uiui($t, $n, $k);
            Math::GMPz::Rmpz_mul($t, $t, $t);
            push @terms, __mul__(__mul__(__pow__($x1, $n - $k), __pow__($x2, $k)), $t);
        }

        my $sum = _binsplit(\@terms, \&__add__);

        Math::GMPz::Rmpz_set_ui($t, 0);
        Math::GMPz::Rmpz_setbit($t, $n);

        bless \__div__($sum, $t);
    }

    *LegendreP  = \&legendre_polynomial;
    *legendrep  = \&legendre_polynomial;
    *legendreP  = \&legendre_polynomial;
    *legendre_P = \&legendre_polynomial;

    #
    ## The physicists' Hermite polynomials H_n(x)
    #

    sub hermiteH {
        my ($n, $x) = @_;

        _valid(\$x);

        $n = _any2ui($$n) // goto &nan;

        $n == 0 && return ONE;
        $x = __add__($$x, $$x);
        $n == 1 && return bless \$x;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init_set_ui(1);

        my $v = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fac_ui($v, $n);

        my @terms;
        foreach my $m (0 .. $n >> 1) {
            Math::GMPz::Rmpz_mul($t, $v, $u);
            Math::GMPz::Rmpz_neg($t, $t) if ($m & 1);

            push @terms, __div__(__pow__($x, $n - ($m << 1)), $t);

            my $d = ($n - ($m << 1)) * ($n - ($m << 1) - 1);
            Math::GMPz::Rmpz_divexact_ui($v, $v, $d) if $d;
            Math::GMPz::Rmpz_mul_ui($u, $u, $m + 1);
        }

        my $sum = _binsplit(\@terms, \&__add__);
        Math::GMPz::Rmpz_fac_ui($v, $n);
        bless \__mul__($sum, $v);
    }

    *HermiteH             = \&hermiteH;
    *hermite_H            = \&hermiteH;
    *hermite_polynomialH  = \&hermiteH;
    *hermite_polynomial_H = \&hermiteH;

    #
    ## The probabilists' Hermite polynomials He_n(x)
    #

    sub hermiteHe {
        my ($n, $x) = @_;

        _valid(\$x);

        $n = _any2ui($$n) // goto &nan;

        $n == 0 && return ONE;
        $n == 1 && return $x;

        $x = $$x;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init_set_ui(1);

        my $v = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fac_ui($v, $n);

        my @terms;
        foreach my $m (0 .. $n >> 1) {
            Math::GMPz::Rmpz_mul($t, $v, $u);
            Math::GMPz::Rmpz_mul_2exp($t, $t, $m);
            Math::GMPz::Rmpz_neg($t, $t) if ($m & 1);

            push @terms, __div__(__pow__($x, $n - ($m << 1)), $t);

            my $d = ($n - ($m << 1)) * ($n - ($m << 1) - 1);
            Math::GMPz::Rmpz_divexact_ui($v, $v, $d) if $d;
            Math::GMPz::Rmpz_mul_ui($u, $u, $m + 1);
        }

        my $sum = _binsplit(\@terms, \&__add__);
        Math::GMPz::Rmpz_fac_ui($v, $n);
        bless \__mul__($sum, $v);
    }

    *HermiteHe             = \&hermiteHe;
    *hermite_He            = \&hermiteHe;
    *hermite_polynomialHe  = \&hermiteHe;
    *hermite_polynomial_He = \&hermiteHe;

    #
    ## Laguerre polynomials: L_n(x)
    #

    sub laguerreL {
        my ($n, $x) = @_;

        _valid(\$x);

        $n = _any2ui($$n) // goto &nan;
        $n || return ONE;

        $x = $$x;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init_set_ui(1);

        my @terms;
        foreach my $k (0 .. $n) {
            Math::GMPz::Rmpz_bin_uiui($t, $n, $k);
            Math::GMPz::Rmpz_neg($t, $t) if ($k & 1);
            push @terms, __div__(__mul__(__pow__($x, $k), $t), $u);
            Math::GMPz::Rmpz_mul_ui($u, $u, $k + 1);
        }

        bless \_binsplit(\@terms, \&__add__);
    }

    *laguerre            = \&laguerreL;
    *Laguerre            = \&laguerreL;
    *LaguerreL           = \&laguerreL;
    *Laguerre_L          = \&laguerreL;
    *laguerre_polynomial = \&laguerreL;

    sub fibonaccimod {
        my ($n, $m) = @_;
        _valid(\$m);

        $n = _big2uistr($n) // goto &nan;
        $m = _big2pistr($m) // goto &nan;

        return ZERO if $m eq '1';

        my ($r) = Math::Prime::Util::GMP::lucas_sequence($m, 1, -1, $n);
        ($r < ULONG_MAX) ? __PACKAGE__->_set_uint($r) : __PACKAGE__->_set_str('int', $r);
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
        ($r < ULONG_MAX) ? __PACKAGE__->_set_uint($r) : __PACKAGE__->_set_str('int', $r);
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
        __PACKAGE__->_set_str('int',
                              Math::Prime::Util::GMP::stirling(_big2uistr($x) // (goto &nan), _big2uistr($y) // (goto &nan)));
    }

    *Stirling  = \&stirling;
    *stirling1 = \&stirling;
    *Stirling1 = \&stirling;

    sub stirling2 {
        my ($x, $y) = @_;
        _valid(\$y);
        __PACKAGE__->_set_str(
                              'int',
                              Math::Prime::Util::GMP::stirling(
                                                               _big2uistr($x) // (goto &nan), _big2uistr($y) // (goto &nan), 2
                                                              )
                             );
    }

    *Stirling2 = \&stirling2;

    sub stirling3 {
        my ($x, $y) = @_;
        _valid(\$y);
        __PACKAGE__->_set_str(
                              'int',
                              Math::Prime::Util::GMP::stirling(
                                                               _big2uistr($x) // (goto &nan), _big2uistr($y) // (goto &nan), 3
                                                              )
                             );
    }

    *Stirling3 = \&stirling3;

    sub bell {
        my ($x) = @_;
        my $n = _any2ui($$x) // goto &nan;

#<<<
        if ($n < 100) {
              return __PACKAGE__->_set_str('int',
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

    sub quadratic_formula {
        my ($x, $y, $z) = @_;

        $x //= ZERO;
        $y //= ZERO;
        $z //= ZERO;

        _valid(\$y, \$z);

        $x = $$x;
        $y = $$y;
        $z = $$z;

        #
        ## (-b ± sqrt(b^2 - 4ac)) / (2a)
        #

        my $u = __mul__($y,              $y);       # b^2
        my $t = __mul__(__mul__($x, $z), $FOUR);    # 4ac
        my $s = __sqrt__(_any2mpfr_mpc(__sub__($u, $t)));    # sqrt(b^2 - 4ac)

        my $n1 = __sub__($s, $y);                            #   sqrt(b^2 - 4ac) - b
        my $n2 = __neg__(__add__($s, $y));                   # -(sqrt(b^2 - 4ac) + b)

        my $d = __add__($x, $x);                             # 2a

        my $x1 = __div__($n1, $d);                           # solution 1
        my $x2 = __div__($n2, $d);                           # solution 2

        ((bless \$x1), (bless \$x2));
    }

    sub iquadratic_formula {
        my ($x, $y, $z) = @_;

        $x //= ZERO;
        $y //= ZERO;
        $z //= ZERO;

        _valid(\$y, \$z);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;
        $z = _any2mpz($$z) // goto &nan;

        #
        ## floor((-b ± isqrt(b^2 - 4ac)) / (2a))
        #

        my $u = Math::GMPz::Rmpz_init();
        my $t = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_mul($t, $y, $y);    # b^2
        Math::GMPz::Rmpz_mul($u, $x, $z);    # ac
        Math::GMPz::Rmpz_mul_2exp($u, $u, 2);    # 4ac

        Math::GMPz::Rmpz_sub($t, $t, $u);        # b^2 - 4ac
        Math::GMPz::Rmpz_sqrt($t, $t);           # isqrt(b^2 - 4ac)

        Math::GMPz::Rmpz_sub($u, $t, $y);        #   sqrt(b^2 - 4ac) - b
        Math::GMPz::Rmpz_add($t, $t, $y);        #   sqrt(b^2 - 4ac) + b
        Math::GMPz::Rmpz_neg($t, $t);            # -(sqrt(b^2 - 4ac) + b)

        Math::GMPz::Rmpz_div($u, $u, $x);
        Math::GMPz::Rmpz_div($t, $t, $x);

        Math::GMPz::Rmpz_div_2exp($u, $u, 1);
        Math::GMPz::Rmpz_div_2exp($t, $t, 1);

        ((bless \$u), (bless \$t));
    }

    *integer_quadratic_formula = \&iquadratic_formula;

    sub geometric_sum {
        my ($n, $r) = @_;
        _valid(\$r);

        $n = $$n;
        $r = $$r;

        bless \__div__(__sub__(__pow__($r, __add__($n, $ONE)), $ONE), __sub__($r, $ONE));
    }

    sub faulhaber_sum {
        my ($n, $p) = @_;

        _valid(\$p);

        $n = _any2mpz($$n) // goto &nan;
        $p = _any2ui($$p)  // goto &nan;

        my $native_n = 0;

        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {
            ($native_n, $n) = (1, Math::GMPz::Rmpz_get_ui($n));
        }

        my @B = _bernoulli_numbers($p);

        my $z = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $q = Math::GMPq::Rmpq_init();

        my $sum = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($sum, 0, 1);

        foreach my $j (0 .. $p) {

            $j % 2 == 0 or $j == 1 or next;

            Math::GMPz::Rmpz_bin_uiui($z, $p + 1, $j);    # z = binomial(p+1, j)

#<<<
            $native_n
              ? Math::GMPz::Rmpz_ui_pow_ui($u, $n, $p + 1 - $j)     # u = n^(p+1 - j)
              : Math::GMPz::Rmpz_pow_ui(   $u, $n, $p + 1 - $j);    # ==//==
#>>>

            Math::GMPz::Rmpz_mul($z, $z, $u);             # z = z * u
            Math::GMPq::Rmpq_mul_z($q, $j <= 1 ? $B[$j] : $B[($j >> 1) + 1], $z);
            Math::GMPq::Rmpq_neg($q, $q) if ($j == 1);
            Math::GMPq::Rmpq_add($sum, $sum, $q);
        }

        Math::GMPq::Rmpq_get_num($z, $sum);
        Math::GMPz::Rmpz_divexact_ui($z, $z, $p + 1);

        bless \$z;
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

            if ($k >= 0 and Math::GMPz::Rmpz_fits_ulong_p($sum)) {
                Math::GMPz::Rmpz_bin_uiui($bin, Math::GMPz::Rmpz_get_ui($sum), $k);
            }
            else {
                $k < 0
                  ? Math::GMPz::Rmpz_bin_si($bin, $sum, $k)
                  : Math::GMPz::Rmpz_bin_ui($bin, $sum, $k);
            }

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

        if ($y >= 0 and Math::GMPz::Rmpz_fits_ulong_p($x)) {
            Math::GMPz::Rmpz_bin_uiui($r, Math::GMPz::Rmpz_get_ui($x), $y);
        }
        else {
            $y < 0
              ? Math::GMPz::Rmpz_bin_si($r, $x, $y)
              : Math::GMPz::Rmpz_bin_ui($r, $x, $y);
        }

        bless \$r;
    }

    *nok = \&binomial;

    sub moebius {
        my ($n, $k) = @_;

        if (defined($k)) {

            $n = _big2istr($n) // return Sidef::Types::Array::Array->new;
            $k = _big2istr($k) // return Sidef::Types::Array::Array->new;

            my @array = map { $_ ? ($_ == 1) ? ONE : MONE : ZERO } (
                                                                    $HAS_PRIME_UTIL
                                                                    ? Math::Prime::Util::moebius($n, $k)
                                                                    : Math::Prime::Util::GMP::moebius($n, $k)
                                                                   );

            return Sidef::Types::Array::Array->new(\@array);
        }

        my $m = Math::Prime::Util::GMP::moebius(_big2istr($n) // goto &nan);
        $m ? ($m == 1) ? ONE : MONE : ZERO;
    }

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

        if ($x eq '1' and defined(my $value = $mertens_table->{$y})) {
            return (
                    ($value > LONG_MIN and $value < ULONG_MAX)
                    ? __PACKAGE__->_set_int($value)
                    : __PACKAGE__->_set_str('int', $value)
                   );
        }

        # Support for large integers (slow for wide ranges)
        if ($y >= ULONG_MAX) {

            $x = Math::GMPz::Rmpz_init_set_str("$x", 10);
            $y = Math::GMPz::Rmpz_init_set_str("$y", 10);

            my $sum = 0;

            for (; Math::GMPz::Rmpz_cmp($x, $y) <= 0 ; Math::GMPz::Rmpz_add_ui($x, $x, 1)) {
                $sum += Math::Prime::Util::GMP::moebius(Math::GMPz::Rmpz_get_str($x, 10));
            }

            return __PACKAGE__->_set_int($sum);
        }

        return ZERO if ($y < $x);

        # Optimization for narrow ranges
        if (($x >= 10**4 and $y - $x <= 10**4) or "$x" / "$y" >= 0.999) {
            my $r =
              List::Util::sum(
                              $HAS_PRIME_UTIL
                              ? Math::Prime::Util::moebius($x, $y)
                              : Math::Prime::Util::GMP::moebius($x, $y)
                             );
            return ($r >= 0 ? __PACKAGE__->_set_uint($r) : __PACKAGE__->_set_int($r));
        }

        my $lookup_size = 2 * CORE::int($y**(2 / 3));

        state @mertens_lookup;

        if (@mertens_lookup < $lookup_size) {
            $mertens_lookup[0] = 0;

            my @mu_range = (
                            $HAS_PRIME_UTIL
                            ? Math::Prime::Util::moebius(scalar(@mertens_lookup), $lookup_size)
                            : Math::Prime::Util::GMP::moebius(scalar(@mertens_lookup), $lookup_size)
                           );

            foreach my $i (@mertens_lookup .. $lookup_size) {
                $mertens_lookup[$i] = $mertens_lookup[$i - 1] + shift(@mu_range);
            }
        }

        my $mertens = sub {
            my ($n) = @_;

            if ($n <= $lookup_size) {
                return $mertens_lookup[$n];
            }

            if (exists $mertens_table->{$n}) {
                return $mertens_table->{$n};
            }

            my $s = CORE::int(CORE::sqrt($n));
            my $M = 1;

            foreach my $k (2 .. CORE::int($n / ($s + 1))) {
                $M -= __SUB__->(CORE::int($n / $k));
            }

            foreach my $k (1 .. $s) {
                $M -= $mertens_lookup[$k] * (CORE::int($n / $k) - CORE::int($n / ($k + 1)));
            }

            $mertens_table->{$n} = $M;
        };

        my $value = (
                     ($x == 1)
                     ? $mertens->($y)
                     : ($mertens->($y) - $mertens->($x) + Math::Prime::Util::GMP::moebius($x))
                    );

        ($value > LONG_MIN and $value < ULONG_MAX)
          ? __PACKAGE__->_set_int($value)
          : __PACKAGE__->_set_str('int', $value);
    }

    sub liouville_sum {
        my ($n) = @_;

        $n = _any2mpz($$n) // goto &nan;
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
            return (
                    ($value > LONG_MIN and $value < ULONG_MAX)
                    ? __PACKAGE__->_set_int($value)
                    : __PACKAGE__->_set_str('int', $value)
                   );
        }

        state $t = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_sqrt($t, $n);
        Math::GMPz::Rmpz_fits_ulong_p($t) || goto &nan;    # too large

        my $L    = 0;
        my $sqrt = Math::GMPz::Rmpz_get_ui($t);

        foreach my $k (1 .. $sqrt) {
            if ($k * $k < ULONG_MAX) {
                Math::GMPz::Rmpz_tdiv_q_ui($t, $n, $k * $k);
            }
            else {
                Math::GMPz::Rmpz_ui_pow_ui($t, $k, 2);
                Math::GMPz::Rmpz_tdiv_q($t, $n, $t);
            }
            $L += Math::GMPz::Rmpz_get_si(${mertens($t)});    # most of the time is spent here
        }

        $liouville_table->{$n} = $L;
        ($L > LONG_MIN and $L < ULONG_MAX)
          ? __PACKAGE__->_set_int($L)
          : __PACKAGE__->_set_str('int', $L);
    }

    sub cyclotomic_polynomial {
        my ($n, $x) = @_;

        _valid(\$x);

        $n = _any2ui($$n) // goto &nan;
        $x = $$x;

        return ONE if ($n == 0);

        return bless(\__dec__($x)) if ($n == 1);
        return bless(\__inc__($x)) if ($n == 2);

        my $x_is_mpz = ref($x) eq 'Math::GMPz';

        my %factors;
        @factors{Math::Prime::Util::GMP::factor($n)} = ();

        # Special case for x = 1: cyclotomic(n, 1) is the greatest common divisor of the prime factors of n.
        if ($x_is_mpz ? (Math::GMPz::Rmpz_cmp_ui($x, 1) == 0) : __eq__($x, 1)) {
            return __PACKAGE__->_set_uint(Math::Prime::Util::GMP::gcd(keys %factors));
        }

        # Generate the squarefree divisors of n, along
        # with the number of prime factors of each divisor
        my @sd;
        foreach my $p (keys %factors) {
            push @sd, map { [$_->[0] * $p, $_->[1] + 1] } @sd;
            push @sd, [$p, 1];
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

    sub squarefree_count {
        my ($from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            return $to->squarefree_count->sub($from->dec->squarefree_count);
        }

        (my $n = __numify__($$from)) <= 0 && return ZERO;

        # Optimization for native integers
        if ($n < ULONG_MAX) {

            $n = CORE::int($n);
            my $s = CORE::int(CORE::sqrt($n));

            # Using moebius(1, sqrt(n)) for values of n <= 2^40
            if ($n <= (1 << 40)) {

                my ($count, $k) = (0, 0);

                foreach my $m (
                               $HAS_PRIME_UTIL
                               ? Math::Prime::Util::moebius(1, $s)
                               : Math::Prime::Util::GMP::moebius(1, $s)
                  ) {
                    ++$k;
                    if ($m) {
                        $count += $m * CORE::int($n / ($k * $k));
                    }
                }

                return (
                        ($count < ULONG_MAX)
                        ? __PACKAGE__->_set_uint($count)
                        : __PACKAGE__->_set_str('int', $count)
                       );
            }

            # Linear counting up to sqrt(n)
            my ($count, $m) = 0;
            foreach my $k (1 .. $s) {
                if ($m = Math::Prime::Util::GMP::moebius($k)) {
                    $count += $m * CORE::int($n / ($k * $k));
                }
            }
            return (
                    ($count < ULONG_MAX)
                    ? __PACKAGE__->_set_uint($count)
                    : __PACKAGE__->_set_str('int', $count)
                   );
        }

        # Implementation for large values of n
        my $c = Math::GMPz::Rmpz_init_set_ui(0);
        my $t = Math::GMPz::Rmpz_init();
        my $z = _any2mpz($$from) // return ZERO;

        my $s = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sqrt($s, $z);

        for (my $k = Math::GMPz::Rmpz_init_set_ui(1) ; Math::GMPz::Rmpz_cmp($k, $s) <= 0 ; Math::GMPz::Rmpz_add_ui($k, $k, 1))
        {
            my $m = Math::Prime::Util::GMP::moebius(Math::GMPz::Rmpz_get_str($k, 10));

            if ($m) {
                Math::GMPz::Rmpz_set($t, $z);
                Math::GMPz::Rmpz_tdiv_q($t, $t, $k);
                Math::GMPz::Rmpz_tdiv_q($t, $t, $k);
                ($m == -1)
                  ? Math::GMPz::Rmpz_sub($c, $c, $t)
                  : Math::GMPz::Rmpz_add($c, $c, $t);
            }
        }

        bless \$c;
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
            $middle = (($right + $left) >> 1);
            $item   = $checkpoints->[$middle][$i];
            $cmp    = ($n <=> $item) || last;

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
            "10"                           => "4",
            "100"                          => "25",
            "1000"                         => "168",
            "10000"                        => "1229",
            "100000"                       => "9592",
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
            "3"                          => "2",
            "31"                         => "11",
            "316"                        => "65",
            "3162"                       => "446",
            "31622"                      => "3401",
            "316227"                     => "27293",
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
        };

        if (defined($y)) {
            $x = 2 if ($x < 2);
        }
        else {
            $y = $x;
            $x = 2;
        }

        return 0 if ($y < $x);

        if ($x eq '2' and defined(my $value = $primepi_lookup->{$y})) {
            return $value;
        }

        # Support for arbitrary large integers (slow for wide ranges)
        if ($y >= ULONG_MAX and !$HAS_PRIME_UTIL) {
            my $prime_count = Math::Prime::Util::GMP::prime_count("$x", "$y");
            return $prime_count;
        }

        if ($HAS_PRIME_UTIL) {
            my $prime_count = Math::Prime::Util::prime_count("$x", "$y");
            return "$prime_count";
        }

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

#<<<
                # Sieve the ranges [x_n, x] and [y_n, y]
                my $x_count = _prime_count_range(Math::Prime::Util::GMP::next_prime($x_n), Math::Prime::Util::GMP::prev_prime($x + 1)) + $x_pi;
                my $y_count = _prime_count_range(Math::Prime::Util::GMP::next_prime($y_n), Math::Prime::Util::GMP::prev_prime($y + 1)) + $y_pi;
#>>>

                my $prime_count = $y_count - $x_count;
                ++$prime_count if ($x == 2 or Math::Prime::Util::GMP::is_prime($x));
                return $prime_count;
            }
        }

#<<<
        # Sieve the range [x, y]
        my $prime_count = _prime_count_range(Math::Prime::Util::GMP::next_prime($x - 1), Math::Prime::Util::GMP::prev_prime($y + 1));
#>>>

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

        my $count = _prime_count($x, $y);

        return (
                ($count < ULONG_MAX)
                ? __PACKAGE__->_set_uint($count)
                : __PACKAGE__->_set_str('int', $count)
               );
    }

    *primepi = \&prime_count;

    sub prime_count_lower {
        my $prime_pi = Math::Prime::Util::GMP::prime_count_lower(&_big2uistr // return ZERO) // 0;
        ($prime_pi < ULONG_MAX) ? __PACKAGE__->_set_uint($prime_pi) : __PACKAGE__->_set_str('int', $prime_pi);
    }

    *primepi_lower = \&prime_count_lower;

    sub prime_count_upper {
        my $prime_pi = Math::Prime::Util::GMP::prime_count_upper(&_big2uistr // return ZERO) // 0;
        ($prime_pi < ULONG_MAX) ? __PACKAGE__->_set_uint($prime_pi) : __PACKAGE__->_set_str('int', $prime_pi);
    }

    *primepi_upper = \&prime_count_upper;

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
                        my $root = $y->iroot(__PACKAGE__->_set_uint($k));
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

            return __PACKAGE__->_set_uint($count);
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
                return __PACKAGE__->_set_uint($pp_table->[$y]);
            }

            my $count = 0;

            for (; $x <= $y ; ++$x) {
                ++$count if Math::Prime::Util::GMP::is_prime_power($x);
            }

            return ZERO if ($count == 0);
            return ONE  if ($count == 1);

            return __PACKAGE__->_set_uint($count);
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

        ($count < ULONG_MAX) ? __PACKAGE__->_set_uint($count) : __PACKAGE__->_set_str('int', $count);
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
            "1"                         => "2",
            "10"                        => "29",
            "100"                       => "541",
            "1000"                      => "7919",
            "10000"                     => "104729",
            "100000"                    => "1299709",
            "1000000"                   => "15485863",
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
        };

        if (exists($nth_prime_lookup->{$n})) {

            my $p = $nth_prime_lookup->{$n};

            return (
                    ($p < ULONG_MAX)
                    ? __PACKAGE__->_set_uint($p)
                    : __PACKAGE__->_set_str('int', $p)
                   );
        }

        if ($n > 1_000_000) {

            if ($HAS_PRIME_UTIL) {
                my $p = Math::Prime::Util::nth_prime($n);
                return (($p < ULONG_MAX) ? __PACKAGE__->_set_uint("$p") : __PACKAGE__->_set_str('int', "$p"));
            }

            my ($i, $count) = _prime_count_checkpoint($n, 1);

            if ($count == $n) {
                return (
                        ($i < ULONG_MAX)
                        ? __PACKAGE__->_set_uint($i)
                        : __PACKAGE__->_set_str('int', $i)
                       );
            }

            my $nth_prime_lower = sub {
                my ($n) = @_;
                CORE::int($n * (CORE::log($n) + CORE::log(CORE::log($n)) - 1));
            };

            my $step         = $nth_prime_lower->($i + CORE::log($n) * 2e3) - $nth_prime_lower->($i);
            my $upper_approx = CORE::int($n * (CORE::log($n) + CORE::log(CORE::log($n))));

            for (my $prev_count = $count ; ; $i += $step) {

                my $from = $i + 1;
                my $to   = $i + $step;

                $to = $upper_approx if ($to > $upper_approx);

                my @primes = Math::Prime::Util::GMP::sieve_primes($from, $to);

                $count += @primes;

                if ($count >= $n) {
                    my $p = $primes[$n - $prev_count - 1];
                    return (
                            ($p < ULONG_MAX)
                            ? __PACKAGE__->_set_uint($p)
                            : __PACKAGE__->_set_str('int', $p)
                           );
                }

                $prev_count = $count;
            }
        }

        state @table;

        my $limit = 1000 + CORE::int(2 * $n * CORE::log($n));
        $limit = 15_485_863 if $limit > 15_485_863;

        if (@table < $n) {
            $table[0] = 2;
            push @table, Math::Prime::Util::GMP::sieve_primes($table[-1] + 1, $limit);
        }

        __PACKAGE__->_set_uint($table[$n - 1]);
    }

    *prime = \&nth_prime;

    sub composite_count {
        my ($n) = @_;
        $n->sub($n->prime_count)->dec;    # n - pi(n) - 1
    }

    sub nth_composite {
        my ($n) = @_;
        $n = _any2ui($$n) // goto &nan;

        return ONE                       if ($n == 0);    # not composite, but...
        return __PACKAGE__->_set_uint(4) if ($n == 1);

        # Lower and upper bounds from A002808 (for n >= 4).
        my $min = CORE::int($n + $n / CORE::log($n) + $n / (CORE::log($n)**2));
        my $max = CORE::int($n + $n / CORE::log($n) + (3 * $n) / (CORE::log($n)**2));

        if ($n < 4) {
            $min = 4;
            $max = 8;
        }

        my $k = 0;

        while (1) {
            $k = ($min + $max) >> 1;

            my $pi = (
                      $HAS_PRIME_UTIL
                      ? Math::Prime::Util::prime_count($k)
                      : _prime_count($k)
                     );

            my $cmp = ($k <=> ($pi + 1 + $n));

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

        if ($HAS_PRIME_UTIL ? Math::Prime::Util::is_prime($k) : Math::Prime::Util::GMP::is_prob_prime($k)) {
            --$k;
        }

        ($k < ULONG_MAX) ? __PACKAGE__->_set_uint($k) : __PACKAGE__->_set_str('int', $k);
    }

    *composite = \&nth_composite;

    sub legendre {
        my ($x, $y) = @_;
        _valid(\$y);

        my $sym = Math::GMPz::Rmpz_legendre(_any2mpz($$x) // (goto &nan), _any2mpz($$y) // (goto &nan));

        if (!$sym) {
            ZERO;
        }
        elsif ($sym == 1) {
            ONE;
        }
        else {
            MONE;
        }
    }

    *Legendre = \&legendre;

    sub jacobi {
        my ($x, $y) = @_;
        _valid(\$y);

        my $sym = Math::GMPz::Rmpz_jacobi(_any2mpz($$x) // (goto &nan), _any2mpz($$y) // (goto &nan));

        if (!$sym) {
            ZERO;
        }
        elsif ($sym == 1) {
            ONE;
        }
        else {
            MONE;
        }
    }

    *Jacobi = \&jacobi;

    sub kronecker {
        my ($x, $y) = @_;
        _valid(\$y);

        my $sym = Math::GMPz::Rmpz_kronecker(_any2mpz($$x) // (goto &nan), _any2mpz($$y) // (goto &nan));

        if (!$sym) {
            ZERO;
        }
        elsif ($sym == 1) {
            ONE;
        }
        else {
            MONE;
        }
    }

    *Kronecker = \&kronecker;

    sub kronecker_delta {
        my ($x, $y) = @_;
        _valid(\$y);
        __eq__($$x, $$y) ? ONE : ZERO;
    }

    *KroneckerDelta = \&kronecker_delta;

    sub is_coprime {
        my ($x, $y) = @_;

        _valid(\$y);

        (__is_int__($$x) && __is_int__($$y))
          || return Sidef::Types::Bool::Bool::FALSE;

        $x = _any2mpz($$x) // return Sidef::Types::Bool::Bool::FALSE;
        $y = _any2mpz($$y) // return Sidef::Types::Bool::Bool::FALSE;

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
                Math::GMPz::Rmpz_cmp_ui($r, 1) || last;
            }

            return bless \$r;
        }

        my ($x, $y) = @vals;

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;

        Math::GMPz::Rmpz_gcd($r, $x, $y);
        bless \$r;
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
        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::consecutive_integer_lcm(&_big2uistr // goto &nan));
    }

    *consecutive_lcm = \&consecutive_integer_lcm;

    sub num2perm {
        my ($n, $k) = @_;
        _valid(\$k);
        my @perm = map { __PACKAGE__->_set_uint($_) }
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
        __PACKAGE__->_set_uint(scalar Math::GMPz::Rmpz_remove($t, $x, $y));
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
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _any2mpz($$x) // goto &nan;
        $y = _any2mpz($$y) // goto &nan;

        my $r = Math::GMPz::Rmpz_init_set($x);
        my $g = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_gcd($g, $r, $y);

        while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            Math::GMPz::Rmpz_remove($r, $r, $g);
            Math::GMPz::Rmpz_gcd($g, $r, $y);
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

        __PACKAGE__->_set_str('int', $prime // goto &nan);
    }

    sub random_bytes {
        Sidef::Types::Array::Array->new(
                                        [map { __PACKAGE__->_set_uint(ord($_)) }
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
        $n <= 1 && return __PACKAGE__->_set_uint(2);
        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::random_nbit_prime($n));
    }

    sub random_nbit_strong_prime {
        my ($x) = @_;
        my $n = _any2ui($$x) // goto &nan;
        $n < 128 && goto &random_nbit_prime;
        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::random_strong_prime($n));
    }

    *random_strong_nbit_prime = \&random_nbit_strong_prime;

    sub random_nbit_maurer_prime {
        my ($x) = @_;
        my $n = _any2ui($$x) // goto &nan;
        $n <= 1 && goto &nan;
        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::random_maurer_prime($n));
    }

    *random_maurer_nbit_prime = \&random_nbit_maurer_prime;

    sub random_ndigit_prime {
        my ($x) = @_;
        my $n = _any2ui($$x) || goto &nan;
        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::random_ndigit_prime($n));
    }

    sub is_semiprime {
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::is_semiprime(&_big2uistr // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub _semiprime_count {
        my ($n) = @_;

        if ($HAS_PRIME_UTIL) {
            return Math::Prime::Util::semiprime_count($n);
        }

        my $count  = 0;
        my $t      = 0;
        my $s      = Math::Prime::Util::GMP::sqrtint($n);
        my $primes = Math::Prime::Util::GMP::primes($s);

        foreach my $p (@$primes) {
            $count += _prime_count(CORE::int($n / $p)) - ++$t + 1;
        }

        return $count;
    }

    sub semiprime_count {
        my ($n) = @_;
        $n = _any2ui($$n) // goto &nan;
        my $count = _semiprime_count($n);
        ($count < ULONG_MAX) ? __PACKAGE__->_set_uint($count) : __PACKAGE__->_set_str('int', $count);
    }

    sub nth_semiprime {
        my ($n) = @_;
        $n = _any2ui($$n) // goto &nan;

        return ONE                       if ($n == 0);    # not semiprime, but...
        return __PACKAGE__->_set_uint(4) if ($n == 1);

        if ($HAS_PRIME_UTIL) {
            my $k = Math::Prime::Util::nth_semiprime($n);
            return (
                    ($k < ULONG_MAX)
                    ? __PACKAGE__->_set_uint("$k")
                    : __PACKAGE__->_set_str('int', "$k")
                   );
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

        my $k = 0;

        while (1) {
            $k = ($min + $max) >> 1;

            my $pi2 = _semiprime_count($k);
            my $cmp = ($pi2 <=> $n);

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

        while (!Math::Prime::Util::GMP::is_semiprime($k)) {
            --$k;
        }

        ($k < ULONG_MAX) ? __PACKAGE__->_set_uint($k) : __PACKAGE__->_set_str('int', $k);
    }

    *semiprime = \&nth_semiprime;

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

            state %cache;
            state $g = Math::GMPz::Rmpz_init_nobless();

            my @checks = (1e4, 1e6);

            push(@checks, 1e7) if ($size > 20_000);
            push(@checks, 1e8) if ($size > 30_000);

            my $prev;

            foreach my $k (@checks) {

                #~ say "Checking factors < $k";

                my $primorial = (
                    $cache{$k} //= do {
                        my $z = Math::GMPz::Rmpz_init_nobless();
                        Math::GMPz::Rmpz_primorial_ui($z, $k);
                        Math::GMPz::Rmpz_divexact($z, $z, $prev) if defined($prev);
                        $z;
                    }
                );

                Math::GMPz::Rmpz_gcd($g, $primorial, $n);

                if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
                    ## say "Composite with a factor < $k";
                    return 0;
                }

                $prev = $primorial;
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

        foreach my $n (@vals) {
            Math::Prime::Util::GMP::is_prob_prime(_big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE)
              || return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub all_composite {
        my (@vals) = @_;
        _valid(\(@vals));

        foreach my $n (@vals) {
            (_primality_pretest($$n) // return Sidef::Types::Bool::Bool::FALSE) || next;
            Math::Prime::Util::GMP::is_prob_prime(_big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE)
              && return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub is_prime {
        my ($n) = @_;
        _primality_pretest($$n)
          && Math::Prime::Util::GMP::is_prime(&_big2uistr // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_prob_prime {
        my ($n) = @_;
        _primality_pretest($$n)
          && Math::Prime::Util::GMP::is_prob_prime(&_big2uistr // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_prov_prime {
        my ($n) = @_;
        _primality_pretest($$n)
          && Math::Prime::Util::GMP::is_provable_prime(&_big2uistr // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_provable_prime = \&is_prov_prime;

    sub is_bpsw_prime {
        my ($n) = @_;
        _primality_pretest($$n)
          && Math::Prime::Util::GMP::is_bpsw_prime(&_big2uistr // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_aks_prime {
        my ($n) = @_;
        _primality_pretest($$n)
          && Math::Prime::Util::GMP::is_aks_prime(&_big2uistr // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_composite {
        my ($n) = @_;

        (_primality_pretest($$n) // return Sidef::Types::Bool::Bool::FALSE)
          || return Sidef::Types::Bool::Bool::TRUE;

        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0 or return Sidef::Types::Bool::Bool::FALSE;

        Math::Prime::Util::GMP::is_prob_prime(_big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::FALSE
          : Sidef::Types::Bool::Bool::TRUE;
    }

    sub miller_rabin_random {
        my ($n, $k) = @_;
        _valid(\$k);

        __is_int__($$n)
          && Math::Prime::Util::GMP::miller_rabin_random(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE),
                                                         _any2ui($$k) // 20,)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_fermat_pseudoprime {
        my ($n, @bases) = @_;
        _valid(\(@bases));

        __is_int__($$n)
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

    *is_pseudoprime = \&is_fermat_pseudoprime;

    sub is_super_pseudoprime {
        my ($n, @bases) = @_;
        _valid(\(@bases));

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _big2uistr($n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::Prime::Util::GMP::is_pseudoprime(
            $n,
            do {
                @bases = grep { defined($_) and $_ > 1 } map { _big2uistr($_) } @bases;
                @bases ? (@bases) : (2);
            }
        ) || return Sidef::Types::Bool::Bool::FALSE;

        # Using Thomas Ordowski's criterion from A050217.
        my @factors =
          map { ($_ < ULONG_MAX) ? ($_ - 1) : (Math::GMPz::Rmpz_init_set_str("$_", 10) - 1) }
          Math::Prime::Util::GMP::factor($n);

        my $gcd = Math::Prime::Util::GMP::gcd(@factors);

        @bases = (2) if !@bases;

        foreach my $base (@bases) {
            Math::Prime::Util::GMP::powmod($base, $gcd, $n) eq '1'
              or return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub is_euler_pseudoprime {
        my ($n, @bases) = @_;
        _valid(\(@bases));
        __is_int__($$n)
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

    sub is_strong_fermat_pseudoprime {
        my ($n, @bases) = @_;
        _valid(\(@bases));
        __is_int__($$n)
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

    *is_strong_pseudoprime = \&is_strong_fermat_pseudoprime;

    sub is_chebyshev_pseudoprime {    # OEIS: A175530
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_cmp_ui($n, 7056721) < 0 and return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_odd_p($n) or return Sidef::Types::Bool::Bool::FALSE;

        my $nstr = Math::GMPz::Rmpz_get_str($n, 10);

        # V_n(P,1) == P (mod n) for any integer P.
        foreach my $i (1 .. 10) {     # test with random values of P

            my $P = CORE::int(CORE::rand(1e6)) + 11;
            my ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($nstr, $P, 1, $nstr);

            if ($V ne $P) {
                return Sidef::Types::Bool::Bool::FALSE;
            }

            if ($i == 1 and Math::Prime::Util::GMP::is_prob_prime($nstr)) {
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

        my @factors = Math::Prime::Util::GMP::factor($nstr);

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

    sub is_bruckman_lucas_pseudoprime {    # OEIS: A005845 (composites)
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0 or return Sidef::Types::Bool::Bool::FALSE;

        my ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($n, 1, -1, $n);
        $V eq '1' ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_pell_lucas_pseudoprime {        # OEIS: A270342 (primes + composites), A270345 (composites)
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_cmp_ui($n, 2) > 0 or return Sidef::Types::Bool::Bool::FALSE;

        my ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($n, 2, -1, $n);
        $V eq '2' ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_pell_pseudoprime {              # OEIS: A099011 (odd composites)
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

    sub is_fibonacci_pseudoprime {    # OEIS: A081264 (odd composites)
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        Math::GMPz::Rmpz_cmp_ui($n, 1) > 0 or return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_divisible_ui_p($n, 5) and return Sidef::Types::Bool::Bool::FALSE;

        my ($U, $V) = Math::Prime::Util::GMP::lucas_sequence($n, 1, -1, $n - Math::GMPz::Rmpz_ui_kronecker(5, $n));
        $U eq '0' ? Sidef::Types::Bool::Bool::TRUE : Sidef::Types::Bool::Bool::FALSE;
    }

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

            if ($i == 1 and Math::Prime::Util::GMP::is_prob_prime($nstr)) {
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

        my @factors = Math::Prime::Util::GMP::factor($nstr);

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
            #   p-1 | n-1, for all p|n.

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

    sub is_lucas_pseudoprime {
        my ($n) = @_;
        __is_int__($$n)
          && Math::Prime::Util::GMP::is_lucas_pseudoprime(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_strong_lucas_pseudoprime {
        my ($n) = @_;
        __is_int__($$n)
          && Math::Prime::Util::GMP::is_strong_lucas_pseudoprime(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_stronger_lucas_pseudoprime {
        my ($n) = @_;
        __is_int__($$n)
          && Math::Prime::Util::GMP::is_extra_strong_lucas_pseudoprime(_big2uistr($n)
                                                                       // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_extra_strong_lucas_pseudoprime = \&is_stronger_lucas_pseudoprime;

    sub is_strongish_lucas_pseudoprime {
        my ($n) = @_;
        __is_int__($$n)
          && Math::Prime::Util::GMP::is_almost_extra_strong_lucas_pseudoprime(_big2uistr($n)
                                                                              // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_plumb_pseudoprime {
        my ($n) = @_;
        __is_int__($$n)
          && Math::Prime::Util::GMP::is_euler_plumb_pseudoprime(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_euler_plumb_pseudoprime = \&is_plumb_pseudoprime;

    sub is_perrin_pseudoprime {
        my ($n) = @_;
        __is_int__($$n)
          && Math::Prime::Util::GMP::is_perrin_pseudoprime(_big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_frobenius_pseudoprime {
        my ($n, $k, $m) = @_;

        _valid(\$k, \$m) if defined($k);

        __is_int__($$n)
          && Math::Prime::Util::GMP::is_frobenius_pseudoprime(
                                                              _big2uistr($n) // (return Sidef::Types::Bool::Bool::FALSE),
                                                              (defined($k) ? _big2istr($k) // () : ()),
                                                              (defined($m) ? _big2istr($m) // () : ()),
                                                             )
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_frobenius_underwood_pseudoprime {
        my ($n) = @_;
        __is_int__($$n)
          && Math::Prime::Util::GMP::is_frobenius_underwood_pseudoprime(_big2uistr($n)
                                                                        // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_underwood_pseudoprime = \&is_frobenius_underwood_pseudoprime;

    sub is_frobenius_khashin_pseudoprime {
        my ($n) = @_;
        __is_int__($$n)
          && Math::Prime::Util::GMP::is_frobenius_khashin_pseudoprime(_big2uistr($n)
                                                                      // (return Sidef::Types::Bool::Bool::FALSE))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_khashin_pseudoprime = \&is_frobenius_khashin_pseudoprime;

    sub is_nminus1_prime {
        my ($x) = @_;

        __is_int__($$x) || return Sidef::Types::Bool::Bool::FALSE;
        $x = _big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE;

        Math::Prime::Util::GMP::is_prob_prime($x)
          && Math::Prime::Util::GMP::is_nminus1_prime($x)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_nm1_prime = \&is_nminus1_prime;

    sub is_nplus1_prime {
        my ($x) = @_;

        __is_int__($$x) || return Sidef::Types::Bool::Bool::FALSE;
        $x = _big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE;

        Math::Prime::Util::GMP::is_prob_prime($x)
          && Math::Prime::Util::GMP::is_nplus1_prime($x)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_np1_prime = \&is_nplus1_prime;

    sub is_ecpp_prime {
        my ($x) = @_;

        __is_int__($$x) || return Sidef::Types::Bool::Bool::FALSE;
        $x = _big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE;

        Math::Prime::Util::GMP::is_prob_prime($x)
          && Math::Prime::Util::GMP::is_ecpp_prime($x)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_mersenne_prime {
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::is_mersenne_prime(_big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE)
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
            sub { Math::Prime::Util::GMP::primes($_[0], $_[1]) }
        );
#>>>
    }

    *each_prime = \&primes_each;

    sub primes {
        my ($x, $y) = @_;

        _valid(\$y) if defined($y);

        Sidef::Types::Array::Array->new(
            [
             map {
                 ($_ < ULONG_MAX)
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
               }

               defined($y)
             ? Math::Prime::Util::GMP::sieve_primes((_big2uistr($x) // 0), (_big2uistr($y) // 0), 0)
             : Math::Prime::Util::GMP::sieve_primes(2, (_big2uistr($x) // 0), 0)
            ]
        );
    }

    sub pn_primes {
        my ($x, $y) = @_;

        if (defined($y)) {
            _valid(\$y);
            return $x->nth_prime->primes($y->nth_prime);
        }

        $x->nth_prime->primes;
    }

    sub sum_primes {
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

        if ($HAS_PRIME_UTIL) {
            my $r = Math::Prime::Util::sum_primes($x, $y);
            return (($r < ULONG_MAX) ? __PACKAGE__->_set_uint("$r") : __PACKAGE__->_set_str('int', "$r"));
        }

        my $r = Math::Prime::Util::GMP::vecsum(Math::Prime::Util::GMP::sieve_primes($x, $y));
        ($r < ULONG_MAX) ? __PACKAGE__->_set_uint($r) : __PACKAGE__->_set_str('int', "$r");
    }

    *primes_sum = \&sum_primes;

    sub prev_prime {
        my $p = Math::Prime::Util::GMP::prev_prime(&_big2uistr // goto &nan) || goto &nan;
        ($p < ULONG_MAX) ? __PACKAGE__->_set_uint($p) : __PACKAGE__->_set_str('int', $p);
    }

    sub next_prime {
        my $p = Math::Prime::Util::GMP::next_prime(&_big2uistr // goto &nan) || goto &nan;
        ($p < ULONG_MAX) ? __PACKAGE__->_set_uint($p) : __PACKAGE__->_set_str('int', $p);
    }

    sub next_composite {
        my ($n) = @_;
        $n = _any2mpz($$n) // goto &nan;

        Math::GMPz::Rmpz_sgn($n) < 0 and goto &nan;
        Math::GMPz::Rmpz_cmp_ui($n, 3) <= 0 and return __PACKAGE__->_set_uint(4);

        # Optimization for native integers
        if (Math::GMPz::Rmpz_fits_slong_p($n)) {
            $n = Math::GMPz::Rmpz_get_ui($n) + 1;
            return __PACKAGE__->_set_uint($n) if (($n & 1) == 0);
            ++$n if ($HAS_PRIME_UTIL ? Math::Prime::Util::is_prime($n) : Math::Prime::Util::GMP::is_prob_prime($n));
            return __PACKAGE__->_set_uint($n);
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add_ui($r, $n, 1);

        if (Math::GMPz::Rmpz_even_p($r)) {
            return bless \$r;
        }

        if (Math::Prime::Util::GMP::is_prob_prime(Math::GMPz::Rmpz_get_str($r, 10))) {
            Math::GMPz::Rmpz_add_ui($r, $r, 1);
        }

        return bless \$r;
    }

    sub znorder {
        my ($x, $y) = @_;
        _valid(\$y);
        my $z = Math::Prime::Util::GMP::znorder(_big2uistr($x) // (goto &nan), _big2uistr($y) // (goto &nan)) // goto &nan;
        ($z < ULONG_MAX) ? __PACKAGE__->_set_uint($z) : __PACKAGE__->_set_str('int', $z);
    }

    sub znprimroot {
        my $z = Math::Prime::Util::GMP::znprimroot(&_big2uistr // (goto &nan)) // goto &nan;
        ($z < ULONG_MAX) ? __PACKAGE__->_set_uint($z) : __PACKAGE__->_set_str('int', $z);
    }

    sub rad {
        my %f;
        @f{Math::Prime::Util::GMP::factor(&_big2uistr // goto &nan)} = ();
        exists($f{'0'}) and return ONE;
        my $r = Math::Prime::Util::GMP::vecprod(CORE::keys %f);
        ($r < ULONG_MAX) ? __PACKAGE__->_set_uint($r) : __PACKAGE__->_set_str('int', $r);
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

            my %factors;
            ++$factors{$_} for Math::Prime::Util::GMP::factor($s);

            while (my ($p, $k) = each %factors) {

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

        foreach my $p (2, 3, 5) {
            if (Math::GMPz::Rmpz_divisible_ui_p($n, $p)) {
                return __PACKAGE__->_set_uint($p);
            }
        }

        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {
            my @f = Math::Prime::Util::GMP::factor(Math::GMPz::Rmpz_get_ui($n));
            return __PACKAGE__->_set_uint($f[0]);
        }

        my $size = Math::GMPz::Rmpz_sizeinbase($n, 2);

        foreach my $j (2 .. 8) {

            my (undef, $f) = _native_trial_factor($n, 10**$j);

            if (defined($f)) {
                return __PACKAGE__->_set_uint($f);
            }

            last if (($j >= 5) && ($size <= 100));    # 30 digits
            last if (($j >= 6) && ($size <= 133));    # 40 digits
            last if (($j >= 7) && ($size <= 150));    # 45 digits
        }

        my @f = Math::Prime::Util::GMP::factor(Math::GMPz::Rmpz_get_str($n, 10));
        __PACKAGE__->_set_str('int', $f[0]);
    }

    sub gpf {
        my ($n) = @_;

        my $z = _any2mpz($$n) // goto &nan;
        Math::GMPz::Rmpz_sgn($z) >= 0 or goto &nan;

        if (Math::GMPz::Rmpz_cmp_ui($z, 1) <= 0) {
            return bless \$z;
        }

        my $nstr = (
                      Math::GMPz::Rmpz_fits_ulong_p($z)
                    ? Math::GMPz::Rmpz_get_ui($z)
                    : Math::GMPz::Rmpz_get_str($z, 10)
                   );

        my @f = Math::Prime::Util::GMP::factor($nstr);

        __PACKAGE__->_set_str('int', $f[-1]);
    }

    sub factor {
        Sidef::Types::Array::Array->new(
            [
             map {
                 ($_ < ULONG_MAX)
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
             } Math::Prime::Util::GMP::factor(&_big2pistr // return Sidef::Types::Array::Array->new())
            ]
        );
    }

    *factors = \&factor;

    sub factor_exp {

        my %count;
        ++$count{$_} for Math::Prime::Util::GMP::factor(&_big2pistr // return Sidef::Types::Array::Array->new());

        my @pairs;
        foreach my $factor (sort { (CORE::length($a) <=> CORE::length($b)) || ($a cmp $b) } keys(%count)) {
            push @pairs,
              Sidef::Types::Array::Array->new(
                                              [
                                               (
                                                ($factor < ULONG_MAX)
                                                ? __PACKAGE__->_set_uint($factor)
                                                : __PACKAGE__->_set_str('int', $factor)
                                               ),
                                               __PACKAGE__->_set_uint($count{$factor})
                                              ]
                                             );
        }

        Sidef::Types::Array::Array->new(\@pairs);
    }

    *factors_exp = \&factor_exp;

    sub _native_trial_factor {
        my ($n, $k) = @_;

        # n is a positive > 1 Math::GMPz object
        # k is an unsigned integer

        state %cache;

        # Clear the cache when there are too many values cached
        if (scalar(keys(%cache)) > 100) {
            Math::GMPz::Rmpz_clear($_) for values(%cache);
            undef %cache;
        }

        my $B = (
            $cache{$k} //= do {
                my $t = Math::GMPz::Rmpz_init_nobless();
                Math::GMPz::Rmpz_primorial_ui($t, $k);
                $t;
            }
        );

        state $g = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_gcd($g, $n, $B);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {

            my $t    = Math::GMPz::Rmpz_init_set($n);
            my $gstr = Math::GMPz::Rmpz_get_str($g, 10);

            my @factors = (
                           ($HAS_PRIME_UTIL and $gstr < ULONG_MAX)
                           ? Math::Prime::Util::factor($gstr)
                           : Math::Prime::Util::GMP::factor("$gstr")
                          );

            my @return;
            foreach my $f (@factors) {
                Math::GMPz::Rmpz_set_ui($g, $f);
                push @return, ($f) x Math::GMPz::Rmpz_remove($t, $t, $g);
            }

            return ($t, @return);
        }

        return ($n);
    }

    sub trial_factor {
        my ($n, $k) = @_;

        if (!defined($k)) {
            return Sidef::Types::Array::Array->new(
                [
                 map {
                     ($_ < ULONG_MAX)
                       ? __PACKAGE__->_set_uint($_)
                       : __PACKAGE__->_set_str('int', $_)
                 } Math::Prime::Util::GMP::trial_factor(_big2pistr($n) // (return Sidef::Types::Array::Array->new))
                ]
            );
        }

        _valid(\$k);
        __is_int__($$n) || return Sidef::Types::Array::Array->new();

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new();
        $k = _any2ui($$k)  // return Sidef::Types::Array::Array->new();

        return Sidef::Types::Array::Array->new()          if Math::GMPz::Rmpz_sgn($n) <= 0;
        return Sidef::Types::Array::Array->new(bless \$n) if $k <= 0;
        return Sidef::Types::Array::Array->new(ONE)       if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

        my ($r, @factors) = _native_trial_factor($n, $k);

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
          map { (Sidef::Types::Number::Number->_set_uint($_)) x $count{$_} } @uniq_factors;

        if (Math::GMPz::Rmpz_cmp_ui($r, 1) > 0) {
            push @return, bless \$r;
        }

        return Sidef::Types::Array::Array->new(\@return);
    }

    sub prho_factor {
        my ($n, $k) = @_;
        _valid(\$k) if defined($k);
        Sidef::Types::Array::Array->new(
            [
             map {
                 ($_ < ULONG_MAX)
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
               }
               Math::Prime::Util::GMP::prho_factor(
                                                   _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                   (defined($k) ? _big2uistr($k) // () : ()),
                                                  )
            ]
        );
    }

    sub pbrent_factor {
        my ($n, $k) = @_;
        _valid(\$k) if defined($k);
        Sidef::Types::Array::Array->new(
            [
             map {
                 ($_ < ULONG_MAX)
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
               }
               Math::Prime::Util::GMP::pbrent_factor(
                                                     _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                     (defined($k) ? _big2uistr($k) // () : ()),
                                                    )
            ]
        );
    }

    sub pminus1_factor {
        my ($n, $B1, $B2) = @_;

        _valid(\$B1) if defined($B1);
        _valid(\$B2) if defined($B2);

        Sidef::Types::Array::Array->new(
            [
             map {
                 ($_ < ULONG_MAX)
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
               }
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
            [
             map {
                 ($_ < ULONG_MAX)
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
               }
               Math::Prime::Util::GMP::pplus1_factor(
                                                     _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                     (defined($B1) ? _big2uistr($B1) // () : ()),
                                                    )
            ]
        );
    }

    *pp1_factor = \&pplus1_factor;

    sub holf_factor {
        my ($n, $k) = @_;
        _valid(\$k) if defined($k);
        Sidef::Types::Array::Array->new(
            [
             map {
                 ($_ < ULONG_MAX)
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
               }
               Math::Prime::Util::GMP::holf_factor(
                                                   _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                   (defined($k) ? _big2uistr($k) // () : ()),
                                                  )
            ]
        );
    }

    sub fermat_factor {
        my ($n, $k) = @_;
        _valid(\$k) if defined($k);

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new();

        if (defined($k)) {
            $k = _any2ui($$k) // 1e4;
        }
        else {
            $k = 1e4;
        }

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

    sub squfof_factor {
        my ($n, $k) = @_;
        _valid(\$k) if defined($k);
        Sidef::Types::Array::Array->new(
            [
             map {
                 ($_ < ULONG_MAX)
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
               }
               Math::Prime::Util::GMP::squfof_factor(
                                                     _big2pistr($n) // (return Sidef::Types::Array::Array->new()),
                                                     (defined($k) ? _big2uistr($k) // () : ()),
                                                    )
            ]
        );
    }

    sub ecm_factor {
        my ($n, $B1, $curves) = @_;

        _valid(\$B1)     if defined($B1);
        _valid(\$curves) if defined($curves);

        Sidef::Types::Array::Array->new(
            [
             map {
                 ($_ < ULONG_MAX)
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
             } Math::Prime::Util::GMP::ecm_factor(
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
            [
             map {
                 ($_ < ULONG_MAX)
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
             } Math::Prime::Util::GMP::qs_factor(_big2pistr($n) // (return Sidef::Types::Array::Array->new()))
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

        foreach my $d (Math::Prime::Util::GMP::divisors(Math::GMPz::Rmpz_get_str($n, 10))) {

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

    # Divisors d of n, such that d <= k, with k = n when `k` is not specified
    sub divisors {
        my ($n, $k) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new();
        Math::GMPz::Rmpz_sgn($n) > 0 or return Sidef::Types::Array::Array->new();

        if (defined($k)) {
            _valid(\$k);

            $k = _any2mpz($$k) // return Sidef::Types::Array::Array->new();

            if (Math::GMPz::Rmpz_fits_ulong_p($k)) {    # k is a native integer

                $k = Math::GMPz::Rmpz_get_ui($k) || return Sidef::Types::Array::Array->new();

                my @factors;

                if (($k <= 1e6 or $k == 1e7 or $k == 1e8) and Math::GMPz::Rmpz_cmp_ui($n, $k) > 0) {
                    (undef, @factors) = _native_trial_factor($n, $k);
                }
                else {
                    @factors = grep { $_ - 1 < $k } Math::Prime::Util::GMP::factor($n);
                }

                @factors || return Sidef::Types::Array::Array->new([ONE]);

                my %table;
                ++$table{$_} for @factors;

                my @d = (1);

                foreach my $p (sort { $a <=> $b } keys %table) {

                    my @t;
                    my $r = 1;

                    for my $i (1 .. $table{$p}) {
                        $r *= $p;
                        foreach my $u (@d) {
                            push(@t, $u * $r) if ($u * $r - 1 < $k);
                        }
                    }

                    push @d, @t;
                }

                return Sidef::Types::Array::Array->new([map { __PACKAGE__->_set_uint($_) } sort { $a <=> $b } @d]);
            }

            return Sidef::Types::Array::Array->new([grep { $$_ <= $k } @{$_[0]->divisors}]);
        }

        Sidef::Types::Array::Array->new(
            [
             map {
                 ($_ < ULONG_MAX)
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
             } Math::Prime::Util::GMP::divisors($n)
            ]
        );
    }

    sub udivisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor($n);

        my @d;
        while (my ($p, $e) = each %factors) {

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

    sub prime_power_divisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor($n);

        my $u = Math::GMPz::Rmpz_init();

        my @d;
        while (my ($p, $e) = each %factors) {

            my $t = (
                     ($p < ULONG_MAX)
                     ? Math::GMPz::Rmpz_init_set_ui($p)
                     : Math::GMPz::Rmpz_init_set_str("$p", 10)
                    );

            push @d, $t;
            next if ($e == 1);

            Math::GMPz::Rmpz_set($u, $t);

            foreach my $i (2 .. $e) {
                Math::GMPz::Rmpz_mul($u, $u, $t);
                push @d, Math::GMPz::Rmpz_init_set($u);
            }
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        Sidef::Types::Array::Array->new(\@d);
    }

    sub prime_power_udivisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor($n);

        my @d;
        while (my ($p, $e) = each %factors) {

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

    sub squarefree_divisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my %factors;
        @factors{Math::Prime::Util::GMP::factor($n)} = ();

        my @d;
        foreach my $p (keys %factors) {

            $p = (
                  $p < ULONG_MAX
                  ? Math::GMPz::Rmpz_init_set_ui($p)
                  : Math::GMPz::Rmpz_init_set_str("$p", 10)
                 );

            my @t;
            foreach my $d (@d) {
                my $t = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_mul($t, $d, $p);
                push @t, $t;
            }

            push @d, @t;
            push @d, $p;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        unshift @d, ONE;

        Sidef::Types::Array::Array->new(\@d);
    }

    sub square_divisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor($n);

        my @d = ($ONE);
        foreach my $p (grep { $factors{$_} > 1 } keys %factors) {

            my $e = $factors{$p};

            $p = (
                  $p < ULONG_MAX
                  ? Math::GMPz::Rmpz_init_set_ui($p)
                  : Math::GMPz::Rmpz_init_set_str("$p", 10)
                 );

            my @t;
            for (my $i = 2 ; $i <= $e ; $i += 2) {
                foreach my $d (@d) {
                    my $z = Math::GMPz::Rmpz_init();
                    Math::GMPz::Rmpz_pow_ui($z, $p, $i);
                    Math::GMPz::Rmpz_mul($z, $z, $d);
                    push @t, $z;
                }
            }

            push @d, @t;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        Sidef::Types::Array::Array->new(\@d);
    }

    sub square_udivisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor($n);

        my @d = ($ONE);
        foreach my $p (grep { $factors{$_} % 2 == 0 } keys %factors) {

            my $e = $factors{$p};

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
    }

    *unitary_square_divisors = \&square_udivisors;
    *square_unitary_divisors = \&square_udivisors;

    sub squarefree_udivisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor($n);

        my @d;
        foreach my $p (grep { $factors{$_} == 1 } keys %factors) {

            $p = (
                  ($p < ULONG_MAX)
                  ? Math::GMPz::Rmpz_init_set_ui($p)
                  : Math::GMPz::Rmpz_init_set_str("$p", 10)
                 );

            my @t;
            foreach my $d (@d) {
                my $t = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_mul($t, $d, $p);
                push @t, $t;
            }

            push @d, @t;
            push @d, $p;
        }

        @d = sort { Math::GMPz::Rmpz_cmp($a, $b) } @d;
        @d = map  { bless \$_ } @d;

        unshift @d, ONE;

        Sidef::Types::Array::Array->new(\@d);
    }

    *unitary_squarefree_divisors = \&squarefree_udivisors;
    *squarefree_unitary_divisors = \&squarefree_udivisors;

    sub prime_divisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my %factors;
        @factors{Math::Prime::Util::GMP::factor($n)} = ();

        my @d;
        foreach my $p (sort { (CORE::length($a) <=> CORE::length($b)) || ($a cmp $b) } keys %factors) {
            push @d,
              (
                ($p < ULONG_MAX)
                ? __PACKAGE__->_set_uint($p)
                : __PACKAGE__->_set_str('int', $p)
              );
        }

        Sidef::Types::Array::Array->new(\@d);
    }

    sub prime_udivisors {
        my $n = &_big2pistr // return Sidef::Types::Array::Array->new();

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor($n);

        my @factors = grep { $factors{$_} == 1 } keys %factors;

        my @d;
        foreach my $p (sort { (CORE::length($a) <=> CORE::length($b)) || ($a cmp $b) } @factors) {
            push @d,
              (
                ($p < ULONG_MAX)
                ? __PACKAGE__->_set_uint($p)
                : __PACKAGE__->_set_str('int', $p)
              );
        }

        Sidef::Types::Array::Array->new(\@d);
    }

    *unitary_prime_divisors = \&prime_udivisors;
    *prime_unitary_divisors = \&prime_udivisors;

    sub exp_mangoldt {
        my $n = Math::Prime::Util::GMP::exp_mangoldt(&_big2uistr || return ONE);
        $n eq '1' and return ONE;
        ($n < ULONG_MAX) ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
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
        my $n = Math::Prime::Util::GMP::totient(&_big2uistr // goto &nan);
        ($n < ULONG_MAX) ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
    }

    *EulerPhi      = \&totient;
    *eulerphi      = \&totient;
    *euler_phi     = \&totient;
    *euler_totient = \&totient;

    sub inverse_totient {
        my ($n) = @_;

        # Based on Dana Jacobsen's code from Math::Prime::Util,
        # which in turn is based on invphi.gp v1.3 by Max Alekseyev.

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return Sidef::Types::Array::Array->new(ZERO) if !Math::GMPz::Rmpz_sgn($n);
            return Sidef::Types::Array::Array->new;
        }

#<<<
        if ($HAS_PRIME_UTIL) {
            return Sidef::Types::Array::Array->new([
                map {
                    ref($_) eq 'Math::GMPz'
                        ? (bless \$_)
                        : __PACKAGE__->_set_uint("$_")
                } Math::Prime::Util::inverse_totient($n)
            ]);
        }
#>>>

        my $u = Math::GMPz::Rmpz_init();
        my $v = Math::GMPz::Rmpz_init();
        my $w = Math::GMPz::Rmpz_init();

        my $nstr = Math::GMPz::Rmpz_get_str($n, 10);

        my %r = (1 => [$ONE]);

        foreach my $d (Math::Prime::Util::GMP::divisors($nstr)) {

            my $t  = (($d + 1) < ULONG_MAX) ? $d : Math::GMPz::Rmpz_init_set_str("$d", 10);
            my $tt = $t + 1;

            Math::Prime::Util::GMP::is_prime($tt) || next;

            my %temp;
            foreach my $k (1 .. Math::Prime::Util::GMP::valuation($nstr, $tt) + 1) {

                if (ref($tt)) {
                    Math::GMPz::Rmpz_pow_ui($u, $tt, $k - 1);
                    Math::GMPz::Rmpz_set($v, $u);
                    Math::GMPz::Rmpz_mul($v, $v, $tt);
                    Math::GMPz::Rmpz_mul($u, $u, $t);
                }
                else {
                    Math::GMPz::Rmpz_ui_pow_ui($u, $tt, $k - 1);
                    Math::GMPz::Rmpz_set($v, $u);
                    Math::GMPz::Rmpz_mul_ui($v, $v, $tt);
                    Math::GMPz::Rmpz_mul_ui($u, $u, $t);
                }

                Math::GMPz::Rmpz_divexact($w, $n, $u);

                foreach my $f (Math::Prime::Util::GMP::divisors($w)) {
                    if (exists $r{$f}) {
                        push @{$temp{$u * $f}}, map { $v * $_ } @{$r{$f}};
                    }
                }
            }

            foreach my $i (keys %temp) {
                push @{$r{$i}}, @{$temp{$i}};
            }
        }

        exists($r{$n})
          || return Sidef::Types::Array::Array->new;

        Sidef::Types::Array::Array->new([map { bless \$_ } sort { Math::GMPz::Rmpz_cmp($a, $b) } @{$r{$n}}]);
    }

    *inverse_phi       = \&inverse_totient;
    *inverse_euler_phi = \&inverse_totient;

    sub inverse_totient_len {
        my ($n) = @_;

        my $z = _any2mpz($$n) // return ZERO;

        if (Math::GMPz::Rmpz_sgn($z) <= 0) {
            return ONE if !Math::GMPz::Rmpz_sgn($z);
            return ZERO;
        }

        if ($HAS_PRIME_UTIL) {
            return Sidef::Types::Number::Number->_set_uint(scalar Math::Prime::Util::inverse_totient($z));
        }

        $n->inverse_totient->len;
    }

    sub inverse_sigma {
        my ($n) = @_;

        # Code based on invphi.gp v1.3 by Max Alekseyev.
        # https://home.gwu.edu/~maxal/gpscripts/invphi.gp

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        if (Math::GMPz::Rmpz_sgn($n) <= 0) {
            return Sidef::Types::Array::Array->new(ZERO) if !Math::GMPz::Rmpz_sgn($n);
            return Sidef::Types::Array::Array->new;
        }

        my %cache;
        my %mpz_cache;
        my %factor_cache;
        my %divisor_cache;

        my $P = Math::GMPz::Rmpz_init();

        my $results = sub {
            my ($n, $m) = @_;

            return [1] if ($n == 1);

            my $key = "$n $m";
            if (exists $cache{$key}) {
                return $cache{$key};
            }

            my (@R, @D);
            $divisor_cache{$n} //= [Math::Prime::Util::GMP::divisors($n)];

            foreach my $d (@{$divisor_cache{$n}}) {
                if ($d >= $m) {

                    if ($d < ULONG_MAX) {
                        push @D, $d;
                    }
                    else {
                        push @D, ($mpz_cache{$d} //= Math::GMPz::Rmpz_init_set_str("$d", 10));
                    }

                    $factor_cache{$d} //= do {
                        my %factors;
                        @factors{Math::Prime::Util::GMP::factor($D[-1] - 1)} = ();
                        [keys %factors];
                    };
                }
            }

            if (ref($n) and Math::GMPz::Rmpz_fits_ulong_p($n)) {
                $n = Math::GMPz::Rmpz_get_ui($n);
            }

            foreach my $d (@D) {
                foreach my $p (@{$factor_cache{$d}}) {

                    if (!ref($d) and $p < ULONG_MAX) {    # optimization for small d and p

                        my $r = $d * ($p - 1) + 1;

                        if ($r < ULONG_MAX) {
                            my $k = Math::Prime::Util::GMP::valuation($r, $p) - 1;

                            next if ($k < 1);

                            my $s = $p;
                            for (1 .. $k) {
                                $s *= $p;
                            }

                            if ($s < ULONG_MAX) {
                                next if ($r != $s);

                                my $z = $p;
                                for (1 .. $k - 1) {
                                    $z *= $p;
                                }

                                my $u = $n / $d;
                                if (ref($u) and Math::GMPz::Rmpz_fits_ulong_p($u)) {
                                    $u = Math::GMPz::Rmpz_get_ui($u);
                                }

                                my $array = __SUB__->($u, $d);

                                foreach my $v (@$array) {
                                    if (ref($v)) {
                                        if (!Math::GMPz::Rmpz_divisible_ui_p($v, $p)) {
                                            push @R, $v * $z;
                                        }
                                    }
                                    else {
                                        if ($v % $p != 0) {
                                            if ($v * $z < ULONG_MAX) {
                                                push @R, $v * $z;
                                            }
                                            else {
                                                my $w = Math::GMPz::Rmpz_init_set_ui($z);
                                                Math::GMPz::Rmpz_mul_ui($w, $w, $v);
                                                push @R, $w;
                                            }
                                        }
                                    }
                                }

                                next;
                            }
                        }
                    }

                    if ($p < ULONG_MAX) {
                        if (ref($d)) {
                            Math::GMPz::Rmpz_mul_ui($P, $d, $p - 1);
                        }
                        else {
                            Math::GMPz::Rmpz_set_ui($P, $d);
                            Math::GMPz::Rmpz_mul_ui($P, $P, $p - 1);
                        }
                        Math::GMPz::Rmpz_add_ui($P, $P, 1);
                    }
                    else {
                        $p = Math::GMPz::Rmpz_init_set_str("$p", 10);
                        if (ref($d)) {
                            Math::GMPz::Rmpz_mul($P, $d, $p - 1);
                        }
                        else {
                            Math::GMPz::Rmpz_mul_ui($P, $p - 1, $d);
                        }
                        Math::GMPz::Rmpz_add_ui($P, $P, 1);
                    }

                    my $k = Math::Prime::Util::GMP::valuation($P, $p) - 1;

                    next if ($k < 1);

                    my $t = Math::GMPz::Rmpz_init();

                    if (ref($p)) {
                        Math::GMPz::Rmpz_pow_ui($t, $p, $k + 1);
                    }
                    else {
                        Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k + 1);
                    }

                    next if (Math::GMPz::Rmpz_cmp($t, $P) != 0);

                    if (ref($p)) {
                        Math::GMPz::Rmpz_divexact($t, $t, $p);
                    }
                    else {
                        Math::GMPz::Rmpz_divexact_ui($t, $t, $p);
                    }

                    my $u = Math::GMPz::Rmpz_init();

                    if (ref($d)) {
                        if (ref($n)) {
                            Math::GMPz::Rmpz_divexact($u, $n, $d);
                        }
                        else {
                            Math::GMPz::Rmpz_set_ui($u, $n);
                            Math::GMPz::Rmpz_divexact($u, $u, $d);
                        }
                    }
                    else {
                        if (ref($n)) {
                            Math::GMPz::Rmpz_divexact_ui($u, $n, $d);
                        }
                        else {
                            Math::GMPz::Rmpz_set_ui($u, $n);
                            Math::GMPz::Rmpz_divexact_ui($u, $u, $d);
                        }
                    }

                    if (Math::GMPz::Rmpz_fits_ulong_p($u)) {
                        $u = Math::GMPz::Rmpz_get_ui($u);
                    }

                    my $native_p = !ref($p);
                    my $array    = __SUB__->($u, $d);

                    foreach my $v (@$array) {
                        if (ref($v)) {
                            if ($native_p) {
                                if (!Math::GMPz::Rmpz_divisible_ui_p($v, $p)) {
                                    push @R, $v * $t;
                                }
                            }
                            else {
                                if (!Math::GMPz::Rmpz_divisible_p($v, $p)) {
                                    push @R, $v * $t;
                                }
                            }
                        }
                        else {
                            if ($v % $p != 0) {
                                push @R, $v * $t;
                            }
                        }
                    }
                }
            }

            $cache{$key} = \@R;
          }
          ->($n, 3);

        my %seen;

        @$results = grep { !$seen{$_}++ } @$results;
        @$results = sort { $a <=> $b } @$results;
        @$results = map  { ref($_) ? bless(\$_) : __PACKAGE__->_set_uint($_) } @$results;

        Sidef::Types::Array::Array->new($results);
    }

    sub jordan_totient {
        my ($n, $k) = @_;
        $k //= ONE;
        _valid(\$k);
        my $r = Math::Prime::Util::GMP::jordan_totient(_big2uistr($k) // (goto &nan), _big2uistr($n) // (goto &nan));
        ($r < ULONG_MAX) ? __PACKAGE__->_set_uint($r) : __PACKAGE__->_set_str('int', $r);
    }

    *JordanTotient = \&jordan_totient;

    sub dedekind_psi {
        my ($n, $k) = @_;

        # Multiplicative with:
        #   a(p^e, k) = p^(k*e) + p^(k*e - k)

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 1;
        }

        return $n->usigma0 if ($k == 0);

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan);

        exists($factors{'0'}) and return ZERO;

        state $t = Math::GMPz::Rmpz_init_nobless();
        state $u = Math::GMPz::Rmpz_init_nobless();

        my $r = Math::GMPz::Rmpz_init_set_ui(1);

        while (my ($p, $e) = each %factors) {

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
        my $n = Math::Prime::Util::GMP::carmichael_lambda(&_big2uistr // goto &nan);
        ($n < ULONG_MAX) ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
    }

    *lambda           = \&carmichael_lambda;
    *CarmichaelLambda = \&carmichael_lambda;

    sub liouville {
        Math::Prime::Util::GMP::liouville(&_big2uistr // goto &nan) == 1 ? ONE : MONE;
    }

    *Liouville = \&liouville;

    sub big_omega {
        my ($n, $m) = @_;

        if (defined($m)) {
            _valid(\$m);
            $m = _any2ui($$m) // goto &nan;
        }
        else {
            $m = 0;
        }

        my $nstr = _big2uistr($n) // goto &nan;
        $nstr eq '0' and return ZERO;

        my @factors = Math::Prime::Util::GMP::factor($nstr);

        if ($m == 0) {
            return __PACKAGE__->_set_uint(scalar @factors);
        }

        # Ω_m(n) = Sum_{p^k|n} Sum_{j=1..k} n^m / p^(j*m)
        #        = Sum_{p^k|n} n^m * (p^(m*k) - 1) / (p^m - 1) / p^(m*k)

        my %factors;
        ++$factors{$_} for @factors;

        my $t  = Math::GMPz::Rmpz_init();
        my $u  = Math::GMPz::Rmpz_init();
        my $nm = Math::GMPz::Rmpz_init_set_str($nstr, 10);

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

            Math::GMPz::Rmpz_pow_ui($t, $u, $k);           # t = (p^m)^k = p^(m*k)
            Math::GMPz::Rmpz_sub_ui($u, $u, 1);            # u = p^m - 1
            Math::GMPz::Rmpz_mul($u, $u, $t);              # u = (p^m - 1) * p^(m*k)
            Math::GMPz::Rmpz_sub_ui($t, $t, 1);            # t = p^(m*k) - 1
            Math::GMPz::Rmpz_mul($t, $t, $nm);             # t = n^m * (p^(m*k) - 1)
            Math::GMPz::Rmpz_divexact($t, $t, $u);         # t = (n^m * (p^(m*k) - 1)) / ((p^m - 1) * p^(m*k))

            Math::GMPz::Rmpz_add($sum, $sum, $t);
        }

        bless \$sum;
    }

    *Omega              = \&big_omega;
    *bigomega           = \&big_omega;
    *prime_power_sigma0 = \&big_omega;

    sub omega {
        my ($n, $m) = @_;

        if (defined($m)) {
            _valid(\$m);
            $m = _any2ui($$m) // goto &nan;
        }
        else {
            $m = 0;
        }

        my $nstr = _big2uistr($n) // goto &nan;

        my %factors;
        @factors{Math::Prime::Util::GMP::factor($nstr)} = ();
        exists($factors{'0'}) and return ZERO;

        if ($m == 0) {
            return __PACKAGE__->_set_uint(scalar keys %factors);
        }

        # omega_m(n) = n^m * Sum_{p|n} 1/p^m

        my $t  = Math::GMPz::Rmpz_init();
        my $nm = Math::GMPz::Rmpz_init_set_str($nstr, 10);

        Math::GMPz::Rmpz_pow_ui($nm, $nm, $m) if $m > 1;

        my $sum = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $p (keys %factors) {

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

    *prime_sigma0        = \&omega;
    *prime_power_usigma0 = \&omega;

    sub usigma0 {

        # Identity:
        #   usigma0(n) = 2^omega(n)

        my %factors;
        @factors{Math::Prime::Util::GMP::factor(&_big2uistr // goto &nan)} = ();
        exists($factors{'0'}) and return ZERO;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_setbit($r, scalar keys %factors);
        bless \$r;
    }

    sub usigma {
        my ($n, $k) = @_;

        # Interesting identity:
        #   usigma(n, k) = sigma(n^(2*k) / rad(n)) / sigma(n^k / rad(n))

        # Multiplicative with:
        #   usigma(p^e, k) = p^(k*e) + 1

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 1;
        }

        if ($k == 0) {
            goto &usigma0;
        }

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan);
        exists($factors{'0'}) and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        while (my ($p, $e) = each %factors) {

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

    sub prime_power_sigma {
        my ($n, $k) = @_;

        # Additive with:
        #   a(p^e, k) = (p^(k*(e+1)) - p^k) / (p^k - 1)

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 1;
        }

        if ($k == 0) {
            goto &prime_power_sigma0;
        }

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan);
        exists($factors{'0'}) and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(0);

        while (my ($p, $e) = each %factors) {

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

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 1;
        }

        if ($k == 0) {
            goto &prime_power_usigma0;
        }

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan);
        exists($factors{'0'}) and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(0);

        while (my ($p, $e) = each %factors) {

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

        # Multiplicative with:
        #   a(p, k)   = 2
        #   a(p^e, k) = 1       # for e > 1

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(&_big2uistr // goto &nan);

        exists($factors{'0'}) and return ZERO;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_setbit($r, scalar grep { $factors{$_} == 1 } keys %factors);
        bless \$r;
    }

    sub squarefree_usigma {
        my ($n, $k) = @_;

        # Multiplicative with:
        #   a(p, k)   = p^k + 1
        #   a(p^e, k) = 1        # for e > 1

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 1;
        }

        if ($k == 0) {
            goto &squarefree_usigma0;
        }

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan);
        exists($factors{'0'}) and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $p (grep { $factors{$_} == 1 } keys %factors) {

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $k);
            }

            Math::GMPz::Rmpz_add_ui($t, $t, 1);
            Math::GMPz::Rmpz_mul($s, $s, $t);
        }

        bless \$s;
    }

    sub squarefree_sigma0 {

        my %factors;
        @factors{Math::Prime::Util::GMP::factor(&_big2uistr // goto &nan)} = ();
        exists($factors{'0'}) and return ZERO;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_setbit($r, scalar keys %factors);
        bless \$r;
    }

    sub squarefree_sigma {
        my ($n, $k) = @_;

        # Multiplicative with:
        #   a(p^e, k) = p^k + 1

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 1;
        }

        if ($k == 0) {
            goto &squarefree_sigma0;
        }

        my %factors;
        @factors{Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan)} = ();
        exists($factors{'0'}) and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $p (keys %factors) {

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $k);
            }

            Math::GMPz::Rmpz_add_ui($t, $t, 1);
            Math::GMPz::Rmpz_mul($s, $s, $t);
        }

        bless \$s;
    }

    sub square_sigma0 {

        # Multiplicative with:
        #   a(p^e) = floor(e/2) + 1

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(&_big2uistr // goto &nan);
        exists($factors{'0'}) and return ZERO;

        my $r = Math::Prime::Util::GMP::vecprod(map { ($_ >> 1) + 1 } values %factors);
        ($r < ULONG_MAX) ? __PACKAGE__->_set_uint($r) : __PACKAGE__->_set_str('int', $r);
    }

    sub square_sigma {
        my ($n, $k) = @_;

        # Multiplicative with:
        #   a(p^e, k) = (p^((e+2)*k) - 1)/(p^(2*k) - 1)   # for even e
        #   a(p^e, k) = (p^((e+1)*k) - 1)/(p^(2*k) - 1)   # for odd e

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 1;
        }

        if ($k == 0) {
            goto &square_sigma0;
        }

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan);
        exists($factors{'0'}) and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $p (grep { $factors{$_} > 1 } keys %factors) {

            my $e = $factors{$p};
            $e += 2 - ($e % 2);

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $e * $k);
                Math::GMPz::Rmpz_ui_pow_ui($u, $p, 2 * $k);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($u, $t, 2 * $k);
                Math::GMPz::Rmpz_pow_ui($t, $t, $e * $k);
            }

            Math::GMPz::Rmpz_sub_ui($t, $t, 1);
            Math::GMPz::Rmpz_sub_ui($u, $u, 1);

            Math::GMPz::Rmpz_divexact($t, $t, $u);
            Math::GMPz::Rmpz_mul($s, $s, $t);
        }

        bless \$s;
    }

    sub square_usigma0 {

        # Multiplicative with:
        #   a(p^e) = 2          # for even e
        #   a(p^e) = 1          # for odd e

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(&_big2uistr // goto &nan);
        exists($factors{'0'}) and return ZERO;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_setbit($r, scalar grep { $_ % 2 == 0 } values %factors);
        return bless \$r;
    }

    sub square_usigma {
        my ($n, $k) = @_;

        # Multiplicative with:
        #   a(p^e) = p^(k*e) + 1        # for even e
        #   a(p^e) = 1                  # for odd e

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 1;
        }

        if ($k == 0) {
            goto &square_usigma0;
        }

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan);
        exists($factors{'0'}) and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(1);

        foreach my $p (grep { $factors{$_} % 2 == 0 } keys %factors) {

            my $e = $factors{$p};

            if ($p < ULONG_MAX) {
                Math::GMPz::Rmpz_ui_pow_ui($t, $p, $e * $k);
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $p, 10);
                Math::GMPz::Rmpz_pow_ui($t, $t, $e * $k);
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

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 1;
        }

        if ($k == 0) {
            goto &prime_sigma0;
        }

        my %factors;
        @factors{Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan)} = ();
        exists($factors{'0'}) and return ZERO;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $p (keys %factors) {

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

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(&_big2uistr // goto &nan);
        exists($factors{'0'}) and return ZERO;

        __PACKAGE__->_set_uint(scalar grep { $factors{$_} == 1 } keys %factors);
    }

    sub prime_usigma {
        my ($n, $k) = @_;

        # Additive with:
        #   a(p,   k) = p^k
        #   a(p^e, k) = 0 for e>1

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 1;
        }

        if ($k == 0) {
            goto &prime_usigma0;
        }

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan);
        exists($factors{'0'}) and return ZERO;

        my @factors = grep { $factors{$_} == 1 } keys %factors;

        my $t = Math::GMPz::Rmpz_init();
        my $s = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $p (@factors) {

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
        ($s < ULONG_MAX) ? __PACKAGE__->_set_uint($s) : __PACKAGE__->_set_str('int', $s);
    }

    sub sigma {
        my ($n, $k) = @_;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // goto &nan;
        }
        else {
            $k = 1;
        }

        $n = _big2uistr($n) // (goto &nan);
        $n eq '0' and return ZERO;

        my $s = Math::Prime::Util::GMP::sigma($n, $k);
        ($s < ULONG_MAX) ? __PACKAGE__->_set_uint($s) : __PACKAGE__->_set_str('int', $s);
    }

    sub is_abundant {
        my ($n) = @_;

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

    sub sopfr {    # https://oeis.org/A001414
        my ($n) = @_;
        my $s = Math::Prime::Util::GMP::vecsum(Math::Prime::Util::GMP::factor(_big2uistr($n) // goto &nan));
        ($s < ULONG_MAX) ? __PACKAGE__->_set_uint($s) : __PACKAGE__->_set_str('int', $s);
    }

    sub factor_map {
        my ($n, $block) = @_;

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new;

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor($n);

        my @array;
        foreach my $key (sort { (CORE::length($a) <=> CORE::length($b)) || ($a cmp $b) } keys %factors) {

            my $p = ($key < ULONG_MAX) ? __PACKAGE__->_set_uint($key) : __PACKAGE__->_set_str('int', $key);
            my $k = __PACKAGE__->_set_uint($factors{$key});

            push @array, $block->run($p, $k);
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    sub divisor_map {
        my ($n, $block) = @_;

        $n = _big2pistr($n) // return Sidef::Types::Array::Array->new;

        my @array;
        foreach my $divisor (Math::Prime::Util::GMP::divisors($n)) {
            push @array,
              $block->run(
                          ($divisor < ULONG_MAX)
                          ? __PACKAGE__->_set_uint($divisor)
                          : __PACKAGE__->_set_str('int', $divisor)
                         );
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
        ($n < ULONG_MAX) ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
    }

    *number_of_partitions = \&partitions;

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

    sub _squarefree_sieve {
        my ($from, $to) = @_;

        my @squarefree;

#<<<
        if (0 and $HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($to)) {
            Math::Prime::Util::forsquarefree(sub {   # XXX: leaks memory in MPU 0.73
                push @squarefree, $_;
            }, Math::GMPz::Rmpz_get_ui($from), Math::GMPz::Rmpz_get_ui($to));
        }
        elsif ($HAS_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($to)) {

            $from = Math::GMPz::Rmpz_get_ui($from);
            $to   = Math::GMPz::Rmpz_get_ui($to);

            my @mu = Math::Prime::Util::moebius($from, $to);
            for (my $i = -1; $from < $to; ++$from) {
                push(@squarefree, $from) if $mu[++$i];
            }
            push(@squarefree, $to) if $mu[-1];
        }
        else {
            for (my $t = Math::GMPz::Rmpz_init_set($from) ; Math::GMPz::Rmpz_cmp($t, $to) <= 0 ; Math::GMPz::Rmpz_add_ui($t, $t, 1)) {
                my $s = Math::GMPz::Rmpz_get_str($t, 10);
                if (Math::Prime::Util::GMP::moebius($s)) {
                    push @squarefree, $s;
                }
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
                ($_ < ULONG_MAX)
                    ? __PACKAGE__->_set_uint($_)
                    : __PACKAGE__->_set_str('int', $_)
        } @{_squarefree_sieve($from, $to)};
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

        _generic_each($from, $to, $block, sub { 1e4 }, sub { _squarefree_sieve($_[0], $_[1]) });
    }

    *each_squarefree = \&squarefree_each;

    sub is_squarefree {
        my ($n) = @_;
        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;

        my $z = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        if (Math::GMPz::Rmpz_sizeinbase($z, 2) > 100) {
            state $lim = __PACKAGE__->_set_uint(1e6);
            $n->is_prob_squarefree($lim) || return Sidef::Types::Bool::Bool::FALSE;
        }

        $z = _big2uistr($z) // return Sidef::Types::Bool::Bool::FALSE;

        if ($HAS_PRIME_UTIL and $z < ULONG_MAX) {
            return (
                    Math::Prime::Util::is_square_free($z)
                    ? Sidef::Types::Bool::Bool::TRUE
                    : Sidef::Types::Bool::Bool::FALSE
                   );
        }

        Math::Prime::Util::GMP::moebius($z)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_square_free = \&is_squarefree;

    sub is_totient {    # OEIS: A002202
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::is_totient(_big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_cyclic {     # OEIS: A003277
        my ($x) = @_;

        __is_int__($$x) || return Sidef::Types::Bool::Bool::FALSE;
        $x = _big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE;

        (Math::Prime::Util::GMP::gcd(Math::Prime::Util::GMP::totient($x), $x) == 1)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_carmichael {    # OEIS: A002997
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::is_carmichael(_big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_lucas_carmichael {    # OEIS: A006972
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        # Small or even
        Math::GMPz::Rmpz_cmp_ui($n, 399) < 0 and return Sidef::Types::Bool::Bool::FALSE;
        Math::GMPz::Rmpz_odd_p($n) or return Sidef::Types::Bool::Bool::FALSE;

        # Divisible by small square
        foreach my $p (3, 5, 7, 11) {
            if (Math::GMPz::Rmpz_divisible_ui_p($n, $p * $p)) {
                return Sidef::Types::Bool::Bool::FALSE;
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

        state $np1 = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_add_ui($np1, $n, 1);

        my $omega     = 0;
        my $remainder = $n;
        my $size      = Math::GMPz::Rmpz_sizeinbase($n, 10);

        # Check the Lucas-Korselt criterion: p+1 | n+1, for small p|n.
        if ($size > 30) {

            my $trial_limit = 1e3;

#<<<
            if    ($size > 70) { $trial_limit = 1e7 }
            elsif ($size > 60) { $trial_limit = 1e6 }
            elsif ($size > 50) { $trial_limit = 1e5 }
            elsif ($size > 40) { $trial_limit = 1e4 }
#>>>

            my ($r, @factors) = _native_trial_factor($n, $trial_limit);

            $omega += scalar(@factors);

            my %seen;
            foreach my $p (@factors) {
                my $q = $p + 1;

                if ($seen{$q}++) {    # not squarefree
                    return Sidef::Types::Bool::Bool::FALSE;
                }

                Math::GMPz::Rmpz_divisible_ui_p($np1, $q)
                  || return Sidef::Types::Bool::Bool::FALSE;
            }

            if (Math::GMPz::Rmpz_cmp_ui($r, 1) == 0) {
                return Sidef::Types::Bool::Bool::TRUE;
            }

            $remainder = $r;
        }

        my @factors = Math::Prime::Util::GMP::factor($remainder);

        $omega += scalar(@factors);

        $omega >= 3
          or return Sidef::Types::Bool::Bool::FALSE;

        my %seen;
        state $t = Math::GMPz::Rmpz_init_nobless();

        # Check the Lucas-Korselt criterion: p+1 | n+1, for all p|n.
        foreach my $p (@factors) {

            if ($seen{$p}++) {    # not squarefree
                return Sidef::Types::Bool::Bool::FALSE;
            }

            ($p < ULONG_MAX)
              ? Math::GMPz::Rmpz_set_ui($t, $p)
              : Math::GMPz::Rmpz_set_str($t, $p, 10);

            Math::GMPz::Rmpz_add_ui($t, $t, 1);

            Math::GMPz::Rmpz_divisible_p($np1, $t)
              || return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub is_fundamental {
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::is_fundamental(_big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_smooth {
        my ($n, $k) = @_;

        _valid(\$k);
        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;

        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;
        $k = _any2ui($$k)  // return Sidef::Types::Bool::Bool::FALSE;

        return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_sgn($n) <= 0;
        return Sidef::Types::Bool::Bool::FALSE if $k <= 0;
        return Sidef::Types::Bool::Bool::TRUE  if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

        state %cache;

        # Clear the cache when there are too many values cached
        if (scalar(keys(%cache)) > 100) {
            Math::GMPz::Rmpz_clear($_) for values(%cache);
            undef %cache;
        }

        my $B = (
            $cache{$k} //= do {
                my $t = Math::GMPz::Rmpz_init_nobless();
                Math::GMPz::Rmpz_primorial_ui($t, $k);
                $t;
            }
        );

        my $g = Math::GMPz::Rmpz_init();
        my $t = Math::GMPz::Rmpz_init_set($n);

        Math::GMPz::Rmpz_gcd($g, $t, $B);

        while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            Math::GMPz::Rmpz_remove($t, $t, $g);
            return Sidef::Types::Bool::Bool::TRUE if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
            Math::GMPz::Rmpz_gcd($g, $t, $B);
        }

        return Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_smooth_over_prod {
        my ($n, $k) = @_;

        _valid(\$k);

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        __is_int__($$k) || return Sidef::Types::Bool::Bool::FALSE;

        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;
        $k = _any2mpz($$k) // return Sidef::Types::Bool::Bool::FALSE;

        return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_sgn($n) <= 0;
        return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_sgn($k) <= 0;
        return Sidef::Types::Bool::Bool::TRUE  if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

        my $g = Math::GMPz::Rmpz_init();
        my $t = Math::GMPz::Rmpz_init_set($n);

        Math::GMPz::Rmpz_gcd($g, $t, $k);

        while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            Math::GMPz::Rmpz_remove($t, $t, $g);
            return Sidef::Types::Bool::Bool::TRUE if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
            Math::GMPz::Rmpz_gcd($g, $t, $k);
        }

        return Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_prob_squarefree {
        my ($n, $k) = @_;

        if (!defined($k)) {
            state %cache;
            foreach my $k (2 .. 7) {

                $n->is_prob_squarefree(__PACKAGE__->_set_uint(10**$k))
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

        state %cache;

        # Clear the cache when there are too many values cached
        if (scalar(keys(%cache)) > 100) {
            Math::GMPz::Rmpz_clear($_) for values(%cache);
            undef %cache;
        }

        my $B = (
            $cache{$k} //= do {
                my $t = Math::GMPz::Rmpz_init_nobless();
                Math::GMPz::Rmpz_primorial_ui($t, $k);
                $t;
            }
        );

        my $g = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_gcd($g, $n, $B);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            Math::GMPz::Rmpz_divexact($g, $n, $g);
            return Sidef::Types::Bool::Bool::TRUE  if Math::GMPz::Rmpz_cmp_ui($g, 1) == 0;
            return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_perfect_power_p($g);
            Math::GMPz::Rmpz_gcd($g, $g, $B);
            return Sidef::Types::Bool::Bool::FALSE if Math::GMPz::Rmpz_cmp_ui($g, 1) > 0;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub is_square {
        my ($x) = @_;
        __is_int__($$x)
          && Math::GMPz::Rmpz_perfect_square_p(_any2mpz($$x))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_sqr            = \&is_square;
    *is_perfect_square = \&is_square;

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

    sub is_cube {
        my ($n) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        __is_power__($n, 3)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_power {
        my ($n, $k) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

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

    *is_pow           = \&is_power;
    *is_perfect_power = \&is_power;

    sub is_power_of {
        my ($n, $k) = @_;

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;
        $k = _any2mpz($$k) // return Sidef::Types::Bool::Bool::FALSE;

        my $e = __ilog__($n, $k) // return Sidef::Types::Bool::Bool::FALSE;

        state $t = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_pow_ui($t, $k, $e);

        (Math::GMPz::Rmpz_cmp($t, $n) == 0)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub powerful {    # k-powerful numbers <= n
        my ($n, $k) = @_;

        $n = _any2mpz($$n) // return Sidef::Types::Array::Array->new;

        Math::GMPz::Rmpz_sgn($n) > 0
          or return Sidef::Types::Array::Array->new;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // return Sidef::Types::Array::Array->new;
        }
        else {
            $k = 2;
        }

        my @powerful;
        my $t = Math::GMPz::Rmpz_init();

        sub {
            my ($m, $r) = @_;

            if ($r < $k) {
                push @powerful, $m;
                return;
            }

            Math::GMPz::Rmpz_tdiv_q($t, $n, $m);
            Math::GMPz::Rmpz_root($t, $t, $r);

            foreach my $v (1 .. $t) {

                if ($r > $k) {
                    Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $v) == 1 or next;
                    Math::Prime::Util::GMP::moebius($v) == 0 and next;
                }

                Math::GMPz::Rmpz_ui_pow_ui($t, $v, $r);
                __SUB__->($m * $t, $r - 1);
            }
          }
          ->($ONE, 2 * $k - 1);

        @powerful = sort { Math::GMPz::Rmpz_cmp($a, $b) } @powerful;
        @powerful = map  { bless \$_ } @powerful;

        Sidef::Types::Array::Array->new(\@powerful);
    }

    sub powerful_count {    # count of k-powerful numbers <= n
        my ($n, $k) = @_;

        $n = _any2mpz($$n) // return ZERO;
        Math::GMPz::Rmpz_sgn($n) > 0 or return ZERO;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2ui($$k) // return ZERO;
        }
        else {
            $k = 2;
        }

        my $t     = Math::GMPz::Rmpz_init();
        my $count = Math::GMPz::Rmpz_init_set_ui(0);

        sub {
            my ($m, $r) = @_;

            Math::GMPz::Rmpz_tdiv_q($t, $n, $m);
            Math::GMPz::Rmpz_root($t, $t, $r);

            if ($r <= $k) {
                Math::GMPz::Rmpz_add($count, $count, $t);
                return;
            }

            foreach my $v (1 .. $t) {

                if ($r > $k) {
                    Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $v) == 1 or next;
                    Math::Prime::Util::GMP::moebius($v) == 0 and next;
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

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

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

        my %factors;
        ++$factors{$_} for Math::Prime::Util::GMP::factor(Math::GMPz::Rmpz_get_str($n, 10));

        foreach my $e (values %factors) {
            $e < $k and return Sidef::Types::Bool::Bool::FALSE;
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub is_prime_power {
        my ($n) = @_;
        __is_int__($$n)
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
        $pow == 1 ? ONE : __PACKAGE__->_set_uint($pow);
    }

    sub perfect_root {
        my ($n) = @_;

        my $str = _big2istr($n) // return $n;
        my $pow = Math::Prime::Util::GMP::is_power($str) || return $n;

        my $t = _any2mpz($$n) // return $n;
        my $r = Math::GMPz::Rmpz_init();

        $pow == 2
          ? Math::GMPz::Rmpz_sqrt($r, $t)
          : Math::GMPz::Rmpz_root($r, $t, $pow);

        bless \$r;
    }

    sub perfect_power {
        __PACKAGE__->_set_uint(Math::Prime::Util::GMP::is_power(&_big2istr // return ONE) || return ONE);
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

    sub next_pow2 {
        my ($x) = @_;
        @_ = ($x, TWO);
        goto &next_pow;
    }

    *next_power2 = \&next_pow2;

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

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;

        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;
        $k = _any2mpz($$k) // return Sidef::Types::Bool::Bool::FALSE;

        __is_polygonal__($n, $k)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_polygonal2 {
        my ($n, $k) = @_;

        _valid(\$k);

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;

        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;
        $k = _any2mpz($$k) // return Sidef::Types::Bool::Bool::FALSE;

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

        my @divisors = Math::Prime::Util::GMP::divisors(Math::GMPz::Rmpz_get_str($t, 10));

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

        __is_int__($$n) || return Sidef::Types::Bool::Bool::FALSE;
        $n = _any2mpz($$n) // return Sidef::Types::Bool::Bool::FALSE;

        if (defined($k)) {
            _valid(\$k);
            $k = _any2mpz($$k) // return Sidef::Types::Bool::Bool::FALSE;
        }

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

            if ($k == 10 and $str < ULONG_MAX and $str > 0) {
                return __PACKAGE__->_set_uint($str);
            }

            return bless \Math::GMPz::Rmpz_init_set_str("$str", $k);
        }

        $_[0]->digits($_[1])->flip->digits2num($_[1])->mul($_[0]->sgn);
    }

    *flip = \&reverse;

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
                push @array, $obj->run(__PACKAGE__->_set_uint($i));
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
            my $k = __PACKAGE__->_set_uint($i);
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
            push @items, $block->run(__PACKAGE__->_set_uint($i)) // next;
            ++$j;
        }

        Sidef::Types::Array::Array->new(\@items);
    }

    sub times {
        my ($x, $block) = @_;

        $x = CORE::int(__numify__($$x));

        for (my $i = 0 ; $i < $x ; ++$i) {
            $block->run(__PACKAGE__->_set_uint($i));
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
            Sidef::Types::Array::Array->new([map { __PACKAGE__->_set_uint($_) } 0 .. __numify__($$n) - 1])->$name($block);
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
            Sidef::Types::Array::Array->new([map { __PACKAGE__->_set_uint($_) } 0 .. __numify__($$n) - 1])->$name($k, $block);
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
        *{__PACKAGE__ . '::' . 'γ'}   = \&EulerGamma;
        *{__PACKAGE__ . '::' . 'Γ'}   = \&gamma;
        *{__PACKAGE__ . '::' . 'Ψ'}   = \&digamma;
        *{__PACKAGE__ . '::' . 'ϕ'}   = \&euler_totient;
        *{__PACKAGE__ . '::' . 'σ'}   = \&sigma;
        *{__PACKAGE__ . '::' . 'Ω'}   = \&big_omega;
        *{__PACKAGE__ . '::' . 'ω'}   = \&omega;
        *{__PACKAGE__ . '::' . 'ζ'}   = \&zeta;
        *{__PACKAGE__ . '::' . 'η'}   = \&eta;
        *{__PACKAGE__ . '::' . 'μ'}   = \&moebius;
        *{__PACKAGE__ . '::' . 'δ'}   = \&kronecker_delta;
        *{__PACKAGE__ . '::' . '=~='} = \&approx_eq;
        *{__PACKAGE__ . '::' . '≅'}   = \&approx_eq;
        *{__PACKAGE__ . '::' . '<~>'} = \&approx_cmp;
    }
}

1
