package Sidef::Types::Number::Number {

    use utf8;
    use 5.014;

    our $GET_PERL_VALUE = 0;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => sub { ${$_[0]} != 0 },
      q{0+}   => sub { ${$_[0]}->numify },
      q{""}   => sub { ${$_[0]}->bstr };

    my %cache;

    sub new {
        my (undef, $num) = @_;

        ref($num) eq 'Math::BigFloat'
          ? (bless \$num => __PACKAGE__)
          : (
            ref($num) || (length($num) > 5) ? (
               bless \do {
                   eval { Math::BigFloat->new($num) } // Math::BigFloat->new(Math::BigInt->new($num));
                 }
                 => __PACKAGE__
              )
            : (
               $cache{$num} //= (
                   bless \do {
                       eval { Math::BigFloat->new($num) } // Math::BigFloat->new(Math::BigInt->new($num));
                     }
                     => __PACKAGE__
               )
              )
            );
    }

    *call = \&new;

    sub get_value {
        $GET_PERL_VALUE ? ${$_[0]}->numify : ${$_[0]};
    }

    sub mod {
        my ($self, $num) = @_;
        $self->new($$self % $num->get_value);
    }

    sub modpow {
        my ($self, $y, $mod) = @_;
        $self->new($$self->copy->bmodpow($y->get_value, $mod->get_value));
    }

    *expmod = \&modpow;

    sub pow {
        my ($self, $num) = @_;
        $self->new($$self->copy->bpow($num->get_value));
    }

    sub inc {
        my ($self) = @_;
        $self->new($$self->copy->binc);
    }

    sub dec {
        my ($self) = @_;
        $self->new($$self->copy->bdec);
    }

    sub and {
        my ($self, $num) = @_;
        $self->new($$self->as_int->band($num->get_value->as_int));
    }

    sub or {
        my ($self, $num) = @_;
        $self->new($$self->as_int->bior($num->get_value->as_int));
    }

    sub xor {
        my ($self, $num) = @_;
        $self->new($$self->as_int->bxor($num->get_value->as_int));
    }

    sub eq {
        my ($self, $arg) = @_;
        Sidef::Types::Bool::Bool->new($$self == $$arg);
    }

    *equals = \&eq;

    sub ne {
        my ($self, $arg) = @_;
        Sidef::Types::Bool::Bool->new($$self != $$arg);
    }

    sub cmp {
        my ($self, $num) = @_;

        state $mone = Sidef::Types::Number::Number->new(-1);
        state $zero = Sidef::Types::Number::Number->new(0);
        state $one  = Sidef::Types::Number::Number->new(1);

        my $cmp = $$self->bcmp($num->get_value);
        $cmp == 0 ? $zero : $cmp > 0 ? $one : $mone;
    }

    sub acmp {
        my ($self, $num) = @_;

        state $mone = Sidef::Types::Number::Number->new(-1);
        state $zero = Sidef::Types::Number::Number->new(0);
        state $one  = Sidef::Types::Number::Number->new(1);

        my $cmp = $$self->bacmp($num->get_value);
        $cmp == 0 ? $zero : $cmp > 0 ? $one : $mone;
    }

    sub gt {
        my ($self, $num) = @_;
        Sidef::Types::Bool::Bool->new($$self->bcmp($num->get_value) > 0);
    }

    sub lt {
        my ($self, $num) = @_;
        Sidef::Types::Bool::Bool->new($$self->bcmp($num->get_value) < 0);
    }

    sub ge {
        my ($self, $num) = @_;
        Sidef::Types::Bool::Bool->new($$self->bcmp($num->get_value) >= 0);
    }

    sub le {
        my ($self, $num) = @_;
        Sidef::Types::Bool::Bool->new($$self->bcmp($num->get_value) <= 0);
    }

    sub sub {
        my ($self, $num) = @_;
        $self->new(scalar $$self->copy->bsub($num->get_value));
    }

    sub add {
        my ($self, $num) = @_;
        $self->new(scalar $$self->copy->badd($num->get_value));
    }

    sub mul {
        my ($self, $num) = @_;
        $self->new(scalar $$self->copy->bmul($num->get_value));
    }

    *x = \&mul;

    sub div {
        my ($self, $num) = @_;
        $self->new(scalar $$self->copy->bdiv($num->get_value));
    }

    *divide = \&div;

    sub divmod {
        my ($self, $num) = @_;
        ($self->div($num)->int, $self->mod($num));
    }

    sub factorial {
        my ($self) = @_;
        $self->new($$self->copy->bfac);
    }

    *fac  = \&factorial;
    *fact = \&factorial;

    sub array_to {
        my ($self, $num, $step) = @_;

        $step = defined($step) ? $step->get_value : 1;

        my @array;
        my $to = $num->get_value;

        if ($step == 1) {

            # Unpack limit
            $to = $to->bstr if ref($to);

            foreach my $i ($$self .. $to) {
                push @array, $self->new($i);
            }
        }
        else {
            for (my $i = $$self ; $i <= $to ; $i += $step) {
                push @array, $self->new($i);
            }
        }

        Sidef::Types::Array::Array->new(@array);
    }

    *arr_to = \&array_to;

    sub array_downto {
        my ($self, $num, $step) = @_;
        $step = defined($step) ? $step->get_value : 1;

        my @array;
        my $downto = $num->get_value;

        for (my $i = $$self ; $i >= $downto ; $i -= $step) {
            push @array, $self->new($i);
        }

        Sidef::Types::Array::Array->new(@array);
    }

    *arr_downto = \&array_downto;

    sub to {
        my ($self, $num, $step) = @_;
        $step = defined($step) ? $step->get_value : 1;
        Sidef::Types::Array::RangeNumber->new(
                                              from => $$self,
                                              to   => $num->get_value,
                                              step => $step,
                                             );
    }

    *upto  = \&to;
    *up_to = \&to;

    sub downto {
        my ($self, $num, $step) = @_;
        $step = defined($step) ? $step->get_value : 1;
        Sidef::Types::Array::RangeNumber->new(
                                              from => $$self,
                                              to   => $num->get_value,
                                              step => -$step,
                                             );
    }

    *down_to = \&downto;

    sub range {
        my ($self, $to, $step) = @_;

        defined($to)
          ? $self->to($to, $step)
          : $self->new(0)->to($self);
    }

    sub sqrt {
        my ($self) = @_;
        $self->new($$self->copy->bsqrt);
    }

    sub root {
        my ($self, $n) = @_;
        $self->new($$self->copy->broot($n->get_value));
    }

    sub troot {
        my ($self) = @_;

        state $two   = Math::BigFloat->new(2);
        state $eight = Math::BigFloat->new(8);

        $self->new(scalar $$self->copy->bmul($eight)->binc->bsqrt->bdec->bdiv($two));
    }

    sub abs {
        my ($self) = @_;
        $self->new($$self->copy->babs);
    }

    *pos      = \&abs;
    *positive = \&abs;

    sub hex {
        my ($self) = @_;
        $self->new(Math::BigInt->new("0x$$self"));
    }

    *from_hex = \&hex;

    sub oct {
        my ($self) = @_;
        $self->new(Math::BigInt->from_oct($$self));
    }

    *from_oct = \&oct;

    sub bin {
        my ($self) = @_;
        $self->new(Math::BigInt->new("0b$$self"));
    }

    *from_bin = \&bin;

    sub exp {
        my ($self) = @_;
        $self->new($$self->copy->bexp);
    }

    sub int {
        my ($self) = @_;
        $self->new($$self->as_int);
    }

    *as_int = \&int;
    *to_i   = \&int;

    sub max {
        my ($self, $num) = @_;
        my ($x, $y) = ($$self, $num->get_value);
        $self->new($x > $y ? $x : $y);
    }

    sub min {
        my ($self, $num) = @_;
        my ($x, $y) = ($$self, $num->get_value);
        $self->new($x < $y ? $x : $y);
    }

    sub cos {
        my ($self) = @_;
        $self->new($$self->copy->bcos);
    }

    sub sin {
        my ($self) = @_;
        $self->new($$self->copy->bsin);
    }

    sub atan {
        my ($x) = @_;
        Sidef::Types::Number::Number->new($x->get_value->copy->batan);
    }

    sub atan2 {
        my ($x, $y) = @_;
        Sidef::Types::Number::Number->new($x->get_value->copy->batan2($y->get_value));
    }

    sub log {
        my ($self, $base) = @_;
        $self->new($$self->copy->blog(defined($base) ? $base->get_value : ()));
    }

    sub ln {
        my ($self) = @_;
        $self->new($$self->copy->blog);
    }

    sub log10 {
        my ($self) = @_;
        state $ten = Math::BigFloat->new(10);
        $self->new($$self->copy->blog($ten));
    }

    sub log2 {
        my ($self) = @_;
        state $two = Math::BigFloat->new(2);
        $self->new($$self->copy->blog($two));
    }

    sub inf {
        my ($self) = @_;
        $self->new(Math::BigInt->binf);
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
        Sidef::Types::String::String->new(CORE::chr($$self->numify));
    }

    sub npow2 {
        my ($self) = @_;
        my $two = Math::BigInt->new(2);
        $self->new(scalar $two->blsft($$self->as_int->blog($two)));
    }

    sub npow {
        my ($self, $num) = @_;
        $num = $num->get_value;
        $self->new(scalar $num->copy->bpow($$self->as_int->blog($num)->binc));
    }

    sub is_zero {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_zero);
    }

    sub is_one {
        my ($self, $sign) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_one(defined($sign) ? $sign->get_value : ()));
    }

    sub is_nan {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_nan);
    }

    *is_NaN = \&is_nan;

    sub is_positive {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_pos);
    }

    *is_pos = \&is_positive;

    sub is_negative {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_neg);
    }

    *is_neg = \&is_negative;

    sub is_even {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->as_int->is_even);
    }

    sub is_odd {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->as_int->is_odd);
    }

    sub is_inf {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_inf);
    }

    *is_infinite = \&is_inf;

    sub is_integer {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self->is_int);
    }

    *is_int = \&is_integer;

    sub rand {
        my ($self, $max) = @_;
        defined($max)
          ? $self->new($$self + CORE::rand($max->get_value - $$self))
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
                                        ? $places->get_value
                                        : ()
                                       )
                  );
    }

    sub roundf {
        my ($self, $places) = @_;
        $self->new(
                   $$self->copy->bfround(
                                         defined($places)
                                         ? $places->get_value
                                         : ()
                                        )
                  );
    }

    *fround = \&roundf;

    sub length {
        my ($self) = @_;
        $self->new($$self->length);
    }

    *len = \&length;

    sub digit {
        my ($self, $n) = @_;
        $self->new($$self->as_int->digit($n->get_value));
    }

    sub digits {
        my ($self) = @_;

        my $len = $$self->length;
        my $int = $$self->as_int;

        my @digits;
        foreach my $i (0 .. $len - 1) {
            unshift @digits, $self->new($int->digit($i));
        }
        Sidef::Types::Array::Array->new(@digits);
    }

    sub nok {
        my ($self, $k) = @_;
        $self->new($$self->as_int->bnok($k->get_value));
    }

    *binomial = \&nok;

    sub of {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Block::Code') {
            return Sidef::Types::Array::Array->new(map { $obj->run($self->new($_)) } 1 .. $$self);
        }

        Sidef::Types::Array::Array->new(($obj) x $$self);
    }

    sub times {
        my ($self, $obj) = @_;
        $obj->repeat($self);
    }

    sub to_bin {
        my ($self) = @_;
        Sidef::Types::String::String->new(substr(Math::BigInt->new($$self)->as_bin, 2));
    }

    *as_bin = \&to_bin;

    sub to_oct {
        my ($self) = @_;
        Sidef::Types::String::String->new(substr(Math::BigInt->new($$self)->as_oct, 1));
    }

    *as_oct = \&to_oct;

    sub to_hex {
        my ($self) = @_;
        Sidef::Types::String::String->new(substr(Math::BigInt->new($$self)->as_hex, 2));
    }

    *as_hex = \&to_hex;

    sub is_div {
        my ($self, $num) = @_;
        Sidef::Types::Bool::Bool->new($$self->copy->bmod($num->get_value)->is_zero);
    }

    sub divides {
        my ($self, $num) = @_;
        Sidef::Types::Bool::Bool->new(Math::BigFloat->new($num->get_value)->bmod($$self)->is_zero);
    }

    sub commify {
        my ($self) = @_;

        my $n = $$self;
        $n = $n->bstr if ref($n);

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

    sub rat {
        my ($self) = @_;
        $self->new(Math::BigRat->new($$self));
    }

    sub numerator {
        my ($self) = @_;
        $self->new($$self->numerator);
    }

    *nu = \&numerator;

    sub denominator {
        my ($self) = @_;
        $self->new($$self->denominator);
    }

    *de = \&denominator;

    sub parts {
        my ($self) = @_;
        map { $self->new($_) } $$self->parts;
    }

    *nude = \&parts;

    sub as_float {
        my ($self) = @_;
        $self->new($$self->as_float);
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self->bstr);
    }

    *to_s = \&dump;

    sub sstr {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self->bsstr);
    }

    sub shift_right {
        my ($self, $num, $base) = @_;
        $self->new($$self->copy->brsft($num->get_value, (defined($base) ? $base->get_value : ())));
    }

    sub shift_left {
        my ($self, $num, $base) = @_;
        $self->new($$self->copy->blsft($num->get_value, defined($base) ? $base->get_value : ()));
    }

    sub complex {
        my ($self, $num) = @_;
        Sidef::Types::Number::Complex->new($self, $num);
    }

    *c = \&complex;

    sub i {
        my ($self) = @_;
        Sidef::Types::Number::Complex->new(0, $$self);
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
        *{__PACKAGE__ . '::' . '='}   = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'} = \&ne;
        *{__PACKAGE__ . '::' . '..'}  = \&array_to;
        *{__PACKAGE__ . '::' . '...'} = \&to;
        *{__PACKAGE__ . '::' . '..^'} = \&to;
        *{__PACKAGE__ . '::' . '^..'} = \&downto;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
        *{__PACKAGE__ . '::' . '%%'}  = \&is_div;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
        *{__PACKAGE__ . '::' . ':'}   = \&complex;
    }
};

1;
