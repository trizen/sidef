package Sidef::Types::Number::Number {

    use utf8;
    use 5.014;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new_float {
        my (undef, $num) = @_;

        require Math::BigFloat;
        ref($num) eq 'Math::BigFloat'
          ? (bless \$num)
          : (
            bless \do {
                eval { Math::BigFloat->new($num) } // Math::BigFloat->new(Math::BigInt->new($num));
              }
            );
    }

    *new = \&new_float;

    sub new_int {
        my (undef, $num) = @_;

        require Math::BigInt;
        my $ref = ref($num);
        $ref eq 'Math::BigInt' ? (bless \$num)
          : (   $ref eq 'Math::BigFloat'
             || $ref eq 'Math::BigRat'
             || $ref eq __PACKAGE__) ? (bless \Math::BigInt->new($num->as_int))
          : (bless \Math::BigInt->new(index($num, '.') > 0 ? CORE::int($num) : $num));
    }

    sub new_rat {
        my (undef, $num) = @_;

        require Math::BigRat;
        ref($num) eq 'Math::BigRat'
          ? (bless \$num)
          : (
            bless \do {
                eval { Math::BigRat->new($num) }
                  // eval { Math::BigRat->new(Math::BigFloat->new($num)) } // Math::BigRat->new(Math::BigInt->new($num));
              }
            );
    }

    sub get_value { ${$_[0]}->numify }

    sub mod {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self % $$num);
    }

    sub pow {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self**$$num);
    }

    sub inc {
        my ($self) = @_;
        $self->new($$self->copy->binc);
    }

    sub dec {
        my ($self) = @_;
        $self->new($$self->copy->bdec);
    }

    sub lt {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        Sidef::Types::Bool::Bool->new($$self < $$num);
    }

    sub gt {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        Sidef::Types::Bool::Bool->new($$self > $$num);
    }

    sub and {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self->as_int->band($$num->as_int));
    }

    sub or {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self->as_int->bior($$num->as_int));
    }

    sub xor {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self->as_int->bxor($$num->as_int));
    }

    sub eq {
        my ($self, $num) = @_;
        ref($self) ne ref($num) and return Sidef::Types::Bool::Bool->false;
        Sidef::Types::Bool::Bool->new($$self == $$num);
    }

    *equals = \&eq;

    sub ne {
        my ($self, $num) = @_;
        ref($self) ne ref($num) and return Sidef::Types::Bool::Bool->true;
        Sidef::Types::Bool::Bool->new($$self != $$num);
    }

    sub cmp {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        __PACKAGE__->new($$self->bcmp($$num));
    }

    sub acmp {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        __PACKAGE__->new($$self->bacmp($$num));
    }

    sub ge {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        Sidef::Types::Bool::Bool->new($$self >= $$num);
    }

    sub le {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        Sidef::Types::Bool::Bool->new($$self <= $$num);
    }

    sub subtract {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self - $$num);
    }

    sub add {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self + $$num);
    }

    sub multiply {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self * $$num);
    }

    *x = \&multiply;

    sub div {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self / $$num);
    }

    sub divmod {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        Sidef::Types::Array::Array->new($self->div($num)->int, $self->mod($num));
    }

    sub factorial {
        my ($self) = @_;
        $self->new($$self->copy->bfac);
    }

    *fact = \&factorial;

    sub comb {
        my ($self, $num) = @_;

        $self->_is_number($num) || return;

        my $k = $$self;
        my $n = $$num;
        my @c = 0 .. $k - 1;

        my @bag;
        while (1) {
            push @bag, [@c];
            next if $c[$k - 1]++ < $n - 1;
            my $i = $k - 2;
            $i-- while $i >= 0 && $c[$i] >= $n - ($k - $i);
            last if $i < 0;
            $c[$i]++;
            while (++$i < $k) { $c[$i] = $c[$i - 1] + 1; }
        }

        Sidef::Types::Array::Array->new(
            map {
                Sidef::Types::Array::Array->new(map { Sidef::Types::Number::Number->new($_) } @{$_})
              } @bag
        );
    }

    sub to {
        my ($self, $num, $step) = @_;

        $self->_is_number($num) || return;
        $step = defined($step) ? $self->_is_number($step) ? ($$step) : return : 1;

        my $array = Sidef::Types::Array::Array->new();
        for (my $i = $$self ; $i <= $$num ; $i += $step) {
            $array->push($self->new($i));
        }
        $array;
    }

    *upto = \&to;
    *upTo = \&to;

    sub downto {
        my ($self, $num, $step) = @_;

        $self->_is_number($num) || return;
        $step = defined($step) ? $self->_is_number($step) ? ($$step) : return : 1;

        my $array = Sidef::Types::Array::Array->new();
        for (my $i = $$self ; $i >= $$num ; $i -= $step) {
            $array->push($self->new($i));
        }
        $array;
    }

    *downTo = \&downto;

    sub range_to {
        my ($self, $num, $step) = @_;
        $self->_is_number($num) || return;
        $step = defined($step) ? $self->_is_number($step) ? ($$step) : return : 1;
        Sidef::Types::Array::Range->new(from => $$self, to => $$num, step => $step, type => 'number', direction => 'up');
    }

    sub range_downto {
        my ($self, $num, $step) = @_;
        $self->_is_number($num) || return;
        $step = defined($step) ? $self->_is_number($step) ? ($$step) : return : 1;
        Sidef::Types::Array::Range->new(from => $$self, to => $$num, step => $step, type => 'number', direction => 'down');
    }

    sub sqrt {
        my ($self) = @_;
        $self->new(CORE::sqrt($$self));
    }

    sub root {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        $self->new($$self->copy->broot($$n));
    }

    sub abs {
        my ($self) = @_;
        $self->new(CORE::abs($$self));
    }

    *pos      = \&abs;
    *positive = \&abs;

    sub hex {
        my ($self) = @_;
        require Math::BigInt;
        $self->new(Math::BigInt->new("0x$$self"));
    }

    *from_hex = \&hex;

    sub oct {
        my ($self) = @_;
        require Math::BigInt;
        __PACKAGE__->new(Math::BigInt->from_oct($$self));
    }

    *from_oct = \&oct;

    sub bin {
        my ($self) = @_;
        require Math::BigInt;
        $self->new(Math::BigInt->new("0b$$self"));
    }

    *from_bin = \&bin;

    sub exp {
        my ($self) = @_;
        $self->new(CORE::exp($$self));
    }

    sub int {
        my ($self) = @_;
        $self->new($$self->as_int);
    }

    *as_int = \&int;

    sub cos {
        my ($self) = @_;
        $self->new(CORE::cos($$self));
    }

    sub sin {
        my ($self) = @_;
        $self->new(CORE::sin($$self));
    }

    sub log {
        my ($self, $base) = @_;
        $self->new(
                   $$self->copy->blog(
                                        defined($base)
                                      ? $self->_is_number($base)
                                            ? ($$base)
                                            : return
                                      : ()
                                     )
                  );
    }

    sub log10 {
        my ($self) = @_;
        $self->new($$self->copy->blog(10));
    }

    sub log2 {
        my ($self) = @_;
        $self->new($$self->copy->blog(2));
    }

    sub inf {
        my ($self) = @_;
        $self->new('inf');
    }

    sub neg {
        my ($self) = @_;
        $self->new($$self->copy->bneg);
    }

    *negate = \&neg;

    sub not {
        my ($self) = @_;
        $self->new($$self->copy->bnot);
    }

    sub sign {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self->sign);
    }

    sub nan {
        my ($self) = @_;
        $self->new(Math::BigFloat->bnan);
    }

    *NaN = \&nan;

    sub chr {
        my ($self) = @_;
        Sidef::Types::Char::Char->new(CORE::chr $$self);
    }

    sub next_power_of_two {
        my ($self) = @_;
        $self->new(2 << ($$self->copy->blog(2)->as_int));
    }

    *npow2 = \&next_power_of_two;

    sub next_power_of {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$num**($$self->copy->blog($$num)->as_int->binc));
    }

    *npow = \&next_power_of;

    sub is_zero {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_zero);
    }

    *isZero = \&is_zero;

    sub is_nan {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_nan);
    }

    *isNaN  = \&is_nan;
    *is_NaN = \&is_nan;

    sub is_positive {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_pos);
    }

    *isPositive = \&is_positive;
    *isPos      = \&is_positive;
    *is_pos     = \&is_positive;

    sub is_inf {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_inf);
    }

    *isInf       = \&is_inf;
    *is_infinite = \&is_inf;
    *isInfinite  = \&is_inf;

    sub is_negative {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_neg);
    }

    *isNegative = \&is_negative;
    *isNeg      = \&is_negative;
    *is_neg     = \&is_negative;

    sub is_even {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->as_int->is_even);
    }

    *isEven = \&is_even;

    sub is_odd {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->as_int->is_odd);
    }

    *isOdd = \&is_odd;

    sub is_integer {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_int);
    }

    *isInt     = \&is_integer;
    *is_int    = \&is_integer;
    *isInteger = \&is_integer;

    sub rand {
        my ($self, $max) = @_;
        defined($max)
          ? $self->_is_number($max)
              ? $self->new($$self + CORE::rand($$max - $$self))
              : ()
          : $self->new(CORE::rand($$self));
    }

    sub ceil {
        my ($self) = @_;
        $self->new($$self->copy->bceil);
    }

    sub floor {
        my ($self) = @_;
        $self->new($$self->copy->bfloor);
    }

    sub round {
        my ($self, $places) = @_;
        $self->new(
                   $$self->copy->bround(
                                          defined($places)
                                        ? ($self->_is_number($places))
                                              ? ($$places)
                                              : (return)
                                        : ()
                                       )
                  );
    }

    sub roundf {
        my ($self, $places) = @_;
        $self->new(
                   $$self->copy->bfround(
                                           defined($places)
                                         ? ($self->_is_number($places))
                                               ? ($$places)
                                               : (return)
                                         : ()
                                        )
                  );
    }

    *fround = \&roundf;
    *fRound = \&roundf;

    sub range {
        my ($self) = @_;
        $$self >= 0 ? $self->new(0)->to($self) : $self->to($self->new(0));
    }

    sub length {
        my ($self) = @_;
        $self->new($$self->length);
    }

    *len = \&length;

    sub digit {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        $self->new($$self->as_int->digit($$n));
    }

    sub nok {
        my ($self, $k) = @_;
        $self->_is_number($k) || return;
        $self->new($$self->as_int->bnok($$k));
    }

    sub of {
        my ($self, $obj) = @_;

        defined($obj)
          || $self->_is_code($obj)
          || return;

        if ($self->_is_code($obj, 1, 1)) {
            my $array = Sidef::Types::Array::Array->new();

            for my $i (1 .. $$self) {
                $array->push($obj->run);
            }

            return $array;
        }

        Sidef::Types::Array::Array->new(($obj) x $$self);
    }

    sub times {
        my ($self, $obj) = @_;
        $self->_is_code($obj) || return;
        $obj->repeat($self);
    }

    sub to_bin {
        my ($self) = @_;
        require Math::BigInt;
        Sidef::Types::String::String->new(Math::BigInt->new($$self)->as_bin);
    }

    *as_bin = \&to_bin;

    sub to_oct {
        my ($self) = @_;
        require Math::BigInt;
        Sidef::Types::String::String->new(Math::BigInt->new($$self)->as_oct);
    }

    *as_oct = \&to_oct;

    sub to_hex {
        my ($self) = @_;
        require Math::BigInt;
        Sidef::Types::String::String->new(Math::BigInt->new($$self)->as_hex);
    }

    *as_hex = \&to_hex;

    sub is_div {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        Sidef::Types::Bool::Bool->new($$self % $$num == 0);
    }

    *isDiv = \&is_div;

    sub commify {
        my ($self) = @_;

        my $n = $$self->bstr;
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
        Sidef::Types::String::String->new($$self);
    }

    sub sstr {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self->bsstr);
    }

    sub shift_right {
        my ($self, $num, $base) = @_;
        $self->_is_number($num) || return;
        $self->new($$self->copy->brsft($$num, defined($base) ? $self->_is_number($base) ? $$base : return : ()));
    }

    *shiftRight = \&shift_right;

    sub shift_left {
        my ($self, $num, $base) = @_;
        $self->_is_number($num) || return;
        $self->new($$self->copy->blsft($$num, defined($base) ? $self->_is_number($base) ? $$base : return : ()));
    }

    *shiftLeft = \&shift_left;

    sub complex {
        my ($self, $num) = @_;
        Sidef::Types::Number::Complex->new($self, $num);
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '*'}   = \&multiply;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&subtract;
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
        *{__PACKAGE__ . '::' . '='}   = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'} = \&ne;
        *{__PACKAGE__ . '::' . '..'}  = \&to;
        *{__PACKAGE__ . '::' . '...'} = \&range_to;
        *{__PACKAGE__ . '::' . '..^'} = \&range_to;
        *{__PACKAGE__ . '::' . '^..'} = \&range_downto;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
        *{__PACKAGE__ . '::' . '%%'}  = \&is_div;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
        *{__PACKAGE__ . '::' . ':'}   = \&complex;
    }
};

1;
