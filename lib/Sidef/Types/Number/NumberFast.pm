## package Sidef::Types::Number::NumberFast
package Sidef::Types::Number::Number {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => sub { ${$_[0]} != 0 },
      q{""}   => \&get_value;

    sub new {
        bless \(ref($_[1]) ? ($_[1]->can('numify') ? $_[1]->numify : $_[1]->get_value + 0) : (($_[1] // 0) + 0)), __PACKAGE__;
    }

    *new_float = \&new;

    sub new_int {
        my (undef, $num) = @_;
        __PACKAGE__->new(CORE::int($num));
    }

    sub new_rat {
        state $x = require Math::BigRat;
        __PACKAGE__->new(Math::BigRat->new(ref($_[1]) ? ${$_[1]} : $_[1]));
    }

    sub get_value {
        ${$_[0]};
    }

    sub modpow {
        my ($self, $y, $mod) = @_;
        $self->new(($self->get_value**$y->get_value) % $mod->get_value);
    }

    *expmod = \&modpow;

    sub inc {
        my ($self) = @_;
        $self->new($self->get_value + 1);
    }

    sub dec {
        my ($self) = @_;
        $self->new($self->get_value - 1);
    }

    sub and {
        my ($self, $num) = @_;
        $self->new($self->get_value & $num->get_value);
    }

    sub or {
        my ($self, $num) = @_;
        $self->new($self->get_value | $num->get_value);
    }

    sub xor {
        my ($self, $num) = @_;
        $self->new($self->get_value ^ $num->get_value);
    }

    sub cmp {
        my ($self, $num) = @_;
        __PACKAGE__->new($self->get_value <=> $num->get_value);
    }

    sub acmp {
        my ($self, $num) = @_;
        __PACKAGE__->new(CORE::abs($self->get_value) <=> CORE::abs($num->get_value));
    }

    sub factorial {
        my ($self) = @_;
        my $fac = 1;
        $fac *= $_ for (2 .. $self->get_value);
        $self->new($fac);
    }

    *fact = \&factorial;

    sub root {
        my ($self, $n) = @_;
        $self->new($self->get_value**(1 / $n->get_value));
    }

    sub hex {
        my ($self) = @_;
        $self->new(CORE::hex($self->get_value));
    }

    sub bin {
        my ($self) = @_;
        $self->new(CORE::oct("b$self->get_value"));
    }

    sub int {
        my ($self) = @_;
        $self->new(CORE::int($self->get_value));
    }

    *as_int = \&int;

    sub log {
        my ($self, $base) = @_;
        my $log = CORE::log($self->get_value);
        defined($base) ? $self->new($log / CORE::log($base->get_value)) : $self->new($log);
    }

    sub atan { ... }

    sub ln {
        my ($self) = @_;
        $self->new(CORE::log($self->get_value));
    }

    sub log10 {
        my ($self) = @_;
        $self->new(CORE::log($self->get_value) / CORE::log(10));
    }

    sub log2 {
        my ($self) = @_;
        $self->new(CORE::log($self->get_value) / CORE::log(2));
    }

    sub inf {
        my ($self) = @_;
        $self->new('inf');
    }

    sub neg {
        my ($self) = @_;
        $self->new(-$self->get_value);
    }

    *negate = \&neg;

    sub not {
        my ($self) = @_;
        $self->new(-$self->get_value - 1);
    }

    sub sign {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->get_value >= 0 ? '+' : '-');
    }

    sub nan {
        my ($self) = @_;
        $self->new('nan');
    }

    *NaN = \&nan;

    sub next_power_of_two {
        my ($self) = @_;
        $self->new(2 << CORE::log($self->get_value) / CORE::log(2));
    }

    *npow2 = \&next_power_of_two;

    sub next_power_of {
        my ($self, $num) = @_;

        $self->new($num->get_value**(CORE::int(CORE::log($self->get_value) / CORE::log($num->get_value)) + 1));
    }

    *npow = \&next_power_of;

    sub is_zero {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value eq '0');    # 'eq' is well intented here
    }

    *isZero = \&is_zero;

    sub is_nan {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(lc($self->get_value) eq 'nan');
    }

    *isNaN  = \&is_nan;
    *is_NaN = \&is_nan;

    sub is_positive {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value >= 0);
    }

    *isPositive = \&is_positive;
    *isPos      = \&is_positive;
    *is_pos     = \&is_positive;

    sub is_inf {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value == 'inf');
    }

    *isInf       = \&is_inf;
    *is_infinite = \&is_inf;
    *isInfinite  = \&is_inf;

    sub is_negative {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value < 0);
    }

    *isNegative = \&is_negative;
    *isNeg      = \&is_negative;
    *is_neg     = \&is_negative;

    sub is_even {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::not($self->get_value & 1));
    }

    *isEven = \&is_even;

    sub is_odd {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value & 1);
    }

    *isOdd = \&is_odd;

    sub is_integer {
        my ($self) = @_;

        # 'eq' is well intented here
        Sidef::Types::Bool::Bool->new($self->get_value eq CORE::int($self->get_value));
    }

    *isInt     = \&is_integer;
    *is_int    = \&is_integer;
    *isInteger = \&is_integer;

    sub rand {
        my ($self, $max) = @_;

        my $min = $self->get_value;
        $max = ref($max) ? $max->get_value : do { $min = 0; $self->get_value };

        $self->new($min + CORE::rand($max - $min));
    }

    sub ceil {
        my ($self) = @_;

        # 'eq' is well intended here
        CORE::int($self->get_value) eq $self->get_value
          && return $self;

        $self->new(CORE::int($self->get_value + 1));
    }

    sub floor {
        my ($self) = @_;
        $self->new(CORE::int($self->get_value));
    }

    sub round { ... }

    sub roundf {
        my ($self, $num) = @_;

        $self->new(sprintf "%.*f", $num->get_value * -1, $self->get_value);
    }

    *fround = \&roundf;
    *fRound = \&roundf;

    sub digit { ... }

    sub length {
        my ($self) = @_;
        my $len1   = CORE::length($$self);
        my $len2   = CORE::length(CORE::int($$self));
        $self->new($len1 == $len2 ? $len1 : $len1 - 1);
    }

    *len = \&length;

    sub nok {
        my ($n, $k) = @_;
        $n->factorial->div($n->subtract($k)->factorial->multiply($k->factorial));
    }

    *binomial = \&nok;

    sub to_bin {
        my ($self) = @_;

        my $dec      = $self->get_value;
        my $reminder = $dec % 2;

        my @bin;
        while ($dec > 0) {
            unshift @bin, $reminder;
            $reminder = ($dec >>= 1) % 2;
        }

        Sidef::Types::String::String->new(join('', @bin));
    }

    *as_bin = \&to_bin;

    sub commify {
        my ($self) = @_;

        my $n = $self->get_value;
        my $x = $n;

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

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->get_value);
    }

    sub sstr {
        my ($self) = @_;
        Sidef::Types::String::String->new(sprintf "%g", $self->get_value);
    }

    sub shift_right {
        my ($self, $num) = @_;
        $self->new($self->get_value >> $num->get_value);
    }

    *shiftRight = \&shift_right;

    sub shift_left {
        my ($self, $num) = @_;
        $self->new($self->get_value << $num->get_value);
    }

    *shiftLeft = \&shift_left;

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
    }
};

1
