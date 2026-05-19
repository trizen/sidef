package Sidef::Types::Number::Quadratic;

use utf8;
use 5.016;

use parent qw(
  Sidef::Types::Number::Number
);

use overload
  q{bool} => sub { (@_) = ($_[0]); goto &__boolify__ },
  q{""}   => sub { (@_) = ($_[0]); goto &__stringify__ },
  q{0+}   => \&to_n,
  q{${}}  => \&to_n;

# Constructor: Quadratic(a, b, p, q) where t^2 = p + q*t
sub new {
    my ($class, $A, $B, $p, $q) = @_;

    # Handle evaluation of polynomials
    if (ref($_[0]) eq __PACKAGE__) {
        return $_[0]->eval($A);
    }

    # Ensure all arguments are proper Number objects
    $A //= Sidef::Types::Number::Number::ZERO;
    $B //= Sidef::Types::Number::Number::ZERO;
    $p //= Sidef::Types::Number::Number::ONE;
    $q //= Sidef::Types::Number::Number::ZERO;

    $A = Sidef::Types::Number::Number->new($A) if !UNIVERSAL::isa($A, 'Sidef::Types::Number::Number');
    $B = Sidef::Types::Number::Number->new($B) if !UNIVERSAL::isa($B, 'Sidef::Types::Number::Number');
    $p = Sidef::Types::Number::Number->new($p) if !UNIVERSAL::isa($p, 'Sidef::Types::Number::Number');
    $q = Sidef::Types::Number::Number->new($q) if !UNIVERSAL::isa($q, 'Sidef::Types::Number::Number');

    bless {a => $A, b => $B, p => $p, q => $q};
}

*call = \&new;

sub with_value {
    my ($self, $value_1, $value_2) = @_;
    __PACKAGE__->new($value_1, $value_2, $self->{p}, $self->{q});
}

# Evaluate as a polynomial at $x (replace t by $x)
sub eval {
    my ($self, $x) = @_;
    __PACKAGE__->new($self->{a}->eval($x), $self->{b}->eval($x), $self->{p}->eval($x), $self->{q}->eval($x));
}

# Lift coefficients (used by modular arithmetic)
sub lift {
    my ($self) = @_;
    __PACKAGE__->new($self->{a}->lift, $self->{b}->lift, $self->{p}->lift, $self->{q}->lift);
}

# Accessors
sub a { $_[0]->{a} }
*re   = \&a;
*real = \&a;

sub b { $_[0]->{b} }
*im   = \&b;
*imag = \&b;

sub p { $_[0]->{p} }
sub q { $_[0]->{q} }

*w = \&p;

sub reals {
    ($_[0]->{a}, $_[0]->{b});
}

sub parts {
    Sidef::Types::Array::Array->new($_[0]->{a}, $_[0]->{b}, $_[0]->{p}, $_[0]->{q});
}

# Boolean context (true unless zero)
sub __boolify__ {
    $_[0]->{a};
}

# Numification returns the complex embedding (principal root)
sub to_n {
    my ($self) = @_;

    state $two  = Sidef::Types::Number::Number::TWO;
    state $four = $two->add($two);

    my $D      = $self->{q}->sqr->add($self->{p}->mul($four));    # discriminant q^2 + 4p
    my $sqrt_D = $D->sqrt;                                        # complex if D<0, real otherwise

    my $t = $self->{q}->add($sqrt_D)->div($two);                  # principal root (q + sqrt(D))/2
    my $r = $self->{a}->add($self->{b}->mul($t));

    if (ref($r) ne 'Sidef::Types::Number::Number') {
        return $r->to_n;
    }

    return $r;
}

*to_c = \&to_n;

# --- Stringification ---

sub __stringify__ {
    my ($self) = @_;
    sprintf("Quadratic(%s, %s, %s, %s)", $self->{a}->dump, $self->{b}->dump, $self->{p}->dump, $self->{q}->dump);
}

sub _pretty_stringify {
    my ($x) = @_;

    if (!$x->{q}->is_zero) {
        return $x->__stringify__;
    }

    my $a_str = $x->{a}->stringify;

    if ($x->{b}->is_zero) {
        return $a_str;
    }

    my $p_str     = $x->{p}->stringify;
    my $sign      = $x->{b}->is_neg ? ' - ' : ' + ';
    my $b_abs_str = $x->{b}->abs->stringify;

    Sidef::Types::String::String->new($a_str . $sign . $b_abs_str . '*sqrt(' . $p_str . ')');
}

sub stringify {
    my ($x) = @_;
    Sidef::Types::String::String->new($x->_pretty_stringify);
}

*pretty = \&stringify;

sub to_s {
    my ($x) = @_;
    Sidef::Types::String::String->new($x->__stringify__);
}

*dump = \&to_s;

# --- Arithmetic operations (scalar- and ring-element-aware) ---

sub add {
    my ($x, $y) = @_;
    if (ref($y) eq __PACKAGE__ and $x->{p}->eq($y->{p}) and $x->{q}->eq($y->{q})) {
        return __PACKAGE__->new($x->{a}->add($y->{a}), $x->{b}->add($y->{b}), $x->{p}, $x->{q});
    }

    # Scalar addition: treat other as a+0*t
    return __PACKAGE__->new($x->{a}->add($y), $x->{b}, $x->{p}, $x->{q});
}

sub sub {
    my ($x, $y) = @_;
    if (ref($y) eq __PACKAGE__ and $x->{p}->eq($y->{p}) and $x->{q}->eq($y->{q})) {
        return __PACKAGE__->new($x->{a}->sub($y->{a}), $x->{b}->sub($y->{b}), $x->{p}, $x->{q});
    }
    return __PACKAGE__->new($x->{a}->sub($y), $x->{b}, $x->{p}, $x->{q});
}

sub mul {
    my ($x, $y) = @_;
    if (ref($y) eq __PACKAGE__ and $x->{p}->eq($y->{p}) and $x->{q}->eq($y->{q})) {
        my $A     = $x->{a};
        my $B     = $x->{b};
        my $C     = $y->{a};
        my $D     = $y->{b};
        my $BD    = $B->mul($D);
        my $new_a = $A->mul($C)->add($BD->mul($x->{p}));
        my $new_b = $A->mul($D)->add($B->mul($C))->add($BD->mul($x->{q}));
        return __PACKAGE__->new($new_a, $new_b, $x->{p}, $x->{q});
    }

    # Scalar multiplication
    return __PACKAGE__->new($x->{a}->mul($y), $x->{b}->mul($y), $x->{p}, $x->{q});
}

sub div {
    my ($x, $y) = @_;
    if (ref($y) eq __PACKAGE__ and $x->{p}->eq($y->{p}) and $x->{q}->eq($y->{q})) {
        my $norm = $y->norm;
        my $num  = $x->mul($y->conj);
        return __PACKAGE__->new($num->{a}->div($norm), $num->{b}->div($norm), $x->{p}, $x->{q});
    }

    # Scalar division
    return __PACKAGE__->new($x->{a}->div($y), $x->{b}->div($y), $x->{p}, $x->{q});
}

# --- Unary operations ---

sub neg {
    my ($x) = @_;
    __PACKAGE__->new($x->{a}->neg, $x->{b}->neg, $x->{p}, $x->{q});
}

sub sqr {
    my ($x) = @_;
    $x->mul($x);
}

sub abs {
    my ($x) = @_;
    $x->norm->sqrt;
}

# --- Increment / Decrement (on the real part) ---

sub inc {
    my ($x) = @_;
    __PACKAGE__->new($x->{a}->inc, $x->{b}, $x->{p}, $x->{q});
}

sub dec {
    my ($x) = @_;
    __PACKAGE__->new($x->{a}->dec, $x->{b}, $x->{p}, $x->{q});
}

# --- Rounding and floating point ---

sub float {
    my ($x) = @_;
    __PACKAGE__->new($x->{a}->float, $x->{b}->float, $x->{p}, $x->{q});
}

sub floor {
    my ($x) = @_;
    __PACKAGE__->new($x->{a}->floor, $x->{b}->floor, $x->{p}, $x->{q});
}

sub ceil {
    my ($x) = @_;
    __PACKAGE__->new($x->{a}->ceil, $x->{b}->ceil, $x->{p}, $x->{q});
}

sub round {
    my ($x, $r) = @_;
    __PACKAGE__->new($x->{a}->round($r), $x->{b}->round($r), $x->{p}, $x->{q});
}

# --- Euclidean division ---

# Euclidean division with rounding to nearest (gives better behaviour for Euclidean algorithm)
sub divmod {
    my ($self, $other) = @_;
    my $q = $self->mul($other->inv)->round;
    my $r = $self->sub($q->mul($other));
    return ($q, $r);
}

sub idiv {
    my ($self, $other) = @_;
    my ($q, undef) = $self->divmod($other);
    return $q;
}

sub mod {
    my ($x, $y) = @_;

    if (ref($y) eq 'Sidef::Types::Number::Number') {
        return __PACKAGE__->new($x->{a}->mod($y), $x->{b}->mod($y), $x->{p}, $x->{q});
    }

    # Euclidean remainder
    my (undef, $r) = $x->divmod($y);
    return $r;
}

# --- Shifts (multiplication/division by 2^n) ---

sub shift_left {
    my ($x, $n) = @_;
    $x->mul(Sidef::Types::Number::Number::TWO->pow($n));
}
*lsft = \&shift_left;

sub shift_right {
    my ($x, $n) = @_;
    $x->div(Sidef::Types::Number::Number::TWO->pow($n));
}
*rsft = \&shift_right;

# --- Exponentiation ---

sub pow {
    my ($x, $n) = @_;
    $n->is_int || return $x->to_n->pow($n);    # non‑integer -> complex embedding

    my $negative_power = 0;
    if ($n->is_neg) {
        $n              = $n->abs;
        $negative_power = 1;
    }

    my $c = __PACKAGE__->new(Sidef::Types::Number::Number::ONE, Sidef::Types::Number::Number::ZERO, $x->{p}, $x->{q});

    my $base = $x;
    foreach my $bit (reverse split(//, $n->as_bin)) {
        $c    = $c->mul($base) if $bit;
        $base = $base->sqr;
    }

    $negative_power ? $c->inv : $c;
}

sub powmod {
    my ($x, $n, $m) = @_;
    $x = $x->mod($m);
    my $negative_power = 0;
    if ($n->is_neg) {
        $n              = $n->abs;
        $negative_power = 1;
    }

    my $c = __PACKAGE__->new(Sidef::Types::Number::Number::ONE, Sidef::Types::Number::Number::ZERO, $x->{p}, $x->{q});

    my $base = $x;
    foreach my $bit (reverse split(//, $n->as_bin)) {
        $c    = $c->mul($base)->mod($m) if $bit;
        $base = $base->sqr->mod($m);
    }

    $negative_power ? $c->invmod($m) : $c;
}

# --- Algebraic properties ---

sub conj {
    my ($x) = @_;
    __PACKAGE__->new($x->{a}->add($x->{b}->mul($x->{q})), $x->{b}->neg, $x->{p}, $x->{q});
}

sub norm {
    my ($x) = @_;
    $x->{a}->sqr->add($x->{a}->mul($x->{b})->mul($x->{q}))->sub($x->{b}->sqr->mul($x->{p}));
}

sub trace {
    my ($x) = @_;
    $x->{a}->mul(Sidef::Types::Number::Number::TWO)->add($x->{b}->mul($x->{q}));
}

sub inv {
    my ($x)    = @_;
    my $norm   = $x->norm;
    my $conj_a = $x->{a}->add($x->{b}->mul($x->{q}));
    my $conj_b = $x->{b}->neg;
    __PACKAGE__->new($conj_a->div($norm), $conj_b->div($norm), $x->{p}, $x->{q});
}

sub invmod {
    my ($x, $m) = @_;
    $x = $x->mod($m);
    my $norm   = $x->norm->invmod($m);
    my $conj_a = $x->{a}->add($x->{b}->mul($x->{q}));
    my $conj_b = $x->{b}->neg;
    __PACKAGE__->new($conj_a->mul($norm)->mod($m), $conj_b->mul($norm)->mod($m), $x->{p}, $x->{q});
}

# --- Predicates ---

sub is_zero {
    my ($x) = @_;
    $x->{a}->is_zero && $x->{b}->is_zero;
}

sub is_one {
    my ($x) = @_;
    $x->{a}->is_one && $x->{b}->is_zero;
}

sub is_mone {
    my ($x) = @_;
    $x->{a}->is_mone && $x->{b}->is_zero;
}

sub is_int {
    $_[0]->{b}->is_zero;
}

sub is_unit {
    my ($x) = @_;
    $x->norm->abs->is_one;
}

sub is_associate {
    my ($x, $y) = @_;
    return $x->is_zero ? $y->is_zero : !$y->is_zero && $x->mul($y->inv)->is_unit;
}

sub is_coprime {
    my ($x, $y) = @_;
    $x->norm->gcd($y->norm)->is_one;
}

sub is_prime {
    my ($x) = @_;

    # sufficient condition: norm is a prime integer (not necessary though)
    $x->norm->abs->is_prime;
}

# --- GCD / LCM (Euclidean algorithm) ---

sub gcd {
    my ($self, $other) = @_;
    my $u = $self;
    my $v = $other;
    while (!$v->is_zero) {
        my (undef, $r) = $u->divmod($v);
        $u = $v;
        $v = $r;
    }
    return $u;
}

sub lcm {
    my ($self, $other) = @_;
    if ($self->is_zero || $other->is_zero) {
        return __PACKAGE__->new(Sidef::Types::Number::Number::ZERO, Sidef::Types::Number::Number::ZERO, $self->{p}, $self->{q});
    }
    $self->mul($other)->div($self->gcd($other));
}

# --- Comparison (lexicographic: a, b, p, q) ---

sub cmp {
    my ($x, $y) = @_;
    if (ref($y) eq __PACKAGE__) {
        my $cmp = $x->{a}->cmp($y->{a}) // return undef;
        $cmp and return $cmp;
        $cmp = $x->{b}->cmp($y->{b}) // return undef;
        $cmp and return $cmp;
        $cmp = $x->{p}->cmp($y->{p}) // return undef;
        $cmp and return $cmp;
        return $x->{q}->cmp($y->{q});
    }

    # Compare with a plain number: a vs. $y, then b vs. 0
    my $cmp = $x->{a}->cmp($y) // return undef;
    return $cmp if $cmp;
    $x->{b}->cmp(Sidef::Types::Number::Number::ZERO);
}

sub eq {
    my ($x, $y) = @_;
    if (ref($y) eq __PACKAGE__) {
        $x->{a}->eq($y->{a}) && $x->{b}->eq($y->{b}) && $x->{p}->eq($y->{p}) && $x->{q}->eq($y->{q});
    }
    else {
        $x->{a}->eq($y) && $x->{b}->is_zero;
    }
}

sub ne {
    my ($x, $y) = @_;
    !$x->eq($y);
}

# --- Operator overloading (inspired by Quadratic) ---

{
    no strict 'refs';

    foreach my $method (qw(ge gt lt le)) {
        *{__PACKAGE__ . '::' . $method} = sub {
            my ($x, $y) = @_;
            ($x->cmp($y) // return undef)->$method(Sidef::Types::Number::Number::ZERO);
        };
    }

    foreach my $method (qw(and xor or)) {
        *{__PACKAGE__ . '::' . $method} = sub {
            my ($x, $y) = @_;
            if (ref($y) eq __PACKAGE__ and $x->{p}->eq($y->{p}) and $x->{q}->eq($y->{q})) {
                return __PACKAGE__->new($x->{a}->$method($y->{a}), $x->{b}->$method($y->{b}), $x->{p}, $x->{q});
            }

            # Treat $y as scalar with same ring
            return __PACKAGE__->new($x->{a}->$method($y), $x->{b}, $x->{p}, $x->{q});
        };
    }

    # Map infix operators to methods
    *{__PACKAGE__ . '::' . '/'}   = \&div;
    *{__PACKAGE__ . '::' . '÷'}   = \&div;
    *{__PACKAGE__ . '::' . '*'}   = \&mul;
    *{__PACKAGE__ . '::' . '%'}   = \&mod;
    *{__PACKAGE__ . '::' . '+'}   = \&add;
    *{__PACKAGE__ . '::' . '-'}   = \&sub;
    *{__PACKAGE__ . '::' . '**'}  = \&pow;
    *{__PACKAGE__ . '::' . '++'}  = \&inc;
    *{__PACKAGE__ . '::' . '--'}  = \&dec;
    *{__PACKAGE__ . '::' . '<'}   = \&lt;
    *{__PACKAGE__ . '::' . '>'}   = \&gt;
    *{__PACKAGE__ . '::' . '&'}   = \&and;
    *{__PACKAGE__ . '::' . '|'}   = \&or;
    *{__PACKAGE__ . '::' . '^'}   = \&xor;
    *{__PACKAGE__ . '::' . '<<'}  = \&lsft;
    *{__PACKAGE__ . '::' . '>>'}  = \&rsft;
    *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
    *{__PACKAGE__ . '::' . '<='}  = \&le;
    *{__PACKAGE__ . '::' . '≤'}   = \&le;
    *{__PACKAGE__ . '::' . '>='}  = \&ge;
    *{__PACKAGE__ . '::' . '≥'}   = \&ge;
    *{__PACKAGE__ . '::' . '=='}  = \&eq;
    *{__PACKAGE__ . '::' . '!='}  = \&ne;
}

1
