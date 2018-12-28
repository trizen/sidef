package Sidef::Types::Array::Vector {

    use utf8;
    use 5.016;

    use parent qw(Sidef::Types::Array::Array);

    require List::Util;

    my %vector_like = (
                       'Sidef::Types::Array::Array'  => 1,
                       'Sidef::Types::Array::Pair'   => 1,
                       'Sidef::Types::Array::Vector' => 1,
                      );

    sub new {
        my (undef, @vals) = @_;
        bless \@vals;
    }

    *call = \&new;

    sub zero {
        my (undef, $n) = @_;
        bless [(Sidef::Types::Number::Number::ZERO) x CORE::int($n)];
    }

    sub neg {
        my ($v1) = @_;
        bless($v1->scalar_operator('neg'));
    }

    sub abs {
        my ($v) = @_;
        Sidef::Math::Math->sum(map { $_->mul($_) } @$v)->sqrt;
    }

    sub norm {
        my ($v) = @_;
        Sidef::Math::Math->sum(map { $_->mul($_) } @$v);
    }

    sub manhattan_norm {
        my ($v) = @_;
        Sidef::Math::Math->sum(map { $_->abs } @$v);
    }

    sub manhattan_dist {
        my ($v1, $v2) = @_;
        my $end = List::Util::min($#{$v1}, $#{$v2});
        Sidef::Math::Math->sum(map { $v1->[$_]->sub($v2->[$_])->abs } 0 .. $end);
    }

    sub chebyshev_dist {
        my ($v1, $v2) = @_;
        my $end = List::Util::min($#{$v1}, $#{$v2});
        Sidef::Math::Math->max(Sidef::Types::Number::Number::ZERO, map { $v1->[$_]->sub($v2->[$_])->abs } 0 .. $end);
    }

    sub dist_norm {
        my ($v1, $v2) = @_;
        my $end = List::Util::min($#{$v1}, $#{$v2});
        Sidef::Math::Math->sum(map { my $t = $v1->[$_]->sub($v2->[$_]); $t->mul($t) } 0 .. $end);
    }

    sub dist {
        my ($v1, $v2) = @_;
        $v1->dist_norm($v2)->sqrt;
    }

    sub atan2 {
        my ($v1, $v2) = @_;

        my $end = List::Util::min($#{$v1}, $#{$v2});

        if ($end == 1) {
            my $dot   = $v1->[0]->mul($v2->[0])->add($v1->[1]->mul($v2->[1]));
            my $cross = $v1->[0]->mul($v2->[1])->sub($v1->[1]->mul($v2->[0]));
            return $cross->atan2($dot);
        }

        my $a1 = $v1->abs;
        return Sidef::Types::Number::Number::ZERO if $a1->is_zero;
        my $u1 = $v1->div($a1);
        my $p  = $v2->mul($u1);

        $v2->sub($p->mul($u1))->abs->atan2($p);
    }

    sub add {
        my ($v1, $v2) = @_;

        if (exists $vector_like{ref($v2)}) {
            return bless($v1->wise_operator('+', $v2));
        }

        bless($v1->scalar_operator('+', $v2));
    }

    sub sub {
        my ($v1, $v2) = @_;

        if (exists $vector_like{ref($v2)}) {
            return bless($v1->wise_operator('-', $v2));
        }

        bless($v1->scalar_operator('-', $v2));
    }

    sub div {
        my ($v1, $v2) = @_;

        if (exists $vector_like{ref($v2)}) {
            return $v1->mul($v2->scalar_operator('inv'));
        }

        bless($v1->scalar_operator('/', $v2));
    }

    sub mul {
        my ($v1, $v2) = @_;

        if (exists $vector_like{ref($v2)}) {
            return $v1->wise_operator('*', $v2)->sum;
        }

        bless($v1->scalar_operator('*', $v2));
    }

    sub and {
        my ($m1, $m2) = @_;

        if (exists $vector_like{ref($m2)}) {
            return bless($m1->wise_operator('&', $m2));
        }

        bless($m1->scalar_operator('&', $m2));
    }

    sub or {
        my ($m1, $m2) = @_;

        if (exists $vector_like{ref($m2)}) {
            return bless($m1->wise_operator('|', $m2));
        }

        bless($m1->scalar_operator('|', $m2));
    }

    sub xor {
        my ($m1, $m2) = @_;

        if (exists $vector_like{ref($m2)}) {
            return bless($m1->wise_operator('^', $m2));
        }

        bless($m1->scalar_operator('^', $m2));
    }

    sub floor {
        my ($self) = @_;
        bless [map { $_->floor } @$self];
    }

    sub ceil {
        my ($self) = @_;
        bless [map { $_->ceil } @$self];
    }

    sub round {
        my ($self, $digits) = @_;
        bless [map { $_->round($digits) } @$self];
    }

    sub to_a {
        my ($A) = @_;
        Sidef::Types::Array::Array->new(@$A);
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '*'}  = \&mul;
        *{__PACKAGE__ . '::' . '**'} = \&pow;
        *{__PACKAGE__ . '::' . '+'}  = \&add;
        *{__PACKAGE__ . '::' . '-'}  = \&sub;
        *{__PACKAGE__ . '::' . '/'}  = \&div;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '&'}  = \&and;
        *{__PACKAGE__ . '::' . '|'}  = \&or;
        *{__PACKAGE__ . '::' . '^'}  = \&xor;

    }
};

1
