package Sidef::Types::Array::Vector {

    use utf8;
    use 5.016;

    use parent qw(Sidef::Types::Array::Array);

    use overload q{""} => \&_dump;

    require List::Util;

    sub _is_vector {
        my ($self) = @_;

        my $ref = ref($self);

        if ($ref eq __PACKAGE__ or $ref eq 'Sidef::Types::Array::Array') {
            return 1;
        }

        $ref and UNIVERSAL::isa($self, 'Sidef::Types::Array::Array');
    }

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

    sub not {
        my ($v1) = @_;
        bless($v1->scalar_operator('not'));
    }

    sub norm {
        my ($v) = @_;
        Sidef::Types::Number::Number::sum(map { $_->mul($_) } @$v);
    }

    sub abs {
        my ($v) = @_;
        $v->norm->sqrt;
    }

    sub manhattan_norm {
        my ($v) = @_;
        Sidef::Types::Number::Number::sum(map { $_->abs } @$v);
    }

    sub manhattan_dist {
        my ($v1, $v2) = @_;
        my $end = List::Util::min($#{$v1}, $#{$v2});
        Sidef::Types::Number::Number::sum(map { $v1->[$_]->sub($v2->[$_])->abs } 0 .. $end);
    }

    sub chebyshev_dist {
        my ($v1, $v2) = @_;
        my $end = List::Util::min($#{$v1}, $#{$v2});
        Sidef::Types::Number::Number::max(Sidef::Types::Number::Number::ZERO, map { $v1->[$_]->sub($v2->[$_])->abs } 0 .. $end);
    }

    sub dist_norm {
        my ($v1, $v2) = @_;
        my $end = List::Util::min($#{$v1}, $#{$v2});
        Sidef::Types::Number::Number::sum(map { my $t = $v1->[$_]->sub($v2->[$_]); $t->mul($t) } 0 .. $end);
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

        if (_is_vector($v2)) {
            return bless($v1->wise_operator('+', $v2));
        }

        bless($v1->scalar_operator('+', $v2));
    }

    sub sub {
        my ($v1, $v2) = @_;

        if (_is_vector($v2)) {
            return bless($v1->wise_operator('-', $v2));
        }

        bless($v1->scalar_operator('-', $v2));
    }

    sub div {
        my ($v1, $v2) = @_;

        if (_is_vector($v2)) {
            return $v1->mul($v2->scalar_operator('inv'));
        }

        bless($v1->scalar_operator('/', $v2));
    }

    sub mul {
        my ($v1, $v2) = @_;

        if (_is_vector($v2)) {
            return $v1->wise_operator('*', $v2)->sum;
        }

        bless($v1->scalar_operator('*', $v2));
    }

    sub pow {
        my ($v1, $v2) = @_;

        if (_is_vector($v2)) {
            my @matrix;
            foreach my $x (@$v1) {

                my @row;
                foreach my $y (@$v2) {
                    push @row, $x->pow($y);
                }

                push @matrix, bless(\@row, 'Sidef::Types::Array::Array');
            }

            return Sidef::Types::Array::Matrix->new(@matrix);
        }

        bless($v1->scalar_operator('**', $v2));
    }

    sub and {
        my ($v1, $v2) = @_;

        if (_is_vector($v2)) {
            return bless($v1->wise_operator('&', $v2));
        }

        bless($v1->scalar_operator('&', $v2));
    }

    sub or {
        my ($v1, $v2) = @_;

        if (_is_vector($v2)) {
            return bless($v1->wise_operator('|', $v2));
        }

        bless($v1->scalar_operator('|', $v2));
    }

    sub xor {
        my ($v1, $v2) = @_;

        if (_is_vector($v2)) {
            return bless($v1->wise_operator('^', $v2));
        }

        bless($v1->scalar_operator('^', $v2));
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

    sub to_array {
        my ($v) = @_;
        Sidef::Types::Array::Array->new(@$v);
    }

    *to_a = \&to_array;

    sub _dump {
        "Vector(" . substr($_[0]->SUPER::_dump, 1, -1) . ")";
    }

    sub dump {
        Sidef::Types::String::String->new($_[0]->_dump);
    }

    *to_s   = \&dump;
    *to_str = \&dump;

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
