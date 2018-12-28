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
            return $v1->mul($v2->inv);
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
    }
};

1
