package Sidef::Types::Number::Number {

    use utf8;
    use 5.016;

    use Math::MPFR qw();
    use Math::GMPq qw();
    use Math::GMPz qw();
    use Math::MPC qw();

    use Math::Prime::Util::GMP qw();
    use POSIX qw(ULONG_MAX LONG_MIN);

    our ($ROUND, $PREC);

    BEGIN {
        $ROUND = Math::MPFR::MPFR_RNDN();
        $PREC  = 192;
    }

    my $ONE  = Math::GMPz::Rmpz_init_set_ui(1);
    my $ZERO = Math::GMPz::Rmpz_init_set_ui(0);
    my $MONE = Math::GMPz::Rmpz_init_set_si(-1);

#<<<
    use constant {
          ONE  => bless(\$ONE),
          ZERO => bless(\$ZERO),
          MONE => bless(\$MONE),
    };
#>>>

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => sub { (@_) = (${$_[0]}); goto &__boolify__; },
      q{0+}   => sub { (@_) = (${$_[0]}); goto &__numify__; },
      q{""}   => sub { (@_) = (${$_[0]}); goto &__stringify__; };

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

        # Special string values
        if ($ref eq '' and (!defined($base) or $base == 10)) {
            return bless \_str2obj($num);
        }

        # Number with base
        elsif (defined($base) and $base != 10) {

            my $int_base = CORE::int($base);

            if ($int_base < 2 or $int_base > 36) {
                die "[ERROR] Number(): base must be between 2 and 36, got $base";
            }

            $num = defined($num) ? "$num" : '0';

            if (index($num, '/') != -1) {
                my $r = Math::GMPq::Rmpq_init();
                eval {
                    Math::GMPq::Rmpq_set_str($r, $num, $int_base);
                    1;
                  } // do {
                    my $r = Math::MPFR::Rmpfr_init2($PREC);
                    Math::MPFR::Rmpfr_set_nan($r);
                    return bless \$r;
                  };
                if (Math::GMPq::Rmpq_get_str($r, 10) !~ m{^\s*[-+]?[0-9]+\s*/\s*[-+]?[1-9]+[0-9]*\s*\z}) {
                    my $r = Math::MPFR::Rmpfr_init2($PREC);
                    Math::MPFR::Rmpfr_set_nan($r);
                    return bless \$r;
                }
                Math::GMPq::Rmpq_canonicalize($r);
                return bless \$r;
            }
            elsif (substr($num, 0, 1) eq '(' and substr($num, -1) eq ')') {
                my $r = Math::MPC::Rmpc_init2($PREC);
                if (Math::MPC::Rmpc_set_str($r, $num, $int_base, $ROUND)) {
                    $r = Math::MPFR::Rmpfr_init2($PREC);
                    Math::MPFR::Rmpfr_set_nan($r);
                }
                return bless \$r;
            }
            elsif (index($num, '.') != -1) {
                my $r = Math::MPFR::Rmpfr_init2($PREC);
                if (Math::MPFR::Rmpfr_set_str($r, $num, $int_base, $ROUND)) {
                    Math::MPFR::Rmpfr_set_nan($r);
                }
                return bless \$r;
            }
            else {
                my $r = eval { Math::GMPz::Rmpz_init_set_str($num, $int_base) } // do {
                    my $r = Math::MPFR::Rmpfr_init2($PREC);
                    Math::MPFR::Rmpfr_set_nan($r);
                    $r;
                };
                return bless \$r;
            }
        }

        # Special objects
        elsif ($ref eq __PACKAGE__) {
            return $num;
        }

        # GMPz
        elsif ($ref eq 'Math::GMPz') {
            return bless \Math::GMPz::Rmpz_init_set($num);
        }

        # MPFR
        elsif ($ref eq 'Math::MPFR') {
            my $r = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_set($r, $num, $ROUND);
            return bless \$r;
        }

        # MPC
        elsif ($ref eq 'Math::MPC') {
            my $r = Math::MPC::Rmpc_init2($PREC);
            Math::MPC::Rmpc_set($r, $num, $ROUND);
            return bless \$r;
        }

        # GMPq
        elsif ($ref eq 'Math::GMPq') {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set($r, $num);
            return bless \$r;
        }

        bless \_str2obj("$num");
    }

    *call = \&new;

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

    sub _set_uint {
        $_[1] <= 8192
          ? exists($cache[$_[1]])
              ? $cache[$_[1]]
              : ($cache[$_[1]] = bless \Math::GMPz::Rmpz_init_set_ui($_[1]))
          : bless \Math::GMPz::Rmpz_init_set_ui($_[1]);
    }

    sub _set_int {
        $_[1] == -1 && return MONE;
        $_[1] >= 0  && goto &_set_uint;
        bless \Math::GMPz::Rmpz_init_set_si($_[1]);
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
            bless \Math::GMPz::Rmpz_init_set_str($str, 10);
        }
        elsif ($type eq 'rat') {
            Math::GMPq::Rmpq_set_str((my $r = Math::GMPq::Rmpq_init()), $str, 10);
            bless \$r;
        }
        elsif ($type eq 'float') {
            Math::MPFR::Rmpfr_set_str((my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC))), $str, 10, $ROUND);
            bless \$r;
        }
        elsif ($type eq 'complex') {
            Math::MPC::Rmpc_set_str((my $r = Math::MPC::Rmpc_init2(CORE::int($PREC))), $str, 10, $ROUND);
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

        my $i;
        if (($i = index($str, 'e')) != -1) {

            my $exp = substr($str, $i + 1);

            # Handle specially numbers with very big exponents
            # (it's not a very good solution, but I hope it's only temporary)
            if (abs($exp) >= 1000000) {
                Math::MPFR::Rmpfr_set_str((my $mpfr = Math::MPFR::Rmpfr_init2($PREC)), "$sign$str", 10, $ROUND);
                Math::MPFR::Rmpfr_get_q((my $mpq = Math::GMPq::Rmpq_init()), $mpfr);
                return Math::GMPq::Rmpq_get_str($mpq, 10);
            }

            my ($before, $after) = split(/\./, substr($str, 0, $i));

            if (!defined($after)) {    # return faster for numbers like "13e2"
                if ($exp >= 0) {
                    return ("$sign$before" . ('0' x $exp));
                }
                else {
                    $after = '';
                }
            }

            my $numerator   = "$before$after";
            my $denominator = "1";

            if ($exp < 1) {
                $denominator .= '0' x (abs($exp) + length($after));
            }
            else {
                my $diff = ($exp - length($after));
                if ($diff >= 0) {
                    $numerator .= '0' x $diff;
                }
                else {
                    my $s = "$before$after";
                    substr($s, $exp + length($before), 0, '.');
                    return __SUB__->("$sign$s");
                }
            }

            "$sign$numerator/$denominator";
        }
        elsif (($i = index($str, '.')) != -1) {
            my ($before, $after) = (substr($str, 0, $i), substr($str, $i + 1));
            if (($after =~ tr/0//) == length($after)) {
                return "$sign$before";
            }
            $sign . ("$before$after/1" =~ s/^0+//r) . ('0' x length($after));
        }
        else {
            "$sign$str";
        }
    }

    #
    ## Misc internal functions
    #

    # Converts a string into an mpq object
    sub _str2obj {
        my ($s) = @_;

        $s
          || return Math::GMPz::Rmpz_init_set_ui(0);

        $s = lc($s);

        if ($s eq 'inf' or $s eq '+inf') {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_inf($r, 1);
            return $r;
        }
        elsif ($s eq '-inf') {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_inf($r, -1);
            return $r;
        }
        elsif ($s eq 'nan') {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_nan($r);
            return $r;
        }

        # Remove underscores
        $s =~ tr/_//d;

        # Performance improvement for Perl integers
        if (CORE::int($s) eq $s and $s >= LONG_MIN and $s <= ULONG_MAX) {
            return (
                    $s < 0
                    ? Math::GMPz::Rmpz_init_set_si($s)
                    : Math::GMPz::Rmpz_init_set_ui($s)
                   );
        }

        # Floating-point
        if ($s =~ /^([+-]?+(?=\.?[0-9])[0-9_]*+(?:\.[0-9_]++)?(?:[Ee](?:[+-]?+[0-9_]+))?)\z/) {
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

        # Floating point value
        if ($s =~ tr/e.//) {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            if (Math::MPFR::Rmpfr_set_str($r, $s, 10, $ROUND)) {
                Math::MPFR::Rmpfr_set_nan($r);
            }
            return $r;
        }

        # Fractional value
        if (index($s, '/') != -1 and $s =~ m{^\s*[-+]?[0-9]+\s*/\s*[-+]?[1-9]+[0-9]*\s*\z}) {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_str($r, $s, 10);
            Math::GMPq::Rmpq_canonicalize($r);
            return $r;
        }

        $s =~ s/^\+//;

        eval { Math::GMPz::Rmpz_init_set_str($s, 10) } // do {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_nan($r);
            $r;
        };
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
        my $ref = ref($x);

        $ref eq 'Math::MPC'  && return $x;
        $ref eq 'Math::GMPq' && goto &_mpq2mpc;
        $ref eq 'Math::GMPz' && goto &_mpz2mpc;

        goto &_mpfr2mpc;
    }

    #
    ## Any to MPFR (floating-point)
    #
    sub _any2mpfr {
        my ($x) = @_;
        my $ref = ref($x);

        $ref eq 'Math::MPFR' && return $x;
        $ref eq 'Math::GMPq' && goto &_mpq2mpfr;
        $ref eq 'Math::GMPz' && goto &_mpz2mpfr;

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
        my $ref = ref($x);

        if (   $ref eq 'Math::MPFR'
            or $ref eq 'Math::MPC') {
            return $x;
        }

        $ref eq 'Math::GMPz' && goto &_mpz2mpfr;
        $ref eq 'Math::GMPq' && goto &_mpq2mpfr;
        goto &_any2mpfr;    # this should not happen
    }

    #
    ## Any to GMPz (integer)
    #
    sub _any2mpz {
        my ($x) = @_;
        my $ref = ref($x);

        $ref eq 'Math::GMPz' && return $x;
        $ref eq 'Math::GMPq' && goto &_mpq2mpz;

        if ($ref eq 'Math::MPFR') {
            if (Math::MPFR::Rmpfr_number_p($x)) {
                my $z = Math::GMPz::Rmpz_init();
                Math::MPFR::Rmpfr_get_z($z, $x, Math::MPFR::MPFR_RNDZ);
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
        my $ref = ref($x);

        $ref eq 'Math::GMPq' && return $x;
        $ref eq 'Math::GMPz' && goto &_mpz2mpq;

        if ($ref eq 'Math::MPFR') {
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
    ## Any to unsigned integer
    #
    sub _any2ui {
        my ($x) = @_;
        my $ref = ref($x);

        if ($ref eq 'Math::GMPz') {
            my $d = CORE::int(Math::GMPz::Rmpz_get_d($x));
            ($d < 0 or $d > ULONG_MAX) && return;
            return $d;
        }

        if ($ref eq 'Math::GMPq') {
            my $d = CORE::int(Math::GMPq::Rmpq_get_d($x));
            ($d < 0 or $d > ULONG_MAX) && return;
            return $d;
        }

        if ($ref eq 'Math::MPFR') {
            if (Math::MPFR::Rmpfr_number_p($x)) {
                my $d = CORE::int(Math::MPFR::Rmpfr_get_d($x, $ROUND));
                ($d < 0 or $d > ULONG_MAX) && return;
                return $d;
            }
            return;
        }

        (@_) = _any2mpfr($x);
        goto &_any2ui;
    }

    #
    ## Any to signed integer
    #
    sub _any2si {
        my ($x) = @_;
        my $ref = ref($x);

        if ($ref eq 'Math::GMPz') {
            my $d = CORE::int(Math::GMPz::Rmpz_get_d($x));
            ($d < LONG_MIN or $d > ULONG_MAX) && return;
            return $d;
        }

        if ($ref eq 'Math::GMPq') {
            my $d = CORE::int(Math::GMPq::Rmpq_get_d($x));
            ($d < LONG_MIN or $d > ULONG_MAX) && return;
            return $d;
        }

        if ($ref eq 'Math::MPFR') {
            if (Math::MPFR::Rmpfr_number_p($x)) {
                my $d = CORE::int(Math::MPFR::Rmpfr_get_d($x, $ROUND));
                ($d < LONG_MIN or $d > ULONG_MAX) && return;
                return $d;
            }
            return;
        }

        (@_) = _any2mpfr($x);
        goto &_any2si;
    }

    #
    ## Copy to GMPz
    #
    sub _copy2mpz {
        my ($x) = @_;

        if (ref($x) eq 'Math::GMPz') {
            return Math::GMPz::Rmpz_init_set($x);
        }

        ref($x) eq 'Math::GMPq' and goto &_mpq2mpz;
        goto &_any2mpz;
    }

    #
    ## Copy to MPFR
    #
    sub _copy2mpfr {
        my ($x) = @_;
        my $ref = ref($x);

        if ($ref eq 'Math::MPFR') {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set($r, $x, $ROUND);
            return $r;
        }

        $ref eq 'Math::GMPz' && goto &_mpz2mpfr;
        $ref eq 'Math::GMPq' && goto &_mpq2mpfr;
        goto &_any2mpfr;
    }

    #
    ## Copy to MPFR or MPC, in this order
    #
    sub _copy2mpfr_mpc {
        my ($x) = @_;
        my $ref = ref($x);

        if ($ref eq 'Math::MPFR') {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set($r, $x, $ROUND);
            return $r;
        }
        elsif ($ref eq 'Math::MPC') {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set($r, $x, $ROUND);
            return $r;
        }

        $ref eq 'Math::GMPz' && goto &_mpz2mpfr;
        $ref eq 'Math::GMPq' && goto &_mpq2mpfr;
        goto &_any2mpfr;    # this should not happen
    }

    #
    ## Copy to the same object
    #
    sub _copy {
        my ($x) = @_;
        my $ref = ref($x);

        if ($ref eq 'Math::GMPz') {
            Math::GMPz::Rmpz_init_set($x);
        }
        elsif ($ref eq 'Math::MPFR') {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set($r, $x, $ROUND);
            $r;
        }
        elsif ($ref eq 'Math::GMPq') {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set($r, $x);
            $r;
        }
        elsif ($ref eq 'Math::MPC') {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set($r, $x, $ROUND);
            $r;
        }
        else {
            ${__PACKAGE__->new($x)};    # this should not happen
        }
    }

    sub _big2istr {
        my ($x) = @_;
        Math::GMPz::Rmpz_get_str((_any2mpz($$x) // return undef), 10);
    }

    sub _big2uistr {
        my ($x) = @_;
        my $str = Math::GMPz::Rmpz_get_str((_any2mpz($$x) // return undef), 10);
        $str < 0 && return undef;
        "$str";
    }

    #
    ## Internal conversion methods
    #

    sub __boolify__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            !Math::MPFR::Rmpfr_zero_p($_[0]);
        }

        elsif ($sig eq q(Math::GMPq)) {
            !!Math::GMPq::Rmpq_sgn($_[0]);
        }

        elsif ($sig eq q(Math::GMPz)) {
            !!Math::GMPz::Rmpz_sgn($_[0]);
        }

        elsif ($sig eq q(Math::MPC)) {
            my ($x) = @_;
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_RE($r, $x);
            Math::MPFR::Rmpfr_zero_p($r) || return 1;
            Math::MPC::RMPC_IM($r, $x);
            !Math::MPFR::Rmpfr_zero_p($r);
        }
    }

    sub __numify__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_get_d($x, $ROUND);
        }

        elsif ($sig eq q(Math::GMPq)) {
            goto &Math::GMPq::Rmpq_get_d;
        }

        elsif ($sig eq q(Math::GMPz)) {
            goto &Math::GMPz::Rmpz_get_d;
        }

        elsif ($sig eq q(Math::MPC)) {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_RE($r, $x);
            Math::MPFR::Rmpfr_get_d($r, $ROUND);
        }
    }

    sub __stringify__ {
        my ($x) = @_;

        my $sig = ref($x);

        if ($sig eq q(Math::GMPz)) {
            Math::GMPz::Rmpz_get_str($x, 10);
        }

        elsif ($sig eq q(Math::GMPq)) {

            #Math::GMPq::Rmpq_get_str($x, 10);
            Math::GMPq::Rmpq_integer_p($x) && return Math::GMPq::Rmpq_get_str($x, 10);

            $PREC = CORE::int($PREC) if ref($PREC);

            my $prec = $PREC >> 2;
            my $sgn  = Math::GMPq::Rmpq_sgn($x);

            my $n = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set($n, $x);
            Math::GMPq::Rmpq_abs($n, $n) if $sgn < 0;

            my $p = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_str($p, '1' . ('0' x CORE::abs($prec)), 10);

            if ($prec < 0) {
                Math::GMPq::Rmpq_div($n, $n, $p);
            }
            else {
                Math::GMPq::Rmpq_mul($n, $n, $p);
            }

            state $half = do {
                my $q = Math::GMPq::Rmpq_init_nobless();
                Math::GMPq::Rmpq_set_ui($q, 1, 2);
                $q;
            };

            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_add($n, $n, $half);
            Math::GMPz::Rmpz_set_q($z, $n);

            # Too much rounding... Give up and return an MPFR stringified number.
            !Math::GMPz::Rmpz_sgn($z) && $PREC >= 2 && do {
                my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
                Math::MPFR::Rmpfr_set_q($mpfr, $x, $ROUND);
                return Math::MPFR::Rmpfr_get_str($mpfr, 10, $prec, $ROUND);
            };

            if (Math::GMPz::Rmpz_odd_p($z) and Math::GMPq::Rmpq_integer_p($n)) {
                Math::GMPz::Rmpz_sub_ui($z, $z, 1);
            }

            Math::GMPq::Rmpq_set_z($n, $z);

            if ($prec < 0) {
                Math::GMPq::Rmpq_mul($n, $n, $p);
            }
            else {
                Math::GMPq::Rmpq_div($n, $n, $p);
            }

            my $num = Math::GMPz::Rmpz_init();
            my $den = Math::GMPz::Rmpz_init();

            Math::GMPq::Rmpq_numref($num, $n);
            Math::GMPq::Rmpq_denref($den, $n);

            my @r;
            while (1) {
                Math::GMPz::Rmpz_div($z, $num, $den);
                push @r, Math::GMPz::Rmpz_get_str($z, 10);

                Math::GMPz::Rmpz_mul($z, $z, $den);
                Math::GMPz::Rmpz_sub($num, $num, $z);
                last if !Math::GMPz::Rmpz_sgn($num);

                my $s = -1;
                while (Math::GMPz::Rmpz_cmp($den, $num) > 0) {
                    Math::GMPz::Rmpz_mul_ui($num, $num, 10);
                    ++$s;
                }

                push(@r, '0' x $s) if ($s > 0);
            }

            ($sgn < 0 ? "-" : '') . shift(@r) . (('.' . join('', @r)) =~ s/0+\z//r =~ s/\.\z//r);
        }

        elsif ($sig eq q(Math::MPFR)) {

            Math::MPFR::Rmpfr_number_p($x)
              || return (
                           Math::MPFR::Rmpfr_nan_p($x)   ? 'NaN'
                         : Math::MPFR::Rmpfr_sgn($x) < 0 ? '-Inf'
                         :                                 'Inf'
                        );

            # log(10)/log(2) =~ 3.3219280948873623
            my $digits = CORE::int(CORE::int($PREC) >> 2);
            my $str = Math::MPFR::Rmpfr_get_str($x, 10, $digits, $ROUND);

            if ($str =~ s/e(-?[0-9]+)\z//) {
                my $exp = $1;

                my $sgn = '';
                if (substr($str, 0, 1) eq '-') {
                    $sgn = '-';
                    substr($str, 0, 1, '');
                }

                my ($before, $after) = split(/\./, $str);

                if ($exp > 0) {
                    if ($exp >= CORE::length($after)) {
                        $after = '.' . $after . "e$exp";
                    }
                    else {
                        substr($after, $exp, 0, '.');
                    }
                }
                else {
                    if (CORE::abs($exp) >= CORE::length($before)) {

                        my $diff = CORE::abs($exp) - CORE::length($before);

                        if ($diff <= $digits) {
                            $before = ('0' x (CORE::abs($exp) - CORE::length($before) + 1)) . $before;
                            substr($before, $exp, 0, '.');
                        }
                        else {
                            $before .= '.';
                            $after  .= "e$exp";
                        }
                    }
                }

                $str = $sgn . $before . $after;
            }

            if (index($str, 'e') == -1) {
                $str =~ s/0+\z//;
                $str =~ s/\.\z//;
            }

            (!$str or $str eq '-') ? '0' : $str;
        }

        elsif ($sig eq q(Math::MPC)) {
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
            $re eq '0' ? $sign eq '+' ? "${im}i" : "$sign${im}i" : "$re$sign${im}i";
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

    *trunc = \&int;

    sub rat {
        my ($x) = @_;
        ref($$x) eq 'Math::GMPq' ? $x : bless \(_any2mpq($$x) // (goto &nan));
    }

    sub float {
        my ($x) = @_;
        ref($$x) eq 'Math::MPFR' ? $x : bless \_any2mpfr($$x);
    }

    sub complex {
        my ($x) = @_;
        ref($$x) eq 'Math::MPC' ? $x : bless \_any2mpc($$x);
    }

    sub pair {
        my ($x, $y) = @_;
        Sidef::Types::Number::Complex->new($x, $y);
    }

    sub __norm__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPC)) {
            my $f = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPC::Rmpc_norm($f, $x, $ROUND);
            $f;
        }
        elsif ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_sqr($x, $x, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::GMPz)) {
            Math::GMPz::Rmpz_mul($x, $x, $x);
            $x;
        }
        elsif ($sig eq q(Math::GMPq)) {
            Math::GMPq::Rmpq_mul($x, $x, $x);
            $x;
        }
    }

    sub norm {
        my ($x) = @_;
        bless \__norm__(ref($$x) eq 'Math::MPC' ? $$x : _copy($$x));
    }

    sub conj {
        my ($x) = @_;
        ref($$x) eq 'Math::MPC' or return $x;
        my $r = Math::MPC::Rmpc_init2($PREC);
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
        Math::MPFR::Rmpfr_mul_ui($tau, $tau, 2, $ROUND);
        bless \$tau;
    }

    sub ln2 {
        my $ln2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_log2($ln2, $ROUND);
        bless \$ln2;
    }

    sub euler {
        my $euler = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_euler($euler, $ROUND);
        bless \$euler;
    }

    *Y = \&euler;

    sub catalan {
        my $catalan = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_catalan($catalan, $ROUND);
        bless \$catalan;
    }

    *C = \&catalan;

    sub i {
        my ($x) = @_;

        state $i = do {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_ui_ui($c, 0, 1, $ROUND);
            $c;
        };

        if (ref($x) eq __PACKAGE__) {
            bless \__mul__(_copy($i), $$x);
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
        state $five4_f = (Math::MPFR::Rmpfr_init_set_str_nobless("1.25", 10, $ROUND))[0];
        state $half_f  = (Math::MPFR::Rmpfr_init_set_str_nobless("0.5",  10, $ROUND))[0];

        my $phi = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_sqrt($phi, $five4_f, $ROUND);
        Math::MPFR::Rmpfr_add($phi, $phi, $half_f, $ROUND);

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

    sub _zero {
        state $zero = Math::GMPz::Rmpz_init_set_ui(0);
    }

    sub zero {
        state $zero = do {
            my $r = Math::GMPz::Rmpz_init_set_ui(0);
            bless \$r;
        };
    }

    sub _one {
        state $one = Math::GMPz::Rmpz_init_set_ui(1);
    }

    sub one {
        state $one = do {
            my $r = Math::GMPz::Rmpz_init_set_ui(1);
            bless \$r;
        };
    }

    sub _mone {
        state $mone = Math::GMPz::Rmpz_init_set_si(-1);
    }

    sub mone {
        state $mone = do {
            my $r = Math::GMPz::Rmpz_init_set_si(-1);
            bless \$r;
        };
    }

    sub __add__ {
        my ($x, $y) = @_;
        my $sig = join(' ', ref($x), ref($y));

        #
        ## GMPz
        #
        if ($sig eq q(Math::GMPz Math::GMPz)) {
            Math::GMPz::Rmpz_add($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPz Math::GMPq)) {
            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_add_z($q, $y, $x);
            $q;
        }

        elsif ($sig eq q(Math::GMPz Math::MPFR)) {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_add_z($f, $y, $x, $ROUND);
            $f;
        }

        elsif ($sig eq q(Math::GMPz Math::MPC)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($c, $x, $ROUND);
            Math::MPC::Rmpc_add($c, $c, $y, $ROUND);
            $c;
        }

        #
        ## GMPq
        #
        elsif ($sig eq q(Math::GMPq Math::GMPq)) {
            Math::GMPq::Rmpq_add($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPq Math::GMPz)) {
            Math::GMPq::Rmpq_add_z($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPq Math::MPFR)) {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_add_q($f, $y, $x, $ROUND);
            $f;
        }

        elsif ($sig eq q(Math::GMPq Math::MPC)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($c, $x, $ROUND);
            Math::MPC::Rmpc_add($c, $c, $y, $ROUND);
            $c;
        }

        #
        ## MPFR
        #
        elsif ($sig eq q(Math::MPFR Math::MPFR)) {
            Math::MPFR::Rmpfr_add($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPq)) {
            Math::MPFR::Rmpfr_add_q($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPz)) {
            Math::MPFR::Rmpfr_add_z($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set($c, $y, $ROUND);
            Math::MPC::Rmpc_add_fr($c, $c, $x, $ROUND);
            $c;
        }

        #
        ## MPC
        #
        elsif ($sig eq q(Math::MPC Math::MPC)) {
            Math::MPC::Rmpc_add($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            Math::MPC::Rmpc_add_fr($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::GMPz)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($c, $y, $ROUND);
            Math::MPC::Rmpc_add($x, $x, $c, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::GMPq)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($c, $y, $ROUND);
            Math::MPC::Rmpc_add($x, $x, $c, $ROUND);
            $x;
        }
    }

    sub add {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__add__(_copy($$x), $$y);
    }

    sub __sub__ {
        my ($x, $y) = @_;
        my $sig = join(' ', ref($x), ref($y));

        #
        ## GMPq
        #
        if ($sig eq q(Math::GMPq Math::GMPq)) {
            Math::GMPq::Rmpq_sub($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPq Math::GMPz)) {
            Math::GMPq::Rmpq_sub_z($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPq Math::MPFR)) {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_q($f, $x, $ROUND);
            Math::MPFR::Rmpfr_sub($f, $f, $y, $ROUND);
            $f;
        }

        elsif ($sig eq q(Math::GMPq Math::MPC)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($c, $x, $ROUND);
            Math::MPC::Rmpc_sub($c, $c, $y, $ROUND);
            $c;
        }

        #
        ## GMPz
        #
        elsif ($sig eq q(Math::GMPz Math::GMPz)) {
            Math::GMPz::Rmpz_sub($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPz Math::GMPq)) {
            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_z_sub($q, $x, $y);
            $q;
        }

        elsif ($sig eq q(Math::GMPz Math::MPFR)) {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_z($f, $x, $ROUND);
            Math::MPFR::Rmpfr_sub($f, $f, $y, $ROUND);
            $f;
        }

        elsif ($sig eq q(Math::GMPz Math::MPC)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($c, $x, $ROUND);
            Math::MPC::Rmpc_sub($c, $c, $y, $ROUND);
            $c;
        }

        #
        ## MPFR
        #
        elsif ($sig eq q(Math::MPFR Math::MPFR)) {
            Math::MPFR::Rmpfr_sub($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPq)) {
            Math::MPFR::Rmpfr_sub_q($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPz)) {
            Math::MPFR::Rmpfr_sub_z($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_fr($c, $x, $ROUND);
            Math::MPC::Rmpc_sub($c, $c, $y, $ROUND);
            $c;
        }

        #
        ## MPC
        #
        elsif ($sig eq q(Math::MPC Math::MPC)) {
            Math::MPC::Rmpc_sub($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_fr($c, $y, $ROUND);
            Math::MPC::Rmpc_sub($x, $x, $c, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::GMPz)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($c, $y, $ROUND);
            Math::MPC::Rmpc_sub($x, $x, $c, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::GMPq)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($c, $y, $ROUND);
            Math::MPC::Rmpc_sub($x, $x, $c, $ROUND);
            $x;
        }
    }

    sub sub {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__sub__(_copy($$x), $$y);
    }

    sub __mul__ {
        my ($x, $y) = @_;
        my $sig = join(' ', ref($x), ref($y));

        #
        ## GMPq
        #
        if ($sig eq q(Math::GMPq Math::GMPq)) {
            Math::GMPq::Rmpq_mul($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPq Math::GMPz)) {
            Math::GMPq::Rmpq_mul_z($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPq Math::MPFR)) {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_mul_q($f, $y, $x, $ROUND);
            $f;
        }

        elsif ($sig eq q(Math::GMPq Math::MPC)) {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($r, $x, $ROUND);
            Math::MPC::Rmpc_mul($r, $r, $y, $ROUND);
            $r;
        }

        #
        ## GMPz
        #
        elsif ($sig eq q(Math::GMPz Math::GMPz)) {
            Math::GMPz::Rmpz_mul($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPz Math::GMPq)) {
            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_mul_z($q, $y, $x);
            $q;
        }

        elsif ($sig eq q(Math::GMPz Math::MPFR)) {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_mul_z($f, $y, $x, $ROUND);
            $f;
        }

        elsif ($sig eq q(Math::GMPz Math::MPC)) {
            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($r, $x, $ROUND);
            Math::MPC::Rmpc_mul($r, $r, $y, $ROUND);
            $r;
        }

        #
        ## MPFR
        #
        elsif ($sig eq q(Math::MPFR Math::MPFR)) {
            Math::MPFR::Rmpfr_mul($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPq)) {
            Math::MPFR::Rmpfr_mul_q($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPz)) {
            Math::MPFR::Rmpfr_mul_z($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set($c, $y, $ROUND);
            Math::MPC::Rmpc_mul_fr($c, $c, $x, $ROUND);
            $c;
        }

        #
        ## MPC
        #
        elsif ($sig eq q(Math::MPC Math::MPC)) {
            Math::MPC::Rmpc_mul($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            Math::MPC::Rmpc_mul_fr($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::GMPz)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($c, $y, $ROUND);
            Math::MPC::Rmpc_mul($x, $x, $c, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::GMPq)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($c, $y, $ROUND);
            Math::MPC::Rmpc_mul($x, $x, $c, $ROUND);
            $x;
        }
    }

    sub mul {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__mul__(_copy($$x), $$y);
    }

    sub __div__ {
        my ($x, $y) = @_;
        my $sig = join(' ', ref($x), ref($y));

        #
        ## GMPq
        #
        if ($sig eq q(Math::GMPq Math::GMPq)) {

            # Check for division by zero
            Math::GMPq::Rmpq_sgn($y) || do {
                (@_) = (_mpq2mpfr($x), $y);
                goto __SUB__;
            };

            Math::GMPq::Rmpq_div($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPq Math::GMPz)) {

            # Check for division by zero
            Math::GMPz::Rmpz_sgn($y) || do {
                (@_) = (_mpq2mpfr($x), $y);
                goto __SUB__;
            };

            Math::GMPq::Rmpq_div_z($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPq Math::MPFR)) {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_q($f, $x, $ROUND);
            Math::MPFR::Rmpfr_div($f, $f, $y, $ROUND);
            $f;
        }

        elsif ($sig eq q(Math::GMPq Math::MPC)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($c, $x, $ROUND);
            Math::MPC::Rmpc_div($c, $c, $y, $ROUND);
            $c;
        }

        #
        ## GMPz
        #
        elsif ($sig eq q(Math::GMPz Math::GMPz)) {

            # Check for division by zero
            Math::GMPz::Rmpz_sgn($y) || do {
                (@_) = (_mpz2mpfr($x), $y);
                goto __SUB__;
            };

            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_num($r, $x);
            Math::GMPq::Rmpq_set_den($r, $y);
            Math::GMPq::Rmpq_canonicalize($r);
            $r;
        }

        elsif ($sig eq q(Math::GMPz Math::GMPq)) {

            # Check for division by zero
            Math::GMPq::Rmpq_sgn($y) || do {
                (@_) = (_mpz2mpfr($x), $y);
                goto __SUB__;
            };

            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_z_div($q, $x, $y);
            $q;
        }

        elsif ($sig eq q(Math::GMPz Math::MPFR)) {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_z($f, $x, $ROUND);
            Math::MPFR::Rmpfr_div($f, $f, $y, $ROUND);
            $f;
        }

        elsif ($sig eq q(Math::GMPz Math::MPC)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($c, $x, $ROUND);
            Math::MPC::Rmpc_div($c, $c, $y, $ROUND);
            $c;
        }

        #
        ## MPFR
        #
        elsif ($sig eq q(Math::MPFR Math::MPFR)) {
            Math::MPFR::Rmpfr_div($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPq)) {
            Math::MPFR::Rmpfr_div_q($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPz)) {
            Math::MPFR::Rmpfr_div_z($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_fr($c, $x, $ROUND);
            Math::MPC::Rmpc_div($c, $c, $y, $ROUND);
            $c;
        }

        #
        ## MPC
        #
        elsif ($sig eq q(Math::MPC Math::MPC)) {
            Math::MPC::Rmpc_div($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            Math::MPC::Rmpc_div_fr($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::GMPz)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_z($c, $y, $ROUND);
            Math::MPC::Rmpc_div($x, $x, $c, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::GMPq)) {
            my $c = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_q($c, $y, $ROUND);
            Math::MPC::Rmpc_div($x, $x, $c, $ROUND);
            $x;
        }
    }

    sub div {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__div__(_copy($$x), $$y);
    }

    #
    ## Integer operations
    #

    sub iadd {
        my ($x, $y) = @_;
        _valid(\$y);
        $x = _copy2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y)  // (goto &nan);
        Math::GMPz::Rmpz_add($x, $x, $y);
        bless \$x;
    }

    sub isub {
        my ($x, $y) = @_;
        _valid(\$y);
        $x = _copy2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y)  // (goto &nan);
        Math::GMPz::Rmpz_sub($x, $x, $y);
        bless \$x;
    }

    sub imul {
        my ($x, $y) = @_;
        _valid(\$y);
        $x = _copy2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y)  // (goto &nan);
        Math::GMPz::Rmpz_mul($x, $x, $y);
        bless \$x;
    }

    sub idiv {
        my ($x, $y) = @_;
        _valid(\$y);
        $x = _copy2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y)  // (goto &nan);

        # Detect division by zero
        if (!Math::GMPz::Rmpz_sgn($y)) {
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
        }

        Math::GMPz::Rmpz_tdiv_q($x, $x, $y);
        bless \$x;
    }

    sub neg {
        my ($x) = @_;
        $x = _copy($$x);
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_neg($x, $x, $ROUND);
        }
        elsif ($sig eq q(Math::GMPq)) {
            Math::GMPq::Rmpq_neg($x, $x);
        }
        elsif ($sig eq q(Math::GMPz)) {
            Math::GMPz::Rmpz_neg($x, $x);
        }
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_neg($x, $x, $ROUND);
        }
        bless \$x;
    }

    *negative = \&neg;

    sub abs {
        my ($x) = @_;

        $x = $$x;
        my $sig = ref($x);

        if ($sig eq q(Math::GMPz)) {
            Math::GMPz::Rmpz_sgn($x) >= 0 && return $_[0];
            $x = _copy($x);
            Math::GMPz::Rmpz_abs($x, $x);
        }
        elsif ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_sgn($x) >= 0 && return $_[0];
            $x = _copy($x);
            Math::MPFR::Rmpfr_abs($x, $x, $ROUND);
        }
        elsif ($sig eq q(Math::GMPq)) {
            Math::GMPq::Rmpq_sgn($x) >= 0 && return $_[0];
            $x = _copy($x);
            Math::GMPq::Rmpq_abs($x, $x);
        }
        elsif ($sig eq q(Math::MPC)) {
            my $mpfr = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($mpfr, $x, $ROUND);
            $x = $mpfr;
        }

        bless \$x;
    }

    *pos      = \&abs;
    *positive = \&abs;

    sub __inv__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::GMPq)) {

            # Check for division by zero
            if (!Math::GMPq::Rmpq_sgn($x)) {
                (@_) = _mpq2mpfr($x);
                goto __SUB__;
            }

            Math::GMPq::Rmpq_inv($x, $x);
            $x;
        }

        elsif ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_ui_div($x, 1, $x, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::GMPz)) {
            (@_) = _mpz2mpq($x);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            $x;
        }
    }

    sub inv {
        my ($x) = @_;
        bless \__inv__(_copy($$x));
    }

    sub sqr {
        my ($x) = @_;
        $x = _copy($$x);
        bless \__mul__($x, $x);
    }

    sub __sqrt__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {

            # Complex for x < 0
            if (Math::MPFR::Rmpfr_sgn($x) < 0) {
                (@_) = _mpfr2mpc($_[0]);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_sqrt($x, $x, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_sqrt($x, $x, $ROUND);
            $x;
        }
    }

    sub sqrt {
        my ($x) = @_;
        bless \__sqrt__(_copy2mpfr_mpc($$x));
    }

    sub __cbrt__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {

            # Complex for x < 0
            if (Math::MPFR::Rmpfr_sgn($x) < 0) {
                (@_) = _mpfr2mpc($_[0]);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_cbrt($x, $x, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC)) {
            state $three_inv = do {
                my $r = Math::MPC::Rmpc_init2_nobless(CORE::int($PREC));
                Math::MPC::Rmpc_set_ui($r, 3, $ROUND);
                Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
                $r;
            };
            Math::MPC::Rmpc_pow($x, $x, $three_inv, $ROUND);
            $x;
        }
    }

    sub cbrt {
        my ($x) = @_;
        bless \__cbrt__(_copy2mpfr_mpc($$x));
    }

    sub __iroot__ {
        my ($x, $y) = @_;

        # $x is a Math::GMPz object
        # $y is a signed integer

        if ($y == 0) {
            Math::GMPz::Rmpz_sgn($x) || return $x;    # 0^Inf = 0

            # 1^Inf = 1 ; (-1)^Inf = 1
            if (Math::GMPz::Rmpz_cmpabs_ui($x, 1) == 0) {
                Math::GMPz::Rmpz_abs($x, $x);
                return $x;
            }

            goto &_inf;
        }
        elsif ($y < 0) {
            my $sign = Math::GMPz::Rmpz_sgn($x) || goto &_inf;    # 1 / 0^k = Inf
            Math::GMPz::Rmpz_cmp_ui($x, 1) == 0 and return $x;    # 1 / 1^k = 1

            if ($sign < 0) {
                goto &_nan;
            }

            Math::GMPz::Rmpz_set_ui($x, 0);
            return $x;
        }
        elsif ($y % 2 == 0 and Math::GMPz::Rmpz_sgn($x) < 0) {
            goto &_nan;
        }

        Math::GMPz::Rmpz_root($x, $x, $y);
        $x;
    }

    sub iroot {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__iroot__(_copy2mpz($$x) // (goto &nan), _any2si($$y) // (goto &nan));
    }

    sub isqrt {
        my ($x) = @_;
        my $z = _copy2mpz($$x) // goto &nan;
        Math::GMPz::Rmpz_sgn($z) < 0 and goto &nan;
        Math::GMPz::Rmpz_sqrt($z, $z);
        bless \$z;
    }

    sub icbrt {
        my ($x) = @_;
        bless \__iroot__(_copy2mpz($$x) // (goto &nan), 3);
    }

    sub isqrtrem {
        my ($x) = @_;

        $x = _copy2mpz($$x) // goto &nan;

        Math::GMPz::Rmpz_sgn($x) < 0
          and return ((nan()) x 2);

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sqrtrem($x, $r, $x);
        ((bless \$x), (bless \$r));
    }

    sub irootrem {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _copy2mpz($$x) // goto &nan;
        $y = _any2si($$y)   // goto &nan;

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
        Math::GMPz::Rmpz_rootrem($x, $r, $x, $y);
        ((bless \$x), (bless \$r));
    }

    sub __pow__ {
        my ($x, $y) = @_;
        my $sig = join(' ', ref($x), ref($y) || '$');

        #
        ## GMPq
        #
        if ($sig eq q(Math::GMPq $)) {

            Math::GMPq::Rmpq_pow_ui($x, $x, CORE::abs($y));

            if ($y < 0) {
                if (!Math::GMPq::Rmpq_sgn($x)) {
                    my $inf = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
                    Math::MPFR::Rmpfr_set_inf($inf, 1);
                    return $inf;
                }

                Math::GMPq::Rmpq_inv($x, $x);
            }

            $x;
        }

        elsif ($sig eq q(Math::GMPq Math::GMPq)) {

            # Integer power
            if (Math::GMPq::Rmpq_integer_p($y)) {
                (@_) = ($x, Math::GMPq::Rmpq_get_d($y));
                goto __SUB__;
            }

            # (-x)^(a/b) is a complex number
            elsif (Math::GMPq::Rmpq_sgn($x) < 0) {
                (@_) = (_mpq2mpc($x), _mpq2mpc($y));
                goto __SUB__;
            }

            (@_) = (_mpq2mpfr($x), _mpq2mpfr($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPq Math::GMPz)) {
            (@_) = ($_[0], Math::GMPz::Rmpz_get_d($_[1]));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPq Math::MPFR)) {
            (@_) = (_mpq2mpfr($_[0]), $_[1]);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPq Math::MPC)) {
            (@_) = (_mpq2mpc($_[0]), $_[1]);
            goto __SUB__;
        }

        #
        ## GMPz
        #

        elsif ($sig eq q(Math::GMPz $)) {

            Math::GMPz::Rmpz_pow_ui($x, $x, CORE::abs($y));

            if ($y < 0) {
                Math::GMPz::Rmpz_sgn($x) || do {
                    my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
                    Math::MPFR::Rmpfr_set_inf($r, 1);
                    return $r;
                };

                my $q = Math::GMPq::Rmpq_init();
                Math::GMPq::Rmpq_set_z($q, $x);
                Math::GMPq::Rmpq_inv($q, $q);
                return $q;
            }

            $x;
        }

        elsif ($sig eq q(Math::GMPz Math::GMPz)) {
            (@_) = ($_[0], Math::GMPz::Rmpz_get_d($_[1]));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPz Math::GMPq)) {
            if (Math::GMPq::Rmpq_integer_p($_[1])) {
                (@_) = ($_[0], Math::GMPq::Rmpq_get_d($_[1]));
            }
            else {
                (@_) = (_mpz2mpfr($_[0]), _mpq2mpfr($_[1]));
            }
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPz Math::MPFR)) {
            (@_) = (_mpz2mpfr($_[0]), $_[1]);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPz Math::MPC)) {
            (@_) = (_mpz2mpc($_[0]), $_[1]);
            goto __SUB__;
        }

        #
        ## MPFR
        #
        elsif ($sig eq q(Math::MPFR Math::MPFR)) {

            if (    Math::MPFR::Rmpfr_sgn($x) < 0
                and !Math::MPFR::Rmpfr_integer_p($y)
                and Math::MPFR::Rmpfr_number_p($y)) {
                (@_) = (_mpfr2mpc($x), $y);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_pow($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR $)) {
            $y < 0
              ? Math::MPFR::Rmpfr_pow_si($x, $x, $y, $ROUND)
              : Math::MPFR::Rmpfr_pow_ui($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPq)) {
            (@_) = ($_[0], _mpq2mpfr($_[1]));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPz)) {
            Math::MPFR::Rmpfr_pow_z($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            (@_) = (_mpfr2mpc($_[0]), $_[1]);
            goto __SUB__;
        }

        #
        ## MPC
        #
        elsif ($sig eq q(Math::MPC Math::MPC)) {
            Math::MPC::Rmpc_pow($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC $)) {
            $y < 0
              ? Math::MPC::Rmpc_pow_si($x, $x, $y, $ROUND)
              : Math::MPC::Rmpc_pow_ui($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            Math::MPC::Rmpc_pow_fr($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::GMPz)) {
            Math::MPC::Rmpc_pow_z($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC Math::GMPq)) {
            (@_) = ($_[0], _mpq2mpc($_[1]));
            goto __SUB__;
        }
    }

    sub root {
        my ($x, $y) = @_;
        bless \__pow__(_copy($$x), __inv__(_copy($$y)));
    }

    sub pow {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__pow__(_copy($$x), $$y);
    }

    sub ipow {
        my ($x, $y) = @_;
        _valid(\$y);

        $x = _copy2mpz($$x) // goto &nan;
        $y = _any2si($$y)   // goto &nan;

        Math::GMPz::Rmpz_pow_ui($x, $x, CORE::abs($y));

        if ($y < 0) {
            Math::GMPz::Rmpz_sgn($x) || goto &inf;    # 0^(-y) = Inf
            state $ONE_Z = Math::GMPz::Rmpz_init_set_ui_nobless(1);
            Math::GMPz::Rmpz_tdiv_q($x, $ONE_Z, $x);
        }

        bless \$x;
    }

    sub __log2__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {

            # Complex for x < 0
            if (Math::MPFR::Rmpfr_sgn($x) < 0) {
                (@_) = _mpfr2mpc($x);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_log2($x, $x, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC)) {
            my $ln2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_const_log2($ln2, $ROUND);
            Math::MPC::Rmpc_log($x, $x, $ROUND);
            Math::MPC::Rmpc_div_fr($x, $x, $ln2, $ROUND);
            $x;
        }
    }

    sub __log10__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {

            # Complex for x < 0
            if (Math::MPFR::Rmpfr_sgn($x) < 0) {
                (@_) = _mpfr2mpc($x);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_log10($x, $x, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC)) {

            state $MPC_VERSION = Math::MPC::MPC_VERSION();

            if ($MPC_VERSION >= 65536) {    # available only in mpc>=1.0.0
                Math::MPC::Rmpc_log10($x, $x, $ROUND);
            }
            else {
                my $ln10 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
                Math::MPFR::Rmpfr_set_ui($ln10, 10, $ROUND);
                Math::MPFR::Rmpfr_log($ln10, $ln10, $ROUND);
                Math::MPC::Rmpc_log($x, $x, $ROUND);
                Math::MPC::Rmpc_div_fr($x, $x, $ln10, $ROUND);
            }

            $x;
        }
    }

    sub __log__ {
        my ($x) = @_;

        my $sig = ref($x);

        #
        ## MPFR
        #
        if ($sig eq q(Math::MPFR)) {

            # Complex for x < 0
            if (Math::MPFR::Rmpfr_sgn($x) < 0) {
                (@_) = _mpfr2mpc($x);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_log($x, $x, $ROUND);
            $x;
        }

        #
        ## MPC
        #

        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_log($x, $x, $ROUND);
            $x;
        }
    }

    sub log {
        my ($x, $y) = @_;

        if (defined($y)) {
            _valid(\$y);
            bless \__div__(__log__(_copy2mpfr_mpc($$x)), __log__(_copy2mpfr_mpc($$y)));
        }
        else {
            bless \__log__(_copy2mpfr_mpc($$x));
        }
    }

    sub ln {
        my ($x) = @_;
        bless \__log__(_copy2mpfr_mpc($$x));
    }

    sub log2 {
        my ($x) = @_;
        bless \__log2__(_copy2mpfr_mpc($$x));
    }

    sub log10 {
        my ($x) = @_;
        bless \__log10__(_copy2mpfr_mpc($$x));
    }

    sub ilog {
        my ($x, $y) = @_;

        if (defined($y)) {
            _valid(\$y);
            bless \(_any2mpz(__div__(__log__(_copy2mpfr_mpc($$x)), __log__(_copy2mpfr_mpc($$y)))) // goto &nan);
        }
        else {
            bless \(_any2mpz(__log__(_copy2mpfr_mpc($$x))) // goto &nan);
        }
    }

    sub ilog2 {
        my ($x) = @_;
        bless \(_any2mpz(__log2__(_copy2mpfr_mpc($$x))) // goto &nan);
    }

    sub ilog10 {
        my ($x) = @_;
        bless \(_any2mpz(__log10__(_copy2mpfr_mpc($$x))) // goto &nan);
    }

    sub __lgrt__ {
        my $sig = ref($_[0]);

        if ($sig eq q(Math::MPFR)) {
            my ($d) = @_;

            # Return a complex number for x < e^(-1/e)
            if (Math::MPFR::Rmpfr_cmp_d($d, CORE::exp(-1 / CORE::exp(1))) < 0) {
                (@_) = _mpfr2mpc($d);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_log($d, $d, $ROUND);

            my $p = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_ui_pow_ui($p, 10, CORE::int(CORE::int($PREC) >> 2), $ROUND);
            Math::MPFR::Rmpfr_ui_div($p, 1, $p, $ROUND);

            my $x = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_ui($x, 1, $ROUND);

            my $y = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_ui($y, 0, $ROUND);

            my $count = 0;
            my $tmp   = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            while (1) {
                Math::MPFR::Rmpfr_sub($tmp, $x, $y, $ROUND);
                Math::MPFR::Rmpfr_cmpabs($tmp, $p) <= 0 and last;

                Math::MPFR::Rmpfr_set($y, $x, $ROUND);

                Math::MPFR::Rmpfr_log($tmp, $x, $ROUND);
                Math::MPFR::Rmpfr_add_ui($tmp, $tmp, 1, $ROUND);

                Math::MPFR::Rmpfr_add($x, $x, $d, $ROUND);
                Math::MPFR::Rmpfr_div($x, $x, $tmp, $ROUND);
                last if ++$count > CORE::int($PREC);
            }

            Math::MPFR::Rmpfr_set($d, $x, $ROUND);
            $d;
        }

        elsif ($sig eq q(Math::MPC)) {
            my ($x) = @_;

            my $p = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_ui_pow_ui($p, 10, CORE::int(CORE::int($PREC) >> 2), $ROUND);
            Math::MPFR::Rmpfr_ui_div($p, 1, $p, $ROUND);

            my $d = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_log($d, $x, $ROUND);

            Math::MPC::Rmpc_sqr($x, $x, $ROUND);
            Math::MPC::Rmpc_add_ui($x, $x, 1, $ROUND);
            Math::MPC::Rmpc_log($x, $x, $ROUND);

            my $y = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_ui($y, 0, $ROUND);

            my $tmp = Math::MPC::Rmpc_init2(CORE::int($PREC));
            my $abs = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

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
                last if ++$count > CORE::int($PREC);
            }

            $x;
        }

    }

    sub lgrt {
        my ($x) = @_;
        bless \__lgrt__(_copy2mpfr_mpc($$x));
    }

    sub __LambertW__ {
        my $sig = ref($_[0]);

        if ($sig eq q(Math::MPFR)) {
            my ($r) = @_;

            # Return a complex number for x < -1/e
            if (Math::MPFR::Rmpfr_cmp_d($r, -1 / CORE::exp(1)) < 0) {
                (@_) = _mpfr2mpc($r);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_ui_pow_ui((my $p = Math::MPFR::Rmpfr_init2(CORE::int($PREC))),
                                        10, CORE::int(CORE::int($PREC) >> 2), $ROUND);
            Math::MPFR::Rmpfr_ui_div($p, 1, $p, $ROUND);

            Math::MPFR::Rmpfr_set_ui((my $x = Math::MPFR::Rmpfr_init2(CORE::int($PREC))), 1, $ROUND);
            Math::MPFR::Rmpfr_set_ui((my $y = Math::MPFR::Rmpfr_init2(CORE::int($PREC))), 0, $ROUND);

            my $count = 0;
            my $tmp   = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            while (1) {
                Math::MPFR::Rmpfr_sub($tmp, $x, $y, $ROUND);
                Math::MPFR::Rmpfr_cmpabs($tmp, $p) <= 0 and last;

                Math::MPFR::Rmpfr_set($y, $x, $ROUND);

                Math::MPFR::Rmpfr_log($tmp, $x, $ROUND);
                Math::MPFR::Rmpfr_add_ui($tmp, $tmp, 1, $ROUND);

                Math::MPFR::Rmpfr_add($x, $x, $r, $ROUND);
                Math::MPFR::Rmpfr_div($x, $x, $tmp, $ROUND);
                last if ++$count > CORE::int($PREC);
            }

            Math::MPFR::Rmpfr_log($x, $x, $ROUND);
            Math::MPFR::Rmpfr_set($r, $x, $ROUND);
            $r;
        }

        elsif ($sig eq q(Math::MPC)) {
            my ($c) = @_;

            my $p = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_ui_pow_ui($p, 10, CORE::int(CORE::int($PREC) >> 2), $ROUND);
            Math::MPFR::Rmpfr_ui_div($p, 1, $p, $ROUND);

            my $x = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set($x, $c, $ROUND);
            Math::MPC::Rmpc_sqrt($x, $x, $ROUND);
            Math::MPC::Rmpc_add_ui($x, $x, 1, $ROUND);

            my $y = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_ui($y, 0, $ROUND);

            my $tmp = Math::MPC::Rmpc_init2(CORE::int($PREC));
            my $abs = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            my $count = 0;
            while (1) {
                Math::MPC::Rmpc_sub($tmp, $x, $y, $ROUND);

                Math::MPC::Rmpc_abs($abs, $tmp, $ROUND);
                Math::MPFR::Rmpfr_cmp($abs, $p) <= 0 and last;

                Math::MPC::Rmpc_set($y, $x, $ROUND);

                Math::MPC::Rmpc_log($tmp, $x, $ROUND);
                Math::MPC::Rmpc_add_ui($tmp, $tmp, 1, $ROUND);

                Math::MPC::Rmpc_add($x, $x, $c, $ROUND);
                Math::MPC::Rmpc_div($x, $x, $tmp, $ROUND);
                last if ++$count > CORE::int($PREC);
            }

            Math::MPC::Rmpc_log($x, $x, $ROUND);
            $x;
        }
    }

    sub lambert_w {
        my ($x) = @_;
        bless \__LambertW__(_copy2mpfr_mpc($$x));
    }

    *LambertW = \&lambert_w;

    sub __exp__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_exp($x, $x, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_exp($x, $x, $ROUND);
            $x;
        }
    }

    sub exp {
        my ($x) = @_;
        bless \__exp__(_copy2mpfr_mpc($$x));
    }

    sub exp2 {
        my ($x) = @_;
        state $base = Math::GMPz::Rmpz_init_set_ui(2);
        bless \__pow__($base, $$x);
    }

    sub exp10 {
        my ($x) = @_;
        state $base = Math::GMPz::Rmpz_init_set_ui(10);
        bless \__pow__($base, $$x);
    }

    #
    ## sin / sinh / asin / asinh
    #

    sub __sin__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_sin($x, $x, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_sin($x, $x, $ROUND);
            $x;
        }
    }

    sub sin {
        my ($x) = @_;
        bless \__sin__(_copy2mpfr_mpc($$x));
    }

    sub __sinh__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_sinh($x, $x, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_sinh($x, $x, $ROUND);
            $x;
        }
    }

    sub sinh {
        my ($x) = @_;
        bless \__sinh__(_copy2mpfr_mpc($$x));
    }

    sub __asin__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {

            # Return a complex number for x < -1 or x > 1
            if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
                or Math::MPFR::Rmpfr_cmp_si($x, -1) < 0) {
                $x = _mpfr2mpc($x);
                Math::MPC::Rmpc_asin($x, $x, $ROUND);
                return $x;
            }

            Math::MPFR::Rmpfr_asin($x, $x, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_asin($x, $x, $ROUND);
            $x;
        }
    }

    sub asin {
        my ($x) = @_;
        bless \__asin__(_copy2mpfr_mpc($$x));
    }

    sub __asinh__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_asinh($x, $x, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_asinh($x, $x, $ROUND);
            $x;
        }
    }

    sub asinh {
        my ($x) = @_;
        bless \__asinh__(_copy2mpfr_mpc($$x));
    }

    #
    ## cos / cosh / acos / acosh
    #

    sub __cos__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_cos($x, $x, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_cos($x, $x, $ROUND);
            $x;
        }
    }

    sub cos {
        my ($x) = @_;
        bless \__cos__(_copy2mpfr_mpc($$x));
    }

    sub __cosh__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_cosh($x, $x, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_cosh($x, $x, $ROUND);
            $x;
        }
    }

    sub cosh {
        my ($x) = @_;
        bless \__cosh__(_copy2mpfr_mpc($$x));
    }

    sub __acos__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {

            # Return a complex number for x < -1 or x > 1
            if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
                or Math::MPFR::Rmpfr_cmp_si($x, -1) < 0) {
                $x = _mpfr2mpc($x);
                Math::MPC::Rmpc_acos($x, $x, $ROUND);
                return $x;
            }

            Math::MPFR::Rmpfr_acos($x, $x, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_acos($x, $x, $ROUND);
            $x;
        }
    }

    sub acos {
        my ($x) = @_;
        bless \__acos__(_copy2mpfr_mpc($$x));
    }

    sub __acosh__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {

            # Return a complex number for x < 1
            if (Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0) {
                $x = _mpfr2mpc($x);
                Math::MPC::Rmpc_acosh($x, $x, $ROUND);
                return $x;
            }

            Math::MPFR::Rmpfr_acosh($x, $x, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_acosh($x, $x, $ROUND);
            $x;
        }
    }

    sub acosh {
        my ($x) = @_;
        bless \__acosh__(_copy2mpfr_mpc($$x));
    }

    #
    ## tan / tanh / atan / atanh
    #

    sub __tan__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_tan($x, $x, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_tan($x, $x, $ROUND);
            $x;
        }
    }

    sub tan {
        my ($x) = @_;
        bless \__tan__(_copy2mpfr_mpc($$x));
    }

    sub __tanh__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_tanh($x, $x, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_tanh($x, $x, $ROUND);
            $x;
        }
    }

    sub tanh {
        my ($x) = @_;
        bless \__tanh__(_copy2mpfr_mpc($$x));
    }

    sub __atan__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_atan($x, $x, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_atan($x, $x, $ROUND);
            $x;
        }
    }

    sub atan {
        my ($x) = @_;
        bless \__atan__(_copy2mpfr_mpc($$x));
    }

    sub __atanh__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {

            # Return a complex number for x <= -1 or x >= 1
            if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) >= 0
                or Math::MPFR::Rmpfr_cmp_si($x, -1) <= 0) {
                $x = _mpfr2mpc($x);
                Math::MPC::Rmpc_atanh($x, $x, $ROUND);
                return $x;
            }

            Math::MPFR::Rmpfr_atanh($x, $x, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_atanh($x, $x, $ROUND);
            $x;
        }
    }

    sub atanh {
        my ($x) = @_;
        bless \__atanh__(_copy2mpfr_mpc($$x));
    }

    sub __atan2__ {
        my ($x, $y) = @_;

        my $sig = join(' ', ref($x), ref($y));

        if ($sig eq q(Math::MPFR Math::MPFR)) {
            Math::MPFR::Rmpfr_atan2($x, $x, $y, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            (@_) = (_mpfr2mpc($x), $y);
            goto __SUB__;
        }

        # atan2(x, y) = atan(x/y)
        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            Math::MPC::Rmpc_div_fr($x, $x, $y, $ROUND);
            Math::MPC::Rmpc_atan($x, $x, $ROUND);
            $x;
        }

        # atan2(x, y) = atan(x/y)
        elsif ($sig eq q(Math::MPC Math::MPC)) {
            Math::MPC::Rmpc_div($x, $x, $y, $ROUND);
            Math::MPC::Rmpc_atan($x, $x, $ROUND);
            $x;
        }
    }

    sub atan2 {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__atan2__(_copy2mpfr_mpc($$x), _any2mpfr_mpc($$y));
    }

    #
    ## sec / sech / asec / asech
    #

    sub __sec__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_sec($x, $x, $ROUND);
            $x;
        }

        # sec(x) = 1/cos(x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_cos($x, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            $x;
        }
    }

    sub sec {
        my ($x) = @_;
        bless \__sec__(_copy2mpfr_mpc($$x));
    }

    sub __sech__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_sech($x, $x, $ROUND);
            $x;
        }

        # sech(x) = 1/cosh(x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_cosh($x, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            $x;
        }
    }

    sub sech {
        my ($x) = @_;
        bless \__sech__(_copy2mpfr_mpc($$x));
    }

    sub __asec__ {
        my ($x) = @_;
        my $sig = ref($x);

        # asec(x) = acos(1/x)
        if ($sig eq q(Math::MPFR)) {

            # Return a complex number for x > -1 and x < 1
            if (    Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0
                and Math::MPFR::Rmpfr_cmp_si($x, -1) > 0) {
                (@_) = _mpfr2mpc($x);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_ui_div($x, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_acos($x, $x, $ROUND);
            $x;
        }

        # asec(x) = acos(1/x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            Math::MPC::Rmpc_acos($x, $x, $ROUND);
            $x;
        }
    }

    sub asec {
        my ($x) = @_;
        bless \__asec__(_copy2mpfr_mpc($$x));
    }

    sub __asech__ {
        my ($x) = @_;
        my $sig = ref($x);

        # asech(x) = acosh(1/x)
        if ($sig eq q(Math::MPFR)) {

            # Return a complex number for x < 0 or x > 1
            if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
                or Math::MPFR::Rmpfr_cmp_ui($x, 0) < 0) {
                (@_) = _mpfr2mpc($x);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_ui_div($x, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_acosh($x, $x, $ROUND);
            $x;
        }

        # asech(x) = acosh(1/x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            Math::MPC::Rmpc_acosh($x, $x, $ROUND);
            $x;
        }
    }

    sub asech {
        my ($x) = @_;
        bless \__asech__(_copy2mpfr_mpc($$x));
    }

    #
    ## csc / csch / acsc / acsch
    #

    sub __csc__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_csc($x, $x, $ROUND);
            $x;
        }

        # csc(x) = 1/sin(x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_sin($x, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            $x;
        }
    }

    sub csc {
        my ($x) = @_;
        bless \__csc__(_copy2mpfr_mpc($$x));
    }

    sub __csch__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_csch($x, $x, $ROUND);
            $x;
        }

        # csch(x) = 1/sinh(x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_sinh($x, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            $x;
        }
    }

    sub csch {
        my ($x) = @_;
        bless \__csch__(_copy2mpfr_mpc($$x));
    }

    sub __acsc__ {
        my ($x) = @_;
        my $sig = ref($x);

        # acsc(x) = asin(1/x)
        if ($sig eq q(Math::MPFR)) {

            # Return a complex number for x > -1 and x < 1
            if (    Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0
                and Math::MPFR::Rmpfr_cmp_si($x, -1) > 0) {
                (@_) = _mpfr2mpc($x);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_ui_div($x, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_asin($x, $x, $ROUND);
            $x;
        }

        # acsc(x) = asin(1/x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            Math::MPC::Rmpc_asin($x, $x, $ROUND);
            $x;
        }
    }

    sub acsc {
        my ($x) = @_;
        bless \__acsc__(_copy2mpfr_mpc($$x));
    }

    sub __acsch__ {
        my ($x) = @_;
        my $sig = ref($x);

        # acsch(x) = asinh(1/x)
        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_ui_div($x, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_asinh($x, $x, $ROUND);
            $x;
        }

        # acsch(x) = asinh(1/x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            Math::MPC::Rmpc_asinh($x, $x, $ROUND);
            $x;
        }
    }

    sub acsch {
        my ($x) = @_;
        bless \__acsch__(_copy2mpfr_mpc($$x));
    }

    #
    ## cot / coth / acot / acoth
    #

    sub __cot__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_cot($x, $x, $ROUND);
            $x;
        }

        # cot(x) = 1/tan(x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_tan($x, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            $x;
        }
    }

    sub cot {
        my ($x) = @_;
        bless \__cot__(_copy2mpfr_mpc($$x));
    }

    sub __coth__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_coth($x, $x, $ROUND);
            $x;
        }

        # coth(x) = 1/tanh(x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_tanh($x, $x, $ROUND);
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            $x;
        }
    }

    sub coth {
        my ($x) = @_;
        bless \__coth__(_copy2mpfr_mpc($$x));
    }

    sub __acot__ {
        my ($x) = @_;
        my $sig = ref($x);

        # acot(x) = atan(1/x)
        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_ui_div($x, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_atan($x, $x, $ROUND);
            $x;
        }

        # acot(x) = atan(1/x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            Math::MPC::Rmpc_atan($x, $x, $ROUND);
            $x;
        }
    }

    sub acot {
        my ($x) = @_;
        bless \__acot__(_copy2mpfr_mpc($$x));
    }

    sub __acoth__ {
        my ($x) = @_;
        my $sig = ref($x);

        # acoth(x) = atanh(1/x)
        if ($sig eq q(Math::MPFR)) {

            # Return a complex number for x > -1 and x < 1
            if (    Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0
                and Math::MPFR::Rmpfr_cmp_si($x, -1) > 0) {
                (@_) = _mpfr2mpc($x);
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_ui_div($x, 1, $x, $ROUND);
            Math::MPFR::Rmpfr_atanh($x, $x, $ROUND);
            $x;
        }

        # acoth(x) = atanh(1/x)
        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_ui_div($x, 1, $x, $ROUND);
            Math::MPC::Rmpc_atanh($x, $x, $ROUND);
            $x;
        }
    }

    sub acoth {
        my ($x) = @_;
        bless \__acoth__(_copy2mpfr_mpc($$x));
    }

    sub __cis__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            my $cos = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $sin = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPFR::Rmpfr_sin_cos($sin, $cos, $x, $ROUND);

            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set_fr_fr($r, $cos, $sin, $ROUND);
            $r;
        }
        elsif ($sig eq q(Math::MPC)) {
            my $cos = Math::MPC::Rmpc_init2(CORE::int($PREC));
            my $sin = Math::MPC::Rmpc_init2(CORE::int($PREC));

            Math::MPC::Rmpc_sin_cos($sin, $cos, $x, $ROUND, $ROUND);

            Math::MPC::Rmpc_mul_i($sin, $sin, 1, $ROUND);
            Math::MPC::Rmpc_add($cos, $cos, $sin, $ROUND);

            $cos;
        }
    }

    sub cis {
        my ($x) = @_;
        bless \__cis__(_any2mpfr_mpc($$x));
    }

    sub __sin_cos__ {
        my ($x) = @_;
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            my $cos = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $sin = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPFR::Rmpfr_sin_cos($sin, $cos, $x, $ROUND);

            return ($sin, $cos);
        }

        if ($sig eq q(Math::MPC)) {
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
        my $sig = join(' ', ref($x), ref($y));

        if ($sig eq q(Math::MPFR Math::MPFR)) {

            if (   Math::MPFR::Rmpfr_sgn($x) < 0
                or Math::MPFR::Rmpfr_sgn($y) < 0) {
                (@_) = (_mpfr2mpc($x), _mpfr2mpc($y));
                goto __SUB__;
            }

            Math::MPFR::Rmpfr_agm($x, $x, $y, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC Math::MPC)) {    # both arguments are modified
            my ($a0, $g0) = ($x, $y);

            # agm(0,  x) = 0
            if (!Math::MPC::Rmpc_cmp_si_si($a0, 0, 0)) {
                return $a0;
            }

            # agm(x, 0) = 0
            if (!Math::MPC::Rmpc_cmp_si_si($g0, 0, 0)) {
                return $g0;
            }

            my $a1 = Math::MPC::Rmpc_init2($PREC);
            my $g1 = Math::MPC::Rmpc_init2($PREC);
            my $t  = Math::MPC::Rmpc_init2($PREC);

            my $count = 0;
            {
                Math::MPC::Rmpc_add($a1, $a0, $g0, $ROUND);
                Math::MPC::Rmpc_div_2exp($a1, $a1, 1, $ROUND);

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

            $g0;
        }
        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            (@_) = (_mpfr2mpc($x), $y);
            goto __SUB__;
        }
        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            (@_) = ($x, _mpfr2mpc($y));
            goto __SUB__;
        }
    }

    sub agm {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__agm__(_copy2mpfr_mpc($$x), _copy2mpfr_mpc($$y));
    }

    sub __hypot__ {
        my ($x, $y) = @_;
        my $sig = join(' ', ref($x), ref($y));

        # hypot(x, y) = sqrt(x^2 + y^2)
        if ($sig eq q(Math::MPFR Math::MPFR)) {
            Math::MPFR::Rmpfr_hypot($x, $x, $y, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($r, $y, $ROUND);
            Math::MPFR::Rmpfr_hypot($x, $x, $r, $ROUND);
            $x;
        }
        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($r, $x, $ROUND);
            Math::MPFR::Rmpfr_hypot($r, $r, $y, $ROUND);
            $r;
        }
        elsif ($sig eq q(Math::MPC Math::MPC)) {
            my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($r, $x, $ROUND);
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($f, $y, $ROUND);
            Math::MPFR::Rmpfr_hypot($r, $r, $f, $ROUND);
            $r;
        }
    }

    sub hypot {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__hypot__(_copy2mpfr_mpc($$x), _any2mpfr_mpc($$y));
    }

    sub gamma {
        my $x = _copy2mpfr(${$_[0]});
        Math::MPFR::Rmpfr_gamma($x, $x, $ROUND);
        bless \$x;
    }

    sub lngamma {
        my $x = _copy2mpfr(${$_[0]});
        Math::MPFR::Rmpfr_lngamma($x, $x, $ROUND);
        bless \$x;
    }

    sub lgamma {
        my $x = _copy2mpfr(${$_[0]});
        Math::MPFR::Rmpfr_lgamma($x, $x, $ROUND);
        bless \$x;
    }

    sub digamma {
        my $x = _copy2mpfr(${$_[0]});
        Math::MPFR::Rmpfr_digamma($x, $x, $ROUND);
        bless \$x;
    }

    #
    ## beta(x, y) = gamma(x)*gamma(y) / gamma(x+y)
    #
    sub beta {
        my ($x, $y) = @_;

        _valid(\$y);
        $x = _copy2mpfr($$x);
        $y = _copy2mpfr($$y);

        my $t = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_add($t, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_gamma($t, $t, $ROUND);
        Math::MPFR::Rmpfr_gamma($x, $x, $ROUND);
        Math::MPFR::Rmpfr_gamma($y, $y, $ROUND);
        Math::MPFR::Rmpfr_mul($x, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_div($x, $x, $t, $ROUND);

        bless \$x;
    }

    #
    ## eta(s) = (1 - 2^(1-s)) * zeta(s)
    #
    sub eta {
        my $r = _copy2mpfr(${$_[0]});

        # Special case for eta(1) = log(2)
        if (!Math::MPFR::Rmpfr_cmp_ui($r, 1)) {
            Math::MPFR::Rmpfr_add_ui($r, $r, 1, $ROUND);
            Math::MPFR::Rmpfr_log($r, $r, $ROUND);
            return bless \$r;
        }

        my $p = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_set($p, $r, $ROUND);
        Math::MPFR::Rmpfr_ui_sub($p, 1, $p, $ROUND);
        Math::MPFR::Rmpfr_ui_pow($p, 2, $p, $ROUND);
        Math::MPFR::Rmpfr_ui_sub($p, 1, $p, $ROUND);

        Math::MPFR::Rmpfr_zeta($r, $r, $ROUND);
        Math::MPFR::Rmpfr_mul($r, $r, $p, $ROUND);

        bless \$r;
    }

    sub zeta {
        my $r = _copy2mpfr(${$_[0]});
        Math::MPFR::Rmpfr_zeta($r, $r, $ROUND);
        bless \$r;
    }

    sub bernfrac {
        my ($n) = @_;

        $n = _any2ui($$n) // goto &nan;

        $n == 0 and return ONE;
        $n > 1 and $n % 2 and return ZERO;    # Bn=0 for odd n>1

        # Using bernfrac() from `Math::Prime::Util::GMP`
        my ($num, $den) = Math::Prime::Util::GMP::bernfrac($n);

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_str($q, "$num/$den", 10);
        bless \$q;
    }

    *bern      = \&bernfrac;
    *bernoulli = \&bernfrac;

    sub bernreal {
        my ($n) = @_;

        $n = _any2ui($$n) // goto &nan;

        # |B(n)| = zeta(n) * n! / 2^(n-1) / pi^n

        $n == 0 and return ONE;
        $n == 1 and return do { state $x = bless(\_str2obj('1/2')) };
        $n % 2  and return ZERO;                                        # Bn = 0 for odd n>1

        #local CORE::int($PREC) = CORE::int($n*CORE::log($n)+1);

        my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        my $p = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPFR::Rmpfr_zeta_ui($f, $n, $ROUND);                      # f = zeta(n)
        Math::MPFR::Rmpfr_fac_ui($p, $n, $ROUND);                       # p = n!
        Math::MPFR::Rmpfr_mul($f, $f, $p, $ROUND);                      # f = f * p

        Math::MPFR::Rmpfr_const_pi($p, $ROUND);                         # p = PI
        Math::MPFR::Rmpfr_pow_ui($p, $p, $n, $ROUND);                   # p = p^n

        Math::MPFR::Rmpfr_div_2exp($f, $f, $n - 1, $ROUND);             # f = f / 2^(n-1)

        Math::MPFR::Rmpfr_div($f, $f, $p, $ROUND);                      # f = f/p
        Math::MPFR::Rmpfr_neg($f, $f, $ROUND) if $n % 4 == 0;

        bless \$f;
    }

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

    *harm     = \&harmfrac;
    *harmonic = \&harmfrac;

    sub harmreal {
        my ($n) = @_;

        $n = _copy2mpfr($$n);
        Math::MPFR::Rmpfr_add_ui($n, $n, 1, $ROUND);
        Math::MPFR::Rmpfr_digamma($n, $n, $ROUND);

        my $y = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_euler($y, $ROUND);
        Math::MPFR::Rmpfr_add($n, $n, $y, $ROUND);

        bless \$n;
    }

    sub erf {
        my ($x) = @_;
        $x = _copy2mpfr($$x);
        Math::MPFR::Rmpfr_erf($x, $x, $ROUND);
        bless \$x;
    }

    sub erfc {
        my ($x) = @_;
        $x = _copy2mpfr($$x);
        Math::MPFR::Rmpfr_erfc($x, $x, $ROUND);
        bless \$x;
    }

    sub bessel_j {
        my ($x, $n) = @_;

        $n = defined($n) ? do { _valid(\$n); __numify__($$n) } : 0;

        if ($n < LONG_MIN or $n > ULONG_MAX) {
            return ZERO;
        }

        $x = _copy2mpfr($$x);
        $n = CORE::int($n);

        if ($n == 0) {
            Math::MPFR::Rmpfr_j0($x, $x, $ROUND);
        }
        elsif ($n == 1) {
            Math::MPFR::Rmpfr_j1($x, $x, $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_jn($x, $n, $x, $ROUND);
        }

        bless \$x;
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

        $x = _copy2mpfr($$x);
        $n = CORE::int($n);

        if ($n == 0) {
            Math::MPFR::Rmpfr_y0($x, $x, $ROUND);
        }
        elsif ($n == 1) {
            Math::MPFR::Rmpfr_y1($x, $x, $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_yn($x, $n, $x, $ROUND);
        }

        bless \$x;
    }

    *BesselY = \&bessel_y;

    sub eint {
        my ($x) = @_;
        $x = _copy2mpfr($$x);
        Math::MPFR::Rmpfr_eint($x, $x, $ROUND);
        bless \$x;
    }

    *ei = \&eint;
    *Ei = \&eint;

    sub ai {
        my ($x) = @_;
        $x = _copy2mpfr($$x);
        Math::MPFR::Rmpfr_ai($x, $x, $ROUND);
        bless \$x;
    }

    *airy = \&ai;
    *Ai   = \&ai;

    sub li {
        my ($x) = @_;
        $x = _copy2mpfr($$x);
        Math::MPFR::Rmpfr_log($x, $x, $ROUND);
        Math::MPFR::Rmpfr_eint($x, $x, $ROUND);
        bless \$x;
    }

    *Li = \&li;

    sub li2 {
        my ($x) = @_;
        $x = _copy2mpfr($$x);
        Math::MPFR::Rmpfr_li2($x, $x, $ROUND);
        bless \$x;
    }

    *Li2 = \&li2;

    #
    ## Comparison and testing operations
    #

    sub __eq__ {
        my ($x, $y) = @_;
        my $sig = join(' ', ref($x), ref($y) || '$');

        #
        ## MPFR
        #
        if ($sig eq q(Math::MPFR Math::MPFR)) {
            Math::MPFR::Rmpfr_equal_p($x, $y);
        }

        elsif ($sig eq q(Math::MPFR Math::GMPz)) {
            Math::MPFR::Rmpfr_integer_p($x)
              and Math::MPFR::Rmpfr_cmp_z($x, $y) == 0;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPq)) {
            Math::MPFR::Rmpfr_number_p($x)
              and Math::MPFR::Rmpfr_cmp_q($x, $y) == 0;
        }

        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            (@_) = (_mpfr2mpc($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPFR $)) {
            Math::MPFR::Rmpfr_integer_p($x)
              and (
                   $y < 0
                   ? Math::MPFR::Rmpfr_cmp_si($x, $y)
                   : Math::MPFR::Rmpfr_cmp_ui($x, $y)
                  ) == 0;
        }

        #
        ## GMPq
        #
        elsif ($sig eq q(Math::GMPq Math::GMPq)) {
            Math::GMPq::Rmpq_equal($x, $y);
        }

        elsif ($sig eq q(Math::GMPq Math::GMPz)) {
            Math::GMPq::Rmpq_integer_p($x)
              and Math::GMPq::Rmpq_cmp_z($x, $y) == 0;
        }

        elsif ($sig eq q(Math::GMPq Math::MPFR)) {
            Math::MPFR::Rmpfr_number_p($y)
              and Math::MPFR::Rmpfr_cmp_q($y, $x) == 0;
        }

        elsif ($sig eq q(Math::GMPq Math::MPC)) {
            (@_) = (_mpq2mpc($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPq $)) {
            Math::GMPq::Rmpq_integer_p($x)
              and (
                   $y < 0
                   ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
                   : Math::GMPq::Rmpq_cmp_ui($x, $y, 1)
                  ) == 0;
        }

        #
        ## GMPz
        #
        elsif ($sig eq q(Math::GMPz Math::GMPz)) {
            Math::GMPz::Rmpz_cmp($x, $y) == 0;
        }

        elsif ($sig eq q(Math::GMPz Math::GMPq)) {
            Math::GMPq::Rmpq_integer_p($y)
              and Math::GMPq::Rmpq_cmp_z($y, $x) == 0;
        }

        elsif ($sig eq q(Math::GMPz Math::MPFR)) {
            Math::MPFR::Rmpfr_integer_p($y)
              and Math::MPFR::Rmpfr_cmp_z($y, $x) == 0;
        }

        elsif ($sig eq q(Math::GMPz Math::MPC)) {
            (@_) = (_mpz2mpc($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPz $)) {
            (
             $y < 0
             ? Math::GMPz::Rmpz_cmp_si($x, $y)
             : Math::GMPz::Rmpz_cmp_ui($x, $y)
            ) == 0;
        }

        #
        ## MPC
        #
        elsif ($sig eq q(Math::MPC Math::MPC)) {

            my $f1 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $f2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($f1, $x);
            Math::MPC::RMPC_RE($f2, $y);

            Math::MPFR::Rmpfr_equal_p($f1, $f2) || return 0;

            Math::MPC::RMPC_IM($f1, $x);
            Math::MPC::RMPC_IM($f2, $y);

            Math::MPFR::Rmpfr_equal_p($f1, $f2);
        }

        elsif ($sig eq q(Math::MPC Math::GMPz)) {
            (@_) = ($x, _mpz2mpc($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC Math::GMPq)) {
            (@_) = ($x, _mpq2mpc($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            (@_) = ($x, _mpfr2mpc($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC $)) {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_IM($f, $x);
            Math::MPFR::Rmpfr_zero_p($f) || return 0;
            Math::MPC::RMPC_RE($f, $x);
            (@_) = ($f, $y);
            goto __SUB__;
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

        my $sig = join(' ', ref($x), ref($y) || '$');

        #
        ## MPFR
        #
        if ($sig eq q(Math::MPFR Math::MPFR)) {
            !Math::MPFR::Rmpfr_equal_p($x, $y);
        }

        elsif ($sig eq q(Math::MPFR Math::GMPz)) {
            !Math::MPFR::Rmpfr_integer_p($x)
              or Math::MPFR::Rmpfr_cmp_z($x, $y) != 0;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPq)) {
            !Math::MPFR::Rmpfr_number_p($x)
              or Math::MPFR::Rmpfr_cmp_q($x, $y) != 0;
        }

        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            (@_) = (_mpfr2mpc($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPFR $)) {
            !Math::MPFR::Rmpfr_integer_p($x)
              or (
                  $y < 0
                  ? Math::MPFR::Rmpfr_cmp_si($x, $y)
                  : Math::MPFR::Rmpfr_cmp_ui($x, $y)
                 ) != 0;
        }

        #
        ## GMPq
        #
        elsif ($sig eq q(Math::GMPq Math::GMPq)) {
            !Math::GMPq::Rmpq_equal($x, $y);
        }

        elsif ($sig eq q(Math::GMPq Math::GMPz)) {
            !Math::GMPq::Rmpq_integer_p($x)
              or Math::GMPq::Rmpq_cmp_z($x, $y) != 0;
        }

        elsif ($sig eq q(Math::GMPq Math::MPFR)) {
            !Math::MPFR::Rmpfr_number_p($y)
              or Math::MPFR::Rmpfr_cmp_q($y, $x) != 0;
        }

        elsif ($sig eq q(Math::GMPq Math::MPC)) {
            (@_) = (_mpq2mpc($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPq $)) {
            !Math::GMPq::Rmpq_integer_p($x)
              or (
                  $y < 0
                  ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
                  : Math::GMPq::Rmpq_cmp_ui($x, $y, 1)
                 ) != 0;
        }

        #
        ## GMPz
        #
        elsif ($sig eq q(Math::GMPz Math::GMPz)) {
            Math::GMPz::Rmpz_cmp($x, $y) != 0;
        }

        elsif ($sig eq q(Math::GMPz Math::GMPq)) {
            !Math::GMPq::Rmpq_integer_p($y)
              or Math::GMPq::Rmpq_cmp_z($y, $x) != 0;
        }

        elsif ($sig eq q(Math::GMPz Math::MPFR)) {
            !Math::MPFR::Rmpfr_integer_p($y)
              or Math::MPFR::Rmpfr_cmp_z($y, $x) != 0;
        }

        elsif ($sig eq q(Math::GMPz Math::MPC)) {
            (@_) = (_mpz2mpc($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPz $)) {
            (
             $y < 0
             ? Math::GMPz::Rmpz_cmp_si($x, $y)
             : Math::GMPz::Rmpz_cmp_ui($x, $y)
            ) != 0;
        }

        #
        ## MPC
        #
        elsif ($sig eq q(Math::MPC Math::MPC)) {

            my $f1 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $f2 = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($f1, $x);
            Math::MPC::RMPC_RE($f2, $y);

            Math::MPFR::Rmpfr_equal_p($f1, $f2) || return 1;

            Math::MPC::RMPC_IM($f1, $x);
            Math::MPC::RMPC_IM($f2, $y);

            !Math::MPFR::Rmpfr_equal_p($f1, $f2);
        }

        elsif ($sig eq q(Math::MPC Math::GMPz)) {
            (@_) = ($x, _mpz2mpc($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC Math::GMPq)) {
            (@_) = ($x, _mpq2mpc($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            (@_) = ($x, _mpfr2mpc($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC $)) {
            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::RMPC_IM($f, $x);
            Math::MPFR::Rmpfr_zero_p($f) || return 1;
            Math::MPC::RMPC_RE($f, $x);
            (@_) = ($f, $y);
            goto __SUB__;
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

    sub __cmp__ {
        my ($x, $y) = @_;
        my $sig = join(' ', ref($x), ref($y) || '$');

        #
        ## MPFR
        #
        if ($sig eq q(Math::MPFR Math::MPFR)) {

            if (   Math::MPFR::Rmpfr_nan_p($x)
                or Math::MPFR::Rmpfr_nan_p($y)) {
                return undef;
            }

            Math::MPFR::Rmpfr_cmp($x, $y);
        }

        elsif ($sig eq q(Math::MPFR Math::GMPz)) {
            Math::MPFR::Rmpfr_nan_p($x) && return undef;
            Math::MPFR::Rmpfr_cmp_z($x, $y);
        }

        elsif ($sig eq q(Math::MPFR Math::GMPq)) {
            Math::MPFR::Rmpfr_nan_p($x) && return undef;
            Math::MPFR::Rmpfr_cmp_q($x, $y);
        }

        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            (@_) = (_mpfr2mpc($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPFR $)) {
            Math::MPFR::Rmpfr_nan_p($x) && return undef;
            $y < 0
              ? Math::MPFR::Rmpfr_cmp_si($x, $y)
              : Math::MPFR::Rmpfr_cmp_ui($x, $y);
        }

        #
        ## GMPq
        #
        elsif ($sig eq q(Math::GMPq Math::GMPq)) {
            Math::GMPq::Rmpq_cmp($x, $y);
        }

        elsif ($sig eq q(Math::GMPq Math::GMPz)) {
            Math::GMPq::Rmpq_cmp_z($x, $y);
        }

        elsif ($sig eq q(Math::GMPq Math::MPFR)) {
            Math::MPFR::Rmpfr_nan_p($y) && return undef;
            -(Math::MPFR::Rmpfr_cmp_q($y, $x));
        }

        elsif ($sig eq q(Math::GMPq Math::MPC)) {
            (@_) = (_mpq2mpc($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPq $)) {
            $y < 0
              ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
              : Math::GMPq::Rmpq_cmp_ui($x, $y, 1);
        }

        #
        ## GMPz
        #
        elsif ($sig eq q(Math::GMPz Math::GMPz)) {
            Math::GMPz::Rmpz_cmp($x, $y);
        }

        elsif ($sig eq q(Math::GMPz Math::GMPq)) {
            -(Math::GMPq::Rmpq_cmp_z($y, $x));
        }

        elsif ($sig eq q(Math::GMPz Math::MPFR)) {
            Math::MPFR::Rmpfr_nan_p($y) && return undef;
            -(Math::MPFR::Rmpfr_cmp_z($y, $x));
        }

        elsif ($sig eq q(Math::GMPz Math::MPC)) {
            (@_) = (_mpz2mpc($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPz $)) {
            $y < 0
              ? Math::GMPz::Rmpz_cmp_si($x, $y)
              : Math::GMPz::Rmpz_cmp_ui($x, $y);
        }

        #
        ## MPC
        #
        elsif ($sig eq q(Math::MPC Math::MPC)) {

            my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($f, $x);
            Math::MPFR::Rmpfr_nan_p($f) && return undef;

            Math::MPC::RMPC_RE($f, $y);
            Math::MPFR::Rmpfr_nan_p($f) && return undef;

            Math::MPC::RMPC_IM($f, $x);
            Math::MPFR::Rmpfr_nan_p($f) && return undef;

            Math::MPC::RMPC_IM($f, $y);
            Math::MPFR::Rmpfr_nan_p($f) && return undef;

            my $si = Math::MPC::Rmpc_cmp($x, $y);
            my $re_cmp = Math::MPC::RMPC_INEX_RE($si);
            $re_cmp == 0 or return $re_cmp;
            Math::MPC::RMPC_INEX_IM($si);
        }

        elsif ($sig eq q(Math::MPC Math::GMPz)) {
            (@_) = ($x, _mpz2mpc($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC Math::GMPq)) {
            (@_) = ($x, _mpq2mpc($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            (@_) = ($x, _mpfr2mpc($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC $)) {
            (@_) = ($x, _any2mpc(_str2obj($y)));
            goto __SUB__;
        }
    }

    sub cmp {
        my ($x, $y) = @_;
        _valid(\$y);
        my $cmp = __cmp__($$x, $$y) // return undef;
        !$cmp ? ZERO : ($cmp > 0) ? ONE : MONE;
    }

    # TODO: add the acmp() method.

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
        __eq__($$x, 1)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_mone {
        my ($x) = @_;
        __eq__($$x, -1)
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
        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            goto &Math::MPFR::Rmpfr_sgn;
        }
        elsif ($sig eq q(Math::GMPq)) {
            goto &Math::GMPq::Rmpq_sgn;
        }
        elsif ($sig eq q(Math::GMPz)) {
            goto &Math::GMPz::Rmpz_sgn;
        }
        elsif ($sig eq q(Math::MPC)) {
            my $abs = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPC::Rmpc_abs($abs, $x, $ROUND);

            if (Math::MPFR::Rmpfr_zero_p($abs)) {    # it's zero
                return 0;
            }

            my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_div_fr($r, $x, $abs, $ROUND);
            $r;
        }
    }

    sub sign {
        my ($x) = @_;
        my $r = __sgn__($$x);
        if (ref($r)) {
            bless \$r;
        }
        else {
            !$r ? ZERO : ($r > 0) ? ONE : MONE;
        }
    }

    *sgn = \&sign;

    sub popcount {
        my ($x) = @_;
        my $z = _any2mpz($$x) // return MONE;

        if (Math::GMPz::Rmpz_sgn($z) < 0) {
            my $t = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_neg($t, $z);
            $z = $t;
        }

        __PACKAGE__->_set_uint(Math::GMPz::Rmpz_popcount($z));
    }

    sub __is_int__ {
        my ($x) = @_;

        my $ref = ref($x);

        $ref eq 'Math::GMPz' && return 1;
        $ref eq 'Math::GMPq' && return Math::GMPq::Rmpq_integer_p($x);
        $ref eq 'Math::MPFR' && return Math::MPFR::Rmpfr_integer_p($x);

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

        my $ref = ref($x);

        $ref eq 'Math::GMPz' && return 1;
        $ref eq 'Math::GMPq' && return 1;
        $ref eq 'Math::MPFR' && return Math::MPFR::Rmpfr_number_p($x);

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

        my $f = Math::MPFR::Rmpfr_init2($PREC);
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

        my $f = Math::MPFR::Rmpfr_init2($PREC);
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

    sub is_div {
        my ($x, $y) = @_;
        _valid(\$y);
        __eq__(__mod__(_copy($$x), $$y), 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub divides {
        my ($x, $y) = @_;
        _valid(\$y);
        __eq__(__mod__(_copy($$y), $$x), 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub __is_inf__ {
        my ($r) = @_;
        my $ref = ref($r);

        $ref eq 'Math::GMPz' && return 0;
        $ref eq 'Math::GMPq' && return 0;
        $ref eq 'Math::MPFR' && return (Math::MPFR::Rmpfr_inf_p($r) and Math::MPFR::Rmpfr_sgn($r) > 0);

        (@_) = _any2mpfr($r);
        goto __SUB__;
    }

    sub is_inf {
        my ($x) = @_;
        __is_inf__($$x)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub __is_ninf__ {
        my ($r) = @_;
        my $ref = ref($r);

        $ref eq 'Math::GMPz' && return 0;
        $ref eq 'Math::GMPq' && return 0;
        $ref eq 'Math::MPFR' && return (Math::MPFR::Rmpfr_inf_p($r) and Math::MPFR::Rmpfr_sgn($r) < 0);

        (@_) = _any2mpfr($r);
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

        my $r   = $$x;
        my $ref = ref($r);

        $ref eq 'Math::GMPz' && return Sidef::Types::Bool::Bool::FALSE;
        $ref eq 'Math::GMPq' && return Sidef::Types::Bool::Bool::FALSE;
        $ref eq 'Math::MPFR'
          && return (
                     Math::MPFR::Rmpfr_nan_p($r)
                     ? Sidef::Types::Bool::Bool::TRUE
                     : Sidef::Types::Bool::Bool::FALSE
                    );

        my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

        Math::MPC::RMPC_RE($real, $r);
        Math::MPC::RMPC_IM($imag, $r);

        if (   Math::MPFR::Rmpfr_nan_p($real)
            or Math::MPFR::Rmpfr_nan_p($imag)) {
            return Sidef::Types::Bool::Bool::TRUE;
        }

        return Sidef::Types::Bool::Bool::FALSE;
    }

    sub max {
        my ($x, $y) = @_;
        _valid(\$y);
        (__cmp__($$x, $$y) // return undef) > 0 ? $x : $y;
    }

    sub min {
        my ($x, $y) = @_;
        _valid(\$y);
        (__cmp__($$x, $$y) // return undef) < 0 ? $x : $y;
    }

    sub as_int {
        my ($x, $y) = @_;

        my $base = 10;
        if (defined($y)) {
            _valid(\$y);
            $base = _any2ui($$y) // 0;
            if ($base < 2 or $base > 36) {
                die "[ERROR] Number.as_int(): base must be between 2 and 36, got $y";
            }
        }

        Sidef::Types::String::String->new(Math::GMPz::Rmpz_get_str((_any2mpz($$x) // return undef), $base));
    }

    sub __base__ {
        my ($x, $base) = @_;
        my $sig = ref($x);

        if ($sig eq 'Math::GMPz') {
            Math::GMPz::Rmpz_get_str($x, $base);
        }
        elsif ($sig eq 'Math::GMPq') {
            Math::GMPq::Rmpq_get_str($x, $base);
        }
        elsif ($sig eq 'Math::MPFR') {
            Math::MPFR::Rmpfr_get_str($x, $base, CORE::int($PREC) >> 2, $ROUND);
        }
        elsif ($sig eq 'Math::MPC') {
            my $fr = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPC::RMPC_RE($fr, $x);
            my $real = __base__($fr, $base);
            Math::MPC::RMPC_IM($fr, $x);
            my $imag = __base__($fr, $base);
            "($real $imag)";
        }
    }

    sub base {
        my ($x, $y) = @_;

        my $base = 10;
        if (defined($y)) {
            _valid(\$y);
            $base = _any2ui($$y) // 0;
            if ($base < 2 or $base > 36) {
                die "[ERROR] Number.base(): base must be between 2 and 36, got $y";
            }
        }

        Sidef::Types::String::String->new(__base__($$x, $base));
    }

    *in_base = \&base;

    sub as_rat {
        my ($x, $y) = @_;

        my $base = 10;
        if (defined($y)) {
            _valid(\$y);
            $base = _any2ui($$y) // 0;
            if ($base < 2 or $base > 36) {
                die "[ERROR] base must be between 2 and 36, got $y";
            }
        }

        Sidef::Types::String::String->new(Math::GMPq::Rmpq_get_str((_any2mpq($$x) // return undef), $base));
    }

    sub as_frac {
        my ($x, $y) = @_;

        my $base = 10;
        if (defined($y)) {
            _valid(\$y);
            $base = _any2ui($$y) // 0;
            if ($base < 2 or $base > 36) {
                die "as_frac(): base must be between 2 and 36, got $y";
            }
        }

        my $str = Math::GMPq::Rmpq_get_str((_any2mpq($$x) // return undef), $base);
        if (index($str, '/') == -1) { $str .= '/1' }
        Sidef::Types::String::String->new($str);
    }

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

    sub dump {
        Sidef::Types::String::String->new(__stringify__(${$_[0]}));
    }

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

    sub digits {
        my ($x, $y) = @_;

        my $str = as_int($x, $y) // return undef;
        my @digits = split(//, "$str");
        shift(@digits) if $digits[0] eq '-';

        Sidef::Types::Array::Array->new(map { __PACKAGE__->_set_uint($_) } @digits);
    }

    sub digit {
        my ($x, $y, $z) = @_;

        _valid(\$y);

        my $str = as_int($x, $z) // return undef;
        my @digits = split(//, "$str");
        shift(@digits) if $digits[0] eq '-';

        $y = _any2si($$y) // return undef;
        exists($digits[$y]) ? __PACKAGE__->_set_uint($digits[$y]) : undef;
    }

    sub length {
        my ($x) = @_;
        my ($z) = _any2mpz($$x) // return MONE;
        my $neg = (Math::GMPz::Rmpz_sgn($z) < 0) ? 1 : 0;
        __PACKAGE__->_set_uint(CORE::length(Math::GMPz::Rmpz_get_str($z, 10)) - $neg);
    }

    *len  = \&length;
    *size = \&length;

    sub __floor__ {
        my ($x) = @_;

        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_floor($x, $x);
            $x;
        }

        elsif ($sig eq q(Math::GMPq)) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_integer_p($x) && return $x;
            Math::GMPz::Rmpz_set_q($z, $x);
            Math::GMPz::Rmpz_sub_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($x) < 0;
            $z;
        }

        elsif ($sig eq q(Math::MPC)) {

            my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($real, $x);
            Math::MPC::RMPC_IM($imag, $x);

            Math::MPFR::Rmpfr_floor($real, $real);
            Math::MPFR::Rmpfr_floor($imag, $imag);

            if (Math::MPFR::Rmpfr_zero_p($imag)) {
                return $real;
            }

            Math::MPC::Rmpc_set_fr_fr($x, $real, $imag, $ROUND);
            $x;
        }
    }

    sub floor {
        my ($x) = @_;
        my $r = $$x;
        ref($r) eq 'Math::GMPz' and return $x;    # already an integer
        bless \__floor__(ref($r) eq 'Math::GMPq' ? $r : _copy($r));
    }

    sub __ceil__ {
        my ($x) = @_;

        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_ceil($x, $x);
            $x;
        }

        elsif ($sig eq q(Math::GMPq)) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_integer_p($x) && return $x;
            Math::GMPz::Rmpz_set_q($z, $x);
            Math::GMPz::Rmpz_add_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($x) > 0;
            $z;
        }

        elsif ($sig eq q(Math::MPC)) {

            my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($real, $x);
            Math::MPC::RMPC_IM($imag, $x);

            Math::MPFR::Rmpfr_ceil($real, $real);
            Math::MPFR::Rmpfr_ceil($imag, $imag);

            if (Math::MPFR::Rmpfr_zero_p($imag)) {
                return $real;
            }

            Math::MPC::Rmpc_set_fr_fr($x, $real, $imag, $ROUND);
            $x;
        }
    }

    sub ceil {
        my ($x) = @_;
        my $r = $$x;
        ref($r) eq 'Math::GMPz' and return $x;    # already an integer
        bless \__ceil__(ref($r) eq 'Math::GMPq' ? $r : _copy($r));
    }

    sub __inc__ {
        my ($x) = @_;

        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_add_ui($x, $x, 1, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::GMPq)) {
            state $one = Math::GMPz::Rmpz_init_set_ui_nobless(1);
            Math::GMPq::Rmpq_add_z($x, $x, $one);
            $x;
        }

        elsif ($sig eq q(Math::GMPz)) {
            Math::GMPz::Rmpz_add_ui($x, $x, 1);
            $x;
        }

        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_add_ui($x, $x, 1, $ROUND);
            $x;
        }
    }

    sub inc {
        my ($x) = @_;
        bless \__inc__(_copy($$x));
    }

    sub __dec__ {
        my ($x) = @_;

        my $sig = ref($x);

        if ($sig eq q(Math::MPFR)) {
            Math::MPFR::Rmpfr_sub_ui($x, $x, 1, $ROUND);
            $x;
        }

        elsif ($sig eq q(Math::GMPq)) {
            state $one = Math::GMPz::Rmpz_init_set_ui_nobless(1);
            Math::GMPq::Rmpq_sub_z($x, $x, $one);
            $x;
        }

        elsif ($sig eq q(Math::GMPz)) {
            Math::GMPz::Rmpz_sub_ui($x, $x, 1);
            $x;
        }

        elsif ($sig eq q(Math::MPC)) {
            Math::MPC::Rmpc_sub_ui($x, $x, 1, $ROUND);
            $x;
        }
    }

    sub dec {
        my ($x) = @_;
        bless \__dec__(_copy($$x));
    }

    sub __mod__ {
        my ($x, $y) = @_;

        my $sig = join(' ', ref($x), ref($y) || '$');

        #
        ## GMPq
        #
        if ($sig eq q(Math::GMPq Math::GMPq)) {
            my ($x, $y) = @_;

            Math::GMPq::Rmpq_sgn($y)
              || goto &_nan;

            my $quo = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set($quo, $x);
            Math::GMPq::Rmpq_div($quo, $quo, $y);

            # Floor
            if (!Math::GMPq::Rmpq_integer_p($quo)) {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_set_q($z, $quo);
                Math::GMPz::Rmpz_sub_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($quo) < 0;
                Math::GMPq::Rmpq_set_z($quo, $z);
            }

            Math::GMPq::Rmpq_mul($quo, $quo, $y);
            Math::GMPq::Rmpq_sub($x, $x, $quo);

            $x;
        }

        elsif ($sig eq q(Math::GMPq Math::GMPz)) {
            (@_) = ($x, _mpz2mpq($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPq Math::MPFR)) {
            (@_) = (_mpq2mpfr($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPq Math::MPC)) {
            (@_) = (_mpq2mpc($x), $y);
            goto __SUB__;
        }

        #
        ## GMPz
        #
        elsif ($sig eq q(Math::GMPz Math::GMPz)) {

            my $sgn_y = Math::GMPz::Rmpz_sgn($y)
              || goto &_nan;

            Math::GMPz::Rmpz_mod($x, $x, $y);

            if (!Math::GMPz::Rmpz_sgn($x)) {
                ## ok
            }
            elsif ($sgn_y < 0) {
                Math::GMPz::Rmpz_add($x, $x, $y);
            }

            $x;
        }

        elsif ($sig eq q(Math::GMPz $)) {
            Math::GMPz::Rmpz_mod_ui($x, $x, $y);
            $x;
        }

        elsif ($sig eq q(Math::GMPz Math::GMPq)) {
            (@_) = (_mpz2mpq($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPz Math::MPFR)) {
            (@_) = (_mpz2mpfr($x), $y);
            goto __SUB__;
        }

        elsif ($sig eq q(Math::GMPz Math::MPC)) {
            (@_) = (_mpz2mpc($x), $y);
            goto __SUB__;
        }

        #
        ## MPFR
        #
        elsif ($sig eq q(Math::MPFR Math::MPFR)) {

            my $quo = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set($quo, $x, $ROUND);
            Math::MPFR::Rmpfr_div($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_floor($quo, $quo);
            Math::MPFR::Rmpfr_mul($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_sub($x, $x, $quo, $ROUND);

            $x;
        }

        elsif ($sig eq q(Math::MPFR $)) {

            my $quo = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set($quo, $x, $ROUND);
            Math::MPFR::Rmpfr_div_ui($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_floor($quo, $quo);
            Math::MPFR::Rmpfr_mul_ui($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_sub($x, $x, $quo, $ROUND);

            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPq)) {

            my $quo = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set($quo, $x, $ROUND);
            Math::MPFR::Rmpfr_div_q($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_floor($quo, $quo);
            Math::MPFR::Rmpfr_mul_q($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_sub($x, $x, $quo, $ROUND);

            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::GMPz)) {

            my $quo = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set($quo, $x, $ROUND);
            Math::MPFR::Rmpfr_div_z($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_floor($quo, $quo);
            Math::MPFR::Rmpfr_mul_z($quo, $quo, $y, $ROUND);
            Math::MPFR::Rmpfr_sub($x, $x, $quo, $ROUND);

            $x;
        }

        elsif ($sig eq q(Math::MPFR Math::MPC)) {
            (@_) = (_mpfr2mpc($x), $y);
            goto __SUB__;
        }

        #
        ## MPC
        #
        elsif ($sig eq q(Math::MPC Math::MPC)) {

            my $quo = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set($quo, $x, $ROUND);
            Math::MPC::Rmpc_div($quo, $quo, $y, $ROUND);

            my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($real, $quo);
            Math::MPC::RMPC_IM($imag, $quo);

            Math::MPFR::Rmpfr_floor($real, $real);
            Math::MPFR::Rmpfr_floor($imag, $imag);

            Math::MPC::Rmpc_set_fr_fr($quo, $real, $imag, $ROUND);

            Math::MPC::Rmpc_mul($quo, $quo, $y, $ROUND);
            Math::MPC::Rmpc_sub($x, $x, $quo, $ROUND);

            $x;
        }

        elsif ($sig eq q(Math::MPC $)) {

            my $quo = Math::MPC::Rmpc_init2(CORE::int($PREC));
            Math::MPC::Rmpc_set($quo, $x, $ROUND);
            Math::MPC::Rmpc_div_ui($quo, $quo, $y, $ROUND);

            my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($real, $quo);
            Math::MPC::RMPC_IM($imag, $quo);

            Math::MPFR::Rmpfr_floor($real, $real);
            Math::MPFR::Rmpfr_floor($imag, $imag);

            Math::MPC::Rmpc_set_fr_fr($quo, $real, $imag, $ROUND);

            Math::MPC::Rmpc_mul_ui($quo, $quo, $y, $ROUND);
            Math::MPC::Rmpc_sub($x, $x, $quo, $ROUND);

            $x;
        }

        elsif ($sig eq q(Math::MPC Math::MPFR)) {
            (@_) = ($x, _mpfr2mpc($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC Math::GMPz)) {
            (@_) = ($x, _mpz2mpc($y));
            goto __SUB__;
        }

        elsif ($sig eq q(Math::MPC Math::GMPq)) {
            (@_) = ($x, _mpq2mpc($y));
            goto __SUB__;
        }
    }

    sub mod {
        my ($x, $y) = @_;
        _valid(\$y);
        bless \__mod__(_copy($$x), $$y);
    }

    sub imod {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _copy2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y)  // (goto &nan);

        my $sign_y = Math::GMPz::Rmpz_sgn($y)
          || goto nan;

        Math::GMPz::Rmpz_mod($x, $x, $y);

        if (!Math::GMPz::Rmpz_sgn($x)) {
            ## OK
        }
        elsif ($sign_y < 0) {
            Math::GMPz::Rmpz_add($x, $x, $y);
        }

        bless \$x;
    }

    sub modpow {
        my ($x, $y, $z) = @_;

        _valid(\$y, \$z);

        $x = _copy2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y)  // (goto &nan);
        $z = _any2mpz($$z)  // (goto &nan);

        Math::GMPz::Rmpz_sgn($z) || goto &nan;

        if (Math::GMPz::Rmpz_sgn($y) < 0) {
            my $t = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_gcd($t, $x, $z);
            Math::GMPz::Rmpz_cmp_ui($t, 1) == 0 or goto &nan;
        }

        Math::GMPz::Rmpz_powm($x, $x, $y, $z);
        bless \$x;
    }

    *expmod = \&modpow;
    *powmod = \&modpow;

    sub modinv {
        my ($x, $y) = @_;
        _valid(\$y);
        $x = _copy2mpz($$x) // (goto &nan);
        $y = _any2mpz($$y)  // (goto &nan);
        Math::GMPz::Rmpz_invert($x, $x, $y) || (goto &nan);
        bless \$x;
    }

    *invmod = \&modinv;

    sub divmod {
        my ($x, $y) = @_;

        _valid(\$y);

        $x = _copy2mpz($$x) // return (nan(), nan());
        $y = _copy2mpz($$y) // return (nan(), nan());

        Math::GMPz::Rmpz_sgn($y)
          || return (nan(), nan());

        Math::GMPz::Rmpz_divmod($x, $y, $x, $y);
        ((bless \$x), (bless \$y));
    }

    sub and {
        my ($x, $y) = @_;

        _valid(\$y);

        my $z = _copy2mpz($$x) // (goto &nan);
        my $n = _any2mpz($$y)  // (goto &nan);

        Math::GMPz::Rmpz_and($z, $z, $n);

        bless \$z;
    }

    sub or {
        my ($x, $y) = @_;

        _valid(\$y);

        my $z = _copy2mpz($$x) // (goto &nan);
        my $n = _any2mpz($$y)  // (goto &nan);

        Math::GMPz::Rmpz_ior($z, $z, $n);

        bless \$z;
    }

    sub xor {
        my ($x, $y) = @_;

        _valid(\$y);

        my $z = _copy2mpz($$x) // (goto &nan);
        my $n = _any2mpz($$y)  // (goto &nan);

        Math::GMPz::Rmpz_xor($z, $z, $n);

        bless \$z;
    }

    sub not {
        my ($x) = @_;
        my $z = _copy2mpz($$x) // (goto &nan);
        Math::GMPz::Rmpz_com($z, $z);
        bless \$z;
    }

    sub ramanujan_tau {
        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::ramanujan_tau(&_big2uistr // (goto &nan)));
    }

    sub factorial {
        my ($x) = @_;
        my $ui = _any2ui($$x) // (goto &nan);
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fac_ui($z, $ui);
        bless \$z;
    }

    *fac = \&factorial;

    sub double_factorial {
        my ($x) = @_;
        my $ui = _any2ui($$x) // (goto &nan);
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_2fac_ui($z, $ui);
        bless \$z;
    }

    *dfac       = \&double_factorial;
    *dfactorial = \&double_factorial;

    sub mfactorial {
        my ($x, $y) = @_;
        _valid(\$y);
        my $ui1 = _any2ui($$x) // (goto &nan);
        my $ui2 = _any2ui($$y) // (goto &nan);
        my $z   = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mfac_uiui($z, $ui1, $ui2);
        bless \$z;
    }

    *mfac = \&mfactorial;

    sub primorial {
        my ($x) = @_;
        my $ui = _any2ui($$x) // (goto &nan);
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_primorial_ui($z, $ui);
        bless \$z;
    }

    sub pn_primorial {
        my ($x) = @_;
        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::pn_primorial(_any2ui($$x) // (goto &nan)));
    }

    sub lucas {
        my ($x) = @_;
        my $ui = _any2ui($$x) // (goto &nan);
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_lucnum_ui($z, $ui);
        bless \$z;
    }

    sub fibonacci {
        my ($x) = @_;
        my $ui = _any2ui($$x) // (goto &nan);
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fib_ui($z, $ui);
        bless \$z;
    }

    *fib = \&fibonacci;

    sub stirling {
        my ($x, $y) = @_;
        _valid(\$y);
        __PACKAGE__->_set_str('int',
                              Math::Prime::Util::GMP::stirling(_big2uistr($x) // (goto &nan), _big2uistr($y) // (goto &nan)));
    }

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

    sub bell {
        my ($x) = @_;
        my $n = _any2ui($$x) // goto &nan;
        __PACKAGE__->_set_str('int',
                              Math::Prime::Util::GMP::vecsum(map { Math::Prime::Util::GMP::stirling($n, $_, 2) } 0 .. $n));
    }

    sub binomial {
        my ($x, $y) = @_;
        _valid(\$y);

        my $n = _any2si($$y)  // (goto &nan);
        my $z = _any2mpz($$x) // (goto &nan);

        my $r = Math::GMPz::Rmpz_init();

        $n < 0
          ? Math::GMPz::Rmpz_bin_si($r, $z, $n)
          : Math::GMPz::Rmpz_bin_ui($r, $z, $n);

        bless \$r;
    }

    *nok = \&binomial;

    sub moebius {
        my $mob = Math::Prime::Util::GMP::moebius(&_big2istr // goto &nan);
        if (!$mob) {
            ZERO;
        }
        elsif ($mob == 1) {
            ONE;
        }
        else {
            MONE;
        }
    }

    *mobius = \&moebius;

    # Currently, this method is very slow for wide ranges.
    # It's included with the hope that it will become faster in the future.
    sub prime_count {
        my ($x, $y) = @_;
        my $n = defined($y)
          ? do {
            _valid(\$y);
            Math::Prime::Util::GMP::prime_count(_big2istr($x) // (goto &nan), _big2istr($y) // (goto &nan));
          }
          : Math::Prime::Util::GMP::prime_count(2, _big2istr($x) // (goto &nan));
        $n <= ULONG_MAX ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
    }

    sub square_free_count {
        my ($from, $to) = @_;

        if (defined($to)) {
            _valid(\$to);
            return $to->square_free_count->sub($from->dec->square_free_count);
        }

        (my $n = __numify__($$from)) <= 0 && return ZERO;

        # Optimization for native integers
        if ($n <= ULONG_MAX) {

            $n = CORE::int($n);
            my $s = CORE::int(CORE::sqrt($n));

            # Using moebius(1, sqrt(n)) for values of n <= 2^40
            if ($n <= (1 << 40)) {

                my ($count, $k) = (0, 0);

                foreach my $m (Math::Prime::Util::GMP::moebius(1, $s)) {
                    ++$k;
                    if ($m) {
                        $count += $m * CORE::int($n / ($k * $k));
                    }
                }

                return __PACKAGE__->_set_uint($count);
            }

            # Linear counting up to sqrt(n)
            my ($count, $m) = 0;
            foreach my $k (1 .. $s) {
                if ($m = Math::Prime::Util::GMP::moebius($k)) {
                    $count += $m * CORE::int($n / ($k * $k));
                }
            }
            return __PACKAGE__->_set_uint($count);
        }

        # Implementation for large values of n
        my $c = Math::GMPz::Rmpz_init_set_ui(0);
        my $t = Math::GMPz::Rmpz_init();
        my $z = _any2mpz($$from) // return ZERO;

        my $s = Math::GMPz::Rmpz_init_set($z);
        Math::GMPz::Rmpz_sqrt($s, $s);

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

    sub _Li_inverse {
        my ($x) = @_;

        # Function translated from:
        #   https://github.com/kimwalisch/primecount

        my $logx  = CORE::log($x);
        my $first = CORE::int($x * $logx);
        my $last  = CORE::int($x * $logx * 2 + 2);

        my $mpfr = Math::MPFR::Rmpfr_init2(64);

        # Find Li^-1(x) using binary search
        while ($first < $last) {
            my $mid = $first + (($last - $first) >> 1);

            Math::MPFR::Rmpfr_set_d($mpfr, CORE::log($mid), $ROUND);
            Math::MPFR::Rmpfr_eint($mpfr, $mpfr, $ROUND);

            if (Math::MPFR::Rmpfr_get_d($mpfr, $ROUND) - 1.045163780117 < $x) {
                $first = $mid + 1;
            }
            else {
                $last = $mid;
            }
        }

        return $first;
    }

    sub nth_prime {
        my ($n) = @_;

        $n = _any2ui($$n) // goto &nan;

        if ($n == 0) {
            return ONE;    # not a prime, but it's convenient...
        }

        if ($n > 100_000) {

            my $i          = 2;
            my $count      = 0;
            my $prev_count = 0;

            #my $approx    = CORE::int($n * CORE::log($n) + $n * (CORE::log(CORE::log($n)) - 1));
            #my $up_approx = CORE::int($n * CORE::log($n) + $n * CORE::log(CORE::log($n)));

            my $li_inv_n  = _Li_inverse($n);
            my $li_inv_sn = _Li_inverse(CORE::int(CORE::sqrt($n)));

            ## Formula due to Dana Jacobsen:
            ## Nth prime ≈ Li^-1(n) + Li^-1(sqrt(n)) / 4
            my $approx    = CORE::int($li_inv_n + $li_inv_sn / 4);
            my $up_approx = CORE::int($li_inv_n + $li_inv_sn);       # conjecture

            state $checkpoints = [[1000000000000, 37607912018],
                                  [100000000000,  4118054813],
                                  [50000000000,   2119654578],
                                  [45000000000,   1916268743],
                                  [40000000000,   1711955433],
                                  [35000000000,   1506589876],
                                  [30000000000,   1300005926],
                                  [25000000000,   1091987405],
                                  [22000000000,   966358351],
                                  [21000000000,   924324489],
                                  [20000000000,   882206716],
                                  [19000000000,   840000027],
                                  [18000000000,   797703398],
                                  [17000000000,   755305935],
                                  [16000000000,   712799821],
                                  [15000000000,   670180516],
                                  [14000000000,   627440336],
                                  [13000000000,   584570200],
                                  [12000000000,   541555851],
                                  [11000000000,   498388617],
                                  [10000000000,   455052511],
                                  [9900000000,    450708777],
                                  [9700000000,    442014876],
                                  [9500000000,    433311792],
                                  [9300000000,    424603409],
                                  [9000000000,    411523195],
                                  [8700000000,    398425675],
                                  [8500000000,    389682427],
                                  [8300000000,    380930729],
                                  [8000000000,    367783654],
                                  [7500000000,    345826612],
                                  [7300000000,    337024801],
                                  [7000000000,    323804352],
                                  [6700000000,    310558733],
                                  [6500000000,    301711468],
                                  [6400000000,    297285198],
                                  [6300000000,    292856421],
                                  [6000000000,    279545368],
                                  [5700000000,    266206294],
                                  [5500000000,    257294520],
                                  [5300000000,    248370960],
                                  [5200000000,    243902342],
                                  [5000000000,    234954223],
                                  [4900000000,    230475545],
                                  [4700000000,    221504167],
                                  [4500000000,    212514323],
                                  [4300000000,    203507248],
                                  [4200000000,    198996103],
                                  [4000000000,    189961812],
                                  [3900000000,    185436625],
                                  [3800000000,    180906194],
                                  [3700000000,    176369517],
                                  [3500000000,    167279333],
                                  [3400000000,    162725196],
                                  [3300000000,    158165829],
                                  [3100000000,    149028641],
                                  [3000000000,    144449537],
                                  [2900000000,    139864011],
                                  [2800000000,    135270258],
                                  [2700000000,    130670192],
                                  [2600000000,    126062167],
                                  [2500000000,    121443371],
                                  [2400000000,    116818447],
                                  [2200000000,    107540122],
                                  [2000000000,    98222287],
                                  [1900000000,    93547928],
                                  [1800000000,    88862422],
                                  [1700000000,    84163019],
                                  [1600000000,    79451833],
                                  [1500000000,    74726528],
                                  [1400000000,    69985473],
                                  [1300000000,    65228333],
                                  [1200000000,    60454705],
                                  [1100000000,    55662470],
                                  [1000000000,    50847534],
                                  [950000000,     48431471],
                                  [900000000,     46009215],
                                  [850000000,     43581966],
                                  [800000000,     41146179],
                                  [750000000,     38703181],
                                  [700000000,     36252931],
                                  [650000000,     33793395],
                                  [600000000,     31324703],
                                  [550000000,     28845356],
                                  [500000000,     26355867],
                                  [450000000,     23853038],
                                  [400000000,     21336326],
                                  [370000000,     19818405],
                                  [360000000,     19311288],
                                  [350000000,     18803526],
                                  [330000000,     17785475],
                                  [300000000,     16252325],
                                  [290000000,     15739663],
                                  [270000000,     14711384],
                                  [250000000,     13679318],
                                  [230000000,     12642573],
                                  [200000000,     11078937],
                                  [190000000,     10555473],
                                  [170000000,     9503083],
                                  [160000000,     8974458],
                                  [150000000,     8444396],
                                  [140000000,     7912199],
                                  [120000000,     6841648],
                                  [100000000,     5761455],
                                  [95000000,      5489749],
                                  [90000000,      5216954],
                                  [85000000,      4943731],
                                  [80000000,      4669382],
                                  [75000000,      4394304],
                                  [70000000,      4118064],
                                  [65000000,      3840554],
                                  [60000000,      3562115],
                                  [55000000,      3282200],
                                  [50000000,      3001134],
                                  [45000000,      2718160],
                                  [40000000,      2433654],
                                  [35000000,      2146775],
                                  [30000000,      1857859],
                                  [25000000,      1565927],
                                  [20000000,      1270607],
                                  [19000000,      1211050],
                                  [18000000,      1151367],
                                  [17000000,      1091314],
                                  [16000000,      1031130],
                                  [15000000,      970704],
                                  [14000000,      910077],
                                  [13000000,      849252],
                                  [12000000,      788060],
                                  [11000000,      726517],
                                  [10000000,      664579],
                                  [9000000,       602489],
                                  [8000000,       539777],
                                  [7000000,       476648],
                                  [6000000,       412849],
                                  [5000000,       348513],
                                  [4000000,       283146],
                                  [3000000,       216816],
                                  [2000000,       148933],
                                  [1000000,       78498],
                                 ];

            {
                state $end = $#{$checkpoints};

                my $left  = 0;
                my $right = $end;

                my ($middle, $item, $cmp);

                while (1) {
                    $middle = (($right + $left) >> 1);
                    $item   = $checkpoints->[$middle][0];
                    $cmp    = ($approx <=> $item) || last;

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

                my $point = $checkpoints->[$middle];

                $count      = $point->[1];
                $i          = $point->[0];
                $prev_count = $count;
            }

            my $count_approx = $up_approx - $i;
            my $step = $count_approx < 1e6 ? $count_approx : $n > 1e8 ? 1e7 : 1e6;

            for (; ; $i += $step) {
                my $primes = Math::Prime::Util::GMP::primes($i, $i + $step);
                $count += $#$primes + 1;

                if ($count >= $n) {
                    my $p = $primes->[$n - $prev_count - 1];
                    return __PACKAGE__->_set_str('int', $p);
                }

                $prev_count = $count;
            }
        }

        state $table = Math::Prime::Util::GMP::primes(1_299_709);    # primes up to prime(100_000)
        __PACKAGE__->_set_uint($table->[$n - 1]);
    }

    *prime = \&nth_prime;

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

    sub gcd {
        my ($x, $y) = @_;
        _valid(\$y);
        $x = _copy2mpz($$x) // goto &nan;
        $y = _any2mpz($$y)  // goto &nan;
        Math::GMPz::Rmpz_gcd($x, $x, $y);
        bless \$x;
    }

    sub lcm {
        my ($x, $y) = @_;
        _valid(\$y);
        $x = _copy2mpz($$x) // goto &nan;
        $y = _any2mpz($$y)  // goto &nan;
        Math::GMPz::Rmpz_lcm($x, $x, $y);
        bless \$x;
    }

    sub valuation {
        my ($x, $y) = @_;
        _valid(\$y);
        $x = _copy2mpz($$x) // goto &nan;
        $y = _any2mpz($$y)  // goto &nan;
        Math::GMPz::Rmpz_sgn($y) || return ZERO;
        Math::GMPz::Rmpz_cmpabs_ui($y, 1) || return ZERO;
        __PACKAGE__->_set_uint(scalar Math::GMPz::Rmpz_remove($x, $x, $y));
    }

    sub remove {
        my ($x, $y) = @_;
        _valid(\$y);
        $x = _copy2mpz($$x) // goto &nan;
        $y = _any2mpz($$y)  // goto &nan;
        Math::GMPz::Rmpz_sgn($y) || return $_[0];
        Math::GMPz::Rmpz_cmpabs_ui($y, 1) || return $_[0];
        Math::GMPz::Rmpz_remove($x, $x, $y);
        bless \$x;
    }

    *remdiv = \&remove;

    sub make_coprime {
        my ($x, $y) = @_;
        _valid(\$y);

        my $z = _copy2mpz($$x) // goto &nan;

        my %factors;
        @factors{Math::Prime::Util::GMP::factor(_big2uistr($y) // goto &nan)} = ();

        my $t = Math::GMPz::Rmpz_init();
        foreach my $f (keys %factors) {
            if ($f <= ULONG_MAX) {
                Math::GMPz::Rmpz_divisible_ui_p($z, $f)
                  ? Math::GMPz::Rmpz_set_ui($t, $f)
                  : next;
            }
            else {
                Math::GMPz::Rmpz_set_str($t, $f);
            }
            Math::GMPz::Rmpz_remove($z, $z, $t);
        }

        bless \$z;
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

    sub random_nbit_prime {
        my ($x) = @_;
        my $n = _any2ui($$x) // goto &nan;
        $n <= 1 && goto &nan;
        __PACKAGE__->_set_str('int', Math::Prime::Util::GMP::random_nbit_prime($n));
    }

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

    sub is_prime {
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::is_prime(&_big2uistr // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_prob_prime {
        my ($x, $k) = @_;

        my $z = $$x;
        if (defined($k)) {
            _valid(\$k);
            (__is_int__($z) and Math::GMPz::Rmpz_probab_prime_p(_any2mpz($z), CORE::abs(_any2si($$k) // 20)) > 0)
              ? Sidef::Types::Bool::Bool::TRUE
              : Sidef::Types::Bool::Bool::FALSE;
        }
        else {
            __is_int__($z)
              && Math::Prime::Util::GMP::is_prob_prime(_big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE)
              ? Sidef::Types::Bool::Bool::TRUE
              : Sidef::Types::Bool::Bool::FALSE;
        }
    }

    sub is_prov_prime {
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::is_provable_prime(_big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE)
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

    sub primes {
        my ($x, $y) = @_;

        _valid(\$y) if defined($y);

        Sidef::Types::Array::Array->new(
            [
             map {
                 $_ <= ULONG_MAX
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
               }

               @{Math::Prime::Util::GMP::primes(_big2uistr($x) // 0, defined($y) ? (_big2uistr($y) // 0) : ())}
            ]
        );
    }

    sub prev_prime {
        my $p = Math::Prime::Util::GMP::prev_prime(&_big2uistr // goto &nan) || goto &nan;
        $p <= ULONG_MAX ? __PACKAGE__->_set_uint($p) : __PACKAGE__->_set_str('int', $p);
    }

    sub next_prime {
        my ($x) = @_;
        $x = _copy2mpz($$x) // goto &nan;
        Math::GMPz::Rmpz_nextprime($x, $x);
        bless \$x;
    }

    sub znorder {
        my ($x, $y) = @_;
        _valid(\$y);
        my $z = Math::Prime::Util::GMP::znorder(_big2uistr($x) // (goto &nan), _big2uistr($y) // (goto &nan)) // goto &nan;
        $z <= ULONG_MAX ? __PACKAGE__->_set_uint($z) : __PACKAGE__->_set_str('int', $z);
    }

    sub znprimroot {
        my $z = Math::Prime::Util::GMP::znprimroot(&_big2uistr // (goto &nan)) // goto &nan;
        $z <= ULONG_MAX ? __PACKAGE__->_set_uint($z) : __PACKAGE__->_set_str('int', $z);
    }

    sub rad {
        my %f;
        @f{Math::Prime::Util::GMP::factor(&_big2uistr // goto &nan)} = ();
        my $r = Math::Prime::Util::GMP::vecprod(CORE::keys %f);
        $r <= ULONG_MAX ? __PACKAGE__->_set_uint($r) : __PACKAGE__->_set_str('int', $r);
    }

    sub factor {
        Sidef::Types::Array::Array->new(
            [
             map {
                 $_ <= ULONG_MAX
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
               }

               Math::Prime::Util::GMP::factor(&_big2uistr || return Sidef::Types::Array::Array->new())
            ]
        );
    }

    *factors = \&factor;

    sub factor_exp {
        my %count;
        foreach my $f (Math::Prime::Util::GMP::factor(&_big2uistr || return Sidef::Types::Array::Array->new())) {
            ++$count{$f};
        }

        my @pairs;
        foreach my $factor (sort { (CORE::length($a) <=> CORE::length($b)) || ($a cmp $b) } keys(%count)) {
            push @pairs,
              Sidef::Types::Array::Array->new(
                                              [
                                               (
                                                $factor <= ULONG_MAX
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

    sub divisors {
        my $n = &_big2uistr || return Sidef::Types::Array::Array->new();

        Sidef::Types::Array::Array->new(
            [
             map {
                 $_ <= ULONG_MAX
                   ? __PACKAGE__->_set_uint($_)
                   : __PACKAGE__->_set_str('int', $_)
               } Math::Prime::Util::GMP::divisors($n)
            ]
        );
    }

    sub exp_mangoldt {
        my $n = Math::Prime::Util::GMP::exp_mangoldt(&_big2uistr || return ONE);
        $n eq '1' and return ONE;
        $n <= ULONG_MAX ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
    }

    sub totient {
        my $n = Math::Prime::Util::GMP::totient(&_big2uistr // goto &nan);
        $n <= ULONG_MAX ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
    }

    *euler_phi     = \&totient;
    *euler_totient = \&totient;

    sub jordan_totient {
        my ($x, $y) = @_;
        _valid(\$y);
        my $n = Math::Prime::Util::GMP::jordan_totient(_big2istr($x) // (goto &nan), _big2istr($y) // (goto &nan));
        $n <= ULONG_MAX ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
    }

    sub carmichael_lambda {
        my $n = Math::Prime::Util::GMP::carmichael_lambda(&_big2uistr // goto &nan);
        $n <= ULONG_MAX ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
    }

    sub liouville {
        Math::Prime::Util::GMP::liouville(&_big2uistr // goto &nan) == 1 ? ONE : MONE;
    }

    sub big_omega {
        __PACKAGE__->_set_uint(scalar Math::Prime::Util::GMP::factor(&_big2uistr // goto &nan));
    }

    sub omega {
        my %factors;
        @factors{Math::Prime::Util::GMP::factor(&_big2uistr // goto &nan)} = ();
        __PACKAGE__->_set_uint(scalar keys %factors);
    }

    sub sigma0 {
        my $str = &_big2uistr // goto &nan;
        $str eq '0' && return ZERO;
        my $n = Math::Prime::Util::GMP::sigma($str, 0);
        $n <= ULONG_MAX ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
    }

    sub sigma {
        my ($x, $y) = @_;

        my $n = defined($y)
          ? do {
            _valid(\$y);
            Math::Prime::Util::GMP::sigma(_big2uistr($x) // (goto &nan), _big2uistr($y) // (goto &nan));
          }
          : Math::Prime::Util::GMP::sigma(&_big2uistr // (goto &nan), 1);

        $n <= ULONG_MAX ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
    }

    sub partitions {
        my $n = Math::Prime::Util::GMP::partitions(&_big2uistr // goto &nan);
        $n <= ULONG_MAX ? __PACKAGE__->_set_uint($n) : __PACKAGE__->_set_str('int', $n);
    }

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

    sub is_square_free {
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::moebius(_big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub is_square {
        my ($x) = @_;
        __is_int__($$x)
          && Math::GMPz::Rmpz_perfect_square_p(_any2mpz($$x))
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    *is_sqr = \&is_square;

    sub is_power {
        my ($x, $y) = @_;

        __is_int__($$x) || return Sidef::Types::Bool::Bool::FALSE;
        $x = _any2mpz($$x) // return Sidef::Types::Bool::Bool::FALSE;

        if (defined $y) {
            _valid(\$y);

            if (Math::GMPz::Rmpz_cmp_ui($x, 1) == 0) {
                return Sidef::Types::Bool::Bool::TRUE;
            }

            $y = _any2si($$y) // return undef;

            # Everything is a first power
            $y == 1 and return Sidef::Types::Bool::Bool::TRUE;

            # Return a true value when $x=-1 and $y is odd
            $y % 2
              and (Math::GMPz::Rmpz_cmp_si($x, -1) == 0)
              and return Sidef::Types::Bool::Bool::TRUE;

            # Don't accept a non-positive power
            # Also, when $x is negative and $y is even, return faster
            if ($y <= 0 or ($y % 2 == 0 and Math::GMPz::Rmpz_sgn($x) < 0)) {
                return Sidef::Types::Bool::Bool::FALSE;
            }

            # Optimization for perfect squares (thanks to Dana Jacobsen)
            $y == 2
              and return (
                          Math::GMPz::Rmpz_perfect_square_p($x)
                          ? Sidef::Types::Bool::Bool::TRUE
                          : Sidef::Types::Bool::Bool::FALSE
                         );

            Math::GMPz::Rmpz_perfect_power_p($x)
              || return Sidef::Types::Bool::Bool::FALSE;

            my $z = Math::GMPz::Rmpz_init_set($x);
            Math::GMPz::Rmpz_root($z, $z, $y)
              ? Sidef::Types::Bool::Bool::TRUE
              : Sidef::Types::Bool::Bool::FALSE;
        }
        else {
            Math::GMPz::Rmpz_perfect_power_p($x)
              ? Sidef::Types::Bool::Bool::TRUE
              : Sidef::Types::Bool::Bool::FALSE;
        }
    }

    *is_pow = \&is_power;

    sub is_prime_power {
        my ($x) = @_;
        __is_int__($$x)
          && Math::Prime::Util::GMP::is_prime_power(_big2uistr($x) // return Sidef::Types::Bool::Bool::FALSE)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub prime_root {
        my $str = &_big2uistr // return $_[0];

        my $pow = Math::Prime::Util::GMP::is_prime_power($str) || return $_[0];
        $pow == 1 and return $_[0];

        my $x = Math::GMPz::Rmpz_init_set_str($str, 10);
        $pow == 2
          ? Math::GMPz::Rmpz_sqrt($x, $x)
          : Math::GMPz::Rmpz_root($x, $x, $pow);
        bless \$x;
    }

    sub prime_power {
        my $pow = Math::Prime::Util::GMP::is_prime_power(&_big2uistr // return ONE) || return ONE;
        $pow == 1 ? ONE : __PACKAGE__->_set_uint($pow);
    }

    sub perfect_root {
        my $str = &_big2istr // return $_[0];
        my $pow = Math::Prime::Util::GMP::is_power($str) || return $_[0];

        my $x = Math::GMPz::Rmpz_init_set_str($str, 10);
        $pow == 2
          ? Math::GMPz::Rmpz_sqrt($x, $x)
          : Math::GMPz::Rmpz_root($x, $x, $pow);
        bless \$x;
    }

    sub perfect_power {
        __PACKAGE__->_set_uint(Math::Prime::Util::GMP::is_power(&_big2istr // return ONE) || return ONE);
    }

    sub next_pow2 {
        my ($x) = @_;

        my $f = _copy2mpfr($$x);
        Math::MPFR::Rmpfr_log2($f, $f, $ROUND);
        Math::MPFR::Rmpfr_add_ui($f, $f, 1, $ROUND);
        Math::MPFR::Rmpfr_floor($f, $f);

        my $z = Math::GMPz::Rmpz_init_set_ui(1);
        my $ui = Math::MPFR::Rmpfr_get_ui($f, $ROUND);
        Math::GMPz::Rmpz_mul_2exp($z, $z, $ui);
        bless \$z;
    }

    *next_power2 = \&next_pow2;

    sub next_pow {
        my ($x, $y) = @_;

        _valid(\$y);

        my $f1 = _copy2mpfr($$x);
        my $f2 = _copy2mpfr($$y);

        Math::MPFR::Rmpfr_log($f1, $f1, $ROUND);
        Math::MPFR::Rmpfr_log($f2, $f2, $ROUND);

        Math::MPFR::Rmpfr_div($f1, $f1, $f2, $ROUND);

        Math::MPFR::Rmpfr_add_ui($f1, $f1, 1, $ROUND);
        Math::MPFR::Rmpfr_floor($f1, $f1);

        $y = _copy2mpz($$y) // goto &nan;
        my $ui = Math::MPFR::Rmpfr_get_ui($f1, $ROUND);
        Math::GMPz::Rmpz_pow_ui($y, $y, $ui);
        bless \$y;
    }

    *next_power = \&next_pow;

    sub shift_left {
        my ($x, $y) = @_;

        _valid(\$y);

        my $n = _any2si($$y)   // (goto &nan);
        my $z = _copy2mpz($$x) // (goto &nan);

        $n < 0
          ? Math::GMPz::Rmpz_div_2exp($z, $z, -$n)
          : Math::GMPz::Rmpz_mul_2exp($z, $z, $n);

        bless \$z;
    }

    *lsft = \&shift_left;

    sub shift_right {
        my ($x, $y) = @_;

        _valid(\$y);

        my $n = _any2si($$y)   // (goto &nan);
        my $z = _copy2mpz($$x) // (goto &nan);

        $n < 0
          ? Math::GMPz::Rmpz_mul_2exp($z, $z, -$n)
          : Math::GMPz::Rmpz_div_2exp($z, $z, $n);

        bless \$z;
    }

    *rsft = \&shift_right;

    #
    ## Rational specific
    #

    sub numerator {
        my ($x) = @_;

        my $r = $$x;
        while (1) {
            my $ref = ref($r);
            ref($r) eq 'Math::GMPz' && return $x;    # is an integer

            if (ref($r) eq 'Math::GMPq') {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPq::Rmpq_get_num($z, $r);
                return bless \$z;
            }

            $r = _any2mpq($r) // (goto &nan);
        }
    }

    *nu = \&numerator;

    sub denominator {
        my ($x) = @_;

        my $r = $$x;
        while (1) {
            my $ref = ref($r);
            ref($r) eq 'Math::GMPz' && return ONE;    # is an integer

            if (ref($r) eq 'Math::GMPq') {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPq::Rmpq_get_den($z, $r);
                return bless \$z;
            }

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
        my ($n, $prec) = @_;

        my $sig = join(' ', ref($n), '$');

        if ($sig eq q(Math::MPFR $)) {
            my ($n, $prec) = @_;

            my $nth = -CORE::int($prec);

            my $p = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            Math::MPFR::Rmpfr_set_str($p, '1e' . CORE::abs($nth), 10, $ROUND);

            if ($nth < 0) {
                Math::MPFR::Rmpfr_div($n, $n, $p, $ROUND);
            }
            else {
                Math::MPFR::Rmpfr_mul($n, $n, $p, $ROUND);
            }

            Math::MPFR::Rmpfr_round($n, $n);

            if ($nth < 0) {
                Math::MPFR::Rmpfr_mul($n, $n, $p, $ROUND);
            }
            else {
                Math::MPFR::Rmpfr_div($n, $n, $p, $ROUND);
            }

            $n;
        }

        elsif ($sig eq q(Math::MPC $)) {

            my $real = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
            my $imag = Math::MPFR::Rmpfr_init2(CORE::int($PREC));

            Math::MPC::RMPC_RE($real, $n);
            Math::MPC::RMPC_IM($imag, $n);

            $real = __SUB__->($real, $prec);
            $imag = __SUB__->($imag, $prec);

            if (Math::MPFR::Rmpfr_zero_p($imag)) {
                return $real;
            }

            Math::MPC::Rmpc_set_fr_fr($n, $real, $imag, $ROUND);
            $n;
        }

        elsif ($sig eq q(Math::GMPq $)) {

            my $nth = -CORE::int($prec);
            my $sgn = Math::GMPq::Rmpq_sgn($n);

            Math::GMPq::Rmpq_neg($n, $n) if $sgn < 0;

            my $p = Math::GMPz::Rmpz_init_set_str('1' . ('0' x CORE::abs($nth)), 10);

            if ($nth < 0) {
                Math::GMPq::Rmpq_div_z($n, $n, $p);
            }
            else {
                Math::GMPq::Rmpq_mul_z($n, $n, $p);
            }

            state $half = do {
                my $q = Math::GMPq::Rmpq_init_nobless();
                Math::GMPq::Rmpq_set_ui($q, 1, 2);
                $q;
            };

            Math::GMPq::Rmpq_add($n, $n, $half);

            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $n);

            if (Math::GMPz::Rmpz_odd_p($z) and Math::GMPq::Rmpq_integer_p($n)) {
                Math::GMPz::Rmpz_sub_ui($z, $z, 1);
            }

            Math::GMPq::Rmpq_set_z($n, $z);

            if ($nth < 0) {
                Math::GMPq::Rmpq_mul_z($n, $n, $p);
            }
            else {
                Math::GMPq::Rmpq_div_z($n, $n, $p);
            }

            if ($sgn < 0) {
                Math::GMPq::Rmpq_neg($n, $n);
            }

            if (Math::GMPq::Rmpq_integer_p($n)) {
                Math::GMPz::Rmpz_set_q($z, $n);
                return $z;
            }

            $n;
        }

        elsif ($sig eq q(Math::GMPz $)) {
            (@_) = (_mpz2mpq($n), $prec);
            goto __SUB__;
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

        bless \__round__(_copy($$x), $nth);
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
                    $rand = __mul__($rand, __sub__(_copy($$y), $$x));
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
                my $z = _copy2mpz($$x) // die "[ERROR] Number.seed(): invalid seed value <<$x>> (expected an integer)";
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

                $x = _copy2mpz($$x);

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
                my $z = _copy2mpz($$x) // die "[ERROR] Number.iseed(): invalid seed value <<$x>> (expected an integer)";
                Math::GMPz::zgmp_randseed($state, $z);
                bless \$z;
            }
        }
    }

    sub of {
        my ($x, $obj) = @_;

        $x = CORE::int(__numify__($$x));

        if (ref($obj) eq 'Sidef::Types::Block::Block') {
            my @array;
            for (my $i = 0 ; $i < $x ; ++$i) {
                push @array,
                  $obj->run(
                            $i <= 8192
                            ? __PACKAGE__->_set_uint($i)
                            : bless \Math::GMPz::Rmpz_init_set_ui($i)
                           );
            }
            return Sidef::Types::Array::Array->new(\@array);
        }

        Sidef::Types::Array::Array->new([($obj) x $x]);
    }

    sub defs {
        my ($x, $block) = @_;

        my @items;
        my $end = CORE::int(__numify__($$x));

        for (my ($i, $j) = (0, 0) ; $j < $end ; ++$i) {
            push @items,
              $block->run(
                          $i <= 8192
                          ? __PACKAGE__->_set_uint($i)
                          : bless \Math::GMPz::Rmpz_init_set_ui($i)
                         ) // next;
            ++$j;
        }

        Sidef::Types::Array::Array->new(\@items);
    }

    sub times {
        my ($num, $block) = @_;

        if (__is_inf__($$num)) {
            for (my $i = 0 ; ; ++$i) {
                $block->run(
                            $i <= 8192
                            ? __PACKAGE__->_set_uint($i)
                            : bless \Math::GMPz::Rmpz_init_set_ui($i)
                           );
            }
            return $_[0];
        }

        $num = _any2mpz($$num) // return undef;

        if (defined(my $ui = _any2ui($num))) {
            for (my $i = 0 ; $i < $ui ; ++$i) {
                $block->run(
                            $i <= 8192
                            ? __PACKAGE__->_set_uint($i)
                            : bless \Math::GMPz::Rmpz_init_set_ui($i)
                           );
            }
            return $_[0];
        }

        for (my $i = Math::GMPz::Rmpz_init_set_ui(0) ; Math::GMPz::Rmpz_cmp($i, $num) < 0 ; Math::GMPz::Rmpz_add_ui($i, $i, 1))
        {
            $block->run(bless(\Math::GMPz::Rmpz_init_set($i)));
        }

        $_[0];
    }

    sub forperm {
        my ($n, $block) = @_;

        $n = CORE::int(__numify__($$n));

        if (!defined $block) {
            return Sidef::Types::Array::Array->new(map { __PACKAGE__->_set_uint($_) } 0 .. $n - 1)->permutations;
        }

        if ($n == 0) {
            $block->run();
            return $block;
        }

        if ($n < 0) {
            return $block;
        }

        my @idx = (0 .. $n - 1);
        my @nums = map { __PACKAGE__->_set_uint($_) } @idx;

        my @perm;
        while (1) {
            @perm = @nums[@idx];

            my $p = $#idx;
            --$p while $idx[$p - 1] > $idx[$p];

            my $q = $p || do {
                $block->run(@perm);
                return $block;
            };

            CORE::push(@idx, CORE::reverse CORE::splice @idx, $p);
            ++$q while $idx[$p - 1] > $idx[$q];
            @idx[$p - 1, $q] = @idx[$q, $p - 1];

            $block->run(@perm);
        }

        return $block;
    }

    *permutations = \&forperm;

    sub forcomb {
        my ($n, $k, $block) = @_;
        _valid(\$k);

        $n = CORE::int(__numify__($$n));

        if (!defined $block) {
            return Sidef::Types::Array::Array->new(map { __PACKAGE__->_set_uint($_) } 0 .. $n - 1)->combinations($k);
        }

        $k = CORE::int(__numify__($$k));

        if ($k == 0) {
            $block->run();
            return $block;
        }

        ($k < 0 or $k > $n or $n == 0)
          && return $block;

        my @c = (0 .. $k - 1);
        my @nums = map { __PACKAGE__->_set_uint($_) } (0 .. $n - 1);

        while (1) {
            $block->run(@nums[@c]);
            next if ($c[$k - 1]++ < $n - 1);
            my $i = $k - 2;
            $i-- while ($i >= 0 && $c[$i] >= $n - ($k - $i));
            last if $i < 0;
            $c[$i]++;
            while (++$i < $k) { $c[$i] = $c[$i - 1] + 1; }
        }

        return $block;
    }

    *combinations = \&forcomb;

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
        bless \__mul__(_copy2mpfr_mpc($$x), $f);
    }

    sub deg2rad {
        my ($x) = @_;
        my $f = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_const_pi($f, $ROUND);
        Math::MPFR::Rmpfr_div_ui($f, $f, 180, $ROUND);
        bless \__mul__(_copy2mpfr_mpc($$x), $f);
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
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
        *{__PACKAGE__ . '::' . '≤'} = \&le;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'} = \&ge;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'} = \&ne;
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
        *{__PACKAGE__ . '::' . 'γ'}  = \&Y;
        *{__PACKAGE__ . '::' . 'Γ'}  = \&gamma;
        *{__PACKAGE__ . '::' . 'Ψ'}  = \&digamma;
        *{__PACKAGE__ . '::' . 'ϕ'}  = \&euler_totient;
        *{__PACKAGE__ . '::' . 'σ'}  = \&sigma;
        *{__PACKAGE__ . '::' . 'Ω'}  = \&big_omega;
        *{__PACKAGE__ . '::' . 'ω'}  = \&omega;
        *{__PACKAGE__ . '::' . 'ζ'}  = \&zeta;
        *{__PACKAGE__ . '::' . 'η'}  = \&eta;
        *{__PACKAGE__ . '::' . 'μ'}  = \&mobius;
    }
}

1
