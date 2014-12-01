package Sidef::Math::Math {

    use 5.014;
    our @ISA = qw(Sidef);

    sub new {
        require Math::BigFloat;
        bless {}, __PACKAGE__;
    }

    sub e {
        my ($self, $places) = @_;
        Sidef::Types::Number::Number->new(
                            Math::BigFloat->bexp(1, defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    sub exp {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        Sidef::Types::Number::Number->new(
                     Math::BigFloat->new($$x)->bexp(defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    sub pi {
        my ($self, $places) = @_;
        Sidef::Types::Number::Number->new(
                        Math::BigFloat->new(0)->bpi(defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    *PI = \&pi;

    sub atan {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        Sidef::Types::Number::Number->new(
                    Math::BigFloat->new($$x)->batan(defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    sub atan2 {
        my ($self, $x, $y, $places) = @_;
        ($self->_is_number($x) && $self->_is_number($y)) || return;
        Sidef::Types::Number::Number->new(
              Math::BigFloat->new($$x)->batan2($$y, defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    sub cos {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        Sidef::Types::Number::Number->new(
                     Math::BigFloat->new($$x)->bcos(defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    sub sin {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        Sidef::Types::Number::Number->new(
                     Math::BigFloat->new($$x)->bsin(defined($places) ? ($self->_is_number($places)) ? $$places : return : ()));
    }

    sub asin {
        my ($self, $x, $places) = @_;
        $self->_is_number($x) || return;
        $self->atan2(
                     $x,
                     $self->sqrt(
                                 Sidef::Types::Number::Number->new(1)
                                   ->subtract($self->pow($x, Sidef::Types::Number::Number->new(2))),
                                 $places
                                )
                    );
    }

    sub log {
        my ($self, $n, $base) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(
                           Math::BigFloat->new($$n)->blog(defined($base) ? ($self->_is_number($base)) ? $$base : return : ()));
    }

    sub log2 {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->blog(2));
    }

    sub log10 {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->blog(10));
    }

    sub npow2 {
        my ($self, $x) = @_;

        $self->_is_number($x) || return;
        $x = Math::BigFloat->new($$x);

        my $y = Math::BigFloat->new(2);
        Sidef::Types::Number::Number->new($y->blsft($x->blog($y)->as_int));
    }

    sub npow {
        my ($self, $x, $y) = @_;
        $self->_is_number($x) || return;
        $self->_is_number($y) || return;

        $x = Math::BigFloat->new($$x);
        $y = Math::BigFloat->new($$y);

        Sidef::Types::Number::Number->new($y->bpow($x->blog($y)->as_int->binc));
    }

    sub gcd {
        my ($self, @list) = @_;
        $self->_is_number($_) || return for @list;
        Sidef::Types::Number::Number->new(Math::BigFloat::bgcd(map { $$_ } @list));
    }

    sub abs {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->babs);
    }

    sub lcm {
        my ($self, @list) = @_;
        $self->_is_number($_) || return for @list;
        Sidef::Types::Number::Number->new(Math::BigFloat::blcm(map { $$_ } @list));
    }

    sub inf {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(Math::BigFloat->binf);
    }

    sub precision {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->precision($$n));
    }

    sub accuracy {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->accuracy($$n));
    }

    sub ceil {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->bceil);
    }

    sub floor {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->bfloor);
    }

    sub sqrt {
        my ($self, $n) = @_;
        $self->_is_number($n) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->bsqrt);
    }

    sub pow {
        my ($self, $n, $pow) = @_;
        $self->_is_number($n)   || return;
        $self->_is_number($pow) || return;
        Sidef::Types::Number::Number->new(Math::BigFloat->new($$n)->bpow($$pow));
    }

    sub range_sum {
        my ($self, $from, $to, $step) = @_;

        $self->_is_number($from) || return;
        $self->_is_number($to)   || return;

        defined($step) ? $self->_is_number($step) ? () : return : do {
            $step = Sidef::Types::Number::Number->new(1);
        };

        Sidef::Types::Number::Number->new(($$from + $$to) * (($$to - $$from) / $$step + 1) / 2);
    }

    *rangeSum = \&range_sum;

    sub map {
        my ($self, $amount, $from, $to) = @_;

        $self->_is_number($amount) || return;
        $self->_is_number($from)   || return;
        $self->_is_number($to)     || return;

        my $step  = ($$to - $$from) / $$amount;
        my $array = Sidef::Types::Array::Array->new();

        return $array if $step == 0;

        for (my $i = $$from ; $i < $$to ; $i += $step) {
            $array->push(Sidef::Types::Number::Number->new($i));
        }

        $array;
    }

};

1
